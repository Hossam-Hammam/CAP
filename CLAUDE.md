# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A SAP CAP backend (Node.js, `@sap/cds` 9, SQLite) that serves purchase-order data over OData V4 to a separate UI5 approval app. The UI5 app is not in this repo. The project is still called `bookshop` and the service class is still `BooksService`, but the domain is purchase orders. The original Books/Authors/Orders sample entities have been removed.

## Commands

- `npm start`: runs `cds deploy` (as `prestart`), then `cds watch`. The server listens on http://localhost:4004, with the service at `/odata/v4/bookshop/`.
- `npx cds deploy`: rebuilds `bookshop.sqlite` from `db/schema.cds` and the CSVs in `db/data/`.
- `npx eslint .`: lints the project. The config extends `cds.recommended`.
- `npx cds compile srv --to serviceinfo`: shows which services are served and at which paths.

There are no tests and no `test` script yet. `@cap-js/cds-test` is installed as a dev dependency. The `[testing]` profile uses the same `bookshop.sqlite` file as `[development]`.

## Architecture

- **Model** (`db/schema.cds`, namespace `org.hossam`): `PO` is the header, and it composes many `Items` through `PONumber`. `Items.PO` is the association back to the header. All keys are strings, and item numbers are zero-padded, e.g. `0010`. Dates are stored as `String`, not `Date`. `L1Approve` and `L2Approve` are strings holding `TRUE` or empty. They are the approval fields the UI5 app PATCHes.
- **Seed data**: `db/data/org.hossam-<Entity>.csv` is loaded by `cds deploy`. `db/data/POData.json` is left over from an older flat `POItems` shape. CAP does not load it.
- **Service** (`srv/main.cds`): exposes `PO` and `Items` as projections guarded by `@requires: 'POViewer'`. Requests without a signed-in user get 401, and signed-in users without the role get 403. `userInfo()` requires only an authenticated user. The UI5 app calls it at startup to get the user id and check whether the user has `POViewer`. CAP loads `srv/main.js` as the implementation because it has the same base name as the `.cds` file.
- **Custom server** (`server.js`): on `bootstrap`, adds CORS that reflects the request origin and allows PATCH. Without it, the cross-origin UI5 app's preflight requests fail. On `listening`, it writes an empty `listening` marker file, which is gitignored.

## Persistence and auth gotchas

- The database is a file (`bookshop.sqlite`), not in-memory, so `cds watch` does **not** redeploy when you change the schema or CSVs. Run `npx cds deploy`, or restart `npm start`, after editing anything in `db/`. Deploying drops and recreates the tables, so it also wipes any approvals made through the app.
- In development, auth uses mocked basic-auth users defined in `package.json` under `cds.requires.auth`. `alice`/`alice` has `POViewer`. `bob`/`bob` has no roles. `"*": false` turns off CAP's default mock users. Example: `curl -u alice:alice 'http://localhost:4004/odata/v4/bookshop/PO?$expand=Items'`.
