# Spike Forever 0.76.0

## Difesa bassa

Nuovo bagher basso laterale dal riferimento `Oz93Tf6y3DE`, anche nella variante speculare: trasferimento del peso sulla gamba piegata, appoggio largo, bacino basso e piattaforma orientata. Preparazione e risalita sono progressive; le gambe mantengono le lunghezze anatomiche e gli appoggi rimangono sul pavimento. L'altezza d'intercetto è ricavata dalle mani della nuova animazione, non dalla vecchia posa più alta.

Le pose sono adattamenti creati sullo scheletro esistente e convertiti in clip native immutabili. L'AnimationTree e le correzioni di contatto originali restano il percorso di riproduzione. Non viene usato il laboratorio separato di animazioni.

## Ricezione di Diventa un mito

Corretti due problemi distinti:

- Negli aggiustamenti laterali su servizio il corpo si girava verso la corsa, ruotando anche la piattaforma lontano dalla palla. Ora mantiene l'orientamento di ricezione mentre i piedi si spostano.
- Premendo bagher si poteva scegliere di nuovo una posa differente, cambiando altezza e punto d'intercetto quando il giocatore era già arrivato sulla posizione prevista. Il comando conserva ora il gesto preparato per quella traiettoria.

Verificate trenta ricezioni su traiettorie reali nelle sei rotazioni, comprese correzioni laterali e palloni laterali. Verificati i contatti delle due nuove difese a 60 e 120 Hz, oltre ai comandi PlayStation/Xbox. Restano il movimento manuale, il timing arcade della 0.75 e la necessità di posizionarsi correttamente.

## Aggiornamenti selettivi

La release pubblica un indice separato `SpikeForever-UpdateIndex.json`. Dopo la conferma dell'aggiornamento:

1. Viene verificato l'hash dell'indice e confrontato lo SHA256 dei file installati con la versione scelta, fuori dal thread grafico.
2. Vengono scaricate dal pacchetto soltanto le parti compresse dei file diversi o mancanti, usando richieste HTTP Range. I file identici non vengono scaricati né riscritti.
3. Ogni file viene decompresso e verificato; il gioco si chiude soltanto quando il piccolo pacchetto selettivo è pronto.
4. L'installer ricontrolla anche i file rimasti invariati, poi applica i cambi con backup e rollback. Se la scansione non è utilizzabile, la base è troppo diversa o il server non supporta i Range, rimane disponibile il download completo verificato.

Sono conservati controlli personalizzati, salvataggi dei campionati, Diventa un mito e modifiche al database salvate dalla sezione Modifica. Percorsi personali e cartelle deviate non possono entrare nell'indice di aggiornamento.

Non serve una catena di patch intermedie: vengono confrontati i file con l'intera versione di destinazione. È possibile anche riparare file danneggiati scegliendo nuovamente la stessa versione.

**Passaggio iniziale:** i client 0.75 e precedenti non conoscono il nuovo sistema e scaricano ancora una volta il pacchetto completo per passare alla 0.76. Dalla 0.76 gli aggiornamenti che pubblicano l'indice utilizzano la scansione selettiva. Le vecchie release senza indice restano installabili con il metodo completo.

Prova reale GitHub/CDN: scansione di 1.699 file, riparazione di un file con 44.763 byte di contenuto scaricato anziché l'archivio da 779.336.506 byte. L'indice verificato è un download separato di circa 323 KB. Provati anche mancati cambiamenti, file mancanti, dati personali, hash errati e modifiche fra scansione e installazione.

Rapporti: `reception76-real-flights.json`, `defense76-tests.json`, `defense76-real-contacts.json`, `selective76-offline.json`, `selective76-ui.json`, `selective76-live-range.json`. Anteprima: `defense76-preview.mp4`.
