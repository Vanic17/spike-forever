# Studio del giocatore 93 ? locale, non approvato

Avvio: `Avvia studio giocatore.cmd`. ? uno studio separato, con un profilo
utente isolato; non installa il modello sulle rose e non usa i salvataggi
personali. `player93-review.html` confronta dieci viste con la stessa camera,
luce e posa. Il rig e le animazioni restano quelli del gioco. Il volto ?
ancora generico: non si tratta di una scansione di Damiano Catania.

Sono stati ricostruiti la parte inferiore del collo e i suoi pesi, gli occhi,
il groom corto, la barba e lo spessore dei bordi della divisa. La maschera
sul cuoio capelluto usa coordinate in posa di riposo per non scivolare quando
la testa ruota. La maglia conserva sponsor, numeri e UV originali. La pelle
coperta dalle fasce di questo atleta ? esclusa dalla mesh di rendering.
Questa maschera ? specifica del prototipo, non va estesa indiscriminatamente
ad altre configurazioni di accessori. La resa estetica richiede valutazione.

Pipeline, dalla radice del progetto:

1. Blender: `tools/Build-PlayerStudy93.py`.
2. Blender: `tools/Refine-PlayerStudy93.py -- --neck --groom`.
3. Blender: `tools/Finish-PlayerStudy93.py`.
4. Godot headless: `tools/Import-PlayerStudy93.gd`.
5. Profilo isolato: `tools/Test-PlayerStudy93.gd` e acquisizioni.

Controlli del viewer: Croce/A/Invio cambia volto-corpo; L1/R1 o LB/RB
cambiano l'azione, stick sinistro/frecce ruotano la camera, Options/Start o
Spazio fermano l'animazione, Cerchio/B/Esc chiudono. Non sono nuovi comandi
di partita. Nessuna pubblicazione remota e nessuna certificazione grafica AAA.
