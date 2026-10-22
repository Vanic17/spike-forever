# Revisione 05 — ruoli, rotazioni e muro

Riferimenti: sequenza della partita reale intorno a 69–73 s; regolamento FIVB 2025–2028, capitoli 7, 13, 14 e 19; materiale tecnico USA Volleyball.

## Sistema 5–1

Il ruolo appartiene al giocatore, non alla posizione attuale nella rotazione. Identica rosa fissa per le due squadre:

| Numero | Ruolo |
| --- | --- |
| 1 | Schiacciatore 1 |
| 2 | Centrale 1 |
| 3 | Opposto |
| 4 | Schiacciatore 2 |
| 5 | Centrale 2 |
| 6 | Palleggiatore |
| 7 | Libero, sostituisce il centrale in seconda linea |

Sei atleti in campo. Il libero usa la maglia di colore opposto e il numero 7. La sostituzione è rappresentata cambiando l'atleta visualizzato nello slot del centrale, senza animazione della panchina. Il centrale resta al servizio nel proprio turno: il libero non serve, non attacca sopra rete e non va a muro.

Il palleggiatore resta il numero 6 attraverso tutte le rotazioni. L'alzata passa a un compagno solo se ha ricevuto il primo tocco o non è fisicamente in grado di arrivare. La scelta d'emergenza esclude il libero per evitare un'alzata in palleggio dalla zona d'attacco non compatibile con il successivo attacco sopra rete.

Ricezione principalmente a schiacciatori e libero, valutando distanza dalla posizione effettiva delle mani. Attacco in zona 4 allo schiacciatore di prima linea, veloce al centrale, zona 2 all'opposto. Se l'opposto è di seconda linea riceve una palla D con stacco dietro i 3 m; pipe allo schiacciatore di seconda linea. I giocatori non cambiano ruolo inseguendo la palla più vicina.

## Rotazione e coordinate

Ordine delle zone nel codice: `[4,3,2,1,6,5]`. Corretta la progressione da `indice-rotazione` a `indice+rotazione`: zona 2 → zona 1 al cambio palla. Il battitore segue lo stesso ordine. Le coordinate della CPU sono ruotate di 180°, includendo X e Z; la vecchia sola inversione di Z scambiava destra e sinistra per gli avversari.

Le posizioni di partenza rispettano l'ordine di rotazione fino al contatto del servizio; durante questa fase lo stick sinistro non sposta i ricevitori. Dopo il colpo si passa alle posizioni specialistiche: palleggiatore verso zona 2/3, centrale al centro, schiacciatore a sinistra, opposto a destra, difesa distribuita fra libero, schiacciatore e giocatore di seconda linea sul lato destro.

## Muro e separazione

- Solo i tre giocatori di prima linea sono candidati al muro. Primo responsabile del lato, poi centrale in chiusura, terzo giocatore solo quando il gameplay concede un muro a tre.
- Assegnazioni congelate per l'alzata: nessuno cambia continuamente compagno di muro o attraversa intenzionalmente il suo corridoio.
- Bersagli distanti 0,90 m. Il limite laterale sposta l'intera formazione prima di applicare gli scarti: i bersagli non collassano più sulla stessa coordinata vicino all'antenna.
- Trasferimento laterale dietro la corsia di rete, poi ingresso accanto al compagno. Il salto richiede arrivo vicino al proprio bersaglio e spazio laterale sufficiente. Chi arriva tardi resta fuori dal salto.
- Assegnazioni mantenute nella fase iniziale dell'atterraggio. Gli altri giocatori coprono pallonetti, linea e diagonale, senza convergere sulla posizione dell'attaccante o del muro.
- Aggiramento preventivo dei compagni e controllo continuo dei segmenti di movimento con spazio minimo di 0,78 m fra i centri. A contatto si scorre lateralmente, senza spostamenti istantanei per separare due corpi.

La distanza di 0,78/0,90 m è una scelta di implementazione relativa ai modelli del gioco, non una prescrizione FIVB.

## Verifiche

Anteprima finale: `Spike Forever - ruoli rotazioni e muro.mp4`, 30 secondi, 1280×720 e 1800 fotogrammi. Registrazione della build con bot; codifica e decodifica completa verificate senza errori FFmpeg. Il frame rate del filmato è quello della registrazione, non una misura delle prestazioni in tempo reale. Resta il precedente avviso Godot ObjectDB alla chiusura della cattura.

108 scenari di muro: 6 rotazioni × 2 squadre × 3 direzioni (comprese antenne) × 3 formazioni. Ogni scenario simula 150 passi, verifica candidati legali, bersagli distinti e assenza di intersezione dei corpi. Distanza minima osservata fra muratori: 0,844 m.

Simulazione con asset originali: 16 punti, 186 contatti, distanza minima giocatori 0,788 m e muratori 0,835 m. Fallback senza asset: 16 punti, 109 contatti, minimo giocatori 0,788 m e muratori 0,842 m. Restano attive le regressioni di Quadrato, contatti, appoggi e rimbalzi. `Verifica.cmd` fallisce anche quando una simulazione scende sotto 0,775 m.

I controlli riguardano i corpi e i casi simulati; non dimostrano ogni possibile combinazione di braccia, pallone e contatto di rete. La tattica implementa un sistema 5–1 fisso, senza strategie personalizzabili o completa gestione arbitrale delle sostituzioni.

## Fonti

- [FIVB Official Volleyball Rules 2025–2028](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-v05.pdf): ordine, posizione e rotazione; prima/seconda linea; libero.
- [USA Volleyball: Rules of Volleyball](https://usavolleyball.org/play/rules-of-volleyball/): sistemi 5–1 e 6–2.
- [USA Volleyball: Staying Square to the Net While Blocking](https://usavolleyball.org/resource/staying-square-to-the-volleyball-net-while-blocking-five-steps/): responsabilità del laterale e chiusura del centrale, stabilità del salto e relazione con la difesa.
- [USA Volleyball: 10 Keys to Middle Blocking](https://usavolleyball.org/resource/10-keys-to-middle-blocking/).

Backup dei sorgenti precedenti: `baseline-v04`. Nessuna logica AI è stata estratta dal programma originale Spike Volleyball; le animazioni e i modelli già integrati restano quelli locali.
