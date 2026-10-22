# Revisione 09 — riferimento Killer Aces Volleyball Demo

La logica tattica di Spike Forever è stata ricostruita usando i file della demo installata in `C:\Program Files (x86)\Steam\steamapps\common\Killer Aces Volleyball Demo`. L'analisi riguarda codice gestito e dati Unity locali; la verifica visiva è stata eseguita sulla versione aggiornata di Spike Forever.

**Grafica, materiali, arena, suoni, telecamera e assegnazioni dei pulsanti sono conservati.** Restano le barre di carica di battuta e attacco della revisione 08, Croce come azione principale, Quadrato per float/veloce e Cerchio per seconda. La ricezione mantiene la mira ordinaria in zona 3 e il margine tardivo di 100 ms. Nessun timer oscillante.

[Video aggiornato, 45 secondi](Spike%20Forever%20-%20tattiche%20e%20ritmo%20Killer%20Aces.mp4) · [Tavola delle formazioni](reference-formations.png)

## Dati effettivamente analizzati

La demo usa Unity **6000.3.10f1** con codice Mono leggibile. Sono stati inventariati e decompilati i tipi di `Assembly-CSharp.dll`, in particolare:

| File di riferimento | Sistemi analizzati |
|---|---|
| `reference-killer-aces/decompiled/manager_game.cs` | `TeamRotation`, scelta di ricevitore e palleggiatore, ruoli, sostituzioni del libero, stato dello scambio e conteggio tocchi |
| `reference-killer-aces/decompiled/player.cs` | `JobReceiver`, `JobSetter`, `JobAttacker`, `JobMover`, letture del muro, coperture, rincorse, ricezioni sporche, tuffi e curve del tempismo |
| `reference-killer-aces/decompiled/ball.cs` | Servizio, ricezione, tipi di alzata, attacco, seconda, muro pieno, deviazione, nastro, velocità e ampiezza delle traiettorie |
| `reference-killer-aces/reference-profile.json` | Trasformazioni delle formazioni e parametri serializzati dei prefab reali di giocatore e palla |

L'impronta SHA-256 dell'assembly analizzato è registrata nel profilo estratto e nel profilo usato dal gioco. I file dell'installazione Steam sono stati letti; gli output e gli strumenti di analisi si trovano nella cartella di Spike Forever.

## Rotazioni e posizionamento

La demo possiede due tabelle distinte da 42 riferimenti ciascuna: sei rotazioni con sette posizioni, compreso il riferimento della panchina. Sono state trasferite **tutte le 72 posizioni attive**, cioè dodici formazioni da sei uomini. Il lato avversario usa le stesse disposizioni specchiate.

La conversione dalla metà campo di riferimento alla nostra metà campo è `larghezza = -Unity.z`, `profondità = -Unity.x`. In questo modo campo e telecamera rimangono quelli di Spike Forever.

| Maglia | Ruolo fisso | Zona iniziale di rotazione |
|---|---|---|
| 1 | Banda OH1 | 2 |
| 2 | Centrale MB1 | 3 |
| 3 | Opposto | 4 |
| 4 | Banda OH2 | 5 |
| 5 | Centrale MB2 | 6 |
| 6 | Palleggiatore | 1 |

Il giro di servizio è 6 → 1 → 2 → 3 → 4 → 5. I ruoli restano fissi mentre cambia la zona di rotazione. Il libero, maglia 7, occupa il posto del centrale di seconda linea; durante il servizio del centrale resta fuori per quel punto, secondo la disposizione della demo.

Le posizioni iniziali comprendono gli incastri dei ricevitori e la penetrazione del palleggiatore dopo il servizio. Una banda di prima linea può quindi partire in una posizione arretrata di ricezione e poi aprirsi sulla propria corsia d'attacco. Questo sostituisce la vecchia griglia generica di tre uomini davanti e tre dietro.

![Le dodici formazioni trasferite](reference-formations.png)

## Comportamento durante lo scambio

- **Ricezione:** precedenza a bande e libero sul servizio; il palleggiatore si libera e penetra verso l'area di alzata. Un giocatore ancora in atterraggio, a muro o in recupero riceve una forte penalità nella scelta del difensore.
- **Alzata:** il palleggiatore titolare viene scelto quando può raggiungere il pallone. Una ricezione larga, lontana dalla rete o raccolta da un sostituto cambia la valutazione fra situazione in sistema, parziale e fuori sistema. Nelle emergenze il secondo tocco può essere in bagher.
- **Attacco senza palla:** le due ali si aprono oltre la linea laterale per la rincorsa; il centrale prepara un primo tempo rispetto alla posizione reale del palleggiatore; seconda linea, pipe e attacco D hanno preparazioni distinte. Il destinatario rimane coerente dall'alzata al colpo.
- **Copertura:** i giocatori esclusi dall'attacco chiudono davanti e dietro lo schiacciatore. Il libero lascia libero il corridoio della seconda linea. Il centrale si offre e poi rientra in copertura.
- **Difesa:** prima dell'alzata il centrale legge l'opzione di primo tempo e le ali mantengono le corsie. Dopo il rilascio si distinguono linea, diagonale, primo tempo e attacco da dietro. I difensori fanno letture con piccoli errori individuali anziché convergere tutti sullo stesso punto.
- **Muro:** chiusura leggermente interna sulla banda, attesa di un appoggio vicino alla posizione assegnata, arrivo del compagno entro una breve finestra del comando già dato. Ogni atleta conserva un solo salto per attacco. Le mani penetrano verso il piano della rete con IK limitata; il contatto può coinvolgere mani e avambracci animati sopra la rete.
- **Recuperi:** il tuffo viene preparato prima dell'intercetto quando la ricezione in piedi risulta insufficiente. La spinta modifica la velocità del giocatore, mentre posizione, collisioni e raggiungibilità restano continue. La nuova clip originale `PASS_1H_Dig_Front_RHand_FromHalfSquat_V2` porta a 22 le animazioni attive. Il recupero basso tardivo della revisione 08 resta disponibile.

La velocità di base estratta del giocatore è 3,0, con una curva di locomozione che arriva a circa 1,52: il movimento ordinario di corsa raggiunge quindi circa 4,56 m/s. Assistenza urgente e spinta del tuffo sono adattate alle nostre animazioni, con controllo continuo delle distanze fra corpi.

## Ritmo e traiettorie

Nel codice della demo la velocità è un avanzamento normalizzato della traiettoria, espresso al secondo, distinto dall'altezza dell'arco. I valori base estratti sono:

| Famiglia | Velocità normalizzata base |
|---|---:|
| Servizio | 1,60 |
| Ricezione | 0,60 |
| Alzata | 0,80 |
| Schiacciata | 3,00 |
| Attacco morbido | 1,86 |
| Deviazione | 1,00 |

Spike Forever deriva tempi differenti per salto potente, float, ricezione alta, alzata normale, veloce, pipe, recupero e attacco. Per esempio, il servizio potente al massimo dura circa 0,58 s fino all'intercetto previsto; il float circa 1 s. Le ricezioni alte lasciano più tempo al palleggiatore, mentre gli attacchi viaggiano in pochi decimi di secondo.

Il solver condiviso mantiene velocità, spin, collisioni e intercetti coerenti. L'altezza del volo usa una gravità effettiva per famiglia per riprodurre l'indipendenza fra durata e arco della demo. Pipe, attacchi morbidi e seconda hanno archi sufficienti a superare la rete; i rimbalzi liberi tornano alla gravità ordinaria. Nessuna correzione della palla viene usata per fingere un contatto con le mani.

Il tempismo della ricezione usa il lato di avvicinamento della curva spaziale estratta. La parte perfetta è mantenuta fino al contatto per conservare il comando all'arrivo già sviluppato. La difficoltà regola la tolleranza; potenza della palla, tipo di difesa e recupero modificano la qualità del passaggio. La carica di servizio e schiacciata resta quella richiesta nella revisione 08.

## Varietà delle azioni

Le scelte della CPU dipendono da ricezione, posizione dell'attaccante, difesa e muro. Una preferenza per gli spazi liberi è combinata con variazione limitata e penalità per la ripetizione: gli avversari possono indirizzare una palla su un difensore preparato oppure trovare un varco.

Sono gestiti attacco potente, palla morbida, primo tempo, palla alta, seconda, ricezione lontana, bagher d'emergenza, terzo tocco regalato, overpass e attacco diretto sull'overpass. Le collisioni distinguono muro pieno, tocco leggero, nastro che lascia passare la palla e rimbalzo di rete recuperabile. Un servizio che resta nella rete termina fisicamente a terra. Un quarto tocco termina il punto una sola volta, senza consentire alle funzioni successive di riaprire lo scambio.

## Verifiche finali

`Verifica.cmd` passa con asset originali e fallback, mantenendo le regressioni dei comandi della revisione 08.

- **144 posizioni verificate** contro le trasformazioni Unity estratte: 72 posizioni per ciascun lato, dodici formazioni uniche, sei rotazioni e ruoli coerenti.
- 108 scenari di muro e 48 alzate pianificate per ruolo. Distanze controllate e nessun salto duplicato.
- Curve e intercetti a 30/60/120 Hz; controllo fisico del superamento della rete per attacco da seconda linea, palla morbida e seconda.
- Scenari dedicati a bagher d'emergenza, terzo tocco regalato, attacco diretto sull'overpass, nastro vivo e assegnazione unica del punto sul quarto tocco.
- **13 controlli di conservazione** per telecamera, grafica, audio, assegnazioni input e comandi della carica.

| Simulazione | Punti | Tocchi di squadra | Scambio massimo | Gap massimo del contatto | Distanza minima fra compagni |
|---|---:|---:|---:|---:|---:|
| Standard con asset | 16 | 99 | 21 | 0,133 m | 0,800 m |
| Fallback | 16 | 64 | — | 0,114 m | 0,789 m |
| Partita estesa con asset | 64 | 362 | 24 | 0,157 m | 0,792 m |

La partita estesa attraversa tutte e sei le rotazioni di entrambe le squadre. Comprende 42 contatti in tuffo, 35 alzate veloci, 35 attacchi morbidi, 5 colpi di seconda, 12 tocchi leggeri e 4 muri pieni. I tocchi di muro sono registrati come eventi separati dai tre tocchi di squadra. Nessun salto duplicato.

Report: `revision-contact-report.json`, `fallback-contact-report.json`, `reference-stress-report.json`, `reference-profile-test.log`. Gli scenari dedicati verificano anche azioni rare non necessariamente presenti nel campione di 64 punti.

## Riproduzione e adattamento

- `tools/Inspect-KillerAces.ps1`: inventario dell'assembly in sola lettura.
- `tools/extract_killer_profile.py`: lettura delle trasformazioni e dei prefab Unity dall'installazione locale.
- `tools/build_killer_reference.py`: generazione del profilo usato dal gioco.
- `tools/draw_reference_formations.py`: tavola delle dodici formazioni.
- `tools/Test-Reference.gd` e `tools/Check-ReferenceScope.ps1`: confronto con i dati estratti e controlli del perimetro conservato.

L'adattamento usa le animazioni di Spike Forever e la sua simulazione Godot. Le coordinate iniziali provengono direttamente dalla demo; transizioni, decisioni e traiettorie sono ricostruite per questi scheletri e per i comandi attuali. Il gioco aggiornato funziona usando il profilo incluso in `assets/gameplay`, senza caricare l'eseguibile o le DLL della demo. Gli input sono verificati con eventi simulati; la prova fisica di ogni controller resta manuale.

Backup della revisione precedente: `baseline-v08`. La cattura a passo fisso serve alla verifica visiva, con input automatici per la dimostrazione; non costituisce un benchmark delle prestazioni in tempo reale.
