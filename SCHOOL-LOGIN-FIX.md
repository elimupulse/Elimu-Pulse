# School administrator login fix

## What changed
- School login now looks up `school_users` first and `schools` separately rather than relying on an embedded PostgREST relation (`schools(name)`). This avoids a common RLS/relationship-join failure that can reject otherwise valid school administrator accounts.
- Login now reports whether the membership is missing, the school row cannot be read, or the school is paused.
- Added the Platform Admin Edge Function at the conventional Supabase CLI path `supabase/functions/platform-admin/index.ts` (the original source is retained).

## Deploy
1. Replace the deployed static site's `app.js` with this version.
2. Ensure the `supabase-multischool-schema.sql`, `supabase-global-admin-migration.sql`, and `supabase-platform-admin-migration.sql` migrations have been run in the same Supabase project used by `app.js`.
3. Deploy the function from the project root with:
   `supabase functions deploy platform-admin`
4. In Supabase Authentication > Users, verify each school administrator exists. Then verify that user's UUID has exactly one active row in `public.school_users` with the correct `school_id` and `role='school_admin'`.
5. Test with the school administrator's own email and password, not the Global Administrator credentials.

This patch does not alter or delete learner records or school data. It does not change Supabase credentials or database contents.
