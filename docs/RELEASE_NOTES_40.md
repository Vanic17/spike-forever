# Piloni, rincorse e raggruppamento dopo il punto

## Fine punto

Il video 23-12-38 mostra il raggruppamento dopo il punto. Il movimento continuava a scegliere passi laterali o all'indietro da difesa; alcune pose di attesa, inoltre, erano mezzi squat. Il nuovo contesto di fine punto usa camminata eretta, orientamento verso lo spostamento e attesa rilassata. Il recupero da un salto o tuffo già effettuato viene completato prima della transizione: non si interrompe un atterraggio per mettere in piedi il giocatore di colpo.

L'audit delle sorgenti misura la testa dell'attesa bassa a circa 1,29–1,36 m contro 1,70 m della posa rilassata. Nel test dinamico del nuovo raggruppamento il minimo, terminati i recuperi, è circa 1,66 m. Sono misure del rig di prova, non l'altezza anagrafica dei giocatori.

## Muro manuale con pilone automatico

Il laterale che fronteggia la zona dell'attacco viene incluso automaticamente nel muro e presidia il proprio punto vicino alla rete. La lettura comincia durante l'alzata avversaria e si aggiorna sulla sua destinazione effettiva. Un attacco dalla zona 2 avversaria impegna il pilone nella propria zona 4; un attacco dalla zona 4 avversaria quello nella propria zona 2.

LS continua a muovere il centrale. Il pilone automatico non viene trascinato insieme al centrale; quest'ultimo può chiudere dal suo lato interno, senza condividere la stessa destinazione. **Croce su PlayStation / A su Xbox comanda il salto di entrambi**: il posizionamento automatico non provoca alcun salto da solo.

Il laterale lontano resta in copertura sui tre metri, seguendo la discesa progressiva già presente. **L2/R2, oppure LT/RT**, continuano ad avvicinare i laterali alla posizione del centrale, consentendo anche il muro a tre. Un comando esplicito sul pilone ha precedenza sulla sua posizione automatica; i membri di un salto rimangono gli stessi fino all'atterraggio.

## Schiacciate e CPU

La preparazione dell'attaccante comincia durante il volo della ricezione: apertura più profonda sulle bande e sulla pipe, rincorsa compatta per il primo tempo, ultimi passi già avviati prima che il palleggiatore rilasci la palla. Vengono alternate le prestazioni originali con rincorsa LRL appropriate al lato dell'attacco.

Il prefisso delle animazioni di schiacciata aveva circa 0,43–0,60 secondi disponibili. Il suo tempo visivo viene ora esteso, con una variazione progressiva della velocità di riproduzione fra 0,4 e 0,2 secondi dal contatto. Gli ultimi 0,2 secondi, il contatto, la traiettoria della palla e la riproduzione successiva al colpo mantengono il ritmo originale. Il tempo reale e il movimento del giocatore restano separati dal tempo della posa; non viene aumentata la velocità massima di corsa.

La CPU torna a leggere prima le palle normali e a ricevere più precisamente. Ridotte le esitazioni complete e le probabilità di errori gravi, senza eliminare svirgolate, overpass e palloni staccati. Si aggiungono una difesa in allungo e una risposta di riflesso, con qualità e tempi differenti: sette risposte complessive. I colpi nella fascia vincente e i controlli del giocatore restano quelli già sviluppati.

## Verifiche

- Pilone automatico, movimento indipendente del centrale, copertura del laterale lontano e salto comandato in tutte le sei rotazioni, sui due lati dell'attacco. Verificata anche la lettura durante l'alzata e la precedenza dei trigger.
- 48 combinazioni di rotazione, frequenza di aggiornamento e selezione dei laterali; eventi standard di stick e trigger dei controller, salto manuale e conservazione del muro in volo. La parte del test che esamina i soli trigger usa esplicitamente un'alzata senza destinatario ancora noto.
- Raggruppamento realmente animato dei dodici giocatori, con pose erette dopo il recupero; rendering di `wall40-preview.png` e `regroup40-preview.png`.
- Matrici delle ricezioni e alzate affollate, contatti delle schiacciate, coperture e confronto AnimationTree/PSA delle animazioni selezionate.
- 96 costruzioni da ricezione profonda: sei rotazioni, entrambe le squadre, quattro direzioni e alzata normale/veloce. Tutti e tre i contatti completati in ogni caso; attaccanti in movimento già durante il primo passaggio. Verificata anche la continuità del nuovo orologio visivo della schiacciata e il contatto finale invariato.
- 2.000 letture CPU a parità di semi casuali: tutti i sette esiti raggiungibili; indice medio di qualità 0,630 contro 0,485 della formula v37, esitazioni complete 63 contro 153. Questo confronto descrive il modello di lettura, non un tasso di vittoria o una percentuale di palle difese in una partita reale.
