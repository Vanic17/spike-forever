# Atmosfera sonora del palazzetto — v38

## Sorgenti ed elaborazione

Sono stati utilizzati gli otto MP4 forniti dall'utente (`applause 2`, `applause 3`, `crowd`, `crowd 2`, `drums`, `horn`, `in between`, `sneakers`), estraendo esclusivamente la traccia audio. I video originali non sono inclusi nel pacchetto.

L'analisi PCM a finestre di 10 ms ha individuato, fra l'altro, 4,47 secondi iniziali muti in `applause 2`, 6,13 in `applause 3`, 4,31 in `crowd 2`, 4,74 in `crowd`, 3,94 in `drums`, 5,78 in `horn` e 4,29 in `in between`. Sono escluse anche le pause interne dai frammenti ritmici. Gli interventi comprendono tagli distinti, dissolvenze, filtraggio sotto 75 Hz/sopra 12,5 kHz, lievi variazioni di tempo e normalizzazione EBU R128 a due passaggi. I quattro motivi aggiuntivi combinano tagli distinti di applausi e tamburi con il secondo strato al 18%.

Non è presente un file `whistle`/`fischio` nelle cartelle Captures e Downloads controllate. I sei fischi arbitrali sono quindi sintetizzati: due componenti battenti intorno a 2,8–3,3 kHz, soffio, inviluppo del respiro e variazioni di durata/interruzione. Non vengono attribuiti a una registrazione fornita dall'utente.

Il convertitore riproducibile è [Build-ArenaAudio38.py](../tools/Build-ArenaAudio38.py), senza dipendenze Python esterne. `assets/audio/arena/manifest.json` elenca per ogni file sorgente SHA-256, intervallo estratto, modifiche, durata e livelli misurati sull'Ogg effettivamente codificato.

| Gruppo | File effettivi | LUFS integrati misurati | Picco massimo dBTP |
| --- | ---: | ---: | ---: |
| Applausi ritmici | 8 | −20,62 … −20,23 | −2,60 |
| Tamburi | 6 | −21,62 … −21,26 | −3,02 |
| Motivi compositi | 4 | −21,53 … −21,37 | −2,73 |
| Reazioni pubblico | 8 | −21,70 … −21,04 | −3,34 |
| Intermezzi | 4 | −22,51 … −22,32 | −3,57 |
| Trombette | 6 | −24,22 … −23,01 | −4,68 |
| Scarpe | 12 | −26,39 … −25,16 | −5,29 |
| Fischi arbitrali | 6 | −24,41 … −24,16 | −20,78 |

Totale: **54 file Ogg Vorbis, 44,1 kHz stereo, 3.430.312 byte**. Tutti hanno SHA-256 distinto. I dodici gesti delle scarpe provengono da transitori separati, non da dodici copie della stessa registrazione con nomi diversi.

## Logica in partita

`match_audio.gd` conserva i contatti originali della palla e aggiunge:

- Un solo motivo di applausi/tamburi alla volta prima della battuta, scelto fra tre famiglie e 18 clip, senza ripetizione immediata. Il contatto della battuta lo termina con 80 ms di dissolvenza, senza aspettare l'arrivo della palla.
- Pubblico ambiente sommesso solo nella partita; abbassamento automatico sotto le reazioni del punto e lievi variazioni lente del livello.
- Un fischio arbitrale e una reazione del pubblico per punto. Trombette occasionali, ritardate rispetto al fischio, e intermezzi occasionali nelle pause. Un evento punto duplicato non produce un secondo fischio.
- Passi e scarpe legati agli spostamenti reali; nessun loop di scarpe quando i giocatori sono fermi. Un limite globale impedisce che dodici giocatori facciano partire dodici stridii nello stesso istante.
- Arresto dei canali di palazzetto al ritorno ai menu e durante la pausa, senza lasciare eventi ritardati accodati. Gli intermezzi terminano prima del prossimo scambio.

Tutti questi suoni passano dal bus **Arena**, con riverbero di sala (room 0,82, wet 0,16, pre-delay 18 ms) e compressore leggero. Il bus Master non riceve effetti e le canzoni dei menu rimangono inalterate. Arena invia al Master, quindi il mute globale L3/LS gestito dal controller globale interrompe anche l'atmosfera e i contatti.

Hook di integrazione: `update_match_state(started, phase, paused)` ogni frame; `contact(...)` resta compatibile. Nel movimento viene usato `movement(position, speed, lateral)` all'evento del passo esistente, senza aggiungere suoni a ogni fotogramma.

## Verifica

[Test-ArenaAudio38.gd](../tools/Test-ArenaAudio38.gd) verifica i 54 stream decodificati, le dimensioni dei gruppi, i livelli misurati, l'assenza di ripetizioni immediate, la raggiungibilità di ogni variante, l'isolamento dal Master e la successione menu/battuta/azione/punto/pausa. La prova con 20 punti riproduce 20 fischi e reazioni, 11 trombette e 6 intermezzi; i numeri sono il risultato del seed di test, non una sequenza fissa nel gioco. Esito: `ARENA AUDIO 38 PASS`.

[Render-ArenaAudio38.gd](../tools/Render-ArenaAudio38.gd) registra **il vero bus Godot**, inclusi gli effetti, durante una breve sequenza di battuta, ricezione, alzata, attacco e punto. Il file locale di verifica `docs/arena38-mix-preview.wav` dura 8,36 s; il suo segnale misura **−22,49 LUFS, −6,03 dBTP, LRA 4,0**, senza clipping. La forma d'onda è in `docs/arena38-mix-waveform.png`. Questi controlli confermano decodifica, rendering e livelli; non sostituiscono un ascolto umano sull'impianto dell'utente.

L'avviso ambientale Godot relativo al certificate store nel test headless non riguarda il caricamento o il rendering dell'audio locale.
