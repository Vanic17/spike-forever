# Spike Forever 0.80.0

## Difese più varie

Otto prestazioni aggiunte al repertorio: piattaforma in passo, difesa raccolta, affondo basso a sinistra e a destra, recupero frontale a due braccia, side roll sui due lati e pancake. Le pose sono adattamenti autoriali sullo scheletro originale, guidati dai riferimenti video; non sono motion capture calibrata. Le clip vengono precalcolate nella libreria nativa e riprodotte nell'AnimationTree, mantenendo il percorso PSA di fallback e le correzioni finali di mani, piedi e sguardo.

Nelle difese basse compatibili la vecchia prestazione frontale con il braccio in discesa passa da circa due selezioni su tre a una su dodici. Rimangono le difese delle patch precedenti. È una distribuzione del selettore nelle condizioni indicate, non una frequenza garantita durante una partita.

Side roll e pancake sono esclusi dal repertorio ordinario: richiedono una palla bassa in discesa, la direzione corretta, spazio e una traiettoria di recupero fisicamente percorribile. Il pancake appoggia la mano sotto la palla prima del pavimento. Il contatto viene valutato al momento effettivo anche se cade tra due aggiornamenti a 30 Hz. Non vengono aggiunti punti di portata o recuperi garantiti; in Diventa un mito resta necessario il comando umano. Il roll conclude la risalita con un tempo limitato, evitando di lasciare il giocatore bloccato a terra.

Riferimenti: `0aOGNaPlo7A`, `Oz93Tf6y3DE`, `gzHnO5SsvfM`, `SHSPUrIjjFo`. Il pancake è costruito sulla prestazione prona esistente, con posa della mano e contatto dedicati.

## Variante d'attacco anche fuori dal centro

Il gesto del centrale è disponibile anche tra le varianti di banda, opposto e pipe sulle costruzioni compatibili. Viene adattato alle clip laterali, conservando stacco, contatto, spostamento reale e rincorsa di quei ruoli. Rimangono sia l'attacco originale sia la variante della 0.78. Sono supportati destri e mancini. Corretto anche l'ingresso del gomito nel caricamento di questa nuova variante, facendo sfumare la rotazione invece di cambiare bruscamente il piano del braccio.

## Compatibilità e verifiche

Contatti effettivi delle quattro difese ordinarie e dei tre recuperi estremi verificati a 30/60/120 Hz. Pose native verificate a 30/60/120/144 Hz: lunghezze dei segmenti di braccia e gambe, contatto delle mani, continuità rispetto al movimento sorgente e spostamento del personaggio invariato. Le ossa ausiliarie IK e muscolari conservano le loro animazioni e non sono considerate segmenti anatomici rigidi.

Attacchi completi di banda, opposto e pipe verificati con entrambe le mani e con AnimationTree e fallback PSA. Rapporti e anteprime: `defense80-contacts.json`, `defense80-poses.json`, `defense80-performance.json`, `attack80-gameplay.json`, `defense80-preview.mp4`, `attack80-preview.mp4`.

La nuova tabella di animazioni richiede la stessa versione sui due client online (protocollo SF080). Aggiornamento selettivo mantenuto; carriere, campionati e modifiche personali al database restano in `user://` e non fanno parte dei file da sostituire.
