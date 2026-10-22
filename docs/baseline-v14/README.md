# Spike Forever

Gioco Windows 3D di pallavolo indoor 6 contro 6, contro la CPU, con controller PlayStation, Xbox o tastiera. Squadre e giocatori senza personalizzazione.

**Avvio:** apri `Spike Forever.exe`, poi Options / Start / Invio. Il launcher carica i sorgenti aggiornati: non occorre installare o ricompilare Godot. Lascia l'eseguibile nella cartella del progetto.

**Revisione 14 — muro vicino alla rete, servizio potente e finta del centrale:** il muro scorre sotto rete mantenendo l'ordine dei giocatori; gli incroci vengono anticipati con piccoli aggiustamenti e frenate. La battuta potente segue ora il lancio della mano destra dell'animazione originale. Su ricezione buona il centrale disponibile prepara sempre il primo tempo e finge se la palla va a un altro attaccante, con una nuova animazione originale completa di rincorsa e atterraggio. Migliorata la preparazione del palleggiatore. [Modifiche e verifiche](docs/REVISION_14.md).

**Grafica, telecamera, suoni e pulsanti conservati.** Restano le barre di carica della revisione 08. Il timer oscillante è eliminato da tutte le azioni.

[Scambi e finta del centrale](docs/Spike%20Forever%20-%20movimenti%20e%20finta%20v14.mp4) · [Servizio potente aggiornato](docs/Spike%20Forever%20-%20servizio%20potente%20v14.mp4) · [Muro vicino alla rete](docs/Spike%20Forever%20-%20muro%20vicino%20rete%20v14.mp4).

[Partita della revisione 12](docs/Spike%20Forever%20-%20rigioco%20e%20spazi%20v12.mp4).

## Comandi attuali

| Azione | PlayStation | Xbox | Tastiera |
|---|---|---|---|
| Battuta al salto potente | Tieni e rilascia Croce / X | Tieni e rilascia A | Tieni e rilascia Spazio |
| Battuta jump float | Tieni e rilascia Quadrato | Tieni e rilascia X | Tieni e rilascia Q |
| Ricezione | Croce / X vicino all'arrivo | A vicino all'arrivo | Spazio vicino all'arrivo |
| Alzata normale | Croce / X | A | Spazio |
| Alzata veloce | Quadrato | X | Q |
| Colpo di seconda | Cerchio | B | E |
| Schiacciata | Tieni e rilascia Croce / X | Tieni e rilascia A | Tieni e rilascia Spazio |
| Mira battuta / attacco, 8 direzioni | Stick sinistro | Stick sinistro | WASD / Frecce |
| Direzione alzata, 4 direzioni | Stick sinistro | Stick sinistro | WASD / Frecce |
| Zona del muro a due, anche prima dell'alzata avversaria | Stick sinistro: sinistra / avanti / destra | Stick sinistro: sinistra / avanti / destra | A / W / D oppure Frecce |
| Salto a muro | Croce / X | A | Spazio |
| Inizio / pausa | Options | Start | Invio / Esc |

Croce PlayStation corrisponde ad **A Xbox**. Quadrato PlayStation corrisponde a **X Xbox**. Le assegnazioni dei pulsanti sono modificabili in `controls.cfg`. Lo stick sinistro controlla le scelte di gioco; posizionamento e spostamenti dei dodici atleti sono automatici. L'interfaccia adatta i nomi al controller riconosciuto; F1 apre l'aiuto.

## Battuta e schiacciata

La barra verde cresce soltanto tenendo premuto. Il rilascio memorizza la potenza e il contatto resta sincronizzato all'animazione e alla palla; non c'è un secondo comando di timing.

- Servizio: Croce sceglie il salto potente, Quadrato il jump float. Durante la carica il battitore aspetta con la palla; al rilascio esegue rincorsa, lancio, salto e atterraggio. La partenza arretrata viene calcolata automaticamente per staccare dietro la linea di fondo. La mira si sceglie con lo stick sinistro.
- Servizio al 100%: massima potenza valida. Oltre il 100% aumenta il rischio di rete o fuori: 110% carica = 25% rischio, 120% = 50%, da 140% = 100%. Anche l'errore viene simulato fisicamente; il punto arriva quando la palla cade.
- Attacco: un tocco rapido dà poca potenza e la mira più precisa. Le otto direzioni individuano punti del campo, comprese le diagonali verso gli angoli.
- Fino al 70% di potenza la precisione nominale resta 100%; poi scende: 90% potenza = 80% precisione, 100% = 70%. La dispersione effettiva varia da colpo a colpo.
- Attacco oltre il 100%: traiettoria lunga fuori. Se stai ancora tenendo premuto quando arriva la palla, viene utilizzata la carica raggiunta al contatto.

## Ricezione e alzata

La ricezione valuta la distanza effettiva della palla dalle mani usando una curva ricavata dal riferimento. Anticipa l'arrivo del pallone: sui colpi rapidi devi preparare prima il gesto; la zona migliore continua fino al contatto. Premere troppo presto peggiora gradualmente la qualità percentuale; non esistono finestre perfette che si ripetono. Senza pressione la palla non viene salvata automaticamente.

È disponibile un margine tardivo di **100 millisecondi**, con qualità inferiore e un'animazione originale di recupero basso. Il recupero deve comunque essere raggiungibile: non teletrasporta il giocatore o la palla.

La ricezione ordinaria mira automaticamente al centro della zona 3, a circa 1,5 m dalla rete. Il tempismo, la difficoltà della palla e il recupero determinano la qualità effettiva del passaggio. Una palla difficile può spostare il palleggiatore, richiedere un secondo tocco in bagher, produrre un overpass oppure costringere a regalare il terzo tocco. La difesa può preparare un tuffo se la palla è raggiungibile con quel gesto.

L'alzata si sceglie direttamente: Croce normale, Quadrato veloce, Cerchio colpo di seconda con animazione originale. Stick sinistra = zona 4, alto = centro, destra = zona 2, basso = pipe. La palla difficile può richiedere un'alzata di sicurezza. Il colpo di seconda conserva le normali limitazioni degli attacchi dalla seconda linea.

## Muro, ruoli e movimento

Durante la costruzione avversaria i giocatori di prima linea si preparano sotto rete. Lo stick sinistro sceglie dove chiudere il muro a due: sinistra, avanti per il centro, oppure destra. La scelta resta memorizzata tornando con lo stick al centro e può essere cambiata fino al salto. Croce fa saltare i due uomini nel momento della pressione, anche prima dell'alzata, dalle posizioni raggiunte: non è necessario centrare una coordinata nascosta. Chi è ancora lontano o salta troppo presto può mancare il pallone. Rimane un solo salto per giocatore per attacco; non c'è un salto automatico successivo alla pressione. Il contatto dipende dalle mani animate e dalla traiettoria, senza barra di timing.

I tre giocatori di prima linea conservano l'ordine laterale durante la costruzione avversaria: la coppia scelta scorre a circa 68 cm dalla rete e il terzo libera il relativo lato, evitando sorpassi e giri all'indietro. Su ricezione almeno al 75%, se il centrale di prima linea è disponibile e non è il destinatario dell'alzata, prepara la rincorsa e salta a vuoto come minaccia di primo tempo. Il salto non tocca la palla. Se l'alzata è al centrale, viene eseguito il vero attacco. Con una palla che richiede il secondo tocco in bagher la finta viene annullata.

Il sistema 5–1 usa le dodici formazioni della demo di riferimento. I ruoli restano fissi mentre cambiano le zone: le ali si aprono per la rincorsa, il centrale legge il palleggiatore, il libero copre i corridoi scoperti e chi non attacca copre lo schiacciatore. Le distanze fra corpi e il salto unico restano controllati. La palla usa nuovamente la gravità costante e i tempi di servizio, ricezione, alzata e attacco della revisione 08, conservando spin, deviazioni, collisioni e rimbalzi dopo il punto.

Le coperture passano gradualmente dall'apertura per l'attacco alle posizioni del riferimento, con tempi diversi per ciascun giocatore. Il centrale prepara un primo tempo vicino al palleggiatore; l'opposto in seconda linea usa la propria corsia D e lo schiacciatore la pipe. Il palleggiatore in prima linea occupa la corretta base difensiva, anziché mantenere quella della seconda linea. Il tuffo usa un'animazione originale completa e resta impegnato fino alla rialzata. Chi recupera oltre le linee rientra correndo, senza essere riportato di colpo nel campo.

Nel rigioco le bande cominciano ad aprirsi prima dell'alzata. I percorsi di uscita dal corridoio del palleggiatore rimangono assegnati durante il volo della palla, evitando correzioni avanti e indietro. I bersagli dei compagni sono separati da quello del contatto; durante il movimento viene considerato anche l'ingombro di un giocatore in tuffo. Le varianti di bagher seguono il lato della palla; le alzate dietro e le schiacciate usano gesti originali diversi, con transizioni dalla posa effettivamente visibile.

## Verifiche e documentazione

- `Verifica.cmd`: controlli automatici con asset originali e fallback, input dei controller, carica e sovraccarico, contatti, tattiche, rotazioni, salto unico e qualità del movimento.
- F2: partita dimostrativa; F3: galleria delle 31 animazioni attive; F5: difficoltà; C: distanza della telecamera; R: nuova partita.
- [Revisione attuale](docs/REVISION_14.md), con muro vicino alla rete, incroci anticipati, lancio destro e finta del centrale.
- [Revisione 13](docs/REVISION_13.md), con muro manuale.
- [Revisione 12](docs/REVISION_12.md), con correzioni del rigioco e varianti originali.
- [Revisione 11](docs/REVISION_11.md), con confronto del posizionamento e verifica della modalità maschile.
- [Revisione 10](docs/REVISION_10.md), con ripristino della fisica e comandi aggiornati.
- [Analisi del riferimento nella revisione 09](docs/REVISION_09.md), con confronto delle 144 posizioni specchiate. I suoi tempi e archi della palla sono stati sostituiti nella revisione 10.
- [Dettagli della revisione 08](docs/REVISION_08.md).
- [Anteprima della revisione 08](docs/Spike%20Forever%20-%20nuovi%20comandi%20e%20carica.mp4).
- [Revisione precedente del movimento](docs/REVISION_07.md).
- Le versioni precedenti dei sorgenti sono in `docs/baseline-v01` … `docs/baseline-v13`. Le vecchie specifiche descrivono comandi storici; per i comandi attuali fa fede questa pagina.
- I riferimenti delle animazioni originali attive sono in `assets/active/sources.json`; l'inventario completo è in `docs/animation-inventory.csv`.

I test automatici inviano gli stessi eventi gestiti dai controller. La verifica fisica dei singoli modelli di controller rimane una prova manuale.
