# Spike Forever 0.82.0

## Database online

Corretto il conflitto quando host e ospite scelgono la stessa squadra: gli ID originali dei giocatori potevano sovrapporsi nel registro di gestione della partita, mescolando rose e affaticamento. Ogni squadra ora ha identità separate durante la sessione, con riferimento al rispettivo ID del database. Le modifiche personali restano nei file locali di chi le ha create.

Verificati due client reali con la stessa squadra e database diversi: nome, numero, sei statistiche, overall ricalcolato, aspetto, mano e preferenza di servizio. La simulazione legge i valori della squadra corretta e la stanchezza di una copia del giocatore non modifica l'altra. Verificate sia l'opzione valori attivi sia quella originale senza modificatori. Controllato anche il flusso online di sostituzione con scena e ripresa del gioco.

## Invito più semplice

Il codice da digitare passa a **13 caratteri**, con controllo degli errori e riconoscimento delle lettere ambigue. Si può anche copiare l'invito dall'host e usare **INCOLLA E UNISCITI** sull'altro PC. La tastiera virtuale e la navigazione con controller restano disponibili; i vecchi formati vengono ancora riconosciuti.

Il codice contiene direttamente indirizzo IPv4 e identificativo della stanza. La connessione utilizza la raggiungibilità UDP dell'host tramite UPnP, inoltro porta o rete/VPN LAN, come il trasporto esistente. Il formato breve usa la porta standard 26761; le porte personalizzate mantengono l'invito completo.

## LED di casa e sponsor

ACE e MONSTER BLOCK compaiono sui LED perimetrali, con pulsazione di luminosità, logo della squadra di casa e relativa palette. Per divise prevalentemente bianche o molto scure viene utilizzato il colore secondario, mantenendo la tinta nella scritta. Le scritte durano circa quattro secondi, poi riprende la rotazione degli sponsor. Vengono mostrate soltanto quando segna la squadra di casa; il controllo è basato sull'identità di casa, indipendentemente dal giocatore umano e dalla telecamera. L'evento viene sincronizzato anche sull'altro client online.

Il monster viene riconosciuto dal contatto effettivo di muro chiuso e annullato se l'azione continua con un nuovo tocco. L'ace segue il registro del servizio: un'azione che prosegue con un'alzata non viene presentata come ace. Nessun messaggio centrale sostituisce i LED.

Il marchio sul parquet, nei pannelli e sui pali ora usa il solo **CREDEM**, estratto dall'immagine originale. Aggiornata anche la pedana dell'arbitro. Il logo ufficiale della competizione nell'overlay mantiene la propria grafica originale.

## Pubblico, tavolo e collisioni

Il pubblico dispone di dodici pose invece di otto. Geometrie con livelli di dettaglio precalcolati e gruppi separati per tribuna migliorano il costo di rendering conservando il numero di spettatori. Rivisti i materiali; al tavolo sono presenti figure con capelli e ritmi di lavoro differenziati, con piccoli orientamenti del capo verso il gioco.

La palla interagisce con arredi esterni, pannelli, persone in panchina, segnapunti e pubblico attraverso volumi di collisione semplificati. Il controllo continuo lungo il movimento evita di attraversarli ad alta velocità. Un contatto esterno termina l'azione come fuori; dopo il punto la palla continua a rimbalzare sugli oggetti senza assegnare altri punti. Il percorso nel campo regolamentare, la rete e i contatti dei dodici giocatori conservano i sistemi esistenti. Le nuove collisioni impiegano una griglia spaziale e vengono escluse rapidamente quando la palla rimane dentro il campo.

## Prestazioni e verifiche

Confronto locale a 1280x720, RTX 5080, stessa scena e stesso numero di spettatori: il rendering della scena con pubblico e panchine passa da circa 2,46 a 1,76 ms medi; primitive renderizzate da 13,18 a 4,12 milioni. Nel test separato con ricezione, alzata e pipe ripetute il frame medio passa da 10,54 a 10,46 ms, con identici contatti. Il miglioramento maggiore riguarda quindi il costo del pubblico; i numeri non rappresentano una garanzia degli FPS di una partita completa o di altri PC.

Verificati codici nuovi/precedenti, due client reali, database ON/OFF, nessuna modifica ai file personali, eventi LED delle dodici squadre, collisioni e chiusura corretta del punto. Passate le regressioni di stadi, attrezzatura, input di Diventa un mito, battuta, finta di seconda, attacchi e difese.

Rapporti: `online82-database-host.json`, `online82-database-guest.json`, `online82-codes.json`, `arena82-tests.json`, `arena82-performance-before.json`, `arena82-performance-after.json`, `arena82-rally-before.json`, `arena82-rally-after-new.json`. Anteprima `arena82-led-preview.mp4`.

Protocollo SF082: aggiornare entrambi i client. Aggiornamento selettivo mantenuto; carriere, campionati e database personale in `user://` sono conservati.
