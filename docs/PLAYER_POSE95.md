# Correzione locale: volto, salti e pallonetto

## Volto

Il singolo giocatore con il prototipo 88/89 usava una testa diversa dagli altri:
profondità di circa 18,4 cm e collo pesato interamente su Head. Il modello
compatibile ha circa 24,3 cm di profondità e una distribuzione articolata
dei pesi. Il primo è stato sostituito nel gioco principale, insieme a occhi,
capelli e barba coerenti con il relativo modello e atlante UV.
Il prototipo grafico 93 resta separato; non è stato distribuito al roster.

I canali facciali delle animazioni PSA possono deformare le teste di roster:
per questi personaggi si mantiene la forma neutra del bind delle ossa facciali.
Restano movimento di testa e collo, orientamento e animazioni del corpo.
Questo stabilizza il viso ma sospende le espressioni facciali dei vecchi clip.

## Salti

Prima: nel campione di riferimento la testa (giunto, senza sommità del cranio)
raggiungeva 2,83 m in attacco, 3,01 m a muro e 2,69 m in battuta al salto.

Ora il massimo del giunto viene calibrato in base all'altezza del giocatore,
aggiungendo 12 cm scalati per stimare la sommità del cranio. Il bersaglio
è il nastro a 2,42 m. La compensazione verticale segue gradualmente la fase
aerea, senza spostare la radice del giocatore o cambiare il tempo del colpo.
Il punto di contatto usato per pianificare le traiettorie riceve la stessa
compensazione: non è un semplice abbassamento della mesh rispetto alla palla.
La float rimane con il gesto originale più basso.

Misurati attacco, muro e salto su stature da 170 a 210 cm, oltre a tutte le
34 varianti di salto registrate. Il valore è approssimato: inclinazione della
testa, capigliatura e blending possono cambiare leggermente la silhouette.

## Pallonetto

La patch precedente applicava soprattutto una posa del polso: lasciava troppo
a lungo il gomito caricato da schiacciata. Ora l'apertura comincia prima del
contatto, con gomito più avanti, braccio alto e seguito corto. La correzione
è sovrapposta alla posa nativa valutata da AnimationTree, mantenendo un solo
autore della posa finale dello scheletro. Il punto della mano al contatto
rimane invariato; destri e mancini condividono il gesto specchiato.
È una ricostruzione ispirata al riferimento, non motion capture del filmato.

## Verifiche e consegna

- `Test-PlayerPose95.gd`: 1571 controlli; statura, contatto, varianti, volto e due mani.
- `Test-NetTip94.gd`: 218 controlli di rete e pallonetto superati.
- `Test-RunningAttack62.gd`: 72 casi, due squadre, sei rotazioni, zero fallimenti.
- `Test-Fluidity84.gd`: superato.
- Profilo renderizzato: `profile95-pilot.png`.
- Fasi del pallonetto renderizzate: `pose95-tip-0.png` ... `pose95-tip-3.png`.
  Sono studi di posa: la palla a terra non rappresenta una traiettoria live.

Tutti i test usano profili isolati. Database e carriere personali non sono
modificati. Le modifiche sono nel sorgente locale, avviabile con
`Avvia Spike Forever.cmd`; nessun eseguibile distribuito è stato sostituito
e non è stata eseguita una pubblicazione GitHub. Per l'online servono due
build uguali: protocollo locale `SF090-POSE95`, perché i contatti sono cambiati.
