# Libreria atleti Blender ? archivio di una revisione respinta

Le revisioni 91 e 92 sono state ritirate dopo il riscontro visivo negativo.
I quattro punti di integrazione sono stati ripristinati dalla versione 0.90.0.
I launcher sperimentali mostrano un avviso e non caricano pi? i modelli.

Avviare il gioco con `Avvia Spike Forever.cmd`. Questi file conservano
la documentazione tecnica del tentativo: non attestano qualit? estetica
n? completamento dell'upgrade richiesto. Nessuna pubblicazione remota.

Il file `.blend` è in `assets/art/blender91/source`.
La cartella sorgente contiene `.gdignore`: l'editor non tenta di importare
automaticamente l'intera libreria di lavorazione. Il gioco usa le mesh native.

## Pipeline ripetibile

Eseguire `tools/Build-Athletes91.ps1` con Blender 5.2 installato. L'esportatore
Godot trasferisce mesh, UV, pesi e i 115 riferimenti originali delle ossa. Blender
realizza scultura, bake della pelle, grooms tridimensionali, vestibilità e LOD;
l'importatore genera ArrayMesh native compresse. La libreria diventa disponibile
solo dopo la verifica delle 169 identità. Un'installazione incompleta mantiene
i modelli originali. Nessun componente modifica le pose a ogni frame.

La pipeline conserva il database e i salvataggi originali. Il manifesto iniziale
include i dati base e le modifiche personali presenti al momento dell'audit;
il renderer continua a leggere le successive modifiche dal sistema esistente.
Le varianti aggiunte per i dettagli mancanti sono deterministiche. Non sono
scansioni dei volti reali degli atleti.

## Verifiche

- `blender91-identity-validation.json`: trasferimento degli attributi e risorse.
- `blender91-validation.json`: binding, pose, identità e riduzione geometrica.
- `blender91-protected-validation.json`: codice, database e salvataggi protetti.
- `blender91-comparison-validation.json`: identità di camera e pose delle catture.
- `blender91-performance-*.json`: misure locali, fixture e limiti dichiarati.

La qualità Bassa riduce realmente i triangoli e le fibre, disattiva normali e
subsurface dei nuovi atleti. Le risorse sono condivise; nessuna generazione di
geometria o lettura dei JSON è eseguita durante il movimento.

Licenze e provenienza: `assets/art/blender91/ATTRIBUTION.md`.
