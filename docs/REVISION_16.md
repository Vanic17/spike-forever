# Revisione 16 — palleggiatore, posizioni e muro L2/R2

## Percorso del palleggiatore

La v15 separava le destinazioni dei compagni dal punto dell'alzata, ma non riservava l'intero segmento che il palleggiatore doveva percorrere. Un compagno già vicino alla propria destinazione poteva restare nel mezzo: la collisione arrestava il corpo, mentre l'animazione delle braccia continuava verso il contatto programmato.

`court_shape.gd` riserva ora il corridoio della penetrazione all'inizio della fase di alzata. I compagni che lo occupano ricevono una destinazione laterale stabile, anche quando prima non avevano motivo di spostarsi. La separazione dei bersagli e le collisioni restano attive. I giocatori che liberano il corridoio usano la risposta di movimento già prevista per il compito di lasciare spazio.

La riserva riguarda penetrazioni superiori a 65 cm. Le piccole correzioni della posa o dell'orientamento sul punto di alzata usano la separazione del punto finale: trattarle come nuove penetrazioni spostava inutilmente il centrale, ritardando la finta. Questa regressione è stata individuata e corretta durante la verifica.

Non sono stati allungati i voli della palla, aumentate le distanze consentite per il contatto o aggiunti tocchi automatici: il test richiede un'alzata effettivamente registrata.

## Corrispondenza fra le linee

La sequenza delle rotazioni, la rosa 5–1, i ruoli e le tabelle del riferimento erano già coerenti. Il difetto concreto era nell'avanzamento preparatorio del palleggiatore di seconda linea: il codice abbinava il posto arretrato al posto anteriore sottraendo 3 all'indice, nonostante l'ordine circolare degli indici.

L'abbinamento corretto è zona 1 dietro zona 2, zona 6 dietro zona 3, zona 5 dietro zona 4 (`front_slot = 5 - back_slot`). L'avanzamento prima del servizio è ora limitato dalla profondità del compagno effettivamente corrispondente, con il margine già esistente. Dopo il servizio avviene la normale penetrazione. Le formazioni di partenza del riferimento, l'ordine dei battitori, le rotazioni sul cambio palla e il libero sono conservati.

## Nuovo muro

Il nuovo componente `src/manual_wall.gd` gestisce il muro umano:

| Comando | Effetto |
|---|---|
| Stick sinistro | Sposta lateralmente il centrale e la formazione attiva in modo continuo e proporzionale |
| Nessun grilletto | Centrale effettivo di prima linea, sempre selezionato |
| Tieni L2 / LT | Unisce il muratore a sinistra del centrale |
| Tieni R2 / RT | Unisce il muratore a destra del centrale |
| Tieni entrambi | Muro a tre |
| Croce / A | Salto degli uomini selezionati dalle posizioni raggiunte |
| Tastiera | A/D o frecce per il movimento, Z sinistra, B destra, Spazio per saltare |

Il centrale è identificato dal ruolo e dalla prima linea della rotazione effettiva; non viene sostituito dal giocatore più vicino. I laterali sono identificati dalle rispettive corsie tattiche. La formazione conserva 90 cm tra i bersagli e profondità di 68 cm; il limite laterale considera tutta la formazione per evitare sovrapposizioni sulle antenne. Tornando con lo stick al centro, la destinazione si ferma: non c'è più la scelta discreta sinistra/centro/destra.

Quando una formazione di partenza impilata dispone i laterali sul lato opposto, questi stabiliscono prima l'ordine passando in due corridoi distinti, a profondità di 2,9 e 1,75 m, e poi chiudono a rete. Questi percorsi sono necessari soltanto per riorganizzare una disposizione incrociata. Il successivo scorrimento della formazione ordinata resta vicino alla rete.

Il rilascio di un grilletto a terra rimuove il relativo compagno. Alla pressione di Croce viene memorizzato il gruppo che esegue quel salto; il rilascio successivo non cancella le sue mani. Il gruppo viene conservato anche quando il colpo avversario fa passare il gioco alla ricezione della propria squadra, affinché la collisione con il muro usi gli stessi giocatori effettivamente saltati. Restano il salto manuale e un solo salto per giocatore per attacco. Non sono stati introdotti salti automatici o attraversamenti dei corpi.

L2/R2 sono associati agli assi dei grilletti, per tutti gli identificativi dei controller; Xbox usa LT/RT. Gli altri pulsanti, le barre di carica e le finestre dei colpi sono conservati. L'interfaccia e il README indicano i nuovi comandi.

## Verifiche

Suite completa: `revision16-final-verification.log`, con esito positivo.

- Asset originali: 16 punti, 122 contatti, scarto massimo mano/palla 0,1065 m, distanza minima tra giocatori e nel muro circa 0,805 m; nessun salto duplicato.
- Ripiego: 16 punti, 59 contatti, scarto massimo 0,1451 m, distanza minima circa 0,796 m.
- Muro: 48 combinazioni di rotazione, partecipanti e frequenza a 60/120 Hz; centrale sempre selezionato, spostamento continuo dello stick parziale, chiusura reale della formazione, salto comandato, salto anticipato conservato dopo l'alzata e gruppo conservato nel passaggio alla ricezione. Inoltre, chiusura del muro a tre dalle sei formazioni reali iniziali, rilascio dei grilletti a terra ed eventi degli assi L2/R2 da un controller con identificativo 9.
- Palleggiatore e rotazione: 12 formazioni di ricezione controllate durante tre secondi di preparazione; corrispondenza effettiva fra prima e seconda linea. Quattro penetrazioni deliberatamente ostacolate, entrambe le squadre a 60/120 Hz: contatto di alzata registrato, distanza minima dal compagno circa 0,991 m.
- Conservati i controlli su 840 posizioni del riferimento, 432 casi tattici, continuità della palla e delle animazioni, servizi, incroci, input degli altri colpi e 36 finte del centrale.
- `Check-Revision16Scope.ps1`: 77 confronti con la v15, oltre ai controlli del riferimento. Fisica, timing dei colpi, PlayStyle, sequenza di rotazione, pulsanti esistenti, camera, audio e asset animati conservati. Le modifiche ai comandi del muro sono quelle richieste in questa revisione.

La prova video [Nuovo muro v16](Spike%20Forever%20-%20muro%20centrale%20L2%20R2%20v16.mp4) dura 18 secondi, 1280×720 a 60 fps. Mostra il movimento e i salti reali in quattro configurazioni; la palla è nascosta in questa scena di controllo. Verificati otto salti complessivi, nell'ordine 1/2/2/3. Il file è stato decodificato interamente senza errori. Riepilogo visivo: `revision16-wall-sheet.jpg`.

Le prove coprono scenari riproducibili e una partita simulata; non implicano che ogni palla difficile debba diventare raggiungibile. Il backup precedente è `docs/baseline-v15`. Chiudere e riaprire il gioco per caricare i nuovi sorgenti.
