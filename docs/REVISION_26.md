# Versione 0.26.0

## Il vuoto nella ricezione R2 e R5

Lo screenshot fornito è coerente con R2. Il palleggiatore penetra dalla seconda linea (Z6), mentre OH2 è il terzo giocatore regolamentarmente di prima linea e riceve a sinistra. S vicino alla rete non acquisisce il diritto al muro. La permutazione dei titolari è corretta: cambiare le identità per ottenere tre giocatori visivamente davanti avrebbe introdotto un errore.

La causa concreta del vuoto era nella tabella delle posizioni di ricezione: OH e L partivano entrambi a sinistra, rispettivamente x=-2,8 e x=-2,6 m, con l'altro OH a destra. Mancava il ricevitore centrale. La stessa duplicazione compariva in R5. I precedenti controlli sui falli di posizione non la rilevavano, perché una disposizione legale può comunque coprire male il campo.

In entrambe le rotazioni L ora parte da x=0, profondità 6,3 m. Sono conservati gli altri cinque punti, l'ordine dei titolari, la sostituzione del libero, il battitore e i diritti di prima/seconda linea. La penetrazione di S e l'apertura degli attaccanti avvengono con il movimento esistente. Non sono aumentate le velocità dei giocatori.

La distanza peggiore dai tre ricevitori su nove campioni della fascia centrale x=-0,75/0/0,75 e profondità 4,5/5/5,5 m scende da 2,946 a 1,950 m in R2/R5. Questo misura la copertura geometrica, senza modificare la difficoltà della battuta o garantire un recupero automatico di ogni pallone.

Riferimenti: specifica 5–1 fornita dall'utente e [regole FIVB 2025–2028, sezioni 7.4 e 7.6](https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN.pdf). L'ordine relativo al servizio e le responsabilità tattiche durante lo scambio rimangono distinti. [Audit delle sei rotazioni e delle fasi](v26-rotation-audit.md).

## Animazioni contestuali

Attivate 79 ulteriori prestazioni originali compatibili presenti nell'archivio, 127 totali, con selezione per situazione, contatti e libreria nativa condivisa. [Inventario, famiglie ed esclusioni](ANIMATION_26.md). Il parser PSA resta disponibile come fallback e tramite F6. Il movimento reale e le regole del gioco rimangono separati dalle animazioni visive.

Le alzate normale e veloce utilizzano coppie della stessa prestazione: confermare la veloce non cambia la corsia dei piedi all'ultimo istante. La selezione visiva resta fissata per il piano corrente anche quando cambia soltanto normale/veloce. I recuperi di qualità inferiore a 0,72 conservano le prestazioni corte già collaudate. Nel reset fra scambi l'attesa viene avviata prima di ripristinare le varianti: la protezione dell'atterraggio precedente non può più lasciare una vecchia posa nel punto successivo.

## Verifiche

- `Test-RotationCoverage.gd`: legalità dei piedi e copertura sinistra/centro/destra in tutte le sei rotazioni su entrambi i lati, con PSA e backend nativo; battute salto/float reali con successiva ricezione; mantenimento della corsia centrale durante il volo.
- `Test-Game.ps1`: suite completa di ricezione, alzata, attacco, muro, spazi, rotazioni, comandi Xbox/PlayStation, timing e updater.
- `Check-Revision26Scope.ps1`: conserva regole, comandi, timing, traiettorie, decisioni CPU, velocità degli atleti e tutte le sorgenti di animazione già attive.

La verifica geometrica non certifica che ogni possibile scambio futuro sia privo di problemi; aggiunge controlli sul difetto concreto che sfuggiva alle sole verifiche di legalità.
