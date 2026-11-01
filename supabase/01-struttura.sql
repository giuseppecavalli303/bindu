-- =====================================================================
-- Bindu · struttura del database e regole di sicurezza
-- Da incollare ed eseguire UNA volta in Supabase → SQL Editor → Run.
-- Si può rieseguire senza danni: non cancella i dati.
-- =====================================================================

-- Insegnanti: possono scrivere contenuti e gestire le allieve.
create table if not exists public.admins (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  telefono text unique,          -- solo cifre, con prefisso: 393331234567
  check (email is not null or telefono is not null)
);

-- Allieve invitate: solo chi è qui può entrare.
create table if not exists public.allieve (
  id uuid primary key default gen_random_uuid(),
  nome text,
  email text unique,
  telefono text unique,          -- solo cifre, con prefisso: 393331234567
  aggiunta timestamptz not null default now(),
  check (email is not null or telefono is not null)
);

-- Temi del mese.
create table if not exists public.temi (
  id uuid primary key default gen_random_uuid(),
  sezione text not null check (sezione in ('yoga','posturale','mindfulness')),
  mese text not null check (mese ~ '^[0-9]{4}-[0-9]{2}$'),
  titolo text not null,
  sottotitolo text,
  testo text,
  approfondimenti jsonb not null default '[]'::jsonb,
  esempio boolean not null default false,
  creato timestamptz not null default now(),
  aggiornato timestamptz not null default now()
);

-- Video, meditazioni audio, articoli e lezioni dal vivo.
create table if not exists public.contenuti (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('video','audio','articolo','diretta')),
  sezione text not null check (sezione in ('yoga','posturale','mindfulness')),
  mese text not null check (mese ~ '^[0-9]{4}-[0-9]{2}$'),
  titolo text not null,
  descrizione text,
  testo text,
  durata text,
  livello text,
  link text,
  file text,                     -- percorso del file nello spazio "media"
  settimana int check (settimana between 1 and 4),
  quando text,                   -- data e ora della lezione dal vivo: 2026-11-06T18:30
  dove text,
  esempio boolean not null default false,
  creato timestamptz not null default now(),
  aggiornato timestamptz not null default now()
);

-- Le pratiche di ogni allieva (il suo mandala). Ognuna vede solo le sue.
create table if not exists public.pratiche (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  chiave text not null,
  at timestamptz not null default now(),
  mese text not null,
  sezione text,
  titolo text,
  primary key (user_id, chiave)
);

-- Chi sta usando il sito? (email o telefono dell'accesso)
create or replace function public.mia_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;
create or replace function public.mio_telefono() returns text
language sql stable as $$ select regexp_replace(coalesce(auth.jwt() ->> 'phone', ''), '[^0-9]', '', 'g') $$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admins a
    where (a.email is not null and lower(a.email) = public.mia_email() and public.mia_email() <> '')
       or (a.telefono is not null and a.telefono = public.mio_telefono() and public.mio_telefono() <> '')
  );
$$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists (
    select 1 from public.allieve a
    where (a.email is not null and lower(a.email) = public.mia_email() and public.mia_email() <> '')
       or (a.telefono is not null and a.telefono = public.mio_telefono() and public.mio_telefono() <> '')
  );
$$;

revoke all on function public.is_admin() from public, anon;
revoke all on function public.is_member() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_member() to authenticated;

-- Regole di sicurezza (Row Level Security)
alter table public.admins    enable row level security;
alter table public.allieve   enable row level security;
alter table public.temi      enable row level security;
alter table public.contenuti enable row level security;
alter table public.pratiche  enable row level security;

drop policy if exists "insegnante vede se stessa" on public.admins;
create policy "insegnante vede se stessa" on public.admins for select to authenticated using (public.is_admin());

drop policy if exists "lettura elenco allieve" on public.allieve;
create policy "lettura elenco allieve" on public.allieve for select to authenticated using (public.is_admin());
drop policy if exists "insegnante gestisce allieve" on public.allieve;
create policy "insegnante gestisce allieve" on public.allieve for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "allieve leggono i temi" on public.temi;
create policy "allieve leggono i temi" on public.temi for select to authenticated using (public.is_member());
drop policy if exists "insegnante scrive i temi" on public.temi;
create policy "insegnante scrive i temi" on public.temi for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "allieve leggono i contenuti" on public.contenuti;
create policy "allieve leggono i contenuti" on public.contenuti for select to authenticated using (public.is_member());
drop policy if exists "insegnante scrive i contenuti" on public.contenuti;
create policy "insegnante scrive i contenuti" on public.contenuti for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "ognuna le sue pratiche" on public.pratiche;
create policy "ognuna le sue pratiche" on public.pratiche for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid() and public.is_member());

-- Spazio privato per i file (audio e video brevi), massimo 50 MB a file.
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', false, 52428800)
on conflict (id) do nothing;

drop policy if exists "allieve ascoltano i file" on storage.objects;
create policy "allieve ascoltano i file" on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.is_member());
drop policy if exists "insegnante carica i file" on storage.objects;
create policy "insegnante carica i file" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_admin());
drop policy if exists "insegnante aggiorna i file" on storage.objects;
create policy "insegnante aggiorna i file" on storage.objects for update to authenticated
  using (bucket_id = 'media' and public.is_admin());
drop policy if exists "insegnante elimina i file" on storage.objects;
create policy "insegnante elimina i file" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.is_admin());
