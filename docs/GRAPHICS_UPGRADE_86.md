> Historical prototype: integrated in release 0.89.0. The local-only status below describes its earlier review stage.

# Revisione grafica 0.86 — prototipo locale basato sulla 0.85.0

La 0.85.0, comprensiva della correzione WAV e del precedente upgrade, è [pubblicata su GitHub](https://github.com/Vanic17/spike-forever/releases/tag/v0.85.0). Questa revisione 0.86 resta **locale e non pubblicata**. Il numero del gioco rimane 0.85.0 fino a un rilascio autorizzato, preservando la compatibilità con i client pubblici mentre si valuta il prototipo grafico.

Sono stati riletti entrambi i documenti: la prima parte dell'upgrade 0.86 e il completamento `Volti.txt`. La priorità ai personaggi è affrontata con un singolo atleta pilota. **Non viene dichiarato completato un rifacimento fotorealistico dei giocatori:** sono presenti miglioramenti verificabili di geometria, raccordo e materiali, ma restano limiti degli asset originali.

## Confronto reale

[Aprire il confronto interattivo](graphics86-review.html): sei viste a 1920×1080, divisore prima/dopo e selezione delle fasi intermedie. Squadre Cuneo/Lube, stessa scena, pose, palla, clock, stato RNG e camere. I metadati sono confrontati in [invarianti](graphics86-invariants.json).

Viste: campo durante uno scambio, primo piano, pubblico, campo/rete, replay ravvicinato, tribune/soffitto. Sono acquisizioni del framebuffer Godot; nessun mockup, ritocco fotografico o immagine generata esternamente. Il solo strumento di acquisizione nasconde l'HUD e imposta le camere diagnostiche: il gioco conserva HUD e telecamere esistenti.

## Audit: rendering e asset sono problemi diversi

[Audit della geometria e del rig](graphics86-audit.json). La base dispone di un volto generico da 7.578 triangoli, occhi da 800, corpo da 7.472, scarpe da 4.378; scheletro del corpo a 115 ossa. L'albedo facciale è 1024px, il normal 2048px. Esistono varianti di pelle non sfruttate dall'abbinamento standard; capelli e barbe rimangono principalmente superfici ritagliate. Il pubblico usa due corpi base e un numero limitato di atlanti e pose.

I problemi di rendering della 0.85 comprendono separazione troppo contrastata, riempimento insufficiente sulle tribune e una doppia conversione dei pigmenti del campo. Il materiale standard dichiara già `albedo : source_color`: applicare anche `srgb_to_linear()` ai valori esadecimali dei profili li scuriva ulteriormente. La conversione preventiva è rimossa soltanto nel nuovo percorso grafico. Riferimento: [generazione dello shader standard di Godot 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/scene/resources/material.cpp#L905).

## A — Distribuzione della luce

Esposizione predefinita sempre 1,0; il comando di esposizione nelle preferenze continua a funzionare. Tonemapping Filmic, luce principale neutra, riempimenti per i volti e tre contributi statici diffusi verso la parte alta del palazzetto. Ombre meno opache, SSAO meno aggressivo e foschia ridotta: le gradinate non vengono nascoste nel buio. Nessuna nuova luce colorata, motion blur, vignettatura o profondità di campo.

Le luci aggiuntive non producono nuove shadow map. Il filtro PCF resta stabile; non viene riattivato il PCSS che aveva mostrato reticoli sui capelli. L'illuminazione superiore viene disattivata nel livello Basso. Le immagini della fase “solo luce” permettono di valutarla prima delle altre modifiche.

## B — Un atleta pilota

Il primo atleta del sestetto usa risorse visive separate, conservando rig, bind frame, ossa, pose e punti di contatto. I file originali non sono sovrascritti.

| Parte | Originale | Prototipo | Utilizzo |
|---|---:|---:|---|
| Testa | 7.578 triangoli | 30.312 | Alto/Ultra |
| Occhi | 800 | 3.200 | Alto/Ultra |
| Corpo e mani | 7.472 | 29.888 | Ultra |
| Scarpe | 4.378 | 17.512 | Ultra |

La rifinitura PN-edge aggiunge curvatura tra i vertici esistenti; il raccordo inferiore del collo viene adattato sotto il colletto. I nuovi vertici hanno pesi interpolati e normalizzati sulle stesse ossa. Basso/Medio usano la geometria originale. Se una risorsa opzionale del prototipo manca, resta visibile la parte originale.

Per il pilota con barba viene riutilizzato il set facciale **M_01 già disponibile**, più dettagliato e coerente con il corpo M_01, al posto del precedente abbinamento M_02. Barba, capelli, pelle e loro tinte restano quelli del database; gli aspetti senza barba e calvi conservano le scelte corrispondenti. La selezione è immediata all'assegnazione dell'aspetto e rimane corretta al cambio di qualità; nessuna sostituzione periodica durante lo scambio.

Non si tratta di una nuova scansione facciale o di una nuova anatomia scolpita. La suddivisione non inventa dettagli di naso, bocca o orecchie assenti nella base; anche capelli e barbe richiedono asset migliori. Una prova alternativa sui materiali dei capelli produceva un riferimento nullo durante la chiusura headless: è stata scartata integralmente. Non è estesa agli altri atleti.

## C — Campo, rete e pallone

Tre nuove mappe procedurali 2048px per superficie in acero: tavole sfalsate, venature, micro-normal e roughness. Restano dimensioni, mesh del terreno, linee, sponsor e colori dei dodici profili. Viene corretta la gestione sRGB dei pigmenti, senza riscrivere i valori dei profili. I riflessi statici della 0.85 restano moderati e configurabili.

La rete conserva integralmente il proprio shader di movimento e la risposta fisica; è eliminata l'ombra a griglia troppo invasiva sul terreno. Il materiale del pallone della 0.85 viene conservato e verificato sotto la nuova luce: pannelli, scritte e rotazione rimangono leggibili. Nessuna modifica a spin o traiettorie.

## D — Pubblico

Pantaloni separati cromaticamente dalle maglie, palette più varia, una quota di tifosi con i colori dei club e piccole differenze di corporatura. Alcune maglie hanno righe filtrate in base alla dimensione del pixel per evitare reticoli a distanza. Restano gli stessi 1.280 spettatori, gli stessi sedili, le stesse pose disponibili e il medesimo LOD.

Questa fase riduce la ripetizione cromatica, ma non crea nuove identità facciali. I due corpi base e l'atlante del volto continuano a essere un limite visibile nei primi piani delle tribune. Non viene rivendicato un pubblico ricostruito da nuovi modelli o animazioni.

## E — Architettura

Aggiunti corrimano tubolari lungo le scale, diagonali delle travature, pannelli e telai del soffitto e fasce dei camminamenti superiori. Sono batch MultiMesh nativi, esclusivamente visivi. L'arena originale mantiene la propria struttura superiore; non viene presentata come un nuovo palazzetto modellato integralmente.

I 1.401 proxy di collisione con arredi e pubblico risultano identici, compresi posizione, dimensioni, tipo e coefficiente: [prima](graphics86-collisions-before.json), [dopo](graphics86-collisions-after.json). Le nuove decorazioni non entrano nel sistema di collisioni.

## F — Qualità e prestazioni

I quattro preset esistenti restano reversibili e persistenti. Oltre a texture, antialiasing, luci, ombre e riflessi, la qualità materiali ora seleziona anche il dettaglio geometrico del pilota. Nessun effetto viene sincronizzato alla simulazione o usato per cambiare i risultati dei colpi.

Confronto RTX 5080, driver 621.01, Godot 4.5.1 Forward+, 1920×1080, scala 3D 100%, MSAA 4×, VSync disattivato e FPS illimitati. Tre esecuzioni per versione, quattro secondi di warmup e sedici misurati per esecuzione, identico scenario ricezione/alzata/pipe e 26 contatti per prova. CPU della simulazione misurata con warmup di due secondi.

| Misura | Prima: media (min–max) | Dopo: media (min–max) |
|---|---:|---:|
| FPS | 106.044 (105.638–106.758) | 106.127 (105.759–106.820) |
| Frame medio, ms | 9.430 (9.367–9.466) | 9.423 (9.362–9.455) |
| Frame p95, ms | 12.484 (12.346–12.561) | 12.512 (12.485–12.559) |
| Frame p99, ms | 14.538 (14.267–14.797) | 14.564 (14.192–14.760) |
| GPU media, ms | 2.098 (2.090–2.103) | 2.343 (2.338–2.350) |
| CPU renderer, ms | 0.813 (0.808–0.816) | 0.828 (0.811–0.857) |
| CPU simulazione, ms | 1.801 (1.794–1.805) | 1.791 (1.785–1.796) |
| Memoria video, MiB | 1261.189 (1261.189–1261.189) | 1349.053 (1349.053–1349.053) |
| Draw call | 1456.093 (1456.083–1456.114) | 1455.091 (1455.084–1455.104) |
| Primitivi, milioni | 5.557 (5.557–5.557) | 5.653 (5.653–5.653) |

I dati mostrano un costo GPU e di memoria maggiore, con FPS medi comparabili nelle prove. Non viene rivendicato un aumento generale delle prestazioni. [Riepilogo con minimi, massimi e deviazione standard](graphics86-performance-summary.json); disponibili anche i sei JSON grezzi. La memoria è l'allocazione riportata dal motore, non il consumo complessivo del driver. Lo scenario ripetibile non rappresenta ogni situazione di gioco; altre applicazioni e condizioni del PC non sono controllate integralmente.

## G — Verifiche

- [Geometria, skinning e impostazioni](graphics86-tests.json): pesi normalizzati e validi, indici delle 115 ossa, 10.632 campioni di deformazione su sei famiglie di azione e quattro fasi, tutti i preset e dodici arene. Lo scostamento aggiunto sui bordi raffinati rimane sotto 2,5 mm nei campioni: non è una misura dell'adattamento intenzionale del collo. Verificate anche pelle, barba/calvizie e persistenza dell'aspetto tra preset.
- [Regressioni](graphics86-regressions.json): 19 suite offline, comprese le verifiche di animazioni/contatti, controller, Diventa un mito, replay e dieci stagioni di Campionato. Il vecchio test dei pigmenti viene eseguito nel percorso di confronto 0.85; il nuovo percorso è verificato separatamente sui dodici profili.
- Tre coppie online host/ospite: [database](graphics86-online-database.json), [sostituzioni](graphics86-online-substitutions.json), [replay](graphics86-online-replay.json). Nessuna modifica a protocollo o sincronizzazione.
- [Ciclo delle scene 3D nel renderer reale](graphics86-lifecycle.json): tre creazioni, cambi Basso/Medio/Alto/Ultra/Alto e chiusure, comprendendo il materiale facciale dettagliato. Le riaperture dell'editor sono controllate separatamente; non si confonde una prova headless con una renderizzata.
- [Partita completa renderizzata](graphics86-full-match.json): driver di test esplicito con attacchi umani al 99%, normali percorsi per CPU/battuta/ricezione/alzata; replay disattivati in questa sola prova e verificati separatamente.
- [Invarianti](graphics86-invariants.json): hash dei file protetti, identità degli stati delle catture, collisioni identiche e conservazione dei sorgenti di animazione, fisica, controlli, IA, networking e database. Tutti i test scrivono in profili isolati.

Partita completata **15–2**, 95 contatti e 31,153 frame in 232.0 secondi: frame medio 7.318 ms, p99 12.252 ms, 0 frame oltre 25 ms e 0 oltre 50 ms. Questo risultato riguarda lo scenario e il driver di test dichiarati, non ogni possibile partita.

## Stabilità dell'ambiente

[Importazione e avvio editor](graphics86-editor-tests.json): import completo, caricamento delle risorse audio e due aperture reali consecutive dell'editor Godot 4.5.1 Forward+ Vulkan superati senza crash. Ripetuto anche il controllo dei materiali del roster dopo l'ultima modifica all'atleta pilota.

Corretto e pubblicato con la 0.85 il WAV a sei canali: [diagnosi audio/editor](AUDIO_EDITOR_85.md). Il vecchio file produceva errori di importazione, ma il crash di accesso alla memoria non è stato riprodotto nel progetto minimo. Il formato non viene indicato automaticamente come causa del crash.

È presente in Windows un rapporto `Kernel_117` del 7 novembre, ore 10:52; il contenuto nella cartella WER protetta non è leggibile con i permessi disponibili, anche nel tentativo di lettura autorizzato. Secondo [Microsoft](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/bug-check-0x117---video-tdr-timeout-detected), il codice identifica un timeout del sottosistema di visualizzazione. Questo non prova quale modulo sia responsabile, né un collegamento diretto al crash dell'editor. Nessun driver, BIOS, timeout TDR, ACL o parametro di Windows viene modificato.

Nei test validi finali non vengono ignorati errori Vulkan o shader. Gli avvisi preesistenti del caricatore di immagini a runtime e il certificato non accessibile nel sandbox sono registrati separatamente. Le prove locali non dimostrano l'assenza assoluta di crash in ogni futura sessione.

## Ripristino e asset ancora necessari

Baseline completa e immutabile: `dist/v0.85.0-graphics-audio/SpikeForever-Windows.zip`, SHA256 `c67004ac25e6c01684191c9713598e10a5976e1bf00aa220c805deca2952787c`. I file grafici precedenti sono anche in `.runtime/graphics86-backup`.

Per confrontare lo stesso gioco con il percorso grafico precedente usare `Avvia Spike Forever - confronto grafica 0.85.cmd`, che aggiunge `--graphics-baseline85`. Il normale avvio usa il prototipo locale. Non vengono cambiati salvataggi o database per passare tra i due percorsi.

[Manifest dei file modificati](graphics86-files.json) · [provenienza degli asset](../assets/art/visual86/README.md) · [lista precisa degli asset necessari](GRAPHICS86_REQUIRED_ASSETS.md).

Luce, campo e presentazione sono migliorati oltre un cambio di contrasto; il pilota ha geometria e superfici verificate. Il rifacimento moderno completo di volti, capelli e pubblico **rimane parziale**: richiede anatomie e atlanti nuovi, non ulteriore rumore procedurale o semplice aumento del numero di triangoli. Non sono introdotti asset esterni senza licenza, né vengono sostituiti tutti gli atleti prima di validare il prototipo.
