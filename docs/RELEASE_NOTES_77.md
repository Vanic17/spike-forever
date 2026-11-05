# Spike Forever 0.77.0

Difese ispirate al riferimento `Wue2fnqT5oE`, con preparazione bassa, assorbimento laterale e risalita senza capriola. Il gesto originale non viene eliminato: le nuove alternative compaiono in circa un quinto delle situazioni compatibili, secondo altezza, direzione e tipo di palla. Non vengono assegnate automaticamente alla ricezione del servizio.

Sei clip native: bagher basso laterale, recupero laterale senza rotolamento e tentativo estremo non riuscito, ciascuno verso i due lati. Sono adattamenti delle pose sullo scheletro originale, non motion capture calibrata dal video. La risalita sostituisce il rotolamento con un'interpolazione delle rotazioni locali delle articolazioni, mantenendo le lunghezze degli arti. Il lavoro sulle pose viene precalcolato nella libreria nativa; la riproduzione usa l'AnimationTree e il blending già presenti.

Il tentativo estremo si attiva soltanto dopo una mancata difesa laterale bassa, in un intervallo limitato di distanza, con palla in discesa. Non viene scelto per palle normalmente recuperabili, per il palleggiatore, per una mancata pressione del comando o durante un altro tuffo. Non cambia palla, tocchi, punteggio o posizione iniziale del personaggio.

Preservati il sincronismo del contatto, i movimenti reali dei personaggi, i controlli, la fisica e i salvataggi. Il nuovo bagher usa l'altezza delle proprie mani per intercettare la stessa traiettoria. Gli aggiornamenti selettivi della 0.76 restano attivi.

Verifiche: pose attraverso AnimationTree a 30/60/120/144 Hz, contatti reali di bagher e tuffi a 60/120 Hz, selezione contestuale, conservazione dei gesti precedenti, tentativi falliti senza effetti sul risultato, benchmark CPU su dodici avatar. I rapporti e il confronto animato sono nei file `defense77-*` di questa cartella.
