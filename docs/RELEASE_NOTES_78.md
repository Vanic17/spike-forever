# Spike Forever 0.78.0

## Risalita dopo la difesa

Le nuove difese laterali della 0.77 mantenevano una risalita di quasi tre secondi e il blocco del vecchio rotolamento. Il passaggio alla postura rialzata ora termina entro circa 1,1 secondi dal contatto. La traiettoria delle piante dei piedi è continua e le articolazioni mantengono le lunghezze; l'AnimationTree conserva il blending. Anche il controller del tuffo viene liberato al termine del nuovo recupero, anziché attendere la durata del filmato originale. Le altre difese restano invariate.

## Variante di attacco

Dal riferimento `emqBnve9wd8`: corsa progressiva, ampio caricamento delle braccia all'indietro, apertura della spalla, contatto alto, chiusura del polso e seguito del colpo. Sono adattamenti autoriali dello scheletro originale, non motion capture calibrata. Due clip coprono le basi di zona 4/pipe e zona 2; il mirroring esistente gestisce correttamente i mancini.

Il gesto si aggiunge al repertorio attuale: è scelto in circa un terzo delle situazioni compatibili di banda, opposto e pipe, con palla sufficientemente buona. Non sostituisce primo tempo, pallonetti o attacchi d'emergenza.

Durante la rincorsa, il caricamento viene stratificato sulla parte alta del corpo con la maschera Spine già disponibile. I piedi mantengono la corsa reale; lo stacco, il punto di contatto e l'avanzamento in volo conservano i tempi della prestazione originale. La posa di preparazione è memorizzata per variante, mano e percorso di animazione, evitando un campionamento aggiuntivo a ogni fotogramma.

## Verifiche

- Dodici sequenze complete ricezione–alzata–attacco: banda, opposto di seconda linea e pipe; destri e mancini; AnimationTree nativo e fallback PSA. Contatti riusciti, corsa visibile, stacco dietro i tre metri per gli attaccanti di seconda linea e assenza di teletrasporti della radice.
- Pose controllate a 30/60/120/144 Hz: lunghezze degli arti, contatto preservato e risalita.
- Contatti reali delle difese laterali e rilascio del blocco di recupero a 60/120 Hz.
- Benchmark CPU su dodici avatar, due in rincorsa: circa 0,16 ms aggiuntivi nel test. Misura del lavoro animazione/skinning, non degli FPS complessivi o della GPU.
- Rapporti `attack78-gameplay.json`, `attack78-performance.json`, `recovery78-tests.json`; confronti animati `attack78-preview.mp4` e `recovery78-preview.mp4`.

Conservati controlli, regole, fisica della palla, salvataggi e database personale. Aggiornamento selettivo disponibile per i client dalla 0.76.
