> Historical prototype: integrated in release 0.89.0. The local-only status below describes its earlier review stage.

# Atleta pilota — confronto locale, da approvare

Questo intervento riguarda un solo slot atleta (`players[0]`). Non cambia le luci, la camera, il pubblico o lo stadio. Il normale avvio conserva il prototipo precedente. Il nuovo modello si abilita con **Avvia Spike Forever - prototipo giocatore.cmd**; non è pubblicato su GitHub.

[Confronto interattivo](athlete87-review.html) · [Geometria prodotta](athlete87-build.json) · [Verifiche e prestazioni](athlete87-validation.json).

## Modifiche effettive

- **Testa differente:** integrata la mesh `SK_Char_Head_Tier1_M_Perrin`, presente nell'archivio locale autorizzato di Spike Volleyball, al posto della testa generica Caucasian M02. Non è una scansione nuova creata per questo progetto. La nuova base ha una topologia e UV propri; non viene utilizzata semplicemente la vecchia testa con un colore diverso.
- **Scultura geometrica:** modificati rilievi zigomatici, angolo mandibolare, mento, ponte nasale, arcata sopraccigliare e apertura delle palpebre. Spostamenti localizzati di circa 1–4,4 mm oltre al cambio della mesh di base. Raccordo inferiore del collo adattato al colletto. L'immagine grigia permette di distinguere questi interventi dalla texture.
- **Capelli e barba:** costruiti offline 11.442 ciocche di capelli e 5.545 ciocche di barba con sezioni triangolari rastremate e traiettorie curve. Sono geometria opaca pesata alla testa, non un nuovo effetto di illuminazione. La base del cuoio capelluto è ritagliata alla linea di attaccatura; il groom non aggiunge ossa o simulazione dei capelli.
- **Pelle e occhi:** albedo e normal corrispondenti alla nuova testa; roughness ricavata dal canale alpha dell'atlante facciale. Iride ridimensionata rispetto alla sclera, materiale oculare dedicato e ciglia separate dalla pelle, per mantenere compatibile l'editor dell'aspetto. Texture facciale 1024px, normal 2048px: non vengono dichiarati dettagli 4K inesistenti.
- **Mani:** superficie raffinata con rilievi dei giunti e dei tendini, conservando i pesi delle dita. Dieci piccole superfici convesse per le unghie, pesate alle falangi esistenti. Non è una nuova mano anatomica scolpita integralmente.
- **Divisa:** pieghe geometriche localizzate su vita, fianchi e pantaloncini; materiale tessile dedicato. Conservati UV per le stampe, numero, nome, maglia e sponsor della squadra scelta.
- **Scarpe:** il pilota usa il secondo modello di scarpa disponibile con la sua normal map e maschera. Nel percorso di anteprima gli altri atleti hanno varianti indipendenti di texture e colore: non vengono uniformati al pilota. Nessuna nuova geometria del volto o del corpo viene estesa agli altri undici atleti.

Il nome interno Perrin indica la provenienza della base. Non cambia identità, nome, ruolo o statistiche del giocatore del database e non rappresenta una ricostruzione fedele del suo volto reale. Il groom è un preset curato per questa verifica; non è ancora una libreria completa di acconciature per tutte le identità.

## Confronto controllato

Sei viste principali a 1920×1080: volto, profilo, corpo intero, gameplay, mani/divisa e geometria grigia. Sono framebuffer reali di Godot; nessuna immagine è ritoccata per il confronto. Disponibili anche le catture aggiuntive di campo, pubblico e replay.

Verificati identici: squadre, posa scheletrica, posizione dei dodici atleti, clock, palla, velocità, fase, RNG, camera, FOV, esposizione, tonemapping, luce principale e luci del campo. Le immagini grigie nascondono capelli e barba da entrambe le parti e uniformano il materiale del viso. Il nuovo atleta mantiene la stessa animazione del precedente.

## Compatibilità e verifiche

Lo scheletro rimane quello esistente a 115 ossa; stessi nomi, bind frame e animazioni PSA/AnimationTree. Le mesh conservano quattro influenze normalizzate per vertice. I campioni di deformazione coprono attesa, ricezione, alzata, schiacciata, muro, battuta al salto e tuffo. Le prove verificano anche che l'applicazione del prototipo non cambi contatti, RNG, rotazioni, punteggi o movimento.

Le verifiche confrontano gli hash dei 179 file protetti della baseline, compresi fisica, animazioni, IA, controlli, rete e dati. Le sole integrazioni in file preesistenti sono la selezione del prototipo dietro flag e il richiamo visivo dopo la modifica dell'aspetto. Non vengono modificati `avatar.gd`, parser PSA/PSK, AnimationTree, contatti o statistiche.

Risultato finale: 6.370.603 controlli e 204.365 campioni di deformazione superati, più tre cicli renderizzati di creazione/modifica/chiusura. Nei log finali non compaiono nuovi errori del motore, degli script o degli shader. Resta registrato l'avviso già noto del sandbox sull'accesso al deposito dei certificati.

Tre creazioni/chiusure reali della scena con cambio dei preset e dell'aspetto; tre benchmark per versione con lo stesso scenario. I dati nel rapporto descrivono il costo di **un solo atleta**, non di dodici copie del modello. Tutte le prove usano profili separati da carriera, Diventa un mito e database personali.

Su RTX 5080, Godot 4.5.1 Forward+, 1920×1080 Alto, scala 100%, MSAA 4× e VSync disattivato: media delle tre prove 105,755 FPS prima e 105,792 dopo; GPU 2,332 → 2,508 ms e p99 del frame 14,794 → 14,892 ms. Allocazione video del motore circa +51,6 MiB. Sono prestazioni comparabili nello scenario ripetibile, con un costo grafico aggiuntivo misurato; non una promessa per tutte le situazioni. Le ciocche sono pesate dalla GPU, senza generazione o riallocazione a ogni frame.

## Limiti e valutazione

Si tratta di un prototipo con modifiche geometriche reali e confrontabili, non del completamento di una rosa fotorealistica. La base facciale e gli atlanti restano asset della generazione originale; il groom procedurale ha ancora un aspetto molto pettinato e deve essere valutato artisticamente. Il corpo sotto la divisa resta derivato dal modello precedente. Non viene dichiarato raggiunto uno standard fotografico o AAA.

Prima di estendere il modello agli altri giocatori serve la verifica visiva di questo candidato. La galleria espone anche profilo, grigio e mani proprio per valutare forme, raccordi e difetti residui, senza affidarsi soltanto alla luminosità o al conteggio dei triangoli.

## Riproducibilità

`tools/Build-Athlete87.gd` genera le mesh in modo deterministico (seed 87019), usando il parser PSK esistente e una copia locale della funzione di suddivisione. `tools/Validate-Athlete87.ps1` esegue le prove e aggiorna il confronto. I sorgenti estratti restano in `assets/art/athlete87/source`; provengono dal gioco locale, non da un nuovo download. Non viene attribuita loro una licenza di redistribuzione diversa da quella autorizzata per il progetto.
