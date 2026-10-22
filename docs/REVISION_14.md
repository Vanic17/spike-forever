# Revisione 14 — rete, incroci, battuta potente e finta

## Muro vicino alla rete

La revisione 13 faceva arretrare il muratore per passare dietro ai compagni. Quel percorso poteva arrivare a oltre due metri dalla rete. Adesso i tre giocatori di prima linea conservano il proprio ordine laterale per la costruzione avversaria; le due posizioni attive appartengono a giocatori adiacenti e il terzo libera il lato esterno. Cambiare sinistra, centro o destra non richiede sorpassi.

I bersagli della coppia restano a profondità 0,68 m e separati da 0,90 m. Rimangono il comando sullo stick sinistro prima dell'alzata e il salto manuale con Croce / X, dalle posizioni effettive. Il controllo verifica che una coppia già sotto rete non superi 0,90 m di profondità durante gli spostamenti laterali. Le piccole correzioni verso la rete sono consentite; i corpi non vengono teletrasportati sulla riga.

## Incroci e preparazione dei ruoli

Il controllo di movimento usa una fotografia comune delle posizioni e delle velocità dei dodici giocatori. Prima di arrivare alla distanza di collisione, prevede il punto d'incontro nei successivi 0,55 secondi: riduce gradualmente il passo in avanti e sceglie un piccolo scarto laterale stabile. Restano le collisioni di sicurezza, gli ingombri dei bagher e del giocatore in tuffo. La formazione del muro usa le proprie corsie ordinate.

Corretto anche il percorso del palleggiatore che partiva da dietro il ricevitore: prima libera lateralmente il passatore, invece di tagliare diagonalmente contro la sua schiena. Il palleggiatore di seconda linea prepara un avanzamento contenuto durante la preparazione del servizio avversario, mantenendo il lato e il riferimento della propria prima linea; poi penetra con priorità durante la ricezione. Questo evita di destinare inutilmente al centrale un'alzata d'emergenza dopo un passaggio perfetto.

Il centrale prepara gli appoggi anche durante il volo del servizio. La sua corsia di primo tempo rimane separata da quella del palleggiatore: un aggiramento generico non lo manda più indietro nel momento in cui dovrebbe presentarsi per la veloce.

## Battuta potente: individuata la mano corretta

L'audit dei due polsi nell'animazione originale ha mostrato il difetto delle revisioni precedenti: `Serve_Action_SmashJumped_1` lancia con la **destra**. Tenere la palla sulla sinistra non poteva coincidere con quel gesto, anche correggendo il momento del rilascio.

La palla passa dalla tenuta iniziale al palmo destro con una breve transizione anatomica. Poi segue il vero movimento originale del polso destro e viene rilasciata a 1,03 s del filmato animato, durante la sua prima salita. Prosegue in una parabola a gravità costante, raggiunge l'apice durante la rincorsa e arriva alla mano che colpisce mentre sta scendendo. Eliminata la correzione artificiale del lancio sinistro. La float continua a usare la propria mano sinistra e il proprio evento di lancio.

Restano i tempi complessivi di preparazione, la rincorsa originale, il salto, l'atterraggio e la fisica della palla dopo il servizio. Camera, grafica, suoni, pulsanti e barre di carica rimangono quelli del gioco.

## Finta del centrale su ricezione buona

La minaccia di primo tempo si prepara automaticamente su passaggio almeno al 75%, anche se l'alzata normale deve essere eseguita da un compagno diverso dal palleggiatore. Il centrale deve essere di prima linea, disponibile e diverso da chi alza e da chi riceverà l'alzata. Se l'alzata è effettivamente destinata a lui, si esegue il vero attacco. Se il secondo tocco deve essere in bagher, si privilegia la ricostruzione dell'azione.

È stata aggiunta l'animazione originale `SPK_Line_FakeNoShoot_RunLRL.psa`, registrata come `attack_decoy`: **31 animazioni attive**. Il centrale raggiunge l'inizio della rincorsa; il corpo segue poi lo spostamento reale del filmato animato durante appoggi, salto e atterraggio. Non corre sul posto e non viene riportato di colpo al punto iniziale. I controlli delle collisioni rimangono attivi anche durante questa rincorsa.

Il gesto è sincronizzato al contatto dell'alzata, circa un decimo di secondo dopo per il punto alto della minaccia; non attende il salto della banda. Dopo l'atterraggio il centrale torna in copertura. La finta non registra alcun tocco, non cambia la traiettoria della palla e non seleziona un nuovo attaccante.

## Verifiche e registrazioni

- `Verifica.cmd`: partite con asset originali e con personaggi di ripiego, input, carica, contatti, ruoli, formazioni, muro e continuità dei movimenti. Esito completo in `revision14-verification.log`. Asset originali: 16 punti, 82 contatti e scarto massimo mani/palla 0,090 m; ripiego: 16 punti e 81 contatti. Nessun doppio salto dello stesso muratore sul medesimo attacco.
- Muro: 36 casi sulle sei rotazioni, tre direzioni, 60/120 Hz; chiusura effettiva vicino alla rete, cambi ripetuti, salto anticipato conservato e nessun salto automatico o ripetuto.
- Finta: 36 azioni buone, tutte le rotazioni ed entrambe le squadre; un solo salto reale a vuoto, spostamento effettivo del corpo di oltre mezzo metro nella rincorsa, salto vicino all'alzata, nessun tocco della palla e ritorno in copertura. Controllate anche ricezione scadente, vero primo tempo e alzatore di riserva.
- Incroci: due prove con traiettorie frontali e perpendicolari, correzione prima del contatto, nessun arresto brusco contro il compagno e destinazioni raggiunte. Distanze minime rispettivamente 1,015 m e 0,989 m. Report: `traffic-read-report.json`.
- Battuta: prove a 30/60/120 Hz sulla mano corretta per ogni servizio, tenuta, rilascio e contatto. La palla potente deve rimanere davanti al corpo durante la salita del polso e arrivare al colpo in discesa.
- Conservati 840 confronti delle coordinate tattiche, 432 casi di ruolo/fase, i controlli della continuità delle animazioni e i confronti della fisica della palla. I nuovi percorsi vengono applicati sopra le tabelle delle posizioni.

Le prove controllate sugli incroci non garantiscono l'assenza di ogni possibile contatto visivo in una partita. Le registrazioni permettono di esaminare anche l'effetto effettivo dei percorsi e dei gesti, oltre alle distanze numeriche.

Il filmato dello scambio usa la partita reale automatica, camera e metodo di movimento del gioco. La prova del muro isola i tre comandi ed esegue il vero salto animato; il pallone è nascosto soltanto in questa scena di ispezione. Il servizio potente ha una vista di controllo più larga per includere l'intera parabola del lancio. I video sono a 60 fps e vengono decodificati interamente per controllarne i file.

Backup precedente: `baseline-v13`. Riferimenti dell'animazione aggiunta: `assets/active/sources.json`. Traccia dello scambio: `revision14-demo-events.json`.

[Scambi e finta](Spike%20Forever%20-%20movimenti%20e%20finta%20v14.mp4) · [Servizio potente](Spike%20Forever%20-%20servizio%20potente%20v14.mp4) · [Muro vicino alla rete](Spike%20Forever%20-%20muro%20vicino%20rete%20v14.mp4).

[Dettaglio della finta al 50% della velocità](Spike%20Forever%20-%20finta%20rallentatore%2050%20v14.mp4): ritaglio ingrandito dello scambio reale, senza audio. Il centrale è il numero 2 della squadra blu. La partita completa dura 32 secondi; le due finte si vedono intorno a 16 e 22 secondi. Servizio potente: circa 7 secondi. Prova dei comandi del muro: 14,4 secondi.
