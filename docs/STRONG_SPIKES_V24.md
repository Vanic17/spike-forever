# Ritocco schiacciate forti, versione 0.24

La curva precedente usava `0.72 - power * 0.24` secondi per ogni attacco. Il colpo al 100% aveva quindi 0,480 s di volo fino al bersaglio a terra. Non c'era una riduzione artificiale della potenza nel lancio da correggere.

Il ritocco interessa soltanto la parte alta della carica di una schiacciata: fra il 75% e il 100% una curva `smoothstep` sottrae progressivamente fino a 0,024 s. Un colpo al 100% arriva in 0,456 s; al 90% la riduzione è di circa 0,016 s. I colpi controllati fino al 75%, i pallonetti e le restituzioni in bagher conservano il ritmo precedente. Restano invariati carica, precisione, dispersione, fallo oltre il 100%, collisioni, gravità, integratore e decisioni dei difensori.

`tools/Test-StrongSpikes.gd` verifica la continuità della curva, l'arrivo sullo stesso bersaglio a 30/60/120 Hz e 144 confronti con i giocatori reali: 72 bersagli distribuiti fra centro, linee, corto e profondo, ripetuti a 60 e 120 Hz. Ogni confronto riparte dallo stesso stato dei dodici giocatori e dallo stesso generatore casuale. Il muro viene escluso per isolare la difesa a terra; rete, movimento, recupero e controllo effettivo del contatto restano attivi.

Nel campione, i punti diretti passano da 46 a 49 su 144. In 95 casi i difensori continuano a recuperare il nuovo attacco. La velocità orizzontale di lancio misurata cresce del 5,24%; in una traiettoria diagonale rappresentativa il tempo al contatto difensivo passa da 342,1 a 322,0 ms. Sono misure di questo campione deterministico, non una percentuale garantita durante una partita.

Risultati completi: `docs/strong-spikes-report.json`. La regressione non modifica la qualità casuale di ricezione e non assegna punti in base alla potenza: il punto continua a dipendere dalla palla e dall'arrivo del difensore.
