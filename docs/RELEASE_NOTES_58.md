# Spike Forever 0.58.0

Ribilanciamento leggero degli esiti del muro, applicato allo stesso modo a giocatore e CPU.

- I contatti sul bordo interno delle mani diventano meno spesso mani fuori. Una parte viene frenata e ricade nel campo della squadra che mura, pronta per una difesa e un nuovo attacco.
- I contatti ben chiusi diventano un po' più spesso muri forti e diretti verso terra nel campo avversario. Il punto viene deciso dal contatto reale con il terreno: nessun punto assegnato automaticamente.
- Restano mani fuori sulle estremità delle dita, palloni alti e tocchi recuperabili. Non cambia la rilevazione del contatto con le mani, né il comando del muro, il salto o la bravura della CPU nel posizionarsi.

## Confronto controllato

Stessi 10.000 contatti e stessi valori di potenza, qualità, bordo delle mani e variazione, prima e dopo:

| Esito | 0.57 | 0.58 |
| --- | ---: | ---: |
| Mani fuori classificati dal contatto | 3.266 | 2.710 |
| Muri forti diretti verso terra | 2.034 | 2.212 |
| Altri tocchi di muro | 4.700 | 5.078 |

Nel sottoinsieme di 1.000 traiettorie fisiche, comprendente entrambi i lati del campo, i tocchi morbidi difendibili nel campo di chi mura passano da 130 a 174. Questi sono risultati del campione controllato, non percentuali garantite di una partita: gli esiti dipendono ancora da posizione, tempismo e contatto effettivo.

Controllate simmetria tra le squadre, traiettorie a 60/120 Hz, difese reali dei tocchi morbidi e punti reali dopo un muro forte. La suite esistente conserva 12/12 punti sui muri forti e 12/12 recuperi sui tocchi alti del proprio scenario. I rapporti e il confronto con il codice della 0.57 sono inclusi nel pacchetto.

Le altre meccaniche, la preparazione del centrale e i controlli restano invariati. Per giocare online entrambi devono usare **0.58.0 / SF058**. Roster e preferenze locali vengono conservati dall'aggiornamento.
