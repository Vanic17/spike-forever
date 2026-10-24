# Spike Forever 0.47.0

## Muro

La lettura della CPU passa dal 65% al 70% e il limite inferiore della qualità del suo muro da 0,45 a 0,50. Posizionamento e comandi del muro umano sono conservati.

Il rimbalzo dipende ancora dal contatto effettivo con mani e avambracci, dalla chiusura e dal bordo colpito. La variazione delle superfici di contatto produce smorzate, palloni alti da rigiocare, ricadute basse, deviazioni laterali, passaggi tra le dita e mani fuori. I tocchi ben chiusi spingono la palla più rapidamente verso il pavimento vicino alla rete, invece di rimandarla lunga verso i difensori. Non viene assegnato un punto artificiale al muro: il pallone deve cadere realmente.

Resta la regola preesistente dei colpi vincenti nella fascia d'oro. Un contatto debole o sulle dita non diventa un monster block soltanto per aggiungere varietà.

## Pallonetto

La rincorsa memorizzava il bersaglio della schiacciata e continuava a usarlo anche quando la scelta del pallonetto cambiava altezza e posizione del contatto. Ora il percorso segue la nuova intercettazione senza riavviare la rincorsa di un giocatore già in stacco. Mira, carica e animazioni di polso rimangono quelle del pallonetto.

## Battuta e secondo tocco

- Prima della carica, levetta sinistra per spostare il battitore lateralmente o in profondità, sempre fuori dal campo e nella larghezza della zona di servizio. Durante la carica la stessa levetta torna a gestire la mira. Valido anche con controller Xbox e telecamera laterale.
- Se la rincorsa dell'animazione porterebbe allo stacco oltre la linea di fondo, il battitore arretra realmente prima del lancio; il contatto rimane sincronizzato con mano e pallone. Si può rientrare in campo in volo dopo lo stacco.
- Il palleggiatore mantiene la priorità anche quando una ricezione richiede il piccolo prolungamento già previsto del primo passaggio. Il libero subentra se S ha ricevuto o se è davvero in difficoltà e L può arrivare con un vantaggio significativo.

## Aspetto

Dieci acconciature distinte più testa rasata, due barbe, sei colori dei capelli e più tonalità di carnagione. Sono mesh originali applicate allo scheletro: non si ingrandiscono i capelli attorno all'origine del personaggio, difetto che poteva staccarli dalla testa. Mesh e materiali sono condivisi in cache.

167 profili del database sono stati rivisti indicativamente dalle foto delle pagine ufficiali delle dodici squadre. Si tratta di capelli, barba e tonalità visibile della pelle, non di ricostruzioni dei volti. Per Dermaux e Marttila la foto disponibile era una sagoma: i loro profili rimangono non verificati. Fonti e associazioni individuali in `appearance47-sources.json`.

I nuovi preset sono modificabili nel menu Modifica. Nomi, numeri, valori, formazioni e modifiche estetiche personali restano locali; i vecchi campi estetici non specificati possono ricevere i nuovi valori predefiniti senza sovrascrivere le scelte esplicite.

## Verifiche

- 64 pallonetti: due rotazioni, quattro uscite, otto direzioni, comandi a 180 o 360 ms dall'intercettazione; tutti con contatto reale.
- 96 costruzioni complete ricezione/alzata/attacco nelle sei rotazioni di entrambe le squadre; tutte completate con i tre tocchi reali.
- 2.000 risposte sintetiche del muro distribuite fra tre famiglie e sette dettagli di traiettoria. Questa distribuzione è un test del risolutore, non una percentuale prevista di punti in partita.
- Nel confronto controllato con attaccante in atterraggio e copertura profonda: 12/12 punti fisici sul muro ben chiuso, 12/12 recuperi CPU sul tocco morbido e alto. Sono casi costruiti per verificare la differenza fra le due risposte, non una simulazione statistica del bilanciamento di una partita.
- Movimento del battitore nelle tre telecamere; servizio float e al salto dopo l'arretramento con contatto mano/palla valido; priorità S verificata.
- Menu, navigazione controller, preset estetici e compatibilità dei salvataggi verificati.

La misurazione con rendering reale, dodici giocatori e divise/roster Perugia–Monza è inclusa in `animation42-rendered-v47-rosters-new.json`: media 60,00 FPS su 600 fotogrammi, percentile 95 a 19,09 ms, massimo 24,66 ms, nessun fotogramma oltre 25 ms. Hardware locale RTX 5080, 1280×720, limite 60 FPS; misura su costruzioni ripetute, non garanzia per ogni configurazione o ogni situazione di gioco.
