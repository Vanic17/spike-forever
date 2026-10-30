# Spike Forever 0.71.0 — Panchine e bordi campo

Rimosse da tutti i dodici profili le due stampe dietro la linea di fondo che ne coprivano una parte. Gli altri sponsor, compreso Del Monte sui due lati della rete, rimangono presenti.

Il tavolo dei segnapunti passa da 1,15 m a 0,83 m sul bordo superiore. Frontale e monitor sono ridimensionati; gli addetti hanno un'animazione seduta con le mani sul piano, anziché sulle ginocchia sotto al tavolo.

La panchina reagisce con due–quattro riserve, talvolta anche l'allenatore, mentre gli altri continuano a osservare. Applauso, cenno con la mano, indicazione, assenso, gesto a mani aperte e sguardo al compagno sono famiglie diverse: nessuna viene assegnata a due persone della stessa panchina nello stesso punto. Una riserva non ripete il proprio ultimo gesto al punto seguente. Anche i ritardi e la velocità delle reazioni variano. In caso di punto avversario sono possibili piccole reazioni senza esultanza.

Quattordici animazioni native aggiuntive: dieci gesti seduti, tre gesti dell'allenatore e un'attività al tavolo. I gesti mantengono gambe e bacino delle animazioni originali; nessun nuovo AnimationTree o parser PSA per fotogramma. Le nuove reazioni dell'allenatore evitano lo spostamento laterale di alcuni metri presente nel vecchio filmato di esultanza.

La casualità cosmetica usa un generatore separato, senza modificare il comportamento della partita. Regole, comandi, statistiche, rotazioni e fisica della palla rimangono invariati.

## Verifiche

- 200 piani di reazione, sei famiglie e oltre 50 combinazioni di posti differenti, senza gesti contemporanei duplicati.
- Riproduzione effettiva delle reazioni in quattro punti consecutivi.
- 150 campioni delle nuove pose: gambe e bacino corrispondono alle animazioni originali.
- Tutti i dodici campi con linee di fondo libere; busti e mani degli addetti sopra il tavolo.
- Regressioni: sostituzioni, panchine/arbitro, profili dei campi e replay.

Risultati: `docs/bench71-tests.json`, `docs/bench71-regression.json`. Catture: `docs/bench71-*.png`.

Entrambi i PC devono usare la 0.71.0 per l'online (`SF071`).
