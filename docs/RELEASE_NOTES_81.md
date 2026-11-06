# Spike Forever 0.81.0

## Finta di attacco di seconda trasformata in alzata

Premi Cerchio e subito dopo X/Croce su PlayStation, oppure B e subito dopo A su Xbox. Da tastiera: E seguito da Spazio. Il secondo comando deve arrivare entro 280 ms dal primo, prima del contatto e con il tempo necessario per completare uno stacco credibile. La direzione dell'alzata continua a seguire la mira attiva.

Il giocatore prepara il salto e carica il braccio come per schiacciare; poi riunisce le due mani sopra la testa e alza durante lo stesso salto. È una sola prestazione, con un solo contatto. Si applica alle opportunità di seconda già consentite: devono esserci altezza, portata e posizione regolamentare, senza libero o attacco irregolare dalla seconda linea. Cerchio/B da solo mantiene la spinta o la schiacciata di seconda precedente. Se la conversione non è praticabile, non viene inserita una posa già in volo: rimane il comando di seconda originario.

L'azione è disponibile su comando umano in esibizione, Diventa un mito e online. Non viene aggiunta alle scelte della CPU. La trasformazione ricalcola l'istante in cui le mani possono incontrare la traiettoria esistente, senza riscrivere posizione, velocità o spin della palla. L'alzata risultante usa il sistema condiviso di destinazioni, statistiche e preparazione degli attaccanti, e conta come secondo tocco.

L'animazione è un adattamento autoriale guidato dai tre riferimenti `uwN5xoXdBj0`, `GhF_qlDi5kc` e `zzfkasgZmmQ`, non motion capture calibrata. Il caricamento da attacco sfuma nelle rotazioni locali della parte superiore del palleggio; il contatto delle due mani è dedicato. Stacco, gambe, spostamento reale e atterraggio rimangono quelli dell'unico salto sorgente. La prestazione è precalcolata nella libreria nativa e riprodotta tramite AnimationTree, con fallback PSA e mirroring mancino conservati.

## Diventa un mito: levetta sinistra e battuta

- La levetta sinistra gestisce sia movimento sia mira, anche per alzate, attacchi e pallonetti. La levetta destra non modifica più la mira. Le direzioni rispettano la visuale scelta. Da tastiera restano WASD per spostarsi e frecce per mirare.
- Prima della carica della battuta, LS permette di arretrare e spostarsi lateralmente. Durante la carica, LS mira e il battitore frena con la stessa inerzia dell'esibizione.
- Movimento di servizio, limiti della zona, arretramento di sicurezza, lancio e colpo usano direttamente il percorso dell'esibizione. La rotta automatica di rientro fra i punti lascia il controllo quando il giocatore muove LS.
- Aggiornate le istruzioni PlayStation/Xbox e aggiunto il comando della finta nelle indicazioni di Diventa un mito.

## Verifiche e aggiornamento

Contatti reali della finta verificati a 30 e 120 Hz: quattro direzioni, entrambe le mani, ingresso dalla spinta e dalla schiacciata di seconda, esibizione e Diventa un mito. Verificati un solo contatto, due tocchi complessivi, assenza di riavvolgimento del salto e traiettoria della palla invariata al comando di conversione. Controllati rifiuti per finestra scaduta, comando tardivo, libero, seconda linea vicino a rete, terzo tocco, mancato Cerchio, palla fuori portata e palla non in volo.

Pose native verificate a 30/60/120/144 Hz: lunghezze anatomiche, contatto a due mani, continuità e gambe/stacco/atterraggio invariati. Verificata la mira LS in 72 combinazioni di visuale, fase e direzione, più camminata, confine di fondo e carica in battuta. Passate le regressioni di input, palleggio ordinario/veloce, colpi di seconda precedenti, attacchi e difese della 0.80.

Rapporti: `setter81-gameplay.json`, `setter81-fallback.json`, `setter81-poses.json`, `legend81-stick.json`, `legend81-service.json`. Anteprima: `setter81-preview.mp4`.

Protocollo online SF081: i due giocatori devono usare la stessa generazione. Aggiornamento selettivo mantenuto. Campionati, carriere e database personale in `user://` non sono sostituiti dal pacchetto.
