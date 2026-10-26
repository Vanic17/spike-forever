# Spike Forever 0.60.0 — Tutorial

Nuova modalità locale di allenamento, accessibile dalla voce **TUTORIAL** nella home. Il menu iniziale dispone ora sei pulsanti su due righe, mantenendo la grafica e l'evidenziazione della selezione.

## Training Center

Cinque categorie, schema del campo, comandi e selezione libera della lezione:

| Categoria | Lezioni | Contenuti |
| --- | ---: | --- |
| Servizio | 7 | Salto, float, angoli, movimento prima della carica, potenza e sovraccarico |
| Ricezione e difesa | 5 | Contatto, precisione, palla veloce, difesa e recuperi contestuali |
| Palleggio | 9 | Quattro direzioni normali, quattro varianti veloci, colpo di seconda |
| Schiacciata | 7 | Carica, lungolinea, diagonale, opposto di seconda linea, pipe, pallonetto e potenza |
| Muro | 7 | Salto, chiusure laterali, L2/R2, muro a tre e contatto pieno |

Le 35 lezioni sono disponibili immediatamente: non serve completare una categoria per aprirne un'altra. Menu e istruzioni seguono la lingua italiana o inglese selezionata nelle Impostazioni.

## In campo

- Prima di iniziare compare una scheda con istruzioni PlayStation, Xbox e tastiera. Nei tutorial si usa la camera frontale, coerente con le direzioni spiegate.
- Le prove usano i contatti e le animazioni del gioco, le barre reali, la fisica della palla e le collisioni con mani, rete e terreno. I lanci del coach e le posizioni iniziali sono preparati per la singola lezione; nei primi esercizi di muro il lancio è più leggibile e ci sono due secondi per preparare la formazione.
- Le zone evidenziate aiutano a mirare. Nei servizi e negli attacchi conta la caduta reale nel bersaglio; nel palleggio vengono verificati destinazione e variante; nel muro vengono verificati contatto, selezione dei laterali e numero dei muratori quando richiesti.
- Feedback, conteggio delle riuscite e tentativi rimangono visibili. Ricezione e difesa riportano qualità e anticipo/ritardo. Dopo un tentativo arriva una nuova palla automaticamente.
- Due esecuzioni riuscite completano la lezione. Puoi passare alla successiva o continuare liberamente, senza limite di tentativi.

**Options / Menu / Esc** apre la pausa dell'allenamento: riprendi, riprova, lezione precedente, successiva, categorie oppure menu principale. **Cerchio / B** torna indietro nei menu; durante il palleggio in campo rimane il comando del colpo di seconda. La tastiera può riprovare immediatamente con **R**.

I progressi sono salvati separatamente in `user://tutorial-progress.cfg`, conservati dagli aggiornamenti. Entrare e uscire dall'allenamento ripristina squadre, punteggio, rotazioni, formato e camera della configurazione precedente; il roster non viene modificato.

## Verifiche

I rapporti `tutorial60-gameplay*.json` verificano le azioni tramite i comandi del gioco e i contatti effettivi. `tutorial60-flow.json` controlla ripetizione automatica, completamento, allenamento libero, pausa durante la carica, errori senza input e direzioni errate. `tutorial60-ui.json` verifica le due lingue, visibilità dei comandi fino a 1024×600, navigazione, Cerchio/B durante il palleggio, salvataggio e ripristino della configurazione.

Restano le correzioni del muro della 0.59. Le partite normali mantengono controlli, timing, fisica, rotazioni e IA; la preparazione guidata è attiva esclusivamente nel tutorial. Online richiede **0.60.0 / SF060** su entrambi i PC.
