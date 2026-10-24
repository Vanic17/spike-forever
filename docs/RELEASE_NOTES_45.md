# Spike Forever 0.45.0 — Divise SuperLega

Le maglie a tinta unita sono sostituite da texture delle squadre sulle coordinate del modello originale. Sono disponibili **32 varianti per le 12 squadre**: 24 casa/trasferta e 8 divise dedicate al libero. La scelta Casa/Trasferta nel menu Gioca determina il completo utilizzato in partita.

| Squadra | Casa | Trasferta | Libero |
|---|---|---|---|
| Allianz Milano | Bianco | Nero | Divisa opposta |
| Cisterna Volley | Viola | Bianco/azzurro | Rosso |
| Cucine Lube Civitanova | Nero | Rosso | Giallo |
| Acqua Sant’Anna Cuneo | Blu navy | Azzurro ghiaccio | Arancione |
| Gas Sales Bluenergy Piacenza | Rosso | Bianco | Navy/arancione |
| Itas Trentino | Bianco | Blu navy | Rosso |
| Pallavolo Padova | Nero | Bianco | Verde |
| Rana Verona | Blu | Giallo | Bianco/giallo |
| Sir Susa Scai Perugia | Nero | Rosso | Divisa opposta |
| Tinet Prata di Pordenone | Blu/ciano | Bianco | Divisa opposta |
| Valsa Group Modena | Giallo | Blu navy | Verde scuro |
| Vero Volley Monza | Blu | Bianco | Divisa opposta |

Nome completo e numero vengono stampati sul dorso con contrasto chiaro/scuro. Il testo segue la deformazione della maglia e non è più un’etichetta sospesa. Viene utilizzato il nome modificabile nel database locale; non sono conservati i numeri dei modelli fotografati. I cambi del libero applicano identità e completo corretti. Le modifiche personali e le formazioni rimangono in `user://roster-overrides.json`, fuori dal pacchetto degli aggiornamenti.

## Riferimenti e ricostruzioni

La priorità è l’archivio **Maglie.7z** fornito dall’utente, inclusi i file rinominati Casa/Trasferta/Libero. Le immagini non sono tutte della stessa stagione: Milano riporta 2025/26, Perugia Supercoppa 2025/26. Questi disegni sono conservati intenzionalmente. Non sono sostituiti automaticamente dalle immagini attuali della Lega.

Sono state scaricate 24 immagini dei completi dalla sezione [Divise gara della Lega](https://www.legavolley.it/divise-gara/) e dalle pagine delle squadre, tra cui [Cuneo](https://www.legavolley.it/team/6863). Servono a verificare pantaloncini, colori e abbinamenti. [Trentino](https://www.trentinovolley.it/it/news-superlega/stagione-2026-27-ecco-le-nuove-divise-realizzate-da-errea-sport/) conferma bianco, blu e rosso; il [produttore di Perugia](https://www.piuadrenalina.com/en/merchandising-sir-safety-perugia/) distingue pantaloncini Supercoppa neri e rossi.

**I retro senza una foto verificabile sono ricostruzioni credibili**, con motivi della famiglia grafica della maglia, inserti, cuciture, nome e numero. Non sono presentati come riproduzioni fotografiche identiche. Per Cisterna sono ripresi anche GRUPPO GESA e XGO visibili sul retro nel riferimento. I pantaloncini del libero e quelli Supercoppa di Perugia sono ricostruiti quando non documentati. Non vengono inventati elenchi di sponsor sul retro. Le scritte molto piccole nelle fotografie e nelle ricostruzioni possono differire dal marchio originale.

Le foto indossate o in prospettiva sono state ricostruite in 16 tavole frontali con lo strumento integrato `image_gen`; gli altri frontali utilizzano direttamente i riferimenti forniti. Le tavole sono in [assets/art/kits45](../assets/art/kits45/), con [prompt e provenienza](kits45-imagegen-prompts.json), [fonti ufficiali](kits45-reference-sources.json) e [risultato dei tentativi sui pantaloncini Perugia](kits45-extra-sources.json). Gli URL del produttore che restituiscono HTML non sono stati inclusi come immagini.

## Anteprime nel motore 3D

Ogni immagine mostra casa, trasferta e libero, davanti e dietro. Per le quattro squadre senza completo dedicato il libero mostrato usa la trasferta, come accade scegliendo Casa. Scegliendo Trasferta userà Casa.

- [Milano](kits45-allianz-milano.png), [Cisterna](kits45-cisterna-volley.png), [Lube](kits45-cucine-lube-civitanova.png), [Cuneo](kits45-acqua-santanna-cuneo.png).
- [Piacenza](kits45-gas-sales-bluenergy-piacenza.png), [Trento](kits45-itas-trentino.png), [Padova](kits45-pallavolo-padova.png), [Verona](kits45-rana-verona.png).
- [Perugia](kits45-sir-susa-scai-perugia.png), [Prata](kits45-tinet-prata-di-pordenone.png), [Modena](kits45-valsa-group-modena.png), [Monza](kits45-vero-volley-monza.png).

## Implementazione e verifica

`tools/Build-Kits45.py` proietta i frontali sulle UV originali del PSK e prepara atlanti 2048×2048 con bordi di filtraggio. Richiede Pillow e NumPy soltanto per rigenerare gli asset; il gioco non usa Python. `src/club_kits.gd` carica solo le divise utilizzate, con cache condivisa dei tessuti e piccole texture 512×512 per i nomi/numeri. La stampa è renderizzata una sola volta, non a ogni frame. Verificare `DisplayServer` reale per le prove visive: headless non rende i SubViewport.

Viene aggiunto un canale UV2 alla mesh visuale; posizioni, indici, pesi, ossa e UV originali restano identici. La serializzazione del motore arrotonda normali/tangenti entro 0,001 (delta misurati 0,000127 e 0,000109). Il PSK e la libreria delle animazioni originali non sono modificati. Regole, controlli, timing, fisica della palla e IA restano quelli della v44.

- `Test-Kits45.gd`: 12 squadre, 32 texture, hash e risoluzione; inversione libero; preservazione della mesh; nomi modificati e cache.
- `Test-KitMatch45.gd`: **144 combinazioni** squadra/divisa/rotazione per entrambe le squadre, identità e libero corretti.
- `Test-Clubs.gd`: menu/controller, formazione, scelta squadre e divise, set decisivo e musica.
- `Test-NativeAnimation.gd`: 5233 controlli superati; libreria originale SHA-256 `8b43cc903cfad4aaaa674ce51f2e7b638c4fedb4d4502eb8752a9bf64f470186`, PSK della divisa `a6b1e4e70866f46df734c9d970f0e3e52ca0de13aca0da1e0151422602a76f92`.
- Anteprime 3D di tutte le 12 squadre con il renderer reale.
- [Divise durante uno scambio reale nel motore](kits45-match.png).
- `Benchmark-Kits45.gd`: stesso scambio con 12 giocatori, RTX 5080, Forward+, 1280×720, limite 60 FPS, 600 frame misurati dopo 120 di riscaldamento. Riferimento: **59,998 FPS**, p95 19,677 ms; divise attive: **60,000 FPS**, p95 20,556 ms. Entrambi hanno un frame oltre 25 ms e nessuno oltre 50 ms. È una misura locale di uno scenario ripetibile, non una garanzia per ogni macchina o partita. [Riferimento](animation42-rendered-v45-plain-new.json), [divise attive](animation42-rendered-v45-kits-new.json).

Pubblicazione: pacchetto Windows completo con manifest SHA-256 e sorgenti, aggiornamento dalla v44 e versioni precedenti conservate.
