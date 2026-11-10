# Rincorsa e costanza della palla — 0.99.0

## Riferimento osservato

https://www.youtube.com/watch?v=w6IevIgUfxY

Scaricata la traccia video 720p in una cartella locale esclusa dalla distribuzione e osservata per fotogrammi. Il filmato mostra: passo iniziale piccolo/lento con tronco eretto e braccia rilassate; passo di ritmo più ampio; ultimo passo lungo con caricamento delle braccia indietro; chiusura corta e risalita. Non è una ricostruzione motion capture 3D automatica da una singola vista.

## Raccordo visivo

`approach105.gd` crea una nuova preparazione delle braccia e del tronco sulla locomozione esistente. Risorsa nativa `approach105`, presente nella AnimationLibrary `native_motion105.res` insieme alle 36 clip precedenti. Apertura con braccia rilassate, caricamento progressivo durante la rincorsa vera, fusione tramite il filtro dell'alto corpo di AnimationTree e ritorno completo alla performance di attacco attorno allo stacco.

Le gambe conservano la cadenza della locomozione e il piantamento del salto già sincronizzati con il movimento reale. Nessuno spostamento aggiuntivo della radice. Nessuna modifica alle sei performance di attacco, ai loro eventi di contatto, al tempismo della rincorsa introdotto nella 0.98.0 o alle loro pose dopo il salto. Stesso raccordo con attaccanti mancini e fallback PSA. Non c'è scrittura concorrente di AnimationTree e PSA sullo scheletro finale.

## Differenze di velocità individuate

1. Il punto perfetto avviava una traiettoria sostitutiva al tentativo di ricezione: una palla riprogrammata verso il pavimento in 0,19/0,34/0,48 s, visibilmente più lenta della schiacciata. Per gli attacchi forti ora la traiettoria continua invariata fino a terra. La precedente varietà delle svirgolate resta sui servizi e sui colpi morbidi.
2. La durata richiesta dal solver dipendeva ancora dai precedenti clamp. A piena potenza ora dipende direttamente da geometria, bersaglio e carica; le vecchie durate non cambiano il risultato. La quota effettiva del contatto e la distanza da rete rimangono limiti fisici: una palla molto staccata non può diventare una diagonale corta ripidissima attraversando il nastro.
3. Nei sei gesti laterali, le quote di contatto differiscono di meno di un centimetro. Nel test a geometria equivalente le velocità sono circa 35,31–35,34 m/s, senza una variante improvvisamente debole. Testate anche le versioni mancine.

Attacco chiuso forte: obiettivo orizzontale fino a 31 m/s, minimo volo 0,145 s e verifica del nastro tramite integratore invariato. Altri attacchi fino a 28 m/s. Le cariche inferiori mantengono una progressione continua. La finestra perfetta cambia l'esito difensivo, senza ridurre la velocità iniziale.

## Primo tempo e servizio

Il primo tempo passa da 1,30–1,45 m a 1,05–1,20 m di distacco laterale dal palleggiatore secondo la distanza da rete, mantenendo il riferimento davanti alle spalle di S. La 7 mantiene la propria corsia. Verificate 12 costruzioni primo tempo/7 nelle sei rotazioni.

Sul servizio il vecchio clamp geometrico annullava molti aumenti della durata nominale. `serve_delivery105` usa la traiettoria fisica e il controllo reale del nastro, con spin basso stabile sulla float e maggiore topspin sulla battuta al salto. Nel caso misurato di 17,5 m: float 1,0763 → 1,0529 s (+2,2% velocità media); salto 0,9644 → 0,7270 s (+32,7%). Non sono percentuali fisse per ogni mira o posizione. Barra, comandi e probabilità di errore non cambiano. Una sovraccarica valida conserva il tempo proporzionalmente ridotto, correggendo la curvatura affinché superare 100% non imponga sempre un errore di rete.

## Verifiche

- `Test-Attack105`: 1791 controlli, varianti e mancinismo, pose del colpo dopo il raccordo, uscita forte, indipendenza dalla vecchia durata, punto perfetto senza riscrivere velocità, servizio reale e sovraccarico al 110%.
- Audit di 24 azioni sulle sei rotazioni, backend nativo e fallback; 12 costruzioni del centrale.
- Due peer ENet locali con il nuovo protocollo SF099-APPROACH105 e la libreria di animazioni coerente.
- Integratore, timing, risposte ordinarie del muro, database e controlli confrontati con la 0.98.0. Verificati invariati 216 file personali preesistenti. Le nuove risorse e il video di verifica sono file del gioco, non dati dei profili utente.

Report `attack105-*.json`; cattura `attack105-preview.mp4`. Nessuna pubblicazione del video YouTube di riferimento o di profili personali.
