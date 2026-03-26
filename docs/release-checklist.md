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
  - upload/download/delete attachments

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
- Download and delete one attachment.
- Open profile/settings and logout/login again (session persistence).

## 4) Quality gates

- `flutter analyze`
- `flutter test`
- Verify no crash on cold start and relaunch.

## 5) Android release identity & signing (required for Play Store)

- Production Android identifier:
  - `namespace`: `com.chiempt.odoocrm`
  - `applicationId`: `com.chiempt.odoocrm`
- Release builds require signing values from environment variables (or equivalent Gradle properties):
  - `ANDROID_RELEASE_STORE_FILE`
  - `ANDROID_RELEASE_STORE_PASSWORD`
  - `ANDROID_RELEASE_KEY_ALIAS`
  - `ANDROID_RELEASE_KEY_PASSWORD`
- Do not use debug signing for production. The build is configured to fail for release tasks when any signing value is missing.

Example local release command:

```bash
export ANDROID_RELEASE_STORE_FILE=/absolute/path/to/upload-keystore.jks
export ANDROID_RELEASE_STORE_PASSWORD='***'
export ANDROID_RELEASE_KEY_ALIAS='upload'
export ANDROID_RELEASE_KEY_PASSWORD='***'

flutter build appbundle --release
```

Production mode policy:

- Use `--release` only.
- Do not introduce build flavors unless there is a clear product requirement.
- Prefer one canonical command for repeatability:

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=ODOO_DEFAULT_URL=https://your-odoo.example.com \
  --dart-define=ODOO_DEFAULT_DB=odoo_prod \
  --dart-define=ODOO_REQUIRE_HTTPS=true
```

## 6) Release operations

- Tag release version (`pubspec.yaml`).
- Build artifact:
  - Android: `flutter build appbundle --release`
  - iOS: `flutter build ios --release`
- Publish internal changelog with known limitations.

## 7) Rollback plan

- Keep previous stable app binary available.
- Keep previous API/base URL settings documented.
- If severe auth/API regression appears, rollback app build first, then investigate server-side changes.

## 8) Go/No-Go sign-off

- Final release decision document: `docs/go-no-go.md`.
- Staging/demo can proceed when sections 1-5 are green.
- Production launch requires explicit sign-off after production blockers in `docs/go-no-go.md` are closed.
