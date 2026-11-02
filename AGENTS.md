# Istruzioni per chi lavora sul codice di Mandala (persone e assistenti AI)

**Mandala** (fino al 1° novembre 2026 si chiamava Bindu: il repository e l'indirizzo del sito contengono ancora `bindu`) è l'app di un'insegnante di yoga e posturale per le sue allieve. Chi la usa non è tecnico: le spiegazioni vanno date in italiano semplice.

## Com'è fatta

- **Un solo file**: `index.html` contiene HTML, CSS e JavaScript. Non ci sono build, framework o npm. Il sito è statico, pubblicato con GitHub Pages dal branch `main`.
- **Database**: Supabase. Il client `supabase-js@2.45.4` arriva da jsDelivr, la configurazione da `config.js` (`window.BINDU_CONFIG`: URL, chiave anon/publishable, `telefono: '' | 'sms' | 'whatsapp'`).
- **Accesso**: codice monouso a 6 cifre via email (`signInWithOtp` + `verifyOtp` con `type:'email'`), oppure via SMS/WhatsApp se attivato. Niente password. Per sicurezza la pagina accetta anche il link dell'email (`emailRedirectTo` = indirizzo del sito, `detectSessionInUrl`), ma le email configurate mandano il codice.
- **Lezioni dell'anno**: i video delle cartelle Drive "Lezioni di Yoga online" e "Lezioni di Posturale online" li scrive nella tabella `lezioni` il programma `google/bindu-drive.gs` (Google Apps Script nell'account dell'insegnante, ogni 10 minuti, chiave `SUPABASE_KEY` nelle Proprietà script). Le allieve li vedono da ottobre a giugno e solo per l'anno scolastico in corso (regola RLS con `anno_scolastico()` e `lezioni_aperte()`). Lo stesso programma condivide i singoli video con link solo in quel periodo e li rende privati a luglio.
- **Lettore interno**: i link di Google Drive, YouTube e Vimeo si aprono dentro Bindu (`embedOf()` e `openPlayer()` in `index.html`). Con YouTube e Vimeo la fine del video aggiunge da sola l'anello al mandala; con Drive l'allieva tocca "Ho praticato".
- **Chi entra**: solo gli indirizzi nella tabella `allieve`, più le insegnanti nella tabella `admins`. Il controllo lo fanno le funzioni SQL `is_member()` e `is_admin()` e le regole RLS in `supabase/01-struttura.sql`.

## Stato attuale (novembre 2026)

| Cosa | Dove / come |
|---|---|
| Sito online | <https://mandala.yogacontiziana.it/> (GitHub Pages, branch `main`, cartella principale, file `CNAME`). Il vecchio indirizzo giuseppecavalli303.github.io/bindu porta qui da solo |
| Dominio | `yogacontiziana.it` su OVH (DNS `dns103`/`ns103.ovh.net`): `mandala` CNAME → `giuseppecavalli303.github.io.`; posta MX Plan OVH con la casella `tiziana@yogacontiziana.it`; record Brevo: `brevo-code` (TXT), `brevo1/2._domainkey` (CNAME), `_dmarc` (TXT `p=none`); SPF di OVH già presente |
| Codice | <https://github.com/giuseppecavalli303/bindu> |
| Database | Supabase, progetto `bindu` (ref `muakbnnfscwciogulmqt`, regione Paris), organizzazione **Bindu** sul piano Free. Va tenuto **separato** dal progetto Distanti Book Club |
| Struttura dati | `supabase/01-struttura.sql`, `02-insegnante.sql` e `03-esempi.sql` sono già stati eseguiti |
| Insegnanti | Tiziana, `yogacontiziana@gmail.com`, e Giuseppe, suo marito, che cura il sito (tabella `admins`) |
| Orario | `supabase/07-orario.sql` eseguito: lunedì e mercoledì yoga 19–20, martedì e giovedì posturale 19–20. L'app ne ricava le lezioni dal vivo (`lezioniOrario()`, id `or-<id>-<data>`), da ottobre a giugno. Link Zoom da inserire in Gestisci Mandala |
| Da aggiornare | Nel progetto Apps Script va ricopiato `google/bindu-drive.gs` (la mail della domenica firma "Tiziana · Mandala") |
| Durata dell'accesso | Access token expiry portato da 3600 a **604800 secondi (1 settimana)** il 2 novembre 2026 (Project Settings → JWT Keys → Legacy JWT Secret). Motivo: sull'app iPhone dalla schermata Home il rinnovo orario del token a volte si perdeva quando iOS sospendeva l'app, e veniva richiesto di nuovo il codice. Le regole RLS ricontrollano comunque `allieve` a ogni richiesta |
| Auth → URL Configuration | Site URL = indirizzo del sito qui sopra |
| Email di accesso | SMTP personalizzato tramite Brevo (`smtp-relay.brevo.com`, porta 465, chiave SMTP "bindu2"). Mittente **Mandala `<tiziana@yogacontiziana.it>`** (dominio autenticato su Brevo con DKIM e DMARC). Site URL in Supabase: `https://mandala.yogacontiziana.it/`. Se la mail non parte e i log Auth dicono `535 Authentication failed`, la chiave SMTP in Supabase è sbagliata: generarne una nuova su Brevo e incollarla in Auth → SMTP Settings |
| Modelli email | "Magic link or OTP" e "Confirm sign up" sono in italiano, oggetto "Il tuo codice per entrare in Mandala", e contengono `{{ .Token }}` (il codice a 6 cifre). Oggetto: "Il tuo codice per entrare in Mandala" |
| Pratiche libere | `supabase/05-pratiche-libere.sql` eseguito (colonne `minuti`, `tipo`, `nota`) |
| Presenze e mail | `supabase/06-presenze-e-mail.sql` eseguito. Mail della domenica: funzioni `installaMail` / `fermaMail` / `anteprimaMail` nello stesso progetto Apps Script; parte dall'account di Tiziana (MailApp, quota 100 mail al giorno). **Attiva dal 1° novembre 2026** (attivatore `mailSettimanale`, domenica verso le 18); la mail contiene l'immagine PNG del mandala di ogni allieva (`mandalaPng`). Per fermarla: eseguire `fermaMail` |
| Lezioni da Drive | `supabase/04-lezioni.sql` eseguito. Programma installato il 1° novembre 2026 nell'account Google di Tiziana: progetto Apps Script **Bindu Drive**, attivatore `sincronizza` ogni 10 minuti, proprietà `SUPABASE_KEY` = chiave secret "default" di Supabase. Se si cambia `google/bindu-drive.gs` va ricopiato anche nell'editor di Apps Script. Errori: Apps Script → Bindu Drive → Esecuzioni |
| SMS / WhatsApp | Non attivi (`telefono: ''` in `config.js`) |

C'è anche una versione di prova dell'app pubblicata come Artifact su claude.ai, con la stessa grafica, che salva i dati sulla piattaforma di Claude. **Il sito vero è questo repository.**

### Cosa manca o andrebbe migliorato

- **Video di Drive su iPhone** (novembre 2026): il riquadro di Drive (`/preview`) su iPhone a volte non parte o si blocca. Provato e scartato: riprodurre il file direttamente con `<video>` da `drive.usercontent.google.com` (Drive risponde 403 alle richieste da altri siti) e caricare in automatico su YouTube (i video caricati via API da progetti non verificati restano privati; Zapier va in timeout con file grandi). Decisione: **per ora si resta su Drive**. Su iPhone il lettore mostra al posto del riquadro un pulsante "Guarda nell'app Drive" (`isIOS()` in `openPlayer`), con "Prova a guardarla qui" e un promemoria per "Ho praticato" quando si torna in Bindu. L'alternativa valutata è YouTube "non in elenco" caricato a mano da Tiziana in playlist, letto dal programma Google.

- Informativa privacy (GDPR) per le allieve: nome ed email vengono conservati.
- Il mittente usa un indirizzo Gmail, quindi alcune email possono finire nello spam. Con un dominio proprio autenticato su Brevo si risolve.
- Gli esercizi della pausa posturale (`const PAUSA` in `index.html`) sono esempi scritti da un'AI: vanno sostituiti con quelli dell'insegnante.
- I contenuti d'esempio di novembre hanno `esempio = true` e si possono eliminare dall'app.

## Dati (tabelle Supabase)

| Tabella | Contenuto |
|---|---|
| `temi` | Tema del mese per sezione (`yoga`, `posturale`, `mindfulness`), mese `AAAA-MM`, testo, `approfondimenti` (jsonb `[{titolo,testo}]`) |
| `contenuti` | `tipo` = `video` / `audio` / `articolo` / `diretta`; `link` (es. Google Drive), `file` (percorso nel bucket privato `media`), `settimana` 1–4, `quando`/`dove` per le lezioni dal vivo |
| `pratiche` | Le pratiche di ogni allieva (righe sue, `user_id = auth.uid()`). `sezione` = yoga / posturale / mindfulness / **movimento**; `minuti` (spessore dell'anello), `tipo` (camminata, sport, yoga, posturale, meditazione, rivisto, altro, oppure il tipo del contenuto), `nota`. Chiavi: id del contenuto, `lz-<drive_id>` per le lezioni da Drive, `lib-<ora>` per le pratiche registrate a mano, `rv-<id>-<ora>` per un video rivisto, `timer-<ora>`, `sciolto-AAAA-MM` per il mandala dissolto |
| `lezioni` | Video da Drive: `drive_id`, `sezione` (yoga/posturale), `titolo`, `link`, `durata`, `mese`, `anno` scolastico (es. `2026-27`, cambia il 1° luglio), `caricata`. La scrive solo il programma Google; nell'app non si modifica |
| `presenze` | Presenze segnate dall'insegnante: `allieva_id` (→ `allieve`), `chiave` (id della lezione dal vivo o `sala-…`), `titolo`, `sezione`, `minuti`, `at`, `mese`. L'allieva le vede (RLS con `mia_allieva()`) e diventano anelli `pres-<id>` nel suo mandala, senza doppioni con "Ero presente" |
| `allieve`, `admins` | Elenco di accesso (email e/o telefono solo con le cifre, es. `393331234567`) |

I file nel bucket `media` sono privati: il sito li mostra con URL firmati (`createSignedUrls`, validi 6 ore).

## Idee centrali da rispettare

- **Il mandala**: ogni pratica aggiunge un anello intorno al bindu: video o audio finito, "Ho praticato", lezione dal vivo con "Ero presente", timer di silenzio, pausa posturale, e anche le pratiche **fuori dalle lezioni** registrate dall'allieva ("Registra una pratica": camminata, sport, yoga o meditazione per conto suo, lezione rivista, altro; anche con cronometro, che resta attivo se l'app si chiude). Rivedere un video conta ogni volta ("+ Di nuovo"). Il **colore** dice cosa (rosa yoga, lavanda posturale, lilla mindfulness, pesca movimento), lo **spessore** quanto è durata (30 min = 1, da 0,45 a 1,8). Sotto il mandala c'è il diario del mese, dove si modifica o si toglie una pratica. Ogni mese ha il suo mandala, che riparte dal centro.
- **Lo scopo**: invitare le allieve a restare attive ogni giorno, non solo durante le lezioni. Se oggi non c'è ancora una pratica, la home mostra un invito gentile con "Registra una pratica" e "Inizio a camminare". Il tono resta caldo, mai colpevolizzante.
- **Il rito di fine mese**: negli ultimi 3 giorni del mese (o nei mesi passati) l'allieva può **dissolvere** il mandala con due tocchi. Animazione: la sabbia viene raccolta al centro e poi si disperde. Deve essere un gesto attivo dell'allieva, mai automatico. Il mandala era il tema della tesi di laurea dell'insegnante: va trattato con cura.
- **Presenze**: le lezioni sono su Zoom (link nel campo `dove` della lezione dal vivo). Tiziana spunta le presenti con «Segna le presenze» sulla lezione, o in Gestisci Bindu per le lezioni in sala. L'allieva non può togliere una presenza segnata da Tiziana.
- **La mail della domenica**: ogni domenica verso le 18 il programma Google manda a ogni allieva (colonna `allieve.mail_settimanale`, che l'allieva cambia dal suo profilo) un riepilogo caldo del mandala del mese, firmato Tiziana: anelli della settimana, colori, minuti, un cerchio colorato per pratica. I dati arrivano dalla funzione SQL `riepilogo_mandala(mese)`, eseguibile solo con la chiave segreta. Il tono incoraggia senza colpevolizzare.
- **L'anno scolastico**: va da ottobre a giugno. Luglio, agosto e settembre le lezioni registrate sono chiuse. Il 1° luglio inizia il nuovo anno scolastico (le lezioni caricate a settembre compaiono dal 1° ottobre).
- **Sezioni**: Yoga non ha il percorso del mese; Yoga e Posturale non hanno meditazioni guidate. **Mindfulness** ha: tema del mese, percorso del mese **solo descrittivo** (4 settimane, salvate nel tema come elementi di `approfondimenti` con `settimana` 1–4, `titolo`, `testo`; `percorsoTesto()`), **una sola meditazione del mese** (l'audio più recente del mese), silenzio con campana e blog. Niente lezioni del mese né dal vivo in Mindfulness. **Posturale** ha: tema, lo stesso percorso descrittivo in 4 settimane (anche con immagine per settimana; di solito la 4ª è il riepilogo e la lezione registrata, con il pulsante «Guarda la lezione del mese»), **una sola lezione del mese** (`lezioneDelMese()`: la lezione Drive di quel mese, altrimenti l'ultimo video aggiunto a mano), pausa posturale, dal vivo, lezioni dell'anno (senza il mese corrente) e blog. Gli approfondimenti del tema possono avere un'immagine (`approfondimenti[].immagine`, file in `media/temi/`, ridotta a 1600 px nel browser).
- **Pagina d'ingresso**: in alto a destra c'è `tiziana.png`, Tiziana seduta sul mandala, scontornata e con il telo ricolorato dal blu ai toni lilla/malva dell'app. Ha un alone lilla e un'ombra morbida (`.login-foto`) e si rimpicciolisce quando si scorre.
- **Grafica**: paesaggi pastello rosa e viola disegnati in SVG (alba = yoga, lago = posturale, notte = mindfulness), font Marcellus + Figtree, tema chiaro e scuro tramite variabili CSS in `:root`. Logo: fiore di loto sopra le vertebre (colonna e loto).
- **Lingua**: interfaccia in italiano, tono caldo e semplice.

## Come lavorare

- Prima di modificare `index.html`, cerca la sezione giusta: i commenti `/* ---------- ... ---------- */` dividono il codice (scene, mandala, viste, timer, pausa posturale, modulo insegnante, accesso Supabase).
- Le modifiche al database vanno in un nuovo file `supabase/0N-descrizione.sql`, che si possa rieseguire senza danni (`if not exists`, `drop policy if exists`). Aggiorna anche `GUIDA.md`.
- Non mettere mai nel codice la chiave `service_role` / `secret`, la chiave SMTP di Brevo, password o dati delle allieve. La chiave `sb_publishable_...` in `config.js` invece è pubblica per scelta: la protezione la fanno le regole RLS.
- Per pubblicare una modifica basta un commit su `main`: GitHub Pages aggiorna il sito in 1–2 minuti.
- Le modifiche fatte nella dashboard di Supabase o di Brevo vanno annotate nella tabella "Stato attuale" qui sopra.
- Prova in locale con `python3 -m http.server` nella cartella del progetto, poi apri `http://localhost:8000`.


## Passaggio di lavoro · 1 novembre 2026 · Codex

- Applicata la proposta grafica dell’ingresso approvata da Giuseppe: «Lo spazio di pratica con Tiziana», fondo avorio, prugna, paesaggio alba più discreto e modulo con etichette visibili. Su desktop presentazione e accesso sono affiancati; su mobile sono impilati.
- Conservato il logo SVG loto-colonna originale. Il sottotitolo del marchio ora è «Pratica con Tiziana» anche dentro l’app.
- Gli stili nuovi sono circoscritti a `body.login-page` e ai componenti `login-*`; supportano tema chiaro e scuro. Non estendere la palette alle schermate interne senza verificarle.
- Logica OTP, link di accesso, canali SMS/WhatsApp, database, contenuti e mandala non modificati. Nessuna modifica alle dashboard Supabase/Brevo.
- Prima di riprendere, leggere il branch aggiornato. Al termine di ogni intervento annotare qui modifiche, verifiche e attività residue per il passaggio Claude/Codex.

- Verifiche: sintassi JavaScript valida; struttura dei moduli ingresso/codice verificata per email, SMS e WhatsApp; anteprima browser desktop e mobile 375 px controllata. Nessun accesso reale con OTP eseguito.

## Icona Home · 1 novembre 2026 · Codex

- Ridisegnata `icona.svg`: fondo prugna pieno, loto rosa a cinque petali, punto bindu e quattro vertebre lavanda. Il logo inline dell’header resta invariato.
- PNG opachi 180 (Apple), 192 e 512 px generati dal vettoriale. Simbolo nella zona sicura centrale per maschere Android; niente angoli arrotondati incorporati.
- Manifest e riferimenti icone versionati `?v=2`; manifest aggiornato con scopo `any maskable` per i PNG 192/512 e colori avorio. Nessuna modifica a start_url o scope.
- Per rigenerare: usare Sharp/libvips dal file SVG, ridimensionare a 180/192/512 px ed esportare PNG RGB senza alpha.
- Verifiche: ispezione del PNG, dimensioni/assenza trasparenza e riferimenti del manifest. L’aggiornamento di un’icona già installata dipende dal dispositivo; installazione su dispositivo fisico non verificata.
