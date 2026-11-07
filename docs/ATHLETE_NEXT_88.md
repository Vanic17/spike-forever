> Historical prototype: integrated in release 0.89.0. The local-only status below describes its earlier review stage.

# Atleta da scansione — prototipo locale

[Confronto prima/dopo](athlete88-review.html) · [Geometria](athlete88-build.json) · [Verifiche](athlete88-validation.json).

Questa revisione continua sul singolo atleta. Il confronto è con il prototipo 0.87, non con un'inquadratura o un'illuminazione artificialmente peggiorata. Non sono stati aggiunti effetti generici alla luce dello stadio. L'avvio normale e il precedente prototipo rimangono disponibili.

Avvio: **Avvia Spike Forever - prototipo next gen.cmd**. Usa gli stessi menu e lo stesso gioco; soltanto il primo slot atleta riceve la nuova anatomia. Non vengono modificati gameplay, controlli, fisica, IA, rotazioni, database, salvataggi, animazioni, parser o AnimationTree. Non è una release pubblicata.

## Il salto di asset

Il limite principale era la base facciale della generazione originale. È stata integrata una **scansione reale della testa**, Infinite di Lee Perry-Smith, da un [repository con licenza CC BY 3.0 esplicita](https://github.com/keijiro/InfiniteScan). L'[attribuzione completa](../assets/art/athlete88/ATTRIBUTION.md) conserva autori, conversioni, fonte, licenza e modifiche. Non è un volto generato da un'immagine né una nuova scansione acquisita per questo progetto.

La geometria contiene realmente naso, labbra, orecchie, zigomi, mento e superficie anatomica del viso. La sorgente aveva gli occhi chiusi: le aperture sono state ricostruite con contorno a mandorla e un piccolo spessore del bordo; gli occhi sono sfere separate con iride e sclera. Non viene presentata una scansione a occhi chiusi come un giocatore finito.

Sono stati adattati scala, profondità e raccordo del collo al colletto esistente. La testa è pesata alle ossa Head/Neck già presenti; il mento segue la testa, mentre la transizione verso il torso rimane nel collo. Capelli e barba sono ricampionati sulla nuova superficie; i peli sotto il mento conservano la stessa transizione di pesi della pelle, per limitare distacchi durante l'animazione.

La texture fotografica originale è **4096×4096**, non un vecchio atlante 1K semplicemente ingrandito. La mappa normale deriva dal bump originale 1024px; roughness e scattering derivati sono 2048px. Il materiale separa zone più asciutte, fronte/naso e orecchie. I limiti di texture dei preset vengono rispettati: Alto riduce la texture a 2048px, Ultra usa la risoluzione nativa.

## Corpo, groom e divisa

- Capelli con curve rastremate e lieve variazione delle ciocche; barba corta coerente con la pelle della scansione. Sono mesh pesate, senza nuove ossa o simulazioni. Rimane un groom curato singolo, non una libreria completa di acconciature.
- Rilievo moderato di braccia, polpacci e polsi, conservando struttura e pesi del corpo esistente. L'atlante corporeo mantiene la sua risoluzione originale ed è calibrato cromaticamente verso la carnagione della scansione. Non è dichiarata una nuova scansione del corpo o delle mani.
- Divisa con geometria più fitta e pieghe effettive, piccoli bordi in rilievo, materiale tessile direzionale e risposta differente delle stampe. Nome, numero, sponsor, colori e UV delle maglie rimangono quelli della squadra selezionata.
- Scarpe differenziate come nell'anteprima precedente; gli altri atleti non adottano il modello del pilota.

## Confronto e prestazioni

Le sei viste principali includono volto, profilo, corpo intero, gameplay, mani/divisa e viso in grigio senza capelli/barba. Sono framebuffer del gioco. Stessa posa, camera, FOV, stato dello scambio, palla, RNG e illuminazione tra le due versioni. Le catture finali usano Ultra in entrambi i casi per mostrare la texture nativa; i benchmark ripetibili sono separati e usano Alto in entrambi i casi.

Sono verificati i pesi delle mesh e le deformazioni con le animazioni esistenti, il mantenimento dello stato di gameplay e i cicli di creazione/modifica/chiusura della scena. Tre benchmark per versione misurano il costo dello stesso scenario a 1920×1080, fisica 120 Hz, MSAA 4× e VSync disattivato. Il confronto degli hash protegge i 179 file di simulazione, animazioni e dati. Tutte le prove usano profili isolati.

I numeri sono nel rapporto JSON e nella galleria. Riguardano un atleta pilota, non dodici copie di questo asset.

Nel benchmark Alto ripetuto tre volte per versione: media circa 100,60 FPS prima e 102,81 dopo; tempo GPU 2,581 → 2,730 ms; p99 del frame 17,127 → 16,034 ms. Queste differenze di FPS non dimostrano un miglioramento generale: i tempi GPU aumentano leggermente e le prove hanno variabilità. L'allocazione video riportata dal motore passa da circa 1400,7 a 1544,2 MiB. Le catture Ultra non vengono impropriamente associate a questi FPS misurati in Alto.

## Cosa non è ancora risolto

È una base anatomica e fotografica superiore al precedente modello, ma **non viene dichiarato che l'intero gioco abbia raggiunto qualità AAA/next gen**. Corpo, mani, pubblico e molte altre risorse restano della generazione precedente. Gli occhi ricostruiti non hanno una nuova animazione facciale; il groom richiede ancora valutazione artistica. Una produzione moderna completa richiede ulteriori asset coerenti e retopologia professionale, non semplicemente l'aumento dei triangoli o dell'esposizione.

Questo candidato resta separato, da valutare prima di estenderlo ad altri giocatori. Il nome, il ruolo e le statistiche del giocatore del database non cambiano; la scansione non è un ritratto fedele di quel giocatore reale.
