# Revisione 12 — rigioco, spazi e gesti contestuali

Analizzato il video `Spike Forever (DEBUG) 2026-10-21 19-29-45.mp4`, con particolare attenzione alla difesa che diventa alzata e agli incroci fra compagni. La revisione interviene sui percorsi e sulle transizioni: conserva le dodici formazioni, i ruoli maschili, i comandi sullo stick sinistro, il sistema di carica, la fisica dello scambio, camera, grafica e audio.

## Posizioni e percorsi

Il problema non era limitato alle coordinate finali. Nel rigioco gli attaccanti di prima linea potevano restare nelle basi vicine alla rete fino all'inizio dell'alzata, per poi aprirsi tutti in ritardo. Inoltre, il bersaglio usato per liberare il corridoio del palleggiatore veniva ricostruito dalla posizione corrente a ogni aggiornamento: il giocatore poteva uscire, riprendere la vecchia destinazione e rientrare nel corridoio.

`court_shape.gd` organizza adesso le destinazioni dei dodici atleti prima che inizi il loro aggiornamento individuale. Il giocatore che deve toccare la palla conserva la propria posizione di contatto; gli altri ricevono spazi e percorsi compatibili con quel contatto.

- Durante una difesa o un rigioco, bande e centrale iniziano già a preparare l'attacco. Il ricevitore continua la propria azione e il palleggiatore mantiene la propria penetrazione.
- Chi deve attraversare il corridoio del contatto riceve un punto di passaggio stabile per quel volo della palla. Due compagni non ricevono lo stesso punto di aggiramento.
- Le destinazioni dei compagni vengono separate fra loro e dal giocatore che riceve o alza. Il libero mantiene la corsia assegnata, senza cambiarla attraversando il centro del campo.
- Il giocatore di prima linea esterno al muro scelto arretra in copertura del pallonetto. Restano gli uomini effettivamente assegnati al muro e un solo salto per atleta per attacco.
- Gli spostamenti ordinari mantengono più spazio fra i corpi; gli uomini del muro conservano la possibilità di chiudere vicini. Il controllo del percorso considera anche gli avambracci del bagher e l'ingombro del compagno sdraiato dopo il tuffo.
- Ridotta la deviazione laterale eccessiva durante l'aggiramento dei compagni, che poteva produrre percorsi curvi e correzioni ripetute.

Le coordinate tattiche originali rimangono in `killer_aces_positioning.json`; questa organizzazione dei percorsi viene applicata durante il movimento. Il bersaglio del contatto non viene spostato per risolvere un incrocio. Accelerazione, reazioni individuali e transizioni continuano a gestire lo spostamento effettivo.

## Battuta e continuità delle animazioni

Il lancio della battuta veniva staccato dalla mano in un istante fisso, anticipato rispetto al gesto originale. Ora la palla resta sul palmo sinistro campionato fino al rilascio del relativo filmato animato, sia nel salto potente sia nel jump float. La traiettoria del lancio raggiunge la mano destra durante la vera rincorsa; il tempo complessivo di preparazione e il contatto finale restano quelli del gioco.

Corretto anche un problema nelle transizioni fra varianti: sostituire il gesto di un giocatore poteva sostituire contemporaneamente la posa di partenza del blend. Adesso la transizione conserva il filmato precedente e la posa composta effettivamente visibile. Un gesto già oltre il contatto completa la propria fase di recupero prima di cambiare variante.

Il palleggiatore si orienta per l'alzata alla banda e usa il gesto dietro per l'opposto. La posizione delle mani e quella del corpo vengono calcolate con lo stesso orientamento.

## Otto animazioni originali aggiunte

Erano disponibili altre animazioni compatibili: non è stato necessario inventare nuovi gesti. I precedenti 22 file attivi sono conservati, per un totale di 30.

| Variante | Impiego |
|---|---|
| `attack_line` | Schiacciata con gesto lungolinea |
| `attack_left` | Schiacciata dalla banda sinistra |
| `set_back` | Alzata lunga dietro |
| `fast_set_back` | Alzata rapida dietro |
| `receive_follow` | Bagher frontale con accompagnamento |
| `receive_left_up` | Bagher laterale alto |
| `receive_right_up` | Bagher laterale alto sul lato opposto |
| `dive_short` | Recupero basso corto a una mano su palla morbida |

La scelta è individuale e contestuale; non cambia simultaneamente le animazioni di tutti i compagni. Il tuffo lungo preesistente resta disponibile sulle palle forti. Ogni nuovo file attivo viene confrontato byte per byte con il corrispondente originale estratto da Spike Volleyball. I riferimenti completi sono in `assets/active/sources.json`.

## Verifica

`Verifica.cmd` completato con asset originali e con i personaggi di ripiego:

- Asset originali: 16 punti e 121 contatti, distanza massima mani/palla 0,111 m; tutti i dodici atleti si spostano. Distanza minima fra radici dei giocatori e fra muratori: 0,806 m.
- Ripiego: 16 punti e 69 contatti, distanza massima mani/palla 0,109 m. Nessun doppio salto dello stesso muratore sul medesimo attacco.
- 840 confronti del posizionamento, 432 casi di ruolo/fase e 48 correzioni direzionali durante i gesti preparati.
- Dodici combinazioni squadra/rotazione per percorsi stabili, punti di aggiramento distinti, apertura anticipata e copertura del giocatore esterno al muro.
- Battuta verificata a 30, 60 e 120 Hz: scarto massimo rispetto al centro atteso sul palmo durante la tenuta 0,005 m. Contatto riuscito per entrambe le battute.
- Le otto varianti superano il controllo del contatto effettivo mantenendo le altezze della palla del gioco: scarto massimo 0,091 m nella prova dedicata.
- Conservati i controlli su input, carica, sovraccarico, ciclo del gioco, tuffo e rialzata, rimbalzi e rotazione della palla. Passano i 22 controlli sul mantenimento del perimetro e i 14 su grafica, camera, audio e comandi.

I controlli numerici sulle distanze non esauriscono la valutazione visiva della naturalezza. Sono stati controllati anche fotogrammi degli scambi e registrazioni del gioco aggiornato. La vista ravvicinata delle battute e del tuffo usa gli stessi metodi della partita, con una telecamera di ispezione limitata allo script di registrazione.

Log principali: `revision12-verification.log`, `CourtFlow-test.log`, `serve-variety-report.json`, `revision-contact-report.json` e `fallback-contact-report.json`. Il backup precedente è `baseline-v11`.

[Partita aggiornata, 40 secondi](Spike%20Forever%20-%20rigioco%20e%20spazi%20v12.mp4) · [Battute e tuffo, vista ravvicinata](Spike%20Forever%20-%20battute%20e%20tuffo%20v12.mp4).
