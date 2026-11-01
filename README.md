# Bindu

Yoga, posturale e mindfulness: tema del mese, lezioni registrate, blog, meditazioni guidate, lezioni dal vivo e un mandala personale che cresce a ogni pratica.

- Sito statico (un solo `index.html`) pubblicato con GitHub Pages
- Database, accesso con codice monouso e file su Supabase (`supabase/*.sql`)
- Solo le allieve invitate dall'insegnante possono entrare

**Sito:** <https://giuseppecavalli303.github.io/bindu/>

Come è stato messo online: [GUIDA.md](GUIDA.md). Per chi lavora sul codice, persone o assistenti AI come Claude o ChatGPT: leggete prima [AGENTS.md](AGENTS.md).

| File | A cosa serve |
|---|---|
| `index.html` | L'app |
| `config.js` | Indirizzo e chiave pubblica del progetto Supabase |
| `manifest.webmanifest`, `icona*.{svg,png}` | Icona e installazione sul telefono |
| `supabase/01-struttura.sql` | Tabelle e regole di sicurezza |
| `supabase/02-insegnante.sql` | Email dell'insegnante |
| `supabase/03-esempi.sql` | Contenuti d'esempio (facoltativo) |
| `supabase/05-pratiche-libere.sql` | Durata, tipo e nota delle pratiche (camminate, sport…) |
| `supabase/06-presenze-e-mail.sql` | Presenze segnate dall'insegnante e mail della domenica |
| `supabase/04-lezioni.sql` | Tabella delle lezioni dell'anno da Drive |
| `google/bindu-drive.gs` | Programma Google che porta in Bindu i video delle cartelle Drive |
