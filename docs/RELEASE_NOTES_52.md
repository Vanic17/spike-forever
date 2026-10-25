# Spike Forever 0.52.0 — secondo tocco, difesa e muro

## Alzate e giocatori bloccati

Analizzate le sequenze del video del 25 ottobre alle 13:23:30, intorno a 00:34 e nell'azione iniziata a 02:48. Nel secondo caso il gioco passa dall'alzata alla preparazione dell'attacco e poi segnala «palla fuori portata»: non è sufficiente interpretarlo come una scelta di mira del palleggiatore. Senza il log degli input e dello stato di quella partita non è possibile ricostruire esattamente ogni parametro del video. Le correzioni riguardano cause riprodotte nel codice e verificate con contatti fisici reali.

- La protezione finale delle collisioni bloccava anche passi che separavano due atleti già troppo vicini. Ora consente di uscire da una sovrapposizione, mantenendo i controlli contro l'avvicinamento e l'attraversamento di altri corpi. Due costruzioni con centrale fermo nel traffico passano da 0/2 a 2/2 completate nel caso riprodotto.
- Il passaggio da una variante PSA di alzata a un'altra poteva lasciare la scadenza calcolata all'altezza delle mani precedente. La nuova posa intercetta la stessa traiettoria alla propria altezza: nessun rilancio, rallentamento, teletrasporto o modifica della gravità.
- Il recupero basso del secondo tocco è valutato prima e rimane disponibile anche su costruzioni difficili che richiedono ancora un palleggio. Se la presa alta fallisce, viene valutato il bagher sulla traiettoria ancora in corso, purché fisicamente raggiungibile.
- Per il bagher di emergenza si riserva anche lo spazio della piattaforma delle braccia, non soltanto quello dei piedi. Il centrale cede dalla parte in cui si trova, evitando di attraversare il corridoio del palleggiatore per raggiungere il suo lato tattico ideale.
- La scelta fra palleggiatore e libero considera la lunghezza del percorso fra i compagni e i tempi di recupero. La priorità resta al palleggiatore sulle palle giocabili.
- Un secondo tocco comandato e fisicamente valido non viene annullato solo per una qualità molto bassa; la consegna diventa meno precisa. Senza comando il giocatore umano continua a non alzare automaticamente.
- Gli errori di contatto conservano nel registro circolare già esistente fase, atleta, posa, palla, destinazione e qualità. Nessuna scrittura continua su disco aggiunta.

## Difese più varie

Le difese di attacco, pallonetto e muro hanno una distribuzione distinta dalla ricezione in battuta. Tempismo peggiore e attacco più potente aumentano la dispersione: palla stretta, staccata, laterale e più profonda verso zona 6. Il risultato viene estratto una sola volta al contatto, con traiettoria fisica coerente e successiva costruzione adattata a dove va realmente la palla. Vale per CPU ed entrambi i lati umani online. La finestra e i tasti della ricezione in battuta restano invariati.

## Muro più incisivo

La soglia di chiusura passa da 0,70 a 0,66. Il muro chiuso restituisce più velocità verso terra e meno profondità, soprattutto contro colpi potenti. I contatti esterni delle dita continuano a produrre mani fuori; i tocchi morbidi possono restare alti e recuperabili. Nessun punto assegnato artificialmente dal solo nome «monster block».

Confronto deterministico su 10.000 identici contatti di mano: rimbalzi chiusi 1.583 → 1.944, mani fuori 3.741, altri tocchi 4.315. Questo misura le risposte ai contatti già avvenuti, non la percentuale di tutti gli attacchi murati.

In 40 situazioni identiche di copertura reale, simulate sino al pavimento o al recupero CPU: punti del muro 22 → 25, recuperi 17 → 13. Non è una promessa di percentuali per ogni partita: dipendono da posizione, salto, copertura e colpo avversario.

## Verifiche

- 16 cambi di performance: nuova altezza intercettata senza modificare posizione, velocità o spin della palla.
- Secondo tocco comandato con qualità zero: contatto e costruzione conservati per entrambe le squadre.
- 36 costruzioni di difesa/alzata/centrale con passaggi decentrati, due lati e sei rotazioni.
- 20 situazioni con compagni in piedi, centrali a rete e giocatori a terra, a 60/120 Hz; contatto e separazione fisica verificati.
- Regressione delle 96 costruzioni ricezione/alzata/attacco e del muro con collisioni continue sulle mani.
- Le 36 costruzioni e i 16 cambi di performance passano sia con AnimationTree sia con il fallback PSA originale.
- Verifica grafica del recupero basso e del contatto reale per entrambi i lati; schermate `recovery52-preview-*` incluse.
- Due processi online: 16 contatti osservati, comandi dei due giocatori, pausa sincronizzata e ritorno di entrambi alla home. Collegamento locale; nessun nuovo collaudo fra due reti esterne dichiarato.

Sorgenti, test, confronti e pacchetto Windows completo pubblicati insieme. Per l'online entrambi i giocatori devono usare 0.52.0; le versioni precedenti restano scaricabili. Roster personale e comandi locali conservati dagli aggiornamenti.
