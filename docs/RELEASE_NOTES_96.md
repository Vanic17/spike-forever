# Spike Forever 0.96.0 — Primo tempo e 7 più incisivi

- Primo tempo e 7: incremento progressivo della forza dalla carica alta, più marcato mirando in basso o lateralmente. Riduzione aggiuntiva del tempo di volo fino al 30% sui colpi corti/laterali e al 20% sui lunghi, dove la traiettoria lo consente. Mira, dispersione, finestre di timing, rischio di sovraccarico e fisica generale conservati.
- Sulle ricezioni buone, il centrale prepara un contatto più vicino al nastro: può chiudere dall'alto verso il basso senza dover trasformare un colpo corto in una parabola lenta. Il contatto resta quello realmente raggiunto dal giocatore, senza teletrasporti.
- Alzata a una mano esclusiva del primo tempo con X/A e ricezione sopra il 95%: 25% di estrazione quando il gesto è fisicamente eseguibile. Dopo un'esecuzione riuscita, la variante è esclusa per i tre primi tempi successivi della stessa squadra; poi torna il 25%. La 7 non consuma questo intervallo.
- Gesto ricostruito con braccio alto disteso, mano libera aperta, piccolo stacco e contatto sulle dita. Nuovo punto di contatto coerente per destri e mancini, libreria AnimationTree precalcolata e fallback PSA conservato.
- Il contatore viene mantenuto fra set e sostituzioni e sincronizzato online; si azzera con una nuova partita/rivincita.

Verifiche: 229 controlli dedicati, 1.000 estrazioni idonee, sei rotazioni per primo tempo e 7, cinque comandi reali da un secondo client ENet, verifica dei contatti e delle pose native/PSA. Anteprima del gesto in `docs/middle102-onehand.mp4`.

Riferimenti forniti: [primo tempo potente](https://www.youtube.com/shorts/ODSH3A1Beac), [alzata a una mano](https://www.youtube.com/shorts/oLIQM4TsErk). Animazione ricostruita, non motion capture estratto dai video.

Online: entrambi devono usare la 0.96.0. Database, personalizzazioni locali e salvataggi delle carriere non vengono riscritti dall'aggiornamento.
