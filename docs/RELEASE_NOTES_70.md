# Spike Forever 0.70.0 — Campi di casa

Dodici profili grafici per il campo, selezionati dalla squadra a **sinistra** in esibizione, dalla squadra dell'host in online e dalla squadra di casa del calendario in carriera. La scelta della divisa, il cambio di campo e la telecamera non cambiano l'identità del palazzetto.

- Colori dedicati per superficie di gioco, zona d'attacco e zona libera; campo tricolore di Perugia.
- Sponsor principali e tecnici sul pavimento e sui pannelli LED, con rotazione delle pubblicità.
- Credem e **Del Monte su entrambi i lati della rete in tutti i campi**.
- 29 marchi originali conservati con URL e SHA-256. Niente loghi ricreati con caratteri approssimativi o immagini generate.
- Colori convertiti correttamente da sRGB; stampe leggibili sotto le luci del palazzetto.
- Geometria riutilizzata; immagini caricate al cambio del profilo, conservando in memoria solo quelle del club attivo.

Gli screenshot allegati guidano colori e collocazione delle stampe; i marchi sono ricavati dai siti dei club e degli sponsor. Suntory proviene dalla copia vettoriale del marchio ufficiale conservata su Wikimedia; il simbolo storico di Banca Alpi Marittime dalla pagina del suo partner WOWnature. Sono personalizzazioni grafiche della stessa struttura 3D del palazzetto, non dodici ricostruzioni architettoniche.

Fonti e configurazioni: `assets/art/arenas70/sources.json` e `profiles.json`. Nomi, roster, regole, rotazioni, timing e fisica della palla non sono modificati. Salvataggi e modifiche personali restano in `user://`.

L'online richiede la stessa versione su entrambi i PC (`SF070`).

## Verifiche

- `Test-Arenas70.gd`: tutti i 12 profili; sostituzione delle stampe; Del Monte fisso; cache e nodi limitati; fisica/RNG/rotazioni invariati; avvio reale dell'esibizione.
- `Test-CareerArena70.gd`: otto partite reali di carriera, casa/trasferta, tre/cinque set e ritorno alla carriera.
- `Test-OnlineArena70.gd`: host e ospite collegati realmente, stesso campo e sostituzione sincronizzata.
- Catture dei 12 campi: `docs/arena70-*.png`.

Riepilogo delle verifiche effettivamente eseguite in `docs/arena70-regression.json`.
