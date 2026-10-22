# Revisione 17 — introduzione progressiva di AnimationTree

## Analisi del sistema esistente

Godot 4.5.1, scheletro di 145 ossa. Il parser ActorX legge nomi, keyframe locali e frequenza effettiva da ANIMINFO; i clip non hanno tutti lo stesso frame rate. La gerarchia viene ripristinata dal PSK perché questi PSA UE4 non la riportano correttamente. Le rotazioni dei figli sono coniugate durante la lettura.

Il campionamento precedente interpola posizione e quaternion locali, ricostruisce le pose globali, converte centimetri/assi ActorX in metri/assi Godot e sottrae lo spostamento orizzontale della root. Rimangono oscillazione del bacino e movimento verticale. Il nodo giocatore viene mosso esclusivamente dalla logica esistente.

Il blending esistente lavora già in spazio locale per non accorciare gli arti. Conserva la posa visualizzata quando una transizione viene interrotta, continua il clip uscente e compensa i cicli di locomozione. La ricezione può già mantenere un passo sotto il busto: la compensazione del bacino è necessaria per non far affondare gambe distese sotto un busto accovacciato.

Quindi introdurre AnimationTree da solo non elimina automaticamente la rigidità. Questa fase sostituisce la valutazione e il blending dei soli clip scelti, mantiene i vincoli esistenti e introduce gradualmente una curva più dolce nelle transizioni di attesa e passi laterali. Le durate delle transizioni e i tempi dei contatti restano quelli precedenti.

## Implementazione

- `src/psa_animation_library.gd`: conversione in tracce native POSITION_3D e ROTATION_3D, mantenendo i keyframe e il frame rate di ciascun PSA. Nessuna traccia di scala, nodo giocatore, input o evento di gameplay. Metadata di provenienza e contatto conservati.
- Nove clip: idle, ready, relaxed, shuffle_left, shuffle_right, receive, receive_follow, receive_left_up, receive_right_up. Le altre animazioni vengono ancora campionate dai PSA.
- `src/pose_animation_tree.gd`: AnimationPlayer come contenitore e AnimationTree in aggiornamento manuale. Due nodi Animation, due TimeSeek e Blend2; il clock rimane quello di Avatar. Le pose già compensate del blending interrotto entrano tramite due buffer Animation di posa, senza convertire gli altri clip.
- Il filtro per ossa include bacino e discendenti delle due cosce. La ricezione conserva braccia e busto e riceve il movimento degli appoggi, con la compensazione del bacino precedente.
- Il mixer 4.5 accumula le rotazioni rispetto alla posa di riferimento. Interpolare direttamente due pose assolute produceva differenze importanti: i buffer usano delta locali rispetto alla posa uscente, poi ripristinano tale riferimento. Questo conserva lo slerp precedente.
- La curva visiva combina smoothstep precedente e 35% di curva quintica soltanto per il busto nelle transizioni di attesa e passi laterali. Un secondo filtro comprende Spine e discendenti, escludendo bacino e gambe: gli appoggi conservano la curva precedente. Il contributo viene sfumato in circa 120 ms quando si cambia modalità. Le ricezioni conservano la curva precedente.

## Proprietà delle pose e fallback

AnimationTree scrive soltanto su un `Skeleton3D` privato di valutazione, senza mesh. Non è collegato allo scheletro visibile. La sua uscita torna alla pipeline di Avatar; appoggio dei piedi, inclinazione del corpo, testa e IK di contatto vengono applicati dopo. Il ciclo finale già esistente rimane l'unico scrittore dello scheletro visibile. AnimationPlayer non viene messo in riproduzione autonoma.

Il parser PSA e la normalizzazione originale restano integri. Una verifica iniziale di gerarchia e campionamento impedisce di attivare il backend nativo se non è compatibile. I clip non convertiti usano automaticamente il parser originale.

F6 alterna i due sistemi senza azzerare clip, fase, clock o azione. Per partire interamente dal sistema originale aggiungere `-- --psa-original` agli argomenti di Godot. Il fallback non dipende dal file nativo esportato.

## Conversione riproducibile

La libreria viene costruita una sola volta in memoria per processo e condivisa dai giocatori. Ogni giocatore ha invece mixer, filtri e buffer di posa propri. Per esportare la stessa libreria come risorsa nativa ispezionabile:

```powershell
.\tools\godot\Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tools/Convert-PsaAnimations.gd
```

Output: `assets/active/native_stage1.res`. Il test verifica anche salvataggio e rilettura della risorsa. A runtime si costruisce la libreria dai PSA correnti, evitando di caricare un'esportazione obsoleta.

## Verifiche e limiti

`tools/Test-NativeAnimation.gd` confronta entrambi i sistemi a 60 e 120 Hz, tutti i nove clip a tempi fra i keyframe, fine clip e wrapping; verifica filtri, contatti delle quattro ricezioni, cambi di modalità, trasformazione del giocatore e supporto dei piedi. Report riproducibile in `docs/native-animation-report.json`.

Il campionamento convertito differisce dall'originale meno di 0,000001 m; il blending relativo meno di 0,000001 m. Il confronto delle rotazioni ha una tolleranza di 0,002 radianti, anche per l'arrotondamento dei quaternion. L'addolcimento del busto modifica le pose finali fino a circa 9,2 mm nella sequenza di stress; il cambio di modalità a tempo fermo differisce meno di 0,000001 m. Il test distingue l'addolcimento intenzionale dalla fedeltà della conversione.

Il sistema precedente consente già uno scostamento temporaneo del piede dall'ancora perché la correzione è limitata e sfumata. Nella sequenza di stress il massimo è circa 11,8 cm in entrambi i sistemi, con differenza inferiore a 0,001 mm. Una prima curva applicata anche alle gambe aumentava questo valore: è stata scartata in favore del filtro sul busto. Il test impone che il nuovo sistema non aumenti lo scostamento oltre 1 mm. Questo non dimostra assenza assoluta di foot sliding preesistente; verifica che la migrazione non lo aumenti e conserva il rilascio dell'ancora a 22 cm.

Lo scheletro di valutazione aggiunge costo CPU. Nella prova automatica la pipeline nativa usa circa 1,5 volte il tempo della pipeline PSA per le pose testate; non è un'ottimizzazione delle prestazioni. I valori misurati sono nel report e dipendono dalla macchina.

Confronto renderizzato: `docs/native-comparison.mp4`, AnimationTree a sinistra, PSA a destra; fotogrammi `native-comparison-0.png` fino a `native-comparison-3.png`. Il confronto isola la resa delle animazioni e non rappresenta uno scambio completo.

La suite completa continua a verificare partita, fisica, contatti, posizionamento, rotazioni, muro, controlli e movimenti. `Check-NativeAnimationScope.ps1` protegge i sorgenti estranei alla migrazione, il parser, la normalizzazione originale e il blocco delle correzioni procedurali. Il precedente controllo di ambito v16 resta disponibile per quella revisione; la suite corrente usa il controllo aggiornato.

Esito finale: suite completa PASS (`docs/native-final-verification.log`), 976 verifiche dedicate PASS, 128 controlli di ambito PASS. La simulazione principale completa 16 punti e 122 contatti, con distanza massima mano-palla 0,1064 m; la simulazione dei recuperi completa 16 punti e 59 contatti, massimo 0,1450 m. Passa anche la prova anatomica avviata esplicitamente con `--psa-original`. Il convertitore autonomo termina con `PSA CONVERSION PASS`. Il video finale è stato decodificato interamente senza errori.

Nessuna estensione ad alzata, attacco, battuta, muro o tuffi in questa fase.

Riferimenti API: [AnimationTree 4.5](https://docs.godotengine.org/en/4.5/classes/class_animationtree.html), [Blend2](https://docs.godotengine.org/en/4.5/classes/class_animationnodeblend2.html), [TimeSeek](https://docs.godotengine.org/en/4.5/classes/class_animationnodetimeseek.html), [rotazioni del mixer 4.5](https://github.com/godotengine/godot/blob/4.5/scene/animation/animation_mixer.cpp).
