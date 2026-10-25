# Spike Forever 0.53.0 — Impostazioni, lingue e grafica

Nuova quinta voce **Impostazioni** nella home, con due schede, Lingua e video / Grafica. Navigazione con stick sinistro o D-pad, A/Croce per scegliere, B/Cerchio per chiudere un elenco o tornare alla home. Il controllo selezionato viene portato nello spazio visibile; Applica e salva resta fuori dallo scorrimento.

## Lingua

Italiano e inglese si applicano immediatamente dopo Applica e salva: home, preparazione partita, formazioni, editor e profilo/statistiche, online, aggiornamenti, pausa, comandi e feedback durante gli scambi. Il catalogo include oltre 350 messaggi e frammenti, con gestione dei valori dinamici. La traduzione avviene attraverso il sistema nativo di Godot; nessuna scansione dell'interfaccia a ogni frame. Nomi delle squadre/giocatori, dati del roster, ruoli interni e stato delle azioni restano invariati.

## Video

- Finestra, schermo intero senza bordi, schermo intero esclusivo.
- Risoluzione della finestra o del display in esclusivo; senza bordi viene indicata e usata quella del desktop.
- **Automatica / nativa:** rileva la modalità preferita dichiarata dal monitor (quando disponibile), con ripiego sulla risoluzione del desktop e verifica delle modalità supportate. Mostra Full HD, QHD/2K o 4K UHD secondo lo schermo effettivo; funziona anche con proporzioni ultrawide. La scelta automatica viene salvata come tale e rivalutata sul PC/monitor usato al successivo avvio. Senza bordi segue la risoluzione corrente del desktop; in esclusivo usa la modalità nativa supportata. In finestra si adatta all'area del display tramite massimizzazione.
- Hz del monitor: in esclusivo, elenco delle combinazioni risoluzione/frequenza effettivamente enumerate da Windows. In finestra/senza bordi viene usata la frequenza del desktop e l'opzione è disabilitata.
- Limite FPS: illimitati, 30, 60, 90, 120, 144, 165, 180, 240, 360.
- V-Sync disattivato, attivato, adattivo o mailbox. I limiti derivanti dal V-Sync/monitor restano indipendenti dal limite FPS scelto.

I cambi di modalità/risoluzione/Hz richiedono conferma entro **15 secondi**; altrimenti si torna alla configurazione precedente. Il cambio del display Windows è temporaneo, non scrive nel registro; la modalità originale viene ripristinata uscendo dal gioco e quando perde il focus. L'helper Windows verifica le combinazioni supportate prima di applicarle. Le sue sorgenti sono `src/DisplayModes.cs`.

## Grafica realmente applicata

- Preset **Basso, Medio, Alto, Ultra** e Personalizzato: configurano i parametri effettivi, lasciando disponibili tutte le modifiche manuali.
- Texture 3D: 512 px, 1024 px, 2048 px o originali. Le immagini di giocatori, maglie, arena e sponsor vengono ridimensionate mantenendo mipmap e riferimenti dei materiali; tornando a Originale si ricarica la sorgente. Interfaccia e stampa dei nomi/numeri rimangono nitide.
- Scala della risoluzione 3D: 50/67/75/85/100%, senza ridurre la risoluzione della UI.
- Ricostruzione bilineare oppure **AMD FSR**.
- MSAA disattivato / 2× / 4× / 8× e antialiasing temporale indipendente.
- Ombre disattivate, basse, alte, massime; dimensione dell'atlante ombre e luce direzionale effettivamente aggiornate.
- Occlusione ambientale e bagliore delle luci.
- Illuminazione indiretta SSIL, riflessi SSR, luminosità/esposizione e distanza di rendering delle ombre.
- Densità del pubblico ridotta, media o completa, applicata alle istanze degli spettatori.
- Filtro anisotropico disattivato / 2× / 4× / 8× / 16×.

Le opzioni agiscono sul renderer della scena di partita e vengono riapplicate all'avvio. Configurazione in `user://settings.cfg`, salvata atomicamente nel profilo locale del gioco e conservata dagli aggiornamenti. Nessun cambiamento a fisica della palla, rotazioni, IA, tempismo o comandi.

## Verifiche

- Salvataggio/ricaricamento, configurazioni non valide, ritorno automatico dopo timeout e annullamento delle modifiche non confermate.
- Proprietà reali del viewport, ambiente, ombre e gruppi di spettatori; texture 1024 → 512 → 1024 senza cambiare l'oggetto usato dai materiali.
- Rilevamento automatico verificato con casi Full HD, QHD, 4K e 3440×1440 ultrawide, più modalità reale 2560×1440 del monitor di prova. Preset Basso/Ultra e proprietà effettive di FSR, SSIL, SSR, esposizione e distanza ombre verificati.
- Traduzioni italiane/inglesi e feedback con percentuali; i valori restituiti dagli elenchi dei ruoli restano gli identificatori originali.
- Eventi reali del controller A/B e D-pad, popup, fondo della scheda e scroll automatico a 1440×810, 1280×720 e 1024×600.
- Renderer Forward Plus reale: finestra 1280×720, senza bordi, esclusivo alla risoluzione/frequenza già attive del monitor; ritorno al desktop verificato. Limiti di 30 e 60 FPS misurati rispettivamente a circa 30,00 e 60,00 FPS su questo PC. Le altre combinazioni sono enumerate/validate da Windows, senza dichiarare una prova fisica di ogni modalità e monitor.
- Schermate di home e menu, editor e HUD in inglese incluse come `settings53-*.png`.

Riferimenti tecnici: [Godot 4.5 Viewport](https://docs.godotengine.org/en/4.5/classes/class_viewport.html), [Translation](https://docs.godotengine.org/en/4.5/classes/class_translation.html), [DisplayServer](https://docs.godotengine.org/en/4.5/classes/class_displayserver.html).

Rilevamento della modalità preferita: [Microsoft WmiMonitorListedSupportedSourceModes](https://learn.microsoft.com/en-us/windows/win32/wmicoreprov/wmimonitorlistedsupportedsourcemodes). In assenza di informazioni del monitor si usa il desktop, senza indovinare una risoluzione dalla potenza della GPU.

Pacchetto Windows completo e sorgenti pubblicati insieme. I protocolli e i pacchetti dell'online non cambiano rispetto alla 0.52.0; ogni giocatore usa le proprie impostazioni locali.
