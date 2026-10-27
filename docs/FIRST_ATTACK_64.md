# Primo attacco e continuità del centrale — 0.64.0

## Riferimenti applicati

L'archivio `primo attacco.zip` contiene sei immagini. Associazione verificata visivamente:

| Screenshot | Schema |
|---|---|
| 202923 | P5 |
| 202931 | P6 |
| 202939 | P1 |
| 202950 | P4 |
| 202956 | P3 |
| 203004 | P2 |

Legenda: B1/B2 = OH1/OH2; C1/C2 = MB1/MB2; O = OPP; P = S; L = libero effettivamente in campo. L'ordine interno delle rotazioni resta P1, P6, P5, P4, P3, P2. Non cambia l'ordine di servizio né chi è in prima/seconda linea.

Gli schemi sono stati trascritti come ancoraggi in metri in `rotation_layout.gd::FIRST_ATTACK`: prima linea circa 2,45 m da rete per preparare la rincorsa, seconda linea circa 4,2 m. I disegni non contengono misure, quindi le coordinate sono una trasposizione proporzionale, non quote ufficiali.

Il libero occupa il lato destro in P1/P5/P4/P2 e il sinistro in P6/P3. La banda di seconda linea mantiene il lato indicato prima di essere eventualmente scelta per la pipe. Gli opposti di seconda linea preparano il proprio corridoio a destra senza trasformarsi in attaccanti di prima linea.

## Causa della disposizione errata

In precedenza `RallyAI.opening()` usava la stessa apertura specialistica sia per il primo cambio palla sia per i rigiocati. Inoltre `court_shape.arrange()` rimandava sempre il libero a sinistra, anche dopo una diversa assegnazione nominale. Il doppio livello di assegnazione annullava la posizione corretta e poteva mandare il libero attraverso il corridoio della banda di seconda linea.

Ora la prima costruzione è riconosciuta dalla palla proveniente dal servizio avversario e resta distinta fino all'attacco. Gli ancoraggi del primo attacco vengono usati dopo il primo tocco. Prima del primo tocco resta lo schema di ricezione precedente; dopo una difesa successiva tornano le aperture già esistenti. Il confronto automatico con i moduli della 0.63 conferma che gli array di ricezione/difesa e le aperture del rigioco non sono cambiati.

Non si costringe un atleta a raggiungere una casella ignorando la palla. Il palleggiatore segue il punto di contatto fisico; il centrale prepara primo tempo/7 rispetto a quel punto; il destinatario scelto usa la propria rincorsa e il contatto della sua animazione; gli altri entrano in copertura. Gli ancoraggi descrivono la preparazione, non una formazione immobile durante tutto il volo.

## Doppio salto: riproduzione e correzione

La registrazione precedente ha riprodotto sei riavvolgimenti su 18 costruzioni con scelta del centro ritardata. Al passaggio SET → ATTACK il tempo sorgente del centrale poteva tornare da circa 0,71 s a circa 0,01 s. Il motore non stava creando un nuovo comando di salto: la ricostruzione di una traiettoria più lunga risincronizzava da capo la stessa animazione.

Cause combinate:

- La finta aspettava e saltava dalla preparazione a 2,35 m, mentre il primo tempo reale era previsto più vicino a rete.
- Se il centrale era già in volo, il nuovo punto ideale poteva richiedergli un altro spostamento non realizzabile entro il tempo breve del primo tempo.
- Il controllo di disponibilità rifiutava il tempo breve; la costruzione ritornava al volo ordinario più lungo e `prepare_contact()` riportava la sorgente prima dello stacco.

Correzioni in `middle_decoy.gd` e `main.gd`:

1. La finta chiude progressivamente dalla preparazione al punto reale del primo tempo prima di saltare, usando lo stesso spazio riservato al palleggiatore.
2. Una finta che diventa attacco reale conserva il salto, senza tornare all'inizio. La sincronizzazione di un centrale già staccato non riavvolge il tempo sorgente durante SET.
3. Al rilascio, se il centrale è già in volo e ancora nel momento utile del colpo, l'alzata può raggiungere il suo contatto effettivamente impegnato entro un adattamento spaziale limitato. Non viene teletrasportato il giocatore.
4. Se il comando al centro arriva quando il momento utile della finta è già passato, si conclude l'atterraggio e si prepara un terzo tocco di recupero a terra. Il bersaglio usa la posizione prevista alla fine del movimento sorgente; il volo viene pianificato prima del rilascio considerando il tempo residuo reale di recupero e la preparazione del bagher. Non si sospende una palla già in volo e non si aggiunge un secondo salto.

La gestione speciale delle barre del centrale introdotta nella 0.63 resta attiva quando si usano i valori del database. Non cambiano tasti, fasce di potenza, formule delle statistiche o regole di contatto.

## Seconde palle e corridoi

La prenotazione del percorso del palleggiatore e il controllo delle impronte di corpo/piattaforma restano attivi. L'assegnazione L/S non viene sostituita con un inseguimento del giocatore più vicino. Con i nuovi ancoraggi, il libero non attraversa inutilmente il centro durante il primo attacco, e la preparazione del centrale continua a rispettare il corridoio vivo del secondo tocco.

Sono stati verificati contatti realmente avvenuti, non solo distanze dai bersagli. Nelle prove delle seconde palle il controllo richiede il secondo contatto registrato, distanza della mano entro 0,18 m e spostamenti per fotogramma limitati. Un pallone fisicamente impossibile o senza comando resta perdibile: la correzione non introduce contatti magnetici.

## Verifiche riproducibili

- `Test-FirstAttack64.gd`: sei schemi su entrambe le metà, confronto delle disposizioni precedenti di ricezione/difesa e delle aperture del rigioco.
- `Test-Transitions64.gd`: 96 costruzioni per ricevitore L, OH1 e OH2, totale **288**; due squadre × sei rotazioni × quattro destinazioni × normale/veloce. Tutti i tre tocchi completati; controllo separazione delle radici e spostamenti limitati.
- `Test-StatsFlights64.gd`: altre **96** costruzioni complete con rose reali e database gameplay attivo.
- `Test-SecondTouch64.gd`: **168/168** ricezione del servizio → secondo tocco, con dispersione, due squadre, tutte le rotazioni, 60/120 Hz e protezione della futura piattaforma di bagher.
- `Test-MiddleReady64.gd`: **108/108** costruzioni di primo tempo/7/finta, 50/60/120 Hz; 108 centrali già in volo al contatto del palleggiatore, di cui 72 attacchi reali e 36 finte.
- `Test-MiddleClock64.gd`: **36/36**, primo tempo e 7 con tre ritardi di scelta su sei rotazioni; nessun salto risincronizzato all'indietro e tutti i contatti completati.
- `Test-LateMiddle64.gd`: due casi forzati oltre il momento utile della finta, X e Quadrato; atterraggio conservato e terzo tocco a terra realmente completato.
- `Test-Online64.gd`: host/ospite con statistiche attive, comandi, contatti, orientamento, pausa e ritorno home. Prova localhost, non una misura della latenza WAN.

I rapporti `first-attack64-*`, `middle64-*`, `second-touch64-report.json` accompagnano gli script. Le prove coprono molte costruzioni riproducibili; non costituiscono una garanzia su ogni possibile ricezione estrema. Il caso originario non aveva un filmato del doppio salto associato a un timestamp: il difetto è stato riprodotto tramite scelte ritardate e confronto dei tempi sorgente.

File di gameplay modificati: `rotation_layout.gd`, `rally_ai.gd`, `court_shape.gd`, `middle_decoy.gd`, `main.gd`. In aggiunta cambia il protocollo in `online_session.gd`. Nessun aumento generale della velocità, nessuna sostituzione degli asset o del parser PSA, nessuna variazione alle formule di volo della palla o alle statistiche.
