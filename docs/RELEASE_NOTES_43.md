# Spike Forever 0.43.0

## Recupero mancato nel finale del video

Nel finale dell'ultimo scambio completato, il difensore sembra ripetere un bagher mentre arretra e la palla e gia passata. Il percorso `winning_shot.failed_save` riavviava la prestazione dalla prima posa anche quando il contatto era mancato. In seguito la fase LOOSE conservava il vecchio bersaglio del difensore: un tentativo finito diventava una breve corsa tardiva con un secondo bagher.

Ora non viene avviato un altro bagher. Il gesto gia in corso puo terminare, l'IK smette di inseguire la palla e il bersaglio diventa un breve arresto nella direzione della velocita corrente. Velocita e posizione non vengono azzerate o teletrasportate. I tuffi mantengono atterraggio e rialzata originali. La stessa chiusura del tentativo viene applicata ai normali contatti mancati.

La logica del punto e il volo fisico restano invariati: nessun tocco aggiunto, nessun salvataggio magnetico e nessun aumento della percentuale di errore CPU.

## Preparazione degli specialisti

- Il centrale legge prima la fase di ricezione e raggiunge prima la posizione di preparazione. Il raccordo verso il bersaglio usa una risposta piu pronta, mantenendo accelerazione, frenata, collisioni e velocita massima esistenti.
- Il palleggiatore raggiunge piu decisamente la posizione di disponibilita per il secondo tocco. L'anticipo non viene applicato quando il percorso taglia il corridoio del primo tempo: accelerare insieme entrambi gli specialisti in quel punto faceva perdere tempo al centrale.
- Le rincorse ampie della v42, la priorita S/L sul secondo tocco, i controlli e il sistema del timing sono conservati.

`Benchmark-Preparation43.gd` confronta 12 preparazioni speculari, sei rotazioni per entrambe le squadre, con la v42 installata in una cartella isolata. Nei dieci casi in cui il centrale raggiungeva la soglia entro i due secondi della prova, passa mediamente da **0,794 s a 0,703 s**; negli otto casi corrispondenti del palleggiatore, da **1,041 s a 0,806 s**. Nessuno di questi casi diventa piu lento. I casi fuori dalla finestra non vengono trasformati artificialmente in arrivi riusciti e non sono inclusi nella media. Report completi: `preparation43-before.json` e `preparation43-after.json`.

## Verifiche

- `Test-RecoveryPresentation43`: quattro casi su entrambe le squadre, gesto precedente di corsa o bagher, nessun riavvio, arresto coerente con l'inerzia e volo della palla invariato su un contatto mancato.
- `Test-Approach42`: 96 costruzioni ricezione-alzata-attacco, tutte le rotazioni e direzioni, normali e veloci, con tre contatti reali.
- `Test-MiddleDecoy`: 36 finte su ricezione buona, salto reale, nessun contatto e rientro in copertura.
- `Test-SetterPipeline38`: 144 sequenze a 60/120 Hz, cambio attaccante, contatti e distanze.
- `Test-ContactTraffic28`: 20 avvicinamenti con ostacoli in piedi o a terra, squadre speculari e 60/120 Hz, recupero basso sullo stesso volo.
- `Test-Power29`: punti reali nella fascia vincente, battuta, attacco, muro e buffering conservati.

Il controllo renderizzato usa lo stesso scenario della v42: RTX 5080, Forward+, 1280x720, limite 60 FPS, 600 frame dopo il riscaldamento. Risultato finale: **60,00 FPS medi**, p95 **19,32 ms**, massimo **23,44 ms**, nessun frame oltre 25 ms. I dati sono in `animation42-rendered-v43-final-new.json`. Una prova locale non garantisce lo stesso frame time su ogni computer o in ogni recupero possibile. I video dell'utente sono stati letti per l'analisi e non sono inclusi nella pubblicazione.
