-- =====================================================================
-- Mandala · il Cerchio: pensieri, impressioni dopo la lezione,
-- pratiche e mandala condivisi dalle allieve, con il fiore di loto.
-- Richiede 08-blog-e-pausa.sql (usa la funzione firma_commento).
-- Si può rieseguire senza danni.
-- =====================================================================

create table if not exists public.cerchio (
  id uuid primary key default gen_random_uuid(),
  autore uuid not null default auth.uid(),
  nome text,                         -- lo scrive il database, non l'app
  insegnante boolean not null default false,
  tipo text not null check (tipo in ('pensiero','impressione','pratica','mandala')),
  testo text check (testo is null or char_length(testo) <= 1000),
  dati jsonb not null default '{}'::jsonb check (pg_column_size(dati) < 20000),
  creato timestamptz not null default now(),
  check (tipo in ('pratica','mandala') or char_length(btrim(coalesce(testo,''))) > 0)
);
create index if not exists cerchio_creato on public.cerchio (creato desc);

-- Nome (primo nome dell'allieva, "Tiziana" per l'insegnante), autore e data li mette il database.
drop trigger if exists cerchio_firma on public.cerchio;
create trigger cerchio_firma before insert on public.cerchio
  for each row execute function public.firma_commento();

alter table public.cerchio enable row level security;
drop policy if exists "allieve leggono il cerchio" on public.cerchio;
create policy "allieve leggono il cerchio" on public.cerchio for select to authenticated
  using (public.is_member());
drop policy if exists "allieve scrivono nel cerchio" on public.cerchio;
create policy "allieve scrivono nel cerchio" on public.cerchio for insert to authenticated
  with check (public.is_member());
drop policy if exists "ognuna toglie i suoi, l'insegnante tutti" on public.cerchio;
create policy "ognuna toglie i suoi, l'insegnante tutti" on public.cerchio for delete to authenticated
  using (autore = auth.uid() or public.is_admin());

-- Fiori di loto alle voci del Cerchio: uno per persona e voce.
create table if not exists public.cerchio_loti (
  post_id uuid not null references public.cerchio(id) on delete cascade,
  autore uuid not null default auth.uid(),
  creato timestamptz not null default now(),
  primary key (post_id, autore)
);
alter table public.cerchio_loti enable row level security;
drop policy if exists "allieve vedono i loti del cerchio" on public.cerchio_loti;
create policy "allieve vedono i loti del cerchio" on public.cerchio_loti for select to authenticated
  using (public.is_member());
drop policy if exists "ognuna mette il suo loto" on public.cerchio_loti;
create policy "ognuna mette il suo loto" on public.cerchio_loti for insert to authenticated
  with check (public.is_member() and autore = auth.uid());
drop policy if exists "ognuna toglie il suo loto" on public.cerchio_loti;
create policy "ognuna toglie il suo loto" on public.cerchio_loti for delete to authenticated
  using (autore = auth.uid());

select (select count(*) from public.cerchio) as voci, (select count(*) from public.cerchio_loti) as loti;
