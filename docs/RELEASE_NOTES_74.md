# Spike Forever 0.74.0 — Ricezione e comandi di Diventa un mito

## Ricezione più permissiva, solo per l'atleta manuale

Il comando della ricezione in Diventa un mito non accumula più due penalità per la stessa anticipazione: la qualità dipende dal tempo rispetto all'arrivo, mentre posizione e raggiungibilità restano controllate dal contatto fisico condiviso. La finestra perfetta è più ampia; anticipo e ritardo degradano gradualmente il risultato. Il margine tardivo arriva a 200 ms, sempre subordinato all'esistenza di un contatto reale prima che la palla tocchi terra.

Prova con traiettorie fisiche e identico atleta: +80 ms = 100% anziché 94%; +250 ms = 88% anziché 66%; +500 ms = 62% anziché 26%; −60 ms = 88% anziché 42%. Sono valori di tempismo prima dei modificatori delle statistiche e della fatica. Un giocatore lontano dal pallone continua a mancarlo; non sono stati aggiunti tocchi invisibili, spostamenti automatici o salvataggi senza input.

Il motore resta quello dell'esibizione. Nessuna modifica alle sue finestre di ricezione, alla fisica della palla, ai valori della CPU o alle cariche di servizio/attacco.

## Bagher, palleggio e tuffo distinti

| Situazione | PlayStation | Xbox | Tastiera |
| --- | --- | --- | --- |
| Primo tocco in bagher | Croce | A | Spazio |
| Primo tocco sopra la testa | Quadrato | X | Q |
| Alzata normale al secondo tocco | Croce | A | Spazio |
| Alzata veloce al secondo tocco | Quadrato | X | Q |
| Tuffo difensivo | R2 | RT | C |
| Salto in attacco / a muro | R1 | RB | R |
| Movimento / mira | LS / RS | LS / RS | WASD / frecce |
| Scatto / chiama alzata | L2 / L1 | LT / LB | Maiusc / F |
| Seconda del palleggiatore | Cerchio | B | E |

Quadrato/X sul primo tocco usa il gesto nativo del palleggio, con contatto realmente sopra la testa. L'intercettazione viene calcolata sulla medesima traiettoria alla quota delle mani; velocità, posizione, spin e gravità non cambiano. Il tocco è registrato come ricezione/difesa, non come alzata. Se la palla è ormai troppo bassa, viene usato il bagher con un messaggio esplicito.

Il tuffo continua a usare i recuperi e le animazioni native dell'esibizione. Una pressione leggermente anticipata rimane preparata per un breve intervallo, senza avviare subito la corsa o sottrarre la palla a un compagno. Quando compare un recupero raggiungibile viene eseguito; se non è raggiungibile, lo comunica. Un tentativo fallito non lascia il ricevitore o il palleggiatore IA sostituito dal personaggio manuale.

Il collegamento temporaneo tra ricezione e gesto sopra la testa viene ripulito anche se si esce dalla carriera durante l'atterraggio: non può finire nell'esibizione successiva.

## Feedback giocabile

Una scheda centrale mostra il gesto previsto, il comando, il tempo rimanente e quando premere. Se serve spostarsi, indica di raggiungere il punto di contatto. Dopo la pressione distingue anticipo, buon tempo, ritardo, tocco preparato, richiesta di tuffo memorizzata e mancato contatto.

Sono separati il tempismo e l'errore di posizione: una buona pressione non viene descritta come tocco riuscito quando la palla era fuori portata. Azioni indisponibili, libero a muro, salto di servizio, recupero in corso e seconda non eseguibile hanno spiegazioni contestuali. Aiuto e comandi sono aggiornati in italiano e inglese.

## Verifiche

- 207 controlli e 143 eventi reali nel sistema input di Godot: dispositivi 0/3/7, tasti PlayStation/Xbox, tastiera, stick, carica/rilascio, tuffo, riarmo del grilletto, pausa e replay.
- Contatti nativi distinti di bagher e palleggio; tuffo anticipato che entra effettivamente nell'animazione; pallone non comandato che non viene salvato.
- 114 controlli visivi e 18 schermate native a 720p, 1080p e 1440p, senza sovrapposizioni con punteggio e barra della potenza.
- Regressioni: 322 controlli di partita manuale, 16 sul risultato/salvataggio e confronto esatto tra i motori su 1.800 passi di simulazione e 120 passi con dodici pose native. La diversa tolleranza è applicata solo agli input della ricezione del personaggio manuale.

Rapporti: `legend75-inputs.json`, `legend75-feedback-visual.json`, `legend75-feedback-review.md`, `legend75-regression.json`. Salvataggi e modifiche personali rimangono compatibili con la 0.73.
