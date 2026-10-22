# Versione 0.22.0

## Pannello aggiornamenti

Il pannello nascosto calcolava inizialmente le etichette a larghezza zero: il minimo del PanelContainer raggiungeva 3351 pixel e rimaneva sovradimensionato. Titolo e pulsanti uscivano dallo schermo. Il pannello ora ha dimensioni indipendenti dal minimo dei contenuti; i container interni lavorano nella sua area visibile. Ricerca automatica, conferma, elenco storico e installazione restano disponibili. Il test attende i riordini differiti dei container e verifica tutti i controlli su quattro risoluzioni.

## Primo attacco R1

L'identità OH1 e la sua posizione di ricezione a destra erano corrette, ma l'assegnazione obbligatoria OH in zona 4 imponeva un attraversamento completo prima del primo attacco. In R1 sulla ricezione del servizio OPP offre ora zona 4 e OH1 zona 2. Apertura, percorso preparatorio e scelta del destinatario condividono la stessa assegnazione. Le identità, i sei slot e la rotazione al cambio servizio non cambiano. Nelle successive transizioni restano le corsie specialistiche ordinarie.

La precedente soluzione v21 del solo tempo di rincorsa non risolveva questo errore tattico: la v22 corregge l'assegnazione. La pianificazione progressiva dell'arrivo rimane disponibile per recuperi e altre rincorse effettivamente lunghe.

## Ricezione vicina al palleggiatore

La riserva del corridoio era esclusa per percorsi inferiori a 65 cm. Un ricevitore vicino al bersaglio poteva quindi occupare lo spazio fisico necessario al secondo tocco, mentre l'animazione delle braccia partiva normalmente. Ora anche gli approcci corti riservano il volume del contatto e il compagno in piedi libera lateralmente la zona. I giocatori a terra conservano l'aggiramento del corpo: non vengono spostati artificialmente.

Otto prove dedicate verificano secondi tocchi reali su entrambi i lati del ricevitore, entrambe le squadre, 60/120 Hz e scadenza originale della ricezione. Restano le verifiche dei recuperi a terra.

## Battuta

- Carica completa in 0,78 s anziché 1,05 s; la carica dell'attacco resta invariata.
- Tempo nominale del servizio al salto al 100%: 0,82 s anziché 0,90 s. Float: 1,00 s anziché 1,12 s.
- Oltre il 100% nessun limite alla potenza effettiva: il tempo di volo continua a scendere in rapporto alla carica, mantenendo l'incremento della velocità reale. Anche le traiettorie di errore tengono conto della potenza.
- Rischio aggiuntivo proporzionale al sovraccarico: 110% = 25%, 120% = 50%, 140% = 100%, ripartito fra rete e fuori. Sono simulati traiettoria e collisione reali.
- Mira del servizio continua con la levetta sinistra; alto profondo, basso corto, sinistra/destra nel campo avversario. Il bersaglio non dipende dalla posizione laterale del battitore. L'attacco conserva le otto direzioni.

La matrice verifica tutte le sei rotazioni, tre posizioni di partenza, sette direzioni, salto/float e potenze 100/110%, inclusi contatti, traiettorie alla rete e velocità reale. Il modello di gravità, spin e collisioni resta invariato, come ricezione, alzata, attacco e controlli.

Verifica completa: `powershell -ExecutionPolicy Bypass -File tools/Test-Game.ps1`. Il controllo di ambito v22 confronta con v21 tutte le funzioni non autorizzate e conserva i controlli storici sulle animazioni e sulla fisica.
