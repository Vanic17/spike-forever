# Spike Forever 0.72.0 — Diventa un mito

Nel menu **Gioca** si aggiunge **Diventa un mito**, accanto a Esibizione, Online e Campionato. È una carriera del singolo atleta con un motore manuale separato: le altre modalità mantengono i propri comandi e il proprio gameplay.

## Crea il giocatore e firma il primo contratto

- Nome, numero, ruolo, mano, preferenza di servizio, capelli, barba e carnagione.
- Sei attributi iniziali da 30 a 65, con un budget totale di 300 punti. L'overall usa i pesi già previsti per ogni ruolo.
- Tre club di ingresso, individuati dalle formazioni del database locale: attualmente Cuneo, Monza e Prata. Un database modificato può cambiare questa selezione.
- Partite al meglio di tre o cinque set e tre livelli di difficoltà. Le difficoltà modificano l'esecuzione degli avversari, senza cambiare la portata dei contatti o i comandi del giocatore.
- Il tuo atleta entra nel roster e nella formazione del club con la divisa corretta, nome e numero personali.

## Controllo manuale in campo

Controlli soltanto il giocatore creato. Gli altri undici atleti gestiscono ricezione, costruzione, attacco, muro e copertura. Le alzate dei compagni coinvolgono più attaccanti; chiamando la palla ottieni priorità. Il pallone viene alzato verso un corridoio del campo: devi raggiungerlo, saltare e colpirlo.

| Azione | PlayStation | Xbox | Tastiera |
| --- | --- | --- | --- |
| Movimento libero | Stick sinistro | LS | WASD |
| Mira | Stick destro | RS | Frecce |
| Salto manuale / salto a muro | R1 | RB | R |
| Bagher, palleggio, attacco o servizio al salto | Croce | A | Spazio |
| Float / pallonetto | Quadrato | X | Q |
| Seconda / recupero | Cerchio | B | E |
| Chiama l'alzata | L1 | LB | F |
| Sprint | L2 | LT | Maiusc |
| Tuffo | R2 | RT | C |
| Telecamera | Triangolo | Y | V |
| Pausa | Options | Menu | Esc |

Tieni il comando del colpo per caricare, poi rilascialo quando la palla è alla portata del corpo. Il salto richiede un comando distinto: la carica non sposta e non fa saltare automaticamente l'atleta. A muro, le mani devono incontrare davvero il pallone durante il salto. Il tuffo muove il corpo nella direzione scelta; non aggancia palloni lontani.

Il movimento ha accelerazione, frenata, sprint e consumo di energia. Sono mantenuti gli asset PSA e le pose native AnimationTree; la traslazione verticale delle animazioni viene compensata, così il salto visibile segue il salto fisico manuale. Il contatto modifica la velocità del pallone senza spostarlo artificialmente sulla mano.

L'attributo Muro aumenta il controllo delle respinte e la probabilità di un ritorno forte dopo un contatto valido. Oltre il 100%, servizio e attacco mantengono l'aumento della velocità fisica insieme al rischio crescente di errore.

Il libero entra in seconda linea al posto del centrale e lascia il campo quando il centrale torna davanti o serve. In quei periodi segui la partita dalla panchina; il comando non passa al centrale. I falli di servizio, quattro tocchi e attacchi irregolari di seconda linea o del libero sono controllati dal motore dedicato.

## La tua carriera

Hub personale con prossima partita, profilo, guardaroba, crescita, calendario, classifica, mercato, storico e salvataggi. Le competizioni e il passaggio di stagione riutilizzano il calendario del Campionato Master League.

Il voto deriva dalle azioni effettivamente registrate del tuo giocatore: attacchi, punti, ace, muri, difese, ricezioni, alzate, assist ed errori. Le partite simulate degli altri club non assegnano esperienza personale. Ogni 60 XP ottieni un punto abilità; il costo per aumentare una statistica sale a 70 e a 85, fino al limite di 99.

La reputazione e il rendimento continuativo possono generare offerte da club più forti, con contratto, ingaggio e storico dei trasferimenti. Firmare conserva identità e progressi, rimuove l'atleta dal vecchio roster e lo inserisce una sola volta nel nuovo. La stagione può proseguire dopo il suo completamento.

Dodici slot dedicati in `user://legend72`, con checksum e backup. Database globale, modifiche del roster e salvataggi Master League rimangono separati. Il risultato viene registrato e premiato una sola volta. Se la scrittura su disco fallisce, rimane visibile in memoria con un avviso per ritentare tramite **SALVA**.

Dalla pausa puoi riprendere o tornare direttamente alla tua carriera. Una partita abbandonata non produce un risultato o premi. Il risultato finale torna invece alla schermata della prestazione.

## Verifiche

- Backend: 355 controlli, quattro stagioni, limiti di creazione, crescita, offerte, trasferimenti, backup e separazione dei salvataggi.
- Manuale: tutti i cinque ruoli, movimento indipendente dalla mira, salti, contatti, tuffi, ingresso del libero, difficoltà e distribuzione delle alzate. Una partita completa fisica arriva al risultato senza assegnare punti per scorciatoia.
- UI: 197 controlli e 33 combinazioni di pagina/risoluzione, navigazione controller e traduzione italiana/inglese.
- Scena reale: asset nativi, identità e maglia, pausa, risultato, abbandono e recupero dopo errore di salvataggio.
- Catture reali di corsa, salto, bagher, muro e tuffo; pose finite e contatti visibili vicini al pallone.
- Regressioni delle sostituzioni, campi, finestra verde, replay, formato del campionato e overall.

I report sono in `docs/legend72-*.json`; le anteprime in `docs/legend72-*.png`. Il benchmark misura il tempo CPU della simulazione e delle dodici pose native, non gli FPS complessivi della scheda video. I comandi sono verificati con eventi controller sintetici: il test finale sul pad fisico resta utile per sensibilità e sensazione del controllo.

L'online delle modalità già esistenti richiede la stessa versione su entrambi i PC (`SF072`). Diventa un mito è una carriera locale.
