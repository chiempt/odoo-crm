# Staging Contract Smoke Test

This smoke test validates the current mobile contract directly against a staging Odoo instance.

Covered flows:

- login (`/web/session/authenticate`)
- lead CRUD (`crm.lead`)
- stage transition (`crm.stage` + `crm.lead.write`)
- activity creation (`mail.activity`)
- chatter note post (`crm.lead.message_post`)
- attachment upload/list (`ir.attachment`)

## Prerequisites

- Staging Odoo URL/database/user/password with CRM permissions.
- Models available in staging: `crm.lead`, `crm.stage`, `mail.activity`, `mail.activity.type`, `mail.message`, `ir.attachment`.
- Flutter/Dart dependencies installed:

```bash
flutter pub get
```

## Run

From `odoo-crm-app/`:

```bash
export ODOO_SMOKE_BASE_URL="https://your-staging-odoo.example.com"
export ODOO_SMOKE_DB="staging_db"
export ODOO_SMOKE_LOGIN="qa.user@example.com"
export ODOO_SMOKE_PASSWORD="your-password"

dart run tool/odoo_contract_smoke.dart
```

## Expected Output

Successful run prints all steps with `[OK]`, ending with:

```text
[OK] Contract smoke test PASSED
```

If any step fails, the script exits with status `1`, logs `[FAIL]`, and attempts cleanup by deleting any test lead it created.
