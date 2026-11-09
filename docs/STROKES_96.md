# Gesti e traiettorie della v0.91.0

Sei clip nativi supplementari, valutati dal medesimo AnimationTree privato:
`attack_shorttip96`, `attack_cut96`, `set_first96`, `dump_back96`,
`dump_down96`, `dump_forward96`. Libreria precalcolata: `native_motion96.res`.
Parser PSA, fallback e singolo autore della posa finale restano disponibili.

Le varianti di attacco si sovrappongono alle braccia della rincorsa già
programmata, senza cambiare salto, corsa o orologio del contatto quando si
decide tardi il colpo. Il polso viene mantenuto nel punto originale al contatto;
il seguito della diagonale corta si orienta verso l'interno del campo.

La versione corta del pallonetto è selezionata solo con mira verso le zone
corte. Per altre direzioni si mantiene `attack_wrist94`. Si usa una parabola
gravitazionale contenuta con margine sulla rete, senza cambiare la gravità.
Il suono usa il banco morbido del palleggio a volume ridotto anziché il colpo
di schiacciata. Anche il client online sceglie questo suono.

La seconda speciale richiede un comando umano Triangolo/Y/T durante SET:
palleggiatore effettivo e primo tocco di squadra già eseguito. La distanza
dalla rete o la qualità della ricezione non impediscono la richiesta del
gesto. Una posizione sfavorevole produce una traiettoria nella rete anziché
una parabola artificiale sempre corretta. Il giocatore deve comunque toccare
fisicamente la palla e le regole di attacco della seconda linea restano valide.
La CPU non richiede le tre nuove mosse.
La tipologia rapida 3 alza maggiormente il contatto con un piccolo salto
coordinato, permettendo una discesa più rapida dietro la rete. Tutte le
traiettorie da posizioni idonee conservano il margine sulla rete. Lontano
dalla rete il tentativo può invece colpirne la maglia.

I pallonetti corti recuperabili preferiscono il pancake, con previsione del
contatto vicino al suolo, percorso senza compagni di mezzo e velocità di
spostamento limitata. Il braccio arriva a circa il 99% della propria estensione
anatomica senza allungare le ossa; è controllato anche dopo l'IK del contatto.
L'input resta necessario per la squadra umana e non si convertono le palle
vincenti garantite in recuperi forzati. In Diventa un mito resta la richiesta
manuale del tuffo per il giocatore controllato.

L'alzata a una mano riguarda esclusivamente il primo tempo normale scelto
con Croce/A e seconda palla entro 0,85 m dalla rete. La sette con Quadrato/X,
le alzate staccate e le altre destinazioni mantengono le animazioni esistenti.

## Riferimenti esaminati

- [Pallonetto corto](https://www.youtube.com/shorts/F7_XbNdVvMc): estensione alta, rilascio delle dita e caduta oltre muro; sequenza rallentata nel filmato.
- [Cut shot](https://www.youtube.com/shorts/f2Y-Wzz--eE): contatto alto e seguito corto attraverso il corpo.
- [Diagonale Kliuka](https://www.youtube.com/shorts/E0-y69m7Trk): chiusura trasversale del braccio verso l'interno.
- [Alzata a una mano](https://www.youtube.com/shorts/oLIQM4TsErk): contatto alto rapido con la palla vicina alla rete.
- [Tutorial numeri 2, 3, 7](https://www.youtube.com/shorts/OYnemJcvpD0): dietro la testa, classica e tocco lungo.
- [Rilascio di polso](https://www.youtube.com/shorts/K946bfJAJPI): estensione singola e spinta controllata.
- [Spinta rapida](https://www.youtube.com/shorts/3dCAFN8rQrg): accelerazione breve verso il basso.

I video originali sono consultati solo come riferimento e non fanno parte
del pacchetto distribuito. `strokes96-preview.mp4` è uno studio di posa del
gioco, non una registrazione di partita o una prova di Internet reale.

## Verifiche

`strokes96-tests.json` contiene controlli di pose finite, altezze, registrazione
nativa, mira, destri/mancini, contatto fisico delle mani, tre seconde nelle
rotazioni di prima linea e codec online. Gli altri rapporti e i log della
consegna distinguono prove ENet su due istanze locali e test di regressione.
I profili dei test sono isolati da database personale e carriere.
