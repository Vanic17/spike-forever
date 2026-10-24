# Spike Forever 0.46.0

## Campo e arbitro

- Pali esterni alle linee laterali con protezioni verdi e marchio CREDEM originale, bande laterali e antenne.
- Seggiolone rosso dell'arbitro sul lato sinistro del campo nella visuale da fondo.
- Modello originale dell'arbitro, materiali corretti e sei gesti nativi: attesa, autorizzazione della battuta, assegnazione del punto nelle due direzioni e fine set. Le animazioni si raccordano senza riavviarsi a ogni frame.
- L'attrezzatura aggiunta è visiva: non aggiunge ostacoli invisibili alla palla o ai giocatori.

## Preparazione all'attacco

- Il centrale legge la traiettoria già durante la ricezione e prepara il primo tempo anche quando viene scelta un'altra uscita. La preparazione non dipende più da una soglia arbitraria di qualità né dalla scelta finale dell'alzata.
- Caricamento della parte superiore del corpo sovrapposto alla locomozione: piedi e movimento reale restano separati. Il salto di finta parte soltanto se il centrale ha raggiunto una posizione credibile; sulle palle troppo staccate da rete rimane in copertura.
- Corretta la destinazione della finta, che poteva mandare il centrale verso i ricevitori. La scelta del centrale come attaccante trasferisce la gestione al contatto reale, senza mantenerlo bloccato nella finta.
- La deviazione usata dalla finta non sovrascrive il percorso del centrale quando deve realmente attaccare: il contatto mantiene la propria gestione del movimento.
- Raccordo della rincorsa sulle palle alte: eliminato l'arretramento supplementare dopo l'apertura in ricezione; animazioni complete originali e riproduzione meno rallentata nella preparazione. Velocità massima dei giocatori invariata.

## Scelta delle divise

- Le barre di colore sono sostituite da anteprime fronte/retro delle vere maglie e dei pantaloncini, aggiornate scegliendo squadra e divisa.
- 32 immagini generate dal modello e dai materiali effettivamente usati in partita; cache delle immagini per evitare ulteriori personaggi 3D animati nei menu.
- Navigazione controller e salvataggi personali conservati.

## Verifiche

Le verifiche e le immagini della patch sono incluse nella cartella `docs`:

- 96 costruzioni complete ricezione/alzata/attacco, tutte con tre contatti reali; rincorsa media delle bande di prima linea sulle palle alte: 3,41 m.
- 96 scenari di preparazione: 72 minacce del centrale non selezionato e 24 preparazioni dell'attaccante centrale selezionato. Il caricamento a terra è distinto dal salto effettivo, che viene evitato se la rincorsa è ostacolata.
- Attrezzatura, segnali arbitrali, anteprime delle divise e navigazione del menu verificati.
- Rendering reale a 1280×720, RTX 5080, limite 60 FPS: media 60,00 FPS su 600 fotogrammi, percentile 95 a 19,06 ms, nessun fotogramma oltre 25 ms. È una misura locale su costruzioni ripetute, non una garanzia di prestazioni su ogni configurazione o in ogni scambio.

Le regole, le rotazioni, i controlli, i valori dei giocatori e la fisica della palla non sono modificati da questa patch. Il parser PSA e il fallback originale restano disponibili.
