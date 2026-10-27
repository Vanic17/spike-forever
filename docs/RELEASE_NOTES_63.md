# Spike Forever 0.63.0

- Aggiunta Difesa ai 169 giocatori: 111 con osservazioni ufficiali SuperLega/VNL, 58 stimati con confidenza dichiarata. Tutti i valori sono stime editoriali modificabili, non voti ufficiali.
- Scheda giocatore con radar esagonale e Difesa modificabile tramite controller; modifiche locali conservate negli aggiornamenti, compresi i salvataggi precedenti.
- Scelta **Valori giocatori: Disattivati · originale / Attivi · database V1** nella preparazione offline e nella stanza online. Online decide l'host, la scelta vale per entrambe le squadre. Richiesta la stessa versione, protocollo SF063.
- V1: Ricezione/Difesa influenzano il controllo dopo contatto valido; Alzata produce tre qualità reali; Schiacciata modifica la velocità della barra e la qualità dell'alzata ne determina il verde; Battuta modifica velocità e finestra; Muro modifica la risposta dei contatti validi. Nessun punto automatico nella fascia verde V1.
- Barra attacco V1 sincronizzata al rilascio effettivo dell'alzata, con gestione distinta del primo tempo e previsione condivisa per l'ospite.
- Modalità originale preservata e confrontata byte per byte con la 0.62 su sequenze riproducibili con demo e comandi manuali. Tutorial conserva il gameplay originale.

[Analisi, formule, fonti, decisioni e verifiche](PLAYER_STATS_63.md). I parametri V1 sono centralizzati e regolabili senza modificare il percorso originale.
