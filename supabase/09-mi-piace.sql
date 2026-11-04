-- =====================================================================
-- Mandala · "mi piace" (fiore di loto) agli articoli del blog
-- Ognuna può mettere un solo loto per articolo e toglierlo. Si vede solo il totale.
-- Si può rieseguire senza danni.
-- =====================================================================

create table if not exists public.mi_piace (
  contenuto_id uuid not null references public.contenuti(id) on delete cascade,
  autore uuid not null default auth.uid(),
  creato timestamptz not null default now(),
  primary key (contenuto_id, autore)
);

alter table public.mi_piace enable row level security;
drop policy if exists "allieve vedono i mi piace" on public.mi_piace;
create policy "allieve vedono i mi piace" on public.mi_piace for select to authenticated
  using (public.is_member());
drop policy if exists "ognuna mette il suo mi piace" on public.mi_piace;
create policy "ognuna mette il suo mi piace" on public.mi_piace for insert to authenticated
  with check (public.is_member() and autore = auth.uid() and exists (
    select 1 from public.contenuti c where c.id = contenuto_id and c.tipo = 'articolo'));
drop policy if exists "ognuna toglie il suo mi piace" on public.mi_piace;
create policy "ognuna toglie il suo mi piace" on public.mi_piace for delete to authenticated
  using (autore = auth.uid());

select count(*) as mi_piace from public.mi_piace;
