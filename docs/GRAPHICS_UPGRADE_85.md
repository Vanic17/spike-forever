# Upgrade grafico 0.85.0 — baseline Spike Forever 0.84.0

Questa revisione, inizialmente verificata in locale senza upload, è inclusa nella patch 0.85.0 su richiesta dell'utente insieme alla correzione dell'importazione audio. I confronti mantengono la 0.84.0 come baseline.

## Confronto visivo

Aprire [il confronto interattivo](graphics85-review.html): contiene cinque coppie di screenshot originali a 1920×1080, con divisore regolabile e immagini apribili alla risoluzione piena.

Le coppie mostrano scambio, giocatore, campo/rete, gradinate e replay ravvicinato. Squadre: Acqua Sant'Anna Cuneo e Cucine Lube Civitanova. Camera, FOV, posizioni, orologi, palla, RNG e pose coincidono nei metadati: [verifica invarianti](graphics85-invariants.json).

## A — Audit

Il rendering usa Godot 4.5.1 Forward+. La scena precedente comprendeva una luce direzionale inclinata, quattro spot da soffitto, un contributo ambientale elevato e nessun riflesso ambientale locale. Il parquet aveva colore quasi uniforme e una normal map Taraflex. Materiali di viso, scarpe e tessuto ignoravano mappe di roughness/AORM già presenti. La texture dell'iride era applicata come colore dell'intero occhio. Il pubblico disponeva già di 12 pose, MultiMesh e LOD precalcolati, con una palette molto variopinta.

[Audit delle risorse e delle proprietà effettive di Godot 4.5.1](graphics85-audit.json). Non sono stati introdotti asset esterni né nuovi modelli anatomici.

## B — Luce, campo e attrezzatura

- Luce principale più vicina alla direzione del soffitto; contributi morbidi sui volti limitati al layer visivo degli atleti e dello staff. Spalti distinti dal campo e tonemapping ACES.
- Ombre PCF con filtro morbido. Il tentativo PCSS è stato scartato perché produceva una trama visibile sulle superfici sovrapposte dei capelli; non viene usato neppure in Ultra.
- Trama del parquet, variazioni di roughness e micro-normal generate in modo riproducibile. Zona libera con risposta più opaca e granulare. Restano colori specifici delle dodici arene, geometrie, dimensioni, linee e sponsor.
- Un probe statico, configurabile, fornisce riflessi ambientali moderati. Gli atleti sono esclusi dalla cattura statica per evitare figure riflesse congelate.
- Rete con materiale dei fili e della banda superiore più definito. La funzione vertex che realizza il movimento è identica all'originale; nessuna modifica alle risposte fisiche.
- Protezioni e metalli con risposta superficiale distinta; pallone con rilievo fine che sfuma sotto il pixel e segue la rotazione già esistente.

## C — Giocatori

Utilizzate le mappe originali di roughness del viso e i normali già presenti; mantenuti gli incarnati scelti nel database. Gli occhi hanno un materiale che compone sclera e iride originale nelle proporzioni corrette, con riflesso superficiale. Divise con microtrama filtrata, risposta tessile più opaca e normali delle pieghe; stampe, nomi e numeri rimangono quelli del sistema attuale. Scarpe con albedo originale, normal e AORM. Materiali di capelli e barba rivisti senza cambiare mesh, colore individuale o skinning.

Il subsurface scattering è limitato al dettaglio materiali Ultra. Nei livelli inferiori rimangono illuminazione, texture e normali, contenendo il costo. L'alpha-to-coverage dei capelli è stato scartato durante il confronto e resta il taglio alpha originale.

**Limite dichiarato:** non sono stati creati visi fotorealistici o nuove anatomie. Forme delle orecchie, palpebre, mani e silhouette restano quelle dei modelli originali; anche la risoluzione delle texture facciali albedo resta 1024 px. Il miglioramento riguarda i materiali, gli occhi e la luce. Restano anche alcuni difetti preesistenti del raccordo geometrico tra colletto e corpo, visibili nel primo piano originale e in quello aggiornato; non vengono corretti alterando rig o pesi in questa revisione. Per superare questi limiti servono nuove mesh e texture facciali autorizzate, da validare separatamente contro il rig.

## D — Pubblico e arena

La palette degli abiti è più contenuta, con colori della squadra di casa e un settore ospiti. Piccole variazioni cromatiche dei capelli riducono l'uniformità delle teste. Conservati numero di spettatori, geometrie, pose, animazioni shader, organizzazione per tribuna e LOD della 0.82.

Le decorazioni del soffitto, i corpi illuminanti, le strutture portanti, le separazioni delle tribune e i piccoli dettagli dei monitor sono istanze MultiMesh. Sono esclusivamente visive: il sistema esistente continua a rilevare gli stessi 1401 volumi di collisione con arredi e pubblico. Nessuna nuova superficie fisica o modifica ai corridoi.

## E — Preset e preferenze

I quattro preset esistenti sono estesi con illuminazione del palazzetto, dettaglio materiali e riflessi ambientali statici. Basso disattiva spot e probe; Medio mantiene i materiali senza SSS/probe; Alto aggiunge i riflessi statici; Ultra abilita SSS e il livello di dettaglio maggiore. Restano configurabili separatamente risoluzione, MSAA, texture, SSAO, SSIL, SSR e ombre.

Le nuove opzioni utilizzano il file di preferenze locale esistente. Le vecchie preferenze vengono migrate soltanto per le chiavi nuove: le scelte precedenti non vengono sostituite. Database e carriere non vengono scritti dal sistema grafico.

## Prestazioni

Confronto locale, RTX 5080, Forward+, 1920×1080, preset Alto, scala 3D 100%, MSAA 4×, VSync disattivato, FPS illimitati; stessa costruzione ricezione–alzata–attacco e fisica asincrona a 120 Hz. Quattro secondi di warmup e circa sedici secondi misurati per il rendering.

| Misura | 0.84.0 | Upgrade locale |
|---|---:|---:|
| FPS medi | 105.1 | 107.1 |
| Frame medio | 9.51 ms | 9.33 ms |
| Frame p99 | 14.93 ms | 14.83 ms |
| Tempo GPU medio | 1.97 ms | 2.09 ms |
| CPU renderer media | 0.82 ms | 0.81 ms |
| CPU simulazione media/tick | 1.81 ms | 1.79 ms |
| Draw call medie | 1490 | 1456 |
| Primitive medie | 5.85 milioni | 5.56 milioni |
| Memoria video rilevata dal motore | 878 MiB | 1261 MiB |

Le prestazioni risultano comparabili in questo campione: il costo GPU cresce leggermente e la memoria aumenta soprattutto con le risorse PBR e l'atlante dei riflessi. Non viene rivendicato un aumento generale degli FPS. I preset inferiori consentono di disattivare gli effetti aggiuntivi. La memoria indicata è l'allocazione del motore, non l'intero consumo del driver o una misura universale per altri PC. Tempi CPU del renderer e della simulazione sono riportati separatamente nei JSON; la misura CPU della simulazione ha un warmup di due secondi.

[Baseline](graphics85-performance-before-high.json) · [Upgrade](graphics85-performance-after-high.json). Le registrazioni e gli screenshot non vengono usati per calcolare gli FPS.

### Scalabilità dei preset

Finestra 1920×1080 in tutte le prove; la scala 3D è quella prevista da ciascun preset esistente. I numeri non rappresentano confronti a qualità identica. Ogni preset ha eseguito 26 contatti nello scenario ripetibile.

| Preset | Scala 3D | MSAA | FPS medi | Frame p99 | GPU media | Memoria motore |
|---|---:|---:|---:|---:|---:|---:|
| [Basso](graphics85-performance-after-low.json) | 67% | No | 109,0 | 14,84 ms | 0,76 ms | 314 MiB |
| [Medio](graphics85-performance-after-medium.json) | 85% | 2× | 105,4 | 15,02 ms | 1,50 ms | 546 MiB |
| [Alto](graphics85-performance-after-high.json) | 100% | 4× | 107,1 | 14,83 ms | 2,09 ms | 1261 MiB |
| [Ultra](graphics85-performance-after-ultra.json) | 100% | 8× | 102,4 | 15,11 ms | 3,17 ms | 1722 MiB |

## F — Verifiche e ripristino

[Test grafici](graphics85-tests.json): migrazione e salvataggio dei preset, comportamento degli effetti, numero di spettatori e LOD, 1401 collisioni, identità e stampe delle divise casa/trasferta delle dodici squadre, conservazione degli override locali. [Invarianti](graphics85-invariants.json): 180 file protetti, compresi gameplay, rig, animazioni, fisica, networking, database e raccordo visivo, senza modifiche.

[Regressioni complete](graphics85-regressions.json): 18 suite offline superate e tre coppie host/ospite superate (database, sostituzioni, replay). I controlli includono controller, persistenza delle impostazioni, Diventa un mito, pose del palleggiatore, contatti di attacco/difesa, divise, dodici arene, panchina e Campionato. Il motore di carriera ha completato dieci stagioni, verificando archivi, backup e assenza di statistiche duplicate. Tutti i test usano profili isolati, senza scrivere nei salvataggi personali.

[Partita completa renderizzata](graphics85-full-match.json): set a 15 concluso 15-2 in 232 secondi, 30.926 frame, media 7,37 ms, p99 12,47 ms, un frame oltre 25 ms e nessuno oltre 50 ms. Il driver di prova carica gli attacchi umani al 99%; CPU, battute, ricezioni e alzate usano il normale percorso del gioco. Replay esclusi da questa prova e verificati separatamente, anche online. Una precedente prova di sei minuti senza carica assistita non aveva concluso il set entro il limite: non viene presentata come partita completata. Queste misure attestano una prova locale, non l'assenza assoluta di problemi in ogni scenario.

Gli shader sono stati compilati anche con il renderer reale Forward+, oltre alle verifiche headless. Restano avvisi preesistenti del caricatore di immagini a runtime e del certificato di sistema nell'ambiente di test; non sono nuovi errori shader o importazioni mancanti.

La baseline completa è conservata in `dist/v0.84.0-fluidity-release/SpikeForever-Windows.zip`; i file grafici precedenti sono anche in `.runtime/graphics85-backup`. Il parametro `--graphics-original85` disabilita l'upgrade visivo per confronti e ripristino grafico, conservando il raccordo della 0.84.0. Nessun asset originale è stato eliminato.

## Evoluzione successiva

Un passo ulteriore richiede volti e mani più dettagliati con pesi compatibili verificati, atlanti facciali ad alta risoluzione e maggiore varietà di teste per il pubblico. Per un'arena definitiva si può valutare un modello architettonico dedicato con UV per lightmap e illuminazione statica precalcolata. Questi asset non vengono simulati o dichiarati presenti in questa revisione.


## Elenco dei file

[Manifest con hash e stato rispetto alla 0.84.0](graphics85-files.json).

File esistenti modificati: `src/app_settings.gd`, `src/settings_menu.gd`, `src/arena.gd`, `src/source_assets.gd`, `src/player_appearance.gd`, `src/club_kits.gd`, `src/club_kit.gdshader`, `src/volleyball_v200.gdshader`, `assets/ui/en53.tsv`.

Nuovi moduli: `visual_graphics85.gd`, `visual_materials85.gd`, `visual_palette85.gd`; shader `eye_surface85`, `net_surface85`, `stadium_shell85`. Cinque mappe procedurali e relativa provenienza in `assets/art/visual85/`. Strumenti di audit, acquisizione, benchmark e test in `tools/*Graphics85*`; generatore mappe `tools/Build-Visual85.py`. Rapporti e confronti in `docs/graphics85-*`.

Il sistema di aggiornamento selettivo esistente distribuisce la 0.85.0. Il gioco della cartella originale utilizza già queste risorse; gli altri PC possono riceverle dal menu aggiornamenti. Vedere anche [note della patch](RELEASE_NOTES_85.md) e [verifica audio/editor](AUDIO_EDITOR_85.md).
