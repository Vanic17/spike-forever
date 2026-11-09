# Ricostruzione anatomica — prototipo non approvato

**Ritirato dopo il secondo rifiuto visivo.** I quattro punti d'integrazione
nel gioco sono stati ripristinati byte per byte dalla versione 0.90.0.
Nessuno dei due launcher sperimentali avvia più questi modelli. Le risorse
e i confronti restano soltanto come archivio del tentativo fallito.
Il miglioramento grafico richiesto non è completato.

La revisione grafica 91 non ha superato il riscontro visivo dell'utente ed è
ora esclusa dall'avvio normale. È conservata con `--athletes-blender91`.
Il prototipo 92 si avvia con `Avvia prototipo anatomico.cmd` / `--anatomy92`.
Non è una release e non viene pubblicato su GitHub.

## Ricostruzione

- Base completa Blender Studio Human Base Meshes 1.4.1, realistic male, CC0.
- Superficie testa-collo-corpo continua; stesso rig di 115 ossa del gioco.
- Posizionamento dei segmenti nelle coordinate del bind esistente.
- Mandibola solidale alla testa; transizione dei pesi limitata al vero collo.
- Skin atlas e bakes PBR unificati con texture derivate dal materiale esistente.
- Grooms adattati; barba rigenerata sulla nuova superficie per evitare fibre
  allungate da un trasferimento indipendente dei vertici.
- Geometria nascosta sotto divisa e calzature esclusa dal rendering.
- Attributi, altezze, colori, numeri e nomi letti dagli stessi dati esistenti.

Pipeline: `Build-Anatomy92.py`, `Fit-Anatomy92.py`, `Finish-Anatomy92.py` in
Blender 5.2, poi `Import-Anatomy92.gd` in Godot 4.5.1.

## Stato e limiti

Revisione visiva finale: **non superata**. Nel primo piano restano evidenti
difetti del raccordo collo-colletto, occhi poco naturali e capelli troppo
compatti. Il prototipo non soddisfa ancora il livello di realismo richiesto
e non va distribuito come upgrade definitivo. I test di compatibilità non
costituiscono approvazione estetica.

Benchmark locale High, 1920×1080, RTX 5080: 105,19 fps medi su 16 secondi,
frame p95 12,60 ms e p99 14,03 ms. È una singola sequenza ripetibile,
non una misura di tutte le situazioni di partita.

L'adattamento automatico della divisa ha evidenziato compenetrazioni e pieghe
non valide; sono state introdotte deformazioni più regolari e pesi coerenti
con la nuova pelle. La vestibilità deve ancora superare una revisione visiva
su tutte le pose. Anche volti, capelli e resa dalla camera di gioco richiedono
valutazione: la base non viene certificata come grafica AAA dai test tecnici.

Il modello anatomico è generico; i dettagli del volto non rappresentano i
lineamenti reali di ciascun atleta. Non sono stati modificati animazioni,
fisica, IA, rotazioni, controlli, networking o file del database.

`anatomy92-review.html` contiene i confronti effettivamente renderizzati nel
gioco, senza cambiare la luce o la posa per abbellire il risultato.
