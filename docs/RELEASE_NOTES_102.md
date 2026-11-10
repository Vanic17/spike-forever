# Spike Forever 0.102.0

- **Database online dell'host:** entrambe le squadre vengono selezionate dal catalogo dell'host, trasferito in memoria e verificato con hash. Le statistiche, i nomi, i ruoli, l'aspetto e la panchina del client non possono più sovrascriverlo.
- **Barra dell'attacco:** durata calcolata dall'host e inviata al client, insieme alla zona d'attacco effettiva. Corretto il rischio di usare sul client una zona precedente e una durata diversa sul centrale. Nessuna modifica alle curve di bilanciamento: con valori attivi i giocatori meno abili continuano ad avere, intenzionalmente, una barra più veloce.
- **Riconnessione rapida:** le ultime otto stanze raggiunte con successo restano nello storico locale; seleziona la stanza e premi **RICONNETTI ALLA STANZA**, anche con il controller. L'ultimo codice è già precompilato.
- **Identificativo host persistente:** il codice non cambia più a ogni apertura se IP e porta rimangono uguali. Se cambia l'IP Internet dell'host occorre condividere una volta il nuovo codice: la connessione resta diretta, senza un servizio centrale di lobby.
- Database personali, formazioni locali, campionati e carriere non vengono sovrascritti dal catalogo ricevuto. Lo storico usa un proprio file separato.

Entrambi i giocatori devono aggiornare alla stessa versione. [Verifiche tecniche](ONLINE_DATABASE_108.md).
