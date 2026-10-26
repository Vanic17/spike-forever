# Spike Forever 0.59.0

Corretti tre difetti che rendevano il muro poco incisivo anche quando i giocatori erano sulle mani della palla.

- La forza del contatto veniva calcolata dalla distanza del centro della palla dalle mani al primo ingresso nella collisione. Questa distanza comprende il raggio della palla: un impatto pieno risultava spesso debole. Ora la chiusura dipende dalla copertura laterale e verticale sulla superficie dei palmi, mantenendo la stessa collisione fisica. Lo sfioramento delle dita e il contatto sugli avambracci restano distinti dal muro pieno.
- Il lancio della schiacciata cancellava anche i salti già iniziati dal muro CPU. Inoltre, durante la successiva fase difensiva, il suo blocco del movimento controllava l'identificativo dell'attacco successivo. Ora il muratore conserva posizione e salto fino all'atterraggio, poi torna subito libero di muoversi.
- Un muro pieno poteva imprimere una traiettoria troppo verticale prima che la palla superasse la propria rete. Ora l'angolo di uscita tiene conto della distanza effettiva dalla rete, con una correzione limitata della componente orizzontale. Restano gravità, collisioni, coperture e punto deciso dal terreno.

## Scambi completi

Confronto tra 0.58 e 0.59: due simulazioni indipendenti con gli stessi semi iniziali, ciascuna fino a 25 azioni concluse. Il sistema usa i comandi reali, compreso il movimento del centrale e il salto manuale; non vengono imposti contatti sulle mani o punti.

| Risultato sulle 50 azioni | 0.58 | 0.59 |
| --- | ---: | ---: |
| Punti a muro del lato giocatore | 2 | 5 |
| Punti a muro CPU | 0 | 4 |
| Muri forti rilevati | 6 | 16 |

Dei 16 muri forti della nuova versione, 7 producono un punto diretto e 9 vengono recuperati con un contatto reale. Altri due punti provengono da tocchi di muro meno forti. Nessuno dei 16 muri forti rimbalza contro la propria rete nel campione.

Sono azioni di prova, non due set completi né una quota garantita di muri punto. Le traiettorie divergono dopo le correzioni e cambiano anche il numero di attacchi. Il controllo simulato non rappresenta la prestazione di ogni giocatore. Il confronto e le tracce sono in [block-rallies59-summary.json](block-rallies59-summary.json).

## Verifiche

- 336 controlli di campionamento e simmetria a 60/120/240 Hz e 42 casi sulle mani dello scheletro reale: contatti pieni, sfioramenti, bordo dei mani fuori, salti fuori tempo e traiettorie lontane.
- AnimationTree e fallback PSA, entrambi i campi e 60/120 Hz: 8 contatti fisici, 6 muri forti con punto a terra e 2 contatti sulle dita esterne; conservazione del salto, nessuno spostamento della radice in volo, rilascio dopo l'atterraggio.
- Conservati i controlli su L2/R2, levetta sinistra e salto Croce/A; verificati anche alzate, preparazione del centrale, costruzioni d'attacco e partita online locale con host e ospite.

Non cambia il sistema di timing del giocatore, né le rotazioni, la potenza degli attacchi o i parametri della difesa CPU. Le soglie del risolutore di esito della 0.58 restano invariate: viene corretta la misura del contatto reale che lo alimenta.

Online richiede **0.59.0 / SF059** su entrambi i PC. L'aggiornamento conserva roster, impostazioni e comandi locali.
