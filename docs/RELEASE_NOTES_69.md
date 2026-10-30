# Spike Forever 0.69.0 — panchine, sostituzioni e controller

## Cause riscontrate nei video del 30 ottobre

- Il sistema procedurale del bordo campo assumeva il lato sinistro sul semiasse X negativo; nel rig importato il braccio sinistro è sul positivo. Alcune rotazioni della testa usavano inoltre assi locali non corrispondenti agli assi anatomici. Ne risultavano braccia incrociate e posture innaturali.
- I cambi usavano segmenti diretti verso il punto d'incontro, senza ostacoli e senza precedenza fra i due attori. Il rientro poteva attraversare allenatore o altro giocatore.
- Un aggiornamento delle identità della panchina durante il punto/replay poteva spostare la riserva su un'altra sedia prima dell'inizio della scena. Erano visibili solo sei riserve: gli ingressi delle altre usavano una posizione di ripiego non corrispondente a una seduta.
- Nello screenshot di conferma il controllo regolamentare indicava che lo scambio era ancora in corso. Il pulsante risultava disabilitato per la fase della partita. Una seconda causa di navigazione era il menu Pausa che poteva riprendersi il focus all'apertura del sottomenu.

## Animazioni e sostituzioni

Undici animazioni cinematiche originali di Spike Volleyball, convertite offline in AnimationLibrary nativa, sostituiscono le pose procedurali di panchina e allenatore. Applausi seduti, alzata/applauso, attesa, consigli e reazione del tecnico conservano i movimenti originali e vengono sfalsati fra gli attori. Valutazione manuale a 30 Hz tramite AnimationPlayer; nessuna nuova AnimationTree da partita e nessuna scrittura concorrente del sistema PSA.

La camminata della sostituzione usa il ciclo cinematico eretto, chiuso sulle pose iniziale/finale per eliminare il salto delle caviglie al riavvio. L'avanzamento del ciclo segue la distanza percorsa. L'alzata usa il tratto originale dell'animazione dalla panchina; la seduta ne usa il tratto inverso. Il cinque usa IK coerente con i lati anatomici e lo stesso punto di contatto per entrambe le mani.

La scena calcola i percorsi su una mappa riservata alla presentazione: dodici giocatori, riserve visibili, allenatori, tavolo, rete e seggiolone. La geometria dello staff è letta dalla posizione reale delle anche, non solo dall'origine dei nodi. L'ingresso attende quando necessario che l'uscente abbia liberato il percorso. I punti d'incontro restano distinti, con circa 80 cm fra i due attori. Se non esiste un percorso libero la scena viene omessa mantenendo il cambio regolamentare, senza inventare attraversamenti.

Fino a otto riserve visibili per squadra, con panchine allungate. I posti dei giocatori non coinvolti rimangono stabili; la sedia della riserva entrante viene conservata prima del cambio d'identità. Gli eventuali atleti oltre la capienza visiva provengono dall'area di riscaldamento e non si siedono su posti inesistenti.

## Controller e cambi durante lo scambio

Conferma raggiungibile da tutte le riserve tramite D-pad/stick, con navigazione fra lista e conferma e ritorno con Cerchio/B. Il menu Pausa non sottrae più il focus al sottomenu.

Durante uno scambio il comando diventa **PROGRAMMA SOSTITUZIONE**: confermando si riprende l'azione e il cambio viene applicato alla prima palla ferma consentita. Non vengono modificati giocatori o conteggi a palla viva. Restano attivi limiti di sei sostituzioni, abbinamenti titolare/riserva, rientri e indisponibilità. Le richieste duplicate vengono rifiutate e le richieste pendenti sono cancellate abbandonando la partita.

Richieste dell'ospite, coda e presentazione sono gestite dall'host e sincronizzate con protocollo SF069. La scena conserva punteggio, RNG e contatti della simulazione.

## Verifiche

- `substitution69-tests.json`: 42 combinazioni controller, comprese tutte le riserve in basso, in pausa su servizio e su alzata. Cambio programmato applicato dal tick reale alla palla ferma; controllo dei percorsi a 40 campioni/s; aggiornamento della panchina prima della scena e conservazione delle sedute. Distanza minima misurata fra attori circa 78 cm; distanza fra polsi durante il cinque circa 3 mm.
- `substitution69-online-host.json` e `substitution69-online-guest.json`: due istanze ENet reali, richiesta dell'ospite durante scambio, applicazione a palla ferma, scena e ripresa sincronizzate, un solo cambio conteggiato.
- `substitution69-regression.json`: nove verifiche riuscite, comprendenti UI in tre risoluzioni, panchine, stato dopo la scena, formati carriera, overall, finestra verde, recuperi e replay.
- `sideline69-sources.json`: provenienza degli undici clip e verifica dell'altezza delle anche nelle sequenze sedute/in piedi.
- `sideline69-performance.json`: microbenchmark CPU del solo bordo campo, 18 attori di squadra e tre ufficiali, circa 0,18 ms per aggiornamento su 1.000 campioni; non è una misura degli FPS dell'intera partita.
- `sideline69-*.png`: catture renderizzate delle nuove pose e delle fasi del cambio, incluso il cinque.

## Incluse tutte le novità della 0.68

Interfaccia carriera ripulita; scelta iniziale fra incontri al meglio dei tre o cinque set, con set decisivo a 15; punti in classifica 3/0 per il 2–0 e 2/1 per il 2–1. Tre telecamere offline, replay anche sui punti da attacchi sovraccaricati, palla V200W e ufficiali al tavolo.

Overall aggiornati: palleggiatore con ricezione 0% e palleggio 50%; opposto con ricezione 0% e difesa 15%; libero con difesa 40% e palleggio 15%. Tutti gli altri pesi sono invariati. Il ricalcolo si applica anche al caricamento delle carriere e alle modifiche locali, preservando i fondamentali individuali. [Dettagli della 0.68](RELEASE_NOTES_68.md).

Pacchetto Windows completo e sorgenti pubblicati insieme. I dati personali restano in locale. Nessuna installazione automatica sulla cartella di gioco viene eseguita dalla pubblicazione.
