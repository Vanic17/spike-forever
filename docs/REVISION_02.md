# Revisione 02 — camera, contatti e presentazione

Richiesta: esaminare il video `Spike Forever (DEBUG) 2026-10-20 18-49-02.mp4`, passare alla telecamera posteriore e rifare sincronizzazione, movimento, audio e resa visiva.

Il video dura circa 16,64 secondi. Fotogrammi: `video-review/contact-sheet.jpg`. Difetti evidenti: campo lontano, atleti poco leggibili, materiali piatti, punti rapidi e contatti non vincolati alle mani. I test precedenti dimostravano il ciclo logico ma non una buona esperienza visiva o manuale.

La camera usa prospettiva a 48 gradi, posizione (0,9.8,18.4), orientata oltre la rete. C passa a (0,11.5,23); entrambe rimangono dietro la squadra umana.

Gli eventi derivano dai campioni delle animazioni. Il movimento orizzontale del bacino viene normalizzato. Un arco verticale parametrizzato integra l'animazione in-place per attacco, muro, alzata e servizio. La previsione fisica della palla determina l'appoggio necessario: la palla non viene spostata verso mani lontane. La correzione a due ossa delle braccia ha limite locale di 0,38 m e rispetta le lunghezze dei segmenti. Il colpo viene rifiutato se il punto previsto è troppo lontano prima della correzione.

I muratori sono scelti tra la prima linea e mantengono l'assegnazione. Le deviazioni restano fisiche e possono essere recuperate. La rifinitura visiva non viene presentata come già equivalente a Spike Volleyball.

## Asset aggiunti realmente

- `STD_Move_Run_R_S4`, `BLK_Step_Left_Loop_D0_upArm`, `BLK_Step_Right_Loop_D0_upArm` per locomozione.
- `SK_Char_Cloth_FRA_M`, `SK_Char_Eyes_Generic_M_01`, `SK_Char_Hair_M_Asian04`, `SK_Char_Shoes_M_01` per gli atleti.
- Texture originali di pelle, testa, occhi, divise home/away, capelli, scarpe e tessuto.
- `SM_STA01_Test`, `Furn_PublicChairA_LOD0`, `SM_Furn_VolleyNet01A`, `SM_Acc_VolleyBallB` per arena e attrezzatura. Campo e linee sono generati secondo le dimensioni del gioco. L'architettura è ridimensionata e i materiali sono ricostruiti in modo semplificato.
- `Female_Public_Preview` con superfici e texture di testa, torso e pantaloni. Pubblico in tre pose sedute calcolate, mesh istanziate e lieve oscillazione del busto, senza riprodurre il sistema completo originale.
- Ventotto campioni dal soundbank Wwise: servizio, ricezione, alzata, attacco, muro, rimbalzo, passi, scarpe, reazioni e atmosfera. Nomi e ID in `assets/audio/sources.json`. Non sono integrate musiche o voci del commentatore.

Il lettore PAK supporta soltanto il formato v4 ispezionato e zlib standard. Interrompe l'estrazione di una voce cifrata. Nessuna chiave o protezione è stata modificata.

## Evidenza

- `revision-test.log` / `self-test.log`: simulazione e asserzioni.
- `revision-contact-report.json`: posizioni di mani e palla, distanze, spostamenti di ogni atleta.
- `fallback-test.log`: simulazione senza modelli o animazioni originali.
- `capture-final-test.log`: avvio Vulkan e registrazione.
- `Spike Forever - revisione gameplay.mp4`: confronto visivo con il video dell'utente.

Il pallone usa la maschera a canali originale per pannelli gialli/blu, invece della sola base grigia. L'audio viene riprodotto al contatto con posizione e riverbero. Un DualSense è rilevato; resta da eseguire il collaudo manuale completo con entrambi i controller richiesti.
