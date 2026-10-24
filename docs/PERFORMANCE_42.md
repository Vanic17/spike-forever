# Prestazioni e verifiche v0.42.0

## Costo delle pose

Stesso test `Benchmark-Animation41.gd`, stesso carico congelato: 12 avatar, 145 ossa, backend nativo, 90 frame di riscaldamento e 600 campioni. Le misure CPU headless non rappresentano FPS video.

| CPU dei 12 giocatori | Prima | Dopo |
| --- | ---: | ---: |
| Aggiornamento medio | 6,030 ms | 4,101 ms |
| Aggiornamento p95 | 8,782 ms | 6,104 ms |
| Applicazione delle pose media | 5,978 ms | 4,032 ms |
| Applicazione delle pose p95 | 8,727 ms | 6,037 ms |

Riduzione del costo medio di aggiornamento: circa **32%**. Oggetti e risorse non crescono dopo il riscaldamento; variazione memoria statica 43.332 byte in entrambi i test. La libreria originale `native_all.res` resta identica. `Test-NativeAnimation.gd` verifica 5.233 confronti, comprese pose native/PSA, blending e cambio backend.

Report: `animation41-42-before-native.json`, `animation41-42-after-native.json`. La cache in `pose_hierarchy.gd` elimina le scansioni ripetute degli antenati, senza saltare IK, piedi, testa o contatti.

## Scena renderizzata

`Benchmark-Rendered42.gd` esegue ricezione, alzata e pipe reali ripetute, con tutti i giocatori e il palazzetto. RTX 5080, Forward+, finestra 1280x720, limite 60 FPS, VSync disattivato, 120 frame di riscaldamento e 600 frame misurati. Entrambi i percorsi usano realmente la nuova schiacciata in tre contatti e in 162 frame del campione.

Il primo confronto dopo le modifiche ha misurato 58,77 FPS, p95 20,60 ms, massimo 28,80 ms e cinque frame sopra 25 ms. Una ripetizione senza altre elaborazioni attive ha misurato 59,99 FPS, p95 19,90 ms, massimo 22,28 ms e nessun frame sopra 25 ms. Prima: 59,96 FPS, p95 20,48 ms, massimo 30,56 ms, sei frame sopra 25 ms. Nessuno di questi campioni ha frame sopra 50 ms.

Si riportano entrambe le misure successive: la variabilita dello scheduler conta e il limite di 60 FPS nasconde parte del guadagno CPU. Non si dichiara un aumento percentuale degli FPS, ne una garanzia di assenza di scatti in ogni partita. La simulazione costa leggermente di piu con la preparazione contemporanea dei compagni; il risparmio misurato e nelle pose. La cattura video a passo fisso e esclusa da queste misure.

Dopo la correzione finale dell'evitamento vicino al palleggiatore, un ultimo campione sul codice pubblicato misura **60,00 FPS**, p95 **19,01 ms**, p99 **20,10 ms**, massimo **22,33 ms**, **zero frame sopra 25 ms**. Il costo dei due passi di simulazione e 3,102 ms in media, contro 3,211 ms prima. Le due misure precedenti documentano gli stadi intermedi, non sostituiscono questo controllo finale. Vale sempre il limite di un singolo scenario locale.

Report: `animation42-rendered-before-new.json`, `animation42-rendered-after-new.json`, `animation42-rendered-after-repeat-new.json`, `animation42-rendered-after-final-new.json`.

## Verifiche funzionali

| Test | Copertura |
| --- | --- |
| Test-Approach42 | 96 costruzioni con tre contatti; apertura e rincorsa reali, anche al centro |
| Test-MiddleDecoy | 36 azioni su ricezione buona; una finta reale, tempo di salto, atterraggio, copertura, nessun tocco alla palla |
| Test-SpecialistsPause42 | 36 scelte S/L; navigazione reale giu+A e B nella pausa |
| Test-SetterPipeline38 | 144 sequenze, tutte le rotazioni, entrambe le squadre, 60/120 Hz, cambio attaccante |
| Test-SetReliability | 192 sequenze, comandi anticipati/intermedi/tardivi, CPU, tutte le direzioni |
| Test-ContactTraffic28 | 20 avvicinamenti con corpi in piedi e a terra, 60/120 Hz, contatto e distanze fisiche; intercetto basso senza modificare il volo |
| Test-Coverage36 | 288 piani e 24 movimenti speculari, stabilita e traiettoria entrante |
| Test-ManualWall | 48 combinazioni di rotazione, membri e frequenza, LS/L2/R2 e salto manuale |
| Test-Power29 | Attacchi vincenti 97/98,5/100%, secondo salto e carica |

`scope42-report.json` confronta 151 file protetti con la v0.41.0: controlli, fisica della palla, timing, rotazioni, parser/conversione, librerie native e tutti i PSA/PSK della cartella attiva. Le nuove aperture e i percorsi cambiano intenzionalmente il movimento, quindi il vecchio confronto di uguaglianza del gameplay v40/v41 non viene usato come prova per questa patch.

I test coprono scenari riproducibili, non tutte le possibili deviazioni e collisioni di una partita arbitraria. L'eccezione al secondo tocco S/L e limitata al caso legale in cui S ha ricevuto e L non e in campo; il salvataggio e in bagher d'emergenza.
