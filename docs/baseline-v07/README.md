# Spike Forever — revisione del gameplay

**Aggiornamento 07 — solo movimento:** risposte individuali, apertura dello spazio al compagno, passi e busto sovrapposti durante la preparazione, animazione uscente mantenuta in movimento e fermate più graduali. Regole, controlli, timing e fisica conservati con verifica di 58 checksum. [Dettagli e verifiche](docs/REVISION_07.md).

Video attuale: [fluidità e movimenti individuali](docs/Spike%20Forever%20-%20fluidita%20e%20movimenti%20individuali.mp4). Le note sotto descrivono le revisioni precedenti.

**Aggiornamento 06:** salto unico del muro per attacco, alzate pianificate con il destinatario visibile, preparazione e copertura senza palla, scelte CPU legate alla ricezione e fisica condivisa con spin e deviazioni. [Dettagli e verifiche](docs/REVISION_06.md). Le revisioni seguenti sono storiche.

Video attuale: [coordinazione e salto unico](docs/Spike%20Forever%20-%20coordinazione%20e%20salto%20unico.mp4).

**Aggiornamento 05:** sistema 5–1 con ruoli fissi, libero, rotazione oraria corretta, coordinate speculari della CPU e corridoi distinti a muro. Distanze fisiche controllate durante gli spostamenti. [Dettagli, ruoli e verifiche](docs/REVISION_05.md). Le revisioni seguenti sono storiche.

Anteprima della revisione 05: [ruoli, rotazioni e muro](docs/Spike%20Forever%20-%20ruoli%20rotazioni%20e%20muro.mp4).

**Aggiornamento 04:** palla libera di rimbalzare dopo il punto, cadenza dei passi calibrata sulle animazioni, appoggi dei piedi con IK, transizioni sulle articolazioni locali, atterraggi conservati e posture differenti per ruolo. Vedi [REVISION_04](docs/REVISION_04.md). Le note delle revisioni precedenti qui sotto sono storiche.

Anteprima attuale: [appoggi e rimbalzi, 32 secondi](docs/Spike%20Forever%20-%20appoggi%20e%20rimbalzi.mp4).

**Aggiornamento 03:** corretto Quadrato in ricezione (penalità nascosta incoerente con la barra), contatti calcolati al tempo esatto, nuovi movimenti di preparazione/copertura/difesa e palla più rapida. Grafica e audio conservati. Dettagli e risultati aggiornati: [REVISION_03](docs/REVISION_03.md). Le statistiche della revisione precedente riportate sotto sono storiche.

Gioco Windows 3D di pallavolo indoor **6 contro 6**, squadra umana contro CPU, senza personalizzazione. Il progetto usa Godot 4.5.1 e include il motore: non serve installarlo.

**Avvio:** doppio clic su `Spike Forever.exe`, quindi Invio / Start / Options. Mantieni l'eseguibile nella cartella con `src`, `assets` e `tools`.

## Revisione rispetto al video del 20 ottobre 2026

- Telecamera **prospettica da dietro la linea di fondo**, campo più vicino e piccolo inseguimento laterale della palla. C alterna due distanze, entrambe posteriori.
- Contatti riscritti: le traiettorie arrivano al punto delle mani previsto dall'animazione. Il colpo richiede una distanza valida; una correzione limitata delle braccia con IK completa il contatto, senza spostare arbitrariamente la palla.
- Il servizio comprende una traiettoria di lancio e un evento di contatto programmato. Il rilascio registra potenza e tempismo; il colpo avviene all'incontro tra mani e palla.
- Movimento dei dodici atleti con accelerazione, copertura, rientro, separazione e orientamento. I muratori mantengono l'assegnazione durante l'alzata. La traslazione inclusa nelle animazioni viene rimossa per evitare movimenti nascosti della mesh.
- Modelli e texture originali per corpo, testa, occhi, capelli, divise, scarpe, rete e pallone. Arena indoor con tribune, sedili e pubblico texturizzato. Illuminazione Forward+, ombre e occlusione ambientale.
- Sostituiti i bip con **campioni reali** di servizio, ricezione, alzata, attacco, muro, rimbalzi, passi, scarpe e pubblico, con posizione sul campo e riverbero della palestra.
- Interfaccia compatta: punteggio in un angolo e un unico riquadro per tempismo e potenza. Il cursore si ferma alla conferma.

Video: `docs/Spike Forever - revisione gameplay.mp4`. Cattura: `docs/revision-preview.png`. I sorgenti della prima build sono conservati in `docs/baseline-v01`.

## Comandi

| Azione | Xbox | PlayStation | Tastiera |
|---|---|---|---|
| Movimento assistito e correzioni | Stick sinistro | Stick sinistro | WASD |
| Ricezione e alzata | X | Quadrato | Spazio |
| Potenza e tempo di servizio/attacco | Tieni e rilascia X | Tieni e rilascia Quadrato | Tieni e rilascia Spazio |
| Mira servizio/attacco, 8 direzioni | Stick destro | Stick destro | Frecce |
| Destinazione alzata | Stick destro | Stick destro | Frecce |
| Alzata veloce | LB + X | L1 + Quadrato | Q + Spazio |
| Leggi il muro durante la freccia | Stick destro | Stick destro | Frecce |
| Salto a muro manuale | X | Quadrato | Spazio |
| Orienta le mani in aria | Stick destro | Stick destro | Frecce |
| Cambia jump float / jump power | Y, provvisorio | Triangolo, provvisorio | Tab |
| Inizia / pausa | Start | Options | Invio / Esc |

**Alzata:** sinistra zona 4, alto centrale, destra zona 2, basso pipe. Avvicinamento e salto dell'attaccante sono automatici. La squadra umana occupa la metà vicina.

**Ricezione e alzata:** premi quando il cursore attraversa il segno centrale, vicino all'arrivo della palla. La barra deriva dalla previsione di contatto. Una pressione anticipata non produce un contatto immediato a distanza.

**Attacco:** carica prima dell'arrivo e rilascia al contatto. Lo stesso rilascio determina potenza e tempismo. La precisione nominale varia dal 100% al 70% con la carica; la dispersione tiene conto anche del tempismo.

**Servizio:** tieni per avviare il lancio e caricare, poi rilascia entro il limite verde della potenza. Oltre il limite è fallo. Cambia tipo prima del lancio. La selezione Y/Triangolo/Tab è provvisoria e modificabile in `controls.cfg`.

**Muro:** RS sceglie la formazione, X/Quadrato esegue il salto. La previsione corretta non fa saltare automaticamente la squadra umana. La demo invia la stessa azione per simulare il giocatore.

## Altri tasti

- F1: aiuto e dati di verifica.
- F2: demo CPU contro CPU.
- F3: riproduzione delle tredici animazioni; frecce per cambiarle.
- F5: tempismo assistito / standard / esperto.
- C: distanza della telecamera posteriore.
- R: nuova partita.

Un DualSense è stato rilevato durante la verifica grafica. Mappatura X Xbox / Quadrato PlayStation e ID variabili sono verificati tramite eventi; manca un collaudo manuale completo con entrambi i controller fisici.

## Verifiche e limiti

`Verifica.cmd` controlla gli errori di script e l'esito reale degli scenari; non considera sufficiente il solo codice di uscita del motore. Esegue una simulazione con asset e una con giocatori provvisori.

Nella verifica della revisione: **16 punti, 156 contatti, scambio massimo di 35 tocchi**. Distanza massima tra punto di contatto delle mani e centro della palla: **0,085 m**, inferiore al raggio della palla di 0,105 m. Verificati anche movimento di tutti i dodici atleti, quattro alzate, varianti veloci, pipe, precisione, sovraccarico del servizio e formazioni del muro. Report: `docs/revision-contact-report.json`.

La build è stata avviata e registrata con Vulkan Forward+. La registrazione contiene 1.800 fotogrammi a 60 FPS; questa frequenza non costituisce un benchmark su tutti i PC. I test headless nell'ambiente limitato possono segnalare accesso negato al deposito certificati Windows: il gioco e le verifiche sono offline.

**La rifinitura visiva non è ancora equivalente a Spike Volleyball.** Sono riutilizzati asset originali, ma il sistema dei materiali Unreal non è riprodotto integralmente. Restano da migliorare transizioni delle animazioni, appoggio dei piedi, varietà del pubblico, regia e bilanciamento. Il pubblico usa un modello originale in tre pose sedute e lieve oscillazione, senza reazioni individuali complete.

Le collisioni del muro usano il segmento tra le mani e la palla, con controlli di tempo e qualità, senza una mesh fisica completa delle dita. Restano incompleti invasione, doppio tocco, vincoli completi della seconda linea, cambio di campo tra i set e multiplayer. La pipe prevede lo stacco dietro i tre metri, senza tutti i vincoli di ruolo. Set a 25, due punti di scarto, al meglio dei cinque.

## Asset e sorgenti

L'installazione Steam è stata usata in sola lettura. Esportate **2.696 animazioni PSA** in `assets/spike`; tredici sono collegate alla partita o alla locomozione in `assets/active`. Nomi originali: `assets/active/sources.json`.

La gerarchia delle animazioni è ricostruita per nome dal PSK; mesh e pesi restano originali. Il corpo usa 115 ossa e le animazioni ne descrivono 145. Materiali e texture provengono da `assets/art` e `assets/arena_source`. Le sorgenti dei 28 campioni audio sono in `assets/audio/sources.json`. Nessuna chiave o protezione è stata modificata; gli asset locali sono esclusi da Git e non sono stati pubblicati.

- `src/main.gd`: partita, input, AI e unica autorità della palla.
- `src/avatar.gd`: animazioni, locomozione, skinning, normalizzazione e IK.
- `src/arena.gd`, `src/crowd.gd`, `src/source_assets.gd`: ambiente, pubblico e materiali.
- `src/match_audio.gd`: audio spaziale e atmosfera.
- `src/timing.gd`, `src/hud.gd`: tempismo e interfaccia.
- `src/psa.gd`, `src/psk.gd`: risorse ActorX.
- `tools/Test-Game.ps1`: verifica con report e controllo degli errori.

Specifiche originali: `docs/README_Volleyball_Codex.md`. Provenienza: `docs/ASSET_INVENTORY.md` e `docs/REVISION_02.md`. Motore [Godot, MIT](https://godotengine.org/license/); estrazione [UE Viewer](https://github.com/gildor2/UEViewer); decodifica [vgmstream](https://github.com/vgmstream/vgmstream).
