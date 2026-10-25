# Spike Forever 0.51.0

## Modifica e formazioni

- Mano dominante: destra o mancino. I colpi a una mano, la battuta e la posa di preparazione sono specchiati sulle ossa, con scambio destra/sinistra. Numero, nome e tessuti restano leggibili; nessuna scala negativa della mesh. Contatto e IK seguono la mano scelta, sia con AnimationTree sia con PSA.
- Battuta preferita della CPU: salto o float. Il battitore CPU usa la propria preferenza; il giocatore umano mantiene i comandi già disponibili.
- Entrambi i campi sono navigabili con controller e salvati nei dati locali, conservati dagli aggiornamenti.
- Banda e opposto sono intercambiabili nelle formazioni. Il ruolo naturale resta visibile; il posto occupato determina il compito tattico. La scelta dello stesso giocatore in un altro posto scambia i due titolari, senza duplicati. Centrali, palleggiatore e libero mantengono i rispettivi vincoli.
- Ace garantito soltanto al **100% visualizzato**, senza sovraccarico. 97–99% non danno più l'ace automatico. La fascia 97–100% degli attacchi rimane invariata; velocità, rischi e barre non cambiano.

## Online

Il menu principale contiene **Gioca / Online / Aggiornamenti / Modifica**.

1. L'host apre Online, sceglie formato e punti, preme Crea partita e condivide il codice `SF-…`.
2. L'altro giocatore inserisce il codice e preme Unisciti. È disponibile la tastiera navigabile con controller.
3. Ognuno sceglie la propria squadra, divisa e formazione, comprese sostituzioni e rotazione iniziale.
4. Entrambi premono Conferma / Pronto. Per cambiare le scelte dopo la conferma si annulla prima lo stato Pronto.
5. L'host preme Inizia partita. Solo l'host sceglie durata in set e punti; valgono vantaggio di due punti e set decisivo a 15.

La camera frontale viene mostrata dal **proprio lato** su entrambi i PC. Non viene condivisa la camera dell'host: per l'ospite cambiano posizione della camera e conversione dei comandi locali. Sinistra/destra per banda, opposto, battuta e muro seguono la propria vista. L'online mantiene questa camera, senza passare alla laterale.

L'host simula palla, contatti, regole e giocatori. Entrambe le squadre hanno ricezione, alzata, attacco, battuta e muro manuali: la seconda squadra non viene affidata alla CPU. I due centrali a muro conservano comandi e spostamenti separati. Le preferenze, i nomi, i numeri, le divise e gli aspetti scelti in locale vengono condivisi per la partita. I valori restano placeholder.

Pausa/ripresa sono sincronizzate. A fine partita viene comunicata la chiusura prima di chiudere il trasporto, e i due giocatori tornano alla home. L'uscita volontaria o la perdita della connessione chiude la sessione; le porte vengono liberate.

### Connessione come in Volley Rivals

È stato ripreso il sistema del progetto locale Volley Rivals v0.43: codice con indirizzo IPv4, porta e identificativo casuale della stanza, con controllo degli errori di digitazione. **È una connessione diretta all'host, senza servizio relay.** Il codice non è una directory ospitata su GitHub.

- UDP **26761**; tentativo automatico di apertura tramite UPnP e rimozione alla chiusura.
- Modalità Internet con rilevamento dell'indirizzo pubblico; modalità stessa rete / VPN LAN con indirizzo locale.
- Se UPnP non è disponibile, l'host deve essere raggiungibile tramite inoltro della porta o VPN LAN. Dietro CGNAT il solo codice non crea una porta pubblica.
- I due PC devono usare questa stessa versione del gioco.

### Trasmissione

Stato autorevole a 30 Hz, pacchetti compressi, riferimenti compatti ai clip e interpolazione con palla e personaggi sullo stesso orologio. Le posizioni visive trasmesse sono quantizzate al millimetro; la fisica sull'host mantiene i valori originali. I payload più grandi vengono suddivisi in parti da massimo 1100 byte e ricomposti per sequenza, anche se arrivano fuori ordine. Non vengono trasmesse le pose di ogni osso né ricreate librerie durante lo scambio.

La barra dell'ospite parte immediatamente sul suo PC. Il rilascio comunica la durata della pressione, così il 100% visualizzato non diventa un sovraccarico per il solo ritardo del messaggio di rete.

## Verifiche

- Due processi Godot indipendenti: ingresso tramite codice e pulsanti reali della lobby, scelte individuali, banda nello slot opposto, avvio host, servizi float/salto, ricezioni, alzate, attacchi e recupero in tuffo, pausa remota e ritorno di entrambi alla home.
- Uscita volontaria dalla lobby su due processi, con comunicazione all'host e chiusura del trasporto.
- Rilevamento reale dell'IP pubblico, generazione dei codici Internet/LAN, UPnP e verifica che la porta di prova sia di nuovo libera.
- D-pad, A/Croce e B/Cerchio: menu iniziale, tastiera del codice, formazioni e ritorno; controlli visibili anche a 1280×600.
- Preferenze locali, 16 contatti mancini su due lati e due sistemi di animazione, quattro servizi mancini completi e muro a tre manuale su entrambe le squadre.
- 24 costruzioni con due squadre umane e tutte le rotazioni; regressione delle 96 costruzioni offline, dei 48 casi di muro e di tutti i formati partita.

La partita completa in rete è stata verificata su loopback con due processi separati. La verifica Internet copre rilevamento dell'indirizzo e UPnP; non equivale a una prova da due abitazioni diverse.

Anteprime: [menu iniziale](menu51-home.png), [online](menu51-online.png), [preferenze](menu51-preferences.png).
