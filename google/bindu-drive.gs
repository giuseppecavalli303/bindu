/**
 * Bindu · lezioni da Google Drive
 *
 * Gira nell'account Google dell'insegnante (script.google.com), ogni 10 minuti.
 * - Legge le cartelle "Lezioni di Yoga online" e "Lezioni di Posturale online"
 *   (anche le sottocartelle) e scrive i video nella tabella `lezioni` di Supabase.
 * - Da ottobre a giugno condivide con "chiunque abbia il link" solo i video
 *   dell'anno scolastico in corso, così si vedono dentro Bindu.
 *   A luglio, agosto e settembre, e per gli anni passati, li rende privati.
 *   Le due cartelle restano private (i link valgono solo per i singoli video).
 *
 * Installazione (una volta): vedi GUIDA.md, passo 9.
 * La chiave segreta di Supabase va in Impostazioni progetto → Proprietà script,
 * con il nome SUPABASE_KEY. Non scriverla mai qui dentro.
 */

const SUPABASE_URL = 'https://muakbnnfscwciogulmqt.supabase.co';
const CARTELLE = {
  yoga: 'Lezioni di Yoga online',
  posturale: 'Lezioni di Posturale online'
};
const FUSO = 'Europe/Rome';
const MESI = ['gennaio','febbraio','marzo','aprile','maggio','giugno','luglio','agosto','settembre','ottobre','novembre','dicembre'];

/** Da eseguire UNA volta: crea l'aggiornamento automatico ogni 10 minuti e fa il primo giro. */
function installa() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'sincronizza')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('sincronizza').timeBased().everyMinutes(10).create();
  sincronizza();
}

/** Il giro di controllo: Drive → Bindu, e condivisione dei video. */
function sincronizza() {
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) return;
  try {
    const chiave = PropertiesService.getScriptProperties().getProperty('SUPABASE_KEY');
    if (!chiave) throw new Error('Manca SUPABASE_KEY in Impostazioni progetto → Proprietà script.');

    const oggi = new Date();
    const meseOggi = Number(Utilities.formatDate(oggi, FUSO, 'M'));
    const aperte = [7, 8, 9].indexOf(meseOggi) === -1;
    const annoOggi = annoScolastico(Number(Utilities.formatDate(oggi, FUSO, 'yyyy')), meseOggi);

    Object.keys(CARTELLE).forEach(sezione => {
      const it = DriveApp.getFoldersByName(CARTELLE[sezione]);
      if (!it.hasNext()) { console.warn('Cartella non trovata: ' + CARTELLE[sezione]); return; }
      const cartella = it.next();
      chiudiCartella(cartella);

      const righe = [];
      raccogliVideo(cartella).forEach(f => {
        const creato = f.getDateCreated();
        const mese = meseDellaLezione(f.getName(), creato);
        const [y, m] = mese.split('-').map(Number);
        const anno = annoScolastico(y, m);
        condividi(f, aperte && anno === annoOggi);
        righe.push({
          drive_id: f.getId(),
          sezione: sezione,
          titolo: titoloDa(f.getName()),
          link: 'https://drive.google.com/file/d/' + f.getId() + '/view',
          durata: durataDi(f.getId()),
          mese: mese,
          anno: anno,
          caricata: creato.toISOString(),
          aggiornato: new Date().toISOString()
        });
      });

      if (righe.length) {
        supabase(chiave, 'post', '/rest/v1/lezioni?on_conflict=drive_id', righe,
          { Prefer: 'resolution=merge-duplicates,return=minimal' });
      }
      // Toglie da Bindu i video spostati o cancellati da questa cartella.
      const ids = righe.map(r => '"' + r.drive_id.replace(/"/g, '') + '"').join(',');
      const filtro = '/rest/v1/lezioni?sezione=eq.' + sezione + (ids ? '&drive_id=not.in.(' + encodeURIComponent(ids) + ')' : '');
      supabase(chiave, 'delete', filtro, null, { Prefer: 'return=minimal' });

      console.log(sezione + ': ' + righe.length + ' video. Lezioni ' + (aperte ? 'aperte' : 'chiuse') + ', anno ' + annoOggi + '.');
    });
  } finally {
    lock.releaseLock();
  }
}

/* ---------- Drive ---------- */

function raccogliVideo(cartella) {
  const out = [];
  const files = cartella.getFiles();
  while (files.hasNext()) {
    const f = files.next();
    if (f.isTrashed()) continue;
    if (/^video\//.test(f.getMimeType())) out.push(f);
  }
  const sotto = cartella.getFolders();
  while (sotto.hasNext()) {
    const c = sotto.next();
    if (!c.isTrashed()) Array.prototype.push.apply(out, raccogliVideo(c));
  }
  return out;
}

/** Le cartelle non devono essere aperte a "chiunque abbia il link": esporrebbero anche gli anni passati. */
function chiudiCartella(cartella) {
  const a = cartella.getSharingAccess();
  if (a === DriveApp.Access.ANYONE || a === DriveApp.Access.ANYONE_WITH_LINK) {
    cartella.setSharing(DriveApp.Access.PRIVATE, DriveApp.Permission.NONE);
  }
}

function condividi(f, aperto) {
  const a = f.getSharingAccess();
  const pubblico = a === DriveApp.Access.ANYONE || a === DriveApp.Access.ANYONE_WITH_LINK;
  if (aperto && !pubblico) f.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  if (!aperto && pubblico) f.setSharing(DriveApp.Access.PRIVATE, DriveApp.Permission.NONE);
}

/** Durata del video, se Drive la conosce (facoltativa). */
function durataDi(id) {
  try {
    const r = UrlFetchApp.fetch('https://www.googleapis.com/drive/v3/files/' + id + '?fields=videoMediaMetadata(durationMillis)', {
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() }, muteHttpExceptions: true
    });
    if (r.getResponseCode() !== 200) return null;
    const ms = Number((JSON.parse(r.getContentText()).videoMediaMetadata || {}).durationMillis);
    if (!ms) return null;
    const min = Math.round(ms / 60000);
    return min >= 60 ? Math.floor(min / 60) + ' h ' + (min % 60 ? (min % 60) + ' min' : '') : min + ' min';
  } catch (e) {
    return null;
  }
}

/* ---------- date e titoli ---------- */

/** Anno scolastico: dal 1° luglio inizia il successivo. 2026, 11 → "2026-27". */
function annoScolastico(y, m) {
  const inizio = m >= 7 ? y : y - 1;
  return inizio + '-' + String((inizio + 1) % 100).padStart(2, '0');
}

/**
 * Mese della lezione: dal nome del file se contiene un mese ("Yoga ottobre '26"),
 * altrimenti dalla data in cui è stato caricato.
 */
function meseDellaLezione(nome, creato) {
  const n = nome.toLowerCase();
  const yC = Number(Utilities.formatDate(creato, FUSO, 'yyyy'));
  const mC = Number(Utilities.formatDate(creato, FUSO, 'M'));
  const i = MESI.findIndex(x => new RegExp('(^|[^a-zà-ù])' + x + '([^a-zà-ù]|$)').test(n));
  if (i === -1) return yC + '-' + String(mC).padStart(2, '0');
  const m = i + 1;
  let y;
  const a4 = n.match(/\b(20\d{2})\b/), a2 = n.match(/['’](\d{2})\b/);
  if (a4) y = Number(a4[1]);
  else if (a2) y = 2000 + Number(a2[1]);
  else {
    // senza anno: il mese più vicino alla data di caricamento
    y = yC;
    const diff = (y * 12 + m) - (yC * 12 + mC);
    if (diff > 6) y -= 1;
    if (diff < -6) y += 1;
  }
  return y + '-' + String(m).padStart(2, '0');
}

function titoloDa(nome) {
  return nome.replace(/\.[a-z0-9]{2,4}$/i, '').replace(/[_]+/g, ' ').replace(/\s+/g, ' ').trim();
}

/* ---------- Supabase ---------- */

function supabase(chiave, metodo, percorso, corpo, extra) {
  const headers = Object.assign({ apikey: chiave, 'Content-Type': 'application/json' }, extra || {});
  if (!/^sb_secret_/.test(chiave)) headers.Authorization = 'Bearer ' + chiave; // vecchie chiavi service_role
  const r = UrlFetchApp.fetch(SUPABASE_URL + percorso, {
    method: metodo, headers: headers, muteHttpExceptions: true,
    payload: corpo ? JSON.stringify(corpo) : undefined
  });
  if (r.getResponseCode() >= 300) throw new Error('Supabase ' + r.getResponseCode() + ': ' + r.getContentText());
  return r;
}
