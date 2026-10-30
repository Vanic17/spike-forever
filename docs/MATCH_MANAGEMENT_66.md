# Sostituzioni, resistenza ed eventi misurati — 0.66

Il sistema conserva i sei slot tattici esistenti e cambia l'identità effettiva dell'atleta nel relativo slot. Nome, numero, aspetto, mano, preferenza di servizio e sei attributi vengono applicati all'avatar e al gameplay. Il movimento reale, le rotazioni e i comandi non sono riscritti.

## Regole

Fonte: [FIVB Official Volleyball Rules 2025–2028](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-1.pdf), sezioni 15.5–15.7 e 19.4. I cambi ordinari sono sei per squadra/set; un titolare può uscire e rientrare una volta, soltanto nella propria posizione e al posto della propria riserva. La riserva entra una volta e non può essere spostata su un altro abbinamento. Prima della prima battuta di ciascun set la formazione può essere modificata senza consumare i sei cambi; la prima preparazione della battuta fissa il sestetto del set.

Le sostituzioni sono consentite esclusivamente a palla ferma. Non si può cambiare chi sta battendo durante carica/lancio, né alterare il campo durante un replay. Un giocatore non libero può essere impiegato fuori dal suo ruolo naturale: la UI mostra il confronto e mantiene il posto nell'ordine di rotazione. Gli ingressi del libero restano separati dai sei cambi. Durante il set il centrale coperto dal libero deve rientrare prima di essere sostituito ordinariamente.

Per un atleta indisponibile si prova prima un cambio ordinario; soltanto se impossibile viene consentito quello eccezionale, registrato separatamente. Chi è sostituito eccezionalmente non può rientrare nella partita. Il libero indisponibile viene sostituito/ridesignato separatamente, senza consumare i cambi ordinari. Le condizioni iniziali vengono controllate prima di iniziare: se non è possibile schierare una squadra, `configure_rosters` restituisce false.

## Resistenza

La fatica è 0–100, distinta dalla forma. Durante il gioco cresce per secondi attivi, spostamenti, salti reali o di finta e contatti; i partecipanti ricevono inoltre un carico moderato a fine set. Il ruolo modifica leggermente il carico. Panchinari non impiegati non accumulano attività immaginaria. Il recupero fra date di calendario è responsabilità del gestionale, non viene inventato tornando al menu.

Le curve sono in `assets/gameplay/match_management_v1.json`. La penalità si attiva progressivamente dopo fatica 30/35/45, con cap di 5,5 punti percentuali alla qualità, 3,5 alla precisione e 3,5% al rischio aggiuntivo di un colpo mal caricato. La qualità perfetta viene penalizzata meno; una carica esatta al 100% annulla il rischio aggiuntivo di affaticamento. Nessun cambio alla velocità della barra, alla gravità o alla velocità massima dei giocatori.

Con fatica OFF, qualità/precisione/rischio ritornano esattamente i valori originali e la CPU non effettua cambi motivati dalla fatica. Le estrazioni per infortuni hanno un RNG separato dal gameplay e una probabilità bassa con limite per partita; durata e fasce sono parametri di design. Sono eventi simulati, non informazioni sanitarie sugli atleti reali.

La carriera può attivare separatamente `career_form`: la forma -5…+5 modifica la qualità di massimo ±1 punto percentuale. Non cambia potenza, barra, fascia perfetta o rischio. Esibizione e online lasciano questo parametro false. Disabilitare la fatica elimina sempre la sua penalità; la forma resta un indice distinto quando la modalità carriera la abilita esplicitamente.

## UI e online

Pausa → Sostituzioni / Resistenza: sestetto a sinistra, panchina a destra, confronto dei sei fondamentali, condizione e ruolo; conferma sempre fuori dalle aree scorrevoli. Croce/A sceglie e conferma, Cerchio/B torna prima al sestetto e poi alla pausa. D-pad e levetta sinistra navigano; il focus scorre automaticamente e viene conservato al ritorno. Le associazioni D-pad sono esplicite per ogni ID controller, inclusi dispositivi non numerati come zero.

Online la preferenza fatica è dell'host e viene condivisa nel lobby/start. Anche la panchina viene validata e inviata. L'ospite può richiedere soltanto cambi della propria squadra; l'host verifica abbinamenti, disponibilità e stato della palla e trasmette identità e contatori con RPC affidabile. Le condizioni correnti dei dodici atleti viaggiano negli snapshot compatti. Protocollo SF066.

## Eventi effettivi e API

`game.match_management.configure_rosters(teams, lineups, conditions, options)` riceve due squadre complete, due formazioni di sette, condizioni per ID e opzioni `fatigue`, `injuries`, `auto_subs`, `date`, `seed`. I dati base non vengono modificati. `substitute(side,slot,id,exceptional)` restituisce una motivazione se rifiutato, stringa vuota se riuscito. `export_state`/`import_state` gestiscono la sincronizzazione.

Il segnale `match_completed(result)` scatta una sola volta alla conclusione reale. Il risultato conserva punteggi per set prima dell'azzeramento dello scoreboard e statistiche marcate `measured`: contatti di servizio, ricezioni realmente toccate e qualità, difese, alzate, attacchi e muri. Punti e MVP derivano da questi eventi; nessuna ricezione/difesa viene attribuita ai compagni non coinvolti. Le presenze sono registrate per partecipazione effettiva al gioco. `last_result` rimane disponibile dopo il ritorno al menu.

I campi giocatore includono `attack_attempts`, `attack_kills`, `serve_attempts`, `serve_errors`, `aces`, `blocks`, `block_contacts`, `receptions`, `reception_positive`, `reception_perfect`, `digs`, `sets`, `points`, `sets_played`, `appearances`, `fatigue_end`, `form` e `injury_until`. Le battute tentate conteggiano i contatti strumentati; non vengono aggiunti numeri stimati alle partite giocate. Il gestionale può mostrare separatamente dati non disponibili, senza mescolarli alle stime delle partite simulate.

## Prove

- `tools/Test-MatchManagement66.gd`: sei cambi, rientri abbinati, reset set, libero, sostituzione eccezionale, identità, rifiuto durante azione, cap e OFF neutro, singolo risultato misurato. [Report](match66-management.json).
- `tools/Test-MatchManagementUI66.gd`: input reali sintetici del controller con ID 9, campo → panchina → conferma, ultimo slot scorribile e Cerchio/B. 1920×1080, 1280×720, 1024×600. [Report](match66-ui.json).
- `tools/Test-OnlineSubstitutions66.gd`: due processi ENet, cambio dell'ospite e rientro corretto, tentativo di riutilizzo rifiutato, avatar e contatori identici. [Host](online66-substitutions-host.json) · [Ospite](online66-substitutions-guest.json).
- Regressione `tools/Test-StatsRelease65.gd`: battute salto/float, rilascio alzata, precarica e attacco con statistiche ON/OFF conservati.
