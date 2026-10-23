# Squadre e roster locali

Il database base è `assets/gameplay/league.json`. È il file fornito dall'utente: le proiezioni dei titolari e gli HEX mantengono i limiti dichiarati nel documento. Numeri o aspetti null non sono dati verificati e non vengono inventati.

Le modifiche dell'editor sono salvate separatamente in `user://roster-overrides.json` (AppData/Roaming/ Godot/app_userdata/Spike Forever). Il file è esterno alla cartella installata e al manifest degli update. Gli override vengono riapplicati per ID del giocatore. Scrittura su file temporaneo e rinomina evitano di lasciare JSON parziali.

I valori sono esclusivamente metadati. Nessun rating entra nella simulazione. La formazione usa i ruoli del roster e preferisce i nomi della proiezione, senza cambiare la struttura tattica 5–1. Un roster incompleto blocca l'avvio con spiegazione.

Le divise usano i colori del database; non riproducono sponsor e disegni delle maglie reali. Capelli lunghi sono una variante scalata dell'asset esistente; non un nuovo modello. I campi null conservano il modello base. Il libero ha identità separata quando sostituisce il centrale.

Le quattro tracce fornite vengono riprodotte soltanto nei menu, scegliendo casualmente anche la prima e senza ripetizione immediata.
