# Ruoli e rotazioni 0.19.0

Fonti consultate: [sigle FIVB](https://www.fivb.org/VisSDK/Fivb.Vis.DataWPF/Fivb.Vis.DataWPF~Fivb.Vis.Person.PlayerVolleyPosition.html), [regole FIVB 2025–2028](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-v05.pdf), [Coaches Manual II, pp. 49–56](https://www.fivb.com/wp-content/uploads/2024/03/Coaches_Manual_Level_II_EN.pdf).

Etichette visibili: S Setter, OH1/OH2 Outside Hitter, MB1/MB2 Middle Blocker, OPP Opposite, L Libero. I suffissi distinguono i due atleti dello stesso ruolo. La tabella VIS FIVB usa OS per Opposite Spiker; il gioco mantiene la convenzione OPP per chiarezza. I ruoli non cambiano quando cambia il giocatore che alza in emergenza.

## Sei rotazioni del sistema 5–1

La numerazione P0…P5 corrisponde al contatore interno. L'asterisco indica il centrale di seconda linea: viene sostituito dal libero quando non è il battitore.

| Rotazione | Zona 1 | Zona 2 | Zona 3 | Zona 4 | Zona 5 | Zona 6 |
|---|---|---|---|---|---|---|
| P0 | S | OH1 | MB1 | OPP | OH2 | MB2* |
| P1 | OH1 | MB1 | OPP | OH2 | MB2* | S |
| P2 | MB1* | OPP | OH2 | MB2 | S | OH1 |
| P3 | OPP | OH2 | MB2 | S | OH1 | MB1* |
| P4 | OH2 | MB2 | S | OH1 | MB1* | OPP |
| P5 | MB2* | S | OH1 | MB1 | OPP | OH2 |

L'ordine di servizio è invariato: S, OH1, MB1, OPP, OH2, MB2. Una squadra ruota quando conquista il servizio, non quando fa un punto mantenendo la battuta. In ogni rotazione rimangono tre giocatori di prima linea; il libero non viene selezionato fra attaccanti o muratori.

## Fasi distinte

| Fase | Responsabilità e vincoli |
|---|---|
| Battuta nostra | Il battitore resta quello dell'ordine; i tre di prima linea possono preparare le corsie specialistiche OH a sinistra, MB al centro, OPP/S a destra. È consentito dalla regola 7.4 del regolamento 2025–2028. Non si forza più l'incrocio dei laterali dopo il servizio. |
| Battuta avversaria | Si mantiene l'ordine relativo di ricezione, con OH e libero nei corridoi di ricezione e S pronto alla penetrazione. Le etichette dipendono dal ruolo, non dalla profondità visiva del giocatore. |
| Prima costruzione | Rimane l'eccezione P0: OH1 riceve e attacca a destra, OPP offre zona 4; non attraversano contemporaneamente il campo. |
| Rigioco e attacco | S prende il secondo tocco se disponibile, altrimenti subentra un compagno; i ruoli permanenti non vengono riassegnati. MB prepara il primo tempo, i laterali aprono e i giocatori di seconda linea conservano il vincolo dei tre metri per l'attacco alto. |
| Difesa | Il piano laterale viene fissato una volta per costruzione avversaria, in base ai lati fisicamente occupati dai due laterali; MB rimane al centro. Il piano non viene ricalcolato ogni fotogramma mentre i due atleti si incrociano. |
| Muro | Il centrale controllato è sempre il MB di prima linea. L2/R2 aggiungono i laterali della stessa assegnazione sinistra/destra usata dalla difesa. La CPU sceglie il muratore più vicino alla corsia reale, poi il centrale: non si basa su una posizione teorica dall'altro lato del campo. |
| Recupero ed emergenza | L'impronta del corpo a terra rimane riservata e il palleggiatore aggira il libero; cambiare temporaneamente l'attore dell'alzata non cambia l'etichetta del ruolo o l'appartenenza alla prima linea. |

La FIVB descrive gli scambi tattici di posizione come parte normale della transizione; il difetto corretto è la riassegnazione incoerente durante la stessa costruzione, non ogni spostamento tra zone. Nessuna scelta copre letteralmente ogni traiettoria possibile: i test coprono le combinazioni strutturali delle sei rotazioni e i recuperi riproducibili.

Verifiche: 288 combinazioni attacco/difesa/rotazione nel nuovo Test-RoleMatrix, 290 verifiche ricezione, 840 verifiche posizionali aggiornate distinguendo preparazione al servizio e ricezione; test muro manuale, recupero, palleggiatore e suite partita.
