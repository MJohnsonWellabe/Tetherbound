# Hall decisions (PLACES round 10) — Failure A = **A** (root cause + fix), Failure B = **C** (re-site) + one tool bug

## FAILURE A — Hall reads as a black cutout up close → decision **A**

Evidence (all numbers measured on the round-9 960x540 frames with PIL, luma = .299R+.587G+.114B):
- `10-stronghold-gate-day` tower fronts: L median 19 / R median 22 (round 8: 2 / 0). Curtain over arch median 9. Causeway deck 52. Grass 199, sky 159.
- `11-castle-landmark-hall-100m-day` towers median 16–18, curtain 12 (round 8: 0). Highlights (p90 60–110) are moss decals and window slots, not stone.
- So the darken cut 0.74 → 0.48 DID land (0–2 → ~20); it is invisible because both values sit on the ACES toe.
- The material path (`stronghold.gd::_stone_shader_material` → `hall_stone.gdshader` `base = stone.rgb * tint.rgb`):
  - `Color.darkened(0.48)` multiplies **sRGB** channels by 0.52 → in linear light that is **×0.24**. Kit LightRock `#817f78` (lin 0.219) → tint lin **0.055** (66/255 sRGB). Works walls `stone_light #66655e` (lin 0.129) → 0.031. Jambs/coping `_stone_dark()` default `#463f37` (lin 0.055) → 0.013.
  - The tint multiplies `T_UnevenBrick_BaseColor` whose **mean is 123/255 sRGB = 0.202 linear** (measured on the 2048² png). Effective albedo = 0.055 × 0.202 = **0.011** (coal is 0.04, weathered limestone 0.25). No lighting can rescue an albedo of 0.011.
  - No `unshaded`/`ambient_light_disabled`; `fog_disabled` only; `distance_darken` is 1.0 inside 260 m; `variation` ±0.14; `damp` 0.5 over the lowest 8.5 m (×~0.65). None of these is the cause; the sRGB darken on top of a 0.2-mean texture is.
  - Moss `#1f3510` is lin 0.03, i.e. **brighter than the stone base (0.011)** — that is why the judge sees "green blotches on black".
- Sun: `art.json` sun yaw 140 / pitch −44 → `world_look.gd` sets `rotation=(−44°,140°,0)`; −basis.z = light travel (−0.462,−0.695,+0.551); sun sits at (+0.46,+0.70,−0.55) = south-south-east, 44° up. Hall yaw 0, mouth is the −z face → **N·L = 0.55, front-lit**; deck (tilted 16° toward the sun) 0.87; +x faces 0.46; −x/+z faces are shadow (ambient only ≈ 1.9 × 0.9 × #9db3c6 ≈ 0.78 lin vs sun 1.4×0.89×0.55 = 0.69 → shadow ≈ 0.53 × sunlit).
- Arithmetic (Godot ACES, exposure 0.6, white 6): today's front faces at ~20/255 ⇔ pre-tonemap x′≈0.032. Target 60/255 ⇔ x′≈0.103 (×3.2); 28/255 ⇔ x′≈0.044. Lifting tint lin 0.055 → 0.219 (darken 0) is ×4.0 → x′ 0.128 → **~73/255 sunlit, ~42/255 shadowed** for kit stone. Works walls/jambs need their own lift (below) or they stay black beside a lit tower.
- Turning the Hall or adding a fill light is not needed: the façade is already sun-facing; a fill cannot fix albedo 0.011 (×4 at the toe ≈ +15/255).

Instructions (one round, data only, no shader change):
1. `data/config/stronghold.json` `site.weathering.exterior`: `"darken": 0.48` → **`0.0`**; keep `desaturate` 0.5, moss/damp/streak as is. Add to `_why_exterior`: darken is applied in sRGB by `Color.darkened` (0.48 ⇒ ×0.24 linear) on a texture whose mean is 0.2 linear; any value above ~0.15 puts the whole façade under the ACES toe.
2. Same file `site`: `"stone_light": "#66655e"` → **`"#767268"`** (lin 0.178; keeps the T1-HALL-3 ladder: kit LightRock 0.219 / works 0.178 = 1.23×). Add **`"stone_dark": "#5a554d"`** (lin 0.103; today the jambs/coping fall back to the code default `#463f37`). Predicted sunlit medians: kit towers ~73, works walls ~60, DarkRock ~49, jambs ~36; shadowed ~42/34/27/20.
3. Optional guard in `stronghold.gd::_stone_shader_material`: `var darken := clampf(float(ext.get("darken", 0.0)), 0.0, 0.15)` (change the default 0.24 → 0.0 and the clamp 0.95 → 0.15) so the knob can never re-create the toe; comment: "sRGB darken; 0.15 ≈ ×0.7 linear".
4. Do NOT touch `hall_stone.gdshader`, `distance_darken_*`, the sun, or add lights.

Proof (re-render `10-stronghold-gate-day`, `11-castle-landmark-hall-100m-day`, `-400m-day`; same 960x540 boxes as above):
- gate-day L tower (380,150)-(410,230) and R tower (520,150)-(545,230) **median ≥ 55**, curtain (440,190)-(500,215) median ≥ 45; 100m-day L/R tower boxes (440,235)-(465,300)/(500,235)-(520,300) median ≥ 50.
- Towers still darker than grass-right (700,420)-(800,470) median (≈199) by ≥ 60 — silhouette kept; 400m-day hall bbox mean ≤ 0.8 × horizon strip mean.
- Printed sample: a headless walk of `Stronghold`'s `hall_stone` ShaderMaterials prints the kit `LightRock` `tint` uniform with sRGB luminance **≥ 120/255** (today 66) and `exterior_face_stone` ≥ 100/255; judge must name mid-tones/joints/moss-as-darker-than-stone.

## FAILURE B — no sentries at the gate posts → decision **C** (re-site) + tool fix (they are spawned; the eye was shoved off the causeway)

Evidence:
- Sentries are built unconditionally: `stronghold.gd::_build_occupation()` → `_build_gate_sentries()`; `hall_occupation.gate_sentries` has two entries at local (±2, −13.1), y 0 (= `_floor_y` 6.17); `NPC_RANKS.config_for("grunt")` (emission floor 0.18) → `build_from_config`; grunt glb present (7.6 MB); no quest flag, no visibility range, no distance streaming. World positions (site [8,7560], yaw 0): **(6.0, 6.17, 7546.9)** and **(10.0, 6.17, 7546.9)**.
- The stand: `pull_back −24.23` puts the eye at (8, 7531.0) = ON the causeway deck (ramp foot z 7506.8 → top z 7546.8, 11.3 m rise). `_capture_locations.gd::_clear_of_bodies()` then sweeps a capsule (r 0.6, h 2.6) centred at ground+1.3 — its bottom sits exactly on `ApproachRampBody`'s top, `intersect_shape` reports it (only `Terrain` bodies are filtered), and the eye is stepped `aside = (−toward.y, toward.x) = (−1,0)` = **west** by 2, 4, 6 m; at 6 m (world x 2) it is off the 7 m-wide deck (x 4.5–11.5) and lands on the meadow ~9 m below it.
- That reproduces the frame exactly: a camera looking +z has −x on its RIGHT, so the west gate tower (world x −2.6; its sconce at local (−10.6,−12.6) y 6 is the yellow glow at ~(600,120)) projects at 480+480·tan(23.6°)/tan(51.2°) ≈ 648 px — observed 540–700 — and the causeway's west flank (a 4 m-thick slab in `_floor_material`, 0.4 m stones at 1–3 m) fills the left half. Player at his feet is in grass. The jambs, arch and both grunts are behind the raised slab: **in frame? no — occluded**, 18 m away they would have been 51 px tall.
- The `gate` stand (round 8/9) shows the same 2 m westward shove (inner towers centred at 463 px, not 480).

Instructions (one round):
1. `tools/_capture_locations.gd::_clear_of_bodies`: exclude the surface the eye stands on — lift the capsule 0.15 m: `query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.45, candidate.y))` (keep radius 0.6/height 2.6). Comment: a capsule resting on the ramp/floor body it was just ray-seated on is not "occupied". (Alternative: pass the `_surface()` hit collider's RID into `query.exclude`.)
2. Same file, `10-stronghold` shot `gate-face`: `"pull_back": -24.23` → **`-33.1`** (eye at world z 7539.9 = 7.0 m south of the sentries, on the deck 1.95 m below floor); mode stays `standing` (back 3.2, up 1.70, look_up 1.6 on `outer_works`). Camera ends at (8, deck−1.15, 7536.7), **10.2 m** from the posts, pitched up 6.7°. Projection at 1280x720 (vertical fov 70 ⇒ 514 px per unit tan): each grunt **1.8 m → 91 px tall** (68 px on the 960x540 sheet), 30 px wide, centred at x ≈ 539 and 741 (feet y≈360, heads y≈275); arch ring (5.7 m above floor) at y≈98; the player ruler at 3.2 m occupies x 592–688, y 263–554 — clear of both figures by ≥ 40 px. Update the `_why`: 22–28 m stands give only 33–42 px figures (1.8·514/D), which is why the tighter distance is chosen.
3. If the coder wants the 3/4 angle: add `"offset": [-2.4, 0.0]` before `pull_back` (eye (7.1, 7539.9), ~2.6° of yaw) — optional, not required.
4. Night variant needs nothing else: both posts are 6 m from the `gate_source` fires and the tower sconces.

Proof: the tool's own line for the frame must print `eye(8, ~10.4, 7540)` with **no** `NOTE ... occupied by ... moved aside`; in `10-stronghold-gate-face-day.png` (960x540) two humanoid silhouettes ≥ 65 px tall at x≈404±25 and x≈556±25, y 205–270, both with luma median ≥ 45 (day) and ≥ 25 (night, fire-lit); the arch ring visible between them; no wall in the left half (box (50,100)-(400,400) median ≥ 30, today 7).
