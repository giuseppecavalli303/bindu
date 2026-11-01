-- =====================================================================
-- Bindu · contenuti d'esempio per novembre 2026 (facoltativo)
-- Servono a vedere subito l'app piena. Hanno l'etichetta "Esempio"
-- e tua moglie può modificarli o eliminarli dall'app.
-- =====================================================================

insert into public.temi (sezione, mese, titolo, sottotitolo, testo, approfondimenti, esempio) values
('yoga', '2026-11', 'Radicamento', 'Trovare stabilità quando le giornate si accorciano',
 $t$A novembre la natura rallenta e torna verso la terra. Anche la pratica segue questo movimento: lavoriamo sulle posizioni in piedi e sulle torsioni a terra, per sentire il contatto con il suolo e la base del bacino.

Ogni lezione del mese parte da Tadasana, la posizione della montagna, e torna lì alla fine: un punto fermo da cui osservare cosa è cambiato.$t$,
 $j$[{"titolo":"Muladhara, il chakra della radice","testo":"Nella tradizione dello yoga Muladhara si trova alla base della colonna ed è collegato all'elemento terra, alla sicurezza e alla fiducia. Lavorare sul radicamento significa dare al corpo un appoggio stabile prima di cercare l'apertura."},{"titolo":"Le asana del mese","testo":"Tadasana (montagna), Virabhadrasana II (guerriero II), Vrksasana (albero), Malasana (ghirlanda), Balasana (bambino). Tieni a portata di mano un mattoncino e una coperta."}]$j$::jsonb, true),
('posturale', '2026-11', 'La colonna e il respiro', 'Mobilizzare il tratto dorsale con il diaframma',
 $t$Passiamo molte ore seduti e il tratto dorsale tende a irrigidirsi. Questo mese colleghiamo ogni movimento della colonna al respiro: l'inspiro accompagna l'estensione, l'espiro la flessione.

Gli esercizi sono adatti a tutti e si possono ripetere a casa anche per dieci minuti al giorno.$t$,
 $j$[{"titolo":"Il diaframma, muscolo posturale","testo":"Il diaframma si inserisce sulle vertebre lombari: quando respiriamo male, anche la postura ne risente. Imparare a respirare in modo ampio aiuta a scaricare la zona lombare."},{"titolo":"Esercizio da fare a casa","testo":"Seduti sul bordo della sedia, piedi a terra. Inspirando allunga la colonna verso l'alto, espirando arrotonda la schiena vertebra per vertebra. Ripeti 8 volte, lentamente."}]$j$::jsonb, true),
('mindfulness', '2026-11', 'Il corpo come àncora', 'Tornare al presente attraverso le sensazioni',
 $t$Quando la mente corre, il corpo resta sempre qui. Questo mese usiamo il body scan e l'ascolto del respiro per riportare l'attenzione al momento presente.

Non serve fare nulla di speciale: basta accorgersi di dove si trova l'attenzione e riportarla, con gentilezza, al corpo.$t$,
 $j$[{"titolo":"Cos'è il body scan","testo":"È una pratica in cui si porta l'attenzione, una parte alla volta, dai piedi alla testa, osservando le sensazioni senza giudicarle. Si può fare da sdraiati o seduti."}]$j$::jsonb, true);

insert into public.contenuti (tipo, sezione, mese, titolo, descrizione, testo, durata, livello, settimana, quando, dove, esempio) values
('video', 'yoga', '2026-11', 'Lezione 1 · Saluto alla terra', 'Sequenza di radicamento con posizioni in piedi e chiusura in Balasana.', null, '60 min', 'Tutti i livelli', 1, null, null, true),
('video', 'yoga', '2026-11', 'Lezione 2 · L''albero e l''equilibrio', 'Lavoro sull''appoggio dei piedi e su Vrksasana, con varianti al muro.', null, '60 min', 'Principianti', 2, null, null, true),
('video', 'posturale', '2026-11', 'Mobilità dorsale con il respiro', 'Esercizi a terra e in quadrupedia per sciogliere il tratto dorsale.', null, '50 min', 'Tutti i livelli', 1, null, null, true),
('audio', 'mindfulness', '2026-11', 'Body scan di 15 minuti', 'Da sdraiati, dai piedi alla testa. Ideale la sera prima di dormire.', null, '15 min', null, 1, null, null, true),
('audio', 'mindfulness', '2026-11', 'Tre respiri per ricominciare', 'Una pausa breve da usare durante la giornata.', null, '5 min', null, 2, null, null, true),
('articolo', 'yoga', '2026-11', 'Perché iniziamo sempre da Tadasana', 'La posizione più semplice è anche quella che ci dice di più su come stiamo.',
 $t$Tadasana sembra una posizione in cui non succede niente: si sta in piedi, fermi. Eppure è lì che possiamo notare come distribuiamo il peso, se un'anca è più alta dell'altra, se le spalle salgono verso le orecchie.

In questo mese di radicamento torniamo a Tadasana all'inizio e alla fine di ogni lezione. Prova a farlo anche a casa: un minuto, a occhi chiusi, sentendo i piedi sul pavimento.$t$, null, null, 1, null, null, true),
('articolo', 'posturale', '2026-11', 'Seduti otto ore: cosa succede alla schiena', 'Piccole abitudini per proteggere la colonna durante il lavoro.',
 $t$Stare seduti a lungo non è un problema in sé: il problema è stare fermi nella stessa posizione. La colonna ha bisogno di movimento per nutrire i dischi intervertebrali.

Ogni ora alzati, fai tre respiri ampi allungando le braccia verso l'alto e qualche rotazione delle spalle. Sono due minuti, ma fanno la differenza.$t$, null, null, 2, null, null, true),
('diretta', 'yoga', '2026-11', 'Yoga del radicamento', 'Porta il tappetino e una coperta.', null, '75 min', null, null, '2026-11-06T18:30', 'In studio', true),
('diretta', 'posturale', '2026-11', 'Posturale · la colonna e il respiro', 'Lezione online: il link arriva il giorno prima.', null, '60 min', null, null, '2026-11-11T19:00', 'Online', true),
('diretta', 'mindfulness', '2026-11', 'Meditazione di gruppo', 'Body scan guidato e condivisione finale.', null, '45 min', null, null, '2026-11-15T10:00', 'In studio', true);
