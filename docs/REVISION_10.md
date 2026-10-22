# Revisione 10 — fisica precedente, mira e movimento

La palla torna al comportamento della revisione 08, precedente all'adattamento del ritmo di Killer Aces. Restano le formazioni, le sei rotazioni, i ruoli e le letture tattiche della revisione 09. La telecamera, l'arena, i materiali, i suoni e i pulsanti di azione sono conservati.

## Fisica della palla ripristinata

Tutti i voli usano nuovamente una gravità costante di **9,81 m/s²**. Non si applica più una gravità diversa per famiglia di colpo per aumentare l'altezza degli archi. Il calcolo iniziale della velocità, il drag, lo spin, l'integrazione a sottopassi e gli intercetti coincidono con i sorgenti precedenti salvati in `baseline-v08/ball_flight.gd`.

| Colpo | Tempo di volo ripristinato |
|---|---|
| Battuta potente | 0,90 s al 100%, fino a 1,20 s con poca carica |
| Battuta float | 1,12 s al 100%, fino a 1,42 s con poca carica |
| Ricezione ordinaria | 1,05 s con qualità perfetta, fino a 1,50 s con qualità minima |
| Alzata normale | 1,02 s con qualità perfetta, aumentato se la qualità peggiora o serve tempo per la rincorsa |
| Alzata veloce | 0,62 s, con conversione in palla alta quando la rincorsa non è raggiungibile |
| Schiacciata | 0,72 s con poca carica, 0,48 s a piena potenza |
| Colpo di seconda | 0,83 s |

Le durate dell'attacco indicano il volo previsto fino al bersaglio a terra. Il contatto di un difensore o del muro può avvenire prima e modifica fisicamente la traiettoria. Restano le collisioni con rete e mani, il rimbalzo dopo il punto e le situazioni fuori sistema.

## Comandi aggiornati

Lo **stick sinistro** governa tutte le direzioni: mira della battuta e della schiacciata a otto settori, alzata a quattro direzioni, scelta del compagno aggiuntivo e orientamento delle mani a muro. Lo stick destro non viene utilizzato. Gli atleti si spostano automaticamente in base a ruolo e situazione; lo stick non aggiunge movimento manuale nemmeno durante il servizio.

Su tastiera, **WASD e frecce** svolgono le stesse scelte direzionali. Croce/A/Spazio, Quadrato/X/Q e Cerchio/B/E mantengono le rispettive azioni. Carica crescente, sovraccarico, precisione e tempismo della ricezione restano quelli già sviluppati. Nessun timer oscillante.

L'aiuto iniziale, F1 e gli indicatori contestuali mostrano il nuovo stick.

## Corpi e animazioni

Nel video allegato il battitore esegue il salto sul posto. Il codice precedente eliminava lo spostamento orizzontale della sorgente e azzerava la velocità del battitore durante il servizio. Inoltre normalizzava ogni fotogramma rispetto al bacino, cancellando parte del trasferimento del peso.

- La normalizzazione usa ora la vera radice dello scheletro. Il bacino conserva le oscillazioni e il peso passa da un appoggio all'altro.
- Il servizio applica al giocatore la rincorsa originale, compreso il seguito dopo il colpo. Il battitore parte automaticamente a 11,9 m, nella zona libera e davanti alla piattaforma delle tribune. La posizione della radice allo stacco rimane almeno a 9,4 m dalla rete. Carica e potenza mantengono le stesse regole.
- La battuta potente usa la variante originale `Serve_Action_SmashJumped_1`, che contiene una rincorsa completa compatibile con lo spazio disponibile. Per la float si usano i passi finali della rincorsa, a partire da 1,188 s della sorgente, conservando il rapporto originale fra passo e avanzamento del corpo. Non viene accorciato artificialmente lo spostamento di ogni passo.
- La palla resta nella mano durante la preparazione e viene lanciata nella parte finale; la traiettoria raggiunge la mano nel punto di contatto che comprende l'avanzamento del corpo. Il lancio preparatorio dura 1,061 s nella float e 1,12 s nella battuta potente. La fisica e i tempi della palla dopo il colpo restano quelli ripristinati dalla revisione 08.
- Le nuove transizioni partono dalla posa effettivamente visualizzata, anche quando viene interrotto un blend ancora in corso. Prima potevano ripartire dalla posa grezza della clip uscente e far saltare le ginocchia.
- Le correzioni dei piedi entrano ed escono gradualmente. Non viene più rimossa in un singolo fotogramma una correzione di 16 cm. La preparazione del bagher conserva anche l'altezza del bacino associata al passo, evitando gambe tese sotto un bacino accovacciato.
- Corretto l'abbinamento delle due animazioni laterali: nella sorgente i nomi sinistra/destra non corrispondevano al segno dello spostamento che veniva usato dal gioco.
- L'animazione preparata per un contatto viene campionata al tempo raggiunto nello stesso passo fisico della palla, riducendo la correzione visiva richiesta nel fotogramma del tocco.

## Tuffo completo e recupero

Il vecchio gesto a una mano è sostituito da `PASS_2H_Dig_Front_RHand_FromHalfSquat.psa`, esportato dalla libreria originale di Spike Volleyball. La clip dura circa 2,72 s: il busto scende a circa 14 cm dal pavimento e il giocatore torna in piedi prima di riprendere la locomozione ordinaria.

La radice del giocatore segue lo spostamento della sorgente, con una correzione progressiva verso il punto raggiungibile del salvataggio. Restano le collisioni fra compagni e il limite della linea centrale. Il contatto non sposta la palla sulle mani. La scivolata e la rialzata proseguono anche dopo il tocco; ricevitore e palleggiatore vengono scelti considerando il tempo di recupero. Un tuffo in avanti non impone una mezza rotazione istantanea per una palla ormai alle spalle: resta disponibile il recupero tardivo dedicato.

Se un salvataggio termina oltre i normali limiti di movimento dei compagni, il giocatore rientra gradualmente; non viene riposizionato all'interno del campo nel fotogramma successivo.

## Movimento senza palla

Il bersaglio di movimento conserva velocità attraverso i cambi di fase, con una risposta smorzata. I giocatori completano la lettura precedente durante il tempo di reazione individuale. Le ali iniziano ad aprirsi già durante la ricezione; il centrale corregge gradualmente la profondità della rincorsa. Dopo l'alzata, i compagni entrano nella copertura a due profondità con ritardi distinti. Il libero mantiene una corsia stabile mentre la pipe attraversa il centro.

Rotazioni e posizioni in battuta/ricezione restano quelle della revisione 09. Le letture proattive sono contenute nelle rispettive zone e non aggiungono oscillazioni casuali.

## Verifiche riproducibili

`tools/Test-Reference.gd` confronta sei famiglie di traiettorie con l'implementazione effettiva della revisione 08: potente, float, ricezione, alzata normale, veloce e schiacciata. A **30, 60 e 120 Hz** controlla velocità iniziale, posizione e velocità a ogni passo e intercetto finale. La prova dedicata passa. Controlla anche **144 posizioni specchiate**, dodici formazioni e sei rotazioni con ruoli coerenti.

`tools/Check-ReferenceScope.ps1` conserva i controlli su camera, grafica, audio, pulsanti e carica; permette le modifiche direzionali richieste e verifica che il movimento dei giocatori non legga lo stick. `Verifica.cmd` include queste prove insieme alla partita simulata, ai contatti e alle transizioni.

La verifica completa della versione finale passa con gli asset originali e anche senza modelli/animazioni importati:

| Prova | Risultato |
|---|---|
| Partita automatica, asset originali | 16 punti, 197 contatti, scambio massimo di 22 contatti |
| Partita automatica, fallback | 16 punti, 98 contatti |
| Distanza minima fra compagni | 0,780 m con asset originali; 0,799 m nel fallback |
| Salti ripetuti a muro | Nessun secondo salto dello stesso giocatore sul medesimo attacco |
| Input, carica, ricezione, traiettorie | Controllati a 30, 60 e 120 Hz |
| Tattiche senza palla | 432 casi di ruolo/fase; continuità del movimento a 60/120 Hz |
| Formazioni | 144 posizioni specchiate, dodici formazioni, sei rotazioni |
| Modelli e transizioni | Proporzioni delle ossa conservate, skinning coerente e transizioni interrotte senza salto della posa |
| Rincorsa al contatto | Float 3,413 m; salto potente 3,072 m; stacco di entrambi dietro la linea di fondo |
| Tuffo nel gioco | Contatto con la palla verificato, busto a 0,140 m dal suolo, rialzata completata prima del ritorno alla corsa |

I report sono `revision-contact-report.json`, `fallback-contact-report.json`, `avatar-motion-report.json`, `avatar-capture-report.json`, `tactical-motion-quality-report.json` e `movement-quality-report.json`. Il log complessivo è `revision10-verification.log`. I test dei controller inviano eventi e verificano il codice di input; non sostituiscono una prova manuale su ciascun modello fisico di controller.

## Video della versione aggiornata

- [Partita, 40 secondi](Spike%20Forever%20-%20movimenti%20e%20fisica%20ripristinata.mp4), con la telecamera di gioco.
- [Rincorse e tuffo, 19,5 secondi](Spike%20Forever%20-%20rincorse%20e%20tuffo.mp4). Questa sola ripresa usa una camera ravvicinata per mostrare appoggi, avanzamento del corpo e recupero dal pavimento. La camera del gioco è conservata.

La ripresa ravvicinata chiama gli stessi metodi del gioco: battuta, contatto, scelta del recupero e ritorno in piedi. Non riproduce un montaggio separato di pose.

Il backup completo precedente è in `docs/baseline-v09`. I report della revisione 09 descrivono il comportamento storico della sua palla; per i comandi attuali fa fede il README.
