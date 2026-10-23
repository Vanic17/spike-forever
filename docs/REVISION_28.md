# Secondo tocco e traffico dei compagni — 0.28.0

Analizzato il finale del video `Spike Forever (DEBUG) 2026-10-23 12-39-32.mp4` (durata 56,4 secondi). Il palleggiatore si ferma durante la costruzione in un gruppo di compagni dopo il recupero, pur tentando il contatto.

## Cause concrete

- Il collision guard proteggeva tutte le impronte corporee, ma il routing aggirava soltanto i giocatori a terra. Il bagher di un atleta in piedi aggiunge temporaneamente una seconda impronta: il navigatore non la vedeva.
- Il percorso attorno a un corpo non verificava sempre gli altri corpi sul secondo tratto.
- Gli ordini delle bande potevano sovrascrivere la precedenza di chi lasciava spazio al palleggiatore.
- La cache poteva attendere 0,12 secondi anche dopo che un tuffo aveva occupato tutti i passaggi calcolati.
- La ricezione veniva inizialmente indirizzata alle coordinate dei piedi del gesto generico, prima della scelta del vero atleta e della variante di palleggio.

## Correzione

`contact_navigation.gd` calcola il percorso del secondo tocco su tutte le impronte reali di entrambi i corpi interessati. Prima prova il tratto diretto; soltanto se ostruito usa una griglia deterministica da 25 cm. Ogni scorciatoia viene ricontrollata contro i corpi reali. La pianificazione considera anche i successivi 0,18 secondi del movimento originale del tuffo. Cache a 0,12 secondi, con riparazione entro 0,03 secondi quando il percorso diventa completamente ostruito.

Il controllo fisico delle collisioni rimane attivo. Non vengono rimossi corpi né spostati giocatori istantaneamente. Il costo misurato isolato del navigatore con un tuffo reale è p95 0,598 ms, massimo 0,759 ms; non è una misura del tempo totale di un frame renderizzato.

La precedenza al contatto supera l'apertura tattica del compagno. Chi deve lasciare il passaggio esegue un aggiustamento prioritario, con un piccolo movimento procedurale delle spalle sovrapposto ai passi esistenti. Non sono nuovi file PSA e non cambiano la scrittura esclusiva PSA/AnimationTree, l'IK o i contatti esatti.

Prima di lanciare la ricezione, il sistema riserva anche il punto di appoggio della variante e dell'atleta effettivamente scelti. Il tempo di prima palla tiene conto della deviazione fisica prima del lancio, con un incremento massimo di 0,85 secondi rispetto al tempo ordinario.

Se il palleggio alto diventa irraggiungibile, il sistema valuta un bagher in avanzamento. Intercetta più in basso la stessa traiettoria: posizione, velocità, spin e gravità non vengono cambiati. Il comando del giocatore resta necessario e la validazione mani/palla rimane obbligatoria. Una palla realmente irraggiungibile può ancora cadere.

## Verifiche

- `Test-ContactTraffic28`: 20 secondi tocchi reali, barriere di giocatori in piedi, compagni a terra, centrale vicino alla rete, due squadre, 60/120 Hz. Nella riproduzione precedente fallivano 8 dei 16 casi controllati. Ora passano 20/20 inclusi quattro casi della pipeline reale ricezione–alzata.
- Due verifiche mirate del bagher di emergenza confermano l'invarianza della traiettoria e il successivo contatto fisico più basso.
- `Test-ContactNavigation28`: 1.606 controlli isolati, inclusi due ostacoli insieme, endpoint occupato e un corpo spostato dopo il calcolo della cache.
- `Test-RecoveryTraffic`: quattro alzate con deadline originale di 1,2 secondi, nessun arresto brusco, errore finale 0,009–0,019 m e distanza dai corpi superiore a 1 m.
- `Test-SetterCrowd`: 18 secondi tocchi congestionati. Aggiornato il limite temporale della fixture per attendere il volo pianificato, anziché fermare la simulazione arbitrariamente a due secondi.
- Restano superate 192 sequenze ricezione–alzata, 36 sequenze fino alla schiacciata, 48 casi muro, continuità delle animazioni e test menu/roster.

I casi sintetici riproducono le cause del blocco; non sono una riesecuzione deterministica del video originale.
