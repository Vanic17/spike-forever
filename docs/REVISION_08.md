# Revisione 08 — comandi contestuali e carica

Questa revisione applica la nuova richiesta dell'utente e sostituisce il precedente sistema di timing. Le specifiche iniziali e i vincoli della revisione 07 sui comandi conservati sono storici.

## Cambiamenti

- Eliminati il cursore oscillante, le finestre perfette periodiche, il blocco del cursore e la vecchia lettura temporizzata del muro, sia nella logica sia nell'interfaccia.
- Mappa standard: PlayStation Croce / Xbox A / Spazio per azione principale; Quadrato / Xbox X / Q per float e alzata veloce; Cerchio / Xbox B / E per seconda. Niente combinazione L1 + azione o selettore Triangolo.
- Servizio: movimento dietro la linea tra 9,3 e 12,5 m di profondità, preparazione del gesto durante la carica e completamento del lancio al rilascio. Animazioni originali distinte per jump power e jump float. Inquadratura più ampia durante il servizio umano per tenere visibile il battitore.
- Carica servizio: 1,05 secondi per il 100%; la carica continua oltre il massimo. Rischio crescente del 2,5% per ogni punto percentuale di sovraccarico, fino al 100% di rischio al 140%. Gli errori producono traiettorie verso rete o fuori, senza assegnare il punto al semplice rilascio.
- Ricezione: qualità continua in funzione della distanza temporale dal contatto fisico, con finestra perfetta vicina all'arrivo e peggioramento monotono premendo prima. La difficoltà regola la tolleranza. Senza comando nessun salvataggio automatico.
- Ricezione tardiva: margine di 100 ms, intercetto ricalcolato sulla traiettoria in corso e animazione originale di recupero basso. Il controllo verifica le mani animate e la portata effettiva; la palla non viene riposizionata.
- Mira della ricezione centrata in zona 3, a 1,5 m dalla rete. Dispersione proporzionale alla qualità. L'alzata eredita la qualità della ricezione.
- Alzata: un pulsante sceglie direttamente normale, veloce o colpo di seconda; le quattro direzioni restano disponibili. La previsione viene adattata all'altezza di contatto dell'animazione scelta. Il centrale lascia libero lo spazio del palleggiatore prima del secondo tocco.
- Schiacciata: 0,75 secondi per il 100%; rilascio senza un secondo criterio di tempismo. Se il comando è ancora tenuto al contatto si usa la carica raggiunta. Sovraccarico oltre il 100% produce un bersaglio lungo fuori.
- Mira della schiacciata a otto settori: bersagli calcolati a terra, con intercetto difensivo derivato dalla stessa traiettoria. Un tocco breve ha la precisione massima, incluse le diagonali verso gli angoli. Precisione nominale 100% fino al 70% di potenza; 90% potenza → 80% precisione; 100% → 70%.
- Muro: stick destro per il compagno aggiuntivo, salto manuale con Croce. Assegnazione stabile del muratore principale, distanze di sicurezza e un solo salto per atleta per attacco. Il contatto resta fisico, sulle mani animate.
- Aiuto F1, menu, barra verde e README riscritti con i comandi attuali. La barra riserva una zona rossa al sovraccarico; non rimbalza né si azzera mentre si tiene premuto.

## Animazioni aggiunte

Le animazioni estratte erano già presenti nella libreria locale. Due clip sono state copiate nel gruppo attivo e registrate nel manifest, portandolo da 19 a 21:

| Azione | Animazione originale |
|---|---|
| Seconda | `SET/SET_DumpR_RH_Front.psa` |
| Recupero tardivo | `PASS/PASS_HS_BackSave_Short_180_R.psa` |

Restano attive `Serve_Action_SmashJumped_3` e `Serve_Action_FloatingJumped_3`. Grafica, arena e suoni non sono stati sostituiti.

## Verifiche

`Verifica.cmd` / `tools/Test-Game.ps1` ha completato:

- Eventi reali del gestore controller, con ID dispositivo differente: Croce, Quadrato e Cerchio correttamente distinti. Il rilascio di Quadrato non termina la carica di Croce.
- Servizio potente e float a 30/60/120 Hz: carica prolungata, rilascio al massimo, contatto animato e sovraccarico con rete/fuori fisici. Nessun punto assegnato durante la sola carica.
- Movimento del battitore all'indietro e limite dietro la linea di fondo.
- Dodici combinazioni di alzata: tre tipi di colpo per quattro direzioni. Seconda con il relativo contatto originale.
- Schiacciata breve, al 90%, al 100%, sovraccarica e ancora tenuta al contatto. La traiettoria del tocco breve raggiunge l'angolo scelto entro 3 cm nella verifica numerica.
- Ricezione anticipata, perfetta, tardiva e senza input a 30/60/120 Hz. Qualità differenziata, zona 3 per la ricezione perfetta e recupero con la clip dedicata. Una palla fuori portata viene rifiutata.
- Compagno aggiuntivo a muro comandabile sui lati, separazione dei bersagli e assenza di un secondo salto premendo nuovamente.
- 108 scenari di muro con entrambe le squadre e sei rotazioni; 48 alzate con attaccante coerente al ruolo; collisioni con mani/rete, previsione condivisa con spin, reazioni indipendenti e conservazione dei contatti delle animazioni.

| Simulazione finale | Punti | Contatti | Scambio massimo | Distanza massima mani-palla | Distanza minima tra atleti |
|---|---:|---:|---:|---:|---:|
| Asset originali | 16 | 532 | 104 tocchi | 0,153 m | 0,784 m |
| Fallback senza asset | 16 | 277 | 59 tocchi | 0,180 m | 0,787 m |

Tutti i dodici atleti si sono mossi in entrambe le simulazioni; zero salti duplicati. Report completi: `revision-contact-report.json`, `fallback-contact-report.json`, `self-test.log`, `movement-quality-test.log`.

L'anteprima `Spike Forever - nuovi comandi e carica.mp4` contiene 30 secondi di partita dimostrativa, a 1280×720 e 60 fotogrammi al secondo. La cattura usa gli stessi comandi contestuali della partita, con input automatici per la dimostrazione. La registrazione a passo fisso non è un benchmark delle prestazioni in tempo reale. I test degli input sono automatizzati; non sostituiscono una prova fisica di ogni controller.

Backup dei sorgenti precedenti: `baseline-v07`. `Check-MovementScope.ps1` e il relativo elenco di checksum documentano esclusivamente il vincolo storico della revisione 07; non sono il criterio di accettazione di questa revisione, che modifica i comandi su richiesta esplicita.
