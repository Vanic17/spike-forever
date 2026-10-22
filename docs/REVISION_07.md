# Revisione 07 — fluidità e movimenti individuali

Questa revisione riguarda esclusivamente movimento e presentazione delle animazioni. Il confronto con la revisione 06 conserva identici regole, controlli, formule del timing, fisica del pallone e decisioni delle giocate. `Check-MovementScope.ps1` verifica 58 checksum, inclusi i metodi di servizio, alzata, attacco, muro, input e punteggio. Nel file principale cambiano soltanto `move_players` e `tactical_target`.

## Tempi individuali e lavoro senza palla

Ogni atleta ha un profilo deterministico di percezione, partenza, accelerazione, frenata e orientamento. Il palleggiatore anticipa la preparazione, il libero legge prima la copertura e le ali si aprono con tempi propri. I tempi dipendono dal compito: lettura, rincorsa, chiusura a muro, copertura, recupero e apertura di spazio al compagno.

La risposta al comando e l'assistenza del giocatore che deve toccare il pallone restano immediate. Il ritardo riguarda gli altri compiti. Nel test sullo stesso segnale i tempi iniziali osservati dei sei giocatori sono circa 183, 183, 167, 250, 75 e 75 ms: non viene imposto che ogni atleta si muova sempre in un istante diverso, ma viene eliminata la partenza collettiva al cambio di fase.

I bersagli vengono percepiti e raggiunti gradualmente. La soglia dei piccoli aggiustamenti è individuale. Chi si trova nel corridoio di rincorsa o di recupero del compagno si sposta lateralmente per lasciarlo passare; non viene spostato istantaneamente. Sono preservate le distanze dei corpi e il limite della metà campo, anche durante la scivolata di aggiramento.

La progressione di apertura/rincorsa usa il tempo di preparazione individuale, con ritmo diverso fra primo tempo e palla alta. Le correzioni d'emergenza rispondono alla qualità e alle traiettorie già esistenti. Non vengono introdotti nuovi errori casuali nella ricezione o nel timing per simulare imperfezione.

## Continuità delle animazioni

- L'animazione uscente continua ad avanzare durante il blend, invece di fondere il nuovo gesto con una fotografia congelata della posa precedente.
- Durata del blend differenziata per atleta e contesto: preparazione rapida più breve, apertura e recupero più graduali.
- A bassa velocità, peso continuo fra attesa e passo; la fermata non passa bruscamente da una corsa rallentata a un atleta immobile.
- Durante la preparazione di bagher e palleggio, le gambe possono continuare i passi sotto il busto già pronto. Questa sovrapposizione sfuma prima del contatto.
- La rincorsa mantiene i passi fino alla preparazione dello stacco; salto e atterraggio conservano la loro clip originale.
- Le pose di attesa hanno fasi e cadenze individuali; testa e corpo si orientano con risposte graduali differenti.
- Movimento a 120 Hz, aggiornamento della posa dello scheletro una volta per fotogramma visualizzato. Il contatto fisico continua a campionare immediatamente la posa esatta richiesta.

Sono usate le stesse 19 clip e lo stesso sistema di lettura/blend ActorX. Non sono state cambiate grafica, audio o meccaniche della palla, né introdotte nuove animazioni di tuffo.

## Verifica

- `Check-MovementScope.ps1`: **58 controlli superati**, codice protetto invariato. Evidenza in `motion-scope-validation.json` e snapshot in `motion-scope-before.json`.
- `Test-Movement.gd`: reazioni di supporto scaglionate, assistenza al contatto immediata, animazione uscente in movimento, trasformazioni dello scheletro finite, errore del punto di contatto sotto 5 mm nel test dedicato. Risultati in `movement-quality-report.json`.
- `Verifica.cmd` include il nuovo test del movimento oltre alle regressioni precedenti di controller, traiettorie, alzate, contatti, rimbalzi, salto unico e rotazioni.
- Simulazione con asset: 16 punti, 135 contatti, distanza minima fra corpi e muratori circa 0,795 m, zero salti duplicati.
- Fallback senza asset: 16 punti, 39 contatti, minimo fra corpi 0,780 m e fra muratori 0,791 m.

Questi risultati controllano correttezza e regressioni. L'effetto visivo va valutato nel filmato; non dimostrano equivalenza con i movimenti di una partita televisiva. I recuperi usano ancora le animazioni disponibili e non coprono ogni possibile situazione acrobatica.

Backup: `baseline-v06`. Anteprima: `Spike Forever - fluidita e movimenti individuali.mp4`, 30 secondi, 1280×720 e 1800 fotogrammi. La frequenza del filmato è quella della registrazione, non un benchmark delle prestazioni. Rimane il precedente avviso Godot ObjectDB alla chiusura.
