-- =====================================================================
-- Bindu · chi è l'insegnante
-- 1. Sostituisci l'email qui sotto con quella di tua moglie
--    (la stessa che userà per entrare nel sito).
-- 2. Esegui in Supabase → SQL Editor → Run.
-- Per aggiungere un'altra insegnante, ripeti con un'altra email.
-- =====================================================================

insert into public.admins (email)
values ('EMAIL-DELLA-INSEGNANTE@esempio.it')
on conflict do nothing;

-- Se vorrà entrare anche con il telefono (solo dopo aver attivato SMS o WhatsApp),
-- togli i due trattini all'inizio della riga qui sotto e scrivi il numero
-- solo con le cifre, prefisso compreso (39 per l'Italia):
-- insert into public.admins (telefono) values ('393331234567') on conflict do nothing;
