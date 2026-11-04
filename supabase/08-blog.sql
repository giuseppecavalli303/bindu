-- =====================================================================
-- Mandala · blog: immagini negli articoli e commenti delle allieve
-- Si può rieseguire senza danni.
-- =====================================================================

-- Immagini dell'articolo: [{"immagine": "articoli/....jpg", "didascalia": "..."}]
-- I file stanno nello spazio privato "media" (lo carica solo l'insegnante).
alter table public.contenuti add column if not exists immagini jsonb not null default '[]'::jsonb;

-- Commenti agli articoli del blog.
create table if not exists public.commenti (
  id uuid primary key default gen_random_uuid(),
  contenuto_id uuid not null references public.contenuti(id) on delete cascade,
  autore uuid not null default auth.uid(),
  nome text,                         -- lo scrive il database, non l'app
  insegnante boolean not null default false,
  testo text not null check (char_length(btrim(testo)) between 1 and 2000),
  creato timestamptz not null default now()
);
create index if not exists commenti_contenuto on public.commenti (contenuto_id, creato);

-- Firma del commento decisa dal database: chi scrive non può fingersi un'altra persona.
-- Delle allieve si mostra solo il primo nome.
create or replace function public.firma_commento() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.autore := auth.uid();
  new.creato := now();
  new.insegnante := public.is_admin();
  if new.insegnante then
    new.nome := 'Tiziana';
  else
    select nullif(split_part(btrim(a.nome), ' ', 1), '') into new.nome
    from public.allieve a where a.id = public.mia_allieva();
    new.nome := coalesce(new.nome, 'Un''allieva');
  end if;
  return new;
end $$;
drop trigger if exists commenti_firma on public.commenti;
create trigger commenti_firma before insert on public.commenti
  for each row execute function public.firma_commento();

alter table public.commenti enable row level security;
drop policy if exists "allieve leggono i commenti" on public.commenti;
create policy "allieve leggono i commenti" on public.commenti for select to authenticated
  using (public.is_member());
drop policy if exists "allieve commentano gli articoli" on public.commenti;
create policy "allieve commentano gli articoli" on public.commenti for insert to authenticated
  with check (public.is_member() and exists (
    select 1 from public.contenuti c where c.id = contenuto_id and c.tipo = 'articolo'));
drop policy if exists "ognuna elimina i suoi, l'insegnante tutti" on public.commenti;
create policy "ognuna elimina i suoi, l'insegnante tutti" on public.commenti for delete to authenticated
  using (autore = auth.uid() or public.is_admin());
-- Nessuna modifica: un commento si elimina e si riscrive.

select (select count(*) from public.commenti) as commenti,
       (select count(*) from information_schema.columns where table_name = 'contenuti' and column_name = 'immagini') as colonna_immagini;
