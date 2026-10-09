# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A SAP CAP backend (Node.js, `@sap/cds` 9, SQLite) that serves purchase-order data over OData V4 to a separate UI5 approval app. The UI5 app is not in this repo. The npm project is still called `bookshop`, but the domain is purchase orders: the service and its implementation class are both `POService`.

The project is being refactored step by step from a plan in https://claude.ai/artifact/KTEYQLmiPu2F7sYAc9ZyBV (read it with the Artifact tool). Stages 0 and 1 are done. The next stage replaces PATCHing approval fields with bound actions. The UI5 app is updated only after the refactoring, so until then it still calls the old `/odata/v4/bookshop/` URL and the old field names.

## Commands

- `npm start`: runs `cds deploy` (as `prestart`), then `cds watch`. The server listens on http://localhost:4004, with the service at `/odata/v4/po/`. CAP builds that path from the service name `POService`, so renaming the service changes the URL.
- `npx cds deploy`: rebuilds `bookshop.sqlite` from `db/schema.cds` and the CSVs in `db/data/`.
- `npx eslint .`: lints the project. The config extends `cds.recommended`.
- `npx cds compile srv --to serviceinfo`: shows which services are served and at which paths.

There are no tests and no `test` script yet. `@cap-js/cds-test` is installed as a dev dependency. Tests must start the server with `cds.test(__dirname + '/..', '--in-memory')`. Without `--in-memory` they run in the `development` profile and write into the real `bookshop.sqlite`.

## Architecture

- **Model** (`db/schema.cds`, namespace `org.hossam`):
  - `PO` (key `PONumber`) is the header. It uses the `managed` aspect, so it has `createdAt/By` and `modifiedAt/By`.
  - `PO` composes many `Items` through `Items.PO = $self`. `Items` has a two-part key: the managed association `PO` (column `PO_PONumber`) and `Item`, a zero-padded string such as `0010`.
  - `PO.Vendor`, `Items.Material` and `Items.Plant` are managed associations to the master-data entities `Vendors`, `Materials` and `Plants`, each keyed by `ID`.
  - `OrderDate` and `DeliveryDate` are `Date`. `Currency` is the common `Currency` type, stored in the column `Currency_code`.
  - `L1Approve` and `L2Approve` are `Boolean`: `null` means pending, `true` approved, `false` rejected. `L1By`, `L1Date`, `L2By`, `L2Date` and `RejectReason` record each decision.
- **`using` line**: `using { Currency, managed } from '@sap/cds-common-content'` imports both definitions, because that package loads `@sap/cds/common`. It also adds the package's currency list data to the model. Importing from `@sap/cds/common` alone would leave `sap_common_Currencies` empty.
- **Seed data**: `cds deploy` loads `db/data/org.hossam-<Entity>.csv`. CSV headers use the generated foreign key columns (`Vendor_ID`, `PO_PONumber`, `Material_ID`, `Plant_ID`, `Currency_code`), ISO dates and lowercase `true`/`false`. An empty value means `null`.
- **Service** (`srv/main.cds`):
  - `POService` exposes `PO` and `Items` under `@requires: 'POViewer'`. `PO` adds the flat field `VendorName` (`Vendor.Name`).
  - It exposes `Vendors`, `Materials` and `Plants` as `@readonly` under the same role.
  - Requests without a signed-in user get 401, and signed-in users without the role get 403.
  - `userInfo()` requires only an authenticated user. The UI5 app calls it at startup to get the user id and check whether the user has `POViewer`.
  - CAP loads `srv/main.js` as the implementation because it has the same base name as the `.cds` file.
- **Custom server** (`server.js`): on `bootstrap`, adds CORS that reflects the request origin and allows PATCH. Without it, the cross-origin UI5 app's preflight requests fail. On `listening`, it writes an empty `listening` marker file, which is gitignored.

## Persistence and auth gotchas

- The database is a file (`bookshop.sqlite`), not in-memory, so `cds watch` does **not** redeploy when you change the schema or CSVs. Run `npx cds deploy`, or restart `npm start`, after editing anything in `db/`. Deploying drops and recreates the model's tables, so it also wipes any approvals made through the app. It does not drop tables of entities that were removed from the model.
- In development, auth uses mocked basic-auth users defined in `package.json` under `cds.requires.auth`. `alice`/`alice` has `POViewer`. `bob`/`bob` has no roles. `"*": false` turns off CAP's default mock users. Example: `curl -u alice:alice 'http://localhost:4004/odata/v4/po/PO?$expand=Vendor,Items'`.
