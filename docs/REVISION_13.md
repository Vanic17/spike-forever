# Revisione 13 — muro manuale e battuta al salto

## Muro a due

Il comando precedente era disponibile soltanto dopo l'alzata avversaria. Spostava il compagno verso una coordinata assoluta, mentre il primo muratore seguiva un altro bersaglio: era facile ritrovarsi con due uomini lontani. Il salto richiedeva inoltre di arrivare entro 14 cm dalla posizione prevista e poteva essere ritardato dal movimento.

Ora lo stick sinistro sceglie **la zona della coppia**: sinistra, avanti per il centro, destra. Funziona già nelle fasi `CPU_RECEIVE` e `CPU_SET`, oltre che durante l'attacco avversario. La scelta rimane dopo il rilascio dello stick; il centrale chiude accanto al compagno della zona scelta. I due bersagli sono separati da 90 cm e ordinati per evitare incroci. Il terzo giocatore di prima linea aspetta nella propria corsia sotto rete durante la costruzione e copre quando parte l'attacco.

Croce / X avvia i salti alla pressione, dalle posizioni effettive. Non viene richiesto l'arrivo esatto al bersaglio. Un salto anticipato durante l'alzata appartiene già all'attacco successivo: il cambio di fase non lo cancella e non fa saltare nuovamente i giocatori. Eliminato il tentativo automatico ritardato dopo la pressione. Il muro CPU conserva la propria lettura automatica; la modalità dimostrativa resta automatica.

Corretto anche l'aggiramento fra i due muratori: la deviazione laterale generica poteva impedire loro di completare una chiusura vicina. Restano le collisioni e le distanze fra corpi. La frenata della coppia comandata evita di superare il bersaglio e correggersi ripetutamente.

## Seconda battuta del video precedente

Ricontrollata la sequenza della battuta potente. La palla seguiva il ritorno all'indietro del braccio sinistro, passava dietro il corpo e veniva rilasciata tardi; controllare soltanto il contatto finale non rilevava questo difetto visivo.

La mano di lancio ora usa una breve correzione anatomica: abbassamento davanti al corpo, spinta verso l'alto e accompagnamento. Il rilascio avviene prima, a 1,43 secondi del filmato originale. La palla prosegue con una parabola a gravità costante fino alla mano destra durante la rincorsa: al contatto sta scendendo. Il braccio torna gradualmente al gesto originale dopo il lancio. Le lunghezze delle braccia, la rincorsa, il salto e la fisica della palla dopo il servizio sono conservati. La float non riceve questa modifica procedurale.

## Verifiche

- Suite `Verifica.cmd` superata: 16 punti con asset originali e 16 di ripiego; rispettivamente 115 e 69 contatti. Nessun doppio salto sullo stesso attacco. Scarto massimo mani/palla 0,103 m e 0,109 m.
- `Test-ManualWall.gd`: 36 casi su sei rotazioni, tre direzioni, 60 e 120 Hz. Controllati chiusura effettiva dei due giocatori, scelta prima dell'alzata, assenza di salti automatici, pressione anticipata conservata dopo l'alzata e pressione successiva lontano dalla coordinata esatta. Controllati anche cambi di direzione ripetuti nella stessa costruzione avversaria.
- `Test-ServeAndVariety.gd`: entrambe le battute a 30/60/120 Hz, palla sulla mano durante la tenuta, lancio potente davanti al corpo e velocità verticale negativa al contatto. Restano i controlli delle otto varianti.
- Conservati test delle formazioni, ruoli, movimento, tuffo e rialzata, input e barre di carica; 19 controlli sul perimetro e 14 su camera, grafica, audio e stick sinistro. I controlli aggiornati consentono le modifiche richieste al muro e al relativo suggerimento a schermo.
- Registrazioni a 60 fps controllate visivamente e decodificate per intero. La prova del muro è una scena di ispezione dei comandi e dei movimenti reali del gioco, con tre chiusure e pressioni di X; non è una registrazione di uno scambio. Il pallone viene nascosto in questa sola prova per mostrare chiaramente il muro. La vista della battuta usa invece il servizio reale completo e il recupero in tuffo.

Backup: `baseline-v12`. Log: `revision13-verification.log`, `ManualWall-test.log`, `revision13-wall-capture.log`, `revision13-close-capture.log`.

[Muro manuale: tre zone e salto comandato](Spike%20Forever%20-%20muro%20manuale%20v13.mp4) · [Battuta corretta e tuffo](Spike%20Forever%20-%20battuta%20corretta%20v13.mp4).
