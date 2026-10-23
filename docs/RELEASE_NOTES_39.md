# Atmosfera continua e reazioni del pubblico di casa

L'audio del palazzetto continua tra battuta, scambio e pausa, invece di essere avviato e troncato a ogni cambio di fase. Le precedenti dissolvenze di 80–120 millisecondi sono sostituite da ingressi, code e sovrapposizioni di più secondi. Il fondo del pubblico usa due canali alternati, mentre ritmi e intermezzi hanno una propria successione con pause e intensità variabili.

Gli applausi e i tamburi possono accompagnare anche alcuni scambi, a volume contenuto, senza essere riprodotti obbligatoriamente dopo ogni punto. Le frasi hanno sviluppo, pause interne e variazioni di esecuzione; la scelta casuale esaurisce ogni gruppo prima di ripetere le tracce, evitando anche ripetizioni immediate al cambio del ciclo.

Esultanze del pubblico, trombette e intermezzi del punto partono soltanto quando segna la squadra di casa, ossia la prima squadra nella preparazione della partita. Ai punti avversari rimangono il fischio arbitrale e il fondo del palazzetto; eventuali code dell'esultanza precedente sfumano. Anche la reazione visiva degli spalti è riservata al punto di casa. Le scarpe continuano a seguire gli spostamenti reali e i contatti della palla restano distinti dal sottofondo.

Il file fornito `whislte.mp4` è stato analizzato per isolare il fischio effettivo, escludendo l'audio estraneo iniziale e un clic precedente al soffio. Le nuove varianti registrate hanno precedenza sui fischi sintetizzati della versione precedente. Nuove frasi e sottofondi sono costruiti con frammenti dei file originali e componenti procedurali dichiarate, con tagli sovrapposti, inviluppi e code morbide. [Sorgenti, lavorazione e verifiche](AUDIO_ARENA39.md).

La nuova banca contiene 34 Ogg: otto sottofondi da 24–32 secondi, dodici frasi ritmiche da 24–34 secondi, sei intermezzi da 10,5–15 secondi, quattro varianti dell'unico fischio registrato e quattro reazioni del pubblico da 6,5–8 secondi, con rientro graduale nel rumore del palazzetto. Complessivamente sono circa 11 minuti e 8 secondi di materiale, oltre alla banca precedente conservata. La provenienza, le componenti sintetizzate, le durate, gli hash e i livelli sono registrati in `assets/audio/arena39/manifest.json` e descritti nella [banca audio](AUDIO_BANK_39.md).

L3 su PlayStation / clic LS su Xbox mantiene il controllo su tutto l'audio, inclusa la musica dei menu. Riverbero e compressione del palazzetto restano sul solo bus Arena.

## Campo e interfaccia

Rimosso completamente il riquadro centrale dopo un punto ordinario: il tabellone si aggiorna e il campo rimane visibile. Restano separati i risultati di set e partita, che ora mostrano il risultato effettivo senza recuperare un vecchio messaggio di gioco.

Il terreno usa un beige più scuro e meno saturo e un blu più profondo, seguendo la fotografia di riferimento. Sono modificati soltanto i materiali delle superfici, conservando illuminazione, giocatori, sponsor e geometria del campo.

## Verifiche

Controlli sull'integrazione reale dell'assegnazione del punto per entrambe le squadre, sull'unicità degli eventi, sul disegno del HUD e sulla conservazione del tabellone. Verifiche delle code, delle sovrapposizioni, della successione casuale e dei limiti di canali su una sequenza estesa di partita; controllo dei nuovi stream effettivamente decodificati e dei livelli del mix registrato da Godot. Regressioni su mute globale, menu e preparazione della partita, sponsor e attacchi automatici sulle ricezioni avversarie che oltrepassano la rete.

La sequenza audio automatica copre quasi 14 minuti e 49 punti: 32 punti di casa producono 32 esultanze, i 17 punti avversari nessuna. Fischio reale su tutti i 49 punti. Il mix registrato dal vero bus Godot dura 35,48 secondi, misura −24,05 LUFS e −5,23 dBTP e non presenta intervalli quasi muti nelle finestre di passaggio al servizio o tra i due sottofondi.

Le anteprime in `docs/arena39-tv-preview.png` e `docs/arena39-point-preview.png` mostrano il terreno aggiornato e l'assenza del riquadro ai punti ordinari. Le prove audio verificano il segnale e i livelli; l'ascolto sul proprio impianto rimane il riferimento per il bilanciamento percepito.
