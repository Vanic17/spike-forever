# SPIKE FOREVER — Specifica tecnica: rotazioni, ricezione, battuta, attacco e difesa

**Versione:** 1.0 · **Data:** 22 ottobre 2026 · **Destinatario:** Codex / team Godot · **Ambito:** pallavolo indoor 6v6, sistema 5–1, regole FIVB 2025–2028.

> **Regola di progetto:** separare sempre (A) *identità regolamentare nella rotazione*, (B) *giocatore fisicamente in campo*, (C) *posizione tattica corrente* e (D) *posizione visiva/interpolata*. Una formazione può essere tatticamente plausibile ma illegale al servizio, o viceversa.

## 1. Convenzioni e campo

Vista dall'alto della **propria metà campo**, rete in alto; sinistra/destra sono quelle del giocatore che guarda la rete dalla propria metà campo.

```text
                         RETE
               +---------+---------+---------+
 PRIMA LINEA   | 4       | 3       | 2       |
               | avanti  | avanti  | avanti  |
               +---------+---------+---------+  ← linea dei 3 m (schematica)
 SECONDA LINEA | 5       | 6       | 1       |
               | dietro  | dietro  | dietro  |
               +---------+---------+---------+
                       LINEA DI FONDO
```

Ruoli: `S` palleggiatore; `OPP` opposto; `OH1/OH2` schiacciatori-ricevitori; `MB1/MB2` centrali; `L` libero. **L non è un settimo giocatore in campo:** sostituisce temporaneamente uno dei giocatori di seconda linea (di norma un centrale). Gli identificativi delle zone sono *slot di rotazione*, non incarichi tattici permanenti.

## 2. Regole regolamentari non negoziabili

1. **Sei giocatori in campo per squadra**, contando il libero in sostituzione. Il battitore è uno dei sei, temporaneamente fuori dal rettangolo di gioco per servire.
2. La rotazione avviene **solo quando una squadra che riceve conquista il diritto a servire**. Si avanza in senso orario: `2→1→6→5→4→3→2`. Se la squadra già al servizio vince il punto, **non ruota**.
3. Al momento dell'impatto della battuta, la **squadra in ricezione** deve rispettare l'ordine relativo: `4` a sinistra di `3`, `3` a sinistra di `2`; `5` a sinistra di `6`, `6` a sinistra di `1`; `5` dietro `4`, `6` dietro `3`, `1` dietro `2`. Il controllo è sui **piedi a contatto col suolo o sull'ultimo contatto** secondo la regola FIVB 7.4.3: non imporre una griglia rigida o un divieto generico di incrocio diagonale. Utilizzare una tolleranza geometrica coerente con la definizione ufficiale dei piedi.
4. Secondo le regole FIVB 2025–2028, la **squadra al servizio può disporsi liberamente al momento dell'impatto**, eccetto il battitore che si trova nella zona di servizio. L'ordine di rotazione e i vincoli prima/seconda linea **rimangono invariati**: libertà di posizione non significa che un giocatore di seconda linea diventi di prima linea.
5. Dopo il colpo di servizio entrambe le squadre possono muoversi nelle proprie aree consentite per assumere la formazione tattica.
6. Solo i giocatori di **prima linea** possono completare un muro. Un giocatore di seconda linea non può completare un attacco con palla interamente sopra la rete se al momento dello stacco è nella zona d'attacco; può attaccare dalla seconda linea staccando da dietro la linea dei 3 m (l'atterraggio può avvenire davanti).
7. Il libero **non può murare né tentare il muro**, e non può completare un attacco con palla interamente sopra la rete. Se effettua un palleggio di dita nella propria zona d'attacco, un compagno non può completare l'attacco con palla interamente sopra la rete: distinguere la zona e la tecnica del tocco. Nel profilo FIVB internazionale adottato qui, il libero non batte.
8. Le sostituzioni del libero sono **separate** dalle normali sostituzioni e avvengono secondo le procedure e le finestre regolamentari: non teletrasportare il libero a metà scambio. Il centrale sostituito resta il titolare dello slot di rotazione.
9. Il sistema 5–1 impiega **un solo S** per tutte le rotazioni. S e OPP sono **opposti nell'ordine di rotazione** (distanza di tre slot); quindi non sono mai entrambi di prima linea. Gli OH sono opposti tra loro; i MB sono opposti tra loro.
10. In fase di ricezione, una posizione tattica 'vicino alla rete' non dimostra che il giocatore sia di prima linea: i diritti dipendono dallo slot regolamentare, non dalla coordinata `z` corrente.

## 3. Formazione 5–1 di riferimento: tutte e sei le rotazioni

**Formazione iniziale scelta per il progetto:** `Z1=S`, `Z2=OH1`, `Z3=MB1`, `Z4=OPP`, `Z5=OH2`, `Z6=MB2`. È una convenzione di partenza valida, non l'unica formazione possibile. Ogni rotazione successiva deriva dall'applicazione della permutazione regolamentare; non ricostruire la formazione assegnando ruoli a zone fisse.

| Rotazione | Z4 (avanti sx) | Z3 (avanti centro) | Z2 (avanti dx) | Z5 (dietro sx) | Z6 (dietro centro) | Z1 (dietro dx) | S in | OPP in |
|---|---|---|---|---|---|---|---|---|
| R1 | OPP | MB1 | OH1 | OH2 | MB2/L | S | seconda | prima |
| R2 | OH2 | OPP | MB1 | MB2/L | S | OH1 | seconda | prima |
| R3 | MB2 | OH2 | OPP | S | OH1 | MB1/L | seconda | prima |
| R4 | S | MB2 | OH2 | OH1 | MB1/L | OPP | prima | seconda |
| R5 | OH1 | S | MB2 | MB1/L | OPP | OH2 | prima | seconda |
| R6 | MB1 | OH1 | S | OPP | OH2 | MB2/L | prima | seconda |

**Attenzione alla convenzione:** R1→R2→R3→R4→R5→R6→R1 è l'ordine di rotazione **quando si conquista il servizio**, non un cambio dopo ogni punto. Il simbolo `MB/L` indica il centrale titolare dello slot, eventualmente sostituito dal libero se eleggibile; non due giocatori insieme. In R3, R4 e R5 il centrale in seconda linea è MB1; in R1, R2 e R6 è MB2. La presenza del libero dipende anche dal servizio e dalle procedure di sostituzione.

### 3.1 Verifica formale di opposizione

- `S` e `OPP`: in ogni riga uno è davanti e l'altro dietro.
- `OH1` e `OH2`: uno davanti e uno dietro.
- `MB1` e `MB2`: uno davanti e uno dietro.
- Nessuna riga contiene due palleggiatori o un libero in prima linea.
- Il **battitore** è sempre il titolare corrente dello slot `Z1` (se nello slot è previsto un centrale sostituito dal libero, il centrale rientra per il servizio nel profilo FIVB scelto).

## 4. Fasi di gioco: un sistema di stati, non quattro formazioni rigide

Stati suggeriti: `PRE_SERVE`, `SERVE_CONTACT`, `RECEIVE`, `SET_BUILDUP`, `ATTACK_APPROACH`, `ATTACK_CONTACT`, `BLOCK_READ`, `DEFEND_BASE`, `DIG`, `COVER_ATTACKER`, `TRANSITION`, `RALLY_END`.

La squadra che **batte** e quella che **riceve** hanno comportamenti diversi, ma entrambe devono poter transitare in attacco/difesa durante lo stesso rally. Gli stati descrivono *intenzioni tattiche*, non pose/animazioni obbligatorie. Il movimento è interpolato, anticipatorio e sensibile alla traiettoria della palla.

## 5. Prima della battuta: squadra al servizio

- Il giocatore nello slot `Z1` si reca **dietro la linea di fondo**, nella zona di servizio; la sua posizione laterale può variare tatticamente.
- Gli altri cinque preparano una formazione difensiva coerente con la strategia: normalmente una base di muro/difesa, non una fila 3+2 obbligatoria.
- **FIVB 2025–2028:** i cinque in campo non devono rispettare gli overlap di ricezione al colpo di battuta. Tuttavia lo status prima/seconda linea è quello degli slot, e deve essere preservato per muro e attacco.
- Il battitore rientra in campo dopo aver battuto e raggiunge la propria **zona di difesa** senza teletrasporto. Il suo rientro può lasciare temporaneamente uno spazio scoperto, che gli altri coprono.
- Il libero eventualmente fuori per consentire al centrale di battere potrà rientrare **solo secondo le regole di sostituzione del libero**, non durante lo scambio.

**Base difensiva suggerita, adattabile:** blocco sulla rete gestito dai tre aventi diritto di prima linea; copertura di seconda linea con tre difensori, incluso il battitore quando rientra. La difesa effettiva deve reagire a ricezione avversaria, posizione del palleggiatore e minacce di attacco.

## 6. Prima della battuta: squadra in ricezione

### 6.1 Regola di legalità

Prima di calcolare le coordinate ideali dei ricevitori, costruire una formazione che soddisfi **tutti e sei i vincoli di overlap** della sezione 2. Non basta che ci siano tre davanti e tre dietro; non basta che i ruoli siano giusti. Non confrontare solo le coordinate dei centri dei giocatori se la regola riguarda i piedi.

### 6.2 Obiettivo tattico

- Ricezione **tipica a tre**: `OH1`, `OH2`, `L` (se in campo). È una scelta tattica predefinita, non una regola universale: se il libero è fuori o la rotazione non lo permette, scegliere il miglior ricevitore eleggibile.
- `S` parte da una posizione **legalmente compatibile con il suo slot** e si prepara a raggiungere il target di alzata (tipicamente tra Z2 e Z3) **dopo il colpo di battuta**. Non forzarlo sempre in Z3 prima del servizio.
- `MB` di prima linea si prepara a un primo tempo, senza occupare inutilmente il corridoio di ricezione.
- `OPP` e OH di prima linea preparano l'uscita in attacco; l'opposto non deve essere automaticamente vicino alla rete se è di seconda linea.
- Una ricezione a tre **non implica** che i tre ricevitori occupino sempre le tre zone di seconda linea: nelle rotazioni in cui un OH è davanti può ricevere in una posizione compatibile con l'overlap e poi liberarsi per attaccare.

### 6.3 Sequenza temporale

`PRE_SERVE`: posizionamento legale e postura pronta → `SERVE_CONTACT`: snapshot per eventuale fallo di posizione → `RECEIVE`: uno riceve, altri coprono i conflitti → `SET_BUILDUP`: S va al target, attaccanti preparano la rincorsa → `ATTACK_APPROACH`: scelta dell'attacco → `ATTACK_CONTACT`.

La posizione di ricezione **non è** la posizione definitiva di attacco. Il cambio avviene dinamicamente, senza snap e senza aspettare che la palla sia già al palleggiatore.

## 7. Attacco dopo ricezione o difesa (side-out / contrattacco)

**Target tattici di riferimento** (non vincoli regolamentari):

| Ruolo in quel rally | Comportamento/area preferita |
|---|---|
| S | Si orienta e si sposta verso target di alzata tra Z2 e Z3; se la ricezione è cattiva, va al punto di secondo tocco raggiungibile. |
| OH in prima linea | Si apre per rincorsa verso Z4; disponibile per palla alta, super o veloce in banda. |
| MB in prima linea | Si prepara vicino al centro per primo tempo/fast; anticipa in base alla qualità della ricezione. |
| OPP in prima linea | Si prepara sul lato destro Z2, anche per attacco veloce. |
| OPP in seconda linea | Può preparare attacco da seconda linea (es. Z1), con stacco dietro i 3 m. |
| OH in seconda linea | Può attaccare da dietro i 3 m (pipe da Z6, secondo scelta tattica e disponibilità). |
| L | Copertura e difesa; mai muro o attacco completato sopra la rete. |

**S in seconda linea:** tre attaccanti di prima linea potenzialmente disponibili. **S in prima linea:** due altri attaccanti di prima linea, più eventuale secondo tocco del palleggiatore e attacchi di seconda linea. Il palleggiatore in seconda linea non può effettuare un secondo tocco d'attacco sopra la rete staccando dalla zona d'attacco.

**Qualità della ricezione:** perfetta → tutte le opzioni; buona → opzioni veloci con difficoltà maggiore; negativa → palle alte, seconda linea o alzata d'emergenza. La barra di tempismo e la logica di scelta dell'attaccante restano responsabilità del gameplay; la formazione deve supportarle, non sovrascriverle.

**Copertura attacco:** gli altri giocatori si distribuiscono intorno al punto previsto di schiacciata per recuperare eventuali muri; il numero e la geometria dipendono da attaccante, zona, distanza, traiettoria e ruoli. Nessun rientro automatico in una griglia 3+3 durante lo scambio.

## 8. Difesa quando l'avversario costruisce l'attacco

1. **Base di muro:** soltanto giocatori regolamentarmente di prima linea. `MB` centrale se disponibile; `OH` e `OPP`/`S` avanti secondo la rotazione. Un `S` in prima linea può partecipare al muro; un `OPP` in seconda linea **non** può murare.
2. **Lettura dell'alzata avversaria:** la freccia di previsione è un aiuto di gameplay, non un teletrasporto. Scelta corretta → tentativo di **muro a due**, con arrivo e salto ancora soggetti a tempi e distanza. Scelta errata → **muro a uno** con centrale in ritardo, quando fisicamente plausibile.
3. **Primo tempo centrale:** se lettura sbagliata, un solo muro in ritardo, salvo assenza di giocatori eleggibili/raggiungibili. Se la palla è troppo veloce, nessun muro efficace è una possibilità naturale.
4. **Alzata veloce:** freccia visibile meno a lungo; tempi di chiusura ridotti.
5. **Alzata normale imprecisa e alta:** consente alla difesa di organizzarsi meglio. **Nota di coerenza con la decisione progettuale attuale:** è stato richiesto che qui possa arrivare un *muro a tre*, pur avendo escluso il muro a tre dal sistema base. Trattarlo come **eccezione opzionale configurabile**, disabilitata finché non si decide esplicitamente di implementarla; in modalità iniziale restare a massimo due muratori. Se attivata, i tre devono essere di prima linea e avere il tempo di arrivare, mai comparire per script.
6. **Difesa dietro il muro:** assegnare un difensore alla diagonale forte, uno alla parallela/lungo linea e uno a pallonetto/copertura, adattando il posizionamento a muro, mano dominante dell'attaccante, tendenze e traiettoria. Il libero è spesso il difensore principale ma non ha un punto fisso universale.
7. **Dopo il tocco di muro:** il muro non conta tra i tre tocchi di squadra; i difensori reagiscono al rimbalzo effettivo, e un compagno copre la palla che torna indietro.
8. **Dopo la difesa:** il giocatore che ha difeso potrebbe non poter alzare; scegliere S se raggiungibile, altrimenti secondo alzatore. Gli attaccanti ricostruiscono una nuova rincorsa.

## 9. Distinzione fra le quattro configurazioni richieste

| Fase | Cosa determina la posizione | Chi si muove | Cosa NON fare |
|---|---|---|---|
| **Battuta propria** | Battitore Z1 + base difensiva libera FIVB | Battitore dietro fondo; altri preparano copertura | Non imporre overlap della ricezione alla squadra che serve; non ruotare dopo ogni punto |
| **Ricezione** | Rotazione + overlap legale + tattica a 2/3 ricevitori | Ricevitori e S pronti a liberarsi | Non mettere S sempre in zona 3 prima del servizio; non usare posizioni 3+3 statiche |
| **Attacco** | Qualità ricezione/difesa, disponibilità attaccanti, traiettoria | S al target, attaccanti in rincorsa, altri in copertura | Non far attaccare da prima linea un giocatore registrato dietro |
| **Difesa** | Traiettoria avversaria, lettura alzata, diritto a muro | Prima linea chiude muro, seconda linea copre zone | Non far murare L o giocatori di seconda linea; non teletrasportare il centrale |

## 10. Architettura consigliata per Godot

### 10.1 Modello dati minimo

```gdscript
# Pseudocodice GDScript, adattare alle classi reali.
class_name VolleyballPlayerState
var player_id: String
var role: String                 # S, OPP, OH1, OH2, MB1, MB2, L
var rotation_slot: int          # 1..6 del TITOLARE, non del libero
var is_front_row: bool         # derivato da rotation_slot in [2,3,4]
var is_on_court: bool
var replaces_player_id: String # solo L
var tactical_assignment: String
var target_position: Vector3
var locomotion_state: String

class_name VolleyballTeamState
var rotation_index: int        # 0..5
var starter_at_slot: Dictionary # slot -> player_id, escluso L
var libero_replacement_id: String
var serving: bool
var phase: String
```

`is_front_row` **non** va ricalcolato in base alla distanza dalla rete dopo il servizio. Il libero non modifica l'identità regolamentare del centrale sostituito.

### 10.2 Rotazione: unica fonte di verità

```gdscript
func rotate_clockwise(old: Dictionary) -> Dictionary:
    var result := {}
    for slot in range(1, 7):
        var next_slot: int = 1 if slot == 2 else (6 if slot == 1 else slot - 1)
        result[next_slot] = old[slot]
    return result
```

**Verifica della formula:** `1→6`, `2→1`, `3→2`, `4→3`, `5→4`, `6→5`.

### 10.3 Generatore di posizioni

Pipeline obbligatoria:

1. `rotation_slots(team)` → titolari per zona e ordine di servizio.
2. `resolve_libero(team, context)` → sei giocatori fisici in campo, rispettando finestre di sostituzione.
3. `legal_receive_layout(team, serve_context)` → target iniziali e verifica dei piedi **solo per la squadra in ricezione**.
4. `tactical_targets(team, phase, ball_prediction, opponents)` → ruoli dinamici: ricevitore, S, attaccanti, muro, difesa, copertura.
5. `movement_controller` → accelerazione, passi, traiettoria, collisioni, nessuno snap.
6. `avatar/AnimationTree/PSA` → animazione visiva **senza cambiare** identità regolamentare o logica della rotazione.

Se un target tattico viola un vincolo in `PRE_SERVE` per la squadra in ricezione, risolvere il vincolo con un layout alternativo; **non** spostare a forza un giocatore oltre l'altro. Dopo `SERVE_CONTACT` l'overlap non limita più il movimento.

### 10.4 Regole anti-macchinosità

- Pianificare la posizione **di arrivo** prima del contatto palla, quando la traiettoria è stimabile.
- I giocatori senza palla fanno micro-aggiustamenti e coperture, non si bloccano.
- Le traiettorie verso il target sono individuali, con collision avoidance; non muovere tutti con la stessa interpolazione temporale.
- Mantenere `animation_state` separato da `tactical_assignment`; evitare che un cambio tattico azzeri l'animazione.
- Non creare nuove istanze di personaggi al cambio di fase: spostare le stesse sei istanze; il libero si sostituisce solo nei momenti consentiti.
- La modalità PSA/AnimationTree selezionata con F6 non deve influire su rotazioni, diritti di attacco/muro o posizioni tattiche.

## 11. Test automatici e scenari di accettazione

### A. Integrità della rotazione

- [ ] Tutte e sei le rotazioni producono **sei** giocatori fisici in campo.
- [ ] S e OPP sempre opposti (uno prima, uno seconda linea).
- [ ] OH1/OH2 opposti; MB1/MB2 opposti.
- [ ] Sei rotazioni consecutive ripristinano la formazione iniziale.
- [ ] Una squadra ruota soltanto quando conquista il servizio, mai quando conserva il servizio.
- [ ] Il battitore coincide con il titolare dello slot Z1, salvo gestione legale del libero.

### B. Ricezione e servizio

- [ ] In tutte le sei rotazioni la formazione di ricezione supera la verifica dei sei vincoli di overlap, usando le posizioni dei piedi.
- [ ] Il palleggiatore parte legalmente anche quando è in seconda linea e si libera verso la zona di alzata dopo il servizio.
- [ ] La squadra al servizio può occupare una formazione tattica libera, mantenendo i diritti di prima/seconda linea.
- [ ] Un libero non compare in prima linea, non batte nel profilo FIVB scelto e non compare insieme al centrale sostituito.
- [ ] In una ricezione a tre, se OH è di prima linea, riceve legalmente e poi si apre per attaccare.

### C. Attacco e difesa

- [ ] Con S dietro: fino a tre attaccanti di prima linea disponibili; con S davanti: due altri attaccanti di prima linea.
- [ ] Il giocatore di seconda linea che attacca sopra rete stacca dietro la linea dei 3 m.
- [ ] Nessun muro completato da libero o seconda linea, anche se il giocatore è fisicamente vicino alla rete.
- [ ] Muro a uno/due rispetta raggiungibilità e tempo; nessun teletrasporto o duplicazione di muratori.
- [ ] Il cambio `RECEIVE→ATTACK→DEFEND→TRANSITION` non riporta tutti a una griglia fissa a metà rally.
- [ ] Dopo battuta e dopo muro i difensori coprono le zone effettivamente lasciate libere.

### D. Visualizzazione/debug

- [ ] Overlay attivabile con: `player_id`, ruolo, slot 1–6, front/back, target tattico, fase, status libero, server.
- [ ] Modalità *freeze al servizio* che disegna piedi e coppie confrontate per l'overlap.
- [ ] Replay deterministico di sei rotazioni in ricezione e sei al servizio per entrambe le squadre.
- [ ] Test a 12 giocatori con PSA e AnimationTree: nessuna differenza nella logica delle posizioni; misurare FPS separatamente.

## 12. Correzione specifica rispetto agli screenshot condivisi

Negli screenshot la formazione sembrava includere `MB2` a sinistra davanti, `S` vicino al centro davanti, `OPP` a destra davanti, `OH2` dietro a sinistra, `OH1` dietro al centro e `L` dietro a destra. **Se S, MB2 e OPP sono tutti e tre regolamentarmente di prima linea, quella disposizione è incompatibile con un 5–1** perché S e OPP devono essere opposti. **Se S sta solo transitando fisicamente verso il target d'alzata dalla seconda linea, la sua posizione vicina alla rete può essere corretta dopo il servizio**; la valutazione richiede l'identità di slot di ciascuno al contatto della battuta. Il rendering non basta per stabilire la violazione. La verifica deve avvenire sui dati di rotazione, non sul colore della maglia o sulla posizione visiva.

## 13. Questioni di progetto da mantenere configurabili

1. **Profilo regolamentare:** FIVB 2025–2028 come default; altre federazioni possono avere differenze, soprattutto sul servizio del libero.
2. **Ricezione a due o tre:** default tre, ma adattabile alle statistiche dei giocatori e alla rotazione.
3. **Muro a tre:** la specifica gameplay precedente è contraddittoria (massimo due in generale, ma tre su alzata alta imprecisa). Default **massimo due**; abilitare l'eccezione solo dopo decisione esplicita.
4. **Posizioni tattiche precise:** i target in metri e le formazioni di ricezione per ogni rotazione devono essere calibrati in gioco e validati automaticamente. Non sono codificati come un'unica geometria universale perché cambiano in funzione di tattica, battitore e caratteristiche dei ricevitori.

## 14. Fonti e gerarchia

**Fonte normativa primaria:** FIVB, *Official Volleyball Rules 2025–2028*, in particolare §§ 7.4–7.7 (posizioni e rotazioni), 12 (battuta), 13 (attacco), 14 (muro), 19 (libero).  
https://www.fivb.com/wp-content/uploads/2025/01/FIVB-Volleyball_Rules2025_2028-EN-v05.pdf

**Fonti tecniche di supporto (formazioni 5–1):**  
https://www.volleyball-factory.com/images/5-1-serve-receive.html  
https://www.coachboard.app/library/volleyball/5-1-rotation

**Gerarchia:** in caso di contrasto, prevale il regolamento FIVB; le formazioni tattiche di siti/allenatori sono esempi, non obblighi regolamentari.
