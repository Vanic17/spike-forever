# Revisione 15 — continuità del movimento

## Cause riscontrate nella v14

L'analisi riguarda `main.gd`, `avatar.gd`, `movement_intent.gd`, `court_shape.gd`, `rally_ai.gd` e i metadati dei filmati PSA originali. La v14 disponeva già di reazioni individuali, blending delle articolazioni locali, piedi ancorati gradualmente, IK limitata, destinazioni tattiche e previsione delle collisioni: non mancavano completamente questi sistemi.

1. **Preparazione della schiacciata in anticipo sul filmato.** `move_players` cominciava circa 0,71 s prima del contatto, ma il filmato disponibile richiede circa 0,515 s alla velocità già utilizzata. `prepare_contact` limitava il tempo a zero: circa **0,19 s di fotogramma iniziale fermo**, mentre il corpo si spostava. Audit riproducibile: `tools/Audit-Fluidity.gd`, risultati in `fluidity-v14-audit.json`.
2. **Frenata istantanea quando cambiava l'incarico.** La velocità effettiva veniva limitata immediatamente al massimo del nuovo incarico. Passare da rincorsa urgente a copertura poteva eliminare oltre 1 m/s in un solo aggiornamento, aggirando il calcolo progressivo dell'accelerazione.
3. **Rallentamento uniforme dopo ogni tocco.** Durante `motion_lock`, il movimento richiesto veniva moltiplicato per 0,35, anche per un bagher a terra; allo scadere risaliva immediatamente a 1. Il movimento delle gambe veniva inoltre sovrapposto soltanto prima del contatto.
4. **Orientamento a soglia.** Oltre 2,6 m/s e 0,9 m dalla destinazione, il riferimento del busto passava dalla palla alla corsa in modo binario. Le due direzioni potevano essere molto diverse.
5. **Passi incrociati disponibili ma inutilizzati.** Le chiusure laterali veloci usavano gli stessi passi laterali corti degli aggiustamenti.
6. **Percorsi intermedi trattati come arrivi.** Gli aggiramenti del compagno richiedevano di avvicinarsi entro 32 cm dal vertice prima di cambiare direzione, favorendo frenata e ripartenza.
7. **Preparazione comune e copertura basata soprattutto sul tempo di fase.** Il primo arretramento degli attaccanti usava una curva uguale per tutti. Sulle alzate brevi la palla poteva arrivare prima che la transizione in copertura fosse completa.

## Interventi progressivi

- La preparazione visiva comincia quando il filmato può avanzare verso il contatto, usando il metadato della variante effettivamente scelta. Scadenza del contatto, velocità del filmato al colpo e finestra di input restano identici.
- Il limite di velocità agisce sulla richiesta di movimento; l'eventuale velocità già superiore viene smaltita dall'accelerazione e dalla frenata esistenti. Il limite impedisce comunque di accelerare ulteriormente oltre quella velocità. **Nessuna velocità massima di riferimento o di ruolo aumentata.**
- Il bagher a terra non impone più il rallentamento universale. Gli appoggi riprendono gradualmente durante il seguito del gesto; il contatto esatto resta campionato senza questa sovrapposizione. Per gli altri gesti il breve rallentamento sfuma, anziché finire a gradino. Salti, atterraggi, tuffi e rincorse guidate dal filmato conservano i propri vincoli.
- L'orientamento combina gradualmente palla e direzione di corsa in funzione di velocità e distanza. Le chiusure a muro conservano l'orientamento verso rete.
- Aggiunti due filmati originali `STD_Move_Crossing_LOOP_90L_D0` e `90R_D0`, come `cross_left` e `cross_right`. L'analisi del loro movimento verifica il verso, non si affida soltanto al nome. Scelta con isteresi: passi incrociati nelle chiusure laterali veloci, passi accostati per gli aggiustamenti corti, corsa per gli spostamenti orientati in avanti. Le transizioni conservano la posa visibile e cercano un appoggio compatibile. Totale 33 filmati; i 31 precedenti sono conservati.
- I percorsi arrotondano il vertice soltanto dopo aver liberato il corridoio del giocatore al contatto. La destinazione finale e il controllo fisico delle distanze restano attivi.
- Preparazione degli attaccanti con piccoli scarti temporali individuali; il palleggiatore continua a penetrare durante la ricezione, contemporaneamente alla preparazione degli altri.
- Su difesa di un attacco, i compagni di seconda linea compiono aggiustamenti verso il punto di arrivo già previsto, entro 28 cm lateralmente e 20 cm in profondità, senza inseguire tutti la palla. Le ricezioni del servizio mantengono le loro formazioni. Sull'alzata breve viene anticipata la chiusura delle corsie di copertura già assegnate. Separazione delle destinazioni applicata dopo questi aggiustamenti.

## AnimationTree: compatibilità effettiva

Questo progetto campiona direttamente PSA in `normalized_pose`, ricostruisce le trasformazioni locali, miscela le pose e le applica a `Skeleton3D`. Non contiene `AnimationPlayer` o librerie Godot di tracce ossee utilizzabili direttamente da `AnimationTree`. Il sistema di contatto usa gli stessi campioni PSA, insieme alle varianti scelte durante lo scambio.

In questa revisione **non è stato aggiunto AnimationTree**: affiancarlo alla scrittura diretta delle ossa creerebbe due sistemi che controllano lo stesso scheletro. Una migrazione richiederebbe conversione delle tracce, gestione unificata del tempo dei contatti e confronti delle pose. Sono state invece corrette le transizioni del sistema attuale, mantenendo il blending gerarchico locale e la continuità delle gambe. Questo limite appartiene alla struttura del progetto, non all'impossibilità di realizzare questi movimenti in Godot.

## Verifica

- Suite completa: `revision15-stage2-verification.log`. Asset originali: **16 punti, 129 contatti**, massimo scarto mano/palla **0,1532 m**, distanza minima tra giocatori **0,798 m**. Ripiego: **16 punti, 81 contatti**, scarto massimo **0,1343 m**, distanza minima **0,806 m**. Nessun salto duplicato sul medesimo attacco. Le diverse posizioni possono cambiare l'evoluzione di uno scambio anche con lo stesso seme casuale; non è stata modificata la scelta dei colpi.
- Nuova prova `Test-Fluidity.gd`: movimento del gioco effettivo, **215 fotogrammi di preparazione, zero fermi sul fotogramma iniziale**; passaggio dalla rincorsa alla copertura a 30/60/120 Hz, verso dei passi incrociati e ritorno agli aggiustamenti laterali. Report `fluidity-report.json`. Nel caso a 120 Hz, la variazione di velocità nel primo aggiornamento è circa 0,0057 m/s anziché il taglio immediato al limite di copertura.
- Continuità scheletrica estesa ai due nuovi filmati: `revision15-AvatarMotion.log` e `revision15-MotionContinuity.log`. 48 cambi di direzione preparati, controlli a 30/60/120 Hz, conservazione delle lunghezze degli arti, continuità delle giunzioni dei cicli, contatto originale preservato.
- Restano superati: 840 confronti di posizionamento, 432 casi tattici, reazioni individuali, collisioni negli incroci, muro manuale su tutte le rotazioni, finta del centrale, battute e continuità della palla.
- `Check-FluidityScope.ps1`: **90 confronti** con il backup v14. Invariati regole, rotazioni, controlli, timing, PlayStyle/riferimenti di gioco, fisica della palla e funzioni decisionali. La suite `Test-Game.ps1` include ora anche il nuovo test e questa verifica di ambito.

Il filmato [Partita v15](Spike%20Forever%20-%20fluidita%20v15.mp4) mostra 24 secondi della partita automatica con la camera del gioco, a 1280×720 e 60 fps, con audio. File interamente decodificato senza errori (`revision15-decode.log`); esaminate anche la panoramica e la sequenza ravvicinata della preparazione a circa 21–22 s (`revision15-overview.jpg`, `revision15-attack-sequence.jpg`). Le prove numeriche non certificano da sole una naturalezza perfetta o l'assenza di ogni possibile contatto visivo; restano strumenti per controllare gli interventi progressivi.

Backup della base precedente: `docs/baseline-v14`. Il launcher carica direttamente i sorgenti aggiornati; chiudere e riaprire il gioco.
