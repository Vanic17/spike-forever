# Review 103 / 0.97.0

## Attack speed
The existing short-attack branch used 0.90 of the requested flight time. Merely changing that multiplier to 0.85 produced no measurable speed increase on the native fixtures: its analytic net guard erased the change. The new short_attack103 solver requests up to 5.56% less actual flight time (approximately 5.88% higher speed at equal distance) with stronger downward topspin, and verifies the crossing using the existing physical integrator. If necessary it tries half the boost; otherwise it retains the original trajectory. Net height, contact point, aim target, gravity and collision logic are unchanged. This affects downward hard attacks only, not tips/free balls, timing-bar speed or general serve speed. Central 102 boosts and perfect-shot scoring are retained. Planning runs once per hit, not every rendered frame.

## P1
The previous P1 layout intentionally kept OPP on the left pin for both service reception and own service. Only the own-service case with the actual setter serving now reverses the two front pin positions. The rally lane identity, attack recipient and defense anchors agree. Receiving P1, all other rotation tables and the double-substitution role mapping retain their existing behavior.

## Hand research and one-time correction
`review103-hands-research.json` records 169 individual Volleybox profile URLs and explicit Right/Left fields; missing fields are null. English and Italian profiles were checked. Aliases in Prepare-Review103.py reconcile full names/diacritics. No missing value is inferred from role, nationality or a default. `review103-hands-summary.json` lists unresolved names. These values remain unchanged.

Only verified `dominant_hand` facts are inserted into the shipped league.json. All other fields are compared structurally against the previous database before writing. Because the updater protects an existing league.json, `dominant_hand103.gd` performs the authorized narrow correction via user roster overrides once, at first launch. It saves the exact old override file as `roster-overrides.before-hand103.json`, then writes a separate applied marker. It does not open career, championship, legend or condition match ledgers. Once applied, subsequent personal dominant-hand changes win.

## Setter form
The original distributed defaults already contained A/B/C/D setters, but 12/24 had insufficient Italian observations. International setters were often neutral C by fallback, and the earlier method measured serve/block regularity rather than setting directly. The review supplements those defaults with documented season/multi-season continuity (Rowan, Giannelli, Christenson) and international setting evidence (Nikolov). These A–D assignments are editorial estimates of consistency, not measured physical fitness or a function of overall. Sources/confidence are in setter_forms103.json. Unchanged players retain prior researched classifications or neutral fallback when evidence is insufficient. Explicit user choices and already-drawn match arrows are preserved.

## Coach outfit
A cached four-surface garment is skinned to the existing staff skeleton: fitted jacket, continuous shirt inset, collar/lapels, full sleeves/cuffs and trousers. Original short-sleeve faces are suppressed; head, hands, gestures and animation ownership remain unchanged. Two cached meshes, no per-frame mesh generation or file reads.

## Validation
- review103-tests.json: 276 checks, including a malformed personal DB, exact pre-migration backup, subsequent hand edits, form overrides, both sides/all rotations, outfit skinning and physical short-hit clearance. Maximum measured added shot-planning cost: 145 microseconds in this run (not a universal hardware benchmark).
- review103-live.json: 12 native receive/set/attack sequences, two pins across six rotations after own service. P1 uses OH at Z4 and OPP at Z2.
- review103-speed-comparison.json: same native fixture on the published 0.96.0 source and current source; all 12 downward attacks approximately 5.8% faster, with identical intended landing zones. The only recipient differences are the two intended P1 cases.
- MIDDLE102: 229 checks, including the 25% one-hand selection and three-first-tempo cooldown; actual central/7 contacts succeed across all six rotations.
- Two ENet clients: ONLINE102 BOTH CLIENTS PASS on the new protocol.
- MATCH100: 186 checks pass, including set continuation and final report handling.
- review103-preservation.json: 216 existing personal files unchanged during development; structural DB comparison confirms that only dominant_hand was changed.
- Legacy Test-DoubleTactics74: the same five career-end fixture assertions fail on both the published 0.96.0 baseline and current source; all tactical/role/49 native set-contact checks behave identically. The fixture predates the Match Center. Test-DoubleChange74's old TestGame mock also lacks form99, introduced later. These obsolete fixtures were not treated as evidence of a product regression or silently reported as passing.
