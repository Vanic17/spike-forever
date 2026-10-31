# Doppio cambio — interfaccia e verifica controller

Il menu Sostituzioni conserva il percorso del cambio singolo. Dalla prima riga del sestetto, Su raggiunge le schede; Destra porta a Doppio cambio. A / Croce apre la scelta. Il solo scorrimento non seleziona atleti.

La colonna sinistra contiene gli opposti di riserva, quella destra i palleggiatori di riserva. Si sceglie prima l'opposto e poi il palleggiatore. Il riepilogo indica entrambe le uscite e gli ingressi, con un solo pulsante di conferma. Quando il doppio cambio è attivo la scheda diventa Rientro titolari: entrambe le identità originarie sono presentate insieme e rientrano con una sola conferma. B / Cerchio risale di un passaggio senza applicare scelte.

Le condizioni regolamentari sono sempre chieste al gestore della partita; il menu non modifica direttamente sestetto, contatori o ruoli. Durante uno scambio la conferma richiede al gestore una transazione da applicare alla successiva palla ferma. Il client online inoltra la coppia all'host.

## Verifiche

- `Test-DoubleUI74.gd`: 297 controlli superati, 12 flussi completi di ingresso e rientro, risoluzioni 1280×720, 1920×1080 e 2560×1440, dispositivi virtuali 0, 3 e 7.
- Eventi nativi `Input.parse_input_event`, A/B senza alcuna mappatura `ui_accept` / `ui_cancel`: il menu funziona anche con controller rilevati su un indice diverso da zero. D-pad e stick sinistro verificati.
- Riserve iniziali e ultime della lista; sette identità aggiuntive di test per ruolo obbligano lo scorrimento. La riga focalizzata resta interamente visibile e la conferma rimane dentro lo schermo a tutte le risoluzioni.
- Nessuna selezione o sostituzione durante lo scorrimento. Prima della conferma i due titolari e il conteggio restano invariati. Ingresso immediato e programmato: 2 cambi; rientro: altri 2.
- Verificata traduzione inglese completa dei nuovi pulsanti; le vecchie traduzioni generiche per singole parole non devono troncare la frase.
- `Test-Substitution69.gd`: regressione superata, 42 casi controller del cambio singolo, comprese riserve in fondo e programmazione durante lo scambio; cinematica e posti in panchina preservati.
- `Capture-DoubleUI74.gd`: quattro schermate con il motore grafico incluso, esaminate a 720p e 1080p, ingresso e rientro, italiano e inglese. Nessuna sovrapposizione rilevata.

Questi test simulano eventi controller nel motore; non attestano una prova fisica con ogni modello di pad.
