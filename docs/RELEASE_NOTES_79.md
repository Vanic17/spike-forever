# Spike Forever 0.79.0

## Attacco del centrale

Gesto ispirato a `eAL6N6yUgI0`: caricamento della spalla, apertura del busto, richiamo della gamba in volo e chiusura del polso. La clip è un adattamento autoriale del materiale sullo scheletro originale, non motion capture calibrata. È integrata nell'AnimationTree e nel controller del centrale per primo tempo, 7 e finta, conservando gli stessi eventi di contatto e stacco. Il mirroring esistente permette l'esecuzione mancina.

Restano gli attacchi precedenti di banda/opposto/pipe e le varianti introdotte nella 0.78. Il repertorio comprende così le tre famiglie richieste, con il nuovo gesto riservato al centrale nelle costruzioni regolari.

## Palleggiatore di Diventa un mito

- La preparazione dell'orientamento comincia prima della pressione del tasto.
- Quando il giocatore assume la seconda palla prevista per un compagno, l'intercetto viene ricalcolato sulle proprie mani e sulla prestazione scelta, senza cambiare la traiettoria fisica.
- Corretto il caso in cui l'alzata in preparazione veniva considerata un recupero ancora in corso: il sistema poteva sostituire all'ultimo momento il palleggio con un bagher e causare una palla mancata.
- Il raggio di contatto manuale di palleggio normale/veloce è coerente con l'assistenza arcade degli altri colpi. Il contatto finale con le mani resta verificato.
- Feedback distinti per alzata normale, veloce, bagher d'emergenza e alta di sicurezza quando l'attaccante non è pronto.

Verificate 24 alzate reali nelle sei rotazioni, con X e Quadrato e pressioni a 200 e 80 ms dal contatto: tutte completate. Le traiettorie di alzata continuano a usare il motore condiviso con l'esibizione.

## Cerchio / Xbox B: attacco di seconda

Il comando mantiene la spinta a una mano quando è disponibile vicino alla rete. Altrimenti, su una seconda palla alta e fisicamente attaccabile, prepara una vera schiacciata con l'animazione d'attacco e il normale motore di traiettorie, difesa e muro. Non aggiunge un terzo tocco.

È una scelta solo umana, disponibile anche in Diventa un mito. Non viene aggiunta alle decisioni dell'allenatore CPU. La schiacciata usa una potenza base dell'85%; la mira usa il comando di mira attivo nella modalità. Rimangono i vincoli del libero, della seconda linea, dell'altezza e della portata della palla. Se non è fisicamente attaccabile, il comando conserva l'alzata normale invece di inventare un contatto.

Il nuovo stato viene sincronizzato online. Per giocare insieme è necessaria la stessa generazione di protocollo, introdotta con questa versione; un client precedente viene rifiutato con il messaggio di versione non corrispondente.

## Battuta di Diventa un mito

La levetta sinistra mira senza far camminare il battitore; la destra non sostituisce la mira del servizio. La posizione di partenza resta stabile. Lancio, animazione e colpo usano le funzioni dell'esibizione. Se serve il passo di sicurezza all'indietro, la sua velocità non viene più azzerata dal controllo manuale e il giocatore mantiene l'orientamento verso il campo. L'input umano non può alterare la mira della battuta avversaria.

## Verifiche

Contatti reali del centrale e assenza di riavvolgimenti in 36 costruzioni, preparazione anticipata nelle sei rotazioni su entrambi i campi, pose a 30/60/120/144 Hz, destri/mancini in anteprima. Cerchio provato per spinta e schiacciata sia in esibizione sia in Diventa un mito; scelta sincronizzata tramite snapshot e conteggio di esattamente due tocchi. Servizi float/salto verificati sia dalla posizione ordinaria sia vicino alla linea, incluso arretramento di sicurezza. Passati anche i test dei comandi, ricezioni, attacchi della 0.78 e una coppia reale host/ospite.

Rapporti: `legend79-setting.json`, `legend79-service.json`, `second79-gameplay.json`, `middle79-poses.json`. Anteprima `middle79-preview.mp4`. Salvataggi, campionati e database personale non vengono migrati né cancellati. Resta disponibile l'aggiornamento selettivo.
