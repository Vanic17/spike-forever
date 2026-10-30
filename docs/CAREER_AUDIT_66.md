# Audit e integrazione 0.66

## Sistemi riutilizzati

Database e override locali: `league.gd`; identità/divise: `avatar.gd`, `club_kits.gd`; impostazioni/lingua/controller e tastiera virtuale esistenti; lobby e autorità online esistenti; scoring 6v6 esistente; replay e stinger 0.65.

Il documento Word fornito è stato letto integralmente. Il precedente documento sui regolamenti nominato al suo interno non era disponibile nella cartella indicata: i dati sono stati verificati sulle fonti ufficiali elencate in CAREER_DATA_66.md, senza inventare formule mancanti.

## Riferimento UI

Consultato il repository dell'utente https://github.com/Vanic17/football-life-master-league, README, struttura e `football-life/engine/web/style.css`. Adattati a Godot la palette scura, le card editoriali, il focus chiaro, le sezioni dense e il footer controller; nessuna dipendenza dal motore web Football Life. Immagini neutre prodotte nell'arena del gioco, con manifest locale in `assets/ui/career66/manifest.json`; loghi e divise già presenti riutilizzati.

## Separazione dei sistemi

`career_rules.gd`: calendario e formule. `career_manager.gd`: calendario, competizioni, news, condizioni, risultati e archivi. `career_simulation.gd`: risultati stimati. `career_save.gd`: persistenza atomica. `match_management.gd`: cambi, condizione ed eventi misurati nel 6v6. `career_menu.gd`/`career_widgets.gd`: UI e focus. Il movimento dei giocatori, le rotazioni e la fisica restano nel motore match.

I risultati giocati e simulati hanno lo stesso schema e un ID univoco. La UI rimappa correttamente casa/trasferta quando l'utente gioca sempre sul lato vicino della camera. Un'interruzione non crea risultati o statistiche fittizie.

## Cause concrete dei tre difetti UI

1. Il VBox dell'intestazione superava l'altezza assegnata e Salva ereditava l'espansione orizzontale; ora testi, spazi e pulsanti sono dimensionati separatamente.
2. L'intestazione della classifica era una singola Label con spazi manuali, mentre le righe avevano colonne vere. Ora entrambi usano lo stesso layout.
3. `focus_entered` delle riserve assegnava direttamente `incoming`. Ora il focus scorre soltanto; solo A/Croce o il clic selezionano, e un'ulteriore conferma applica il cambio.

## Consegna per fasi

Il publisher supporta `-Phased`: dati/regole; backend; gestione partita; UI; replay/bilanciamento; metadati e prove finali. Le modifiche vengono pubblicate insieme in una sola release completa, mantenendo commit separati per la revisione.

## Limiti dichiarati

Foto esterne non aggiunte: il profilo usa l'aspetto effettivo dell'atleta nel gioco. Gli infortuni e la forma sono simulati. La Final Four di Coppa Italia rimane senza sede reale non verificata. Calendari dal 2027/28 sono simulati e i riconoscimenti europei non generano competizioni. Il confronto sui monster block misura contatti identici; la frequenza per partita dipende da attacchi e qualità del muro.
## Verifica performance

Microbenchmark CPU isolato: la gestione di resistenza e statistiche ha richiesto circa 0,048 ms per tick su 10.000 iterazioni. Il valore misura questo sottosistema, non gli FPS del renderer né la latenza di rete. La simulazione di un passo calendario, che può risolvere anche le gare cronologicamente precedenti, ha richiesto in media 42,7 ms su 30 passi. Vedi `career66-performance.json`.
