# Spike Forever 0.64.0

- Inserite le sei disposizioni di **primo attacco** dagli schemi forniti, distinte da ricezione e attacco successivo. La banda di seconda linea e il libero mantengono i rispettivi lati della rotazione durante la prima costruzione.
- Conservati gli schemi precedenti di ricezione, difesa e attacco successivo; il primo attacco si attiva solo dopo il primo tocco sul servizio avversario. Contatto del palleggiatore, rincorsa del destinatario e copertura hanno priorità sugli ancoraggi statici.
- Corretta la ripartenza dell'animazione del centrale: la finta chiude verso il punto del primo tempo e il passaggio a un attacco reale conserva il salto già iniziato. L'alzata può adattarsi alla posizione reale del centrale in volo, senza rilanciarlo da fermo.
- Un comando al centro eccezionalmente tardivo, dopo il momento utile della finta, conserva l'atterraggio e prepara un recupero in bagher, senza un secondo salto artificiale. Il tempo della palla viene calcolato prima del rilascio sulla durata reale di atterraggio e preparazione del recupero.
- Verificati i percorsi delle seconde palle e la separazione fra palleggiatore, centrale, ricevitore e pipe, senza aumentare indiscriminatamente la velocità dei giocatori.

Verifiche: 288 costruzioni complete con L/OH1/OH2, altre 96 con database attivo, 168 seconde palle, 108 preparazioni del centrale, 36 scelte primo tempo/7 senza riavvolgimenti e due recuperi di comando tardivo. Dettagli e limiti in [FIRST_ATTACK_64.md](FIRST_ATTACK_64.md).

Online: entrambi i giocatori devono usare la 0.64.0, protocollo SF064. Modalità originale/database e salvataggi personali conservati.
