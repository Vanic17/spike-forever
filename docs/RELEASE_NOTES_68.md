# Spike Forever 0.68.0 — patch locale non pubblicata

## Carriera e overall

Interfaccia ripulita dalle descrizioni tecniche, spiegazioni sulle stime e provenienza delle statistiche. Conservati i dati e i comandi necessari alla gestione.

Scelta iniziale fra incontri al meglio dei cinque o tre set, salvata nella carriera e applicata alle gare giocate e simulate. Il set decisivo è a 15 con due punti di vantaggio. Classifica e scontri diretti assegnano 3/0 punti per il 2–0 e 2/1 per il 2–1. Incontri a cinque: 3/0 per 3–0 e 3–1, 2/1 per 3–2. Le serie playoff mantengono il loro numero di incontri. Le carriere precedenti conservano incontri a cinque set.

`OVR = round((BAT*wBAT + RIC*wRIC + DIF*wDIF + PAL*wPAL + SCH*wSCH + MUR*wMUR)/100)`

| Ruolo | BAT | RIC | DIF | PAL | SCH | MUR |
|---|---:|---:|---:|---:|---:|---:|
| S | 15 | 0 | 10 | 50 | 5 | 20 |
| OPP | 20 | 0 | 15 | 5 | 40 | 20 |
| OH | 15 | 20 | 15 | 5 | 30 | 15 |
| MB | 15 | 5 | 5 | 5 | 35 | 35 |
| L | 0 | 45 | 40 | 15 | 0 | 0 |

Aggiornato il solo overall dei 169 giocatori base. Il medesimo calcolo si applica alle modifiche locali, alle carriere caricate e alle rose online; i fondamentali individuali restano preservati.

## Presentazione

- Tre telecamere nel ciclo offline: principale, TV laterale e bassa. Rimossa la precedente seconda camera rialzata. Online rimangono principale e bassa dal proprio lato.
- Replay anche per gli attacchi sovraccaricati che vincono effettivamente il punto; la probabilità di errore del sovraccarico resta invariata.
- Palla ricostruita dal riferimento V200W: diciotto pannelli curvi giallo/blu, marcature vettoriali, cuciture e microtexture filtrata. Il materiale segue la rotazione fisica e quella registrata nei replay. Raggio e fisica preservati.
- Panchine con applausi più rapidi e sfalsati, mani orientate, attenzione alla palla, gesti degli allenatori e reazioni di alzata/seduta. Allenatori con il modello dello staff e abiti lunghi. Tre addetti animati dietro i monitor, con sedute dedicate.
- Pose leggere delle panchine a 30 Hz, senza ulteriori AnimationTree da partita e con aggiornamento limitato alle ossa coinvolte.
- Sostituzione con transizione SuperLega: uscita verso zona cambi, riserva che si alza, attesa, cinque e ingresso. Camminata/corsa con ciclo dei passi basato sulla distanza. Transizione finale e ripresa automatica. Conferma/indietro saltano la sola presentazione offline.
- La sequenza applica un solo cambio regolamentare e non avanza simulazione, RNG, contatti o punteggio. Sincronizzata fra host e ospite tramite SF068.

## Prove

- `patch68-overall-tests.json`: cinque ruoli, arrotondamenti, 169 atleti, modifiche locali, carriere esistenti e rose online.
- `patch68-tests.json`: stagione intera al meglio dei tre, 396 punti nelle 132 gare regolari, salvataggio del formato, replay in sovraccarico e ripristino dello stato dopo sostituzione.
- `patch68-career-formats.json`: otto incontri giocati, casa/trasferta, tre/cinque set, vittorie nette/tiebreak, classifica e ritorno alla carriera.
- `patch68-online-host.json` e `patch68-online-guest.json`: richiesta dell'ospite, singolo cambio conteggiato, scena su entrambe le istanze e ripresa.
- `patch68-regression.json`: carriera, UI/controller, replay, terzi tocchi, finestra verde e impostazioni partita.
- `patch68-*.png`: palla in orientamenti diversi, panchina, tavolo e sostituzione.

Per questa patch non sono stati eseguiti push, creazione release o upload su GitHub, su richiesta dell'utente.
