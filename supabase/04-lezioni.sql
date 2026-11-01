-- =====================================================================
-- Bindu · lezioni registrate dell'anno scolastico (da Google Drive)
-- Le scrive in automatico il programma google/bindu-drive.gs, che legge le
-- cartelle "Lezioni di Yoga online" e "Lezioni di Posturale online".
-- Le allieve le vedono solo da ottobre a giugno e solo per l'anno in corso.
-- Si può rieseguire senza danni.
-- =====================================================================

create table if not exists public.lezioni (
  drive_id text primary key,                 -- codice del file su Google Drive
  sezione text not null check (sezione in ('yoga','posturale')),
  titolo text not null,
  link text not null,                        -- https://drive.google.com/file/d/<id>/view
  durata text,                               -- es. "58 min"
  mese text not null check (mese ~ '^[0-9]{4}-[0-9]{2}$'),   -- mese della lezione
  anno text not null check (anno ~ '^[0-9]{4}-[0-9]{2}$'),   -- anno scolastico, es. "2026-27"
  caricata timestamptz not null,             -- quando il file è arrivato su Drive
  aggiornato timestamptz not null default now()
);

-- Anno scolastico di una data: dal 1° luglio inizia il successivo (ora italiana).
create or replace function public.anno_scolastico(d timestamptz) returns text
language sql stable as $$
  select case when extract(month from d at time zone 'Europe/Rome') >= 7
    then to_char(d at time zone 'Europe/Rome', 'YYYY') || '-' || lpad(((extract(year from d at time zone 'Europe/Rome')::int + 1) % 100)::text, 2, '0')
    else (extract(year from d at time zone 'Europe/Rome')::int - 1)::text || '-' || to_char(d at time zone 'Europe/Rome', 'YY')
  end
$$;

-- Le lezioni sono aperte da ottobre a giugno (luglio, agosto e settembre chiuse).
create or replace function public.lezioni_aperte() returns boolean
language sql stable as $$
  select extract(month from now() at time zone 'Europe/Rome') not in (7, 8, 9)
$$;

alter table public.lezioni enable row level security;

-- Allieve: solo l'anno in corso e solo da ottobre a giugno. Insegnante: tutto.
-- Nessuna regola di scrittura: scrive solo il programma con la chiave segreta.
drop policy if exists "lezioni dell'anno" on public.lezioni;
create policy "lezioni dell'anno" on public.lezioni for select to authenticated
  using (public.is_admin() or (public.is_member() and public.lezioni_aperte() and anno = public.anno_scolastico(now())));
