-- =====================================================================
-- Bindu · pratiche registrate dall'allieva (camminata, sport, yoga da sola…)
-- Aggiunge a `pratiche` la durata, il tipo di attività e una nota.
-- La durata decide lo spessore dell'anello nel mandala.
-- sezione può ora valere anche 'movimento' (anello color pesca).
-- Si può rieseguire senza danni.
-- =====================================================================

alter table public.pratiche add column if not exists minuti int;
alter table public.pratiche add column if not exists tipo text;
alter table public.pratiche add column if not exists nota text;

alter table public.pratiche drop constraint if exists pratiche_minuti_ok;
alter table public.pratiche add constraint pratiche_minuti_ok check (minuti is null or minuti between 1 and 1440);
alter table public.pratiche drop constraint if exists pratiche_nota_ok;
alter table public.pratiche add constraint pratiche_nota_ok check (nota is null or char_length(nota) <= 500);

-- La regola "ognuna le sue pratiche" (01-struttura.sql) vale già anche per
-- modificare e cancellare: ogni allieva tocca solo le righe sue.
