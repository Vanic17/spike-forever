# Spike Forever 0.48.0 — Primo tempo e finta

## Cause individuate

La preparazione stratificata del centrale campionava il vecchio `attack_decoy` fino a una posa con entrambe le mani alte, conservando sotto i piedi della locomozione. Era un caricamento solo della parte superiore, non uno stacco: poteva sembrare un tentativo di palleggio.

Il vero attacco iniziava invece il proprio orologio soltanto dopo il rilascio dell'alzata. La finta aveva un altro orologio e poteva usare come punto di salto una destinazione temporanea di evitamento, invece della corsia d'attacco. Il semplice controllo “animazione iniziata” non verificava che i piedi fossero realmente in aria.

## Correzioni

- Preparazione bassa con il caricamento di una vera schiacciata; eliminata la posa ferma a due mani del vecchio decoy.
- La lettura della ricezione considera già il passaggio atteso in zona 3. La destinazione iniziale del centrale e la preparazione di squadra usano lo stesso riferimento, senza aumentare la velocità massima dei giocatori.
- Un solo orologio collega rincorsa, stacco e contatto attraverso le fasi SET e ATTACK. Quando la corsia è disponibile, il centrale avvia lo stacco prima del tocco del palleggiatore; l'alzata viene costruita per il contatto già preparato, senza ricominciare il salto al rilascio.
- Primo tempo con Quadrato / X Xbox: contatto circa 160 ms dopo l'alzatore. Alzata normale al centrale già pronto: circa 260 ms. Sono tempi di costruzione, non modifiche dei pulsanti o della barra d'attacco.
- Finta con il gesto originale a un braccio di `attack_v26_01`, stacco anticipato e prosecuzione fino all'atterraggio. Il gesto non tocca la palla. Spostamento reale e recupero usano lo stesso fotogramma sorgente, evitando uno scatto o una pausa al termine.
- Punto ideale dello stacco separato dai punti temporanei per evitare i compagni: un passo per lasciar passare S non viene più interpretato come la posizione da cui saltare.
- Sul primo tempo già in volo, il pallonetto applica il gesto di polso alla parte superiore del corpo. Conserva salto e intercettazione originali: attendere una quota più bassa avrebbe potuto spostare il contatto oltre la rete.
- Maschere locali equivalenti nel sistema nativo e nel fallback PSA. Parser, clip originali, IK e correzioni dei piedi restano disponibili.

La correzione non forza un salto quando il centrale è ancora lontano, la corsia è occupata o il secondo tocco è troppo staccato da rete. In quei casi resta l'alzata di sicurezza, con rincorsa e attacco successivi. Le altre uscite d'attacco, le rotazioni, i controlli e il modello fisico della palla sono conservati.

## Verifiche

- 72 costruzioni controllate: due squadre, sei rotazioni, qualità impostate al 55%, 75% e 95%, attacco al centro oppure finta con alzata in banda. Tutte mantengono tre contatti reali. Nei 60 casi con centrale disponibile, entrambi i piedi sono già in aria al contatto del palleggiatore; nei 12 casi con centrale ancora a oltre 3 m dalla corsia viene conservata la palla di sicurezza.
- Ulteriori 96 costruzioni ricezione/alzata/attacco, incluse partenze sfavorevoli senza preparazione del volo precedente: tutte completate con tre contatti reali.
- 64 pallonetti nelle otto direzioni: nessun contatto mancato.
- Fallback PSA: otto scenari di primo tempo/finta, tutti con piedi staccati al tocco dell'alzatore e tre contatti validi, senza errori di script.
- Rendering reale con dodici giocatori, roster e divise Perugia–Monza, pipe ripetute e finte: media 59,99 FPS, percentile 95 a 19,13 ms, massimo 25,24 ms su 600 fotogrammi; un fotogramma oltre 25 ms, nessuno oltre 50 ms. RTX 5080, 1280×720, limite 60 FPS. È una misura locale su uno scenario ripetibile, non una garanzia per ogni situazione di partita.

Report: `first-tempo48-report.json`, `approach48-contacts.json`, `tips47-report.json`, `animation42-rendered-v48-rosters-new.json`.

## Video di verifica

[Primo tempo, finta e alzata normale](first-tempo48-preview.mp4): 13 secondi a 1280×720, 30 FPS, senza audio. Tre costruzioni controllate con qualità impostata al 75%, registrate con il gameplay effettivo e i contatti reali. Il video usa fotogrammi fissi per la verifica delle animazioni; non è il benchmark delle prestazioni.
