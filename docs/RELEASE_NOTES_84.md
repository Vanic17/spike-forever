# Spike Forever 0.84.0

## Causa degli scatti

La simulazione rimane a 120 Hz. In precedenza palla, rotazione e radici dei giocatori venivano mostrate direttamente all'ultimo tick, mentre la telecamera avanzava a ogni frame. Le pose venivano aggiornate solo se era trascorso un tick. Questo produce una cadenza discontinua quando rendering e simulazione non coincidono, anche con una GPU potente.

## Raccordo visivo

Un buffer degli ultimi due tick raccorda posizione e rotazione della palla, ombra e radici visive degli atleti. Le pose vengono valutate a ogni frame sul medesimo tempo interpolato: orologio del gesto, transizioni, passi, preparazione, bersagli delle mani e sguardo. Le correzioni dei piedi e delle mani usano la trasformazione visiva corrispondente.

Il buffer riguarda la presentazione: posizioni tattiche, velocità, fisica, RNG, tempi dei contatti, controlli e valori dei giocatori rimangono autorevoli e non vengono interpolati. La rotazione usata per integrare lo spin viene ripristinata dal tick reale prima di avanzare la simulazione. Il ritardo visivo aggiuntivo è al massimo un tick, circa 8,3 ms; non viene aggiunto un ritardo all'elaborazione dei comandi. Nessuna estrapolazione della palla oltre un contatto.

La telecamera segue la palla effettivamente disegnata. Inizio scambio e spostamenti istantanei vengono separati dai movimenti continui. Pausa, replay e scene di sostituzione mantengono il controllo esclusivo della propria presentazione. Disattivata la correzione del jitter del motore, incompatibile con questo raccordo manuale, mantenendo 120 tick al secondo ([documentazione Godot 4.5](https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html#class-projectsettings-property-physics-common-physics-jitter-fix)).

## Online

Il guest conserva il proprio buffer di rete: non viene interpolato una seconda volta dal buffer locale. Il suo tempo visualizzato ora avanza in modo monotono, correggendo gradualmente lo scarto dai pacchetti. Prima, un pacchetto con ritardo diverso poteva riportare leggermente indietro la palla. La presentazione dell'ospite viene aggiornata prima che la telecamera scelga il bersaglio. Ripristinato il rendering locale delle pose quando si lascia l'online.

## Costo e qualità

Nessuna riduzione di risoluzione, texture, ombre, pubblico o impostazioni grafiche. L'AnimationTree conserva il suo rig privato e usa la gerarchia globale già calcolata dal motore; rimane invariata la scrittura di posizione e rotazione delle ossa, senza introdurre cambi di scala. Eliminati accessi dinamici ripetuti ai campi degli avatar nel percorso di disegno. Parser PSA e fallback restano disponibili.

Prova locale con RTX 5080, Forward+, 1920×1080, VSync disattivato e FPS illimitati, fisica realmente asincrona a 120 Hz: nel caso ripetibile ricezione–alzata–pipe il 99° percentile passa da 14,49 a 13,34 ms; la media da 8,46 a 8,85 ms. Il campionamento continuo ha dunque un piccolo costo medio, mentre il risultato principale è la continuità del moto. Non è una promessa di aumento degli FPS o di eliminazione di ogni possibile stallo su ogni PC. Le registrazioni a tempo fisso sono tenute separate dai benchmark.

Rapporti: `fluidity84-performance-before.json`, `fluidity84-performance-release.json`, `fluidity84-tests.json`.

## Verifiche

- Palla veloce continua a 60, 90, 120, 144, 165, 240 e 360 FPS, senza frame ripetuti nel test di cadenza.
- Nessuna modifica di posizioni autorevoli, orologi delle azioni, tocchi o RNG durante il disegno; ripristino corretto della rotazione fisica e scala delle ossa invariata.
- Arrivi di rete irregolari: il test riproduce 39 arretramenti del vecchio orologio; il nuovo non arretra e limita la velocità di correzione.
- Regressioni di finta R2, palleggiatore, ricezione, tuffi, attacchi, servizio, collisioni esterne, replay e panchine.
- Due client reali per database, replay e sostituzioni.

Aggiornamenti selettivi mantenuti. Carriere, campionati e modifiche personali al database restano nei salvataggi locali separati dal pacchetto del gioco.
