# Animazioni native complete, revisione 18

I 33 clip attivi sono convertiti in AnimationLibrary e vengono valutati attraverso AnimationTree. Sono inclusi attese, camminata, corsa, passi laterali e incrociati, ricezioni e varianti, alzate avanti/dietro, attacchi e finta del centrale, muro, servizi e recuperi/tuffi. Il percorso completo e ora quello predefinito; F6 alterna i due sistemi durante la partita e `-- --psa-original` forza il percorso PSA all'avvio.

`tools/Convert-PsaAnimations.gd` genera `assets/active/native_all.res`. La libreria viene condivisa fra i dodici avatar. Una firma dei keyframe, della gerarchia e dei parametri di normalizzazione controlla che la libreria corrisponda ai PSA; se non corrisponde viene ricostruita. Il parser originale non viene eliminato: gestisce inoltre clip aggiunti o non convertiti e le gerarchie incompatibili conservano il fallback.

La traslazione orizzontale della root resta normalizzata. L'arco verticale aggiuntivo usato dal gioco nei salti non viene approssimato con keyframe: viene rimosso nella conversione e riapplicato analiticamente al tempo originale. Questo evita differenze di altezza delle mani fra due keyframe, specialmente al contatto con la palla. Nessuna traccia modifica il nodo del giocatore, la scala, il tempo di gioco o gli eventi.

AnimationTree valuta clip immutabili su uno scheletro privato senza mesh. Avatar rimane l'unico scrittore sullo scheletro visibile. La composizione delle pose gia corrette usa maschere per busto e parte inferiore in spazio locale sulla CPU; non si introducono risorse Animation dinamiche o riscritture di tracce per simulare un blending. Gli appoggi, IK, testa, correzioni dei servizi e contatti continuano ad applicarsi dopo il campionamento. Il profilo piu dolce per il busto copre ora tutte le animazioni cicliche; le azioni con contatto mantengono la propria curva di transizione.

Una cache limitata al singolo aggiornamento visivo evita di rivalutare lo stesso clip/tempo. Le copie separate delle pose impediscono a IK e correzioni procedurali di alterare i campioni memorizzati. Il limite di dodici campioni evita accumuli durante le ricerche di fase dei passi.

## Verifica

`Test-NativeAnimation.gd`: **2695 controlli PASS**, inclusi tutti i clip, campionamento fra keyframe e al contatto, rotazioni, orientamento/scala, normalizzazione della root, maschere, passaggio F6, piedi, fallback personalizzato e round-trip della libreria.

- Errore massimo di campionamento: 0,00000579 m.
- Differenza massima passando fra backend sulla stessa posa: 0,00000120 m.
- Deriva massima degli appoggi nella sequenza: 0,11819414 m con il nuovo backend e 0,11819403 m con PSA. La deriva preesistente non viene presentata come eliminata.
- AvatarMotion PASS anche con il nuovo percorso predefinito: continuita dei giunti, lunghezza degli arti, tuffo/rialzata e spostamento reale dei servizi.

Prima di attivare il nuovo percorso sono state confrontate sequenzialmente le stesse 359 pose della partita completa con dodici giocatori, dopo 45 fotogrammi di riscaldamento. Due passi di simulazione a 120 Hz e una valutazione visiva per fotogramma. Grafica invariata; VSync disattivato esclusivamente per il benchmark.

| Render Windows, 2560 x 1352 | PSA | AnimationTree, 33 clip |
|---|---:|---:|
| CPU media simulazione e pose | 9,543 ms | 9,785 ms |
| Intervallo mediano fra fotogrammi | 10,552 ms | 11,097 ms |
| Intervallo percentile 95 | 13,573 ms | 14,161 ms |

Il costo aggiuntivo nella sequenza misurata e 0,242 ms di CPU media e 0,588 ms al percentile 95 del fotogramma. Questa misura riguarda la sequenza testata, non garantisce il frame rate dell'intera partita. I report originali sono `animation-performance-v18-rendered-psa.json` e `animation-performance-v18-rendered-native.json`. I report headless corrispondenti sono `animation-performance-v18-psa.json` e `animation-performance-v18-full-native.json`.
