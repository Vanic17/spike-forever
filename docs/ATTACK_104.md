# Attacco e rincorsa — 0.98.0

## Osservazione

Riferimenti: tre registrazioni fornite dall'utente del 10 novembre 2026, ore 01:49:19, 01:50:22 e soprattutto 01:54:24. Visione per sequenze di fotogrammi, incluso avvicinamento, stacco, contatto e caduta. I filmati contengono pause e riproduzioni successive: non si ricavano da essi velocità metriche o motion capture 3D. Gli interventi riguardano il gioco originale Spike Forever.

## Cause concrete

- Il contatto dei pin rimaneva a 1,05 m dalla rete anche su ricezione ottima. Per arrivare corto superando il nastro da circa 3 m di quota, il solver doveva allungare l'arco.
- `short_attack103` aggiungeva circa 24–34 rad/s di topspin per accelerare il tratto corto. L'uscita visiva dipendeva troppo dalla curvatura.
- `court_shape` consumava quasi tutta l'apertura prima del tocco del palleggiatore.
- Il calcolo della rincorsa dei pin includeva la frenata completa e un'attesa generica di 0,38 s, anche sul corridoio libero. Ne risultava un avvicinamento lento.
- Il caricamento durante la corsa riguardava soltanto due varianti. Il cambio d'incarico da approach a contact e la scelta della camminata nascondevano parte della preparazione.

## Implementazione

`attack_delivery104` calcola velocità iniziale e durata usando `ball_flight` invariato. Gli attacchi forti hanno spin orizzontale di 7–12 rad/s, obiettivo orizzontale progressivo 19–27 m/s e una durata minima di 0,18 s. Il vincolo fisico sopra nastro, raggio della palla e margine di 18 mm prevale sulla richiesta di velocità. Se necessario il colpo resta più arcuato. Nessun cambio di gravità, pavimento, direzioni di mira o correzione della posizione della palla.

I pin in prima linea su passaggio preciso e stretto possono colpire a 0,55 m dalla rete, con interpolazione verso la distanza precedente sulle ricezioni meno buone/staccate. Seconda linea e primo tempo mantengono le proprie corsie.

L'apertura della banda viene conservata fino al rilascio dell'alzata alta. Il corridoio libero usa il tempo di corsa e salto con 0,10 s di margine; quello occupato mantiene il precedente margine di manovra. Velocità massima, collisioni e accelerazioni non aumentano. Le combinazioni veloci mantengono l'anticipo precedente.

Tutte le sei varianti di pin già disponibili ricevono il caricamento progressivo dell'alto corpo, con interpolazione continua fra pose memorizzate e dissolvenza al salto. Gambe, contatto, IK e AnimationTree esistenti rimangono responsabili dei propri canali. Nessuna nuova scrittura concorrente delle ossa. Funziona anche in fallback PSA e per mancini. Il flag visivo `pin_run104` viaggia negli snapshot online; protocollo SF098-ATTACK104.

## Verifica

- `Test-Attack104`: traiettorie specchiate, tre posizioni laterali, tre bersagli laterali, tre profondità e quattro distanze dalla rete; atterraggio fisico, superamento del nastro, riduzione dello spin, esclusione pallonetti/servizi/palle libere, corsa e snapshot.
- `Audit-Attack104`: 24 costruzioni reali ricezione–alzata–attacco nelle sei rotazioni, con esito successivo della difesa CPU. Eseguito su versione precedente e nuova, oltre al fallback PSA. Non sono fixture che teletrasportano il colpitore al contatto.
- Confronto dei casi riproducibili in `attack104-comparison.json`; i conteggi di punti di questo campione non rappresentano una previsione statistica di tutte le partite.
- Test primo tempo/7 e alzata a una mano: 229 controlli; rete/pallonetto: 218 controlli; due peer ENet locali compatibili.
- Database, controlli, timing, integratore della palla, risposta del muro e difesa CPU confrontati byte per byte con 0.97.0. Verificati 216 file personali preesistenti senza cambiamenti.
- Cattura di una costruzione effettiva in `attack104-preview.mp4`.

Limite dei test storici: `Test-BlockFlight59` fallisce già sulla versione pubblicata 0.97.0 con la stessa asserzione di mancato contatto del fixture allineato. Non viene conteggiato come test superato, né corretto alterando il muro per soddisfare quella vecchia geometria. La risposta del muro resta byte-identica e le nuove traiettorie vengono controllate con l'integratore attuale.

La ricerca della durata legale avviene una volta al colpo, non ogni frame. Il massimo misurato del solver nel test isolato è registrato nel report; la cattura offline non è un benchmark dei FPS di gioco.
