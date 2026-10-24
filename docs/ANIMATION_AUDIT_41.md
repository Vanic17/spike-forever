# Ricognizione prima dei prototipi v0.41

Analisi del codice e misurazioni eseguite prima dell'integrazione dei nuovi prototipi. I file JSON conservano gli hash delle sorgenti misurate; non sono misure ricostruite dopo la modifica.

## Asset e percorso reale delle pose

- `assets/spike` contiene 2.696 esportazioni PSA. Questo è l'archivio delle sorgenti, non il numero di animazioni giocabili.
- `assets/active` contiene 134 PSA attivi, tutti con hash diverso e con la stessa gerarchia di 145 ossa. Il catalogo nativo ne converte 127; sette pallonetti restano sul sampler PSA. I conteggi e i metadati per ogni file sono in `animation41-source-audit.json`.
- Raggruppando per famiglia: 29 ricezioni, 8 tuffi, 1 recupero, 19 attacchi inclusi i sette pallonetti, 13 alzate normali, 13 veloci, 7 muri. Le altre 44 clip coprono attese, spostamenti, battute e appoggio di seconda. I numeri descrivono i file attivi, non garantiscono che ogni variante sia appropriata in ogni situazione.
- `psa.gd` legge keyframe ActorX in centimetri, corregge il coniugato delle rotazioni dei figli e recupera la gerarchia dal PSK. Il campionamento interpola traslazioni locali e quaternioni, poi ricostruisce la gerarchia. `Avatar.psa_normalized_pose` converte assi/unità e rimuove il viaggio orizzontale della radice. Il gioco controlla la posizione reale del personaggio.
- `psa_animation_library.gd` converte le pose normalizzate in tracce locali di posizione e rotazione; non crea tracce che muovono il nodo del giocatore e non aggiunge tracce di scala. `native_all.res` pesa 44.925.528 byte compresso. La libreria immutabile è condivisa tra avatar.
- Ogni avatar nativo possiede un rig di valutazione privato: `AnimationPlayer` e `AnimationTree` manuale con `Clip → TimeSeek → output`. Questo rig fornisce campioni; non scrive sullo scheletro visibile. `Avatar.apply_pose` combina pose e correttivi, poi è l'unico autore delle pose dello scheletro visibile. Il fallback PSA percorre gli stessi stadi successivi.
- Il blending esistente usa trasformazioni locali e ricostruisce la gerarchia. Sono già presenti maschere per tronco/gambe, continuità delle transizioni interrotte, avanzamento della posa uscente e scelta della fase del passo più vicina.
- Le clip attive vengono scelte per lato, altezza relativa, velocità, qualità, direzione del colpo e seriale visivo. La selezione non consuma il generatore casuale del gameplay. I numeri dei file non sono una scelta casuale indiscriminata.

## Correzioni e contatto da preservare

Sono già presenti IK a due segmenti delle braccia con raggio di correzione limitato, correzioni dei piedi progressive, orientamento della testa, inclinazione per accelerazione, rotazione del busto per liberare un corridoio e sovrapposizione dei passi sotto la preparazione del colpo. Le gambe conservano decollo e atterraggio originali nelle azioni in salto.

`detect_contact` stima il contatto dal movimento delle mani e il recupero dall'altezza di piedi/bacino: non legge eventi temporali originali dell'asset. Il gioco mantiene la scadenza del contatto e suddivide il passo di simulazione per raggiungerla esattamente. Un nuovo prototipo deve dichiarare e verificare il proprio contatto e recupero; non basta ereditare la stima di una clip differente.

Molte protezioni di `Avatar` distinguono le famiglie logiche `attack`, `dive`, `receive`, ecc. È opportuno aggiungere varianti sotto queste azioni, lasciando invariati i nomi delle azioni del gameplay: un nome nuovo non collegato può perdere IK, protezione dell'atterraggio o logica di recupero.

## Baseline riproducibile con 12 giocatori

`tools/Benchmark-Animation41.gd` istanzia dodici avatar completi con le sei parti dei modelli originali. Esegue cicli deterministici sfalsati di spostamento laterale, ricezione, attacco e tuffo, con velocità, accelerazione e sguardo definiti dalla stessa formula. Dopo 90 frame di riscaldamento misura 600 aggiornamenti a passo simulato fisso di 1/60 s. Nessuna IA, audio o esito casuale cambia il carico.

| Backend prima delle modifiche | Aggiornamento 12 avatar medio | p50 | p95 | p99 | Solo `apply_pose` medio |
| --- | ---: | ---: | ---: | ---: | ---: |
| AnimationTree | 5,595 ms | 5,606 ms | 8,002 ms | 9,101 ms | 5,549 ms |
| PSA originale | 5,409 ms | 5,346 ms | 7,737 ms | 8,825 ms | 5,355 ms |

Le misure sono **CPU in modalità headless**, non FPS della partita e non tempi GPU. Il costo totale comprende scelta/transizione/tick e applicazione della posa dei dodici giocatori; il probe di campionamento separato è escluso da questo totale. Gli intervalli tra callback includono il probe e il ciclo dell'engine: sono conservati nel JSON, ma non vengono convertiti in FPS.

Una seconda esecuzione nativa sugli stessi hash di sorgente ha misurato 5,595 ms medi, p95 8,045 ms e p99 9,135 ms (`animation41-before-native-repeat.json`). Questo aiuta a distinguere il rumore di misura da un cambiamento consistente, senza sostituire la verifica della partita renderizzata.

Durante i 600 campioni non crescono il numero di risorse o quello degli oggetti. La memoria statica trattenuta cresce di circa 43 KB sul nativo e 66 KB sul PSA; questo non è un contatore di allocazioni temporanee. Le istanze/risorse dopo il riscaldamento restano rispettivamente 2.071/137 nel nativo e 1.835/9 nel PSA. La memoria statica dell'intera scena isolata è circa 482 MB nel nativo e 241 MB nel PSA: il file nativo compresso viene decompresso in memoria. Non attribuire queste cifre al solo buffer delle pose.

Godot non espone qui un contatore universale delle allocazioni per frame o un trace di accessi al filesystem. Gli indicatori raccolti provano l'assenza di crescita trattenuta nel campione, non l'assenza di allocazioni temporanee o di I/O in qualsiasi altro percorso. Il codice non carica file in `apply_pose` dopo il setup; il caricamento e l'eventuale conversione della libreria avvengono nel setup del rig.

## Costi concreti e scelta progressiva

Quasi tutto il tempo di questo carico visivo è in `apply_pose`, che esegue più campionamenti, ricostruzioni della gerarchia e passaggi per osso. Nel codice sono evidenti creazioni di array e trasformazioni inverse per blending, IK e invio delle ossa; `rotate_subtree` cerca inoltre gli antenati per ogni osso. Questi sono punti da profilare/ottimizzare se si estende il sistema; non sono percentuali di costo individuali misurate.

Il rig nativo non fornisce automaticamente un guadagno rispetto al PSA in questa scena: le pose vengono comunque ricomposte e corrette in GDScript. Il vantaggio attuale è l'uso di risorse native immutabili, un percorso di estensione e la separazione dei due autori delle pose. Non occorre riscrivere il parser, eliminare il fallback o introdurre Blender per aggiungere due clip procedurali mirate.

La soluzione raccomandata è ibrida: due varianti native costruite una volta, un contributo procedurale anatomico limitato e contestuale, scelta compatibile con la situazione, ritorno immediato alle varianti originali tramite interruttore. Generazione o caricamenti dentro `apply_pose` renderebbero invece il carico dipendente dall'azione e vanno evitati.

## Comandi ripetibili

```powershell
$env:APPDATA = Join-Path (Get-Location) '.runtime/roaming'
$env:LOCALAPPDATA = Join-Path (Get-Location) '.runtime/local'
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Audit-Animation41.gd
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-Animation41.gd -- --label=before-native
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-Animation41.gd -- --label=before-psa --psa-original
```

Per il confronto successivo si cambiano soltanto le etichette di output in `after-native` e `after-psa`; non si cambiano tempi, avatar, scene o formule del benchmark. Il costo dei prototipi attivi richiede anche un confronto dedicato, perché un'azione priva del loro contesto deve continuare a usare il comportamento originale.
