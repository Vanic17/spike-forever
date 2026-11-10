# Mirino, dispersione e difese — 0.100.0

## Flusso

Il mirino parte al centro della metà avversaria e si muove con RS, oppure I/J/K/L, sul piano del campo. La direzione segue la proiezione della camera anche nelle visuali laterale e invertita online. LS mantiene il movimento del battitore prima della carica. Nessuna modifica a L1/LB.

La scelta salto/float blocca il centro e avvia la carica consueta. Durante la carica cambia soltanto il raggio. Il rilascio congela tipo, potenza, statistica, freccia, r90, seme e destinazione effettiva. Una ritirata automatica di sicurezza prima del lancio non estrae un nuovo campione. Il mirino scompare all'avvio del lancio, in pausa, replay e sullo schermo avversario.

## Modello

Configurazione versionata: `assets/gameplay/serve_target106.json`, schema 1. Il flag `enabled=false` ripristina il servizio precedente, inclusa la mira LS durante la carica. Sensibilità e deadzone sono configurabili nello stesso file, senza modificare `controls.cfg`.

`r90 = (0.25 + 0.012 × (99 − Battuta)) × tipo × potenza × freccia`.

- Tipo: float 0.82, salto 1.12.
- Frecce: su 0.82, diagonale su 0.92, neutra 1, diagonale giù 1.10, giù 1.22.
- Fino al 70%: coefficiente 0.75; dal 70 al 100%: `0.75 + 0.012 × (P − 70)`.
- Oltre il 100%: `1.11 + 1.3 × ((P − 100)/20)^1.5`. Continua a crescere anche oltre il 120%; nessun tetto fittizio alla barra.

La gaussiana bidimensionale isotropa usa Box–Muller, con sigma `r90 / sqrt(−2 ln(0.1))`. Il 10% dei campioni può essere esterno al cerchio. Solo il centro desiderato è limitato alla metà campo; il punto estratto non viene mai riportato dentro. A–D non viene riapplicata: determina già la freccia della partita. Si legge Battuta **prima** della modifica della freccia. Con gameplay senza valori si usa 85/neutra per tutti, rispettando l'opzione preesistente.

Esempi di r90, neutra, 100%:

| Battuta | Float | Salto |
| --- | ---: | ---: |
| 40 | 0.872 m | 1.191 m |
| 70 | 0.544 m | 0.743 m |
| 99 | 0.228 m | 0.311 m |

La curva di velocità preesistente rimane proporzionale alla sovraccarica. Si calibra l'arco soltanto verso il centro desiderato, con margine nominale al nastro di 2.60 m. Durata e spin nominali vengono poi usati verso il punto estratto: non si ricalcola una traiettoria che lo salvi dalla rete. L'integratore, le collisioni e il rimbalzo della rete restano quelli esistenti. Non c'è un ulteriore tiro casuale rete/fuori. Un eventuale servizio perfetto non può trasformare un campione fuori in un ace valido.

## Difese e varianti visive

La CPU mantiene le scelte tattiche e le coperture del muro precedenti. Sui normali attacchi/servizi il fattore di qualità del timing passa a 0.92, con 15 ms aggiuntivi di lettura e una piccola crescita delle esitazioni sotto pressione. Nel confronto a seme fisso di 4.000 difese forti la qualità media scende circa da 0.639 a 0.598: non è una probabilità di punto né una misura su un intero campionato.

I contatti realmente falliti usano per lo più svirgolate laterali da 2.5–6.5 m, con variabilità di profondità e tempo di volo; il 15% mantiene una caduta corta. Le palle non toccate proseguono senza attribuire un tocco o alterare la velocità. Le esitazioni vengono decise durante la lettura, non inventate dopo il contatto. Gli attacchi vincenti forti mantengono la loro corsa fino a terra. Sono riutilizzati gli appoggi nativi esistenti (passo, piattaforma, posizione bassa, ginocchio), con blending e contatto già presenti: nessuna nuova scrittura concorrente sullo scheletro.

## Online, replay e dati

Protocollo `SF0100-SERVE106`: richiede client aggiornati. Il client predice solo il cursore; invia il centro assoluto anche nel comando affidabile di scelta battuta. L'host valida lato/fase, blocca il centro e campiona una volta. Gli snapshot trasportano centro/blocco e la normale palla autorevole. Il client non estrae campioni propri. Seme, potenza, skill, freccia, centro, destinazione ed esito sono nel log di rally; il replay usa la palla registrata, senza risorteggi.

Non ci sono scritture del modello nel database o nei salvataggi. Le modifiche alle identità fatte dai test sono esclusivamente in memoria, con APPDATA/LOCALAPPDATA isolati.

## Verifiche e limiti

- `Test-Serve106.gd`: 600.000 campioni in 150 combinazioni, monotonia, frecce, linee, input relativo alle tre camere, blocco al tipo, campione unico, campi snapshot, voli reali per entrambi i lati/tipi/potenze, rete da dispersione, varietà svirgolate, CPU e fallback.
- `Run-OnlineServe106.ps1`: due processi ENet reali, mira e durata note del guest, blocco e campione esclusivamente host.
- Regressione attacchi v105 e audit delle sei rotazioni/quattro zone.
- `Verify-Serve106.py`: confronto binario database/controlli/timing/integratore/rotazioni/animazioni rispetto alla release 0.99.0 e hash dei 216 file personali.
- `serve106-preview.mp4`: cattura Godot reale con statistiche 40/95, float/salto, mira e sovraccarica. Non è una prova effettuata fisicamente con ogni marca di controller: usa i medesimi assi SDL RS di PS/Xbox/Claw; eventuali dispositivi con mapping non standard richiedono una verifica hardware.

Il cerchio descrive la dispersione iniziale sul pavimento in assenza di ostacoli: una collisione reale con rete o giocatore può cambiare l'esito. Le tarature sono centralizzate, non stime ricavate da dati di partite reali.
