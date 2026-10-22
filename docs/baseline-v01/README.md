# Spike Forever

Prototipo Windows 3D di pallavolo indoor **6 contro 6**, creato da zero in **Godot 4.5.1**, senza personalizzazione di squadre o giocatori. Una squadra umana contro la CPU; modalità dimostrativa CPU contro CPU. Tutto il necessario per avviarlo è in questa cartella, senza installare Godot.

## Avvio

Doppio clic su **Spike Forever.exe**, poi **Invio / Start**. Non spostare l'eseguibile da solo: avvia il motore incluso e il progetto sorgente presenti nelle sottocartelle. In alternativa usa `Avvia Spike Forever.cmd`.

Collega un controller Xbox o PlayStation prima o durante l'avvio. Il nome rilevato compare in alto a destra. I pulsanti usano le azioni standardizzate del motore: **X Xbox equivale a Quadrato PlayStation**, non a Croce. Non è stato possibile effettuare una prova fisica dei controller durante lo sviluppo: nella verifica grafica era disponibile soltanto la tastiera.

## Comandi

| Azione | Xbox | PlayStation | Tastiera |
|---|---|---|---|
| Movimento assistito / correzioni | Stick sinistro | Stick sinistro | WASD |
| Ricezione e alzata | X | Quadrato | Spazio |
| Carica servizio / attacco | Tieni e rilascia X | Tieni e rilascia Quadrato | Tieni e rilascia Spazio |
| Direzione servizio / attacco | Stick destro, 8 direzioni | Stick destro | Frecce |
| Destinazione alzata | Stick destro | Stick destro | Frecce |
| Alzata veloce | LB + X | L1 + Quadrato | Q + Spazio |
| Lettura del muro | Stick destro durante la freccia | Stick destro | Frecce |
| Salto a muro manuale | X | Quadrato | Spazio |
| Orienta mani a muro | Stick destro in aria | Stick destro | Frecce |
| Cambia servizio float/power | Y, provvisorio | Triangolo, provvisorio | Tab |
| Inizia / pausa | Start | Options | Invio / Esc |

Alzata: **sinistra = zona 4**, **alto = centrale**, **destra = zona 2**, **basso = pipe**. L'avvicinamento del giocatore e il salto di attacco sono automatici. La squadra umana occupa la metà vicina della visuale.

Il cursore del tempo attraversa la zona verde centrale al contatto previsto con la palla. Premi Spazio/X/Quadrato vicino a quel momento per ricevere o alzare. Puoi correggere la posizione con WASD o lo stick sinistro. Nell'attacco inizia a caricare prima dell'arrivo e rilascia al contatto: il rilascio determina insieme potenza e tempismo. La precisione nominale varia dal 100% al 70% con la carica: non è una probabilità arbitraria di segnare.

Al servizio tieni premuto e rilascia entro il segno verde della potenza: **oltre il 100% è fallo**. Lo stesso riquadro mostra il cursore del tempo e, sotto, la potenza, con una sola sequenza di pressione/rilascio. Il comando per cambiare servizio è una scelta provvisoria modificabile in `controls.cfg`.

## Altri tasti

- **F1**: dati di gioco, qualità, precisione, tocchi e rotazioni.
- **F2**: attiva/disattiva la demo CPU contro CPU.
- **F3**: archivio delle dieci animazioni importate; frecce per cambiarle. F3 torna a un nuovo servizio.
- **F5**: difficoltà del tempismo, assistito / standard / esperto.
- **C**: cambia telecamera mantenendo le direzioni riferite al campo.
- **R**: nuova partita.

## Asset realmente estratti e usati

L'installazione locale di Spike Volleyball è stata letta senza modificare il gioco Steam. Il pacchetto `ProVolley-WindowsNoEditor.pak` è risultato leggibile senza chiavi. **2.696 animazioni PSA** sono state esportate in `assets/spike`; l'inventario effettivo è in `docs/animation-inventory.csv` e il log di estrazione in `docs/animation-export.log`.

La partita usa dieci animazioni selezionate in `assets/active`: attesa, corsa, ricezione, alzata normale e veloce, attacco, muro, jump float, jump power e attesa al servizio. `assets/active/sources.json` contiene i nomi originali. Sono stati anche esportati e collegati corpo, testa e divisa generica in PSK: vedi `docs/ASSET_INVENTORY.md`.

Il lettore PSA riproduce i campioni originali. Le animazioni esportate contengono 145 nomi di ossa ma non la gerarchia completa: questa viene ricostruita per nome dallo scheletro PSK. Il corpo usa 115 ossa, con pesi di skinning e pose di riposo originali; testa e divisa vengono rimappate sullo stesso scheletro. I materiali sono tinte semplici, non sono le texture originali del gioco. Gli eventi di contatto visivo sono provvisori e ricavati dall'arco delle mani: serve ancora un passaggio di rifinitura manuale.

Non sono stati estratti asset da Volleyball Unbound. L'autorizzazione al riutilizzo di Spike Volleyball è stata dichiarata dall'utente nella conversazione; questi asset restano nel progetto locale e sono esclusi dal tracciamento Git. Nessun asset è stato pubblicato.

## Funzioni presenti e limiti

Sono presenti il campo 3D, dodici atleti, il ciclo servizio/ricezione/alzata/attacco/difesa, selezione assistita dei giocatori, tempismo condiviso, due servizi, quattro alzate con variante veloce, attacco con carica, lettura del muro, formazioni a uno/due e tre su alzata normale imperfetta, salto umano manuale e orientamento semplificato delle mani.

La palla usa un'unica traiettoria balistica con gravità, controllo dell'attraversamento della rete, rimbalzo semplificato sul muro, palla a terra, fuori, punteggio e rotazione al cambio servizio. Si gioca al meglio dei cinque set, a 25 con due punti di vantaggio. Gli atleti raggiungono le posizioni con velocità limitata; un contatto mancato lascia cadere la palla.

**Non è ancora il completamento di tutto il README originale.** Il muro è una collisione approssimata per posizione, altezza e tempismo, non una collisione esatta dei poligoni delle mani. Le deviazioni del muro mantengono la loro traiettoria fisica e attivano un tentativo di recupero; le difese e le traiettorie della CPU sono semplificate. La sincronizzazione mani-palla è da rifinire; il servizio conserva un'altezza di contatto variabile secondo il rilascio. Non ci sono ancora falli completi di invasione, doppio tocco, controllo del ruolo di seconda linea, cambio di campo tra i set, multiplayer o impostazioni grafiche. La pipe sceglie un punto di stacco dietro i tre metri, ma non gestisce ancora tutti i vincoli dei ruoli.

Per la pipe il segnale di lettura mostra esplicitamente PIPE e mantiene un muro singolo; l'eccezione dell'alzata normale alta può formare il triplo. La previsione non fa saltare automaticamente i giocatori umani. La formazione non garantisce il punto: contano posizione, tempismo e traiettoria.

## Verifiche

`Verifica.cmd` esegue i controlli automatici e una simulazione riproducibile. L'ultima verifica completa ha registrato **16 punti, 395 contatti e uno scambio massimo di 104 tocchi**. Sono verificati caricamento e gerarchia delle animazioni, coordinate finite, mesh con pesi, quattro destinazioni delle alzate, variante veloce, punto pipe, azione contestuale, fallo di sovraccarico, precisione dell'attacco, tempismo e scelta del numero di muratori. Log: `docs/self-test.log`. Una seconda simulazione verifica il funzionamento senza asset originali: `docs/fallback-test.log`.

L'avvio grafico e la riproduzione dei modelli sono stati controllati sul PC disponibile; `docs/preview.png` è una cattura della build. Non è ancora stato eseguito un collaudo completo manuale di tutte le azioni, né un benchmark di 60 FPS o un test fisico Xbox/PlayStation.

## Sorgenti

- `src/main.gd`: stati della partita, AI, input e unica simulazione della palla.
- `src/timing.gd`: tempismo riutilizzabile e parametri di bilanciamento.
- `src/psa.gd`, `src/psk.gd`: importazione delle animazioni e delle mesh ActorX.
- `src/avatar.gd`: scheletro, skinning, riproduzione e fallback provvisorio.
- `src/hud.gd`: interfaccia e indicatori contestuali.
- `src/Launcher.cs`: sorgente dell'avviatore Windows.
- `project.godot`: progetto modificabile con il motore incluso.

Il documento originale è conservato in `docs/README_Volleyball_Codex.md`. Le sue sezioni sono specifiche di progetto, non affermazioni su funzionalità già complete. Per questa build prevalgono le scelte aggiornate della richiesta: creazione da zero in Spike Forever, 6v6 senza personalizzazione e X/Quadrato come azione contestuale.

Motore: [Godot, licenza MIT](https://godotengine.org/license/). Estrazione: [UE Viewer, repository ufficiale](https://github.com/gildor2/UEViewer). Nessuna modifica a Steam o al gioco installato.
