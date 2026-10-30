# Replay e frequenza dei monster block — 0.66.0

## Replay

La transizione dura 1,08 secondi, contro 0,9 della 0.65.0. L'ingrandimento finale inizia al 68% della transizione: la fase effettiva di zoom passa da 0,252 a 0,3456 secondi, quindi dura circa il 37% in più. Il logo continua a coprire il cambio camera prima e dopo il replay.

La registrazione continua per un secondo dopo l'assegnazione del punto, mantenendo anche rimbalzo e reazioni finali. In precedenza proseguiva per 0,16 secondi; con riproduzione a 0,8×, la differenza aggiunge **circa 1,05 secondi di video visibile**. Il segmento continua a partire dall'alzata o dalla preparazione della battuta: non viene allungato recuperando l'intero scambio precedente. Il massimo registrato sale a 6,35 secondi per conservare l'inizio del gesto e la nuova coda.

Il replay sospende la simulazione durante il playback e ripristina stato, pose, camera e RNG. Le verifiche compatibili aggiornate usano le costanti di durata del sistema, senza tempi `.9` rimasti nei test. I report della versione precedente non vengono sovrascritti.

## Muro

Senza valori giocatori, la soglia di chiusura per un monster sale da 0,65 a 0,74. I contatti intermedi diventano tocchi di muro giocabili. Non aumentano automaticamente i mani fuori e un press pieno con mani ben chiuse conserva il rimbalzo forte verso il terreno avversario.

Con i valori attivi, la curva di probabilità del monster è ridotta di circa il 20%: per esempio il valore 85 passa da 0,30 a 0,24 e il 99 da 0,55 a 0,44. I valori minimi sono arrotondati. Il confronto usa la configurazione originale estratta dal pacchetto della 0.65.0, non ricostruita a memoria.

Su **20.000 contatti identici** prima/dopo, il campione senza statistiche registra il **43,96% di monster in meno**. Tutta la differenza confluisce in tocchi giocabili; i mani fuori restano invariati nel medesimo campione. Questo è un confronto dei contatti, non una promessa di un numero fisso di muri per set: qualità delle mani, tempismo, attacchi, rotazioni e opportunità reali continuano a determinarlo.

## Prove

- [Bilanciamento, coda reale post-punto e ripristino](replay66-balance-tests.json): `tools/Test-ReplayBalance66.gd`.
- [Stato, pose, RNG, buffer e camera](replay66-state-tests.json): `tools/Test-Replay65.gd`, aggiornato alle durate correnti.
- [Ace salto/float e attacco perfetto realmente simulati](replay66-events.json): `tools/Test-ReplayEvents65.gd`.
- Fixture online: `tools/Test-OnlineReplay65.gd`, report distinti per host e ospite della 0.66.0.

La prova del press forte verifica entrambi i lati del campo, traiettoria finita, impatto nel campo avversario e assenza di una deviazione artificiale fuori dal campo. Il test della coda prosegue fisicamente il punto per raccogliere i nuovi fotogrammi: non aggiunge un fermo immagine di un secondo.
