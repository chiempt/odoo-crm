# Odoo CRM App Go/No-Go Recommendation

Validation date: 2026-03-25
Last updated at: 2026-03-25 15:48 ICT

## Decision

- Go for internal staging/demo rollout.
- No-go for production/business launch until release blockers are resolved and re-validated.

## Evidence

- Static checks: `flutter analyze` passed with no issues.
- Tests: `flutter test` passed (`test/widget_test.dart`).
- Integration contract exists: `docs/odoo_backend_contract.md`.
- Launch checklist exists: `docs/release-checklist.md`.
- Blockers are tracked as child tickets of `ODO-32` with owners and due dates.

## Production blockers with owner and target date

1. No mobile-safe backend adapter facade for auth/policy/rate-limits.
   - Ticket: ODO-34
   - Owner: Senior Odoo Engineer
   - Target date: 2026-03-28
2. No contract smoke test pack against staging Odoo.
   - Ticket: ODO-35
   - Owner: Senior Flutter Engineer
   - Target date: 2026-03-27
3. Session resilience is minimal (reactive logout on expiry).
   - Ticket: ODO-37
   - Owner: Senior Flutter Engineer
   - Target date: 2026-03-29

## Release gate recommendation

- Staging release: proceed now with production-like UAT in controlled audience.
- Production release: proceed only after blockers 1-3 are closed and UAT is re-run on the release candidate build.
