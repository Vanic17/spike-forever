# Spike Forever 0.61.0

- Fischio reale dell'arbitro prima di ogni servizio e a fine azione, per entrambe le squadre. Una pausa non ripete l'autorizzazione al servizio. Resta valido il comando L3 per disattivare l'audio.
- Corrimano continuo sul lato campo del seggiolone, alla quota delle mani della posa di riposo dell'arbitro.
- Sei riserve sedute e un allenatore in piedi per squadra: divise della squadra selezionata, riserve del roster ove disponibili, movimenti del capo, piccoli aggiustamenti e gesti sfalsati dopo i punti della propria squadra. Allenatori con abbigliamento scuro.
- Animazione delle panchine separata dal gameplay: nessuna IA tattica, IK o AnimationTree aggiuntiva. Aggiornamenti visivi limitati a 20 Hz e sospesi in pausa; identità controllate una volta al secondo.
- La CPU non recupera più in copertura un monster block classificato come muro pieno. La palla continua la traiettoria fisica fino a terra: il punto non viene assegnato artificialmente prima del contatto col pavimento. Tocchi morbidi, ricicli e mani fuori mantengono le loro possibilità di recupero. La difesa comandata dal giocatore e le partite online tra due umani non vengono escluse.

Verifiche: riserve e allenatori, divise, gesti e pausa; fischio reale senza duplicati; contatti fisici a muro con entrambi i sistemi di animazione a 60/120 Hz; 35 lezioni tutorial; accesso al secondo tocco. Anteprime: `arena61-bench.png` e `arena61-referee.png`.

Aggiornamento completo Windows e sorgenti. Dati personali, impostazioni e progressi tutorial restano locali. Online: entrambi i client alla 0.61.0, protocollo SF061.
