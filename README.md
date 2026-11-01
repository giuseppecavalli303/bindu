# Bindu

Yoga, posturale e mindfulness: tema del mese, lezioni registrate, blog, meditazioni guidate, lezioni dal vivo e un mandala personale che cresce a ogni pratica.

- Sito statico (un solo `index.html`) pubblicato con GitHub Pages
- Database, accesso con codice monouso e file su Supabase (`supabase/*.sql`)
- Solo le allieve invitate dall'insegnante possono entrare

Per metterlo online segui [GUIDA.md](GUIDA.md).

| File | A cosa serve |
|---|---|
| `index.html` | L'app |
| `config.js` | Indirizzo e chiave pubblica del progetto Supabase |
| `manifest.webmanifest`, `icona*.{svg,png}` | Icona e installazione sul telefono |
| `supabase/01-struttura.sql` | Tabelle e regole di sicurezza |
| `supabase/02-insegnante.sql` | Email dell'insegnante |
| `supabase/03-esempi.sql` | Contenuti d'esempio (facoltativo) |
