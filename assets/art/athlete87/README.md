# Single athlete review assets

Local prototype; no publication. Source meshes and maps under `source` were extracted from the user's installed Spike Volleyball archive, as authorized in the conversation. The face source is Tier1 M Perrin; source rig is rebound by name to the game's existing 115-bone skeleton. No face likeness claim is made for the roster identity used in the comparison.

Authored offline: anatomical adjustments, eyelid aperture, fitted scalp shell, curved opaque hair/beard fibers, hand relief, nail surfaces and localized garment folds. Build: `tools/Build-Athlete87.gd`, deterministic seed 87019. Shoe albedo `shoe02_87.png` derives from the extracted model02 panel mask; normal and AORM maps belong to that model.

Source facial base 1024px and normal 2048px remain their native resolution. This is not a new photogrammetric head or a full modern anatomical body. Models, image captures and benchmark measurements are documented in `docs/ATHLETE_PROTOTYPE_87.md`.

Opt in with `--athlete-prototype87`. Only player slot0 receives the new head/body/garment/groom. Other players retain their geometry, with independent footwear colors/textures in the preview. Do not propagate this prototype to every athlete before visual approval.
