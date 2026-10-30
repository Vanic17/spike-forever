# Spike Forever 0.66.0

## Gioca e Campionato

Gioca apre tre modalità: Esibizione, Online e Campionato. Online è ora all'interno di Gioca. La nuova carriera usa i dodici club del database e un salvataggio locale autonomo, senza sovrascrivere le modifiche dell'editor.

- Calendario ufficiale 2026/27 completo: 132 gare, senza risultati reali preassegnati. Dal secondo anno calendario asimmetrico deterministico.
- Regular Season, Coppa Italia, Supercoppa, Playoff Scudetto, entrambi i percorsi del quinto posto e Play Out a tre/quattro squadre. Nessuna retrocessione effettiva finché non esiste la Serie A2.
- Dashboard con calendario mensile/per giornata, classifiche, tabelloni delle serie, rosa, ritratto del giocatore nel gioco, statistiche filtrabili, notizie virtuali, risultati e archivio delle stagioni.
- Formazione e rotazione iniziale persistenti. Condizione, forma e indisponibilità simulata sono separate. Opzioni indipendenti per valori giocatori, fatica, infortuni, autosave e sostituzioni automatiche.
- Simulazione rapida oppure dettagliata con cronaca punto per punto. I tabellini delle partite giocate usano solo eventi misurati; quelli simulati sono dichiarati come stime.
- Salvataggi con checksum, backup e ripristino. Le partite interrotte restano da disputare; una partita completata viene conteggiata una sola volta, anche giocando in trasferta.

La sede della Final Four di Coppa Italia 2027 non è inventata: rimane neutra/non annunciata finché una fonte ufficiale non la rende disponibile. Le stagioni successive e le dichiarazioni nelle notizie sono esplicitamente virtuali. Nessuna gara europea viene simulata.

## Sostituzioni e resistenza

Dal menu pausa si apre Gestione partita. Sei cambi ordinari per set, con abbinamento titolare/riserva e un solo rientro; ingresso del libero separato. Prima della prima battuta di ogni set la formazione è libera. Sono gestite le sostituzioni eccezionali per indisponibilità quando non esiste un cambio ordinario consentito.

Il menu presenta tre passaggi: **scegli chi esce → scegli chi entra → conferma**. Scorrere non seleziona una riserva. B/Cerchio torna indietro di un passaggio. Il confronto mostra ruolo, sei attributi, condizione e forma; il contatore distingue i cambi ordinari. Il cambio viene realmente applicato ai giocatori in campo, anche online con autorità dell'host.

La fatica cresce con impiego, corsa, salti e contatti. Le penalità sono graduali e limitate; fatica OFF disattiva esattamente il suo contributo. In carriera forma e recupero persistono fra gli incontri. L'host può scegliere fatica ON/OFF anche nella stanza online.

## Correzioni UI richieste dagli screenshot

- Header ridimensionato: squadra, stagione e progresso restano sopra le schede; Salva e Indietro hanno dimensioni proprie.
- Intestazione e valori della classifica condividono lo stesso componente di colonne, senza spaziature manuali.
- Sostituzioni più compatte, con conferma visibile anche a 720p e scorrimento indipendente delle due liste.
- Il focus non modifica più il giocatore entrante. Navigare oltre l'ultima riga non effettua alcuna scelta.
- Conferma delle formazioni raggiungibile con controller; ritorno al focus precedente, scroll automatico e stick destro per leggere le sezioni lunghe.

## Replay e muro

Lo zoom del logo è leggermente più lento. Il filmato include un secondo registrato dopo il punto, circa 1,05 secondi visibili in più alla velocità del replay.

I monster block richiedono un contatto più chiuso; i contatti intermedi producono più tocchi giocabili. Nel confronto riproducibile di 20.000 contatti identici la frequenza relativa dei monster block diminuisce del 43,96%, senza aumentare i mani fuori. Questo è un confronto fra contatti, non una promessa di un numero fisso di muri per set. Il muro perfettamente chiuso rimane decisivo.

## Compatibilità e verifiche

Entrambi i partecipanti online devono usare **0.66.0 / SF066**. Gli aggiornamenti preservano controlli, impostazioni, modifiche roster, progressi tutorial e carriere locali. Nessuna installazione viene eseguita sulla copia di gioco personale durante i test.

Prove: dieci stagioni complete, integrità/backup dei salvataggi, calendario e formule, limiti/rientri dei cambi, neutralità OFF, risultati giocati casa/trasferta, controller sintetico A/B/D-pad, layout desktop/TV, sostituzioni online e ripristino dei replay. Rapporti JSON e screenshot `career66-*`, `match66-*`, `online66-*`, `replay66-*` inclusi nel pacchetto e nel repository.
