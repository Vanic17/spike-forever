# Spike Forever 0.55.0

## Pipe e attacchi dietro

La pipe prenota il corridoio già durante il secondo tocco. Il palleggiatore conserva la priorità sul contatto; i compagni di appoggio iniziano a lasciare il percorso prima del rilascio dell'alzata. Una destinazione memorizzata viene ricontrollata contro l'intero percorso di rincorsa.

Riprodotto un altro incastro su palla dietro da ricezione difficile: la destinazione con cui un compagno doveva cedere il passo veniva limitata dai bordi del campo, rientrando nel punto d'attacco. Ora il corridoio viene ricontrollato dopo quel limite, e il compagno lascia libero anche l'ultimo tratto. Non vengono rimossi i controlli fisici tra giocatori.

L'alzata usa l'altezza della mano dell'animazione effettivamente scelta per il destinatario, per banda, opposto e pipe, oltre al centrale. Il vecchio uso dell'altezza generica poteva disallineare il contatto rispetto alla rincorsa reale.

Quando è proprio l'opposto a effettuare un secondo tocco d'emergenza, la scelta dietro cerca un altro OH/OPP idoneo: non viene reinterpretata silenziosamente come un primo tempo al centrale. La direzione richiesta resta distinta dal ruolo naturale del destinatario. Nessuna modifica all'ordine regolamentare delle rotazioni.

## Centrale: primo tempo e 7

- **X PlayStation / A Xbox:** primo tempo più vicino al palleggiatore.
- **Quadrato PlayStation / X Xbox:** mantiene la “7” più larga.
- La finta predefinita rimane la minaccia larga. La scelta confermata del palleggiatore indirizza la rincorsa effettiva; va data prima dello stacco.
- Stesso tempo della 7: il riferimento del primo tempo è 170 ms dopo il palleggiatore contro 160 ms della 7. Nei casi già pronti verificati la differenza effettiva rimane sotto 35 ms.

Nei confronti controllati, la distanza laterale del primo tempo è circa 1,18–1,24 m rispetto a 1,65–1,77 m della 7, senza cambiare le animazioni di salto. Se una palla o una rincorsa non permettono fisicamente il primo tempo, rimane la costruzione di sicurezza: nessun salto teletrasportato o palla accelerata per nascondere un ritardo.

Il suggerimento a schermo distingue i due colpi quando si seleziona il centro. Rete, tocchi, rotazioni, potenza e barre restano invariati salvo questa scelta specifica del centrale.

## Camera bassa e reattività

Quarta vista da dietro, più bassa: altezza 8,1 m rispetto a 9,8 m della principale. **C / Triangolo / Y** scorre le camere offline. Online lo stesso comando alterna la vista principale e quella bassa, sempre dal proprio lato, con mira invariata.

Tempi individuali di lettura dei compagni leggermente ridotti e filtro di orientamento verso la copertura più pronto. Non sono state aumentate le velocità massime dei giocatori; vengono preservate accelerazione, frenata, atterraggio e le differenze tra i tempi di reazione. Resta la precedente gestione degli errori della CPU dopo il muro.

## Muro

Piccolo aumento della soglia del contatto esterno necessario per il mani fuori, senza cambiare la forza delle traiettorie esistenti. Su 10.000 contatti identici prima/dopo:

| Esito | Prima | Dopo |
| --- | ---: | ---: |
| Mani fuori | 3.741 | 3.261 |
| Muro forte verso terra | 1.944 | 2.019 |
| Altri tocchi giocabili | 4.315 | 4.720 |

Circa il 13% in meno di mani fuori nel campione; la maggior parte viene redistribuita su tocchi giocabili. Questi numeri riguardano contatti già avvenuti con le mani, non tutti gli attacchi di una partita.

## Verifiche

- 72 costruzioni pipe/dietro: tutte le sei rotazioni, qualità 35/65/95%, alzate normali e veloci; nessun cambio imprevisto di destinatario/direzione.
- 72 rincorse della suite precedente, entrambe le squadre e tutte le rotazioni, compresi stacco fuori dai tre metri e contatto dentro per D/pipe.
- 24 costruzioni al centro, primo tempo/7 su entrambi i lati, con confronto delle distanze e del tempo nei casi pronti.
- 36 selezioni del destinatario dietro, variando rotazione e giocatore impegnato nel secondo tocco: nessun MB selezionato al posto della banda/opposto.
- 36 costruzioni complete della suite precedente, intercetti delle varianti e 20 scenari di traffico/recupero a terra.
- Quattro camere offline e due viste frontali specchiate online; verifica grafica della camera bassa.
- Partita online tra due processi: contatti di entrambe le squadre, pausa e ritorno alla home.

Richiesta **0.55.0 su entrambi i client online** per sincronizzare il tipo di attacco del centrale. Roster personali, comandi e preferenze locali restano conservati dall'installer.
