# Spike Forever 0.73.0 — Diventa un mito e doppio cambio

Diventa un mito usa ora la stessa partita dell'esibizione: fisica della palla, timing, contatti, scelte tattiche, rotazioni, rincorse, animazioni native, suoni, punteggio e replay. Il giocatore creato rimane sotto il tuo controllo; compagni e avversari usano l'IA della partita normale.

## Doppio cambio palleggiatore–opposto

La gestione delle sostituzioni della 0.66 resta il registro unico per cambi, coppie e rientri. Nel menu sostituzioni si può scegliere **DOPPIO CAMBIO**, selezionare un opposto e un palleggiatore di riserva e confermare entrambi con un solo comando. Il rientro avviene dalla stessa voce, diventata **RIENTRO TITOLARI**. A / Croce conferma; B / Cerchio torna al passaggio precedente. La navigazione supporta stick sinistro e D-pad anche sulle ultime riserve.

- Ingresso con il titolare S in prima linea (P4, P3, P2): l'OPP di riserva prende il suo posto e il secondo S sostituisce l'OPP titolare in seconda linea. Non si scambiano caselle dell'ordine di rotazione.
- L'ingresso conta due cambi; il rientro degli stessi titolari ne conta altri due. Occorrono quattro cambi disponibili per iniziare il ciclo; due rimangono riservati al rientro. Le altre sostituzioni continuano a rispettare il limite di sei.
- Entrambi i cambi sono verificati prima di modificare formazione, contatori, statistiche o presentazioni. Un secondo cambio non consentito impedisce anche il primo. Un cambio programmato durante lo scambio viene rivalidato come coppia a palla ferma.
- Il nuovo S assume realmente la regia: scelta della seconda palla, disponibilità, coperture e statistiche usano la sua identità. L'OPP entrato in prima linea dispone della rincorsa e dell'attacco di zona 2; banda, centrale e pipe mantengono le proprie responsabilità. Nessuna riscrittura della fisica o delle animazioni.
- Il rientro manuale è possibile a palla ferma anche prima di P1. L'allenatore CPU lo esegue quando la casella del titolare S passa in seconda linea. Per iniziare il doppio cambio valuta fase del set, distacco nel punteggio, qualità delle riserve, fatica e cambi residui. Non interviene sui due team umani online o sul personaggio manuale di Diventa un mito.
- Campionato conserva i quattro eventi nei risultati e assegna al secondo S le alzate effettivamente misurate. Stato della coppia, riserve e budget sono sincronizzati dall'host anche online. Al nuovo set la diagonale titolare viene ripristinata prima della nuova formazione, usando la gestione esistente per eventuali indisponibili.

Il limite di sei cambi e il vincolo di rientro nella propria casella con la stessa riserva seguono gli articoli 15.1 e 15.6 del [regolamento FIVB 2025–2028](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-1.pdf). La riserva di due cambi per il rientro è una tutela del gioco, indicata nel menu, per evitare di lasciare la coppia senza possibilità di rientrare.

Verifiche dedicate: `double74-core-tests.json`, `double74-tactics.json`, `double74-ui-tests.json` e `double74-online-{host,guest}.json`. Comprendono tutte le rotazioni e le due metà campo, rifiuti atomici, ingresso/rientro al sesto cambio, programmazione durante lo scambio, gestione infortuni, alzate native alle quattro destinazioni, salvataggio del Campionato e due veri peer ENet. Le schermate del menu sono incluse in `double74-ui-*.png`.

## Cause individuate e correzioni

La versione precedente usciva da `main.step` ed eseguiva un secondo simulatore dentro `legend_match.gd`. Quel simulatore aveva proprie traiettorie, distanze di contatto, velocità, gestione del salto e riposizionamento dei dodici giocatori dopo ogni punto. Cambiava anche le pose sottraendo lo spostamento verticale del filmato PSA a un salto fisico aggiuntivo. Il risultato poteva apparire diverso dall'esibizione anche usando gli stessi modelli.

Il secondo simulatore è stato rimosso. `legend_match.gd` gestisce soltanto identità, input del singolo atleta e collegamento con la carriera. Tutta la partita continua nel motore condiviso di `main.gd`; non vengono eseguite due simulazioni. `avatar.gd`, parser PSA e asset di animazione restano quelli dell'esibizione.

- Gli undici altri giocatori ricevono, costruiscono e attaccano con i sistemi esistenti. Non aspettano i comandi destinati al personaggio creato.
- Le animazioni usano gli stessi filmati e lo stesso sistema delle pose dell'esibizione. Il salto manuale avvia il relativo gesto nativo; non aggiunge uno spostamento verticale diverso alle ossa.
- Ricezione, alzata, attacco, pallonetto, servizio e muro passano dagli stessi controlli del contatto reale e dalle stesse formule della partita normale.
- Si può preparare la carica dell'attacco mentre il compagno sta alzando, mantenendo il comportamento della barra dell'esibizione. Un compagno IA non può decidere un pallonetto per l'attaccante controllato dall'utente.
- Rilasci di tasti e stick restano aggiornati durante pausa e replay, evitando comandi che rimangono premuti.
- Tra i punti, i giocatori raggiungono le nuove posizioni correndo. Sono preservati posizione, velocità e orientamento. Eliminato anche il vincolo che spostava istantaneamente un nuovo battitore da centrocampo a dietro la linea.
- Il libero controllato segue gli ingressi effettivi al posto dei due centrali; il controllo non passa a un altro atleta quando è fuori.

Le statistiche della carriera provengono dal medesimo gestore della partita usato dall'esibizione. Risultati, premi, salvataggi e ritorno alla carriera restano collegati al profilo creato. Non cambiano budget iniziale, sviluppo degli attributi, mercato o salvataggi esistenti.

## Posizione consigliata

Un piccolo cerchio semitrasparente sul pavimento indica la posizione assegnata al tuo giocatore dall'IA in quel momento. Legge il bersaglio finale della stessa pianificazione che gestisce contatto, muro, rincorsa e copertura; non esegue una seconda IA e non sposta il personaggio.

La geometria e il materiale vengono creati una volta sola. Il cerchio rimane sopra le decalcomanie del campo e viene nascosto durante replay, pausa e permanenza in panchina. La scheda del giocatore e i comandi lasciano spazio alla barra e al feedback standard dell'esibizione; la barra compare quando il colpo appartiene al giocatore controllato.

## Controller e comandi

Conferma con **Croce/A** e ritorno con **Cerchio/B** sistemati nel flusso di creazione, nei selettori, nella tastiera virtuale e nelle finestre native di conferma. Il focus può raggiungere Conferma/Annulla e viene ripristinato quando un pulsante degli attributi si disabilita. Evitati doppi caratteri e salti nelle liste.

| Azione | Controller | Tastiera |
| --- | --- | --- |
| Muovi il tuo atleta | LS | WASD |
| Mira, comprese le direzioni dell'alzata | RS | Frecce |
| Bagher / alzata normale | Croce / A | Spazio |
| Carica e rilascia servizio / attacco | Croce / A | Spazio |
| Float / alzata veloce / pallonetto | Quadrato / X | Q |
| Salto in attacco o a muro | R1 / RB | R |
| Tuffo | R2 / RT | C |
| Chiama l'alzata | L1 / LB | F |
| Scatto | L2 / LT | Maiusc |
| Seconda del palleggiatore | Cerchio / B | E |

La ricezione e l'alzata si comandano premendo; servizio e attacco usano la carica e il rilascio dell'esibizione. La battuta mantiene la sequenza completa originale. Movimento e salto dell'attaccante restano manuali: il cerchio suggerisce dove andare, senza raggiungere il pallone al tuo posto.

## Verifiche

- Confronto con stessa squadra, valori, seme casuale e input automatico: 1.800 passi di simulazione più 120 con tutte le pose native, confrontando esattamente palla, contatti, stato, radici, ruoli, RNG, varianti e tempi delle animazioni. Nessuna delega al vecchio simulatore.
- Contatti manuali reali con asset nativi: bagher, tuffo, alzata normale/veloce, attacco, pallonetto e muro. Attacchi senza salto o fuori portata respinti.
- Cinque ruoli, sei rotazioni, servizio proprio/avversario, ingressi del libero e continuità dopo i punti. Nella prova di continuità con pose native non si osservano salti di posizione.
- Flusso controller completo su 720p, 1080p e 1440p, con dispositivi 0/3/7 e configurazioni di conferma mancanti o specifiche per dispositivo. Verifica con eventi controller reali nel sistema input di Godot, senza simulare direttamente i segnali dei pulsanti.
- Risultato condiviso, statistiche personali, un solo premio, salvataggio/ricaricamento e abbandono senza premi.
- Regressioni: esibizione, sostituzioni, campi, finestra verde, replay, formato del campionato, overall, primo tempo/7 e rincorse.

I report correnti sono in `docs/legend73-*.json`, gli strumenti in `tools/*73.*`, le immagini in `docs/legend73-guide-camera-*.png`. I vecchi test del simulatore 72 descrivono l'architettura precedente e sono sostituiti dai test 73 per la partita.

Il benchmark con identico carico IA non rileva un sovraccarico del secondo motore: quest'ultimo non esiste più. Sono sempre presenti dodici sistemi delle pose. Le misure si riferiscono al tempo CPU del codice verificato, non agli FPS GPU o alla latenza del pad fisico.

I salvataggi restano in `user://legend72` e sono compatibili con la 0.72.x. Per l'online delle modalità esistenti entrambi i PC devono usare la 0.73.0 (`SF073`).
