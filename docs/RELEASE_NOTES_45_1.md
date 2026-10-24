# Spike Forever 0.45.1

Revisione dell’accuratezza dei frontali di Padova: rimossi marchi tecnici introdotti erroneamente nelle ricostruzioni, mantenendo il simbolo Mitsubishi coerente con la foto fornita. I frontali approvati sono `assets/art/kits45/pallavolo-padova-home-v2-front.png` e `assets/art/kits45/pallavolo-padova-away-v3-front.png`; gli atlanti attivi li utilizzano al posto delle prime ricostruzioni.

Restano incluse tutte le funzionalità della [v45](RELEASE_NOTES_45.md): 32 divise delle 12 squadre, pantaloncini, nome/numero dinamici, cambio del libero e salvataggi locali conservati. Nessuna modifica a gameplay, controlli, animazioni o fisica.

[Anteprima aggiornata di Padova](kits45-pallavolo-padova.png) · [Prompt delle ricostruzioni, strumento integrato image_gen](kits45-imagegen-prompts.json) · [Prompt delle correzioni](kits45-correction-prompts.json).

Rigenerati e verificati i tre atlanti di Padova; nuovamente verificati hash, risoluzione, tutti gli abbinamenti del libero, conservazione dei pesi/UV e cache delle stampe con `Test-Kits45.gd`. La verifica di 144 combinazioni e il confronto prestazioni della v45 rimangono applicabili: la revisione modifica solo due immagini frontali e la loro proiezione UV.
