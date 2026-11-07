# Grafica integrata e qualità scalabile — 0.89.0

La revisione viene caricata dall'avvio normale, senza flag da prototipo. Le modalità di confronto precedenti sono ancora accessibili mediante `--graphics-previous88`, `--graphics-baseline85` e i launcher locali storici. Non vengono installati driver o modificati parametri di Windows.

## Ambiente e materiali

Nuove mappe numeriche del pavimento sportivo (2048px) con variazione della rugosità e piccole tracce di usura, mantenendo pigmenti e sponsor dei dodici campi. Rete e pali mantengono geometria funzionale e comportamento precedenti; sono aggiunti tiranti e tensionatori decorativi. Migliorati materiali delle imbottiture, panchine, monitor e strutture. Nuovi impianti di ventilazione, giunti, pilastri, pannelli, vetrature e dettagli del soffitto. Corretta anche la scala locale dei tubi decorativi, per evitare allungamenti non coerenti con la loro direzione.

Le aggiunte sono MultiMesh e non creano nuovi collisori: il confronto delle forme di collisione viene eseguito separatamente. Sponsor, linee e dimensioni del campo rimangono quelli esistenti.

## Personaggi e pubblico

Il primo slot atleta utilizza la base da scansione già valutata, con livelli di dettaglio dedicati; gli altri atleti e le riserve mantengono volti e varietà originali, con corpi e divise più dettagliati. Non viene duplicata la stessa scansione su tutta la rosa. Le scelte del database per capelli, barba e carnagione sono applicate anche dopo i cambi di preset. Le acconciature più particolari usano gli asset originali adattati alla nuova testa; i dettagli essenziali non vengono sostituiti da una singola pettinatura comune.

Il pubblico usa 48 mesh (12 varianti × 4 livelli), con buffer compattati. Nei livelli alti due varianti maschili integrano la testa fotografica e gli occhi separati. Le altre varianti conservano genere, pose e abbigliamento precedenti. Sono presenti variazioni aggiuntive della forma del viso e della carnagione. Animazioni, eventi e posizioni del pubblico non vengono riscritti.

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

I benchmark renderizzati a 1920x1080 sulla RTX 5080 misurano circa 0,61 ms GPU e 366 MiB di allocazione del motore in Basso, contro 5,91 ms e 2.293 MiB in Ultra. Alto viene ripetuto tre volte; gli altri preset hanno una misura descrittiva ciascuno. Il limite CPU della stessa simulazione rimane presente: questi dati non implicano un aumento proporzionale degli FPS, né sono una prova su hardware meno potente.

Il controllo visivo ravvicinato ha individuato e corretto una degenerazione del LOD più semplificato della testa. Si conserva un minimo di 11.356 triangoli per la testa pilota, invece di accettare deformazioni del cranio per ottenere un conteggio inferiore. Anche le teste aggiunte al pubblico utilizzano questo livello stabile.

Confronto visivo: [galleria del gioco principale](graphics89-review.html). Controlli di qualità, integrità dei file di simulazione, collisioni, regressioni, partite renderizzate e coppie host/ospite sono raccolti in `graphics89-validation.json`. Gli installer e il pacchetto vengono verificati prima del rilascio, con sentinelle per carriere, Diventa un mito, database personale e controlli.

Il cambio di versione del software è intenzionale. Non vengono cambiati nome dell'applicazione o percorso dei salvataggi. L'aggiornamento selettivo esegue il confronto con i file installati e può partire dalla 0.85 o saltare altre versioni; l'archivio completo rimane disponibile come recupero.
