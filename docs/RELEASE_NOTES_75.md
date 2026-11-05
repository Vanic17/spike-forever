# Spike Forever 0.75.0

- Quattro adattamenti difensivi dal riferimento `haSkiDd9P_8`: preparazione bassa, affondo a sinistra, affondo a destra e recupero basso a una mano. La scelta segue direzione e tipo di palla; i nuovi gesti passano dall'AnimationTree originale, mantenendo appoggi, tempi del contatto e spostamento della clip compatibile. Sono adattamenti animati da riferimento, non motion capture 3D.
- Diventa un mito: bagher più permissivo, feedback coerente con la finestra ampliata, maggiore tolleranza temporale del salto d'attacco e piccolo margine spaziale aggiuntivo. Restano necessari posizione corretta, comando del colpo e salto manuale. Esibizione e online mantengono il loro timing.
- Nuovi giocatori di Diventa un mito a OVR 75. Personalizzazione fra 30 e 85, budget 480, OVR finale richiesto 75. Le carriere già iniziate mantengono valori e progressi precedenti.
- Aggiornamenti: trasferimenti in thread, tempo massimo portato da 5 a 60 minuti per pacchetti grandi, due nuovi tentativi per guasti temporanei e messaggi distinti per DNS, TLS, timeout, permessi, spazio e risposta HTTP. L'errore viene registrato in `user://update-error.json`.
- Installazione: rifiutati archivi che includono dati personali o cambiano l'identità della cartella salvataggi. Controlli personalizzati conservati; campionati, Diventa un mito e modifiche al database restano in AppData. Verifiche SHA256, staging e rollback restano attivi.

Verificati download integrale della release 0.74.0 (770.582.969 byte, SHA256 corretto) e collegamento del vero client Godot a GitHub e CDN. Nessuna vecchia release è stata installata per questa prova. È possibile saltare versioni perché i pacchetti sono completi.

Gli aggiornamenti differenziali non sono ancora implementati: richiedono un manifest per versione, verifica dei file di partenza, download dei soli file cambiati e ripiego sul pacchetto completo se la base non corrisponde. Non richiederebbero di installare tutte le patch intermedie.

Anteprima: `defense75-preview.mp4`. Rapporti: `defense75-tests.json`, `arcade75-tests.json`, `update75-preservation.json`, `update75-live-download.json`, `update75-godot-transport.json`, `legend75-inputs.json`.
