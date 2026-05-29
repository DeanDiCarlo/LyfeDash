create extension if not exists vector;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key text not null,
  date date not null,
  timezone_identifier text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, date_key)
);

create table public.metric_daily_aggregates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day_id uuid not null references public.days(id) on delete cascade,
  steps integer,
  sleep_minutes integer,
  screen_time_minutes integer,
  updated_at timestamptz not null default now(),
  unique (user_id, day_id)
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid not null,
  day_id uuid not null references public.days(id) on delete cascade,
  body text not null,
  latitude double precision,
  longitude double precision,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index journal_entries_user_client_id_idx
  on public.journal_entries (user_id, client_id);

create table public.task_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  recurrence text not null check (recurrence in ('daily', 'weekdays', 'weekly', 'adHoc')),
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.task_instances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  template_id uuid references public.task_templates(id) on delete set null,
  day_id uuid not null references public.days(id) on delete cascade,
  title_snapshot text not null,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day_id uuid not null references public.days(id) on delete cascade,
  kind text not null check (kind in ('image', 'video')),
  local_photo_asset_identifier text,
  storage_path text,
  thumbnail_storage_path text,
  captured_at timestamptz,
  duration_seconds double precision,
  latitude double precision,
  longitude double precision,
  ai_state text not null default 'notQueued' check (ai_state in ('notQueued', 'queued', 'processing', 'complete', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.location_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day_id uuid not null references public.days(id) on delete cascade,
  kind text not null check (kind in ('journal', 'photo', 'significantVisit', 'manualCheckIn')),
  latitude double precision not null,
  longitude double precision not null,
  horizontal_accuracy double precision,
  created_at timestamptz not null default now()
);

create table public.ai_artifacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  media_asset_id uuid references public.media_assets(id) on delete cascade,
  day_id uuid not null references public.days(id) on delete cascade,
  provider text not null,
  model text not null,
  caption text,
  tags text[] not null default '{}',
  -- V1 stores 768-dimensional embeddings to control vector storage and query cost.
  -- The backend worker must request the same output dimension from the active provider.
  embedding vector(768),
  processing_state text not null default 'queued' check (processing_state in ('queued', 'processing', 'complete', 'failed')),
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  unique (requester_id, addressee_id)
);

create table public.shared_day_permissions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  viewer_id uuid not null references auth.users(id) on delete cascade,
  day_id uuid not null references public.days(id) on delete cascade,
  can_view_media boolean not null default false,
  created_at timestamptz not null default now(),
  unique (viewer_id, day_id)
);

alter table public.profiles enable row level security;
alter table public.days enable row level security;
alter table public.metric_daily_aggregates enable row level security;
alter table public.journal_entries enable row level security;
alter table public.task_templates enable row level security;
alter table public.task_instances enable row level security;
alter table public.media_assets enable row level security;
alter table public.location_events enable row level security;
alter table public.ai_artifacts enable row level security;
alter table public.friendships enable row level security;
alter table public.shared_day_permissions enable row level security;

create policy "profiles are self owned" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "days are self owned" on public.days
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "metric aggregates are self owned" on public.metric_daily_aggregates
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "journal entries are self owned" on public.journal_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "task templates are self owned" on public.task_templates
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "task instances are self owned" on public.task_instances
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "media assets are self owned" on public.media_assets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "location events are self owned" on public.location_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "ai artifacts are self owned" on public.ai_artifacts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "friendship participants can read" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "users can request friendships" on public.friendships
  for insert with check (auth.uid() = requester_id);

create policy "share owners can manage permissions" on public.shared_day_permissions
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "share viewers can read permissions" on public.shared_day_permissions
  for select using (auth.uid() = viewer_id);

create index ai_artifacts_embedding_idx on public.ai_artifacts
  using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);
