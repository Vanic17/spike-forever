# Asset necessari per completare il salto qualitativo dei personaggi

Questa lista distingue ciò che è presente dal lavoro ancora necessario. Il prototipo locale rifinisce un modello esistente: non fornisce una nuova anatomia fotografica, nuove identità facciali o capelli ricostruiti.

| Asset | Requisiti concreti | Compatibilità da verificare |
|---|---|---|
| Testa maschile atletica | Anatomia scolpita di palpebre, bordi delle labbra, narici e padiglione auricolare; base 20–40 mila triangoli con LOD; collo raccordato alla maglia | Coordinate e scala dell'attuale testa; bind pose originale; stessi nomi/indici delle ossa, nessuna nuova animazione o contatto |
| Texture del volto | Albedo 4K senza ombre dipinte, normal tangent-space, roughness, maschera SSS; almeno 6 identità e incarnati distinti | UV coerenti con la nuova testa, color management sRGB/lineare corretto, stesso sistema di tinta del database |
| Occhi e palpebre | Bulbo e cornea separati, bordo palpebrale corretto, iride e sclera calibrate | Posizione e orientamento dei bulbi attuali; nessuna modifica ai movimenti della testa o alle gerarchie |
| Capelli e barbe | Almeno 8 tagli e 3 barbe con vere ciocche sottili, alpha/roughness/normal/direzione; 2–3 LOD | Attaccatura e silhouette adatte alla testa; ombre e bordi stabili a MSAA 2/4/8, senza reticoli o sorting visibile |
| Mani e corpo | Topologia anatomica per nocche, dita, gomiti e spalle, normal/roughness coerenti, cuciture dei raccordi nascoste | Lunghezze e posizione dei segmenti originali, skinning validato su tutte le famiglie di animazioni, hitbox e mani di contatto inalterate |
| Abbigliamento | Colli e cuciture geometriche credibili, pieghe e tessuto PBR, UV compatibili con le divise esistenti | Sponsor, numeri e nomi preservati; nessuna compenetrazione nelle pose estreme |
| Pubblico modulare | Almeno 8 teste maschili e 8 femminili, 4 corporature, capelli e abiti modulari con atlanti; 3 LOD | Stesse pose disponibili e stesso posizionamento nelle sedute; istanze e collisioni esistenti conservate |
| Arena dedicata | Modello architettonico con gradinate, ingressi, parapetti, copertura e area tecnica, UV per illuminazione statica | Dimensioni funzionali del campo e corridoi invariati, nessuna nuova collisione implicita, tutte le camere leggibili |

Gli eventuali modelli esterni devono avere una licenza che consenta uso e distribuzione nel gioco, inclusi file derivati. Non sono stati scaricati o introdotti nuovi asset esterni di provenienza incerta.

Procedura proposta: un atleta pilota, confronto con il rig originale, verifica di tutti i contatti e delle pose estreme, prove in gioco/replay e misure ripetute; estensione agli altri atleti soltanto dopo tale validazione. La sola suddivisione di una mesh non sostituisce la scultura anatomica né crea dettaglio fotografico assente nella texture.
