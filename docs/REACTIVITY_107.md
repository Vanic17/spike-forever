# Reattività e rincorsa — 0.101.0

## Riferimenti osservati

Registrazione utente del 10 novembre, 12:14:58: azione finale, attacco del centrale bianco su palla molto rapida e corta. Il filmato mostra un recupero laterale ampio in un tempo ridotto; non contiene telemetria del motore. Il test usa quindi una situazione rappresentativa, non pretende di ricostruire esattamente tutti i valori del filmato.

Rincorsa: https://www.youtube.com/shorts/F9Z1HkuVpV0, primi dieci secondi, due dimostrazioni. Osservati caricamento breve negli ultimi appoggi e immediata salita delle braccia; la nuova taratura modifica solo la preparazione superiore, non copia o sostituisce il colpo finale.

## Cause e interventi

La CPU conosce subito l'intercetto esatto; il contatto è un incarico senza ritardo percettivo e il vecchio recupero tardivo ammetteva una stance fino a `tempo × 4.8 + 0.52 m`, con gesto di recupero anche dietro il corpo. La posa poteva quindi concludersi malgrado una lettura iniziale irrealistica.

`defense_read107.gd` valuta una volta alla partenza del colpo i drive reali rapidi (almeno 19 m/s), discendenti (rapporto verticale/orizzontale almeno 0.30), corti (entro 4.6 m dalla rete) e con meno di 0.48 s al pavimento. Per tutti i sei difensori confronta la stance con tempo disponibile, velocità iniziale nella direzione utile, accelerazione, limite di corsa, recupero e atterraggio del muro. Il margine al contatto resta tollerante; un difensore già piazzato può riuscire.

Se nessuno ha un margine fisico sufficiente, niente bagher generico o tuffo assistito capace di annullare la lettura: l'atleta può tentare l'avvicinamento e la palla mantiene posizione, velocità e spin fino al pavimento. Non si assegna un punto da percentuale, non si rallenta la palla e non si altera il punteggio prima della collisione. Pallonetti, servizi, muri e palle più lente non entrano in questa regola. Una nuova deviazione azzera la lettura precedente.

Il bagher arretrato è disattivato nei percorsi di ritardo di esibizione/online e carriera singola. Il salvataggio passa da `contact_rescue.proposal/commit`, già dotato di previsione del percorso, ostacoli, limite di rotazione e controllo della velocità. Gli asset originali restano nel progetto per compatibilità, ma il gesto di recupero arretrato non viene più richiesto da questi percorsi.

Per le deviazioni recuperabili della propria squadra appena fuori campo si riduce il ritardo iniziale a 35–60 ms e si migliora l'avvio dell'accelerazione, da 28 a 32 m/s² soltanto per quel soccorritore. Velocità massima e navigazione rimangono invariate. Non si risvegliano monster block già terminali e non si insegue un attacco avversario chiaramente fuori.

La rincorsa manteneva il caricamento presto nella finestra di avvicinamento e lo teneva fino allo stacco. Ora il riferimento temporale è concentrato negli ultimi appoggi, con entrata progressiva del backswing e dissolvenza allo stesso stacco precedente. Libreria `native_motion107.res`, formato 15; la v105 rimane disponibile. Tutte le 36 animazioni native diverse dalla rincorsa conservano gli stessi valori di keyframe.

## Dispersione della battuta

Modificato solo `overcharge_gain` da 1.3 a 1.6 in `serve_target106.json`. A potenza 100% non cambia nulla; oltre, il raggio cresce di più senza un secondo sorteggio di fallo. Il campione resta unico e autorevole online. Nessuna modifica alla barra o alla velocità della battuta.

## Verifiche

- `Test-Reactivity107.gd`: drive impossibile da difesa profonda, stesso drive difendibile da fermo in posizione, indipendenza dalla carica, esclusione pallonetti/muri, inseguimento dei tocchi propri ed esclusione degli out avversari, nuova curva, 36 animazioni di contatto native identiche e assenza del vecchio percorso di bagher arretrato.
- Regressione v105 (1.791 verifiche), mirino/dispersione v106 (206 verifiche), audit live di sei rotazioni per quattro zone e due processi ENet per la battuta del guest.
- Cattura Godot della rincorsa; il video non è un nuovo motion capture misurato.
- `Verify-Reactivity107.py`: controllo dei 216 file personali e confronto byte per byte di database, controlli, timing, integratore, rotazioni, balistica degli attacchi e libreria precedente.

La regola non rende automaticamente punto ogni attacco forte: distingue il difensore già pronto dal recupero che richiederebbe spostamenti impossibili. Le soglie sono tarature di gameplay esplicite, non misure ricavate automaticamente dal video.
