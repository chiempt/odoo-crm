# Odoo CRM Integration Contract

This app integrates with Odoo over JSON-RPC and authenticated `session_id` cookie.

## Backend prerequisites

- Odoo reachable from app network (public host or VPN).
- Valid SSL certificate for production (`https`).
- Database exists and user has CRM access.
- Installed Odoo apps/modules:
  - `crm`
  - `mail`
  - `utm` (for campaign/source lookups)

## Authentication flow

1. App calls `POST /web/session/authenticate` with `{ db, login, password }`.
2. Session is extracted from:
  - `result.session_id` (preferred), or
  - `set-cookie` header fallback.
3. Session is attached on subsequent calls as:
  - `Cookie: session_id=<value>`
  - `X-Openerp-Session-Id: <value>`

## RPC routes used

- `POST /web/dataset/call_kw` for model operations:
  - `crm.lead`: `search_read`, `read`, `create`, `write`, `unlink`, stage/lifecycle actions.
  - `crm.stage`: `search_read`.
  - `mail.activity`: `search_read`, `create`.
  - `mail.message`: `search_read`.
  - `mail.followers`: `search_read`.
  - `ir.attachment`: `search_read`, `create`.
  - `res.users`: `search_read`.
  - `res.partner`: `search_read`.
  - `crm.tag`, `utm.source`, `utm.campaign`: lookup/create helpers.
- `POST /web/database/list` to discover DB names in login step.

## Session-expiry behavior

App detects Odoo session expiration from JSON-RPC errors and triggers global logout.

## Environment/runtime settings

Provided via Flutter `--dart-define`:

- `ODOO_DEFAULT_URL`
- `ODOO_DEFAULT_DB`
- `ODOO_REQUIRE_HTTPS` (default `true`)

## Production notes

- Do not hardcode credentials in app code.
- Prefer HTTPS-only instances in production.
- Validate CRM ACLs with a least-privilege user profile before launch.
