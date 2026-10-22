# Revisione 03 — ricezione, movimento e ritmo

Riferimenti osservati: cattura utente delle 19:35:23 (44 secondi) e sequenze del video della partita reale (zona 60–76 secondi). Grafica, arena, materiali, camera e sistema audio non modificati.

## Quadrato

Il comando arrivava correttamente: il bug era nella valutazione. Il cursore oscillava e poteva trovarsi sul verde con molto tempo ancora disponibile; una penalità temporale aggiuntiva, invisibile nella barra, portava comunque la qualità a zero. Ora la posizione visibile del cursore determina la qualità. La conferma viene conservata e il contatto avviene all'arrivo fisico della palla.

La simulazione divide il passo esattamente all'evento di contatto, invece di controllare una palla già avanzata di un frame. Eliminata l'attesa tardiva che lasciava passare la palla oltre le mani. Mancanza del comando, timing insufficiente e palla fuori portata hanno messaggi distinti.

## Squadre e animazioni

- Preparazione: penetrazione del palleggiatore, apertura delle ali, opzione di seconda linea.
- Alzata: assegnazione dell'attaccante tra i giocatori di prima linea, oppure seconda linea per pipe.
- Attacco: copertura corta e profonda; difesa su linea e diagonale dietro il muro.
- Spostamento: accelerazione, frenata, separazione; orientamento lungo la corsa e ritorno verso la palla.
- Animazioni originali distinte per corsa, arretramento, passi laterali e attesa bassa. Rimossi i passi laterali con braccia già alzate del muro dalla locomozione ordinaria.
- Nessun cambio artificiale fra due clip di corsa ogni 1,8 metri. Le transizioni conservano la fase del ciclo.
- Preparazione del gesto più vicina al contatto: 0,23 secondi per ricezione/alzata, 0,42 per attacco. Follow-through più breve prima del ritorno alla locomozione.

## Ritmo della palla

Tempi nominali di volo, non velocità costanti: la traiettoria rimane balistica.

| Azione | Prima | Ora |
| --- | --- | --- |
| Float, piena potenza | 1,65 s | 1,12 s |
| Power serve, piena potenza | 1,30 s | 0,90 s |
| Ricezione perfetta verso palleggiatore | 1,50 s | 1,05 s |
| Alzata normale perfetta | 1,45 s | 1,02 s |
| Alzata veloce | 0,95 s | 0,62 s |
| Schiacciata, massima potenza | 0,80 s | 0,42 s |

Le alzate imprecise restano più alte/lente. I giocatori hanno un limite di corsa di 7,2 m/s e accelerazione/frenata: nessun teletrasporto per rendere raggiungibile una palla.

## Verifica

`Verifica.cmd`: regressione dell'evento Quadrato con bot disattivato, conferma anticipata sul verde e vicino al contatto, a 30/60/120 Hz; in tutti e sei i casi si passa fisicamente dalla ricezione all'alzata. Verificato anche rifiuto di contatto fuori portata.

Simulazione con asset: 16 punti, 284 contatti, massimo scarto mani-palla 0,159 m. Fallback: 16 punti, 121 contatti, massimo scarto 0,166 m. Tutti i dodici atleti partecipano agli spostamenti. Log e report JSON in `docs`.

Il test degli eventi non equivale a una prova manuale con controller fisico. La naturalezza delle transizioni resta una valutazione visiva: questa revisione migliora compiti e locomozione, non dimostra equivalenza con una partita televisiva. Resta l'avviso Godot ObjectDB alla chiusura della cattura, già presente nella versione precedente.

Sorgenti precedenti conservati in `docs/baseline-v02`.
