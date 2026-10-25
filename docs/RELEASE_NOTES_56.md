# Spike Forever 0.56.0

## Recupero basso e animazione incongrua

Analizzata l'azione da 2:39 del video `2026-10-25 23-41-43`, in particolare la sequenza con il libero e il messaggio “Palla sporca · recupero”. Il filmato non contiene il registro degli input: mostra il comportamento, senza consentire di identificare con certezza ogni parametro interno. Il percorso corrispondente nel codice presentava due problemi riproducibili:

1. Il recupero di una palla svirgolata impostava una posa bassa, ma non avviava il movimento estratto dalla sorgente. L'avatar veniva ancora spostato dal normale inseguimento a piedi.
2. Al contatto, il recupero a una mano poteva essere sostituito da una diversa animazione sorgente, trattata come bagher a due mani per il secondo tocco.

Ora un recupero basso usa il salvataggio compatto già disponibile negli asset, orientato verso l'intercetto reale. Posizione, posa, arrivo della mano e rialzata condividono un solo orologio. Il secondo tocco mantiene la performance effettivamente utilizzata; non cambia posa durante il contatto.

Se manca ancora tempo all'inizio del gesto sorgente, il giocatore completa l'avvicinamento prima di iniziare il salvataggio. Non completa l'animazione in anticipo per poi riavvolgerla sul contatto. Restano il controllo delle collisioni, il limite anatomico e la necessità dell'input del giocatore: nessun recupero magnetico o contatto extra. Il tentativo a terra continua fino alla rialzata anche se la palla viene mancata.

Anche i tuffi anticipati verificano l'altezza della mano della variante scelta. Il tempo prima dell'inizio della sorgente viene mantenuto come avvicinamento, invece di troncarlo al fotogramma zero e far partire il gesto troppo presto.

La finestra e il gesto del normale input tardivo di ricezione restano invariati. La correzione riguarda le palle sporche da salvare con un secondo contatto. Per una palla irraggiungibile, non viene avviata una rotazione istantanea impossibile del corpo.

[Anteprima isolata del gesto e della rialzata](recovery56-preview.mp4): il movimento del soccorritore continua dopo il contatto; non è un replay della partita dell'utente.

## Preparazione del centrale

Il centrale veniva mandato troppo presto nel punto finale vicino alla rete: una scorciatoia del posizionamento eliminava la distanza necessaria agli ultimi passi. In ricezione e nella finta la preparazione passa da 1,85 a 2,35 m dalla rete. Per il primo tempo reale e la “7”, la posizione iniziale rimane staccata e si chiude progressivamente verso il punto di attacco nell'ultima parte dell'alzata.

La scorciatoia verso il punto finale entra ora solo negli ultimi 120 ms. Prima rimane una vera distanza di rincorsa. Si conservano **X/A per il primo tempo vicino** e **Quadrato/X per la 7**, i riferimenti del salto e la costruzione di sicurezza quando la palla non permette il primo tempo.

## Verifiche

- Quattro recuperi fisici della palla sporca: entrambi i lati, 60 e 120 Hz; un solo secondo tocco, movimento continuo e successivo attacco programmato.
- 24 verifiche dello spazio di preparazione del centrale, primo tempo e 7 in tutte le rotazioni e su entrambi i lati.
- 24 costruzioni complete primo tempo/7 e 72 casi della suite di primi tempi/finta: contatti conservati, 60 preparazioni già in salto al tocco di S, come nella versione precedente.
- 36 costruzioni complete della suite di intercetti, 20 scenari di traffico/giocatori a terra e 72 costruzioni pipe/dietro.
- Controllo con il renderer della sequenza avvicinamento, salvataggio e rialzata.
- Input manuale di ricezione: anticipo, perfetto, ritardo e nessun comando a 30/60/120 Hz, con le finestre originali.

Parser PSA, AnimationTree e fallback restano disponibili. Nessuna modifica a regole, potenza, barre o controlli. Versione richiesta per entrambi i giocatori online: **0.56.0**. L'installer conserva roster, comandi e preferenze locali.
