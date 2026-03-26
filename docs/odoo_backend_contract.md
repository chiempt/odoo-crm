# Odoo Backend Contract for Mobile CRM

## Scope

This document defines the backend contract expected by the mobile CRM app for these flows:

- Auth and session
- Leads and deals (`crm.lead`)
- Activities (`mail.activity`)
- Messages/followers (`mail.message`, `mail.followers`)
- Attachments (`ir.attachment`)

Validation date: 2026-03-25.
Source of truth for current implementation: `lib/core/services/api_service.dart`, `lib/core/services/odoo_crm_service.dart`, `lib/features/authentication/providers/auth_provider.dart`, `lib/features/crm/providers/crm_provider.dart`.

## Current Wire Contract (Implemented)

### A. Auth/session

1. `POST /web/session/authenticate` (JSON-RPC)
   - params: `db`, `login`, `password`
   - expected response: `result.uid`, and session id from `result.session_id` or `set-cookie`
2. Session is reused as cookie for all later RPC calls:
   - `Cookie: session_id=<value>`
   - `X-Openerp-Session-Id: <value>`

### B. Generic RPC endpoint

All CRUD/actions use:

- `POST /web/dataset/call_kw`
- envelope:
  - `jsonrpc: "2.0"`
  - `method: "call"`
  - `params: { model, method, args, kwargs }`

### C. Model/method usage by flow

1. Leads/deals (`crm.lead`)
   - `search_read` (list)
   - `read` (detail)
   - `create`
   - `write`
   - `unlink`
   - `convert_opportunity`
   - `action_set_won`
   - `action_set_lost`
   - `message_post`
2. Stages (`crm.stage`)
   - `search_read`
3. Activities (`mail.activity`)
   - `search_read`
   - `create`
4. Message timeline (`mail.message`)
   - `search_read`
5. Followers
   - `mail.followers.search_read`
   - `crm.lead.message_subscribe`
   - `crm.lead.message_unsubscribe`
6. Attachments (`ir.attachment`)
   - `search_read`
   - `create` (base64 upload)
   - `read` (base64 download payload)
   - `unlink` (delete with record ownership check in app)
7. Lookup/supporting records
   - `res.users.search_read`
   - `res.partner.search_read`
   - `crm.tag.search_read/create` (ensure tags)
   - `utm.source.search_read/create`
   - `utm.campaign.search_read/create`

## Required Odoo Modules and Data

## Must be installed

- `crm`
- `mail`
- `utm`

## Must exist/configured

- At least one sales team for assigned opportunities
- Activity types expected by app (currently assumes IDs 1/2/3)
- User accounts with CRM access

## Required fields consumed by app

`crm.lead` (minimum):

- `id`, `name`, `type`, `stage_id`, `user_id`, `team_id`, `expected_revenue`, `probability`
- `partner_id`, `partner_name`, `contact_name`, `email_from`, `phone`, `mobile`
- `date_deadline`, `date_closed`, `priority`, `description`, `tag_ids`
- `activity_ids`, `message_ids`, `create_date`, `write_date`, `active`

## Permissions Contract (Required)

For mobile user role/group, grant model ACL + record rules for:

- `crm.lead` (read/create/write; delete optional by policy)
- `crm.stage` (read)
- `mail.activity` (read/create/write for own activities)
- `mail.message` (read/create via `message_post`)
- `mail.followers` (read)
- `ir.attachment` (read/create/unlink for linked `crm.lead`)
- `res.users` (read basic fields)
- `res.partner` (read; write optional)
- `crm.tag`, `utm.source`, `utm.campaign` (read/create if app can create missing values)

## Validation: Exists vs Missing

### Exists in current app/backend contract

- Session authenticate and cookie-based JSON-RPC
- Lead/deal CRUD and state actions (won/lost/convert)
- Activity list/create
- Lead message post + timeline read
- Follower list/add/remove
- Attachment list/upload
- Attachment download/delete
- User/partner lookup

### Missing or risky for production mobile rollout

1. No dedicated mobile-safe backend adapter
   - risk: direct DB/login credentials in app, limited policy/observability/rate-limiting
2. Attachment download/delete requires ACL alignment in staging/prod
   - app now enforces record ownership (`res_model` + `res_id`) before read/unlink
3. No contract test suite against target Odoo instance
   - failures will appear late during app QA
4. No explicit permission bootstrap document/script
   - onboarding a new Odoo database is error-prone
5. Session lifecycle handling is minimal (logout on expiry only)
   - no refresh/check endpoint strategy for proactive UX

## Recommended Implementation Tasks (with estimates)

1. Permission profile + setup script
   - Implement: security checklist + optional XML/data script for required groups/ACL/rules
   - Estimate: 0.5 day
2. Backend adapter facade (preferred for production)
   - Implement: thin Odoo module/controller or gateway endpoint set for mobile operations
   - Benefits: hide DB auth details, centralized validation/logging/rate limits
   - Estimate: 2-3 days
3. Attachment completion
   - Implemented 2026-03-25: download + delete flows with record ownership checks
   - Estimate: 0.5-1 day
4. Contract test pack
   - Implement: smoke tests for auth, lead CRUD, activities, followers, attachments against staging Odoo
   - Estimate: 1-1.5 days
5. Session resilience
   - Implement: explicit session check/re-auth UX path + retry guard for idempotent reads
   - Estimate: 0.5 day

Total estimated effort: 4.5-6.5 days (single engineer), excluding deployment approvals.

## Migration notes (ODO-33)

- Date: 2026-03-25
- `mail.activity` creation no longer uses hard-coded IDs (`1/2/3`).
- Mobile client now resolves activity types from `mail.activity.type` by semantic key/name (`call`, `meeting`, `email`, `todo`) and caches the mapping in-session.
- Existing create/edit flows remain compatible:
  - explicit `activityTypeId` continues to work unchanged
  - callers can pass `activityTypeKey` to resolve environment-specific IDs dynamically
- If no semantic match exists, client falls back to the first available `mail.activity.type` by sequence.

## Decision

Current contract is enough for internal demo/staging if Odoo modules/ACL are aligned.
For business-ready rollout, prioritize tasks 1-3 first (ACL bootstrap, backend adapter facade, attachment completion).
