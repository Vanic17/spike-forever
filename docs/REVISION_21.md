# Revisione 0.21.0 — Xbox, controllo aggiornamenti, primo side-out

## Primo punto avversario e alzata in zona 4

Caso riprodotto: Aurora comincia al servizio, perde il primo punto, Ember conquista il servizio e ruota; Aurora rimane in R1. Questa sequenza regolamentare era corretta: l'attaccante di zona 4 era OH1, non mancava nello schieramento.

L'OH, tuttavia, arrivava circa mezzo metro lontano dal contatto. Il limite minimo dell'alzata usava soltanto distanza/5,4 + 0,26 secondi, sottostimando frenata e correzione della rincorsa. `approach_planner.gd` considera velocità corrente proiettata verso il bersaglio, eventuale inversione, accelerazione e frenata con gli stessi limiti del movimento. Il tempo minimo tiene conto del completamento dell'appoggio. Un attaccante già pronto per una veloce non viene più mandato prima ad arretrare verso l'apertura completa della palla alta.

È corretto anche il corridoio del palleggiatore dopo la ricezione a destra: il primo aggiramento usa il lato fisicamente libero, invece di tagliare attraverso il ricevitore seguendo la direzione del bersaglio finale. Dopo l'alzata il secondo toccatore libera la rincorsa dell'attaccante, mantenendo la priorità del contatto. Nessun incremento della velocità massima degli atleti e nessuna sostituzione dell'OH con un altro ruolo.

`Test-FirstSideout.gd` verifica 24 sequenze complete ricezione → alzata in 4 → attacco dopo il primo punto avversario: tre corsie di ricezione, due seed, 60/120 Hz e PSA/AnimationTree. La validazione richiede tre contatti reali e la successiva fase di ricezione avversaria, non soltanto la partenza dell'animazione.

## Controller Xbox

| Comando | Funzione |
|---|---|
| A | Ricezione, alzata normale, carica/rilascio della battuta al salto e dell'attacco, salto a muro |
| X | Battuta float e alzata veloce |
| B | Colpo di seconda del palleggiatore |
| Levetta sinistra | Mira, direzioni e movimento del muro |
| LT / RT | Richiamo rispettivamente del laterale sinistro / destro; insieme muro a tre |
| Menu | Pausa/riprendi |
| Levetta destra | Non usata per la mira |

Gli assi della levetta sinistra sono associati anche alle azioni Godot, oltre alla lettura del controller connesso. Le etichette del muro mostrano LT/RT su Xbox e L2/R2 su PlayStation. Le associazioni utilizzano gli identificativi standard [Godot 4.5](https://docs.godotengine.org/en/4.5/classes/class_@globalscope.html#enum-globalscope-joybutton).

`Test-Xbox.gd` verifica eventi A/X/B/Menu, carica/rilascio, assi della levetta sinistra, assenza di mira dalla destra, LT e RT indipendenti e contemporanei, rilascio e salto del muro. La suite dei controlli verifica inoltre le dodici combinazioni di alzata e i contatti. La verifica di questa sessione usa eventi simulati: non risultava collegato un controller fisico.

## Aggiornamenti all'avvio

All'apertura grafica il menu interroga GitHub Releases in background. L'assenza di rete non impedisce Gioca. Il confronto delle versioni è numerico; versioni uguali, precedenti, bozze e prerelease non producono un avviso. Fra le versioni più recenti viene scelta la maggiore con pacchetto Windows verificabile.

Il popup indica versione installata e disponibile e offre **Aggiorna** e **Non ora**. L'installazione parte soltanto dopo conferma. Non ora conserva la versione corrente. Se la risposta arriva dopo che è iniziato uno scambio o durante una carica, la proposta attende una pausa fra i punti o una preparazione al servizio libera; il popup non sottrae il rilascio del comando. La pausa precedente viene ripristinata dopo il rinvio o un errore di download. Il pannello mantiene anche l'installazione manuale delle release precedenti.

`Test-StartupUpdates.gd` verifica avvio della ricerca, confronto numerico, rinvio, assenza di popup di downgrade, attesa durante lo scambio e conferma del pacchetto selezionato. Il renderer del popup è verificato con una risposta di prova; `Test-RemoteUpdates.gd` verifica separatamente API e pacchetto pubblicato reali.
