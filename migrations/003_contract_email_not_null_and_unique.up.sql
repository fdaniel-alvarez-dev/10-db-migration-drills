-- Contract phase: only safe after application writes email for all rows.
-- This migration is intentionally explicit and may fail if preconditions are not met.
do $$
begin
  if exists (select 1 from public.users where email is null) then
    raise exception 'precondition failed: users.email contains NULLs (run a backfill before contracting)';
  end if;
end $$;

alter table public.users
  alter column email set not null;

create unique index if not exists users_email_unique_idx on public.users (email);

