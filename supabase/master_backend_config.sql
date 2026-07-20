-- Run this on the MASTER Supabase project.
-- Mobile apps and the website read the active URL + anon key from the public
-- view. Admin writes through the service-role key from the web server only.

create table if not exists public.backend_runtime_config (
  id uuid primary key default gen_random_uuid(),
  label text not null default 'production',
  supabase_url text not null,
  supabase_anon_key text not null,
  supabase_service_role_key text,
  is_active boolean not null default false,
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint backend_runtime_config_url_check
    check (supabase_url ~ '^https?://[^[:space:]]+$'),
  constraint backend_runtime_config_anon_key_check
    check (length(trim(supabase_anon_key)) > 20)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists backend_runtime_config_set_updated_at
on public.backend_runtime_config;

create trigger backend_runtime_config_set_updated_at
before update on public.backend_runtime_config
for each row execute function public.set_updated_at();

create unique index if not exists one_active_backend_runtime_config
on public.backend_runtime_config ((is_active))
where is_active = true;

create or replace view public.public_backend_runtime_config as
select
  supabase_url,
  supabase_anon_key,
  updated_at
from public.backend_runtime_config
where is_active = true
order by updated_at desc
limit 1;

alter table public.backend_runtime_config enable row level security;

drop policy if exists "Public can read active backend runtime config"
on public.backend_runtime_config;

create policy "Public can read active backend runtime config"
on public.backend_runtime_config
for select
using (is_active = true);

-- Optional seed. Replace before use.
-- insert into public.backend_runtime_config (
--   label,
--   supabase_url,
--   supabase_anon_key,
--   supabase_service_role_key,
--   is_active,
--   updated_by
-- ) values (
--   'production',
--   'https://your-target-project.supabase.co',
--   'your-target-anon-key',
--   'your-target-service-role-key',
--   true,
--   'initial'
-- );
