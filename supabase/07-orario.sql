-- =====================================================================
-- Mandala · orario settimanale delle lezioni dal vivo
-- Ogni riga è una lezione che si ripete ogni settimana (da ottobre a giugno).
-- L'app ne ricava le date delle prossime lezioni, con "Ero presente" e le presenze.
-- Si può rieseguire senza danni.
-- =====================================================================

create table if not exists public.orario (
  id uuid primary key default gen_random_uuid(),
  giorno int not null check (giorno between 1 and 7),          -- 1 lunedì … 7 domenica
  sezione text not null check (sezione in ('yoga','posturale','mindfulness')),
  titolo text not null,
  inizio text not null check (inizio ~ '^[0-2][0-9]:[0-5][0-9]$'),
  fine text not null check (fine ~ '^[0-2][0-9]:[0-5][0-9]$'),
  dove text,                                                    -- link Zoom
  creato timestamptz not null default now()
);

alter table public.orario enable row level security;
drop policy if exists "allieve leggono l'orario" on public.orario;
create policy "allieve leggono l'orario" on public.orario for select to authenticated using (public.is_member());
drop policy if exists "insegnante scrive l'orario" on public.orario;
create policy "insegnante scrive l'orario" on public.orario for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Orario 2026-27 (solo se la tabella è vuota):
-- lunedì e mercoledì yoga 19-20, martedì e giovedì posturale 19-20.
insert into public.orario (giorno, sezione, titolo, inizio, fine)
select * from (values
  (1, 'yoga', 'Lezione di yoga', '19:00', '20:00'),
  (3, 'yoga', 'Lezione di yoga', '19:00', '20:00'),
  (2, 'posturale', 'Lezione di posturale', '19:00', '20:00'),
  (4, 'posturale', 'Lezione di posturale', '19:00', '20:00')
) v(giorno, sezione, titolo, inizio, fine)
where not exists (select 1 from public.orario);
