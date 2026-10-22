# Versione 0.24.0

## Corsie di attacco per tutto lo scambio

La disposizione mostrata è la ricezione R1: OPP si trova a sinistra e OH1 a destra. La v22 correggeva solo la prima palla; la classificazione `incoming_kind` passava poi da `serve` a `spike` e ripristinava l'opposto a destra. Il destinatario dell'alzata dietro cambiava nonostante la rotazione e la disposizione non fossero cambiate. La v23 conservava quelle corsie a muro, ma non ancora in attacco.

Ora `rally_lanes.gd` assegna le corsie all'inizio dello scambio e le mantiene per tutti i possessi fino al punto successivo. In R1 in ricezione OH1 conserva la zona 2 e OPP la zona 4 anche al rigioco. La nuova assegnazione viene ricostruita alla preparazione successiva, tenendo conto di chi batte e della rotazione effettiva.

Palleggio normale e veloce, scelta CPU, apertura della rincorsa, copertura, primi aggiustamenti dopo la difesa e muro usano lo stesso piano. Il primo passo dopo un nuovo bagher non torna brevemente verso il lato opposto. Non viene scelto genericamente il giocatore più vicino: identità, slot regolamentari, prima/seconda linea, esclusione del libero e del secondo toccatore restano controllati. Nelle altre rotazioni rimangono le opzioni specialistiche e i punti di stacco legali della seconda linea.

`Test-RallyPins.gd` controlla le sei rotazioni, entrambe le squadre e i lati di servizio, sei tipi successivi di palla nello stesso scambio, coerenza di muro/attacco e aggiornamento al cambio servizio. Include otto sequenze con veri contatti ricezione–alzata dietro–attacco, ripetute sul secondo possesso con PSA e AnimationTree.

## Quindici animazioni aggiuntive

Cinque fonti distinte di ricezione, cinque di alzata e cinque di schiacciata, prima inutilizzate nel gioco, portano la libreria da 33 a 48 clip. Sono performance originali dell'archivio, non alias, semplici rinominazioni o nuove registrazioni create ora. L'elenco e gli SHA256 sono nel manifest `assets/active/new_animations_24.json`; dettagli in `ANIMATION_24.md`.

La selezione considera lato/distanza della palla, velocità d'arrivo, qualità, direzione e contesto del gesto. La variante resta fissata per il piano corrente durante accelerazione e frenata; un nuovo colpo o una nuova scelta di direzione può cambiarla. Questo evita variazioni dell'offset delle mani negli ultimi passi. Restano parser PSA, fallback F6, IK, correzione piedi, AnimationTree condiviso e separazione del movimento del corpo dalla posa visiva.

I test verificano fonti e keyframe unici, contatti in tre posizioni sulle due metà campo e con entrambi i backend, transizioni senza scatti d'ingresso e lunghezze degli arti. La libreria nativa è preconvertita; il benchmark locale non ha rilevato un incremento del costo della sequenza campionata rispetto alla v23. Non è una garanzia di FPS per ogni PC o situazione.

## Schiacciate forti

Solo la fascia oltre il 75% riceve un incremento graduale: al 100% il volo nominale passa da 0,480 a 0,456 s, con circa 5,24% di velocità orizzontale in più nella traiettoria misurata. Colpi medi, pallonetti, precisione, carica, sovraccarico e comportamento della difesa restano invariati. Nessun punto viene assegnato in base alla sola potenza.

In 144 confronti ripetibili con gli stessi difensori, traiettorie e seed, i punti diretti passano da 46 a 49; 95 nuovi attacchi vengono comunque difesi. Il vantaggio varia con posizione, mira e preparazione del muro. Dettagli in `STRONG_SPIKES_V24.md`.

## Verifica

Suite completa `tools/Test-Game.ps1`, inclusi i nuovi test RallyPins, ExpandedAnimations e StrongSpikes. Il controllo di ambito conserva comandi, camera TV, battuta, sistema di carica, punteggio, slot delle rotazioni, integratore della palla e codice del backend di animazione. Le fixture di contatto isolato scelgono ora la variante prima di posizionare l'atleta sotto la palla; le sequenze di partita continuano a richiedere avvicinamento e contatto reali.
