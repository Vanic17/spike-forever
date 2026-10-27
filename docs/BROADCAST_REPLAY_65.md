# Broadcast, replay e conclusioni dei recuperi — 0.65.0

## Fonti e risorse

I loghi provengono dai pacchetti del [portale ufficiale Loghi Lega e Club](https://www.legavolley.it/documenti/loghi-lega-e-club), raggiungibile dalla [sezione SuperLega](https://www.legavolley.it/category/superlega/). Nessun logo è stato ridisegnato. I PDF vettoriali vengono renderizzati ad alta risoluzione; dove contengono tavole di presentazione si usa il PNG trasparente originale, senza ingrandimenti artificiali. Le due versioni Verona vengono dal PNG ufficiale, evitando il PDF con due marchi affiancati. Il badge SuperLega deriva dal PDF ufficiale, 1323×2195 pixel.

[Elenco delle fonti, membri ZIP e hash](branding65-sources.json) · [Anteprima dei marchi](branding65-preview.png). Le versioni bianche sono quelle del kit media ufficiale. I file rimangono locali nel gioco e non richiedono collegamento durante la partita. Barlow Condensed è distribuito con la sua licenza OFL nella cartella licenses.

Per ricostruire gli asset: Python con Pillow e PyMuPDF, `tools/Fetch-Branding65.py --download`, poi `tools/Build-Branding65.py`. Per i fischi: `tools/Build-Whistles65.py` con FFmpeg nel percorso tools già usato dal progetto. Queste dipendenze servono agli strumenti di preparazione, non al giocatore.

La transizione è stata osservata nel [riferimento corretto, a 1:36](https://www.youtube.com/watch?v=mhLv0o1MYxU&t=96s): stemma che sale dal basso, ruota verso lo spettatore e si ingrandisce fino a coprire il cambio camera. È ricostruita in Godot con il badge ufficiale. Il filmato YouTube non è incluso nel gioco né nel repository.

## HUD e replay

`league_branding.gd` carica le immagini una sola volta e genera mipmap. `broadcast_scoreboard.gd` disegna forme e testi alla risoluzione corrente, leggendo squadra e colore dalla divisa realmente selezionata. Il segnapunti è a sinistra; il badge d'angolo è a destra. Il feedback del timing usa due componenti tradotte separatamente e un fondo opaco. Le istruzioni del tutorial restano indipendenti.

`match_replay.gd` registra a 30 Hz le pose già corrette di dodici giocatori, i loro trasformati, palla e rete. Nessun avatar aggiuntivo e nessuna seconda valutazione di PSA, AnimationTree o IK. Buffer limitato a 540 campioni; il clip mostrato parte dal rilascio dell'alzata (con 0,22 s di preparazione), dal lancio della battuta o dal contatto di un attacco di prima. Non contiene l'intero scambio: massimo 5,5 s registrati, riprodotti a 0,8×. Le battute reali del test producono clip di circa 2–3 s.

I candidati sono creati da contatti reali: servizio valido, attacco nella fascia perfetta, muro con risposta `stuff_block`. Vengono confermati soltanto se quel colpo produce il punto della squadra corretta. Un secondo tocco avversario annulla il candidato; una schiacciata perfetta deviata fuori conserva la propria classificazione. I servizi sbagliati non producono replay ace.

Durante il playback la simulazione resta ferma: nessun nuovo punto, contatto o numero casuale. Il replay interpola pose locali ottenute dalle pose globali registrate, evitando di accorciare arti interpolando gerarchie globali. All'uscita ripristina pose, radici, palla, camera, rete e aggiornamenti visivi sospesi. Croce/A e Cerchio/B richiedono l'uscita con transizione. Start resta disponibile per la pausa; L3/M continua a essere gestito esclusivamente da GlobalAudio.

Online l'host invia la classificazione e l'inizio del segmento con RPC affidabile. Entrambi riproducono le proprie pose già ricevute con camera laterale; i comandi di gioco e gli snapshot della scena temporaneamente alterata vengono sospesi. L'ospite non va in timeout durante il replay e attende il messaggio affidabile di conclusione dell'host. Il salto richiesto da uno dei due è condiviso. Protocollo SF065.

## Cause concrete e modifiche gameplay

1. `Timing.blockers` restituiva tre per qualsiasi alzata lenta con qualità sotto 0,94. Ora la scelta normale rimane uno/due; `recovery_delivery.cpu_blockers` consente tre solo fuori sistema, con almeno 1,65 s di volo, apice stimato sopra 4,7 m e percorso raggiungibile da tutti i tre giocatori di prima linea. Le scelte manuali non cambiano.
2. `RallyAI.attack_choice` poteva convertire una schiacciata in colpo morbido al contatto. Ora il pallonetto CPU viene scelto al rilascio dell'alzata, preparando il clip corretto e la sua altezza di contatto. Il centrale non cambia gesto mentre è già impegnato nel primo tempo.
3. La durata minima necessaria per superare la rete veniva moltiplicata nuovamente per il rapporto di potenza, alzando molto l'arco dei colpi arretrati. Ora si applica la durata minima dopo la richiesta di velocità, con clearance 2,565 m e bersaglio più profondo quando serve. Restano integratore, gravità, spin e collisioni. Tolta anche la doppia penalità di forza della CPU fuori sistema; resta la sua potenza ridotta di recupero.
4. Il bagher di terzo tocco usava profondità 5 m e tempi costanti di 1,4/1,65 s. Il nuovo selettore varia spazi liberi, lunghezza, lato e altezza del rinvio. I set d'emergenza profondi possono servire un attaccante vicino alla sua zona attuale, con rincorsa reale e forza ridotta. Non trasforma in schiacciata un pallone ingestibile, un recupero tardivo del centrale o un'azione del libero. Con statistiche attive controlla anche la capacità offensiva.
5. Il fischio era un singolo file a volume e durata fissi. `Build-Whistles65.py` deriva otto respiri dal file dell'utente, conservato come fallback. Code separate, niente ripetizione immediata, piccola variazione d'intonazione e coda sfumata. Il generatore casuale audio resta separato da quello della partita.

## Verifiche

- [Replay: stato, RNG, pose e limite del buffer](replay65-tests.json). Il costo medio misurato del solo campionamento è circa 10 microsecondi; non è una misura degli FPS complessivi né del costo grafico del playback.
- [Ace salto/float e schiacciata perfetta realmente simulati](replay65-events.json).
- [Host](online-replay65-host.json) / [ospite](online-replay65-guest.json): tre replay, skip dell'ospite, camera laterale, pausa della simulazione e ritorno al menu.
- [Contatti online host](online-contacts65-host.json) / [ospite](online-contacts65-guest.json): partita umana con statistiche attive, ricezioni, alzate, attacchi, pause e fine partita. Test separato dai replay, disattivati solo nella fixture.
- [96 costruzioni complete, sei rotazioni, due lati](gameplay65-transitions-libero.json).
- [16 recuperi d'emergenza con backend nativo e PSA](gameplay65-emergency.json) e [8 alzate profonde concluse con schiacciata](gameplay65-high-recovery.json).
- [16 traiettorie con crossing della rete, 80 rinvii variabili e fischi](gameplay65-tests.json).
- [Rilascio dei colpi con statistiche ON/OFF](gameplay65-stats-release.json).
- Menu Gioca: quattro risoluzioni, navigazione controller, impostazioni e fine partita. Online: tre risoluzioni e navigazione D-pad/A/B. Tutorial: 40 layout italiano/inglese e ritorno ai menu.

Anteprime native: [scoreboard laterale](broadcast65-hud-tv.png), [frontale](broadcast65-hud-front.png), [transizione](broadcast65-transition.png), [replay](broadcast65-replay.png), [scelta squadre](broadcast65-setup.png), [editor](broadcast65-editor.png), [online](broadcast65-online.png).
