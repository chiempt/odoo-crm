# Odoo CRM App (Flutter)

Mobile-first CRM client for Odoo JSON-RPC.

## Run locally

```bash
flutter pub get
flutter run \
  --dart-define=ODOO_DEFAULT_URL=https://your-odoo.example.com \
  --dart-define=ODOO_DEFAULT_DB=odoo_prod \
  --dart-define=ODOO_REQUIRE_HTTPS=true
```

## Runtime config

Use `--dart-define` values at build/run time:

- `ODOO_DEFAULT_URL`: prefilled login URL.
- `ODOO_DEFAULT_DB`: default database when auto-listing DBs is disabled.
- `ODOO_REQUIRE_HTTPS`: `true` by default. Set to `false` only for local/dev HTTP.

## Integration and release docs

- Odoo API integration details: [`ODOO_CRM_INTEGRATION.md`](./ODOO_CRM_INTEGRATION.md)
- Launch checklist: [`docs/release-checklist.md`](./docs/release-checklist.md)
- Go/No-Go recommendation: [`docs/go-no-go.md`](./docs/go-no-go.md)
