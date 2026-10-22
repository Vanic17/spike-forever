# Versione 0.23.0

## Secondo tocco dopo muro e ricezione ravvicinata

Il video di 68,78 secondi è stato esaminato nel finale, con campioni ravvicinati fra 60 e 65 secondi. La ricezione del libero porta il secondo tocco nella zona affollata davanti alla rete: il palleggiatore prepara il gesto senza completare correttamente l'arrivo.

La riproduzione con i veri personaggi ha isolato un blocco aggiuntivo: il vincolo di movimento del muro poteva restare attivo durante il seguito a terra dell'animazione. Il vincolo ora termina all'atterraggio estratto dal clip, mantenendo intatto il salto e il divieto di un secondo salto nello stesso attacco.

`setter_access.gd` pianifica prima del lancio della ricezione il tempo necessario per atterraggio, accelerazione e appoggio del palleggiatore. Se necessario aggiunge al massimo 0,30 s all'arco del passaggio; una traiettoria già partita non viene rallentata o fermata. Restano gli stessi limiti di velocità degli atleti e il normale secondo toccatore di emergenza per palle non raggiungibili.

Se il punto d'arrivo richiederebbe di stare dentro il corpo di un compagno a terra, il primo passaggio sceglie una piccola correzione verso una posizione libera, nella propria metà campo. Il compagno in recupero continua il proprio movimento originale. Le precedenti riserve del corridoio e gli aggiramenti del corpo restano attivi.

`Test-SetterCrowd.gd` verifica 18 secondi tocchi reali: palleggiatore di prima linea dopo muro, campo affollato, entrambe le squadre, 60/120 Hz e due bersagli occupati da un giocatore in recupero. La configurazione lunga prima della correzione produceva contatti mancati, con circa 0,86 m di errore finale.

## Muro

I laterali non richiamati con un grilletto aspettano ancora vicino alla rete durante l'attacco avversario: prima erano mandati automaticamente a 2,7 m di profondità. Un corridoio arretrato usato per ordinare una formazione incrociata viene abbandonato appena il percorso diretto verso il muro è libero e il laterale si trova sul lato giusto. La distanza dal centrale viene controllata prima del taglio della curva.

In R1 le corsie fisiche OPP/OH1 del primo attacco vengono conservate per il muro successivo, evitando di far scambiare entrambi i laterali mentre arriva l'alzata avversaria. La scelta viene fissata per la costruzione e non cambia di frame in frame. Centrale controllato, grilletti di richiamo e salto manuale restano gli stessi.

## Camera laterale TV

**C**, **Triangolo PlayStation** oppure **Y Xbox** alternano dietro, dietro distante e TV. La camera laterale conserva la sua posizione anche durante la battuta. Il cambio di vista non modifica palla, giocatori o azione in corso.

| Levetta nella camera TV | Alzata |
|---|---|
| Su | Banda in zona 4 |
| Destra | Centrale |
| Giù | Zona 2 |
| Sinistra | Pipe |

La stessa conversione vale per tutte le diagonali della schiacciata, la mira continua del servizio e il muro. In TV, su/giù spostano il muro fra le antenne; L2/LT richiama il laterale superiore e R2/RT quello inferiore. Le etichette si adattano. I pulsanti dei colpi restano invariati.

## Battuta

Incremento minore rispetto alla patch precedente: barra completa in 0,74 s anziché 0,78 s; tempo nominale al 100% del salto 0,79 s anziché 0,82 s e float 0,96 s anziché 1,00 s. Incremento della velocità circa 4%. Nessun limite al 100% per il sovraccarico e stessa proporzione del rischio. Calibrata la destinazione corta della mira per conservare il passaggio sopra la rete alla maggiore velocità.

## Verifica

Suite completa `tools/Test-Game.ps1`, più prove di camera con proiezione reale e direzioni, secondi tocchi affollati e permanenza dei laterali alla rete. Il confronto di ambito v23 conserva integratore della palla, punteggio, ciclo delle rotazioni, timing dell'attacco, animazioni e relativo backend. Sono modificati soltanto accesso al secondo tocco, percorsi del muro, camera e incremento del servizio richiesti.
