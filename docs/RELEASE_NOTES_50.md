# Spike Forever 0.50.0

La rincorsa di banda, opposto e pipe usa principalmente i gesti completi laterali `attack_pin_left` e `attack_pin_right`, con corsa, appoggi L-R-L e schiacciata. Sostituita la precedente scelta del gesto dritto `attack_line`: il riferimento richiesto è l'attacco laterale della banda bianca numero 15. Le palle di emergenza mantengono le alternative contestuali.

## Apertura e rincorsa

Prima il ricevente dell'alzata restava sull'apertura fino al rilascio, poi doveva raggiungere un bersaglio pianificato come un arresto. Ora parte dall'apertura durante gli ultimi 550 ms prima dell'alzata e raccorda la corsa all'appoggio di stacco. Orientamento della corsa e successivo ritorno verso rete dipendono dal lato della squadra e dalla direzione effettiva del percorso.

Il movimento del personaggio resta separato dalla posa dello scheletro. L'avanzamento in volo segue il medesimo orologio del salto e del contatto; mantiene le collisioni e prosegue nell'atterraggio. Il centrale conserva il proprio sistema di primo tempo e finta anticipata.

Nella rotazione dello screenshot (palleggiatore in zona 4, OH2 in zona 2) è la banda OH2 di prima linea a passare in zona 4 dopo il servizio. Il database di Milano identifica OH1 come Francesco Recine #3 e OH2 come Tatsunori Otsuka #15: in questa rotazione il #3 è di seconda linea in zona 5; non diventa prima linea spostandosi verso rete. Il riferimento sono le regole FIVB 7.4 e 13.2: [regolamento 2025–2028](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-v05.pdf).

Corretto il tragitto del #15: attraversa dietro la prima linea e davanti ai ricevitori, invece di scendere fino ai sei metri entrando nella corsia del libero. I compagni liberano anche il corridoio dell'ultimo salto, oltre al punto di contatto corrente. Sei casi dedicati riproducono quel cambio di ala sui due lati e con tre ricevitori diversi.

## Seconda linea

Il punto di stacco è distinto dal punto di contatto: pipe e opposto saltano da oltre i tre metri, colpiscono avanzando all'interno e atterrano più avanti. La pipe normale ha il contatto poco dentro la linea; quella veloce leggermente più avanti. La profondità viene specchiata per la squadra avversaria.

Pipe veloce: tempo nominale dell'alzata perfetta 0,68 s invece di 0,88 s, rispetto agli 0,92 s della normale. Il tempo viene esteso quando serve davvero per raggiungere il punto, conservando le alzate di sicurezza. L'alzata più rapida usa la medesima gravità e quindi ha un arco più basso, senza accelerazioni artificiali della palla.

La curva potenza/velocità è identica per attaccanti di prima e seconda linea. Restano la sicurezza fisica sopra la rete, le penalità contestuali sulle costruzioni d'emergenza e i controlli già disponibili.

## Verifica

- Test dedicato su tutte le sei rotazioni, entrambe le squadre, banda/opposto/pipe, alzate normali e veloci: tre contatti effettivi, stacco legale e avanzamento dentro i tre metri.
- Regressione dei contatti e delle rincorse, primo tempo/finta e 64 pallonetti nelle otto direzioni.
- Registrazione della banda #15 di Milano con cambio di ala e attacco: [video](running50-preview.mp4). Lo strumento di anteprima permette anche la sequenza completa con opposto e pipe.
- Il fallback PSA resta disponibile; nessuna nuova libreria viene generata durante lo scambio.

Le regole di rotazione, i controlli e la barra di potenza non cambiano.
