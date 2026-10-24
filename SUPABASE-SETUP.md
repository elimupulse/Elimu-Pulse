# Supabase Setup for Elimu Pulse

1. Create a new Supabase project for Elimu Pulse. Do not reuse the original Kapnanda project.
2. Run `supabase-schema.sql` in the SQL Editor.
3. In `app.js`, configure the Supabase project URL and publishable/anon key in the cloud config.
4. Create staff accounts under Authentication → Users.
5. Verify an unauthenticated browser cannot read `school_state_shared`.
6. Verify authorised staff can sign in and the initial `ELIMU_PULSE` record contains empty `learners` and `teachers` arrays.

Never place the Supabase service-role key in browser JavaScript.

**Multi-school warning:** this inherited data model uses one shared school-state row and permissive authenticated-user policies. Do not use it as a multi-school SaaS deployment without implementing and testing tenant isolation and least-privilege RLS first.
