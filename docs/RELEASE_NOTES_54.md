# Spike Forever 0.54.0

## Secondo tocco e corridoi

Analizzato il video `2026-10-25 19-12-32`, in particolare il secondo tocco mancato intorno a 1:23–1:25. Il video mostra il movimento e l'esito, senza il registro degli input: non consente di ricostruire esattamente tutti i parametri della partita. La verifica del codice ha riprodotto un conflitto concreto nella stessa classe di azioni.

Su un'alzata d'emergenza in bagher, il primo pianificatore riservava soltanto lo spazio dei piedi; il secondo includeva anche la piattaforma delle braccia e sostituiva la destinazione del compagno. La rivalutazione nel frame successivo poteva invertirla nuovamente. Il compagno attraversava il punto di contatto, la navigazione fermava S e la ripartenza arrivava tardi.

Le emergenze lontane da rete usano ora una sola prenotazione dell'intero corridoio e della piattaforma. La destinazione viene verificata contro tutti i segmenti, separata dalle altre destinazioni di chi cede il passo e mantenuta finché rimane valida. La ricerca dei candidati avviene solo quando la prenotazione non è più valida. Nessun teletrasporto, aumento generale della velocità o prolungamento di una traiettoria già in volo.

P4 verificata con input normali/veloci, alzate davanti/dietro e tempi di comando differenti. Le rotazioni regolamentari, i ruoli e l'ordine del sestetto non sono modificati; il primo tempo vicino a rete mantiene la propria gestione del corridoio.

## Nuovo colpo di seconda

Riferimento osservato: [video indicato dall'utente](https://www.youtube.com/watch?v=rxOxjrkf-_U). Nuova performance `dump_push54`: preparazione a due mani, distacco, estensione della sinistra e accompagnamento del polso verso il basso. Per i mancini il gesto viene specchiato. Animazione nativa immutabile con AnimationTree e maschera superiore; stessa performance sul percorso PSA di fallback, un solo sistema scrive la posa finale. Movimento reale e traiettoria rimangono separati dalla posa.

Il comando resta **Cerchio / B**. La seconda offensiva è disponibile con palla realmente raggiungibile vicino alla rete (entro 1,25 m), palleggiatore di prima linea e contatto abbastanza alto. Il controllo usa l'intercetto della stessa traiettoria all'altezza della nuova mano; non l'altezza del precedente palleggio. Da una posizione non adatta il comando produce un'alzata normale, con feedback esplicito. Nessuna seconda offensiva illegale del libero o del palleggiatore di seconda linea.

La traiettoria usa il medesimo integratore della palla: sceglie il tempo minimo che supera effettivamente rete e raggio della palla. Non usa più un unico pallonetto generico da qualsiasi distanza. Se una seconda rimbalza nella propria rete e viene recuperata al terzo tocco, il recupero manda la palla dall'altra parte; non viene programmata un'altra alzata da quattro tocchi.

## CPU e muro

La lettura di un rimbalzo da muro/rete ora predice il punto a terra, anziché dichiararlo sempre giocabile. La CPU lascia un pallone chiaramente fuori solo se l'ultimo tocco è dell'avversario. Continua a tentare il salvataggio di un pallone fuori toccato dalla propria squadra. Non avvia rincorsa o tuffo verso un rimbalzo già letto fuori.

La copertura dopo un muro introduce un piccolo tempo aggiuntivo di lettura, imperfezioni di piattaforma e variazioni di qualità. Il cambiamento riguarda questa fase; non peggiora indiscriminatamente la difesa ordinaria. Le traiettorie e la forza del muro restano quelle precedenti.

## Verifiche

- 9 costruzioni P4 d'emergenza confrontate sullo stesso codice di gioco, cambiando solo il pianificatore: 3 contatti falliti con il pianificatore precedente, 0 dopo la correzione. Contatto fisico e scadenza della traiettoria verificati.
- 36 costruzioni ricezione/alzata nelle sei rotazioni e su entrambi i lati; 36 costruzioni complete ricezione/alzata/primo tempo della suite precedente.
- 20 casi di traffico, compagni a terra e corridoi vicini alla rete, a 60/120 Hz.
- 72 primi tempi/finti primi tempi: contatti riusciti in tutti i casi; preparazione in salto conservata.
- Mano reale, gesto specchiato, parità AnimationTree/PSA, 16 traiettorie che superano la rete; comando Cerchio reale e recupero al terzo tocco.
- 120 confronti fisici di copertura: punti del muro 75 → 76, recuperi 37 → 36. Sono scenari di prova dopo un contatto di muro, non percentuali universali di tutte le azioni.
- Due processi online: battute, ricezioni, alzate, attacchi di entrambe le squadre, pausa e ritorno alla home.
- Rincorse: 96 costruzioni complete della suite precedente, tutte con contatti riusciti. Benchmark CPU isolato su 12 avatar/600 campioni: applicazione animazioni media 3,26 → 3,42 ms; nessuna crescita di oggetti o risorse durante i campioni. Il piccolo costo aggiuntivo è misurato in modalità headless e non rappresenta una misura degli FPS o della GPU.

La nuova tabella animazioni richiede **0.54.0 per entrambi i giocatori online**. Nessuna modifica ai tasti, alle barre, alle impostazioni di partita o ai salvataggi personali. Pacchetto completo scaricabile dagli Aggiornamenti; nessuna installazione automatica sulla copia con cui l'utente sta giocando.
