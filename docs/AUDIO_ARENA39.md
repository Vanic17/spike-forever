# Audio continuo del palazzetto — v0.39

Il mix mantiene un fondo di pubblico durante la partita, invece di riavviare un breve campione a ogni servizio. Due canali ambiente alternano gli otto nuovi sfondi con crossfade a potenza costante di 2,4–3,8 secondi. Il primo ingresso è sfumato e il livello viene adattato ai LUFS misurati sulla sorgente, evitando di applicare ai nuovi file normalizzati l'attenuazione della vecchia registrazione.

I motivi ritmici hanno adesso uno sviluppo lungo. La loro programmazione è indipendente dall'inizio del punto: riposi variabili di 11–32 secondi, intensità differenti e una coda che può continuare durante lo scambio. Alcune frasi arretrano gradualmente quando comincia l'azione; altre continuano più piano o possono cominciare durante un rally prolungato. Il servizio non provoca più i tagli a 80/120 ms. Le transizioni dei motivi durano normalmente 1,3–3,8 secondi, oltre alle dissolvenze già presenti nei file. Gli intermezzi occasionali possono completare una coda attenuata durante la ripresa del gioco.

## Punti della squadra di casa e arbitraggio

`point_event(team == 0)` distingue l'esito del punto:

- Il fischio dell'arbitro accompagna il punto di entrambe le squadre. Se il nuovo gruppo `whistle_real` è disponibile, viene sempre preferito ai fischi sintetici precedenti.
- Solo un punto della squadra controllata attiva la reazione di festa, un'eventuale trombetta e un eventuale intermezzo. Le reazioni preferiscono i nuovi `crowd_long`, con ritorno progressivo al rumore del palazzetto.
- Un punto avversario annulla le feste ancora accodate e fa svanire quelle precedenti ancora udibili, compresa una trombetta già partita. Il fondo neutro continua.

Le quattro varianti di fischio sono montaggi di **un gesto reale fornito dall'utente**, non quattro registrazioni indipendenti. Le sorgenti, i processi e le misure dei 34 nuovi asset sono documentati in [AUDIO_BANK_39.md](AUDIO_BANK_39.md). La banca v38 resta disponibile per i contatti, le scarpe e i fallback.

Il bus Arena conserva il proprio riverbero e compressore; il Master non riceve effetti. L3/LS continua a silenziare tutto. I passi rimangono legati agli spostamenti. Il ritorno ai menu arresta tutti i canali e gli eventi pendenti. Il numero di riproduttori è fisso: 18 voci spaziali e 10 canali per il palazzetto. Gli inviluppi sostituiscono i tween creati a ogni evento; la programmazione usa un generatore casuale dedicato e non consuma quello del gameplay.

## Verifiche di runtime e segnale

`Test-ArenaAudio39.gd`: **PASS**. La sequenza estesa simula 837,52 secondi e 49 punti: 32 della squadra di casa e 17 avversari. Risultato: 49 fischi reali, 32 feste, 9 trombette e 6 intermezzi; 12 motivi iniziano durante gli scambi, 14 proseguono all'avvio dell'azione. La prova della frase riservata al pre-servizio verifica anche l'arretramento graduale, senza dipendere dall'estrazione casuale di una particolare partita. Picco: 6 canali simultanei e 4 inviluppi; i 28 riproduttori restano costanti. Verificati inoltre non ripetizione fra cicli, coda delle trombette, assenza di feste avversarie, pausa e ritorno ai menu.

`Test-ArenaAudio38.gd` è aggiornato all'API esplicita del punto e ai gruppi lunghi: **PASS** anche sui 54 asset precedenti e sull'isolamento del Master.

`Render-ArenaAudio39.gd` registra il **vero bus Godot** durante 35,48 secondi: fondo neutro, motivi, contatti, due punti di casa, uno avversario e un cambio di sfondo. File: `docs/arena39-mix-preview.wav`; forma d'onda: `docs/arena39-mix-waveform.png`; tempi degli eventi: `docs/audio39-render-events.json`.

Le misure sono riproducibili con `Check-ArenaMix39.py`, applicando il taglio della finestra prima dell'analizzatore LUFS. Il controllo del cambio di sfondo non rileva tratti prossimi al silenzio: il valore minimo su 100 ms è −39,25 dBFS e il maggiore calo fra due blocchi adiacenti è 1,96 dB.

| Finestra nel render | LUFS integrati | Picco dBTP |
| --- | ---: | ---: |
| Fondo neutro iniziale, 3,6–6,0 s | −30,89 | −18,36 |
| Ingresso del motivo, 6,4–8,4 s | −26,76 | −11,60 |
| Servizio e prosecuzione, 8,6–10,8 s | −24,71 | −7,36 |
| Punto della squadra di casa, 11,8–14,8 s | −20,06 | −7,94 |
| Punto avversario e arbitro, 18,9–20,6 s | −24,66 | −9,34 |
| Crossfade ambiente, 20,8–24,6 s | −34,10 | −19,45 |
| Nuovo fondo, 24,1–25,0 s | −32,02 | −20,32 |
| Registrazione completa | **−24,05** | **−5,23** |

Il fondo iniziale è circa 11 dB sotto la finestra della festa. Non c'è clipping. Il silenzio intenzionale all'ingresso e dopo il ritorno al menu è escluso dal controllo di continuità dell'ambiente. Queste sono verifiche del rendering e del segnale; non costituiscono un ascolto umano sull'impianto dell'utente.
