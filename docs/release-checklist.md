# Odoo CRM App Launch Checklist

## 1) Backend/API fit

- Confirm target Odoo version and environment URL.
- Verify auth endpoint returns session:
  - `POST /web/session/authenticate`
- Verify JSON-RPC access for required models:
  - `crm.lead`, `crm.stage`, `mail.activity`, `mail.message`
  - `mail.followers`, `ir.attachment`, `res.users`, `res.partner`
  - `crm.tag`, `utm.source`, `utm.campaign`
- Validate user ACLs:
  - read/write leads
  - schedule activities
  - post chatter notes
  - upload attachments

## 2) App env config

- Build/run with required defines:

```bash
flutter run \
  --dart-define=ODOO_DEFAULT_URL=https://your-odoo.example.com \
  --dart-define=ODOO_DEFAULT_DB=odoo_prod \
  --dart-define=ODOO_REQUIRE_HTTPS=true
```

- Ensure `ODOO_REQUIRE_HTTPS=true` for staging/production.
- Ensure default URL/database values match deployment docs.

## 3) Functional smoke test

- Login with production-like user.
- Load leads list and open a lead detail.
- Create/update/delete a lead.
- Move lead through pipeline stage.
- Create activity and message note.
- Upload one attachment.
- Open profile/settings and logout/login again (session persistence).

## 4) Quality gates

- `flutter analyze`
- `flutter test`
- Verify no crash on cold start and relaunch.

## 5) Release operations

- Tag release version (`pubspec.yaml`).
- Build artifact:
  - Android: `flutter build apk --release`
  - iOS: `flutter build ios --release`
- Publish internal changelog with known limitations.

## 6) Rollback plan

- Keep previous stable app binary available.
- Keep previous API/base URL settings documented.
- If severe auth/API regression appears, rollback app build first, then investigate server-side changes.

## 7) Go/No-Go sign-off

- Final release decision document: `docs/go-no-go.md`.
- Staging/demo can proceed when sections 1-5 are green.
- Production launch requires explicit sign-off after production blockers in `docs/go-no-go.md` are closed.
