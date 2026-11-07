# Stature, equipment and cameras — 0.90.0

## Official height evidence

All 169 athletes in `assets/gameplay/league.json` have `height_cm` and per-player `height_metadata`. Sources are the official Lega Volley team roster pages (height column). `player-heights90-sources.json` records the athlete ID, source URL, exact roster row and downloaded page SHA256. Athlete IDs take priority over normalized names; historical statistics tables are excluded.

`tools/Fetch-Heights90.py` collects evidence without changing the database. `tools/Apply-Heights90.py` performs the explicitly authorized, one-time height migration and asserts that every other database field remains identical. No player ratings are estimated or changed. Existing local edits take precedence; old saved rosters without the new field use a read-only height catalogue by canonical database ID. Custom/created players default to the source model stature until edited.

## Rig and contact consistency

The source model's bind-pose crown is 1.894563m above ground. A uniform `Stature90` presentation parent scales the skeleton, clothing, head and all accessories together. Actor roots, movement velocity, animation clocks and rotation order stay unchanged. World contact offsets and joint sampling use the same factor; IK transforms through the scaled frame. The presentation interpolation offset is divided by that factor to retain the exact interpolated world position. Sideline AnimationPlayer tracks resolve relative to the presentation parent.

The stature difference changes physical hand placement naturally; it does not add a speed bonus or alter a timing window. Walking/running playback compensates for the scaled stride length, without changing movement speed or contact clocks. The serve's initial hand transfer is converted back to bind-space units. This is proportional scaling, not a new anatomical rig for each player.

## Equipment

Weighted cloth shells are clipped from the existing body mesh in bind space, including interpolated skin weights at straight hems. Normal offsets and a raised knee front form fitted socks, sleeves and padded knees. The geometry is baked, shared and skinned by the original rig; there is no per-frame mesh generation or file loading. Three sock lengths, short pads, long sleeves and asymmetric combinations are deterministic per athlete. All liberos receive knee protection. Four shoe silhouettes preserve the source skin weights and UVs while varying forefoot width, toe length, heel cushioning and collar profile. Palettes are stable per athlete, including the bench. Existing graphics presets remain effective.

Camera IDs and cycling remain 0 → 2 → 3 → 0. Profiles 0 and 3 are exchanged, including their serve framing and field of view. Side camera mappings and online mirrored orientation are unchanged.

## Save and update boundaries

Only packaged base data and game code are updated. `user://roster-overrides.json`, career slots and settings are never packaged. Height edits are saved through the existing atomic local override mechanism. Network roster sanitization carries height separately for each team and the protocol is SF090 to prevent incompatible peers.
