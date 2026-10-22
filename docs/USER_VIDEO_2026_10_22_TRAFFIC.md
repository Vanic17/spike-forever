# Analisi del recupero nel video utente

File osservato: `Spike Forever (DEBUG) 2026-10-22 13-16-10.mp4`.

## Evidenza visiva

Negli ultimi scambi, circa 74.15–76.15 secondi, il libero effettua un recupero basso nel centro del campo. Il numero 6 si avvicina alla zona del secondo tocco mentre il libero sta ancora rialzandosi. Il numero 5 occupa la zona immediatamente davanti. L'avvicinamento del numero 6 presenta una deviazione e un arresto/correzione molto ravvicinati al libero; l'animazione di alzata termina senza produrre un attacco, e il punteggio passa da 3–7 a 3–8.

Dal solo video non si può stabilire quale tasto sia stato premuto, né distinguere con certezza una validazione del contatto fallita da un input fuori finestra. Le tre cause di codice sotto sono però riproducibili senza input umano.

Immagini estratte: `user-131610-tail-sheet.jpg`, `user-131610-dig-sheet.jpg`, `user-131610-dig-close.jpg`. Il primo pannello del dettaglio corrisponde a circa 74.15 secondi; i pannelli successivi sono distanziati di 0.25 secondi.

## Cause nel codice iniziale

1. `avoid_teammates()` prendeva in considerazione soltanto la radice dell'altro atleta, mentre `collision_safe_step()` verificava anche l'impronta estesa di un giocatore a terra. Il palleggiatore poteva quindi accorgersi troppo tardi del busto del libero, pur avendo una linea libera rispetto alla sola radice.
2. `avoid_teammates()` interrompeva la correzione per l'attore del contatto negli ultimi 0.65 metri, mentre il controllo delle collisioni continuava a bloccarlo.
3. `court_shape` chiedeva anche a un giocatore impegnato nel recupero a terra di spostarsi lateralmente per liberare il corridoio. Il movimento prescritto da `advance_dive_body()` aveva invece la precedenza fino al termine del clip: il libero non poteva eseguire quella richiesta.

## Verifica aggiunta

`tools/Test-RecoveryTraffic.gd` riproduce una penetrazione di 2.5 metri del palleggiatore, con un atleta in fase di recupero da un tuffo. La radice del difensore si trova a 1.45 metri dal segmento iniziale e non ostruisce la destinazione del secondo tocco; il busto esteso attraversa invece il corridoio. Il clip del tuffo continua con la sua root motion originale. Il volo della palla dura quanto previsto da `Reference.receive_seconds(0.65, false)`; non viene allungato per consentire il recupero del palleggiatore.

Il test copre entrambe le metà campo a 60 e 120 Hz, registra contatto effettivo, distanza dalle impronte, arresti improvvisi e percorso. Il controllo finale non va limitato alla distanza fra le radici dei due giocatori.

Risultato dopo la correzione: quattro secondi tocchi effettivi su quattro, tutti entro il volo originale di 1.2075 secondi; distanza minima dalla sagoma del recupero 0.980680 metri; nessun arresto improvviso; errore finale rispetto alla posizione prevista 0.0864 metri a 60 Hz e 0.1351 metri a 120 Hz. Due verifiche aggiuntive controllano che anche il busto esteso del giocatore che si muove venga incluso nella collisione, in entrambe le metà campo.

`tools/Capture-RecoveryTraffic.gd` usa la medesima funzione di preparazione del test. La ripresa dura otto secondi e mostra i due casi speculari con camera ravvicinata. Non è una riproduzione degli input sconosciuti del video utente: è una verifica controllata del problema riscontrato.

## Aspetti emersi durante la correzione

Un waypoint per aggirare il corpo non è una destinazione in cui rallentare: la velocità di arrivo deve considerare la lunghezza rimanente dell'intero percorso fino al contatto e deve mantenere invariata la velocità massima esistente. Se un bypass è assegnato al palleggiatore, il compito di movimento deve restare `contact`, conservando la risposta immediata alla traiettoria del secondo tocco.
