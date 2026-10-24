# Spike Forever 0.44.0

## Primo tempo e rincorse

Il centrale prepara il gesto del primo tempo mentre il passaggio sta ancora arrivando al palleggiatore. Il destinatario di una veloce raggiungibile avvia la prestazione L-R-L prima dell'alzata. Sulle ricezioni buone la finta anticipa il salto e conserva piu passi della sorgente; non aspetta piu il tasto di conferma dell'alzata. Se il centrale e ancora lontano rimane la conversione gia esistente in palla alta, senza spostarlo istantaneamente davanti al palleggiatore.

Le gambe usano la corsa durante la rincorsa frontale anche a velocita da corsa leggera, invece di selezionare la camminata. Il blend lascia visibili gli ultimi appoggi della prestazione originale prima dello stacco. Pipe e D dell'opposto mantengono uno spazio di rincorsa prima dell'alzata e usano una sorgente di attacco frontale: i gesti da antenna avevano un ampio contatto laterale, poco adatto alla seconda linea.

Dopo il contatto, il corpo continua fisicamente in avanti verso la ricaduta: bersaglio fino a 45 cm per i laterali di prima linea e 75 cm per gli attaccanti di seconda linea, soggetto a collisioni e spazio effettivo. Non e uno spostamento del solo modello. Nei tre casi dedicati di zona 4, D e pipe, l'avanzamento nei 350 ms successivi al contatto e rispettivamente circa 25, 47 e 46 cm. I contatti della seconda linea restano dietro i tre metri; la ricaduta puo avanzare come previsto dalle regole. La velocita massima generale dei giocatori non cambia.

L'[anteprima di 20 secondi](attacks44-preview.mp4) mostra quattro costruzioni del codice reale: zona 4, opposto dietro, pipe e centrale. E una registrazione a passo fisso per guardare i movimenti, non una misura degli FPS.

## Muro

Il contatto non viene piu cercato soltanto nel frame di attraversamento della rete. Si controlla il segmento percorso dalla palla vicino alla rete contro mani e avambracci effettivi dei giocatori in salto. Un primo campione mancato non chiude piu la possibilita del contatto nei frame successivi. La risposta parte dal punto colpito e integra il tempo residuo del passo; non viene assegnato un punto a tavolino.

Le mani hanno una chiusura piu ampia entro il normale IK. Su un contatto centrale ben chiuso, un muro di qualita rimanda la palla rapidamente verso il basso nel campo dell'attaccante. Un contatto meno pieno puo lasciare una palla giocabile su uno dei due lati; un tocco esterno delle dita conserva piu velocita in avanti e produce deviazione laterale, con possibilita di mani-out. Un mani-out e tale solo quando la traiettoria finisce effettivamente fuori dopo il tocco.

La lettura corretta del muro CPU passa dal 52% al 65%. Il salto umano resta manuale e i comandi LS, Croce/A, L2/LT e R2/RT restano gli stessi. La precedente regola della fascia oro 97-100% resta attiva, compresa la finalizzazione automatica di un overpass raggiungibile.

## Meno palle di prima e attacco CPU

Si riducono gli overpass casuali della CPU e quelli delle ricezioni difficili. Un errore umano molto anticipato non manda sempre la palla direttamente dall'altra parte: nella maggior parte di questi casi resta un passaggio difficile nella propria meta campo. Il timing della ricezione e le sue finestre non cambiano.

Un attacco ordinario CPU su alzata buona richiede l'82-96,5% della potenza, indipendentemente dalla presenza del muro. Restano attacchi di sicurezza su alzate cattive e pallonetti tattici occasionali. La scelta morbida avviene una volta per azione: prima, tre candidati morbidi competevano con cinque forti anche sulle costruzioni normali, rendendo troppo frequente la conclusione lenta. Il massimo ordinario CPU resta sotto la fascia oro per non trasformare gli attacchi normali in punti garantiti.

Nel campione deterministico di 2.000 decisioni, con muro alternato assente/a due e pressione 90%, risultano 26 scelte morbide e 54 overpass CPU. Non e una percentuale promessa per ogni partita: sono dati della fixture riproducibile in `balance44-report.json`.

## Verifiche

- 96 costruzioni complete, entrambe le squadre, sei rotazioni, quattro destinazioni, normali e veloci: tre contatti reali mantenuti.
- 12 costruzioni controllate su ricezione buona: otto veloci con gesto prima dell'alzata, quattro palle alte di sicurezza per centrali inizialmente lontani. Verificata anche la finta senza conferma del tasto.
- Sei contatti di muro sullo scheletro reale: squadre speculari, attraversamento tra due campioni, campione mancato seguito da contatto, muro pieno e deviazione esterna.
- Tre sequenze dedicate a corsa, contatto legale e avanzamento reale durante la ricaduta.
- 144 sequenze con cambio attaccante; 192 sequenze con conferma anticipata/intermedia/tardiva dell'alzata.
- 20 avvicinamenti con corpi in piedi o a terra; 36 finte del centrale; 48 combinazioni del muro manuale; 288 piani e 24 movimenti di copertura.
- 12 finalizzazioni fisiche di overpass; fascia oro e recuperi mancati della v43 conservati.
- 5.233 verifiche del percorso nativo/PSA. I file PSA e le librerie native originali restano disponibili; nessun rebake delle prestazioni originali.

Il test renderizzato mantiene lo scenario di confronto delle patch precedenti: 12 giocatori e il palazzetto, RTX 5080, Forward+, 1280x720, limite 60 FPS e 600 frame dopo il riscaldamento. Sul codice finale: **60,00 FPS medi**, p95 **19,12 ms**, massimo **23,74 ms**, nessun frame sopra 25 ms. Dati in `animation42-rendered-v44-final-new.json`. Il video a passo fisso e escluso dalle misure delle prestazioni; i campioni locali non coprono ogni possibile scambio.
