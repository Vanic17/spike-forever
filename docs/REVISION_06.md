# Revisione 06 — coordinazione, salto unico e palla con spin

Confronto visivo: filmato della revisione 05 e sequenze della partita reale intorno a 59–63 e 69–73 secondi. Backup sorgenti precedenti: `baseline-v05`.

## Correzione del doppio salto

Il muro veniva riprogrammato durante la successiva ricezione usando il nuovo `flight_left`. Inoltre, la CPU poteva riavviare il gesto al momento della schiacciata dopo averlo già preparato. Non era una seconda decisione tattica valida.

Ora ogni attacco ha un identificativo. Ogni muratore può iniziare un solo salto per quell'identificativo; il comando manuale viene accettato una sola volta per alzata. La clip parte una volta, avanza normalmente e mantiene l'atterraggio. Il passaggio alla ricezione non può riscriverne il tempo. Durante il salto il giocatore conserva il proprio appoggio invece di seguire il nuovo bersaglio della difesa.

## Alzata e destinatario

La CPU prima sceglieva direzione e variante veloce al momento del tocco, dopo parte dei controlli del contatto. Ora il piano viene preparato durante la ricezione verso il palleggiatore. Il giocatore umano può modificarlo durante la preparazione e lo blocca confermando la barra.

Il piano contiene direzione, variante e identità dell'attaccante. Resta invariato al rilascio: banda allo schiacciatore di prima linea, centro al centrale, destra all'opposto, pipe allo schiacciatore di seconda linea. Se una soluzione è indisponibile per un'alzata d'emergenza viene scelta un'altra opzione legale prima del lancio, visualizzata nella barra con il numero del destinatario.

L'attaccante inizia l'avvicinamento durante l'alzata al palleggiatore. Il tempo della successiva alzata tiene conto della distanza residua della rincorsa. Un tentativo veloce troppo lungo viene rallentato prima che la palla parta, mantenendo il destinatario.

La decisione CPU considera qualità del primo tocco, distanza del palleggiatore dalla rete, disponibilità e distanza degli attaccanti, presenza dei muratori e ripetizione della giocata precedente. Lo stato del generatore casuale è riproducibile e serve a variare opzioni confrontabili, non a sostituire questi vincoli.

## Movimento senza palla

- Durante la difesa del colpo i compagni mantengono equilibrio e aprono spazio attorno al ricevitore.
- Durante il primo tocco verso il palleggiatore, le ali si allargano, il centrale prepara il tempo breve, l'opposto prepara il lato destro o la D, lo schiacciatore dietro prepara la pipe.
- Durante l'attacco, copertura corta e profonda dipendono dal lato della schiacciata. Palleggiatore e libero rientrano in zone distinte di copertura.
- In difesa, i bersagli cambiano con passaggio, posizione della palla, lato del muro e profondità della traiettoria.
- I muratori in lettura usano una nuova clip originale di attesa con braccia pronte; non rimangono eretti con le braccia abbandonate fino al salto.

Nessun rumore casuale viene aggiunto ai bersagli per fingere attività. Rimangono frenata, percorso di aggiramento, soglia di stabilità e separazione dei corpi. Un atleta può restare fermo quando ha già una posizione corretta.

## Animazioni e transizioni

Il progetto continua a leggere le clip ActorX a runtime, con fusione sulle articolazioni locali, sincronizzazione del contatto, appoggi dei piedi e fasi di recupero. Sono attive 19 clip. Non è stato introdotto un `AnimationTree`: la stessa funzione di coordinamento viene svolta dalla gestione delle clip e degli eventi già presente, corretta per impedire riavvii. La migrazione ad AnimationTree non viene dichiarata completata.

## Palla

`ball_flight.gd` contiene un unico integratore deterministico con gravità, resistenza dell'aria e accelerazione laterale/verticale dovuta allo spin. Il lancio risolve la velocità iniziale usando lo stesso modello della simulazione e dell'intercetto. La rotazione visibile segue lo spin.

Il contatto con la rete cambia velocità e spin e lascia cadere la palla; il punto non viene assegnato prima dell'impatto al suolo. I rimbalzi sul terreno dissipano energia e passano al rotolamento.

Le deviazioni a muro dipendono dalla velocità entrante e dalla normale delle mani, modificabile con lo stick. Il rimbalzo trasferisce spin, non sposta il pallone sulle mani e non usa più una velocità verticale fissa. Le ricezioni imprecise continuano a produrre dispersione e palle più difficili da alzare.

Limiti: mani rappresentate da volumi/segmenti di contatto, rete con risposta semplificata, coefficienti tarati per il gioco. Non sono simulati tessuto della rete, deformazione della palla o ogni possibile salvataggio dopo un nastro. Le animazioni di tuffo non sono state aggiunte.

## Evidenza

- 48 giocate integrate: 2 squadre × 6 rotazioni × 4 direzioni; destinatario e zona devono corrispondere al piano.
- Regressione del doppio salto: una richiesta ripetuta viene rifiutata; 90 passi della ricezione successiva non possono riavvolgere l'animazione del muro.
- Intercetto con spin verificato a 30/60/120 Hz, errore sotto 1 cm.
- Contatti eseguiti contro le mani animate: deviazione, cambio di spin e assenza di spostamento artificiale della palla.
- Impatto con la rete eseguito nella simulazione, senza assegnazione anticipata del punto.
- 108 scenari di distanza a muro, più le regressioni precedenti su controller, appoggi e rimbalzi.
- Simulazione completa con asset: 16 punti, 163 contatti, 53 attacchi pianificati, 96 eventi di salto a muro, **zero salti duplicati per attacco**. Minimo fra corpi 0,787 m, fra muratori 0,804 m.
- Ogni atleta accumula 101–174 m in preparazione/copertura durante gli scambi, escludendo i tratti da attore del contatto, muro, servizio e pausa tra punti. Questo misura partecipazione, non dimostra da solo la naturalezza.
- Fallback senza asset: 16 punti e 52 contatti, zero salti duplicati. Log e JSON aggiornati in `docs`.

Le verifiche di correttezza non equivalgono a una prova manuale col controller né dimostrano equivalenza visiva con una partita televisiva. Resta il precedente avviso ObjectDB alla chiusura della registrazione.
