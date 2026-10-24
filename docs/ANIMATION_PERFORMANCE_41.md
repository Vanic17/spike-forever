# Prestazioni dei due prototipi v0.41

Il confronto usa lo stesso `Benchmark-Animation41.gd` scritto ed eseguito **prima** delle modifiche: dodici avatar completi, 145 ossa ciascuno, 90 frame di riscaldamento e 600 campioni. Il file del benchmark non è stato modificato tra le misure. SHA-256: `8ee9e215554ebb71a6b314fb5ebc30c7f3810d49274a65ec0705948de898b394`.

## Percorso originale prima e dopo l'integrazione

| Scena originale | Media CPU / 12 giocatori | p50 | p95 | p99 | Media applicazione pose |
| --- | ---: | ---: | ---: | ---: | ---: |
| Nativo prima | 5,595 ms | 5,606 ms | 8,002 ms | 9,101 ms | 5,549 ms |
| Nativo dopo | 5,606 ms | 5,588 ms | 8,109 ms | 9,157 ms | 5,560 ms |
| PSA prima | 5,409 ms | 5,346 ms | 7,737 ms | 8,825 ms | 5,355 ms |
| PSA dopo | 5,410 ms | 5,338 ms | 7,811 ms | 8,930 ms | 5,357 ms |

La differenza media è +0,19% sul nativo e +0,013% sul PSA. Il p95 nativo cambia di +1,34%. Una ripetizione prima delle modifiche aveva misurato 5,595 ms medi e p95 8,045 ms: non emerge un rallentamento sostanziale sul percorso originale da questi campioni.

Questo primo confronto conserva il banco originale di 127 clip e non registra i prototipi: misura il costo delle integrazioni quando si usa un'animazione originale. Non sostituisce la prova seguente con le varianti effettivamente attive.

## Costo delle nuove varianti realmente selezionate

`Benchmark-AnimationPrototypes41.gd` eredita il carico precedente senza modificarne le formule. Prima del setup registra le due nuove clip come in `main._ready`; usa il banco di 127 clip originali più i due prototipi. A tutti i casi applica lo stesso contesto raggiungibile di contatto: peso 0,65 e variazioni entro 8 cm in laterale, 4 cm in altezza, 3 cm in profondità. Viene cambiata soltanto la selezione delle varianti sotto le azioni logiche `dive` e `attack`.

| Varianti selezionate | Backend | Media CPU / 12 giocatori | p50 | p95 | p99 | Media applicazione pose |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Originali | Nativo | 6,199 ms | 6,216 ms | 8,209 ms | 9,236 ms | 6,157 ms |
| Solo tuffo nuovo | Nativo | 6,168 ms | 6,159 ms | 8,124 ms | 9,111 ms | 6,124 ms |
| Solo attacco nuovo | Nativo | 6,413 ms | 6,478 ms | 8,426 ms | 9,726 ms | 6,370 ms |
| Entrambi nuovi | Nativo | 6,412 ms | 6,470 ms | 8,349 ms | 9,277 ms | 6,369 ms |
| Originali | PSA | 5,940 ms | 5,867 ms | 7,799 ms | 8,869 ms | 5,888 ms |
| Entrambi nuovi | PSA | 6,285 ms | 6,332 ms | 8,144 ms | 9,037 ms | 6,234 ms |

Con entrambi i prototipi il sovraccosto medio del campione nativo è **0,213 ms complessivi sui dodici giocatori (+3,43%)**, p95 +1,71%. Nel fallback PSA è 0,346 ms (+5,82%). Il tuffo viene trasformato durante la generazione iniziale e non aggiunge correzioni runtime proprie; l'attacco adattivo aggiunge un contributo limitato del busto/spalla quando la palla è raggiungibile. La lieve differenza negativa del solo tuffo è una misura di quel carico, non un'ottimizzazione dimostrata.

Ogni esecuzione nativa verifica che i dodici rig di valutazione siano inizializzati. Nei report validi ci sono 12.999 valutazioni native; il fallback PSA ne ha zero e non alloca rig nativi. Le varianti mancanti causano un'asserzione nel benchmark dedicato: non viene accettato un risultato relativo al fallback mentre si dichiara di misurare il prototipo.

## Memoria, risorse e limiti della misura

- In tutte le undici esecuzioni conservate, dopo il riscaldamento il numero di oggetti e risorse resta costante durante i 600 campioni.
- La memoria statica trattenuta cresce nel campione di circa 43 KB sul nativo e 66 KB sul PSA, sia con originali sia con prototipi. Gli array temporanei delle pose esistono ancora: non si dichiara assenza di allocazioni per frame.
- Le due clip e il supplemento nativo portano la memoria statica della scena isolata da circa 482,16 MB a 486,43 MB: circa **4,27 MB aggiuntivi**. Con il backend PSA la crescita corrispondente è circa 1,66 MB. Sono misure dell'intera scena, non soltanto dei keyframe.
- Il supplemento nativo precalcolato è un file separato di 536.756 byte; la libreria originale `native_all.res` resta intatta. I due prototipi PSA in memoria vengono preparati all'avvio, non generati dentro `apply_pose`.
- La misura riguarda CPU dell'aggiornamento visivo in modalità **headless**. Non misura GPU, draw call della partita, FPS visibili o costo complessivo di arena/IA/fisica/audio. Gli intervalli tra callback sono conservati come dati grezzi, senza convertirli in FPS.
- I contatori Godot sono indicatori di memoria e risorse trattenute, non un trace universale delle allocazioni temporanee o degli accessi al disco. `setup_ms` del benchmark ereditato non include la registrazione preventiva dei prototipi, quindi non va usato come misura dell'intero avvio.
- Le undici esecuzioni sono state controllate per errori script e asserzioni, oltre al messaggio di completamento. Un primo tentativo eseguito durante un errore di compilazione è stato escluso e sostituito da una misura valida: il solo testo `PASS` non è considerato sufficiente.

## Ripetere le prove

Da PowerShell nella cartella del progetto, usare etichette nuove per conservare i report originali:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.runtime/roaming'
$env:LOCALAPPDATA = Join-Path (Get-Location) '.runtime/local'
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-Animation41.gd --quit-after 1800 -- --label=local-current-native
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-Animation41.gd --quit-after 1800 -- --label=local-current-psa --psa-original
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-AnimationPrototypes41.gd --quit-after 1800 -- --label=local-originals --prototype-set=none
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-AnimationPrototypes41.gd --quit-after 1800 -- --label=local-dive --prototype-set=dive
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-AnimationPrototypes41.gd --quit-after 1800 -- --label=local-attack --prototype-set=attack
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Benchmark-AnimationPrototypes41.gd --quit-after 1800 -- --label=local-both --prototype-set=both
```

I risultati completi e gli hash sono nei singoli `animation41-*.json`; `animation41-performance-summary.json` raccoglie le undici esecuzioni e le differenze calcolate. La qualità visiva, le fasi complete di caduta/rialzata e la sincronizzazione con la palla vengono verificate dai test funzionali e dalle catture dedicate, non inferite da questi soli tempi.

## Verifica aggiuntiva della partita renderizzata

`Benchmark-RenderedMotion41.gd` avvia il gioco reale con arena, pubblico, HUD e dodici avatar, senza il menu. La camera è quella televisiva laterale e la finestra/viewport misura 1280×720. Su questo PC il renderer è Forward+ e la scheda rilevata è **NVIDIA GeForce RTX 5080**. Le due esecuzioni sono state fatte una per volta, dopo la conclusione delle altre catture grafiche.

Il limite è 60 FPS con VSync disattivato; dopo 120 frame di riscaldamento vengono misurati 600 frame realmente disegnati tramite `RenderingServer.frame_post_draw`. La simulazione esegue due passi di 1/120 s per frame. Una costruzione reale da ricezione profonda ad attacco di pipe viene avviata ogni 240 frame, con gli stessi semi e comandi nelle due modalità. Il selettore sceglie naturalmente `attack_line` nell'originale e il nuovo prototipo nella modalità nuova; non viene forzato un alias di animazione. Non si usa `--fixed-fps` né la modalità di registrazione video: gli intervalli sono tempo reale osservato.

| Modalità | FPS medi osservati | Frame medio | p50 | p95 | p99 | Massimo | Frame >25 ms | Frame >50 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Originale, `--motion-original` | 59,804 | 16,721 ms | 16,493 ms | 21,194 ms | 24,012 ms | 26,006 ms | 2 / 600 | 0 / 600 |
| Nuovo sistema abilitato | 59,600 | 16,779 ms | 16,351 ms | 22,380 ms | 25,525 ms | 28,219 ms | 10 / 600 | 0 / 600 |

Il campione resta vicino al limite di 60 FPS in questa scena sull'hardware indicato, con una differenza media di circa −0,34% di FPS. Il nuovo sistema mostra code leggermente maggiori: circa +1,19 ms al p95 e +1,51 ms al p99, e dieci anziché due frame oltre 25 ms. Non ci sono frame oltre 50 ms in nessuno dei due campioni. Non si dichiara quindi un costo nullo o una perfetta uguaglianza dei tempi. Una singola coppia di esecuzioni brevi non separa in modo definitivo il costo delle pose da ogni variabilità di driver/scheduling; il confronto CPU isolato precedente serve a circoscrivere il lavoro del nuovo sistema.

La nuova schiacciata è effettivamente presente in **162 dei 600 frame misurati**, con **tre contatti reali del prototipo** durante la finestra di misura. Entrambe le versioni completano tredici contatti complessivi nella scena. Il report non si limita quindi ad abilitare un interruttore senza mostrare la nuova animazione.

**Limite del campione:** la prova copre le pipe riproducibili e il gioco renderizzato con dodici giocatori, non l'intera partita competitiva o ogni recupero difensivo. Non misura il massimo FPS ottenibile e non garantisce gli stessi risultati su altri PC. Il costo del tuffo e delle altre combinazioni viene misurato nella matrice CPU; le fasi visive complete sono documentate nelle catture dedicate. Gli intervalli dell'intero frame includono attese del renderer e scheduling: non sono query dirette dei tempi GPU. Il monitor del tempo di processo dell'engine e il costo CPU dei due passi di simulazione sono conservati nei report JSON separati.

Report: `animation41-rendered-original.json` e `animation41-rendered-new.json`. Per ripetere, eseguire lo script senza `--headless`, prima con `-- --motion-original` e poi senza quel flag; ogni finestra si chiude automaticamente al termine dei campioni.
