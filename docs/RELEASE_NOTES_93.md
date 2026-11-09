# Spike Forever 0.93.0

- Rifatte le tre seconde su Triangolo/Y: numero 3 con la sinistra, numero 2 e 7 con la destra. I gesti sono identici per destri e mancini.
- Palleggiatore parallelo alla rete, rivolto a sinistra nella propria telecamera da fondo campo; nessuna rotazione verso il campo avversario durante il gesto.
- Preparazione a due mani, ritiro del braccio libero, contatto con il palmo e uscita delle dita/polso distinti. La numero 2 prepara il contatto dietro la testa quando il tempo disponibile lo permette.
- Contatto alto sulla traiettoria esistente per il colpo preparato, adattamento raccolto per il comando tardivo. Nessun riavvio della palla o contatto a tempo zero.
- Numero 3: spinta discendente e topspin; se l'altezza non consente il passaggio sopra il nastro, la palla incontra fisicamente la rete invece di diventare un pallonetto verso l'alto.
- Numero 2 e 7: uscite rispettivamente dietro e davanti al palleggiatore, traiettorie tese con controllo numerico del passaggio sopra la rete usando spin e resistenza reali.
- Triangolo/Y disponibile esclusivamente per il palleggiatore in prima linea. In seconda linea la richiesta viene rifiutata prima di cambiare posa, tempo o traiettoria, anche sull'autorità online e in Diventa un mito. Le seconde su Cerchio/B mantengono il comportamento precedente.
- IK rilasciata subito dopo il tocco per lasciare visibile il seguito del polso; libreria AnimationTree rigenerata, fallback PSA conservato.

Verifiche: 144 casi a 60/120 Hz, due lati, sei rotazioni, tre direzioni e input anticipato/tardivo: contatti reali in prima linea e rifiuto senza effetti in seconda linea. Controllati mano, orientamento e traiettoria. Eseguiti anche nel fallback PSA, oltre alle regressioni e al controllo online.

Riferimenti per la ricostruzione dei gesti: [classica](https://www.youtube.com/shorts/3dCAFN8rQrg), [dietro la testa](https://www.youtube.com/shorts/K946bfJAJPI), [tipologie 2, 3 e 7](https://www.youtube.com/shorts/OYnemJcvpD0). Sono animazioni ricostruite, non motion capture estratto dai video.

Online: entrambi i client devono usare la 0.93.0. Salvataggi e modifiche personali al database sono esclusi dal pacchetto.
