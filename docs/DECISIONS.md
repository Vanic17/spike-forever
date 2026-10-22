# Decisioni e stato della prima build

Documento storico della prima build: per lo stato attuale leggere il README e `REVISION_02.md`.

La cartella di destinazione era vuota e non conteneva un motore da preservare. È stato scelto Godot 4.5.1 in versione portatile. Il gioco è nativo Windows, non un sito web. L'installazione Steam è stata usata soltanto in lettura.

La richiesta esplicita dell'utente di usare le animazioni e la dichiarazione dei diritti sono state applicate. Non sono stati richiesti codici di cifratura o aggirati controlli di accesso: il PAK era leggibile con UE Viewer.

Il README presenta sia la mappatura aggiornata X/Quadrato sia una vecchia indicazione B/Cerchio per l'attacco. La build usa X/Quadrato per tutte le azioni contestuali. Pressione/rilascio dell'attacco sono un'unica interazione: il rilascio conferma insieme potenza e tempo. Il tipo di servizio è selezionabile con Y/Triangolo/Tab, dichiarato provvisorio e modificabile in controls.cfg.

Formato scelto per il prototipo: una squadra umana contro la CPU, al meglio dei cinque set a 25, due punti di scarto. Nessuna personalizzazione. Una telecamera obliqua e una frontale, selezionabili. Multiplayer e regole avanzate restano aperti.

Le animazioni sono realmente importate e riprodotte, ma i materiali sono provvisori e la sincronizzazione precisa del contatto richiede ulteriori prove manuali. Le finestre del gioco sono basate sul tempo di arrivo fisico della palla; i tempi delle animazioni sono adattati a questa autorità, senza pilotare separatamente la palla.

Non è stato verificato un controller fisico. La mappatura standardizzata Xbox X/PlayStation Quadrato e l'ID variabile del dispositivo sono verificati via eventi nel test. Il nome del controller viene rilevato durante il gioco; non era collegato alcun dispositivo durante la prova grafica.

I test headless nell'ambiente limitato possono emettere un errore di accesso al deposito certificati Windows: il gioco è offline e i test della partita passano. La prova grafica eseguita con accesso al sistema non ha emesso quell'errore né errori GDScript. Non viene rivendicato un benchmark delle prestazioni.
