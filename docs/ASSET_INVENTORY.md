# Inventario asset locale — prima build

Questo inventario descrive la prima build. Le successive importazioni di texture, ambiente, pubblico, scarpe, occhi, capelli e audio sono documentate in `REVISION_02.md` e nel README aggiornato.

Fonte: `C:\Program Files (x86)\Steam\steamapps\common\Spike Volleyball\ProVolley\Content\Paks\ProVolley-WindowsNoEditor.pak` (5.370.960.114 byte).

UE Viewer ha letto 40.405 voci nel PAK v4. Esportazione dei pacchetti `CharactersV1/Animations/*` con compatibilità UE4.19: 2.698 oggetti esportati riportati dallo strumento, **2.696 file PSA effettivamente presenti**. Il valore UE4.19 è il profilo di compatibilità usato con successo, non una certificazione della versione esatta dell'editor originale.

| Uso nel nuovo gioco | Risorsa originale |
|---|---|
| Attesa difensiva | WAIT_OPP_SERVE/WS_Idle_HSR_Loop_HSR_01 |
| Corsa | WAIT_OPP_SERVE/STD_Move_Run_L_S4 |
| Ricezione | PASS/PASS_2H_FrontCenter_Distance0_FromHalfSquat_NoRecoil |
| Alzata normale | SET/SET_Jumped_R_Long_Front_slow |
| Alzata veloce | SET/SET_Jumped_R_Short_Front_quick |
| Attacco | SPIKE/SPK_OutsideRight_After_RunLRL_Center |
| Muro | BLOCK/BLK_Static_Front_midArm_HS |
| Servizio jump float | PLAYER_TO_SERVE/Serve_Action_FloatingJumped_3 |
| Servizio jump power | PLAYER_TO_SERVE/Serve_Action_SmashJumped_3 |
| Attesa servizio | PLAYER_TO_SERVE/Serve_Move_2H_Idle_01 |
| Corpo e scheletro di riferimento | 01_Character_BodyParts/02_Bodies/SK_Char_Body_M_Full |
| Testa | 01_Character_BodyParts/01_Heads/SK_Char_Head_Caucasian_M_02 |
| Divisa generica | 02_Character_Cloth/MyTeam_customCloth/SK_Char_Cloth_Custom_M |

Animazioni in PSA; mesh, skinning e scheletro in PSK. I materiali del prototipo sono nuovi e a tinta unita. Non sono state estratte texture, musiche, voci, pubblico o ambienti originali. Campo, tribune, HUD e suoni sintetici sono generati dal codice del progetto.

Riutilizzo autorizzato dall'utente con la dichiarazione «Ho i diritti». Non è stata eseguita una verifica indipendente dei contratti. Nessuna pubblicazione o distribuzione è stata effettuata. I file sorgenti con gli asset estratti sono esclusi da Git.

I log completi, l'elenco CSV e i nomi originali in `assets/active/sources.json` consentono di verificare quali dati sono stati effettivamente estratti; la presenza nell'archivio non implica che tutti i 2.696 movimenti siano già collegati al gameplay.
