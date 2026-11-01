# Bindu · come mettere online il sito

Tempo: circa 30–40 minuti la prima volta. Costo: zero (piani gratuiti di GitHub e Supabase).

Ti servono due account gratuiti:

- **GitHub**, che ospita il sito: <https://github.com>
- **Supabase**, che è il database: tiene allieve, contenuti, file e mandala. <https://supabase.com> (puoi entrare con l'account GitHub)

> I nomi dei menu di Supabase e GitHub a volte cambiano un po'. Se non trovi una voce esatta, cerca quella con il nome più simile.

---

## 1. Crea il progetto Supabase

1. Su supabase.com premi **New project**.
2. Nome: `bindu`. Scegli una password per il database e **salvala**: non servirà per il sito, ma è meglio non perderla.
3. Regione: **Central EU (Frankfurt)**. I dati restano in Europa, ed è meglio per la privacy.
4. Premi **Create** e aspetta un paio di minuti.

## 2. Prepara il database

Nel progetto apri **SQL Editor** (nella barra a sinistra) e premi **New query**.

1. Apri il file `supabase/01-struttura.sql`, copia tutto, incollalo e premi **Run**. Deve comparire "Success".
2. Apri `supabase/02-insegnante.sql` e **sostituisci** `EMAIL-DELLA-INSEGNANTE@esempio.it` con l'email di tua moglie. Incolla in una nuova query e premi **Run**.
3. (Facoltativo) Esegui `supabase/03-esempi.sql` per avere subito i contenuti d'esempio di novembre.

## 3. Collega il sito al database

1. In Supabase apri **Project Settings → Data API** (o **API**) e copia il **Project URL**.
2. Apri **Project Settings → API Keys** e copia la chiave **anon public** (o **publishable**).
   Non usare mai la chiave **service_role** / **secret**.
3. Apri il file `config.js` con un editor di testo (TextEdit va bene) e incolla i due valori al posto di `INSERISCI-QUI-...`. Lascia gli apici `'...'`.

## 4. Il codice di accesso via email

Bindu non usa password: a chi entra arriva un codice di 6 cifre.

1. **Authentication → Sign In / Providers → Email**: controlla che sia attivo. Lunghezza del codice (Email OTP Length): **6**.
2. **Authentication → Emails → Templates**: modifica i due modelli **Magic Link** e **Confirm signup** in questo modo.
   - Oggetto: `Il tuo codice per entrare in Bindu`
   - Testo (puoi incollarlo così):

     ```html
     <h2>Il tuo codice per Bindu</h2>
     <p>Scrivi questo codice nella pagina di accesso:</p>
     <p style="font-size:28px;letter-spacing:6px"><b>{{ .Token }}</b></p>
     <p>Il codice vale una sola volta e scade dopo un'ora.<br>Se non hai chiesto tu di entrare, ignora questa email.</p>
     ```

   `{{ .Token }}` va lasciato così: Supabase lo sostituisce con il codice.

## 5. Un servizio per inviare le email (importante)

Il servizio email incluso in Supabase invia **pochissime email all'ora** ed è pensato solo per le prove. Prima di invitare le allieve collega un servizio gratuito, per esempio **Brevo** (300 email al giorno gratis):

1. Crea un account su <https://www.brevo.com>, verifica l'indirizzo mittente (per esempio quello di tua moglie) e genera una **chiave SMTP**.
2. In Supabase vai su **Authentication → Emails → SMTP Settings → Enable custom SMTP** e inserisci:
   - Host: `smtp-relay.brevo.com` · Porta: `587`
   - Utente e password: quelli SMTP che ti dà Brevo
   - Email del mittente: l'indirizzo verificato · Nome del mittente: `Bindu`
3. In **Authentication → Rate Limits** alza il limite di email all'ora, per esempio a 100.

## 6. Pubblica il sito su GitHub Pages

1. Su github.com premi **New repository**. Nome: `bindu`, visibilità **Public**, poi **Create repository**.
2. Nella pagina del repository premi **uploading an existing file** (o **Add file → Upload files**).
3. Trascina questi file: `index.html`, `config.js`, `manifest.webmanifest`, `icona.svg`, `icona-512.png`, `icona-180.png`. Poi premi **Commit changes**.
4. Vai su **Settings → Pages**. In "Build and deployment" scegli **Deploy from a branch**, poi branch **main** e cartella **/ (root)**, e premi **Save**.
5. Dopo 1–2 minuti compare l'indirizzo, per esempio `https://NOMEUTENTE.github.io/bindu/`.

## 7. La prima prova

1. Apri l'indirizzo del sito e scrivi l'email di tua moglie: arriva il codice, lei lo inserisce ed entra.
2. In alto deve vedere **Insegnante**. Toccandolo si apre **Gestisci Bindu**, dove aggiunge le allieve: nome ed email.
3. Ogni allieva apre il sito, scrive la sua email, riceve il codice ed entra. Il codice serve solo la prima volta su ogni telefono, poi l'accesso resta attivo.

**Sul telefono come un'app:** iPhone → Safari → tasto Condividi → **Aggiungi alla schermata Home**. Android → Chrome → menu ⋮ → **Installa app** (o **Aggiungi a schermata Home**).

## 8. (Facoltativo) Codice via SMS o WhatsApp

Funziona, ma **ogni messaggio costa** (per un SMS in Italia indicativamente pochi centesimi) e serve un account **Twilio** (<https://www.twilio.com>).

1. In Twilio compra un numero mittente. Per WhatsApp serve anche l'approvazione di un mittente WhatsApp.
2. In Supabase: **Authentication → Sign In / Providers → Phone** → attiva, scegli **Twilio** e inserisci Account SID, Auth Token e numero.
3. In `config.js` imposta `telefono: 'sms'` oppure `telefono: 'whatsapp'` e ricarica il file su GitHub.
4. Da quel momento, aggiungendo un'allieva, tua moglie può scrivere anche il suo numero. Nella pagina di accesso compare la scelta Email / SMS (o WhatsApp).

## Da sapere

- **Pausa automatica**: un progetto Supabase gratuito che nessuno usa per 7 giorni viene messo in pausa. Basta rientrare su supabase.com e premere **Restore**. Se le allieve usano Bindu ogni settimana, non succede.
- **Privacy**: Bindu conserva nome ed email (o telefono) delle allieve. Serve una breve **informativa privacy** (GDPR) da far vedere alle allieve. Posso prepararne una bozza.
- **Video lunghi**: restano su Google Drive con il link. Nello spazio di Supabase vanno i file brevi, fino a 50 MB l'uno (1 GB in tutto nel piano gratuito).
- **Aggiornare il sito**: quando cambia `index.html`, lo si ricarica su GitHub con **Add file → Upload files**. I contenuti invece si aggiungono dall'app, senza toccare GitHub.
- **Dominio vostro** (per esempio `bindu-yoga.it`): si può aggiungere in qualsiasi momento da **Settings → Pages → Custom domain**.
