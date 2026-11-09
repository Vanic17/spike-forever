# Potenza del centrale e alzata a una mano

## Cause riscontrate

Il primo tempo/7 condivideva la stessa durata di base degli altri attacchi: una traiettoria di pochi metri impiegava quasi lo stesso tempo di una lunga, quindi aveva velocità minore. Il contatto centrale veniva inoltre pianificato a circa un metro dal nastro anche con palla buona. La correzione automatica per superare la rete finiva per rallentare i colpi corti.

La variante a una mano era presente ma aveva una differenza visiva limitata dalla posa base a due mani. L'estrazione richiedeva anche che il vecchio marcatore a due mani fosse entro 0,85 m dal nastro: il contatto alto della mano singola avviene prima sulla stessa traiettoria, quindi quel controllo non descriveva la posizione del gesto effettivo. Il punto di contatto era ereditato dall'animazione a due mani.

## Intervento

`middle_delivery102.gd` applica soltanto agli attacchi veri dei centrali, con `destination==1`, una curva continua `smoothstep(0.78,1.0,potenza)`. Diminuisce il tempo di volo richiesto del 20% al massimo e di un ulteriore 10% per mira bassa o laterale. La verifica geometrica del nastro impone il minimo fisicamente consentito: non cambia gravità, spin o integratore, non garantisce una traiettoria impossibile e non cambia il bersaglio scelto. Le cariche basse, i pallonetti e i terzi tocchi in bagher non ricevono il bonus.

Il punto ideale del contatto centrale è più vicino alla rete solo su ricezioni buone e in sistema. Allontanandosi l'alzata, torna progressivamente al comportamento precedente. Le stesse rotazioni, preparazioni anticipate, rincorse e verifiche dei corridoi continuano a governare il movimento; il punto del giocatore già in salto resta prioritario.

`first_set102.gd` seleziona la variante solo per primo tempo normale, S effettivo, ricezione >0,95 e traiettoria/tempo realmente raggiungibili. Si calcola l'intercetto alla quota della mano singola, con limite vicino alla rete, senza rilanciare o spostare la palla. Estrazione una sola volta per prima palla, probabilità 25%; nessun nuovo tentativo ripetendo una lettura. In condizioni incompatibili resta il palleggio ordinario.

Dopo un contatto riuscito con una mano, il contatore della squadra vale 3. Le tre alzate normali di primo tempo successive lo portano a 2, 1, 0; callback duplicati non lo riducono due volte. Altri attacchi, 7, colpi di seconda o palle mancate non lo consumano. Il quarto primo tempo può nuovamente estrarre il 25%, non è obbligatoriamente a una mano. Per questo la frequenza complessiva su una lunga sequenza è inferiore al 25%. Stato indipendente fra squadre, conservato fra set/sostituzioni e azzerato alla configurazione della nuova partita. Esportazione/importazione del match e snapshot online includono il contatore.

Il gesto `set_first96` usa un piccolo stacco visivo, braccio attivo disteso e mano libera abbassata/aperta, con transizioni della libreria esistente. Il contatto è 13 cm sopra il giunto del polso, sulle dita; offset, IK e validazione usano lo stesso riferimento anche per mancini. Il root orizzontale è ancora gestito dal gameplay. La firma della libreria include anche gli offset di contatto, e `native_motion96.res` è stata rigenerata per evitare conversioni durante il gioco.

## Verifica

- `Test-Middle102.gd`: 229 controlli, carica crescente senza rallentamenti, bersagli invariati, passaggio sopra la rete con spin reale, cariche basse inalterate, intervallo di tre primi tempi, isolamento della 7, 237 estrazioni su 1.000 idonee senza intervallo attivo, mani/offset per destri e mancini, firma della libreria nativa.
- `Audit-Middle102.gd`: ricezione, alzata e attacco completati per primo tempo e 7 in tutte le sei rotazioni.
- `Run-OnlineMiddle102.ps1`: due client ENet, cinque comandi del guest, sequenza a una mano/normale/normale/normale/a una mano; pose e contatore sincronizzati.
- Regressioni sui colpi e sulle ricezioni perfette. Fallback PSA mantenuto.
- Anteprima nativa: `middle102-onehand.mp4`, fotogramma di contatto `middle102-onehand-contact.png`.

I video di riferimento sono stati analizzati localmente e non fanno parte del pacchetto. Nessuna modifica al database dei giocatori.
