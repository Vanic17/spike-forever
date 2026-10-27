# Statistiche gameplay V1 — verifica tecnica della 0.63.0

## Uso e conservazione del sistema originale

Nella preparazione della partita si sceglie **Valori giocatori → Disattivati · originale / Attivi · database V1**. Il valore iniziale offline è Disattivati. Il cambiamento è immediato nel menu: non servono due eseguibili o un riavvio. La scelta vale per entrambe le squadre e per tutta la partita, come richiesto nella specifica; non viene modificata durante uno scambio.

Nella stanza online decide l'host. L'ospite vede lo stesso selettore, non modificabile. Cambiare l'opzione annulla entrambi gli stati Pronto. Il server trasmette scelta e sei statistiche di ciascun giocatore, comprese le sostituzioni e il libero; la simulazione resta autorevole sull'host. Entrambi devono usare il protocollo **SF063**.

`use_player_stats=false` salta i nuovi modificatori. Non imposta tutti i valori a 85: usa effettivamente i calcoli, le costanti e le estrazioni casuali precedenti. Parser PSA, AnimationTree, contatti delle mani, rotazioni, IA di posizione, regole, PlayStyle e fisica di volo non vengono sostituiti. Il tutorial usa il sistema originale e ripristina la scelta precedente quando si esce.

## Analisi del codice precedente

- `timing.gd`: carica continua, battuta 0,46 s e attacco 0,55 s per arrivare a 100%; rischio oltre 100% conservato. Ricezione con qualità normalizzata 0–1, finestra tardiva 0,12 s e penalità di anticipo/distanza.
- `main.gd`: `receive_ball()` valida prima il contatto; `pass_quality` determina la costruzione successiva. `set_ball()` viene eseguito al contatto fisico con il secondo tocco, sceglie destinatario/gesto e lancia la traiettoria. La fase ATTACK e la sua barra diventano visibili in quel momento.
- Il vecchio buffering poteva accumulare carica già durante SET. In modalità originale viene conservato esattamente. In V1 una pressione anticipata può essere memorizzata, ma la carica parte dal rilascio effettivo dell'alzata; una pressione già rilasciata prima di quel momento equivale a un tocco, non a una carica anticipata.
- Il primo tempo può avere appena 0,16–0,17 s di volo. Una barra ordinaria da 0,55 s non potrebbe raggiungere 100% partendo dal rilascio: per il centrale è prevista la calibrazione distinta descritta sotto.
- `winning_shot.gd`: prima, il 100% visualizzato della battuta e la fascia 97–100 dell'attacco attivavano un esito vincente speciale. Il file resta originale; V1 non attiva quel flag. La fascia verde V1 indica precisione e continua a consentire muro/difesa reali.
- `try_block()` misura l'intersezione spazzata della palla con mani/avambracci effettivi, durante il salto valido. `block_response.gd` determina poi press, rigiocata o deviazione. Non è un sorteggio eseguito su ogni salto.
- CPU: già disponeva di ricezioni/difese imperfette e scelte tattiche dei colpi. In V1 cambiano soltanto qualità e precisione simulata derivate dalle statistiche, non gli obiettivi tattici o i movimenti.

## Difesa nel database

Tutti i **169 giocatori delle 12 squadre** hanno `ratings.difesa`, modificabile e salvabile in Modifica. Il grafico contiene sei assi: Battuta, Ricezione, Difesa, Palleggio, Schiacciata, Muro. Generale resta una valutazione descrittiva: non alimenta i sei modificatori di gameplay.

Le fonti sono le classifiche ufficiali dei **best diggers**, distinte dalla ricezione del servizio: [SuperLega 2025–26](https://en.volleyballworld.com/volleyball/competitions/superlega/2025-2026/statistics/best-diggers/) e [VNL maschile 2026](https://en.volleyballworld.com/volleyball/competitions/volleyball-nations-league/statistics/men/best-diggers/). Consultazione: 27 ottobre 2026. L'endpoint SuperLega 2024–25 non forniva righe utilizzabili e non è stato usato come evidenza.

**111 giocatori** hanno almeno un'osservazione identificata; **58** hanno una stima senza osservazioni individuali utilizzabili. Non sono punteggi ufficiali 0–99, né una misura certa della bravura: sono stime editoriali riproducibili. Il rapporto `defense63-ratings.json` identifica ogni giocatore, fonte, osservazioni, metodo e confidenza. Non sono stati confusi omonimi come i Porro o i Nikolov; per le iniziali ufficiali sono previsti alias espliciti.

Metodo iniziale:

1. Prior per ruolo: L 88, OH 76, S 70, OPP 65, MB 53.
2. Controllo = clamp((percentuale difese riuscite − 20)/45, 0, 1). Volume = clamp(difese per partita/7, 0, 1).
3. Misura = 48 + 33 × controllo + 15 × volume.
4. Peso osservazione = tentativi/(tentativi+90); peso VNL moltiplicato per 0,65. I campioni piccoli e i calendari diversi non dominano il voto; zero tentativi non costituisce evidenza.
5. Voto = arrotondamento di (prior + somma(misura × peso))/(1 + somma(pesi)). In assenza di dati: 80% prior di ruolo + 20% generale già presente, con confidenza bassa.

Limiti: i dati aggregati non descrivono perfettamente difficoltà degli attacchi, minuti in campo o responsabilità tattiche; prior e scala richiederanno revisione con scouting individuale. Nessun dato mancante è dichiarato verificato. `Build-Defense63.py` permette di rigenerare i valori; conserva hash delle pagine consultate nel rapporto.

Le modifiche personali restano in `user://roster-overrides.json`. Il caricamento ora unisce le statistiche salvate alle nuove chiavi di base: un vecchio salvataggio completo senza Difesa non cancella la nuova statistica, e un valore Difesa già modificato non viene sovrascritto dall'aggiornamento.

## Calcoli V1 e decisioni sui punti ambigui

Tutti i parametri sono in `assets/gameplay/player_stats_v1.json`; i calcoli sono centralizzati in `src/player_stats_gameplay.gd`. Le sei abilità usano l'intervallo 0–99. Si legge l'identità effettivamente in campo, compreso il libero.

### Ricezione e difesa

Dopo un contatto fisico valido:

`q_finale = clamp(q_attuale + (statistica − 85) × 0,005, 0, 1)`

Ricezione vale contro il servizio; Difesa vale durante lo scambio. A qualità iniziale 80 si ottengono rispettivamente 65 / 75 / 80 / 85 / 87 con statistiche 55 / 75 / 85 / 95 / 99. La qualità risultante alimenta i bersagli e le casistiche di controllo già esistenti e il successivo secondo tocco; non si sposta una palla mai raggiunta.

La specifica contiene due richieste incompatibili se si applica sempre la sola somma: penalità −15 a stat 55 e possibilità di qualità 100 con timing eccellente. Per rispettarle entrambe il modificatore sfuma a zero fra qualità iniziale 0,97 e 1, con smoothstep. A timing perfetto, anche 55 può ottenere 100. Il solo bonus positivo sfuma inoltre fra 0 e 0,16, così un errore gravissimo non viene riparato da stat 99. Ai valori ordinari restano esatti gli esempi della tabella.

### Alzata

La qualità d'ingresso è il precedente primo tocco. Penalità moderata di 12 punti per fuori sistema e 6 per un secondo tocco effettivamente in bagher/tuffo; nessuna penalità automatica per alzata veloce, alta o dietro.

Le soglie sono interpolate dagli ancoraggi della tabella richiesta: perfetta da 65 per stat 99, 70 per 95, 80 per 85, 90 per 75 e 100 per 65. A 60/55 la perfetta è irraggiungibile normalmente. Buona da 40 / 45 / 55 / 65 / 75 / 80 / 85 per 99 / 95 / 85 / 75 / 65 / 60 / 55.

La formula proposta avrebbe dato 66 anziché 65 a stat 99: sono stati privilegiati gli ancoraggi espliciti della tabella. Non si sorteggia un grado ai confini.

Perfetta/Buona/Difficile producono qualità di traiettoria 1 / 0,82 / massimo 0,55; una qualità già molto scarsa non viene alzata artificialmente fino a 0,55. La dispersione laterale esistente utilizza questa qualità. Si aggiungono rispettivamente 0 / 0,06 / 0,14 m di distacco da rete, prima di pianificare stance, rincorsa e volo; l'altezza rimane quella della mano del gesto scelto. Il grado non è dunque soltanto un'etichetta.

### Barre e fasce verdi

Attacco: verde 95–100 per alzata perfetta, 97–100 per buona, 99–100 per difficile. L'abilità Schiacciata non cambia questi intervalli. Nella fascia verde la precisione di mira è 0,99, senza forzare l'assegnazione del punto. Esiti intermedi e rischio oltre 100% restano.

Velocità barra rispetto alla vecchia barra a stat 95: 99→0,95×; 95→1×; 90→1,18×; 85→1,35×; 80→1,43×; 75→1,50×; 70→1,58×; 65→1,65×; 60→1,73×; 55→1,80×; 50→1,88×; 40→2×. Interpolazione continua, limitata a 2× sotto 40. Il tempo di carica è la durata base divisa per il moltiplicatore.

Per il centrale: moltiplicatore `lerp(1, curva, 0,45)`; durata base limitata al minimo fra 0,55 s e l'80% del volo effettivamente rilasciato. Questa disponibilità temporale non dipende dal grado dell'alzata. Non vengono cambiate traiettorie tattiche o stacchi di primo tempo/7.

Battuta: curva di velocità separatamente configurabile, inizialmente identica a Schiacciata. Verde da 97 / 98 / 98,5 / 99 / 99,25 / 99,5 / 99,7 per stat 99 / 95 / 90 / 85 / 75 / 65 / 55. Calcoli in virgola mobile e percentuale HUD a due decimali. Il verde riduce la dispersione di mira; non garantisce ace e non cambia la fisica di volo.

La carica dell'ospite usa lo stesso denominatore dell'host. In V1 il tempo tenuto prima dell'alzata non viene trasferito come potenza dopo il rilascio; l'orologio di rilascio è incluso negli snapshot. Nessuna attesa fissa aggiunta alle animazioni.

### CPU

L'IA non ha una barra visibile: simula una precisione di carica mediante distribuzione normale centrata a 0,97, con deviazione interpolata da 0,18 a 0,025 fra stat 0 e 99; potenza limitata a 0,35–1,18. Si conserva la riduzione per attacchi realmente fuori sistema e la scelta tattica dei colpi morbidi. Valori alti non producono automaticamente timing perfetto; si applicano gli stessi controlli fisici e di errore. I modificatori di Ricezione/Difesa/Alzata/Muro sono condivisi con i giocatori umani.

### Muro

Prima si verificano salto e reale contatto sulle mani/avambracci. Fuori portata o fuori tempo non si estrae nessun esito. Contatti marginali (bordo oltre 0,91, forza di chiusura sotto 0,55 o qualità salto sotto 0,35) mantengono la risposta geometrica originale.

Per gli altri contatti validi, la statistica distribuisce le risposte fra press forte, rigiocata e deviazione esterna secondo la tabella richiesta. Le risposte riutilizzano il risolutore di velocità originale, la varietà di traiettorie e la correzione fisica di press oltre il nastro. **Press forte non significa punto assegnato:** la palla continua la propria traiettoria e decide il terreno. In V1 non si attiva il blocco terminale artificiale della copertura CPU; il recupero deve però rispettare la sua posizione e il recupero dall'atterraggio. In modalità originale resta identico il comportamento precedente.

Misura di riferimento: sui 10.000 contatti sintetici ampiamente distribuiti dello stesso risolutore originale: 22% press, 50,9% tocchi, 27,1% deviazioni. Non è una percentuale misurata su partite umane e non è la distribuzione ipotetica 3/3/4. Sul campione più selettivo di soli contatti eleggibili il riferimento originale produce 58,5% press e 41,5% tocchi. Si riportano entrambe le popolazioni per evitare confronti fuorvianti.

Su 1.000 contatti eleggibili per valore, V1 produce:

| Muro | Press forte | Rigiocata | Deviazione esterna |
|---|---:|---:|---:|
| 55 | 9,5% | 31,1% | 59,4% |
| 75 | 24,3% | 30,2% | 45,5% |
| 85 | 30,2% | 30,7% | 39,1% |
| 95 | 51,5% | 27,4% | 21,1% |
| 99 | 56,1% | 28,2% | 15,7% |

I numeri sono risposte al contatto, non punti sul tabellone; errori geometrici e dita esterne rimangono casistiche distinte.

## Validazione

- Parità OFF contro il progetto completo 0.62 estratto dal pacchetto pubblicato: due semi con demo e gli stessi due con input manuali, 240 rilevazioni ciascuno. Identici byte per byte posizione/velocità palla, fasi, carica, qualità, contatti, posizioni, clip, tempi delle pose e stato RNG. SHA demo `63f5331c85fa288d82ea7d333acfed574d04bb928c899dd53c75ad7410042408`; manuale `6021db1999efe52ccd4f9e605fb58cda7dc8a7ad5e518e5da9e0616646679b7d`.
- Formule a stat 55/75/85/95/99; timing 0/80/100; soglie esatte e appena sotto; interpolazione delle curve; indipendenza velocità/fascia verde; lettura del libero effettivo; migrazione vecchi salvataggi; condivisione e rifiuto NaN nelle statistiche online.
- 5.000 contatti di muro V1, oltre ai 10.000 di riferimento; simmetria delle risposte; salto tardivo e palla fuori portata non intercettati.
- Otto contatti fisici con il muro animato, lati speculari, backend nativo/PSA e 60/120 Hz: tutti intercettati; sei press terminano realmente a terra nella costruzione di prova, senza contatto accidentale col nastro. Non è una promessa di sei punti ogni otto tentativi in partita.
- 96 costruzioni reali ricezione→alzata→attacco con V1 e rose reali: tutte le rotazioni, due squadre, quattro destinazioni, normale/veloce. Controlli su contatti, distanza fra radici e assenza di teletrasporti.
- Eventi reali di battuta float/salto e attacco al 100%: ON non arma il punto automatico, OFF conserva il comportamento precedente. Pressione tenuta/rilasciata durante SET: V1 inizia da zero sul vero rilascio.
- Menu a 1440×810, 1280×720 e 1280×600: selettore visibile, raggiungibile con D-pad; Modifica raggiunge Difesa e Salva, aggiorna l'esagono e torna alla lista con Cerchio/B. Anteprime PNG incluse.
- Formati 1 set/meglio di 3/meglio di 5, target 15/25, entrambi i vincitori, vantaggi, decisivo a 15 e ritorno home verificati con entrambe le modalità. Due set simulati dall'inizio alla fine con contatti reali e fisica, uno ON e uno OFF, riportati in `stats63-matches.json`.
- Host/ospite ENet su localhost con V1 e con originale: squadre, formazioni, sei statistiche, modalità comune, orientamento, comandi, pausa e home. Queste prove non sostituiscono una prova WAN con latenze reali.
- Tutorial: 35/35 lezioni superate con il percorso originale. Controllo del muro manuale invariato.

I rapporti JSON e gli script riproducibili accompagnano questa documentazione. Il confronto deterministico copre le sequenze registrate, non ogni possibile sequenza di input. Il bilanciamento dei voti editoriali e delle probabilità resta una V1 da provare giocando; i test accertano formule, collegamenti e regressioni, non l'equilibrio competitivo finale.

## File principali e successivo bilanciamento

Nuovi: `player_stats_gameplay.gd`, `player_stats_v1.json`, generatore Difesa e test `*63`. Aggiornati: `main.gd`, `rally_ai.gd`, `league.gd`, `club_menu.gd`, `player_card.gd`, `hud.gd`, `online_session.gd`, `online_state.gd`, `online_menu.gd`, `tutorial_mode.gd`, database, traduzioni e file di distribuzione.

Per bilanciare, modificare prima gli ancoraggi JSON: bonus dei tocchi, soglie alzata, quantità di dispersione, fasce verdi, curve delle barre e moltiplicatore del centrale, distribuzione dei muri, precisione CPU. Il percorso OFF deve continuare a superare le registrazioni di parità; non cambiare costanti originali per bilanciare V1.
