# Quindici nuove animazioni di gioco, revisione 24

Sono stati attivati **15 PSA originali prima inutilizzati**, cinque per ciascuna famiglia. La libreria condivisa `assets/active/native_all.res` comprende ora **48 clip**. Non sono alias di animazioni precedenti: il test controlla sia gli SHA256 dei file, sia che i dati di posizione/rotazione dei keyframe differiscano da tutti i vecchi clip e dagli altri nuovi. Non sono state inventate o dichiarate nuove animazioni di motion capture: sono ulteriori prestazioni presenti nell'archivio sorgente autorizzato dall'utente.

| Famiglia | Nuove prestazioni attivate |
|---|---|
| Ricezione | Bagher basso; appoggio in accosciata; passo avanti; aggiustamento laterale sinistro; aggiustamento laterale destro |
| Alzata | Palleggio corto avanti; corto dietro; salto con appoggio sinistro avanti; salto con appoggio sinistro dietro; arrivo in corsa avanti |
| Attacco | Braccio su diagonale sinistra; diagonale destra; correzione con torsione; attacco esterno sinistro angolato; attacco esterno destro angolato |

Le fonti esatte e i relativi SHA256 sono in `assets/active/new_animations_24.json`. Il catalogo `src/animation_variety.gd` seleziona la prestazione in base a scarto laterale e distanza dalla palla, velocità d'arrivo, tipo di palla in arrivo, qualità della ricezione e direzione del gioco già scelto. La scelta viene fissata per il piano corrente: accelerazione e frenata successive non cambiano ripetutamente il clip e l'offset delle mani durante l'arrivo all'alzata. Una nuova direzione o un nuovo colpo possono scegliere un'altra prestazione; il reset dello scambio cancella la scelta memorizzata. L'alternanza fra prestazioni equivalenti è deterministica e non usa il generatore casuale della fisica. Non cambia il giocatore assegnato o la scadenza del colpo. La veloce mantiene i suoi clip già calibrati.

Il movimento reale rimane separato dalla root visiva. Parser PSA, `avatar.gd`, correttivi dei piedi, IK, testa e `pose_animation_tree.gd` restano invariati. La libreria è preconvertita, condivisa, immutabile e protetta dalla firma dei keyframe. F6 e `--psa-original` mantengono il confronto con il backend originale. I due backend continuano ad avere un solo scrittore sullo scheletro visibile.

Due fonti provate durante la selezione, un palleggio statico basso e un attacco statico, sono state scartate perché la loro altezza del contatto non era compatibile con l'attuale traiettoria della palla e i limiti anatomici dell'IK. Non si sono allargate le tolleranze di contatto o deformati gli arti per includerle.

Per l'alzata corta avanti è stata scelta la prestazione con appoggio destro: quella sinistra spostava la posizione delle mani verso il volume occupato dal libero nel recupero a terra. `Test-RecoveryTraffic.gd` verifica ora la posizione effettiva della prestazione scelta, mantenendo punto di contatto, percorso, clearance e tempo originali. I quattro casi sui due lati a 60/120 Hz completano l'alzata, senza arresti bruschi: clearance minima 0,98068 m e scarto finale massimo dalla posizione prevista 0,13507 m.

## Verifica

`tools/Test-ExpandedAnimations.gd`: **96.122 controlli PASS**. Verifica le 15 fonti e l'effettiva raggiungibilità dei selettori, rig identico, finitezza delle pose, 180 contatti schedulati su due lati del campo e tre posizioni per ogni backend, parità del campionamento, lunghezza degli arti, ingresso dalla corsa e separazione della root reale. Verifica inoltre che ripetere lo stesso piano con velocità e tempi diversi mantenga clip e offset del contatto, mentre cambio di direzione, nuovo colpo e reset dello scambio possano aggiornare la prestazione.

- Scarto massimo mani-palla: **0,129154 m**, entro la tolleranza esistente di 0,18 m.
- Differenza massima native/PSA sulle nuove prestazioni: **0,00000128 m**.
- Discontinuità massima all'ingresso nella nuova azione: **0,00000170 m**.
- Variazione massima della lunghezza degli arti nei campioni: **0,0000118 m**.

`tools/Test-NativeAnimation.gd`: **3.100 controlli PASS** su tutti i 48 clip. Comprende le rotazioni, interpolazione fra chiavi, contatto, jump analitico, blending a gruppi di ossa, appoggi, commutazione F6, fallback, cache e salvataggio/ricaricamento della libreria. La deriva degli appoggi della sequenza esistente rimane 0,118194 m per entrambi i backend; non viene dichiarata eliminata.

Benchmark headless consecutivi, stessa macchina, 12 atleti, 359 campioni dopo riscaldamento; due passi a 120 Hz e una valutazione visiva per campione:

| Sequenza | CPU media | CPU percentile 95 |
|---|---:|---:|
| Versione 23 originale, 33 clip native | 10,983 ms | 14,623 ms |
| Versione 24, 48 clip native | 10,626 ms | 13,762 ms |
| Versione 24, PSA originale | 10,414 ms | 14,287 ms |

Non emerge un aumento del costo per fotogramma nella sequenza misurata; sono misure locali e non una garanzia del frame rate di ogni scambio o della GPU. La crescita del catalogo aumenta principalmente memoria e dimensione della libreria, non il numero di scheletri valutati. I report sono `animation-performance-v23-before-newclips.json`, `animation-performance-v24-native.json`, `animation-performance-v24-psa.json`, `v24-expanded-animations.json` e `native-animation-report.json`.

`tools/Capture-AnimationVariety.gd` produce un provino delle quindici prestazioni prima del contatto. Il provino statico integra le verifiche tecniche; non certifica assenza di scivolamento dei piedi in ogni possibile transizione di partita.
