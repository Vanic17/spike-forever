# Spike Forever 0.67.0

## Overall dai sei fondamentali

Applicati esattamente i pesi forniti nello screenshot del 30 ottobre, nell'ordine Battuta / Ricezione / Difesa / Palleggio / Schiacciata / Muro:

| Ruolo | BAT | RIC | DIF | PAL | SCH | MUR |
|---|---:|---:|---:|---:|---:|---:|
| Palleggiatore | 15 | 5 | 10 | 45 | 5 | 20 |
| Opposto | 20 | 5 | 10 | 5 | 40 | 20 |
| Banda | 15 | 20 | 15 | 5 | 30 | 15 |
| Centrale | 15 | 5 | 5 | 5 | 35 | 35 |
| Libero | 0 | 45 | 45 | 10 | 0 | 0 |

`OVR = round(sum(fondamentale × peso) / 100)`, valori 0–99. Ciascuna riga somma 100. Un unico modulo calcola il risultato per database, editor, formazione, carriera e rose online. L'overall non è più un settimo valore indipendente modificabile: cambia subito quando si modificano ruolo o fondamentali.

Aggiornati tutti i 169 giocatori del database. Il confronto con la 0.66 conferma che nessun nome, aspetto, ruolo, squadra o valore dei sei fondamentali è stato modificato. Anche gli override locali e le carriere esistenti ricalcolano l'overall al caricamento, conservando tutte le modifiche effettive e i progressi.

## Terzo tocco: attacco quando possibile

La precedente soglia di qualità 0,25 convertiva in bagher anche un'alzata di recupero alta e raggiungibile. Ora gli attaccanti possono concludere quelle palle con l'attacco di emergenza depotenziato già previsto. Restano i bagher per recuperi veramente bassi, palloni molto fuori campo, qualità estremamente bassa, libero o giocatore inadatto.

Sui rimbalzi alti dalla propria rete dopo il secondo tocco viene inoltre cercato un attaccante che abbia realmente tempo di arrivare, staccare e colpire. La traiettoria del rimbalzo resta quella fisica: non viene sostituita, non si teletrasportano gli atleti e il terzo tocco viene contato soltanto al contatto. Se l'attacco non è raggiungibile rimane il recupero in bagher.

## Finestra verde con database attivo

Il codice riconosceva il verde per precisione e replay, ma escludeva il database dal percorso del punto garantito. Corretto: tutte e tre le finestre verdi dell'attacco con statistiche attive producono un punto, usando la normale velocità della palla e la conclusione fisica a terra o con difesa/muro superati. Nessuna assegnazione di punteggio prima che l'azione termini. Una tolleranza numerica di un milionesimo evita che il 100% calcolato in virgola mobile venga scambiato per sovraccarico.

Sotto la finestra verde o oltre il 100% non si ottiene la garanzia. La battuta mantiene la propria logica: questa correzione riguarda l'attacco.

## Verifiche e compatibilità

Test su cinque ruoli, arrotondamento, 169 giocatori, modifiche locali, migrazione carriera e sanitizzazione online. Nove attacchi verdi portati fino al punto fisico, nei tre gradi di alzata; controlli sotto soglia e in sovraccarico. Dodici alzate difficili concluse con attacco reale e quattro rimbalzi alti dalla rete, su entrambi i lati con database ON/OFF; libero e salvataggi bassi conservano il bagher. Rapporti `overall67-*`, `gameplay67-*`, `stats67-*`.

Include integralmente il Campionato, le sostituzioni e le correzioni UI della 0.66. Entrambi i giocatori online devono usare **0.67.0 / SF067**.
