# Spike Forever

Gioco Windows 3D di pallavolo indoor 6 contro 6, contro la CPU, con controller PlayStation, Xbox o tastiera. Squadre e giocatori senza personalizzazione.

**Avvio:** apri `Spike Forever.exe`, poi Options / Start / Invio. Il launcher carica i sorgenti aggiornati: non occorre installare o ricompilare Godot. Lascia l'eseguibile nella cartella del progetto.

**Revisione 08 — nuovi comandi e carica:** il timer oscillante è stato eliminato da tutte le azioni. Questi comandi sostituiscono quelli delle specifiche e delle revisioni precedenti.

## Comandi attuali

| Azione | PlayStation | Xbox | Tastiera |
|---|---|---|---|
| Movimento, anche prima del servizio | Stick sinistro | Stick sinistro | WASD |
| Battuta al salto potente | Tieni e rilascia Croce / X | Tieni e rilascia A | Tieni e rilascia Spazio |
| Battuta jump float | Tieni e rilascia Quadrato | Tieni e rilascia X | Tieni e rilascia Q |
| Ricezione | Croce / X vicino all'arrivo | A vicino all'arrivo | Spazio vicino all'arrivo |
| Alzata normale | Croce / X | A | Spazio |
| Alzata veloce | Quadrato | X | Q |
| Colpo di seconda | Cerchio | B | E |
| Schiacciata | Tieni e rilascia Croce / X | Tieni e rilascia A | Tieni e rilascia Spazio |
| Mira battuta / attacco, 8 direzioni | Stick destro | Stick destro | Frecce |
| Direzione alzata, 4 direzioni | Stick destro | Stick destro | Frecce |
| Sposta il compagno aggiuntivo a muro | Stick destro | Stick destro | Frecce |
| Salto a muro | Croce / X | A | Spazio |
| Inizio / pausa | Options | Start | Invio / Esc |

Croce PlayStation corrisponde ad **A Xbox**. Quadrato PlayStation corrisponde a **X Xbox**. Le assegnazioni sono modificabili in `controls.cfg`. L'interfaccia adatta i nomi al controller riconosciuto; F1 apre l'aiuto.

## Battuta e schiacciata

La barra verde cresce soltanto tenendo premuto. Il rilascio memorizza la potenza e il contatto resta sincronizzato all'animazione e alla palla; non c'è un secondo comando di timing.

- Servizio: puoi arretrare e spostarti dietro la linea prima della carica. Croce avvia la preparazione del salto potente, Quadrato quella del jump float. Durante la carica il giocatore mantiene la preparazione; rilasciando completa lancio e gesto.
- Servizio al 100%: massima potenza valida. Oltre il 100% aumenta il rischio di rete o fuori: 110% carica = 25% rischio, 120% = 50%, da 140% = 100%. Anche l'errore viene simulato fisicamente; il punto arriva quando la palla cade.
- Attacco: un tocco rapido dà poca potenza e la mira più precisa. Le otto direzioni individuano punti del campo, comprese le diagonali verso gli angoli.
- Fino al 70% di potenza la precisione nominale resta 100%; poi scende: 90% potenza = 80% precisione, 100% = 70%. La dispersione effettiva varia da colpo a colpo.
- Attacco oltre il 100%: traiettoria lunga fuori. Se stai ancora tenendo premuto quando arriva la palla, viene utilizzata la carica raggiunta al contatto.

## Ricezione e alzata

La ricezione valuta una sola finestra legata all'arrivo fisico della palla. Premere prima peggiora gradualmente la qualità percentuale; non esistono finestre perfette che si ripetono. Senza pressione la palla non viene salvata automaticamente.

È disponibile un margine tardivo di **100 millisecondi**, con qualità inferiore e un'animazione originale di recupero basso. Il recupero deve comunque essere raggiungibile: non teletrasporta il giocatore o la palla.

La ricezione mira automaticamente al centro della zona 3, a circa 1,5 m dalla rete. Una ricezione perfetta centra il riferimento; una qualità inferiore produce dispersione e costringe il palleggiatore ad adattarsi. La percentuale si trasmette alla qualità dell'alzata.

L'alzata si sceglie direttamente: Croce normale, Quadrato veloce, Cerchio colpo di seconda con animazione originale. Stick sinistra = zona 4, alto = centro, destra = zona 2, basso = pipe. La palla difficile può richiedere un'alzata di sicurezza. Il colpo di seconda conserva le normali limitazioni degli attacchi dalla seconda linea.

## Muro, ruoli e movimento

Lo stick destro ordina al compagno aggiuntivo di andare a sinistra, al centro o a destra. Il muratore principale segue l'attacco. Croce fa saltare gli uomini già in posizione, con un solo salto per giocatore per attacco. Il contatto dipende dalle mani animate e dalla traiettoria, senza barra di timing.

Restano il sistema 5–1, le rotazioni, il libero, le rincorse automatiche, le reazioni individuali e le distanze tra compagni. Il centrale lascia spazio al palleggiatore durante la ricezione in zona 3. La palla continua a rimbalzare dopo il punto. Grafica e suoni sono quelli della revisione precedente.

## Verifiche e documentazione

- `Verifica.cmd`: controlli automatici con asset originali e fallback, input dei controller, carica e sovraccarico, contatti, tattiche, rotazioni, salto unico e qualità del movimento.
- F2: partita dimostrativa; F3: galleria delle 21 animazioni attive; F5: difficoltà; C: distanza della telecamera; R: nuova partita.
- [Dettagli della revisione 08](docs/REVISION_08.md).
- [Anteprima della revisione 08](docs/Spike%20Forever%20-%20nuovi%20comandi%20e%20carica.mp4).
- [Revisione precedente del movimento](docs/REVISION_07.md).
- Le versioni precedenti dei sorgenti sono in `docs/baseline-v01` … `docs/baseline-v07`. Le vecchie specifiche descrivono comandi storici; per i comandi attuali fa fede questa pagina.
- I riferimenti delle animazioni originali attive sono in `assets/active/sources.json`; l'inventario completo è in `docs/animation-inventory.csv`.

I test automatici inviano gli stessi eventi gestiti dai controller. La verifica fisica dei singoli modelli di controller rimane una prova manuale.
