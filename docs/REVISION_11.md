# Revisione 11 — posizionamento e continuità

Il riferimento Killer Aces viene usato per il **solo posizionamento**. Controlli sullo stick sinistro, barre di carica, tempismo, scelte di colpo, animazioni originali e fisica dello scambio restano quelli della revisione 10. Camera, grafica e audio sono conservati.

## Verifica del riferimento maschile

La scena originale installata usa `modeGender = 0`, modalità maschile. Le tabelle di battuta e ricezione sono condivise fra le modalità: non era stata importata una rotazione femminile.

La slide laterale del centrale verso l'antenna è un ramo separato, abilitato nel riferimento con `modeGender == 1` e identificato da `setTargKind = -3`. Quel ramo è escluso. Un primo tempo vicino e dietro al palleggiatore può invece comparire anche nella modalità maschile (`setTargKind = -1`). Non viene confuso con la palla D dell'opposto in seconda linea.

La verifica e i riferimenti puntuali al codice originale sono in [positioning-audit-v11.md](positioning-audit-v11.md). L'esito dei confronti è in `positioning-audit-v11.json`.

## Posizioni durante lo scambio

Le formazioni iniziali erano già confrontate con le tabelle originali. Le posizioni successive contenevano ancora approssimazioni. Ora `rally_ai.gd` usa le coordinate ricostruite da `player.JobMover` e `manager_game.TeamRotation`, registrate separatamente in `assets/gameplay/killer_aces_positioning.json`.

| Situazione | Posizionamento |
|---|---|
| Battuta e ricezione | Dodici formazioni originali, sei rotazioni per squadra |
| Penetrazione del palleggiatore | Area del riferimento, larghezza 1,5 m e profondità 0,5 m |
| Apertura delle bande | Larghezza 5 m fuori dalla linea laterale, profondità 4 m; corsia più interna per la preparazione veloce prevista dal riferimento |
| Centrale | Distanza dal palleggiatore fra 1,52 e 2 m, con avanzamento da profondità 3,52 a 1,52 m |
| Seconda linea | Pipe a larghezza −1,6 m, D dell'opposto a +4,48 m, preparazione da profondità 6 a 4 m |
| Copertura | Prima linea a profondità 2 m, seconda linea a 4,26 m; il palleggiatore attivo conserva la propria corsia |
| Difesa | Basi e letture per ruolo, comprese le correzioni in base ad attaccante, zona e muro |

Corretto anche il palleggiatore in prima linea: prima poteva conservare la base difensiva della seconda linea. Le alzate al centrale ora arrivano accanto al punto effettivo dell'alzata, anziché obbligarlo sempre a convergere sulla coordinata centrale fissa del campo. L'alzata dietro mantiene l'opposto come destinatario; il centrale non viene instradato nella slide verso l'antenna. La posizione del palleggiatore al rilascio viene conservata per evitare che un successivo piccolo passo faccia cambiare lato alla rincorsa del centrale.

I bersagli tattici vengono raggiunti con l'accelerazione e le transizioni del nostro gioco. Restano le distanze minime fra i corpi, i veri punti di contatto delle mani e la rincorsa del servizio compatibile con lo spazio dell'arena: il battitore parte a 11,9 m per staccare dietro la linea senza attraversare la piattaforma della tribuna.

## Continuità dei giocatori e della palla

Durante bagher, alzata e preparazione della schiacciata, il livello delle gambe aggiorna ora la propria direzione anche se il gesto superiore è già preparato. Una correzione laterale o all'indietro non conserva i passi della vecchia direzione. La cadenza cambia progressivamente e le correzioni diagonali non alternano inutilmente due andature.

Corretto un difetto nel ciclo dei passi usati sotto il gesto preparato: il passaggio fra fine e inizio del ciclo poteva spostare ginocchia e caviglie di circa 8,29 cm. Nella prova dedicata la discontinuità scende a circa 0,047 cm. Restano gli stessi file delle animazioni e gli stessi tempi di contatto.

La palla ruota ora attorno all'asse fisico dello spin usando quaternioni, senza dipendere dall'orientamento corrente della sua texture. Dopo il punto, il contatto con il pavimento viene risolto nell'istante dell'urto e viene simulata anche la parte rimanente del passo: la palla non viene prima lasciata penetrare e poi riportata sulla superficie. Restano gravità, spin, resistenze e tempi delle traiettorie dello scambio; i coefficienti dei rimbalzi e del rallentamento sono conservati.

## Verifiche

`Verifica.cmd` passa con gli asset originali e con i personaggi di ripiego:

- Partita con asset originali: 16 punti, 182 contatti, scambio massimo di 33 contatti; distanza minima fra corpi 0,780 m e fra muratori 0,801 m.
- Partita di ripiego: 16 punti, 87 contatti; nessun doppio salto dello stesso atleta sul medesimo attacco.
- 840 confronti indipendenti del posizionamento, comprese 144 coordinate iniziali e tutte le rotazioni di entrambe le squadre.
- 432 casi di ruolo/fase e continuità delle reazioni individuali.
- 48 correzioni direzionali durante i gesti preparati a 30/60/120 Hz, con punti di contatto conservati.
- Traiettorie confrontate con la fisica della revisione 08; rimbalzi e rotazione verificati a 30/60/120 Hz.
- `Check-PositionScope.ps1`: 21 controlli sul mantenimento di comandi, tempismo, fisica dello scambio, scelta dei colpi e selezione delle animazioni. `Check-ReferenceScope.ps1` conserva i controlli su camera, grafica e audio.

I log e i report sono `revision11-verification.log`, `revision-contact-report.json`, `fallback-contact-report.json`, `positioning-audit-v11.json`, `motion-continuity-report.json` e `ball-continuity-report.json`. Il backup precedente è `baseline-v10`.

[Video della revisione aggiornata, 40 secondi](Spike%20Forever%20-%20posizionamento%20e%20movimenti.mp4).
