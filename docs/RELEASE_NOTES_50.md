# Spike Forever 0.50.0

La rincorsa di banda, opposto e pipe usa principalmente il gesto completo `attack_line` (con la variante stratificata `attack_adaptive41` quando applicabile). È la famiglia con corsa, ultimi appoggi e schiacciata mostrata nel riferimento video fornito. Eliminata la scelta casuale delle due prestazioni corte sulle palle ordinarie. Le palle di emergenza mantengono le alternative contestuali.

## Apertura e rincorsa

Prima il ricevente dell'alzata restava sull'apertura fino al rilascio, poi doveva raggiungere un bersaglio pianificato come un arresto. Ora parte dall'apertura durante gli ultimi 550 ms prima dell'alzata e raccorda la corsa all'appoggio di stacco. Orientamento della corsa e successivo ritorno verso rete dipendono dal lato della squadra e dalla direzione effettiva del percorso.

Il movimento del personaggio resta separato dalla posa dello scheletro. L'avanzamento in volo segue il medesimo orologio del salto e del contatto; mantiene le collisioni e prosegue nell'atterraggio. Il centrale conserva il proprio sistema di primo tempo e finta anticipata.

## Seconda linea

Il punto di stacco è distinto dal punto di contatto: pipe e opposto saltano da oltre i tre metri, colpiscono avanzando all'interno e atterrano più avanti. La pipe normale ha il contatto poco dentro la linea; quella veloce leggermente più avanti. La profondità viene specchiata per la squadra avversaria.

Pipe veloce: tempo nominale dell'alzata perfetta 0,68 s invece di 0,88 s, rispetto agli 0,92 s della normale. Il tempo viene esteso quando serve davvero per raggiungere il punto, conservando le alzate di sicurezza. L'alzata più rapida usa la medesima gravità e quindi ha un arco più basso, senza accelerazioni artificiali della palla.

La curva potenza/velocità è identica per attaccanti di prima e seconda linea. Restano la sicurezza fisica sopra la rete, le penalità contestuali sulle costruzioni d'emergenza e i controlli già disponibili.

## Verifica

- Test dedicato su tutte le sei rotazioni, entrambe le squadre, banda/opposto/pipe, alzate normali e veloci: tre contatti effettivi, stacco legale e avanzamento dentro i tre metri.
- Regressione dei contatti e delle rincorse, primo tempo/finta e 64 pallonetti nelle otto direzioni.
- Registrazione di tre azioni reali del gioco: [video](running50-preview.mp4).
- Il fallback PSA resta disponibile; nessuna nuova libreria viene generata durante lo scambio.

Le regole di rotazione, i controlli e la barra di potenza non cambiano.
