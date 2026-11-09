# Forma A–D e condizione della partita

La lettera misura la regolarità, non la forza del giocatore. I valori base, il calcolo dell'overall e la resistenza restano separati.

| Classe | ↑ | ↗ | → | ↘ | ↓ |
|---|---:|---:|---:|---:|---:|
| A | 38% | 38% | 18% | 4% | 2% |
| B | 20% | 38% | 29% | 10% | 3% |
| C | 10% | 25% | 30% | 25% | 10% |
| D | 5% | 10% | 30% | 35% | 20% |

Tutte le casistiche sono possibili. Modificatori: +5%, +3%, 0%, −3%, −5%. Ogni fondamentale effettivo è `clamp(round(base * (1 + bonus)), 1, 99)`. L'overall mostrato in formazione viene ricalcolato dai sei fondamentali; non riceve un secondo bonus. Database OFF conserva il gameplay base.

## Ricerca e limiti

169 giocatori esaminati; 99 con campioni sufficienti, 70 con C prudenziale. Distribuzione iniziale: A 18, B 33, C 103, D 15. Le assegnazioni sono stime di regolarità documentate, non classificazioni ufficiali.

Fonte primaria: tabellini individuali partita per partita della Lega, stagioni 2025/26, 2024/25 e, se necessaria, 2023/24; SuperLega e Serie A2. Esempio: [statistiche individuali Giannelli](https://ww2.legavolley.it/Statistiche_i.asp?cmd=no_combo2&Fase=1&TipoStat=2.2&Serie=1&AnnoInizio=2025&Atleta=GIA-SIM-96). URL, stagione, numero di osservazioni e hash delle pagine sono conservati per ogni atleta in `assets/gameplay/player_forms99.json`.

Metodo: deviazioni dalla media dello stesso atleta nella stessa stagione, ponderate per opportunità; sottrazione del 35% del rumore campionario binomiale stimato, normalizzazione per tipo di fondamentale e confronto dei percentili all'interno del ruolo. Non usa overall, media di efficacia o reputazione. Richiede almeno 12 osservazioni utili e il 60% dei pesi del ruolo supportati. Per i palleggiatori mancano conteggi pubblici partita per partita della qualità delle alzate: servizio e muro sono soltanto proxy, marcati a bassa confidenza. Senza dati sufficienti resta C. Le differenze vicino alle soglie non vanno interpretate come certe.

Pesi di regolarità: OH attacco 65/ricezione 25/servizio 10; OPP attacco 85/servizio 15; MB attacco 65/muro 25/servizio 10; L ricezione 100; S servizio 70/muro 30. Percentili crescenti della dispersione: A fino a 18%, B fino a 50%, C fino a 85%, D il resto. Script riproducibile `tools/Research-Forms99.py`, output in `.runtime/condition99/research-results.json`; non modifica il database.

## Persistenza e online

Estrazione indipendente per ogni atleta, riserve incluse, quando si apre la formazione. Il seme è separato dal generatore del gameplay. Cambiare squadra e tornare indietro, annullare, modificare la formazione o la classe non riestrae gli atleti già presenti nel contesto partita. Set e sostituzioni conservano gli esiti.

Campionato e Diventa un mito conservano il contesto anche in un file separato con checksum sotto `user://condition99/matches`, così la sola visualizzazione non riscrive i vecchi salvataggi. I normali salvataggi successivi includono il contesto. File corrotto: condizione neutra, senza estrazione favorevole aggiuntiva. Simulazioni e partite giocate usano lo stesso contesto.

Online l'host estrae e trasmette gli esiti in lobby prima della formazione; i client non possono imporre frecce. Gli ID sono distinti per lato anche quando entrambi scelgono la stessa squadra. È necessario usare la stessa versione del protocollo.

Le classi iniziali sono in una risorsa aggiuntiva. Il DB base non viene riscritto; le personalizzazioni esplicite prevalgono. Vecchi salvataggi sono normalizzati solo in memoria. L'aggiornamento completo e selettivo conservano anche un `assets/gameplay/league.json` già presente e tutti i dati personali.

## Verifica

`Test-Condition99.gd`: 100.000 estrazioni per classe, probabilità positive e somma 100, scarto inferiore a un punto percentuale, limiti, estrazione unica e persistenza. `Test-ConditionIntegration99.gd`: 1.500 controlli su sei fondamentali, libero, opzione OFF, simulazione, salvataggi e RNG separato. `Test-ConditionUI99.gd`: formazione a 1080p/720p, conferma e navigazione dopo ogni rotazione. `Run-OnlineCondition99.ps1`: due client ENet, contesti identici e regressione delle tre seconde. `Test-ConditionUpdate99.py/.ps1`: preservazione del DB personalizzato con entrambi gli aggiornatori. Tutti usano profili isolati.
