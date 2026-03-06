drop index if exists public.users_email_unique_idx;

alter table public.users
  alter column email drop not null;

