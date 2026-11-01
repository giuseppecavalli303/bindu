-- =====================================================================
-- Bindu · presenze segnate dall'insegnante e mail settimanale del mandala
-- Si può rieseguire senza danni.
-- =====================================================================

-- Presenze: l'insegnante spunta chi era a lezione. L'anello compare nel
-- mandala dell'allieva (anche se non è mai entrata in Bindu prima).
create table if not exists public.presenze (
  id uuid primary key default gen_random_uuid(),
  allieva_id uuid not null references public.allieve(id) on delete cascade,
  chiave text not null,                -- id della lezione dal vivo, oppure "sala-AAAA-MM-GG-sezione"
  titolo text not null,
  sezione text not null check (sezione in ('yoga','posturale','mindfulness','movimento')),
  minuti int check (minuti is null or minuti between 1 and 1440),
  at timestamptz not null,
  mese text not null check (mese ~ '^[0-9]{4}-[0-9]{2}$'),
  creato timestamptz not null default now(),
  unique (allieva_id, chiave)
);

-- La riga dell'allieva che sta usando il sito (per email o telefono).
create or replace function public.mia_allieva() returns uuid
language sql stable security definer set search_path = public as $$
  select a.id from public.allieve a
  where (a.email is not null and lower(a.email) = public.mia_email() and public.mia_email() <> '')
     or (a.telefono is not null and a.telefono = public.mio_telefono() and public.mio_telefono() <> '')
  limit 1
$$;
revoke all on function public.mia_allieva() from public, anon;
grant execute on function public.mia_allieva() to authenticated;

alter table public.presenze enable row level security;
drop policy if exists "insegnante gestisce presenze" on public.presenze;
create policy "insegnante gestisce presenze" on public.presenze for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
drop policy if exists "allieva vede le sue presenze" on public.presenze;
create policy "allieva vede le sue presenze" on public.presenze for select to authenticated
  using (allieva_id = public.mia_allieva());

-- Mail settimanale: attiva per tutte, ogni allieva può spegnerla dal suo profilo.
alter table public.allieve add column if not exists mail_settimanale boolean not null default true;

create or replace function public.mia_mail_settimanale() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select mail_settimanale from public.allieve where id = public.mia_allieva()), true)
$$;
create or replace function public.imposta_mail_settimanale(attiva boolean) returns void
language sql volatile security definer set search_path = public as $$
  update public.allieve set mail_settimanale = attiva where id = public.mia_allieva()
$$;
revoke all on function public.mia_mail_settimanale() from public, anon;
revoke all on function public.imposta_mail_settimanale(boolean) from public, anon;
grant execute on function public.mia_mail_settimanale() to authenticated;
grant execute on function public.imposta_mail_settimanale(boolean) to authenticated;

-- Riepilogo per la mail: per ogni allieva con la mail attiva, le pratiche
-- del mese (le sue + le presenze segnate dall'insegnante, senza doppioni).
-- Solo il programma Google, con la chiave segreta, può chiamarla.
create or replace function public.riepilogo_mandala(p_mese text)
returns table(allieva_id uuid, nome text, email text, pratiche jsonb, sciolto boolean)
language sql stable security definer set search_path = public, auth as $$
  with utenti as (
    select a.id as aid, u.id as uid
    from public.allieve a join auth.users u on lower(u.email) = lower(a.email)
  )
  select a.id, a.nome, a.email,
    coalesce((
      select jsonb_agg(jsonb_build_object('at', x.at, 'sezione', x.sezione, 'minuti', x.minuti, 'titolo', x.titolo, 'tipo', x.tipo) order by x.at)
      from (
        select p.at, p.sezione, p.minuti, p.titolo, p.tipo
          from public.pratiche p join utenti t on t.uid = p.user_id
         where t.aid = a.id and p.mese = p_mese and p.chiave not like 'sciolto-%'
        union all
        select r.at, r.sezione, r.minuti, r.titolo, 'presenza'
          from public.presenze r
         where r.allieva_id = a.id and r.mese = p_mese
           and not exists (select 1 from public.pratiche p2 join utenti t2 on t2.uid = p2.user_id
                            where t2.aid = a.id and p2.chiave = r.chiave)
      ) x
    ), '[]'::jsonb),
    exists (select 1 from public.pratiche p join utenti t on t.uid = p.user_id
             where t.aid = a.id and p.chiave = 'sciolto-' || p_mese)
  from public.allieve a
  where a.email is not null and a.mail_settimanale
$$;
revoke all on function public.riepilogo_mandala(text) from public, anon, authenticated;
grant execute on function public.riepilogo_mandala(text) to service_role;
