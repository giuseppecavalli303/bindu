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
    const chiave = (PropertiesService.getScriptProperties().getProperty('SUPABASE_KEY') || '').replace(/\s+/g, ''); // toglie spazi finiti nel copia-incolla
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

/* =====================================================================
 * La mail della domenica: a ogni allieva, come sta crescendo il suo mandala
 * ===================================================================== */

const SITO = 'https://giuseppecavalli303.github.io/bindu/';
const INSEGNANTE = 'yogacontiziana@gmail.com';
const TINTE = {
  yoga:        { nome: 'Yoga',        chiaro: '#F5C4D8', scuro: '#A8457A' },
  posturale:   { nome: 'Posturale',   chiaro: '#CFCCF4', scuro: '#5650A6' },
  mindfulness: { nome: 'Mindfulness', chiaro: '#E3CCF4', scuro: '#8248AC' },
  movimento:   { nome: 'Movimento',   chiaro: '#FCD9C7', scuro: '#B0603A' }
};

/** Da eseguire UNA volta: la mail parte ogni domenica verso le 18. */
function installaMail() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'mailSettimanale')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('mailSettimanale').timeBased().onWeekDay(ScriptApp.WeekDay.SUNDAY).atHour(18).create();
  console.log('Mail della domenica attivata.');
}

/** Ferma la mail della domenica. */
function fermaMail() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'mailSettimanale')
    .forEach(t => ScriptApp.deleteTrigger(t));
  console.log('Mail della domenica fermata.');
}

function mailSettimanale() { inviaRiepiloghi(false); }

/** Prova: manda solo all'insegnante le mail (al massimo 3) come le riceverebbero le allieve. */
function anteprimaMail() { inviaRiepiloghi(true); }

function inviaRiepiloghi(prova) {
  const chiave = (PropertiesService.getScriptProperties().getProperty('SUPABASE_KEY') || '').replace(/\s+/g, '');
  if (!chiave) throw new Error('Manca SUPABASE_KEY in Impostazioni progetto → Proprietà script.');
  const oggi = new Date();
  const mese = Utilities.formatDate(oggi, FUSO, 'yyyy-MM');
  let allieve = JSON.parse(supabase(chiave, 'post', '/rest/v1/rpc/riepilogo_mandala', { p_mese: mese }).getContentText());
  if (prova) {
    if (!allieve.length) allieve = [esempioAllieva(oggi)];
    allieve = allieve.slice(0, 3);
  }
  let inviate = 0;
  allieve.forEach(a => {
    if (!a.email) return;
    if (MailApp.getRemainingDailyQuota() < 1) { console.warn('Quota giornaliera di mail finita.'); return; }
    const m = componiMail(a, oggi, mese);
    MailApp.sendEmail({
      to: prova ? INSEGNANTE : a.email,
      subject: (prova ? '[Anteprima per ' + (a.nome || a.email) + '] ' : '') + m.oggetto,
      htmlBody: m.html,
      body: m.testo,
      name: 'Tiziana · Bindu',
      replyTo: INSEGNANTE
    });
    inviate++;
  });
  console.log((prova ? 'Anteprime' : 'Mail') + ' inviate: ' + inviate + '.');
}

function componiMail(a, oggi, mese) {
  const P = (a.pratiche || []).slice().sort((x, y) => String(x.at).localeCompare(String(y.at)));
  const n = P.length;
  const settimanaFa = oggi.getTime() - 7 * 864e5;
  const S = P.filter(p => Date.parse(p.at) >= settimanaFa);
  const minTot = P.reduce((t, p) => t + (Number(p.minuti) || 0), 0);
  const minSett = S.reduce((t, p) => t + (Number(p.minuti) || 0), 0);
  const giorni = new Set(P.map(p => Utilities.formatDate(new Date(p.at), FUSO, 'yyyy-MM-dd'))).size;
  const [y, m] = mese.split('-').map(Number);
  const nomeMese = MESI[m - 1];
  const ultimo = new Date(y, m, 0).getDate(), giornoOggi = Number(Utilities.formatDate(oggi, FUSO, 'd'));
  const nome = String(a.nome || '').trim().split(/\s+/)[0];
  const per = {};
  P.forEach(p => { const k = TINTE[p.sezione] ? p.sezione : 'mindfulness'; per[k] = per[k] || { n: 0, min: 0 }; per[k].n++; per[k].min += Number(p.minuti) || 0; });

  let oggetto, apertura;
  if (a.sciolto) {
    oggetto = 'Il tuo mandala è tornato sabbia';
    apertura = 'Questo mese hai già lasciato andare il tuo mandala, come i monaci con la sabbia. Il 1° del mese ne nascerà uno nuovo, a partire dal bindu.';
  } else if (!n) {
    oggetto = 'Il tuo mandala ti aspetta';
    apertura = 'Il tuo mandala di ' + nomeMese + ' è ancora al bindu, il punto da cui tutto nasce. Basta una pratica per far nascere il primo anello: una camminata di dieci minuti, qualche respiro consapevole, una lezione.';
  } else if (!S.length) {
    oggetto = 'Il tuo mandala di ' + nomeMese;
    apertura = 'Questa settimana il tuo mandala si è riposato. Ha ' + anelli(n) + ', nati da ' + dur(minTot) + ' di pratica. Va bene così: anche la pausa fa parte del cammino. Quando vuoi, una piccola pratica lo farà crescere di nuovo.';
  } else {
    oggetto = S.length === 1 ? 'Il tuo mandala ha un anello in più' : 'Il tuo mandala è cresciuto di ' + S.length + ' anelli';
    apertura = 'Questa settimana il tuo mandala è cresciuto di ' + anelli(S.length) + (minSett ? ', ' + dur(minSett) + ' di pratica' : '') + '. Adesso ne ha ' + n + (minTot ? ', per ' + dur(minTot) : '') + ' in ' + (giorni === 1 ? 'un giorno' : giorni + ' giorni') + ' di ' + nomeMese + '.';
  }

  const colori = Object.keys(TINTE).filter(k => per[k]).map(k =>
    '<span style="display:inline-block;margin:3px 6px 3px 0;padding:5px 11px;border-radius:999px;background:' + TINTE[k].chiaro + ';color:#3B2D4D;font-size:13px;font-weight:600">'
    + TINTE[k].nome + ' · ' + per[k].n + (per[k].min ? ' · ' + dur(per[k].min) : '') + '</span>').join('');
  const extra = [];
  if (per.movimento && !a.sciolto) extra.push('Gli anelli color pesca sono le tue camminate e il movimento libero: anche loro fanno parte della pratica.');
  if (!a.sciolto && n && ultimo - giornoOggi <= 7) extra.push('Il mese sta per finire. Negli ultimi tre giorni potrai dissolvere il tuo mandala e lasciarlo andare, per ricominciare dal bindu.');

  const html = '<div style="margin:0;padding:24px 12px;background:#FBF6FA;font-family:Helvetica,Arial,sans-serif;color:#3B2D4D">'
    + '<div style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:22px;padding:28px 24px;border:1px solid #EEE3F0">'
    + '<p style="margin:0 0 4px;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#8248AC;font-weight:700">Il tuo mandala di ' + nomeMese + '</p>'
    + '<h1 style="margin:0 0 16px;font-family:Georgia,serif;font-weight:400;font-size:26px;color:#3B2D4D">' + (nome ? 'Ciao ' + esc(nome) + ',' : 'Ciao,') + '</h1>'
    + '<p style="margin:0 0 18px;font-size:16px;line-height:1.55">' + esc(apertura) + '</p>'
    + (n && !a.sciolto ? disegno(P) : '')
    + (colori ? '<p style="margin:16px 0 6px;font-size:14px;color:#7A6B8A">I colori del tuo mese</p><div>' + colori + '</div>' : '')
    + extra.map(t => '<p style="margin:16px 0 0;font-size:15px;line-height:1.55">' + esc(t) + '</p>').join('')
    + '<p style="margin:24px 0 8px;text-align:center"><a href="' + SITO + '" style="display:inline-block;background:#3B2D4D;color:#FFFFFF;text-decoration:none;padding:12px 22px;border-radius:999px;font-weight:600;font-size:15px">Apri il tuo mandala</a></p>'
    + '<p style="margin:22px 0 0;font-size:15px;line-height:1.55">Con affetto,<br>Tiziana</p>'
    + '</div>'
    + '<p style="max-width:520px;margin:16px auto 0;font-size:12px;line-height:1.5;color:#7A6B8A;text-align:center">Ricevi questa mail ogni domenica perché pratichi con Bindu. Se non vuoi più riceverla, apri Bindu, tocca il tuo profilo in alto a destra e togli la spunta da «La mail della domenica».</p>'
    + '</div>';
  const testo = (nome ? 'Ciao ' + nome + ',' : 'Ciao,') + '\n\n' + apertura + '\n\n' + extra.join('\n\n') + (extra.length ? '\n\n' : '')
    + 'Apri il tuo mandala: ' + SITO + '\n\nCon affetto,\nTiziana';
  return { oggetto: oggetto, html: html, testo: testo };
}

/** Il mandala in mail: un cerchio colorato per ogni pratica, più grande se è durata di più. */
function disegno(P) {
  const punti = P.slice(-60).map(p => {
    const t = TINTE[p.sezione] || TINTE.mindfulness;
    const mm = Number(p.minuti) || 30, d = Math.round(Math.max(12, Math.min(26, 10 + mm / 4)));
    return '<span style="display:inline-block;width:' + d + 'px;height:' + d + 'px;margin:3px;border-radius:50%;background:' + t.chiaro + ';border:2px solid ' + t.scuro + ';vertical-align:middle"></span>';
  }).join('');
  return '<div style="text-align:center;padding:18px 12px;border-radius:18px;background:#F6EEFB">'
    + '<span style="display:inline-block;width:12px;height:12px;margin:3px 8px;border-radius:50%;background:#8248AC;vertical-align:middle"></span>'
    + punti + '</div>';
}

function esempioAllieva(oggi) {
  const g = n => new Date(oggi.getTime() - n * 864e5).toISOString();
  return { nome: 'Anna (esempio)', email: INSEGNANTE, sciolto: false, pratiche: [
    { at: g(12), sezione: 'yoga', minuti: 60, titolo: 'Lezione di yoga', tipo: 'presenza' },
    { at: g(9), sezione: 'movimento', minuti: 40, titolo: 'Camminata', tipo: 'camminata' },
    { at: g(5), sezione: 'mindfulness', minuti: 10, titolo: 'Silenzio · 10 min', tipo: null },
    { at: g(3), sezione: 'posturale', minuti: 56, titolo: "Posturale ottobre '26", tipo: 'video' },
    { at: g(1), sezione: 'movimento', minuti: 25, titolo: 'Camminata', tipo: 'camminata' }
  ] };
}

function anelli(n) { return n === 1 ? 'un anello' : n + ' anelli'; }
function dur(min) { min = Math.round(min); const h = Math.floor(min / 60), r = min % 60; return h ? (h === 1 ? "un'ora" : h + ' ore') + (r ? ' e ' + r + ' minuti' : '') : min + ' minuti'; }
function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]); }
