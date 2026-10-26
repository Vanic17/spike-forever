# Spike Forever 0.57.0

## Analisi dei colpi a vuoto

Esaminate le azioni dei filmati `2026-10-26 10-18-17` da 0:24 e `2026-10-26 10-19-34` da 0:18. Nel primo, un secondo tocco si prepara vicino a un compagno ancora a terra; nel secondo, la CPU manca l'alzata dopo una difesa. Il video mostra il comportamento ma non contiene lo stato interno o il registro dei comandi: le cause sotto sono state riprodotte nel codice, senza attribuire al filmato parametri che non si possono leggere.

- Un compagno incaricato di liberare S aveva una destinazione libera, ma la raggiungeva attraversando il punto del palleggio. Il navigatore fermava S contro l'ingombro del compagno mentre l'animazione delle braccia continuava. Ora si controlla anche il percorso del giocatore che lascia spazio, conservando la rincorsa dell'attaccante selezionato.
- Il punto libero del bagher veniva verificato rispetto ai piedi, senza considerare la piattaforma delle braccia che sarebbe comparsa nella posa. La prenotazione prima del lancio considera entrambi.
- Il calcolo finale della ricezione non concedeva il margine di arrivo già previsto se il giocatore scelto si trovava oltre 5,26 m. Ora il margine resta disponibile anche per il palleggiatore o libero effettivamente selezionato. Si applica prima del lancio ed è limitato al margine esistente; una palla in volo non viene rallentata o sospesa.
- La ricezione usava l'altezza generica della banca anche quando la variante aveva mani più basse. L'intercetto ora segue le mani della performance selezionata, sulla stessa traiettoria. Il test delle sole varianti riusciva anche prima: questo corregge la coerenza del contatto e non viene presentato come unica causa dei colpi mancati.

## Reattività e recuperi

La decisione di passare dal palleggio al bagher usa accelerazione, frenata, orientamento e percorso effettivi. Non si abbandona un palleggio ancora raggiungibile per una posa di emergenza. Se il secondo tocco normale non è più possibile, si valutano le performance basse già presenti negli asset: salvataggio compatto, frontale e laterale a una mano. Prima si prova il giocatore incaricato; il libero può intervenire se disponibile, escludendo chi ha appena ricevuto.

I tentativi si impegnano soltanto dopo aver verificato il punto delle mani, il tempo di rotazione e il percorso della sorgente contro gli ingombri dei compagni. Avvicinamento, contatto e rialzata condividono lo stesso orologio. Il recupero non interrompe un tuffo precedente ancora in corso e non può attraversare la rete. La correzione del movimento non accumula spostamento per poi teletrasportare il corpo quando un ostacolo si libera.

Sulle palle svirgolate non si rinuncia soltanto perché il compagno più vicino è ancora a terra: vengono confrontati gli altri recuperatori possibili prima di impegnare un gesto. Rimangono palloni irraggiungibili, errori di difesa e la necessità del comando umano. Nessun contatto extra, aggancio magnetico, allargamento delle tolleranze o aumento generalizzato della velocità dei giocatori.

Il recupero non deve creare un nuovo ostacolo per l'attaccante: le alzate d'emergenza considerano anche lo spostamento successivo del palleggiatore a terra. Se necessario la palla viene staccata da rete prima del lancio, conservando il giocatore e la zona richiesti. Il centrale fuori sistema ha un corridoio protetto; il percorso consente di allontanarsi da una sovrapposizione iniziale, mantenendo il divieto di attraversare il compagno.

## Preparazione del centrale, primo tempo e 7

Il centrale iniziava ad aggirare il palleggiatore soltanto dopo la ricezione; in una rotazione il successivo ordine di lasciare spazio lo tratteneva dal lato sbagliato. La normale sterzata per evitare i compagni poteva inoltre annullare un percorso già verificato e la frenata trattava un angolo intermedio come il punto finale della rincorsa.

Ora il centrale prepara un percorso fin dalla palla in arrivo. Passa dietro il palleggiatore considerando gli ingombri reali e l'intero tratto che S deve ancora percorrere, conserva lo spazio di preparazione a 2,35 m e supera gli angoli senza una sosta artificiale. L'ordine di attendere viene rimosso soltanto se esiste un percorso libero: un tentativo fallito di aggiramento mantiene la priorità del palleggiatore.

Restano **X/A per il primo tempo vicino**, **Quadrato/X per la 7**, gli stessi riferimenti di salto e contatto e la costruzione alta di sicurezza quando il primo tempo non è raggiungibile. Nessun incremento della velocità massima.

Nel confronto con la 0.56, il test con palla in arrivo completa passa da 90 a 108 preparazioni già in salto al tocco di S su 108 casi (finta, primo tempo, 7; tutte le rotazioni, entrambi i lati, 50/60/120 Hz). La suite precedente con arrivi più brevi conserva tutti i 72 attacchi conclusi e passa da 60 a 69 preparazioni in salto; nei restanti casi rimane l'alzata di sicurezza.

## Verifiche

- 168 costruzioni reali ricezione → secondo tocco, tutte le rotazioni e i due lati, 60/120 Hz; verifica dell'ingombro futuro del bagher.
- Caso di attraversamento del punto di S: 4 verifiche con AnimationTree e fallback PSA, 60/120 Hz.
- 100 contatti su 25 varianti di ricezione; velocità e spin della traiettoria conservati.
- Recuperi a una mano e compagno alternativo: controlli su entrambi i lati, 60/120 Hz, compresi nessun input e palla irraggiungibile.
- 8 percorsi lunghi del palleggiatore/libero; 4 salvataggi a una mano seguiti fino al terzo tocco reale; 16 casi di regressione dell'attacco del centrale, con AnimationTree e fallback PSA.
- 108 preparazioni del centrale con palla in arrivo, confronto con la versione pubblicata e controllo di distanze, continuità e tre contatti reali; suite di 24 primo tempo/7 e 72 costruzioni pipe/dietro conservate.
- Traffico con compagni in piedi e a terra: il termine del contatto viene ricavato dal volo originale all'altezza delle mani; controllati distanze, continuità e assenza di sospensione della palla.
- Scambi completi, stesso seme e 10 punti: 5 mancate alzate su 27 preparazioni nella versione pubblicata, 0 su 39 nella versione finale. Gli scambi successivi alle correzioni possono divergere: è un controllo del campione, non una garanzia di recuperare ogni pallone.
- Partita online tra due processi con host e ospite: 16 contatti, pausa e ritorno al menu verificati. Installazione del pacchetto e conservazione dei dati locali controllate separatamente.

Rapporti e strumenti riproducibili sono inclusi nel pacchetto e nel repository. Nel benchmark CPU della costruzione di gioco, il costo medio con pose campionate passa da 2,506 a 2,544 ms e il 95° percentile da 6,890 a 6,959 ms. Sono misure locali della CPU, separate dagli FPS del renderer. Le [anteprime](rescue57-preview.mp4) sono dimostrazioni isolate del gesto e della rialzata, non replay dei video dell'utente.

Regole, rotazioni, PlayStyle, comandi e formule di potenza restano invariati. Parser PSA, AnimationTree e fallback restano disponibili. Entrambi i giocatori online devono usare **0.57.0 / SF057**. L'aggiornamento conserva roster, comandi e preferenze locali.
