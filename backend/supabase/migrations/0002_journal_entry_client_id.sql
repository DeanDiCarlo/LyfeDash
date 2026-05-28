alter table public.journal_entries
  add column if not exists client_id uuid;

update public.journal_entries
set client_id = gen_random_uuid()
where client_id is null;

alter table public.journal_entries
  alter column client_id set not null;

create unique index if not exists journal_entries_user_client_id_idx
  on public.journal_entries (user_id, client_id);
