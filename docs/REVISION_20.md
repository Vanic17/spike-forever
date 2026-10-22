# Revisione 0.20.0 — menu illustrato e sistema 5–1

La specifica fornita dall'utente è conservata in [SPECIFICA_ROTazioni_5-1.md](SPECIFICA_ROTazioni_5-1.md). Le sue indicazioni di posizionamento sostituiscono le eccezioni tattiche della revisione 19. Riferimento regolamentare verificato: [FIVB 2025–2028, §§7.4–7.7](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-v05.pdf).

## Identità e rotazione

`rotation_model.gd` è la fonte degli slot: R1 ha S in Z1, OH1 in Z2, MB1 in Z3, OPP in Z4, OH2 in Z5 e MB2 in Z6. L'avanzamento mantiene le coppie S/OPP, OH1/OH2 e MB1/MB2 opposte. Il punteggio conserva la rotazione soltanto alla conquista del servizio; mantenerlo non fa ruotare.

Ogni record distingue titolare dello slot, identità fisica attiva, ruolo, zona, prima/seconda linea, sostituzione del libero e battitore. Il libero usa l'istanza visiva del centrale sostituito: restano esattamente sei atleti per squadra. L'assegnazione cambia nella preparazione del nuovo rally; il centrale che batte resta in campo per tutto lo scambio. Le coordinate non attribuiscono diritti di prima linea.

## Posizioni e transizioni

`serve_layout.gd` contiene sei formazioni di ricezione esplicite in metri. Le posizioni sono specchiate per l'altra squadra; tre ricevitori principali hanno corsie distinte. Il palleggiatore rimane nel proprio ordine fino al servizio e penetra dopo il contatto. La vecchia penetrazione progressiva durante l'attesa del servizio è stata rimossa.

Alla nostra battuta, Z1 è il battitore e gli altri cinque partono dalle responsabilità difensive dei propri ruoli. La squadra al servizio non viene sottoposta ai vincoli laterali della ricezione. Il battitore torna alla difesa usando il controller di movimento esistente.

Nella costruzione OH di prima linea prepara Z4, MB il primo tempo, OPP Z2; con S davanti l'opposto offre la seconda linea e l'OH dietro la pipe. È rimossa l'eccezione R1 che scambiava OH e OPP nel primo attacco. I passaggi fra corsie usano due corridoi posteriori differenti: OH più profondo, OPP più corto. Il centrale conserva priorità sul proprio corridoio di finta; i laterali non vengono instradati attraverso la sua rincorsa.

La difesa e il muro condividono corsie specialistiche stabili, indipendenti da incroci momentanei dei corpi. Le selezioni di muro continuano a escludere la seconda linea. La copertura dell'attaccante si dispone su due profondità attorno al punto di attacco previsto, con bersagli differenti per libero, OH dietro, OPP dietro, centrale e palleggiatore.

Il limite di due muratori riportato nel documento è in conflitto con la precedente richiesta esplicita del muro manuale a tre. Sono conservati centrale controllato, L2/R2 e tre muratori quando entrambi i laterali sono richiamati. Non è stato reintrodotto il vecchio sistema di lettura automatico.

## Verifica dei piedi e diagnostica

`rotation_context.gd` rileva le scarpe dallo scheletro già animato e conserva l'ultimo appoggio disponibile. Il fallback senza asset usa le proprie regioni di appoggio. Al contatto del servizio viene salvata la fotografia della squadra in ricezione: sei confronti laterali (ogni esterno rispetto agli altri due) e tre confronti avanti/dietro. Questo verifica anche l'ordine dei due estremi quando le regioni dei piedi si sovrappongono; confrontare solo i centri non sarebbe sufficiente. La tolleranza numerica è 1,5 cm. L'eventuale contatto mancato del battitore mantiene la precedenza sul fallo di posizione.

F1 mostra ID fisico, ruolo, zona regolamentare, prima/seconda linea, battitore e target; prima della battuta disegna gli appoggi. `tools/Test-RotationSpec.gd` salva un replay dei layout e appoggi in `docs/rotation-spec-replay.json`. Il test percorre entrambe le squadre e tutti i giri con PSA e AnimationTree, controlla ripetibilità dei sei giri, side-out, eleggibilità e rilevamento di piedi fuori ordine.

## Menu

Sfondo: immagine senza pulsanti fornita dall'utente, copiata senza modificarla. Gioca e Aggiornamenti sono veri pulsanti Godot, con cornici SVG oro/nero e il font open source Permanent Marker (licenza inclusa). Il pannello delle patch si apre sopra l'illustrazione; la selezione funziona con levetta sinistra e Croce/A, con Cerchio/B per tornare. Le associazioni del gameplay sono conservate.

Il pacchetto comprende PNG, SVG e font caricati direttamente: funziona anche senza cache di importazione dell'editor. Rimangono disponibili ricerca e installazione delle release precedenti, inclusa 0.19.0.

## Validazione

- 24 casi servizio/ricezione nelle due modalità di animazione, 72 fotografie dei piedi e 1.728 controlli di identità/eleggibilità.
- 288 combinazioni ruolo/rotazione/fase e 36 scenari della finta del centrale, con esattamente un salto e senza tocchi alla palla.
- Partite automatiche native e fallback, controlli dei contatti, distanze fra giocatori, muro, palleggiatore ostacolato, tuffi, recuperi e continuità delle animazioni.
- Menu verificato a 16:9, 4:3 e ultrawide, navigazione controller, isolamento del pannello patch e avvio offline.
- Controllo di ambito: cariche, input di gioco, traiettorie, velocità massime, parser PSA e backend delle animazioni conservati.
