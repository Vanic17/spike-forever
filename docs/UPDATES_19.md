# Aggiornamenti e pubblicazione

Versione iniziale della cronologia: **0.19.0**. Repository prevista: `Vanic17/spike-forever`. Non si inventano release delle revisioni precedenti.

Il menu mostra Gioca e Aggiornamenti. Gioca funziona offline; la ricerca usa la API pubblica GitHub Releases, con paginazione, escludendo bozze e prerelease. Ogni release deve contenere `SpikeForever-Windows.zip`. La lista permette di scegliere la più recente o una precedente: entrambe vengono installate con lo stesso percorso verificato. Una versione installata viene letta dal suo `version.json`.

Il pacchetto è scaricato prima di chiudere il gioco; si verifica il digest SHA-256 pubblicato da GitHub. Un helper PowerShell aspetta la chiusura del processo, estrae in staging, respinge percorsi pericolosi/duplicati e verifica il manifest e ogni file. Esegue un backup prima della sostituzione; in caso di errore intercettato ripristina i file precedenti. `controls.cfg` e dati locali sono conservati. Il risultato dell'installazione compare al riavvio. I backup restano in `.updates`.

Limite: il rollback copre errori gestiti dall'installatore, non un'interruzione di alimentazione durante la copia. Il downloader non incorpora token GitHub o credenziali del publisher. Per aggiornamenti senza login la repository e le release devono essere pubbliche.

## Preparazione di una patch

1. Aggiornare `version.json` a una nuova versione.
2. Eseguire i test, compreso `tools/Test-UpdateInstaller.ps1`.
3. Eseguire `powershell -NoProfile -ExecutionPolicy Bypass -File tools/Publish-Release.ps1` con GitHub CLI autenticata come Vanic17.
4. Lo script prepara il pacchetto completo, crea la repository se manca, pubblica i sorgenti con asset di runtime e crea la release `vVERSIONE`. L'engine Godot viene incluso nello ZIP della release, evitando un blob Git da oltre 100 MB.

La prima pubblicazione richiede autorizzazione GitHub CLI. Il connettore di questa sessione riconosce Vanic17 ma non espone la creazione di repository o l'upload delle release; le sue credenziali non vengono estratte. Il programma deve riportare chiaramente quando la repository/release non esiste ancora. La pubblicazione non è considerata completata finché la release remota non è verificata.

Test locali: menu offline, cronologia con più versioni, esclusione bozze, gestione 404, rifiuto URL non autorizzati; installazione verificata, conservazione comandi, rifiuto ZIP traversal e file con checksum errato. La prova su release remota resta dipendente dalla prima pubblicazione.
