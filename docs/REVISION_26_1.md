# Versione 0.26.1 — camminata che sembrava una caduta

Analizzato il video 2026-10-23 09-56-59. La nuova variante `walk_v26_01` (`STD_Move_Walk_R_S2.psa`) non mantiene una postura di camminata in tutto il ciclo: nel campionamento normalizzato la testa scende a 0,567 m e le anche a 0,609 m. La selezione stabile per atleta la assegnava agli indici dispari, perciò il difetto ricompariva durante gli aggiustamenti di metà squadra.

La variante è ora in quarantena: resta archiviata e convertita ma nessun atleta la seleziona. Tutti usano la camminata originale collaudata. Le altre varianti e i veri tuffi restano disponibili. Totale 127 risorse, 126 selezionabili. Non sono modificati velocità dei giocatori, collisioni, regole, timing, comandi, palla o tattiche.

Il nuovo `Test-Standing27.gd` campiona 61 istanti per ciascuna delle nuove animazioni senza palla: testa e anche devono mantenere altezze da postura eretta/accosciata, eccetto la fonte esplicitamente esclusa. Verifica inoltre che nessuno dei 12 atleti usi quella camminata. Il test del catalogo verifica esplicitamente la quarantena, continuando a verificare contatti, IK, transizioni, sorgenti e backend delle altre prestazioni.
