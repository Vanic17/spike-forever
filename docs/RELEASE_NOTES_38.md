# Palleggiatore, arena e atmosfera sonora

## Secondo tocco e attacco automatico

Nel finale del video 20-31-32 il palleggiatore perdeva tempo contro un compagno sulla destinazione del secondo tocco. Il cambio di attaccante durante il volo della ricezione cancellava la prenotazione del corridoio: chi aveva già lasciato spazio poteva rientrarvi. La correzione mantiene la precedenza per tutta l'alzata e controlla anche i percorsi futuri dei compagni, dopo la preparazione delle rincorse. Restano collisioni, velocità, accelerazioni e traiettoria della ricezione: nessun attraversamento dei corpi o contatto assegnato da lontano.

Una ricezione avversaria che oltrepassa la rete, se raggiungibile per l'attacco automatico, viene ora schiacciata al 100% con la stessa logica dei colpi vincenti. Il gesto deve toccare realmente la palla e il punto viene assegnato quando questa arriva a terra. Non cambia la velocità del colpo rispetto a un attacco normale di pari potenza.

Il catalogo di 134 animazioni già attive è stato ricontrollato: per questa correzione vengono riutilizzati i passi laterali e la rotazione di uscita dal corridoio. Non sono aggiunti movimenti superflui né sostituiti i gesti di contatto già validati.

## Campo e pubblico

Campo crema con zona anteriore più calda e spazio libero blu, due marchi CREDEM originali sul parquet e 22 pannelli LED con cambio sponsor ogni otto secondi. Le immagini di Credem Banca, Del Monte, Mikasa e +Adrenalina provengono dalla [pagina ufficiale Lega Volley](https://www.legavolley.it/sponsor/); file originali, URL e hash sono conservati in `assets/art/sponsors/sources.json`. Le proporzioni dei marchi sono preservate; sul campo compare soltanto CREDEM.

Pubblico con otto pose, abbigliamento e colori differenziati, volti corretti e reazione al punto. Le sedie sono raggruppate e gli spettatori non hanno scheletri animati individualmente. [Dettagli e immagini](ARENA_38.md).

## Audio

Dagli otto video sonori sono stati estratti, ripuliti e rielaborati 48 frammenti e motivi distinti; si aggiungono sei fischi arbitrali sintetizzati, perché non era allegato un file di fischio. In totale 54 Ogg: applausi ritmici, tamburi, pubblico, intermezzi, trombette, scarpe e fischi, senza ripetizioni immediate.

Applausi e tamburi accompagnano la preparazione della battuta e terminano all'avvio dell'azione. Scarpe legate al movimento effettivo; reazioni del pubblico, fischi e trombette variabili sui punti. Riverbero e compressione sono applicati al solo bus del palazzetto, lasciando la musica dei menu sul proprio percorso.

**L3 su PlayStation / clic dello stick sinistro (LS) su Xbox** disattiva o riattiva tutto l'audio, anche nei menu e nelle finestre. La preferenza rimane salvata localmente dopo chiusura e aggiornamenti. Disponibile anche il tasto M; F1 mostra il comando. [Sorgenti, elaborazione e verifica audio](AUDIO_ARENA38.md).

## Verifiche

- 144 sequenze ricezione-alzata: sei rotazioni, entrambe le squadre, 60/120 Hz, passaggi medi e buoni, cambio del destinatario, contatto reale, separazione dei corpi e limiti di movimento.
- Otto palle corte ai piedi del palleggiatore, ai due lati del ricevitore, 60/120 Hz e squadre specchiate, senza prolungare la traiettoria originale.
- 12 attacchi automatici su overpass: sei rotazioni e due squadre, contatto effettivo, potenza 100%, un solo punto al terreno.
- 54 stream audio decodificati, hash distinti, varianti raggiungibili, assenza di ripetizioni immediate, transizioni menu/battuta/scambio/punto/pausa e bus separato. Mix realmente registrato da Godot: −22,49 LUFS e −6,03 dBTP, senza clipping.
- Mute globale, persistenza e input nelle finestre; quattro loghi originali, proporzioni sul parquet, cambio LED e pubblico senza scheletri individuali.
- Regressioni su alzate, traffico fra compagni, finta del centrale, coperture difensive, attacchi vincenti e preparazione della partita.

Le prove controller usano gli eventi standard Godot di PlayStation/Xbox; non sono una prova su hardware fisico collegato. I controlli audio verificano rendering e livelli, non sostituiscono l'ascolto sul proprio impianto.
