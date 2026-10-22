# Verifica del posizionamento maschile

La demo installata di **Killer Aces Volleyball** usa `modeGender = 0`: modalità maschile. Il valore è stato letto dai dati serializzati originali, in `docs/reference-killer-aces/manager-settings.json`. L'assembly analizzato ha SHA-256 `902dba68884bcf97cd29baabc5184c069aaaa96a7a01a57097e5b51388ecace4`.

Le tabelle `locServe`, `locReceive` e `locBase` sono comuni alle due modalità. La precedente estrazione delle posizioni non selezionava una formazione femminile. La differenza compare nella logica delle rincorse e nella scelta del bersaglio dell'alzata, non nella rotazione delle sei zone.

Nel codice originale `player.cs`, `JobMover` (righe 2363–2386), la rincorsa laterale del centrale verso l'antenna è legata alla slide, identificata da `setTargKind = -3`. La scelta automatica della slide è limitata alla combinazione `trackSetterFront == 1 && modeGender == 1` (righe 5570–5620). È distinta dal primo tempo maschile dietro il palleggiatore, identificato da `setTargKind = -1`, che resta un attacco del centrale vicino all'alzatore e non una corsa fino all'antenna.

Nella modalità maschile, quando il palleggiatore è in prima linea, la scelta della direzione 2 individua invece l'opposto in seconda linea: `flag3` a riga 5575 e `setTargKind = 8` nel ramo successivo. L'opposto prepara la palla D; lo schiacciatore di seconda linea prepara la pipe. `manager_game.TeamRotation` (righe 4560–4735) mantiene separati questi bersagli e il centrale di prima linea.

La verifica di questa revisione confronta le coordinate originali di battuta e ricezione, i ruoli nelle sei rotazioni, le aperture degli attaccanti, le file di copertura e le basi difensive. Sono esclusi da questo confronto i parametri della fisica, i comandi, il tempismo e le animazioni della demo: il riferimento viene usato per il solo posizionamento.

Conversione delle coordinate: larghezza locale = `-Unity.z`, profondità locale = `-Unity.x`; la seconda squadra è specchiata su entrambi gli assi del terreno. Nel riferimento, l'area di alzata è larghezza 1,5 m / profondità 0,5 m, le bande preparano la rincorsa fuori dalla linea laterale a larghezza 5 m / profondità 4 m, e le coperture hanno profondità 2 m in prima linea e 4,26 m in seconda linea. Il palleggiatore che ha effettuato l'alzata conserva invece la sua corsia a profondità 0,5 m: il suo ramo in `JobMover` precede quello delle coperture.

`tools/Test-Positioning.gd` supera **840 verifiche**: 144 coordinate originali di battuta/ricezione, basi difensive per ruolo, aperture normali e veloci delle bande, preparazione e avanzamento del centrale, corsie dell'opposto e della pipe, coperture distinte e instradamento dei bersagli effettivi dell'IA. Le verifiche coprono entrambe le squadre e tutte e sei le rotazioni. Esito registrato in `docs/positioning-audit-v11.json`.
