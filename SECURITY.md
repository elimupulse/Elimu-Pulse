# Security

- Supabase Authentication controls sign-in.
- Browser code must contain only the project's publishable/anon key; never a service-role key.
- Configure a new Supabase project. This build intentionally has no Kapnanda backend credentials.
- The inherited schema uses one shared state row and authenticated-user policies. This is not sufficient isolation for multiple schools.
- Create only authorised staff accounts.
- Do not publish real learner or staff data in a public repository.
- Before production, implement school-tenant isolation, role-based permissions and restrictive RLS policies; test with accounts from different schools.
