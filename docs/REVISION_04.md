# Revisione 04: appoggi, transizioni e palla dopo il punto

Riferimenti locali: nuova cattura del 20 ottobre alle 20:28:10 e sequenze della partita reale intorno a 55–64 secondi. Sorgenti precedenti conservati in `baseline-v03`.

## Modifiche

- La palla prosegue dopo il fischio. Gravità, rimbalzi con restituzione 0,76, perdita di velocità orizzontale, attrito e rotolamento restano attivi per i 4,5 secondi tra due punti. Il suono del rimbalzo parte all'impatto effettivo, usando i campioni già presenti. Non vengono assegnati altri punti.
- Cadenza della locomozione derivata dalla distanza realmente percorsa dal bacino nell'animazione originale. La corsa attiva misura circa 3,175 m/s: il vecchio divisore 4,8 causava una cadenza insufficiente rispetto allo spostamento.
- Aggiunte camminata, camminata all'indietro e attesa eretta originali. Corsa destra e sinistra ora provengono dalla stessa famiglia S2.
- Fusione delle pose sulle trasformazioni locali delle articolazioni, con ricostruzione della gerarchia. La vecchia interpolazione delle posizioni globali accorciava gli arti durante i cambi di posa.
- Chiusura graduale delle giunzioni dei cicli, transizione di 0,20 s, isteresi camminata/corsa, inclinazione del busto in accelerazione e frenata.
- Appoggi dei piedi in coordinate del campo con IK delle gambe limitata a 16 cm. Il vincolo viene rilasciato durante il salto e quando il piede si solleva. Non è una cattura di movimento nuova né un sistema completo di motion matching.
- Atterraggio e conclusione del gesto mantenuti per 0,58 s dopo schiacciata/muro/servizio. Preparazione iniziata prima: 0,60 s per l'attacco e 0,38 s per ricezione/alzata.
- Rotazione della testa verso la palla con limiti anatomici; busto e direzione di corsa non seguono istantaneamente ogni cambiamento della palla.
- Spostamenti senza palla con bersaglio filtrato, soglia di stabilità, velocità massima 4 m/s e variazione graduale dell'accelerazione. I giocatori coinvolti nel contatto usano invece il tempo disponibile per pianificare arrivo e frenata, fino a 7,2 m/s.
- Posture differenziate: ricevitori/difensori bassi, ali e palleggiatore in preparazione più eretti. Dopo il punto i giocatori camminano verso i compagni, invece di bloccarsi nella posa di difesa.

Arena, illuminazione, camera, materiali e campioni audio sono quelli precedenti.

Anteprima della build finale: `Spike Forever - appoggi e rimbalzi.mp4`, 32 secondi, 1280×720, 1920 fotogrammi. Registrazione del gioco con bot, inclusi punto e rimbalzo; codifica e decodifica completa senza errori FFmpeg. I 60 fps del video indicano la cadenza della registrazione, non un benchmark delle prestazioni in tempo reale.

## Verifiche

`Verifica.cmd` esegue:

- regressione Quadrato con conferma sul verde anticipata e vicino al contatto, tramite lo stesso gestore degli eventi del controller, a 30/60/120 Hz;
- almeno due rimbalzi dopo il fischio, punteggio invariato e differenza di altezza finale sotto 2,5 cm tra 30/60/120 Hz;
- trasformazioni dello scheletro finite durante locomozione e arresto, esecuzione degli appoggi dei piedi;
- conservazione delle lunghezze degli arti durante la fusione delle pose;
- conservazione della fase di atterraggio della schiacciata;
- simulazione completa con asset: 16 punti, 227 contatti, scarto massimo mani-palla 0,1482 m, scambio massimo 39 contatti;
- fallback senza asset: 16 punti, 72 contatti, scarto massimo 0,1514 m.

Queste verifiche misurano correttezza e regressioni. La somiglianza con un atleta reale resta una valutazione visiva: gli appoggi sono corretti entro limiti, non perfetti in ogni gesto. Il sistema non include motion matching, animazioni di tuffo selezionate per ogni traiettoria o nuove animazioni catturate. Il riposizionamento iniziale al nuovo servizio resta presente. L'avviso Godot ObjectDB alla chiusura della cattura era già presente.
