# Versione 0.25.0

Analizzati entrambi i video forniti, incluso il finale del primo e lo scambio finale del secondo.

## Accesso e contatto del palleggiatore

La destinazione della ricezione veniva liberata rispetto ai soli compagni a terra. Ricevitori in piedi e giocatori in atterraggio potevano ancora occupare il punto necessario al secondo tocco. La prenotazione prima del lancio considera ora anche le loro impronte e sceglie un punto libero vicino alla destinazione originaria. Una ricezione perfetta resta in zona 3; la zona non viene ridotta a una coordinata singola occupata da un corpo. Collisioni e distanze non sono disattivate.

Inoltre il lancio usava l'altezza generica del palleggio prima di selezionare la variante visiva. Ora il primo passaggio viene finalizzato sull'altezza delle mani della performance scelta, prima del primo passo di simulazione del volo. La conferma normale/veloce conserva la scadenza fisica di arrivo: sceglie la consegna senza introdurre una finestra perfetta aggiuntiva. Colpo di seconda e bagher di emergenza conservano il loro diverso contatto.

La CPU non aveva un controllo di timing dell'alzata: i suoi contatti mancati potevano dipendere dall'arrivo fisico, dagli ingombri e dalla discrepanza fra posa e palla. Non sono stati introdotti punti o tocchi automatici. Il giocatore deve ancora confermare il colpo prima dell'arrivo; senza input il secondo tocco non parte. Ricezione e qualità del primo passaggio restano rilevanti.

Il nuovo `Test-SetReliability.gd` verifica sequenze di ricezione e secondo tocco reali, con ricevitore vicino al palleggiatore, conferma iniziale/intermedia/tardiva, entrambe le squadre e più rotazioni. Restano i test su corpi a terra, rincorse dopo il muro e rigioco.

## Tempi delle alzate

Tempi nominali a ricezione perfetta; resta il limite fisico per consentire all'attaccante di completare una rincorsa raggiungibile.

| Destinazione | Normale | Veloce |
|---|---:|---:|
| Centro | 0,62 s | 0,42 s |
| Bande, compresa alzata dietro | 1,02 s | 0,82 s |
| Pipe | 0,92 s | 0,88 s |

Il centrale destinatario di una veloce prepara subito l'appoggio durante il primo passaggio, invece di aspettare la parte finale prima di chiudere sotto rete. Una ricezione difficile conserva la penalità di qualità precedente e può richiedere una palla più alta.

## Battuta

Barra completa in 0,70 s invece di 0,74 s. Tempo nominale al 100%: salto 0,76 s invece di 0,79 s, float 0,92 s invece di 0,96 s. Aumento di velocità circa 4%, con carica oltre il 100% e rischio proporzionale conservati. Calibrata la mira corta alla maggiore velocità e verificati passaggi sulla rete con salto/float, sei rotazioni e tre posizioni laterali.

Controlli, camera TV, rotazioni, 48 animazioni, velocità degli atleti e integratore della palla restano invariati. Verifica: `tools/Test-Game.ps1` e controllo di ambito v25.
