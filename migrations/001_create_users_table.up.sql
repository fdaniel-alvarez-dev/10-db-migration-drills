create table if not exists public.users (
  id bigserial primary key,
  username text not null unique,
  created_at timestamptz not null default now()
);

