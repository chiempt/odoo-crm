# Odoo CRM App Go/No-Go Recommendation

Validation date: 2026-03-25

## Decision

- Go for internal staging/demo rollout.
- No-go for production/business launch until backend hardening gaps are closed.

## Evidence

- Static checks: `flutter analyze` passed with no issues.
- Tests: `flutter test` passed (`test/widget_test.dart`).
- Integration contract exists: `docs/odoo_backend_contract.md`.
- Launch checklist exists: `docs/release-checklist.md`.

## Blocking gaps for production

1. Activity type IDs are hard-coded and not resolved dynamically.
2. No mobile-safe backend adapter facade for auth/policy/rate-limits.
3. No contract smoke test pack against staging Odoo.
4. Attachment contract is upload/list-only (download/delete incomplete).
5. Session resilience is minimal (reactive logout on expiry).

## Release gate recommendation

- Staging release: proceed now with production-like UAT.
- Production release: proceed only after items 1-3 are completed at minimum.
