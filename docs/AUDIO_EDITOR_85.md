# Audio e avvio dell'editor — verifica 0.85.0

## Problema accertato e correzione

Il file `assets/audio/crowd.wav` era un RIFF integro, PCM16, 48 kHz, **sei canali**, lungo 90,320625 secondi. Il payload e la lunghezza dichiarata coincidevano; la decodifica completa con FFmpeg riusciva. Non era quindi un file troncato: il numero di canali era incompatibile con il caricatore WAV di Godot 4.5.1.

Il file è stato convertito in **PCM16 stereo, 48 kHz**, conservando tutti i 4.335.390 frame e la durata. L'originale resta recuperabile nella baseline 0.84.0 e nella copia locale `.runtime/audio85-backup/crowd-6ch.wav`. Il percorso resta identico e l'editor rigenera la propria cache `.sample`; nessun riferimento hardcoded alla cache viene distribuito.

`src/match_audio.gd` usa già `crowd.ogg` come ambiente legacy: quel file e la logica audio durante il gioco sono invariati. Non vengono modificati gameplay o animazioni.

La verifica comprende gli header dei 29 WAV e la decodifica completa di tutti i 136 WAV/OGG/MP3 distribuiti. Nessun errore di decodifica. Il packaging ora controlla i WAV prima di creare l'archivio, impedendo di reintrodurre questa incompatibilità.

Fonti tecniche: [caricatore WAV della versione 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/scene/resources/audio_stream_wav.cpp), [importatore](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/import/resource_importer_wav.cpp), [formati audio supportati](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_audio_samples.html).

## Crash: cosa sappiamo

Lo screenshot mostra un accesso non valido alla memoria. Da quel solo indirizzo non si può attribuire la causa ad audio, GPU, shader o script.

In un progetto minimo isolato, il **vecchio WAV a sei canali** riproduce gli errori “not stereo or mono”, “Can't save empty resource” e il successivo errore MD5. L'importazione termina, senza riprodurre il crash dello screenshot. Il codice del motore protegge il salvataggio di una risorsa nulla: [ResourceSaver 4.5.1](https://github.com/godotengine/godot/blob/4.5.1-stable/core/io/resource_saver.cpp). La correzione elimina questi errori, ma non viene dichiarata una cura dimostrata per tutti i crash dell'editor.

Nei dati accessibili non è presente un dump corrispondente al crash segnalato. È disponibile un dump del 24 ottobre: riporta `0xc0000094` (divisione intera per zero), nel modulo Godot, quindi un'eccezione diversa dall'accesso alla memoria mostrato oggi. Non viene usato per diagnosticare il nuovo episodio.

Configurazione rilevata: Godot 4.5.1, RTX 5080, driver NVIDIA 621.01. La capacità della scheda non esclude un difetto del motore o del driver; non abbiamo però evidenza sufficiente per attribuirle il problema. Nessun driver viene installato, nessun renderer viene sostituito e nessun preset viene abbassato automaticamente.

Le prove diagnostiche usano profili separati. La cartella locale `dist` viene esclusa dalla scansione dell'editor con `.gdignore`, evitando di indicizzare vecchie copie di progetto; questo non modifica le risorse del gioco.

## Risultati e riproducibilità

- [Validazione e decodifica audio](audio85-validation.json).
- [Risorse importate e durata dello stream Godot](audio85-import-tests.json).
- [Diagnostica degli avvii](audio85-startup-tests.json).
- Confronti, benchmark e regressioni dell'upgrade grafico: [rapporto grafico](GRAPHICS_UPGRADE_85.md).

Per ripetere i controlli: `tools/Check-Audio85.py --decode-all`, avvio editor con `--import`, quindi `--headless --script tools/Test-Imports85.gd`. I file `.import`, `.godot` e i dump personali non sono inclusi nel pacchetto pubblico. Un avviso sul certificato di sistema compare nel sandbox dei test anche con un progetto vuoto e viene distinto dagli errori audio, shader e risorse mancanti.
