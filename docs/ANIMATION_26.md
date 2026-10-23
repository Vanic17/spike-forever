# Animazioni revision 26: catalogo contestuale e compatibile

L'archivio locale contiene 2.696 file PSA, non 2.696 azioni intercambiabili. Include 1.345 segmenti di locomozione, 310 sequenze cinematografiche, 210 NPC, 168 attese, 291 passaggi/ricezioni, 134 alzate/transizioni del palleggiatore, 64 muri, 68 azioni di servizio/preparazione, 37 attacchi e altri 69 clip di creazione personaggio, volto, scale, emote e postura. Molti sono segmenti di ingresso/uscita, coppie di supporto, clip con root/posa parziale o contatti incompatibili con il gioco attuale. Non sono stati attivati alla cieca.

Sono state aggiunte **79 prestazioni sorgenti distinte**, portando da **48 a 127** le animazioni attive e preconvertite. Sono ulteriori animazioni reali nell'archivio autorizzato dall'utente; non sono alias rinominati, variazioni di sola velocità o motion capture creato da zero.

| Famiglia | Prestazioni aggiunte |
|---|---:|
| Bagher, appoggi e aggiustamenti laterali | 20 |
| Alzate normali | 6 |
| Alzate veloci, abbinate alla corrispondente normale | 11 |
| Schiacciate con direzione e torsione del busto | 3 |
| Muri statici e dopo passo | 6 |
| Tuffi frontali e laterali | 6 |
| Attesa in ricezione, postura rilassata e attesa a muro | 14 |
| Corsa, cammino, arretramento, passi laterali e incrociati; passi a muro con braccia alte | 13 |
| Totale aggiunto | 79 |

I file e SHA256 esatti sono in `assets/active/new_animations_26.json`; le famiglie e i selettori sono in `src/animation_expansion.gd`. La selezione dipende dal movimento relativo della palla, dalla direzione dell'attacco già scelta, dal tipo di contatto, dalla qualità del primo tocco e dalla postura di muro. Le attese e i cicli di locomozione sono assegnati stabilmente ai diversi atleti: non vengono cambiati casualmente ogni fotogramma. Le mani e il movimento a terra rimangono sincronizzati dai proprietari esistenti dell'azione.

## Abbinamento alzata normale e veloce

Una stessa preparazione conserva la propria identità visiva anche quando si conferma normale o veloce. La veloce usa la prestazione corrispondente della stessa famiglia sorgente, con lo stesso supporto dei piedi e una posizione delle mani molto vicina. Questo evita che un comando tardivo chieda al palleggiatore di riposizionarsi improvvisamente per un'animazione diversa. Con ricezioni difficili, la normale conserva i palleggi corti già calibrati per evitare il corpo del ricevitore a terra.

Al reset dello scambio, il personaggio entra prima in attesa e successivamente ripristina i clip base. La protezione che impedisce di cambiare una prestazione durante il recupero di un colpo rimane attiva durante il gioco; non impedisce più il ripristino fra due scambi.

## Backend e validazione

La libreria condivisa `assets/active/native_all.res` comprende tutti i 127 clip. I PSA originali e il parser restano disponibili, insieme a F6 e `--psa-original`. L'inferenza del contatto riceve soltanto il nome della famiglia per i nuovi alias. Campionamento, trasformazioni di normalizzazione, IK, testa, appoggi e proprietà della root reale rimangono invariati. I rig privati dell'AnimationTree vengono validati contro il clip sorgente, indipendentemente dagli alias scelti per il singolo atleta, così la commutazione del backend non dipende dalla sua postura corrente.

`tools/Test-AnimationCatalog26.gd` verifica tutte le 79 prestazioni e tutti i percorsi dei selettori effettivamente usati nel gioco. Esegue **322.316 controlli** e **624 contatti schedulati** su entrambi i lati, tre posizioni e i due backend, senza ampliare la tolleranza di contatto. Risultati:

- scarto massimo mani-palla: **0,173467 m**, entro il limite esistente di 0,18 m;
- scarto massimo nel campionamento PSA/native: **0,00000152 m**;
- variazione massima delle lunghezze degli arti: **0,000032 m**;
- discontinuità massima all'ingresso dalla corsa: **0,00000265 m**;
- root del personaggio invariata dalla sola riproduzione visiva;
- nessun duplicato negli SHA256 o nei dati dei keyframe rispetto ai 48 clip precedenti e fra i nuovi.

Una fonte di muro con braccia già alte (`BLK_Static_45L_upArms_HS.psa`) è stata esclusa dopo la verifica completa del contatto perché l'IK non raggiungeva in modo affidabile l'altezza di gioco. Restano fuori anche le fonti cinematografiche/facciali, i segmenti che richiedono un proprio sistema di concatenazione e le altre battute con lanci non ancora calibrati; aggiungerli senza sincronizzazione reintrodurrebbe i difetti del lancio già corretti. I risultati non dichiarano eliminato lo scivolamento dei piedi in ogni possibile scambio: i test della continuità e degli appoggi preesistenti restano parte della suite.

`tools/Capture-AnimationCatalog26.gd` genera quattro provini PNG delle pose di contatto e di locomozione. Sono una verifica visiva dello scheletro e dell'orientamento, integrata dai test di continuità e contatto, non la misura del ritmo di una partita completa.

## Dimensioni e prestazioni

La libreria binaria è salvata con la [compressione senza perdita di ResourceSaver in Godot 4.5](https://docs.godotengine.org/en/4.5/classes/class_resourcesaver.html): 44.925.528 byte su disco invece di 110.678.212, con identici eventi di contatto e dati caricati. La verifica native/PSA su tutti i 127 clip passa anche leggendo la risorsa compressa. Gli strumenti di conversione e di verifica mantengono lo stesso formato compresso.

Benchmark headless consecutivi, stessa macchina, 12 atleti, 359 campioni dopo riscaldamento; due passi di simulazione a 120 Hz e una posa visuale per campione:

| Versione/backend | CPU media | CPU p95 |
|---|---:|---:|
| 0.25, 48 clip native | 10,395 ms | 13,294 ms |
| 0.26, 127 clip native | 9,764 ms | 12,475 ms |
| 0.25, PSA | 9,809 ms | 13,015 ms |
| 0.26, PSA | 9,626 ms | 12,690 ms |

Nella sequenza misurata non emerge un incremento del costo per fotogramma. Il catalogo non aggiunge atleti o scheletri valutati simultaneamente; le misure locali non sono una garanzia del frame rate GPU o di ogni possibile scambio. Report `animation-performance-v25-before-expansion.json`, `animation-performance-v25-psa-before-expansion.json`, `animation-performance-v26-native.json` e `animation-performance-v26-psa.json`.
