# VOLLEYBALL — Gameplay specification for Codex

> **Status:** design specification / implementation brief. This document describes the intended game; it does **not** claim these systems are already implemented.

## 0. Objective and working rules

Build an **indoor 6v6 volleyball game for Windows PC**, playable with keyboard/mouse and Xbox/PlayStation-compatible controllers. Aim for believable volleyball, responsive controls, readable feedback, and tactical depth without requiring impossible reaction times. Preserve the existing game/project if one is supplied: **inspect the repository and engine first**, then implement incrementally rather than rebuilding or changing engines without approval.

**Codex workflow:** (1) inspect repository and assets, (2) summarize what already exists and any blockers, (3) implement a vertical slice with placeholder animations if necessary, (4) run available checks and report results, (5) continue in small verifiable milestones. Never claim an asset has been imported, tested, or extracted unless that actually occurred.

## 1. Animation sources and asset pipeline

- **Primary animation reference/source:** *Spike Volleyball*.
- **Secondary animation reference/source:** *Volleyball Unbound*, especially block hand movement/penetration and any useful additional volleyball transitions.
- The project owner states they hold rights for both. **Before extraction/reuse**, confirm the precise scope of those rights, compatible formats, and any restrictions on redistribution; ownership of game copies alone is not a reuse license.
- Inspect the actual local installations or user-supplied exports only when accessible. **Do not assume** animations are already present or invent filenames. Do not bypass DRM, encryption, or access controls.
- Make an animation inventory: serve, serve toss, float/jump serve, ready stance, shuffle, run, reception, diving, set (front/back/quick/pipe), approach, jump, spike, tip, block, hand deflection, landing, transitions.
- Retarget to a consistent skeleton. Define animation states and blends; match animation events to ball contact. If extraction/retargeting is blocked, use original placeholder animations and record the blocker.
- Keep third-party licensed assets outside publicly distributed source packages unless distribution is expressly permitted. Keep an attribution/licensing inventory.

## 2. Core philosophy and state machine

**Six players per side** with positions, rotations, legal touch count and basic volleyball rules. Team AI handles off-ball movement. User controls context-sensitive actions. State machine:

`PRE_SERVE -> SERVE_TOSS -> SERVE_CONTACT -> RECEPTION -> SET -> ATTACK -> BLOCK/DEFENSE -> RALLY_CONTINUES or POINT_END`

States may transition through free-ball and emergency-save cases. The ball must be a shared physics/gameplay authority, not moved arbitrarily by unrelated animations. Preserve one consistent scoring and possession system.

- **Approach and attack jump are automatic.** The controlled attacker positions and aims; the game schedules approach/takeoff based on set trajectory, player location and animation timings.
- **Reception movement is semi-automatic.** Player auto-tracks a reachable serve while the left stick/WASD can correct positioning.
- **Blocking movement is assisted, but block jump is manual.** Block hand orientation is adjustable in the air.
- Do not make any action guaranteed: positioning, timing, ball trajectory and eventual player attributes matter.

## 3. Controller mapping (UPDATED — contextual X action)

**X is the primary contextual action** for reception, setting, serving and attacking; **X also triggers the manual block jump when in blocking context**. On Xbox controllers this is **X / Square on PlayStation**. Do not confuse the label X with PlayStation Cross (Xbox A). Use action identifiers and remappable bindings rather than hardcoding buttons. Context comes from the possession/animation state, and on-screen help must display the current meaning of X.

| Context | Input | Effect |
|---|---|---|
| All phases | Left stick | Semi-assisted player movement / manual corrections |
| Reception | X / Square | Stop timing indicator and receive |
| Set | Right stick 4-way + X / Square | Choose destination and time the set |
| Set | Hold LB / L1 + X / Square | Fast set with harder timing minigame |
| Attack | Right stick 8-way | Choose attack direction |
| Attack | Hold/release X / Square | Charge attack power and register timing; timing UI must remain compatible with charge |
| Block, opponent setting | Right stick left/up/right | Select predicted destination while arrow cue is visible |
| Block | X / Square | Manually time and execute block jump |
| Block, airborne | Right stick | Move/orient hands laterally |
| Serve | Right stick 8-way | Aim serve |
| Serve | X / Square | Trigger contextual serve action and timing/power bar |
| Serve | Secondary serve-type selector (rebindable; provisional) | Select jump float versus jump power; exact button still TBD |

**Important:** For serving, retain two serve types but do not invent a second finalized button. For attack, design a non-conflicting input timeline for charge (hold/release X) and oscillating contact timing (e.g. use release to lock both power and timing). Prototype and test responsiveness. Never require the player to press X twice at the same instant. The same X button must never trigger two actions in one state.

## 4. Reception: semi-automatic movement and timing

1. On serve contact, select the most appropriate receiver automatically based on predicted intercept and role; AI positions other receivers.
2. The selected player moves toward the expected interception zone automatically, limited by realistic movement speed, acceleration, and reach. Left stick corrects the route.
3. User presses **X/Square** to receive. The optimal timing is derived from the ball's arrival at the contact volume, not from a fixed delay.
4. **Default reception target is the central setter area just under the net on the player's own side**, at a legal and safe offset from the net. No manual aim is required for an ordinary reception.
5. Timing error increases dispersion from that target. A perfect receive produces a highly accurate pass; an early/late receive may become inaccurate, difficult to set, or an outright error.
6. A badly positioned player or unreachable serve must not be rescued magically. Choose context-appropriate reception, reach, or dive animations.

Suggested tunable formula (prototype, not fixed balance):

`timing_error = abs(input_time - ideal_contact_time)`

`quality = clamp(1 - timing_error / timing_window - positioning_penalty, 0, 1)`

`target_dispersion = lerp(max_dispersion, min_dispersion, quality)`

Sample an offset within the dispersion radius with a deterministic seeded random source for reproducible tests. **Perfect timing should aim precisely at the setter target**, while actual precision can later be modified by player attributes. Display concise timing feedback (Perfect / Good / Late / Early / Miss).

## 5. Setting: four directions and L1 fast modifier

Set target is chosen by the **four cardinal directions** relative to the attacking team, regardless of camera orientation:

| Direction | Destination |
|---|---|
| Left | Zone 4 / outside hitter |
| Up | Zone 3 / middle attacker |
| Down | Pipe / back-row attack from zone 6 |
| Right | Zone 2 / opposite |

Hold **L1/LB** while giving the set input to select a **faster/lower set** for the same destination. Normal set is higher/safer; fast set has tighter timing, higher demands on reception and setter position, and more potential to beat the block. A pipe remains a legal back-row attack (takeoff behind 3-meter line). If a requested play is impossible, fall back to an explicitly communicated emergency/high set or fail naturally—do not teleport the ball.

Set destination should be visually confirmed with a brief, non-intrusive indicator. Ball release/contact must align with setter animation. Set selection should remain responsive even when the ball is fast.

## 6. Attack: eight directions, power vs accuracy

- **Approach and jump automatic** based on ball trajectory and player position. User chooses **8-way direction** with the right stick (N, NE, E, SE, S, SW, W, NW), transformed into **court-relative** directions so camera changes do not invert choices.
- **Hold B/Circle** to charge attack power; release to execute the hit at the applicable contact window. Short press = low power and maximum nominal precision; full charge = maximum power but **70% nominal precision**.
- Baseline accuracy mapping for prototype: `accuracy = 1.0 - 0.30 * normalized_charge`, where charge is clamped from 0 to 1. Therefore minimum charge = 100% and full charge = 70%. Treat this as a **precision rating/aim dispersion multiplier, not a literal 70% chance the ball lands in**. Timing, positioning, block interaction, and future player stats further modify outcomes.
- Higher charge increases ball speed and/or attack aggressiveness. Apply trajectory dispersion that grows with charge; never fake errors by simply ignoring the selected direction.
- Later: player attributes (power, attack precision, technique, jumping, timing) can raise/lower both power and accuracy curves. Build data hooks now; **do not require a complete stats system in the first milestone**.
- Validate attacks from all legal zones, including pipe; enforce net collisions, out-of-bounds, touch and block deflection.

## 7. Block: short directional cue, one or two blockers, manual jump

### 7.1 Prediction and formations (REVISED)

- **Do not implement a three-person block as the default or reward for a correct prediction at this stage.** A successful on-time prediction produces a **two-player block**. A wrong, absent or late prediction produces a **one-player block**, with the middle blocker arriving late (where relevant).
- At the opponent setter's decision/contact moment, show a **brief directional arrow** revealing the AI's committed destination: left = wing zone 4, up = quick middle zone 3, right = opposite zone 2. Make arrow visibility short and configurable, starting around 0.5 s for standard sets.
- The player has to move the **right analog stick** in the matching direction during the cue. The cue is an intentional reaction challenge; do not fake an arrow unrelated to the committed set.
- For a **fast set**, shorten the cue visibility and response window. Parameterize duration separately from the setting timing minigame.
- A correct response triggers assisted lateral travel to create a two-player block if physically reachable. Incorrect/no response leaves a single effective blocker and the middle blocker late. Avoid teleportation; animate lateness and adjust coverage accordingly.
- **Fast middle set, missed prediction:** exactly one blocker attempts the block, **late**. This should be particularly dangerous for the defending team.
- **Exception — normal set with imperfect timing:** when the opponent setter uses a normal set and fails to hit the perfect timing zone, the ball becomes a higher, slower set. The defending team then has time to assemble a **three-player block**. This is the **only planned three-person-block case for now**. Resolve this exception explicitly rather than letting the prediction rule cap it at two.
- If an imperfect set is severely mistimed, also allow realistic trajectory/accuracy errors. An imperfect normal set should tend higher and give the defense more time; do not automatically treat every tiny deviation as identical.
- Pipe/back-row sets: keep a separate documented fallback until the cue scheme explicitly supports the fourth destination.

### 7.2 Manual block execution and hand movement

- Prediction changes **movement/formation only**. Jump is still **manual**, by pressing **X / Square** at the correct moment, using the shared timing indicator.
- While airborne, **right stick** adjusts hand position/orientation (line/diagonal); use compatible *Volleyball Unbound* hand animations where legally and technically feasible.
- A successful prediction is not a guaranteed stuff block. Ball/hand collisions, position, timing and attacker choices decide outcomes. Preserve valid block-touch rules.

## 8. Serve: eight directions and TopSpin-style power bar

Two distinct serve actions/types, interpreted from the brief as:

1. **Jump float serve**: lower speed, less predictable float-like trajectory.
2. **Jump power serve**: faster, more aggressive, potentially higher error risk.

Use **8-way right-stick aim**. Hold the corresponding serve button to charge a visible power meter inspired by the readable risk/reward of **TopSpin 2K25** (do not copy proprietary UI assets).

- Charge **up to the end of the green zone**: maximum valid power.
- Release **before the green limit**: reduced power.
- Continue charging **past the green limit**: serve fault (out/net depending on simulation), with clear visual feedback.
- Ensure the limit is learnable and consistent. Animation toss, jump, contact and bar release must synchronize. The two serves need distinct physics and animations.
- Make charge speed, green-zone threshold, ball speed, float behavior and error tolerance tuneable.

## 8A. UNIVERSAL TIMING MINIGAME (NEW — PRIORITY)

Implement a shared timing widget for **every ball-contact action**: reception, set, attack, serve and manual block jump. Visual reference: **older FIFA penalty timing bars / WWE pin minigame**.

- Show a compact horizontal bar with a **small green perfect-timing zone near its center**. A moving cursor travels **back and forth left ↔ right**; the player presses/releases the contextual action **X / Square** to stop/confirm at the correct moment. Avoid visual clutter and align the timing target with the actual ball-contact animation.
- Center of green zone = perfect; near edge = good; progressively farther away = poorer outcome. Quality must vary **continuously with distance from the target**, not be an arbitrary binary pass/fail. Early/late must matter, including possible complete miss.
- **Reception:** perfect timing sends the ball accurately to the setter target at center near the net; larger timing error means larger directional/height dispersion.
- **Normal set:** perfect timing produces the intended normal set. Imperfect timing increasingly degrades accuracy; importantly, **a non-perfect normal set tends to become a higher/slower ball**, allowing the opponent to organize a **three-player block** (see section 7). Apply sensible tolerances for very small errors.
- **Fast set (L1 held):** the green zone is **narrower** and the oscillating cursor **moves faster** than for a normal set. This makes a quick set difficult but rewarding.
- **Reception → fast set interaction:** a **perfect reception reduces the fast-set timing penalty**, e.g. a wider green zone and/or slower cursor relative to a fast set after an average pass. This mitigation must be meaningful but **must not make a fast set as easy as a normal set by default**. Poor reception makes the fast-set minigame harder and may force a safer set if needed.
- **Attack:** apply timing quality on top of the existing charge-based 100%→70% nominal precision curve; do not replace the power mechanic. A badly timed high-power hit should be especially risky.
- **Serve:** retain the TopSpin-like green power ceiling and overcharge fault risk from section 8; coordinate its bar with the universal contact-timing system so players see one coherent interaction rather than conflicting simultaneous bars. Document the final combined UI/input flow.
- **Block:** X triggers manual jump and timing quality affects whether hands reach the ball correctly; directional prediction determines number/position of blockers, not jump timing.
- Provide `TimingBar` as a reusable component and tunable values per action (`cursorSpeed`, `perfectZoneWidth`, `qualityFalloff`, `perfectPassFastSetMitigation`, `cueDurationNormal`, `cueDurationFast`). Support gamepad and keyboard, colorblind-safe markers and adjustable difficulty.

## 9. AI, physical rules and animation integration

- AI must perform reception, sets, attacks, defensive coverage and blocking using the **same basic gameplay constraints** as the human team.
- AI setter chooses among feasible targets; vary patterns and attack choices. The pre-set prompt reads the **committed** AI choice, not a random direction unrelated to the actual set.
- Implement collision/contact windows tied to animation events; avoid snapping ball to hands or instantly repositioning players.
- Basic rule validation: legal service order/rotations, net, in/out, four hits, double contact (where applicable), back-row attack, block touch, points and rally reset.
- Separate gameplay logic from animation source: swapping an animation must not change scoring or ball physics.
- Keep camera-relative controls translated to consistent court-relative targets, including side switches.

## 10. Suggested architecture (adapt to existing engine)

Use equivalent modules/services in the repository's current language and engine:

- `MatchState` — rally phases, possession, scoring, rotations.
- `BallSimulation` — flight, collisions, touches, predicted intercept.
- `PlayerController` — context-specific human inputs and movement assist.
- `TeamAI` — off-ball coverage, reception selection, set and attack decisions.
- `ReceptionSystem` — contact window, timing quality, target dispersion.
- `SetSystem` — four targets, L1 fast variants, trajectory feasibility.
- `AttackSystem` — 8-way aiming, charge, accuracy, hit windows.
- `BlockSystem` — default formation, cue/prediction, movement, jump, hand adjustment.
- `ServeSystem` — two types, aim, charge, overcharge fault.
- `AnimationBridge` — skeleton retargeting, state transitions, contact events.
- `GameTuning` — editable configuration of all timing, speed and accuracy parameters.

Names are illustrative: match the project's existing naming conventions.

## 11. Implementation order / acceptance criteria

### Milestone 1 — Playable core

- [ ] Load the current project; document engine/version and existing playable systems.
- [ ] One indoor court, 6v6 placeholders, stable rally loop and controller detection.
- [ ] Serve 8-way targeting, two serve types, green-zone charge and overcharge fault.
- [ ] Semi-auto reception with manual correction and timing-dependent pass accuracy to the setter area.
- [ ] Four-direction sets with L1 fast modifier.
- [ ] Auto approach/jump attack, 8-way aim and 100%→70% nominal precision curve.
- [ ] Revised one/two-blocker prediction cue, special triple block on high imperfect normal set, manual X jump and airborne hand movement.
- [ ] End-to-end rally: serve → receive → set → attack → block/dig → point or continuation.

### Milestone 2 — Believability and balance

- [ ] Retarget permitted *Spike Volleyball* animations, then selected *Volleyball Unbound* animations.
- [ ] Blend footwork, takeoff, hand movement, ball contact and landing.
- [ ] Improve AI patterns, defense coverage, float physics and legal edge cases.
- [ ] Add tuning/debug overlay (contact time, pass quality, chosen set, prediction result, charge, precision).
- [ ] Playtest on both keyboard and controller; verify stable 60 FPS target on an agreed reference PC.

### Milestone 3 — Extensibility

- [ ] Data-driven player statistics and ability modifiers.
- [ ] Accessibility and difficulty settings (cue length, aim assist, timing windows).
- [ ] Better camera, audio, menus and game modes, subject to later specification.

## 12. Required test scenarios

1. Perfect vs early/late reception: pass lands progressively farther from setter target.
2. Four set directions all reach the correct role; L1 consistently produces a faster feasible variant.
3. Attack minimum charge yields 100% baseline precision rating; maximum yields 70%; intermediate charge interpolates smoothly; direction remains consistent across camera sides.
4. On a wing attack, no/wrong block prediction produces one effective blocker with late middle; correct timely cue produces two-blocker attempt.
5. On a middle attack, a missed fast middle cue produces one late blocker; correct cue produces a two-blocker attempt.
6. Blockers never jump automatically from prediction alone; manual X/Square jump timing and hand orientation affect collisions.
7. Serve green-limit release = maximum legal charge; early release = slower; overcharge = fault.
8. Float-jump and power-jump serves produce observably different ball flights.
9. CPU can play a complete rally and does not depend on human-only shortcuts.
10. Missing animation assets produce a clear fallback and do not crash the game.

## 13. Open decisions (do not silently assume)

- Exact serve buttons (two separate buttons for jump float vs jump power) and whether the second serve was intended to be **standing float** rather than jump float.
- Confirm combined X press/hold/release timeline for attack power and oscillating contact timing, and for serving.
- Exact cue durations for normal versus fast sets and whether optional harder modes hide the cue.
- Tune travel/arrival times for one-versus-two block; reserve triple block for high, imperfect normal sets.
- Final rule set, match format, camera and multiplayer requirements.

**First Codex response requested:** audit the actual repository and assets, identify the current engine, provide a concrete implementation plan with files to change, flag missing rights/assets/input ambiguities, then implement and test Milestone 1 in small steps. Do not pretend the systems are complete until validated.
