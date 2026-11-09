# Rete e pallonetto ? modifiche locali

Il gioco aggiornato dai sorgenti si avvia con `Avvia Spike Forever.cmd`.
Non ? stata creata una release GitHub n? sostituito il pacchetto pubblicato.

La rete ha bordo superiore a 2,42 unit? metriche dal piano simulato, larghezza
9,50 m, altezza del telo 1 m, celle quadrate di 10 cm e fasce da 7/5 cm.
Grafica e collisioni condividono `net_spec94.gd`. Alte/Ultra usano corde 3D;
Bassa/Media usano la trama pi? leggera. Quattro impulsi locali, orientati
secondo l'impatto e smorzati nel tempo, deformano corde e fasce. ? un modello
di deformazione visiva e risposta dissipativa, non una simulazione completa
di tessuto. Il telo assorbe la velocit? normale e conserva parte del moto
laterale/verticale; il nastro ha una risposta separata. La zona sotto il telo
non produce pi? un rimbalzo contro una superficie inesistente.

Riferimento pallonetto: https://www.youtube.com/shorts/m9FH3qjbi18
Analizzato il contatto alto nella parte centrale del breve filmato. Il gesto
? una ricostruzione ispirata al riferimento, non motion capture. Il nuovo
clip nativo viene campionato da AnimationTree per la mano; il salto, la
rincorsa e il punto/tempo di contatto esistenti rimangono autorevoli. Il
seguito del braccio ? pi? contenuto. La stessa correzione viene specchiata
per i mancini; rimane disponibile il fallback PSA.

La mira usa gli stessi settori. Il corto caricato cade pi? vicino al muro,
la traiettoria usa meno spin della schiacciata e la pressione sale moderatamente.
Sovraccarico, finestra verde e controlli non sono stati ridefiniti. La palla
continua a usare gravit? e integratore condivisi.

La nuova animazione modifica la tabella numerica dei clip online: il protocollo
locale ? SF090-NET94. Due copie di questa build possono condividere la tabella;
un peer precedente viene rifiutato per evitare pose decodificate con ID errati.
Verificato il round trip del codec, non svolto un nuovo playtest Internet.

Verifiche: suite NetTip94 su AnimationTree e PSA; suite colpi 31 aggiornata
per il canale del nuovo gesto e le fixture correnti; regressione Fluidity84;
render della rete e delle pose; prova del viewer. I dati personali e il DB
sono controllati separatamente in net-tip94-preservation.json. La vecchia
suite 31 richiedeva ancora il banner punti gi? rimosso e non dichiarava il
tipo di primo tocco nella fixture di ricezione: entrambe le fixture sono
state allineate al comportamento attuale, senza cambiare la ricezione.

Benchmark locale 1920?1080 High, RTX 5080: 101,86 fps medi su 16 s,
frame p95 13,01 ms e p99 14,87 ms; GPU media 3,30 ms. Non ? una misura
universale di tutti gli scambi e non misura il prototipo grafico separato.
