# Rotazioni P1–P6 — schemi forniti dall'utente

Riferimento: i 18 screenshot estratti da `posizioni.7z` in `.runtime/positions62/` (3 per cartella P). Corrispondenze: C1/2 = MB1/2, B1/2 = OH1/2, O = OPP, P = S, L = libero. La grafica dello schema è una disposizione tattica, non un vincolo che impedisce di inseguire la palla.

P indica la **zona regolamentare del palleggiatore**, non il numero di cambi palla trascorsi. L'indice interno, conservato per compatibilità con formazioni e salvataggi, segue l'ordine dei cambi palla:

| Indice interno | Nome mostrato | Servitore, se la squadra ha il servizio |
| --- | --- | --- |
| 0 | P1 | S |
| 1 | P6 | OH1 |
| 2 | P5 | MB1 |
| 3 | P4 | OPP |
| 4 | P3 | OH2 |
| 5 | P2 | MB2 |

Le identità restano stabili. OH1/OH2, MB1/MB2 e S/OPP sono opposti nel giro. Non si scambiano due bande perché una temporaneamente è più vicina alla palla. Il libero sostituisce il centrale di seconda linea, salvo il centrale che sta servendo.

## Difesa di base e responsabilità in attacco

Righe viste dalla propria metà campo verso la rete, da sinistra a destra:

| P | Prima linea difensiva | Seconda linea difensiva | Attacco sinistro / centro / destro / pipe |
| --- | --- | --- | --- |
| P1 | OPP · MB1 · OH1 | L · OH2 · S | OPP · MB1 · OH1 · OH2 |
| P2 | OH1 · MB1 · S | L · OH2 · OPP | OH1 · MB1 · OPP da seconda linea · OH2 |
| P3 | OH1 · MB2 · S | L · OH2 · OPP | OH1 · MB2 · OPP da seconda linea · OH2 |
| P4 | OH2 · MB2 · S | L · OH1 · OPP | OH2 · MB2 · OPP da seconda linea · OH1 |
| P5 | OH2 · MB2 · OPP | L · OH1 · S | OH2 · MB2 · OPP · OH1 |
| P6 | OH2 · MB1 · OPP | L · OH1 · S | OH2 · MB1 · OPP · OH1 |

P1 mantiene quindi l'opposto in zona 4 e OH1 in zona 2 anche nel rigioco e nel successivo muro. Vale per entrambe le squadre e anche quando P1 parte al servizio.

La prima linea di base è a 0,68 m dalla rete. Il libero copre inizialmente a sinistra (x=-2,85; profondità=4,65), la banda di seconda linea al centro (0; 5,35), S/OPP di seconda linea a destra (2,85; 4,65). Durante l'attacco avversario resta attiva la lettura dinamica esistente: pilone sul lato dell'attacco, centrale comandato, pilone opposto sui tre metri e difensori sulle corsie di diagonale/parallela. L2/R2 e il salto manuale continuano a funzionare.

## Ricezione

Le sei righe di `src/rotation_layout.gd::RECEIVE` trascrivono gli schemi in metri, con rete a profondità zero e campo largo nove metri. Le coordinate sono adattate dal disegno schematico: vengono verificati anche i piedi delle animazioni, le coppie avanti/dietro e l'ordine laterale al colpo di servizio. L'altra squadra viene ruotata di 180°, senza scambiare i ruoli.

Ricevono normalmente le due bande e il libero. OPP è escluso dall'assegnazione della ricezione, salvo la palla corta a sinistra quando in P1 occupa zona 4. S e centrali rimangono possibili ripieghi per i palloni non coperti, con le priorità preesistenti.

## Transizioni e corridoi

- L'alzatore anticipa il futuro punto della ricezione in zona 3, calcolato con l'offset della sua posa di palleggio, invece di avviarsi verso un punto di attesa incompatibile con il passaggio reale.
- In P6 l'opposto esce lateralmente dal gruppo O/S/C1 prima di arretrare per la rincorsa. Evita il passaggio diagonale tra i due compagni.
- Restano attivi i percorsi delle bande all'esterno, le riserve di spazio del palleggiatore e i controlli fisici tra corpi e piedi.
- Il centrale chiude la preparazione di primo tempo/7 prima del rilascio. Nel salto reale orienta progressivamente il corpo verso la rete, anche mentre il palleggiatore è ancora il giocatore del secondo tocco.
- Il primo tempo mantiene maggiore vicinanza a S rispetto alla 7, con un margine laterale per le loro impronte. Un salto reale parte solo da una distanza preparabile. Il rilascio della breve alzata condivisa verifica anche la frenata e l'arrivo previsto, non soltanto la distanza corrente; se manca l'accesso resta disponibile la costruzione di sicurezza già presente.
- La pipe usa la corsia centrale. Dopo aver alzato, S (o il libero che lo ha sostituito sul secondo tocco) esce lateralmente dal lato libero del centrale e mantiene la copertura corta, anziché arretrare nella traiettoria dell'attaccante. Il lato viene fissato per l'alzata. Il libero che non ha alzato prepara l'attacco sulla sinistra e continua a cedere il passo quando il corridoio del corridore lo richiede. Restano invariati lo stacco legale da fuori i tre metri, l'atterraggio dentro e la potenza degli attacchi.

I massimali di corsa, la fisica della palla, i tasti e il sistema di carica non sono stati aumentati per compensare gli incroci.
