// Bindu · collegamento al database
// Copia qui i due valori da Supabase → Project Settings → API (vedi GUIDA.md, passo 3).
// La chiave "anon" / "publishable" è fatta per stare in un sito pubblico: è protetta dalle regole
// di sicurezza del database. NON incollare mai qui la chiave "service_role" / "secret".

window.BINDU_CONFIG = {
  supabaseUrl: 'https://muakbnnfscwciogulmqt.supabase.co',          // es. 'https://abcdefgh.supabase.co'
  supabaseAnonKey: 'sb_publishable_WzlI0_oib_6AJhBotkad_A_kUZsINNa',   // una riga lunga che inizia con 'eyJ' oppure 'sb_publishable_'

  // Codice anche via telefono: lascia '' (solo email), oppure 'sms' o 'whatsapp'
  // dopo aver collegato Twilio in Supabase (GUIDA.md, passo 8).
  telefono: ''
};
