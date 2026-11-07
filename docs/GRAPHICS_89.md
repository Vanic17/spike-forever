# Grafica integrata e qualità scalabile — 0.89.0

La revisione viene caricata dall'avvio normale, senza flag da prototipo. Le modalità di confronto precedenti sono ancora accessibili mediante `--graphics-previous88`, `--graphics-baseline85` e i launcher locali storici. Non vengono installati driver o modificati parametri di Windows.

## Ambiente e materiali

Nuove mappe numeriche del pavimento sportivo (2048px) con variazione della rugosità e piccole tracce di usura, mantenendo pigmenti e sponsor dei dodici campi. Rete e pali mantengono geometria funzionale e comportamento precedenti; sono aggiunti tiranti e tensionatori decorativi. Migliorati materiali delle imbottiture, panchine, monitor e strutture. Nuovi impianti di ventilazione, giunti, pilastri, pannelli, vetrature e dettagli del soffitto. Corretta anche la scala locale dei tubi decorativi, per evitare allungamenti non coerenti con la loro direzione.

Le aggiunte sono MultiMesh e non creano nuovi collisori: il confronto delle forme di collisione viene eseguito separatamente. Sponsor, linee e dimensioni del campo rimangono quelli esistenti.

Il riferimento della partita reale viene applicato al parquet: doghe da 18 cm, giunti sfalsati, fibre longitudinali e finitura sigillata, su mappe 2048px. Le tre superfici del campo utilizzano la stessa scala in metri. I colori delle maglie del pubblico sono convertiti nello spazio lineare dei MultiMesh, evitando l'aspetto slavato; le sedute hanno una finitura più scura. La visuale bassa passa a 6,3 m di altezza: durante lo scambio usa una distanza di 18,4 m e FOV 42°, allargandosi in battuta a 20,5 m e FOV 48° per inquadrare arretramento e lancio. Il raccordo è progressivo. La camera predefinita resta invariata e gli assi di mira restano gli stessi.

## Personaggi e pubblico

Il primo slot atleta utilizza la base da scansione già valutata, con livelli di dettaglio dedicati; gli altri atleti e le riserve mantengono volti e varietà originali, con corpi e divise più dettagliati. Non viene duplicata la stessa scansione su tutta la rosa. Le scelte del database per capelli, barba e carnagione sono applicate anche dopo i cambi di preset. Le acconciature più particolari usano gli asset originali adattati alla nuova testa; i dettagli essenziali non vengono sostituiti da una singola pettinatura comune.

Il pubblico usa 48 mesh (12 varianti × 4 livelli), con buffer compattati. Nei livelli alti due varianti maschili integrano la testa fotografica e gli occhi separati. Le altre varianti conservano genere, pose e abbigliamento precedenti. Sono presenti variazioni aggiuntive della forma del viso e della carnagione. Animazioni, eventi e posizioni del pubblico non vengono riscritti.

La barba piena del pilota utilizza fibre tridimensionali curve da 4–12 mm, aderenti alla scansione e allo stesso skinning Head/Neck. Ha quattro mesh effettive, da circa 10.000 a 242.000 triangoli. La variante corta rimane distinta. Nessuna simulazione dei peli viene aggiunta al ciclo fisico.

Fonte della scansione: Lee Perry-Smith / Infinite-Realities, CC BY 3.0; conversioni di Morgan McGuire, Guedis Cardenas e Keijiro Takahashi. [Attribuzione, licenza e modifiche](../assets/art/athlete88/ATTRIBUTION.md). Gli asset del gioco originale mantengono la propria provenienza; non sono tutti rilicenziati sotto CC BY.

## Preset con effetto reale

[Verifica renderizzata dei preset](graphics89-presets.json), con immagini alla stessa inquadratura e stato di simulazione. I conteggi si riferiscono al test, non a una stima.

| Dettaglio | Basso | Medio | Alto | Ultra |
|---|---:|---:|---:|---:|
| Texture del volto pilota | 512 | 1024 | 2048 | 4096 |
| Triangoli testa pilota | 11.356 | 22.712 | 45.424 | 69.194 |
| Triangoli corpo degli altri atleti | 7.472 | 7.472 | 29.888 | 29.888 |
| Triangoli divisa | 3.874 | 15.496 | 15.496 | 61.984 |
| Spettatori visibili nel test | 325 | 707 | 1.280 | 1.280 |
| Triangoli del pubblico prima del culling | 147.846 | 1.178.304 | 7.716.554 | 11.991.360 |
| Batch di nuovi dettagli visibili | 0 | 8 | 12 | 12 |
| Scala di rendering | 67% | 85% | 100% | 100% |

Gli indici LOD del pilota sono ricompattati in buffer più piccoli; non si tratta soltanto di nascondere triangoli lasciando una mesh identica in uso. Il pubblico seleziona effettivamente risorse diverse. Il preset basso disabilita normali del pavimento, scattering della pelle, riflessi e dettagli aggiuntivi. Le impostazioni personalizzate di texture, densità, ombre, antialiasing e scala continuano ad avere effetto.

Le risorse condivise già caricate possono restare nella cache del motore durante i cambi di qualità; non viene promesso che ogni byte di cache venga immediatamente restituito al sistema operativo. Il consumo e il numero di primitive vengono misurati nel renderer reale. Non sono stati emulati PC meno potenti: i preset riducono davvero il costo grafico, ma non costituiscono una certificazione per ogni GPU.

## Verifiche e distribuzione

### Correzioni online

Il percorso conclusivo di `press_action` poteva ordinare il salto del muro avversario quando il giocatore attaccante premeva ancora il comando durante o dopo la carica. Il ramo online verifica ora che chi invia il comando controlli effettivamente il muro. Ogni comando trasporta inoltre intento, scambio, volo, attacco, proprietario e clock: ricezioni e attacchi vecchi non vengono reinterpretati come comandi di un'azione successiva.

Il client applicava lo stato discreto del fotogramma futuro mentre interpolava ancora la palla dal precedente: questo anticipava ATTACK, animazioni e suoni rispetto al contatto visibile. La selezione dello stato segue ora il clock di presentazione; i cursori procedurali e di rincorsa vengono campionati, senza un secondo avanzamento locale. La ricezione considera il tempo autorevole mostrato al giocatore, con compensazione massima di 250 ms, senza spostare la palla o superare le finestre fisiche di contatto. L'host invia 60 snapshot/s; gli assi rimangono a 30/s e la simulazione a 120 Hz. Il buffer visivo passa a 25 ms.

Il protocollo cambia in SF089: entrambi i peer devono aggiornare. I test includono contatti reali host/ospite, database, sostituzioni, replay e polling ENet variabile fra 20 e 90 ms su entrambi i peer. Sono prove locali con jitter introdotto dal test, non una certificazione su ogni connessione Internet. Per latenze elevate restano i limiti fisici del contatto e della rete.

I benchmark renderizzati a 1920x1080 sulla RTX 5080 misurano circa 0,62 ms GPU e 366 MiB di allocazione del motore in Basso, contro 6,12 ms e 2.309 MiB in Ultra. Alto viene ripetuto tre volte; gli altri preset hanno una misura descrittiva ciascuno. Il limite CPU della stessa simulazione rimane presente: questi dati non implicano un aumento proporzionale degli FPS e non certificano ogni GPU.

Il controllo visivo ravvicinato ha individuato e corretto una degenerazione del LOD più semplificato della testa. Si conserva un minimo di 11.356 triangoli per la testa pilota, invece di accettare deformazioni del cranio per ottenere un conteggio inferiore. Anche le teste aggiunte al pubblico utilizzano questo livello stabile.

Confronto visivo: [galleria del gioco principale](graphics89-review.html). Controlli di qualità, integrità dei file di simulazione, collisioni, regressioni, partite renderizzate e coppie host/ospite sono raccolti in `graphics89-validation.json`. Gli installer e il pacchetto vengono verificati prima del rilascio, con sentinelle per carriere, Diventa un mito, database personale e controlli.

Il cambio di versione del software è intenzionale. Non vengono cambiati nome dell'applicazione o percorso dei salvataggi. L'aggiornamento selettivo esegue il confronto con i file installati e può partire dalla 0.85 o saltare altre versioni; l'archivio completo rimane disponibile come recupero.
