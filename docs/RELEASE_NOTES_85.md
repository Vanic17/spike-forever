# Spike Forever 0.85.0

- Upgrade grafico: illuminazione del palazzetto, materiali PBR di campo, giocatori, divise, rete e pallone, occhi rivisti, pubblico con colori più coerenti, dettagli delle strutture e del tavolo segnapunti.
- Preset Basso, Medio, Alto e Ultra estesi con qualità dell'illuminazione, dettaglio materiali e riflessi ambientali configurabili e salvabili.
- Corretto `crowd.wav`: conversione da PCM16 a sei canali a PCM16 stereo, 48 kHz, durata invariata. Risolto l'errore d'importazione dell'editor Godot 4.5.1. Il flusso OGG usato dal gioco non cambia.
- Controllo dei formati WAV prima della creazione del pacchetto, verifica completa dei file audio e dei riferimenti importati.
- Gameplay, animazioni, controlli, fisica, IA e networking invariati. Conservato il raccordo visivo della 0.84.0 e la simulazione a 120 Hz.

Le verifiche comprendono 18 suite offline, database/sostituzioni/replay con host e ospite, una partita completa renderizzata, cinque confronti visivi e benchmark dei quattro preset su RTX 5080. Risultati e limiti in `docs/GRAPHICS_UPGRADE_85.md` e `docs/AUDIO_EDITOR_85.md`.

L'errore audio non viene indicato come causa accertata del crash mostrato: la vecchia risorsa riproduce errori di importazione senza riprodurre quel crash. Non vengono forzati cambi di renderer, driver o qualità grafica.

Aggiornamento selettivo disponibile tramite indice verificato: vengono scaricati i file diversi. Salvataggi di Campionato, Diventa un mito e modifiche personali al database restano nelle rispettive cartelle locali.
