# Revisione 18 — corsie prima palla, recuperi e animazioni complete

## Screenshot e prima palla

La formazione mostrata dopo il primo punto avversario corrisponde alla rotazione iniziale P1. Il numero 1 è un attaccante di prima linea che arretra per ricevere in zona 2: profondità sul campo e appartenenza alla prima/seconda linea non sono la stessa cosa. L'errore era assegnargli sempre zona 4 dopo il bagher, mentre l'opposto già a sinistra doveva attraversare in direzione contraria.

Ora, sulla prima costruzione da servizio in P1, il numero 1 mantiene la corsia destra e attacca in zona 2; l'opposto già a sinistra offre zona 4. L'alzata sceglie la zona richiesta, con l'attaccante legalmente disponibile in quella corsia. Dopo il primo attacco, il rigioco riprende le normali corsie specialistiche. Sono mantenuti ordine di rotazione, ruoli, sostituzione del libero e posizioni di ricezione del riferimento. Le indicazioni a schermo riportano la zona, evitando di chiamare erroneamente "opposto" uno schiacciatore che attacca a destra.

Gli attaccanti non impegnati nella ricezione preparano l'apertura già durante il volo del servizio, con tempi individuali; non aspettano tutti il cambio a SET.

## Recupero del libero e passaggio del palleggiatore

Il finale del video utente, circa 74–76 secondi, mostra una correzione ravvicinata fra libero, palleggiatore e altro compagno. Non si possono ricostruire gli input dal filmato. Le cause di movimento sono state però isolate nel codice e riprodotte con una fixture che usa i metodi della partita:

- Lo sterzo considerava la radice del libero, mentre le collisioni consideravano anche busto e gambe a terra. Ora le due fasi leggono la stessa impronta estesa.
- Lo sterzo dell'attore del contatto era disattivato negli ultimi 65 cm. Tale eccezione è rimossa.
- Il giocatore a terra riceveva ordini di liberare il corridoio mentre il suo tuffo prescriveva ancora un'altra traiettoria. Il percorso ora aggira il corpo, senza richiedergli uno spostamento impossibile.
- Il palleggiatore diretto a un punto intermedio veniva trattato come un compagno che cede il passo; perdeva la risposta immediata del contatto e rallentava come se quel punto fosse il luogo dell'alzata. Mantiene la priorità del contatto e calcola accelerazione/frenata sulla distanza residua dell'intero percorso.
- I percorsi vengono arrotondati e abbandonati appena la linea verso il contatto è libera, evitando l'arrivo a un angolo seguito da un'inversione.
- La collisione del tuffatore protegge ora anche la sua impronta mobile, non soltanto la sua radice: il busto non può avanzare dentro il palleggiatore.

Le impronte vengono calcolate una volta per giocatore nel passo di movimento e aggiornate dopo ogni spostamento. I controlli di collisione riusano questi dati coerenti, evitando migliaia di ricostruzioni temporanee per secondo.

## AnimationTree

Tutti i **33 clip attivi** sono convertiti in `assets/active/native_all.res` e passano dal backend nativo ottimizzato. La libreria è immutabile e condivisa; non vengono riscritte le chiavi durante il gioco. Il movimento reale resta distinto dalla posa visuale, con lo stesso clock di contatto e la stessa root motion estratta.

Le curve di salto aggiuntive sono applicate analiticamente, conservando l'altezza fra i keyframe. Blending delle pose già corrette e maschere per gruppi di ossa restano una composizione locale CPU: non vengono spediti ripetutamente allo scheletro privato. IK, piedi, testa e writer unico dello scheletro visibile sono conservati. Una piccola cache evita campionamenti ripetuti della stessa posa visuale.

Il backend è attivo per impostazione predefinita dopo la validazione di prestazioni. F6 passa ai PSA; `-- --psa-original` permette di avviare direttamente il percorso precedente. Il parser originale rimane anche il fallback per clip non compatibili. [Dettagli dell'integrazione](ANIMATION_18.md).

## Verifiche

- Suite completa PASS: `revision18-final-verification.log`, inclusi input, muro, collisioni della palla, movimento, contatti, rigioco, finte e rotazioni.
- 290 verifiche specifiche su ricezione e corsie: sei rotazioni, entrambe le squadre, ordine prima/seconda linea e scelta legale degli attaccanti.
- 840 confronti di posizionamento con il riferimento, distinguendo ricezione e corsie del rigioco.
- Recupero: quattro alzate effettive riuscite a 60/120 Hz, due metà campo; distanza minima dall'impronta del libero 0,98068 m, nessun arresto brusco. Il tempo di volo rimane quello originale di 1,2075 s. Due ulteriori casi verificano la collisione dell'impronta del corpo in movimento.
- 2695 verifiche di animazione: tutti i clip, contatti, salto, rotazioni, maschere, appoggi e fallback. Errore massimo di campionamento circa 0,0000058 m. La deriva degli appoggi preesistente non è presentata come eliminata.
- Controllo di ambito: fisica, timing, controlli, punteggio, sequenza di rotazione e muro manuale protetti. Nessuna riduzione della qualità grafica.

La prova renderizzata finale a 2560×1352, con tutte le correzioni di traffico, ha misurato:

| Modalità | CPU media | Fotogramma mediano | Fotogramma p95 |
|---|---:|---:|---:|
| AnimationTree completo | 9,833 ms | 11,212 ms | 13,838 ms |
| PSA | 9,539 ms | 10,573 ms | 13,574 ms |

Il costo aggiuntivo del backend completo nella sequenza misurata è 0,294 ms di CPU media e 0,264 ms al percentile 95 del fotogramma. Report: `animation-performance-v18-final-native.json` e `animation-performance-v18-final-psa.json`. Non è una garanzia del frame rate di ogni scambio. Il VSync è stato disattivato soltanto per questa prova, senza cambiare le impostazioni del progetto.

Il video `recovery-traffic-v18.mp4` mostra due ricostruzioni controllate del problema con movimento e contatti della partita. Non è una riproduzione degli input del video utente. Il recupero non garantisce automaticamente un punto: i comandi successivi restano richiesti come prima.
