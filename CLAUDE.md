# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A SAP CAP backend (Node.js, `@sap/cds` 9, SQLite) that serves purchase-order data over OData V4 to a separate UI5 approval app. The UI5 app is not in this repo. The npm project is still called `bookshop`, but the domain is purchase orders: the service and its implementation class are both `POService`.

## Refactoring status: paused after step 3.4

The project follows the refactoring plan in https://claude.ai/artifact/KTEYQLmiPu2F7sYAc9ZyBV (read it with the Artifact tool).

- **Done:** stages 0 to 3, checked on 2026-10-09. The 12 tests from step 4.1 pass against the current code.
- **On hold:** stages 4 and 5. Those steps may or may not be implemented.
- **Planned, not started:**
  - **Stage 6** moves logic the UI5 app computes in the browser into a read-only `POItemList` view in `srv/main.cds`: delivery status, approval status, search and totals. It also loosens CORS in `server.js`.
  - **Stage 7** adapts the UI5 app in `d:\My Project\UI5 PO` to use that view.
  - The user takes these one step at a time.
- **Do not start any step from 4.1 on, including stages 6 and 7, unless the user explicitly asks for that step.**
- **The UI5 app** is updated only after the refactoring. Until then it still calls the old `/odata/v4/bookshop/` URL and PATCHes the old string approval fields, so it does not work against this service.

## Commands

- `npm start`: runs `cds deploy` (as `prestart`), then `cds watch`. The server listens on http://localhost:4004, with the service at `/odata/v4/po/`. CAP builds that path from the service name `POService`, so renaming the service changes the URL.
- `npx cds deploy`: rebuilds `bookshop.sqlite` from `db/schema.cds` and the CSVs in `db/data/`.
- `npx eslint .`: lints the project. The config extends `cds.recommended`.
- `npx cds compile srv --to serviceinfo`: shows which services are served and at which paths.

There are no tests and no `test` script yet (step 4.1 is on hold). `@cap-js/cds-test` is installed as a dev dependency. Tests must start the server with `cds.test(__dirname + '/..', '--in-memory')`. Without `--in-memory` they run in the `development` profile and write into the real `bookshop.sqlite`.

## Architecture

- **Model** (`db/schema.cds`, namespace `org.hossam`):
  - `PO` (key `PONumber`) is the header. It uses the `managed` aspect, so it has `createdAt/By` and `modifiedAt/By`.
  - `PO` composes many `Items` through `Items.PO = $self`. `Items` has a two-part key: the managed association `PO` (column `PO_PONumber`) and `Item`, a zero-padded string such as `0010`.
  - `PO.Vendor` (`@mandatory @assert.target`), `Items.Material` and `Items.Plant` (both `@assert.target`) are managed associations to the master-data entities `Vendors`, `Materials` and `Plants`, each keyed by `ID`. `Items.OrderQty` has `@assert.range: [1, 999999999]`. These checks run only on writes through the service, not on CSV loading.
  - `OrderDate` and `DeliveryDate` are `Date`. `Currency` is the common `Currency` type, stored in the column `Currency_code`.
  - `L1Approve` and `L2Approve` are `Boolean`: `null` means pending, `true` approved, `false` rejected. `L1By`, `L1Date`, `L2By`, `L2Date` and `RejectReason` record each decision.
- **`using` line**: `using { Currency, managed } from '@sap/cds-common-content'` imports both definitions, because that package loads `@sap/cds/common`. It also adds the package's currency list data to the model. Importing from `@sap/cds/common` alone would leave `sap_common_Currencies` empty.
- **Seed data**: `cds deploy` loads `db/data/org.hossam-<Entity>.csv`. CSV headers use the generated foreign key columns (`Vendor_ID`, `PO_PONumber`, `Material_ID`, `Plant_ID`, `Currency_code`), ISO dates and lowercase `true`/`false`. An empty value means `null`.
- **Service** (`srv/main.cds`):
  - `PO` has `@restrict`: `READ` for `POViewer`, and the bound actions `approve()` and `reject(reason)` for `L1Approver` and `L2Approver`. No CREATE, UPDATE or DELETE is granted, so a PATCH gets 403. `PO` adds the flat field `VendorName` (`Vendor.Name`).
  - `Items` has `@restrict` with `READ` for `POViewer`. `Vendors`, `Materials` and `Plants` are `@readonly @requires: 'POViewer'`.
  - An `annotate POService.PO` block inside the service marks the approval fields `@readonly` and sets `modifiedAt @odata.etag`. Because of the ETag, an action call without `If-Match` gets 428, and one with a stale ETag gets 412. UI5 sends `If-Match` automatically.
  - `userInfo()` requires only an authenticated user and returns `id`, `authorized` (has `POViewer`), `canApproveL1` and `canApproveL2`.
- **Handler** (`srv/main.js`, class `POService`; CAP loads it because it shares the base name of `main.cds`): one `on` handler for `approve` and `reject`.
  - It reads the PO with `SELECT.one.from(req.subject)` and works out the open level from the data. Level 1 is open while `L1Approve` is `null`. Level 2 is open once `L1Approve` is `true` and while `L2Approve` is `null`. Otherwise it returns 409. The client never sends a level.
  - It requires the role `L<level>Approver` (403 otherwise) and refuses level 2 by the same user who approved level 1 (four-eyes rule). `reject` needs a `reason` (400 otherwise).
  - It writes the decision with `UPDATE(req.subject)`, which bypasses the fields' `@readonly`.
  - CAP logs a startup warning that the action name `reject` shadows a method of `ApplicationService`. The action works. Renaming it to `rejectPO` would remove the warning.
- **Custom server** (`server.js`): on `bootstrap`, adds CORS that reflects the request origin and allows PATCH. Without it, the cross-origin UI5 app's preflight requests fail. On `listening`, it writes an empty `listening` marker file, which is gitignored.

## Persistence and auth gotchas

- The database is a file (`bookshop.sqlite`), not in-memory, so `cds watch` does **not** redeploy when you change the schema or CSVs. Run `npx cds deploy`, or restart `npm start`, after editing anything in `db/`. Deploying drops and recreates the model's tables, so it also wipes any approvals made through the app. It does not drop tables of entities that were removed from the model.
- In development, auth uses mocked basic-auth users defined in `package.json` under `cds.requires.auth`. Each user's password is the same as the name. `"*": false` turns off CAP's default mock users.
  - `alice` has `POViewer`.
  - `carol` has `POViewer` and `L1Approver`.
  - `dave` has `POViewer` and `L2Approver`.
  - `erin` has all three roles; use her to test the four-eyes rule.
  - `bob` has no roles.
  - Example: `curl -u alice:alice 'http://localhost:4004/odata/v4/po/PO?$expand=Vendor,Items'`.
- In production, the `[production]` profile uses XSUAA. `xs-security.json` (from `cds add xsuaa`) defines the roles `POViewer`, `L1Approver` and `L2Approver`. `@sap/xssec` is listed in `package.json` but was not installed when work paused, so run `npm install` first.
