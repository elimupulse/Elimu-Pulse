# Security

- Browser code contains only the Supabase project URL and publishable key. Never add a service-role/secret key.
- Multi-school membership is stored in `public.school_users`; each user is assigned to one school.
- `public.school_state` has a row per school and RLS policies check active membership on every read, insert and update.
- School accounts are owner-provisioned. There is no public registration flow.
- The SQL migration revokes browser access to the old `school_state_shared` table, which used permissive shared-data policies.
- Back up and deliberately migrate legacy data only after confirming which school owns it.
- Test tenant isolation using at least two schools before storing real learner data.
- Protect Auth accounts, use strong unique passwords, and avoid committing real learner/staff information to a public repository.


## Global administration and tenant isolation
- Global admin access is granted only by a row in `public.global_admins`; the app checks it through `public.is_global_admin()`.
- Do not treat an email address, client-side variable, or UI role as authorization.
- Run `supabase-global-admin-migration.sql` only after a database backup.
- The migration is additive and does not alter `school_state_shared`, including `ELIMU_PULSE`.
- Test with fake schools/users before importing learner data. Do not call the application production-audited until the cross-school tests pass.
