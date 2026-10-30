# Campionato: calendario e regole verificati

Verifica del 29 ottobre 2026. Il calendario iniziale viene importato, non generato. Sono presenti tutte le **132 gare**, le 22 giornate, dodici club, undici incontri in casa e undici fuori per ciascuno. Nessun risultato reale entra in una nuova carriera.

## Fonti

- [Calendario ufficiale di andata](https://ww2.legavolley.it/Calendario.asp?Anno=2026&IdCampionato=999&IdFase=1&IdSquadra=0) e [ritorno](https://ww2.legavolley.it/Calendario.asp?Anno=2026&IdCampionato=999&IdFase=2&IdSquadra=0).
- [Calendario completo pubblicato da Dallarivolley](https://www.dallarivolley.com/it-it/i-calendari-dei-campionati-di-serie-a-maschili-202627.aspx): secondo riscontro indipendente di tutte le 132 coppie, del campo e della giornata. Il nome Cuneo Volley è ricondotto all'ID già presente del club Acqua Sant'Anna Cuneo.
- [Formula ufficiale SuperLega 2026/27](https://www.legavolley.it/formula-superlega-2026-27/): playoff, Play Out, entrambe le formule del quinto posto, Coppa Italia, diritti di Supercoppa e riconoscimenti europei.
- [Supercoppa: semifinali](https://ww2.legavolley.it/Calendario.asp?Anno=2026&IdCampionato=1004&IdFase=6) e [finale](https://ww2.legavolley.it/Calendario.asp?Anno=2026&IdCampionato=1004&IdFase=7): 14–15 novembre, PalaRaschi di Parma. Partecipanti e abbinamenti della prima edizione sono quelli pubblicati dalla Lega.
- [Carte federali FIPAV attualmente vigenti](https://www.federvolley.it/regolamenti-0), Regolamento Gare, articoli 41–42. L'elenco corrente rimanda al testo con modifiche del 2023, ancora indicato come vigente: non è stato usato un regolamento territoriale di un altro sport.
- [Tabellone ufficiale di riferimento](https://www.legavolley.it/risultati/?IdCampionato=991): ordini 1–8 / 4–5 / 2–7 / 3–6 e accoppiamento delle semifinali. Le date mostrate in quel tabellone storico non sono usate: le date 2026/27 vengono dalla formula corrente.

I file distribuiscono soltanto dati fattuali normalizzati e relativi URL/hash: nessuna fotografia o copia integrale degli articoli. Non viene dichiarata una licenza inesistente sulle pagine esterne.

## Importazione e gate

`tools/Build-CareerData66.py` usa le due pagine ufficiali e il secondo calendario, conserva le pagine di lavoro soltanto in `.runtime`, verifica le 132 triple giornata/casa/trasferta e produce i file in `data/competitions`. [Report di confronto](career66-calendar-validation.json).

Ogni incontro conserva data nominale, data programmata, orario, fonte e data di verifica. Per esempio Verona–Civitanova rimane nella prima giornata nominale del 18 ottobre ma si disputa il 17; Perugia–Padova resta nell'undicesima giornata nominale del 20 dicembre ma mantiene l'anticipo del 28 ottobre. L'orchestratore deve ordinare gli eventi per data programmata.

`career_rules.official_schedule()` impedisce l'avvio ufficiale se mancano gli abbinamenti, il riscontro indipendente, la provenienza o se sono presenti risultati precompilati. Il motore non ripiega silenziosamente su un girone inventato.

## Regole

La configurazione separa tutte le competizioni. Il Play Out distingue il distacco massimo di sette punti da quello di almeno otto, con i bonus previsti, ma disabilita la retrocessione effettiva per scelta di progetto. Il quinto posto distingue il tabellone a quattro dalle tre eliminate ai quarti più l'ingresso in finale della peggiore semifinalista Scudetto. Le competizioni europee sono soltanto riconoscimenti di qualificazione.

Le date di Coppa Italia 2026/27 sono verificate; la sede della Final Four non è stata identificata in una fonte corrente affidabile. Perciò la configurazione usa **Campo neutro**, con `venue_verified=false`, senza attribuire automaticamente a Bologna la sede di una stagione precedente.

La classifica ordina punti, vittorie, quoziente set, quoziente punti e confronti diretti. I quozienti sono confrontati con prodotti interi: una differenza piccola non viene cancellata dalla tolleranza dei float. Le parità multiple usano i punti degli scontri tra le sole squadre rimaste alla pari. Un'ulteriore parità assoluta ha un ordine stabile per ID, finché il regolamento non la risolve con altri dati disponibili; non viene presentato come un risultato sportivo diverso.

## Stagioni successive

Dal 2027/28 il calendario è **simulato**, con seed salvato, campi alternati, ritorno asimmetrico e separazione minima dei confronti. Le date restano tra ottobre e febbraio, lasciando finestre per Supercoppa e Final Four e aggiungendo turni infrasettimanali negli anni con meno domeniche. I diritti della Supercoppa devono derivare dalla stagione della carriera appena conclusa: la configurazione futura non riutilizza i partecipanti reali del 2026.

`tools/Test-CareerRules66.gd` verifica il primo campionato, anticipo e provenienza, gate sugli errori, classifica, condizioni delle coppe e undici calendari consecutivi fino al 2037/38. [Report](career66-rules-tests.json).
