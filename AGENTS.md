# Istruzioni per chi lavora sul codice di Bindu (persone e assistenti AI)

Bindu è l'app di un'insegnante di yoga e posturale per le sue allieve. Chi la usa non è tecnico: le spiegazioni vanno date in italiano semplice.

## Com'è fatta

- **Un solo file**: `index.html` contiene HTML, CSS e JavaScript. Non ci sono build, framework o npm. Il sito è statico, pubblicato con GitHub Pages dal branch `main`.
- **Database**: Supabase. Il client `supabase-js@2.45.4` arriva da jsDelivr, la configurazione da `config.js` (`window.BINDU_CONFIG`: URL, chiave anon/publishable, `telefono: '' | 'sms' | 'whatsapp'`).
- **Accesso**: codice monouso a 6 cifre via email (`signInWithOtp` + `verifyOtp` con `type:'email'`), oppure via SMS/WhatsApp se attivato. Niente password, niente link magici.
- **Chi entra**: solo gli indirizzi nella tabella `allieve`, più le insegnanti nella tabella `admins`. Il controllo lo fanno le funzioni SQL `is_member()` e `is_admin()` e le regole RLS in `supabase/01-struttura.sql`.

## Dati (tabelle Supabase)

| Tabella | Contenuto |
|---|---|
| `temi` | Tema del mese per sezione (`yoga`, `posturale`, `mindfulness`), mese `AAAA-MM`, testo, `approfondimenti` (jsonb `[{titolo,testo}]`) |
| `contenuti` | `tipo` = `video` / `audio` / `articolo` / `diretta`; `link` (es. Google Drive), `file` (percorso nel bucket privato `media`), `settimana` 1–4, `quando`/`dove` per le lezioni dal vivo |
| `pratiche` | Le pratiche di ogni allieva (righe sue, `user_id = auth.uid()`). La chiave `sciolto-AAAA-MM` segna il mandala del mese dissolto |
| `allieve`, `admins` | Elenco di accesso (email e/o telefono solo con le cifre, es. `393331234567`) |

I file nel bucket `media` sono privati: il sito li mostra con URL firmati (`createSignedUrls`, validi 6 ore).

## Idee centrali da rispettare

- **Il mandala**: ogni pratica completata (video o audio finito, "Ho praticato", lezione dal vivo con "Ero presente", timer di silenzio, pausa posturale) aggiunge un anello intorno al bindu. Il colore dipende dalla sezione. Ogni mese ha il suo mandala, che riparte dal centro.
- **Il rito di fine mese**: negli ultimi 3 giorni del mese (o nei mesi passati) l'allieva può **dissolvere** il mandala con due tocchi. Animazione: la sabbia viene raccolta al centro e poi si disperde. Deve essere un gesto attivo dell'allieva, mai automatico. Il mandala era il tema della tesi di laurea dell'insegnante: va trattato con cura.
- **Grafica**: paesaggi pastello rosa e viola disegnati in SVG (alba = yoga, lago = posturale, notte = mindfulness), font Marcellus + Figtree, tema chiaro e scuro tramite variabili CSS in `:root`. Logo: fiore di loto sopra le vertebre (colonna e loto).
- **Lingua**: interfaccia in italiano, tono caldo e semplice.

## Come lavorare

- Prima di modificare `index.html`, cerca la sezione giusta: i commenti `/* ---------- ... ---------- */` dividono il codice (scene, mandala, viste, timer, pausa posturale, modulo insegnante, accesso Supabase).
- Le modifiche al database vanno in un nuovo file `supabase/0N-descrizione.sql`, che si possa rieseguire senza danni (`if not exists`, `drop policy if exists`). Aggiorna anche `GUIDA.md`.
- Non mettere mai nel codice la chiave `service_role` / `secret`, password o dati delle allieve.
- Prova in locale con `python3 -m http.server` nella cartella del progetto, poi apri `http://localhost:8000`.
