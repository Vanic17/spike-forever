# Autorità del database e riconnessione — 0.102.0

## Cause individuate

La precedente stanza validava gli ID e i ruoli, ma accettava anche i valori e le identità completi inviati dall'ospite. Il match era autorevole nella simulazione, ma il suo database combinava di fatto le scelte locali dei due giocatori. Non corrispondeva alla richiesta di usare soltanto il database dell'host.

Il client calcolava autonomamente la durata della barra usando le identità ricevute e `destination`, che non era inclusa negli snapshot. La zona effettiva influisce sul trattamento del primo tempo e sul limite legato al volo dell'alzata. Una zona locale precedente poteva quindi dare tempi diversi. Senza una registrazione del caso specifico non è possibile attribuire con certezza il sintomo segnalato a una sola delle due cause.

La curva già presente rende più rapida la carica dei giocatori meno abili: ad esempio coefficiente 2.0 per Schiacciata 40 contro circa 1.144 a 91, prima della freccia e del trattamento del centrale. Questa scelta di bilanciamento non viene cambiata dalla patch.

## Nuovo flusso

All'apertura della stanza l'host congela una copia del proprio catalogo completo e delle proprie formazioni iniziali salvate. L'invito trasferisce il catalogo sull'ENet affidabile; il guest verifica schema, struttura e SHA256 del JSON ordinato. Entrambi mostrano l'impronta nella lobby. L'inizio partita richiede la conferma della stessa impronta da parte dell'ospite.

`online_catalog108.gd` è una risorsa temporanea, separata da `League` e dagli override locali. Squadre e formazione online usano il catalogo ricevuto. Il client invia gli ID desiderati, ma l'host ricostruisce ogni identità e la panchina dai propri dati prima della validazione: inviare un nome o un valore differente non ha effetto. Le scelte della formazione online vengono conservate separatamente dalla formazione locale di esibizione. La finestra di scelta ripristina lo stato locale sia alla conferma sia all'annullamento.

Il protocollo `SF0102-DB108` include la zona effettiva e le durate autorevoli di servizio e attacco. Le durate sono inviate come float senza la quantizzazione al millisecondo usata per alcuni altri campi, per preservare le finestre strette. La previsione locale della barra usa queste durate; il client non può modificarle alterando il proprio database. Frecce, statistiche effettive e sostituzioni continuano ad essere gestite dall'host. Eventi `online_charge108` annotano durata, zona, stato dei valori e impronta del catalogo per le diagnosi.

## Connessioni salvate

`user://online_connections108.cfg` conserva un identificativo casuale host a 24 bit e fino a otto inviti riusciti, senza modificare file del database o delle carriere. Il codice completo resta ricostruito da IPv4, porta e identificativo; quindi riaprire il PC/gioco non cambia il codice se l'indirizzo resta uguale. Il menu offre storico, riconnessione e precompilazione dell'ultimo invito. Le connessioni fallite non entrano nello storico. Il file viene scritto tramite un temporaneo e rinomina.

Un codice autonomo non può trovare da solo un nuovo indirizzo Internet: se l'IP cambia serve un nuovo invito. Non è stato introdotto un server centrale, un relay o un elenco pubblico di lobby, e rimangono i precedenti requisiti di raggiungibilità UDP/UPnP/VPN.

## Verifiche

- Due processi ENet con database locali intenzionalmente divergenti (valori 40/91, nomi, mano e altezza differenti), stessa squadra selezionata da entrambi e valori falsificati nel messaggio del guest. L'host usa solo il proprio catalogo, le impronte coincidono e il database del guest resta invariato.
- Sei casi con tutte le zone, due primi tempi e valori disattivati; la durata della barra del client coincide con quella dell'host. Modificare artificialmente la statistica locale durante la prova non cambia la barra autorevole.
- 71 controlli su catalogo, panchine, formazioni di tutte le squadre, hash, ID sconosciuti, ricaricamento dell'identificativo, deduplicazione e persistenza dello storico.
- Cattura UI a 1280×720 e controllo del ripristino della formazione locale dopo quella online. La navigazione usa le stesse azioni UI di PS/Xbox e mantiene visibili i controlli al focus.
- Confronto byte per byte di database base, curve dei valori, timing, fisica, rotazioni, difese e animazioni con la 0.101.0; controllo degli hash dei 216 file personali precedenti.

Rapporti: `online108-host.json`, `online108-guest.json`, `online108-catalog-history.json`, `online108-preservation.json`. Il test è locale a due processi: non certifica ogni combinazione di router o rete Internet.
