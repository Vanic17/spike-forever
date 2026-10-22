# Correzione prestazioni 17.1

La revisione 17 aveva attivato il percorso sperimentale per tutti i giocatori. Nel blending venivano riscritte 290 chiavi di un'Animation per ciascuna operazione; i cambi delle risorse invalidavano le cache del mixer. Le pose venivano poi scritte su uno scheletro privato e rilette, più volte per giocatore e fotogramma. Il costo del singolo avatar non era una validazione sufficiente delle prestazioni della partita completa.

Il video utente del 22 ottobre alle 01:17:39 è stato letto ed estratto in `lag-user-sheet.jpg`: durata 13,68 s, acquisizione 59,94 fps. L'inizio è in pausa e la parte finale mostra il gioco attivo. La frequenza del file di acquisizione non rappresenta gli FPS effettivi del gioco.

## Correzione

- Avvio predefinito sul percorso PSA originale, senza istanziare AnimationTree, librerie convertite o scheletri di valutazione.
- Il backend sperimentale viene creato soltanto quando richiesto con F6 oppure `-- --animation-tree`. `-- --psa-original` forza il percorso precedente.
- Rimosse le Animation di posa dinamiche e tutte le scritture alle chiavi durante il blending. Il tree valuta esclusivamente clip nativi immutabili.
- Le pose già corrette e il blending stratificato vengono interpolati direttamente in spazio locale, con maschere delle ossa precalcolate. Questa parte ora è una composizione CPU, non un Blend2 di risorse riscritte ogni frame.
- Restano conversione PSA, AnimationLibrary, fallback, confronto, IK, piedi, testa e sincronizzazione dei contatti. Il solo scrittore dello scheletro visibile rimane Avatar.
- Nessuna riduzione di qualità grafica, risoluzione, frequenza della fisica, gameplay, controlli o IA tattica.

## Verifica

`Test-AnimationPerformance.gd` misura una sequenza identica dell'intera partita con dodici giocatori: 45 fotogrammi di riscaldamento e 359 campioni, due passi di simulazione a 120 Hz e una posa visiva per fotogramma. Misura separatamente CPU della simulazione/pose e intervallo tra callback. I campioni headless non sono FPS GPU né una promessa del frame rate sul monitor.

Prima della correzione: CPU media 12,37 ms, percentile 95 a 17,71 ms; intervallo mediano tra callback 25,61 ms, percentile 95 a 45,36 ms. Report originale: `animation-performance-before.json`.

Dopo la correzione, stessa sequenza headless:

| Modalità | CPU media | Intervallo mediano | Intervallo p95 | Scheletri aggiuntivi |
|---|---:|---:|---:|---:|
| Predefinita PSA | 10,23 ms | 10,20 ms | 13,47 ms | 0 |
| AnimationTree ottimizzato | 10,21 ms | 10,40 ms | 13,42 ms | 12 |

Nella prova **renderizzata su Windows a 2560×1352**, con grafica invariata e VSync disattivato per misurare il costo:

| Modalità | CPU media | Fotogramma mediano | Fotogramma p95 |
|---|---:|---:|---:|
| Predefinita PSA | 10,07 ms | 11,11 ms | 14,12 ms |
| AnimationTree ottimizzato | 10,55 ms | 11,79 ms | 14,77 ms |

Il fotogramma mediano della modalità predefinita corrisponde a circa 90 fps nella sequenza misurata; questo non è una misura dell'intera partita. Non è stato modificato il VSync del progetto: il flag riguarda esclusivamente la prova. Report: `animation-performance-default.json`, `animation-performance-native.json`, `animation-performance-rendered-default.json`, `animation-performance-rendered-native.json`.

I test dedicati confrontano campionamento, maschere, appoggi e contatti fra i due backend. Il test prestazioni controlla inoltre che l'avvio PSA non istanzi alcuno scheletro di valutazione. Il test di blending verifica che non vengano più rivalutati gli scheletri privati durante la composizione delle pose.

Esito: suite completa PASS (`lag-regression.log`), 977 controlli dedicati PASS, 128 verifiche di ambito PASS. La simulazione principale conserva 16 punti, 122 contatti e gap massimo mano-palla di 0,1064 m. Anche la simulazione dei recuperi, con 59 contatti, passa. Le prove renderizzate e i benchmark terminano senza errori di script.

Il resoconto della revisione 17 descrive l'implementazione precedente; il presente documento lo sostituisce per backend di blending e modalità di avvio.
