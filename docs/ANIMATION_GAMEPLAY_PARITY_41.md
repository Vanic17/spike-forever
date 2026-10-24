# Parità del gameplay con i prototipi v0.41

`tools/Test-MotionGameplay41.gd` esegue due istanze indipendenti della partita: una seleziona le prestazioni originali, l'altra i nuovi prototipi contestuali. Le due istanze ricevono gli stessi semi e gli stessi comandi. La verifica confronta lo stato reale della simulazione dopo ogni substep di 1/120 s, invece di dedurre l'assenza di regressioni dalle sole pose.

Il selettore sostituisce soltanto la stessa prestazione di origine da cui è stato costruito il prototipo: `attack_line` per l'attacco, `dive_v26_06` per il tuffo frontale. Contatto, durata, viaggio della radice e recupero conservano quindi i metadati della scelta originale. Il prototipo non viene usato per forzare una diversa azione o cambiare l'attaccante disponibile.

## Risultati finali

- **96 costruzioni complete**: entrambe le squadre, sei rotazioni, quattro destinazioni, alzata normale e veloce. In ogni caso si completano tre contatti reali.
- **26.237 confronti di stato** tra originali e nuove animazioni.
- **24 contatti reali della nuova schiacciata**, selezionata naturalmente dal piano di attacco. Il test non forza la nuova variante dopo la scelta tattica.
- **Due tuffi frontali realmente accodati**, uno per squadra, con viaggio del giocatore, contatto, caduta e completamento della rialzata. Il blocco fisico del recupero si libera nello stesso istante.
- Differenza massima di posizione/velocità/spin/bersaglio della palla: **0,0** nei campioni.
- Differenza massima delle posizioni/bersagli/velocità/accelerazioni dei dodici giocatori: **0,0** nei campioni.
- Uguaglianza di scadenze del volo, tempo simulato, scelta dell'attaccante, fasi giocatore/CPU, rotazioni, tocchi, punteggi, set, armamento del comando e stato del generatore casuale del gameplay.
- Tolleranza dichiarata del test: **0,000001**. Le pose scheletriche sono volutamente diverse e non vengono confrontate per uguaglianza: ciò che deve restare identico è il gameplay.

Il report dei 96 casi è `animation41-gameplay-parity.json`; il log è `v41-gameplay-parity.log`. Sono stati controllati anche errori script e asserzioni, oltre al testo di completamento.

## Altre verifiche sul codice finale

`Test-Approach40.gd` passa tutte le 96 costruzioni, con rincorsa già avviata nella prima ricezione in 96 casi e preparazione visiva anticipata in 87 casi. Restano presenti ricezione, alzata e attacco fisici.

`Test-Power29.gd` passa i controlli dei colpi al 97%, 98,5% e 100%, assegnazione del punto dopo l'arrivo al terreno, nuovo salto a muro dopo l'atterraggio nella stessa azione, carica dell'attacco memorizzata e velocità distinte delle barre.

Gli hash di **tutti i 134 PSA originali attivi** sono stati ricontrollati contro l'audit precedente all'implementazione: nessun file originale è cambiato o scomparso.

Questi test coprono una matrice riproducibile e i due recuperi mirati; non equivalgono a una dimostrazione di ogni possibile situazione di partita. La qualità estetica delle nuove pose e le transizioni vengono valutate anche nelle catture dedicate.

## Comando

```powershell
$env:APPDATA = Join-Path (Get-Location) '.runtime/roaming'
$env:LOCALAPPDATA = Join-Path (Get-Location) '.runtime/local'
& tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Test-MotionGameplay41.gd --quit-after 1800
```
