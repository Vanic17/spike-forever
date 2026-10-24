# Spike Forever 0.49.0 — Preparazione e conclusione della partita

## Preparazione sempre visibile

I pulsanti **Formazioni / Sostituzioni** si trovano sopra le anteprime delle divise. Squadre, divise, formazioni, formato, punti e avvio partita sono fuori dalle aree di scorrimento. Le immagini delle maglie si adattano allo spazio disponibile, lasciando sempre visibili i comandi.

Rimosso il testo esplicativo “Punti per set · vantaggio di due punti; set decisivo sempre a 15”. Restano i selettori del formato e del punteggio. Percorsi espliciti di navigazione verticale e orizzontale collegano i controlli per D-pad e levetta sinistra; Cerchio / B chiude la formazione e riporta il focus sul relativo pulsante.

Anteprima: `match-menu49.png`.

## Fine partita

La vittoria impostava la pausa generica: il gioco non avanzava più fino al ritorno al menu. Ora il completamento della partita è uno stato distinto. Il punto finale mantiene la breve esultanza e i rimbalzi del pallone; dopo 4,5 secondi il gioco torna automaticamente alla home, con focus su Gioca e musica dei menu ripristinata.

Il tasto di pausa non può interrompere questa transizione. La pausa manuale durante una partita e il suo ritorno al menu conservano il comportamento precedente.

## Regole verificate

- 1 set: vittoria a 15 o 25, secondo la scelta.
- Meglio dei 3: primo a 2 set; eventuale terzo set a 15.
- Meglio dei 5: primo a 3 set; eventuale quinto set a 15.
- Ogni set richiede due punti di vantaggio, anche ai vantaggi oltre il punteggio nominale.
- Una vittoria in due set nel meglio dei 3 o in tre set nel meglio dei 5 conclude subito la partita.

## Verifiche eseguite

`Test-MatchSetup49.gd` verifica:

- Tutti i comandi completamente visibili a 1440×810, 1440×720, 1280×720 e 1280×600, senza scorrere.
- Apertura delle due formazioni e ritorno con Cerchio / B al pulsante corretto.
- Eventi di D-pad e levetta sinistra che raggiungono Formazioni, formato e avvio partita.
- 12 combinazioni complete di formato, punti e squadra vincente, comprese parità e vantaggi prolungati.
- Quattro ulteriori vittorie anticipate in set consecutivi.
- Continuazione fra i set, conclusione al numero corretto di set e ritorno automatico alla home.

Il report è in `match49-report.json`. Verificati anche i test precedenti dei menu e della pausa. Non vengono modificati movimenti, animazioni, timing o fisica del gioco.
