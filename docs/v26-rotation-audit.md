# Rotation and central reception audit, revision 26

The supplied screenshot is consistent with R2, rotation index 1: OPP and MB1
are regulatory front-row players, OH2 is the third front-row player receiving
on the left, and S penetrates from back-row Z6. S standing near the net after
service does not turn S into a front-row player. R5 had the same spatial defect
with a different middle replaced by L.

## Concrete defect

R2 and R5 previously placed three receivers at left (-2.8, 5.0), another left
(-2.6, 6.8), and right (3.0, 6.4), in metres measured from the net. OH and L
therefore stacked at almost the same lateral coordinate, leaving no central
receiver. These layouts passed position-fault tests because legal overlap alone
does not establish useful tactical coverage.

Moving only the libero to (0.0, 6.3) gives three distinct passing lanes while
retaining every player's rotation identity. R2 back-row order is L x0 < S x1.2
< OH1 x3.0; R5 is L x0 < OPP x0.6 < OH2 x3.0. The corresponding front/back
relations remain legal, including OH at depth 5.0 in front of L at 6.3.

For nine central-seam sample positions x=-0.75/0/0.75 and depth=4.5/5.0/5.5,
the worst distance to a qualified receiver in R2/R5 falls from 2.9458m to 1.95m.
The worst across all six corrected rotations is 2.2299m in R3/R6.

## Related phases checked

| Phase | Existing responsibilities retained |
| --- | --- |
| Own service | Actual Z1 server outside court; remaining players keep defensive role bases. |
| Opponent service | OH1, OH2 and L occupy three separated passing lanes; all grounded-foot overlap checks apply. |
| Reception flight | S penetrates to the setting target; nonreceiving front attackers open into approach lanes; nonreceiving L keeps the central passing seam in corrected R2/R5. |
| Set construction | Attack identity comes from regulatory row and committed rally flank, not from whoever happens to stand nearest the requested pin. |
| Own attack | Other players enter existing hitter-relative coverage rings. |
| Opponent attack | Only the three regulatory front-row identities join the wall. S penetrating from the back row remains ineligible. |
| Defensive base | L, back OH and S/back OPP already have distinct left, centre and right floor responsibilities; no equivalent left-left-right base duplication was found. |

## Verification

`tools/Test-RotationCoverage.gd` adds independent acceptance criteria for useful
reception geometry: three qualified identities; left/centre/right coverage;
minimum lateral separation; bounded distance to the central seam; legal
grounded shoes with PSA and AnimationTree; and unchanged attack/block rights.

The test also launches 24 real jump/float serves through `serve_ball`, receiver
selection, movement, ball flight and hand validation for every rotation and
both serving teams. All 24 reach SET/CPU_SET with valid serve and reception
hand contacts. Runtime assertions check that nonreceiving L remains central
during R2/R5 service flight.

Result: 755 checks passed. Machine-readable results are in
`docs/v26-rotation-coverage.json`.
