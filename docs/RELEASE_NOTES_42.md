# Spike Forever 0.42.0

Le bande non vengono piu richiamate sul punto di salto mentre il primo passaggio e ancora in volo. In zona 4 e zona 2 mantengono una posizione larga e arretrata, poi percorrono una rincorsa fisica con ingresso obliquo, penultimo passo e arrivo al contatto. La preparazione parte gia sulla ricezione; i limiti di velocita dei giocatori restano quelli precedenti.

## Cause e correzioni

- Il bersaglio dell'attaccante selezionato si accorciava fino a 22 cm prima dell'alzata: arrivava quasi fermo sotto la palla. `attack_run.gd` conserva la pista e gestisce l'ingresso finale senza frenare sul punto intermedio.
- La scelta del secondo tocco poteva preferire il compagno piu vicino, togliendo anche il centrale dal suo attacco. Ora ha priorita S; L lo sostituisce quando S ha ricevuto o e in difficolta. Se S ha ricevuto e L e fuori campo durante il turno di servizio di un centrale, resta possibile solo un secondo tocco d'emergenza di un altro compagno, senza violare il doppio tocco.
- Una precedenza per liberare il palleggiatore poteva trattenere il centrale sul lato sbagliato. Il centrale prepara il primo tempo davanti al palleggiatore; i compagni liberano il corridoio senza invadere la rincorsa della banda selezionata.
- Se gia vicino, il centrale usa gli ultimi passi della finta anziche arretrare per ripetere tutta la prestazione PSA. Movimento del corpo e gesto rimangono sincronizzati. Una finta rimasta bloccata non parte tardivamente mentre la banda sta gia attaccando.
- L'evitamento vedeva il corpo attuale del palleggiatore ma poteva far rientrare un compagno sul suo punto di contatto futuro. Chi sta liberando il corridoio ora conserva la frenata programmata: una correzione per evitare un altro corpo non puo aggiungere una spinta verso quel punto. Il palleggiatore continua ad aggirare i corpi reali. Il recupero basso esistente rimane disponibile sullo stesso volo della palla.
- Le correzioni delle pose cercavano ripetutamente i discendenti delle stesse 145 ossa. La gerarchia viene ora precalcolata e condivisa, con lo stesso ordine di applicazione delle rotazioni.

## Pausa

Start / Options / Esc apre la pausa. Con croce direzionale o stick si sceglie **Riprendi partita** oppure **Torna al menu principale**; Croce PlayStation / A Xbox conferma. Cerchio / B riprende la partita. Tornando al menu vengono conservate le modifiche locali al database.

## Verifica

La matrice delle rincorse comprende 96 costruzioni complete, entrambe le squadre, sei rotazioni, quattro direzioni, alzate normali e veloci. Nei 18 casi di palla alta ai laterali di prima linea, la distanza media al rilascio e 3,59 m e il percorso successivo medio e 3,78 m: viene verificato il movimento reale, oltre alle animazioni.

Il [video di prova](approach42-preview.mp4) mostra tre costruzioni attraverso il codice della partita: zona 4, zona 2 e centrale. E una cattura a passo fisso per giudicare il movimento, **non** una misura delle prestazioni.

I confronti CPU, i frame time della scena renderizzata, gli altri test e i limiti della misura sono in [PERFORMANCE_42.md](PERFORMANCE_42.md). Il parser PSA, i file delle animazioni originali, le librerie native, le rotazioni, i controlli, la fisica della palla e i parametri del timing sono conservati; il piano di apertura e la priorita dei contatti cambiano intenzionalmente. F6 e F7 mantengono il confronto dei backend e dei prototipi introdotto nella v41.
