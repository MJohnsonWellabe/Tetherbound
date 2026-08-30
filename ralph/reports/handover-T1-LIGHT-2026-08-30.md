# Handover — T1-LIGHT — 2026-08-30

Track 1 (Aesthetics) light-and-cast lane. Branch `ralph/T1-LIGHT`, off
`origin/main` at `28265a3a`. Pushed incrementally.

## What I was asked

Four items in priority order: (1) golden hour never rendering on the driven
clock, root-cause and verify with fresh captures; (2) final closure of the
black-NPC defect, retuning `npc_ranks.json`'s multipliers for the dead
emission floor and closing it with MEASURED luminance numbers, day and
night; (3) canopy/foliage albedo darkening, an albedo pass on tree canopy
materials; (4) if time remains, the night stair-step transition.

## What I found before touching anything

Both item 1 and most of item 4's diagnosis were **already done and merged
to `main`** by predecessor lanes before this session started — `main` at
`28265a3a` already carries `ralph/T1-SKY`'s golden-hour config fixes
(weather-leak pin, sun disc size/glow, cloud tint) and `ralph/T1-NIGHT`'s
`dawn` keyframe (fixes the backwards night-to-day brightening ramp
Judge 2 measured). `JUDGE-VISUAL-2-2026-08-30.md` already confirmed both
fixed with real captures, and nothing touching `art.json`'s `times` block,
`world_look.gd`, or `day_cycle.gd` landed between that judged tree and
current `main` (checked with `git log 8567f597..28265a3a -- <those
files>` — the only intervening commit, `T1-NPC-CAST`, only appends new
character entries after line 363 of `art.json`, well clear of the day-cycle
block).

So the brief's headline item was reopened evidence, not a live defect —
per `CLAUDE.md`'s "evidence-backed already fixed is valid," I re-verified
with a fresh capture rather than re-doing the root-cause work, and spent
the saved time on item 2, which was NOT actually closed despite
`npc_ranks.json` carrying a same-day "T1-GROUND" fix.

## Item 1 — golden hour: re-verified, still fixed, no regression

Ran a full fresh `tools/_capture_day_night_transition.gd` 12-hour sweep on
current `main` (not the older judged tree). `tools/frame_stats.py`'s own
`nearL` (near-luma) column confirms the same shape Judge 2 found: 17:50/
17:90/18:10 read warm (yellow/orange/chartreuse-dominant hue histogram,
`nearL` 0.21–0.40) against the flat grey-blue wash the original defect
described, and night frames hold flat (`nearL` 0.18–0.24 across
22:00→02:00, no runaway brightening — the `dawn` keyframe fix still
holds). Evidence: `ralph/reports/T1-LIGHT/shots/day_night_verify/hour-*.png`.

No code or data change made for this item — nothing to fix.

## Item 2 — black NPC: the actual closure

**T1-GROUND's same-day multiplier retune (`npc_ranks.json` grunt
`#8a8a8a`→`#dcdcdc`, officer `#c2c2c2`→`#eeeeee`) was real progress but not
the fix.** `JUDGE-VISUAL-2-2026-08-30.md` subject 8 re-measured that exact
palette in-world and got mean body luma 13/255 — "still a black speck at
distance." I confirmed why directly: `ground-02-band2-grunt-AFTER.png`
(T1-GROUND's own "after" evidence, already committed) is barely
distinguishable from the "before" frame side by side.

**Root cause: `character_model.gd`'s additive emission floor — the
mechanism `npc_ranks.json`'s own comments assumed was doing the lifting —
is dead code on every rig shipping today.** `GF-B-010`'s header already
says `emission_enabled` is `false` on all six rigs' source materials, and
the floor logic in `_shared_variant_material()` was gated behind
`if material.emission_enabled:` — a condition that mirrors the SOURCE
material's own (always-false) state, so the floor never ran. The
multiplier retune was therefore the only live lever, and a 0.54x→0.86x
push on an already near-black texture (median 0.137) stays deep in the
ACES tonemap's toe (the same mechanism `world_look.gd`'s NIGHT-LIGHT
history already documents for a different multiplicative nudge) — which
is why it barely moved a rendered pixel.

**Fix:** added a `body` parameter to `_shared_variant_material()`, passed
`true` only from `_palette_node`'s body-surface call site, that
force-enables emission for any tint under 0.95 luminance regardless of
the source material's own `emission_enabled` — reviving the additive
floor `STRANDED-P3` already designed and tuned for exactly this failure
mode, just never actually wired to run. Scoped to body surfaces only (not
hair, not accessory badges — a badge already has its own legibility fix
via `finish`'s metal, and hair was never the reported defect).

**Retuned `EMISSION_FLOOR_ADD` from 0.06 to 0.18**, empirically, because
0.06 was itself never render-verified (it was tuned against a gate that
never ran). Built a fast iteration probe,
`tools/_probe_grunt_luminance.gd` — real `world_look.gd` day/night
config, no playground boot, so a tuning loop costs ~15s instead of the
~10min a scoped world capture needs — plus `tools/_sample_npc_luma.py`
(background-relative luma so the number is the body's own, immune to the
background colour itself drifting under `world_look.gd`'s own
`adjustment_saturation`/brightness/contrast pass, which shifts a fixed
magenta probe background differently at every time-of-day preset — this
tripped me up once before I made the sampler measure the background
per-image rather than assume a fixed value).

Studio-probe numbers (0..255 scale, real day/night `world_look.gd`
config): grunt/officer at 0.06 read 17.0/20.0 in day, 15.0/18.4 at
night — barely above the in-world 13 Judge 2 measured. At 0.18: 30.6/35.4
day, 51.7/59.5 night. Checked visually, not just the numbers, at every
step: collar, straps, mask and boot folds stay readable; nothing flattens
toward one grey slab the way the file's own R9.4/0.30 history warns an
oversized floor can.

**Confirmed with a real in-world render, not just the studio probe** —
`tools/_capture_ground_and_sky.gd --only=band2 --states=day,night`, the
exact camera stand and NPC (Dorn) both the first and second blind judges
used. Cropped tight to his body only (avoiding the surrounding grass/path
the first attempt at this measurement pulled in and inflated the number
with):

| | before (T1-GROUND, `#dcdcdc` + dead floor) | after (this fix) |
|---|---|---|
| day, mean body luma | 13/255 (Judge 2, in-world) | **31.5/255** (measured here, in-world) |
| night, mean body luma | not previously measured | **16.5/255** (measured here, in-world) |

The day frame in particular is a large, visible change — Dorn goes from
what read as a near-solid dark mass to a figure with a legible dark
tactical uniform: cap, mask, collar, chest strap and belt pouch all read
at normal viewing distance, not just under a diagnostic zoom. Evidence:
`ralph/reports/T1-LIGHT/shots/npc_luminance/` — full frames, the tight
`dorn-day-crop.png`/`dorn-night-crop.png`, and the studio-probe images the
tuning loop was measured against.

The real-world day number (31.5) landed close to the studio probe's own
prediction (30.6), which is worth recording: the fast studio probe is a
reliable proxy for in-world results on this specific class of change (a
flat additive material property, not a scene-lighting interaction), so a
future tuning pass on this same mechanism can trust it without a full
world capture every iteration.

**Confirmed on a second, independent NPC too** — band 4's own close-range
rank NPC, the second body Judge 2 measured at "luma 13" in daylight
(`--only=band4 --states=day,night`, same tool). Day: **13 → 42.9/255**,
and at this close range the improvement reads even more clearly than
Dorn's — cap, mask, oxblood badge, belt pouches and boots are all legible
at normal viewing distance, not just under zoom
(`band4-officer-day-crop.png`). Night: 13.4/255 measured, but the actual
frame reads considerably better than that number alone suggests — he
stands out as a warm brown-toned figure against the cool moonlit scene,
clearly not a black cutout; the low absolute number is partly this
specific frame's own very dark local background (no moonbeam highlight
nearby, unlike Dorn's stand) rather than the fix underperforming — flagged
so the number isn't read as contradicting the visual, the same trap
T1-SKY's own fog-preset measurement hit and named.

**Trainer/Grandpa/villagers/captain/Warden are unaffected** — their tint
luminance is always ≥ 0.95 (identity multiply), so the new gate still
skips them; `tests/test_character_metallic.gd`'s 4 tests / 27 assertions
still pass unmodified.

**Not fully solved to "matches a lit crate" and not meant to be** — the
uniform is a deliberately dark tactical outfit; the target was "reads as
a dark-uniformed person, not a silhouette cutout," which the render
evidence above supports.

## Item 3 — canopy/foliage albedo: checked, does not clearly reproduce, not touched

Judge 2's specific complaint was dusk (19:00–20:50) canopies reading
"near-daylight green over a dusk ground." `T1-GROUND-2` had already
investigated this at a DIFFERENT viewpoint (band1/band2 at deep night
only) and found no reproduction, attributing it to `GROUND-REBUILD`
raising the ground's own albedo baseline enough to close the gap.

I checked the actual complaint window — 19:00, 20:00 and 20:50 at the
`_capture_day_night_transition.gd` ranger-camp viewpoint, which does show
real canopy in frame (unlike T1-GROUND-2's viewpoints) — with
region-averaged luma (not a small point-sample, which the canopy's own
per-leaf-card light/dark mottling makes noisy) comparing the two visible
tree masses against the shadowed foreground ground and the directly-lit
midground path:

| hour | canopy luma | ground (shadowed fg) | ground (lit strip) |
|---|---|---|---|
| 19:00 | 65.1 | 53.9 | 84.4 |
| 20:00 | 57.5–58.8 | 42.6 | 81.7 |
| 20:50 | 56.9 | 43.8 | 70.3 |

The canopy sits **between** the two ground readings at every hour
checked — 20–35% brighter than the ground directly in shade, but always
darker than ground catching direct light. That is a physically plausible
"elevated canopy catches more ambient/sky light than shadowed ground"
relationship, not the dramatic self-lit-slab defect the original report
described. I looked at the actual frames too (not just the numbers) — see
`ralph/reports/T1-LIGHT/shots/day_night_verify/hour-{19.00,20.00,20.50,22.00}.png`
— and while the canopy does read as a somewhat saturated mid-green next to
the desaturated navy ground/sky (a real, softer effect — probably a
saturation/hue-contrast read rather than a raw-brightness one), it is not
a clear enough case to justify an albedo darkening pass, which the file's
own R9.4/NIGHT-LIGHT history warns can flatten blacks and lose mood if
pushed without real evidence backing the specific amount.

**Concurring with `T1-GROUND-2`: this does not clearly reproduce as a bug
on current `main`.** No code or data change made. If the coordinator or a
fresh blind judge still calls this out specifically, the next lever named
by both this session and T1-SKY's original diagnosis is
`vegetation.json`'s `Leaves_NormalTree` `variant_retint` values (`#78c86e`/
`#325f3c`/`#c4d696`) — not a lighting change — but I did not want to spend
a speculative edit against numbers that do not show a dramatic defect.

## Item 4 — night stair-step: not attempted

`T1-NIGHT`'s own handover already diagnosed this thoroughly (a same-hour
A/B on `directional_shadow/size` moves 32.6% of pixels but relocates the
artefact rather than removing it; the better-supported lead is night's
moon pitch, `-20°`, interacting with terrain undulation) and explicitly
flagged that any further move — `shadow_normal_bias`/`shadow_bias` retune,
or a steeper moon pitch — needs one look on **real hardware** before
spending either the VRAM or the mood tradeoff, since this box's llvmpipe
software rasteriser cannot be trusted for "does this look better to a
human eye," only for "does the setting do anything." I did not have real
hardware available in this session either, so I did not take a blind
swing at either lever — that would repeat the exact unverifiable-on-this-
box mistake T1-NIGHT's own report warns against. Left `project.godot` and
`art.json`'s night sun pitch untouched.

## Full file footprint

- `scripts/characters/character_model.gd` — `_shared_variant_material()`
  gained a `body` parameter (default false); the emission-floor gate now
  force-enables emission for dark body-surface tints regardless of the
  source material's own state. `EMISSION_FLOOR_ADD` 0.06 → 0.18.
- `data/config/npc_ranks.json` — one new comment (`_comment_palette_t1_light`
  on `grunt`) recording why the multiplier retune wasn't the fix and
  pointing at the real mechanism. No palette VALUES changed — T1-GROUND's
  `#dcdcdc`/`#eeeeee` are still correct and still doing real work
  alongside the floor.
- `tools/_probe_grunt_luminance.gd` (+ `.uid`) — new fast iteration probe,
  same convention as `_probe_npc_metallic_ab.gd`.
- `tools/_sample_npc_luma.py` — new, background-relative luma sampler for
  the probe's own output.
- `ralph/reports/T1-LIGHT/shots/day_night_verify/` — the full fresh
  12-hour sweep.
- `ralph/reports/T1-LIGHT/shots/npc_luminance/` — band2 day/night frames,
  tight Dorn crops, and the studio-probe frames the tuning was measured
  against.
- This file.
- **Not touched:** `data/config/art.json`'s `times`/sky/sun/moon blocks
  (item 1, already fixed), `vegetation.json`/`vegetation.gd` (item 3,
  does not clearly reproduce), `project.godot`,
  `stronghold*.gd`/`landmark.gd`/`building_prefabs.json` (Hall lane),
  grass/stream/terrain scatter configs (ground lane), `species.json`/spawn
  tables (install lane), objectives/trainers (content lane).

## What I would do next

1. If a fresh blind judge still calls out canopy self-lighting
   specifically after this session's frames, the next lever is
   `vegetation.json`'s `Leaves_NormalTree` retint values — a small,
   render-verified darkening, not a lighting change — rather than the
   larger swing this session declined to take on ambiguous evidence.
2. The night stair-step needs real ROG Ally hardware time before either
   `shadow_normal_bias` or the moon's pitch is worth touching — flagging
   again since it is now the oldest unaddressed item across three lane
   reports (T1-LIGHT, T1-NIGHT before it).
3. `tools/_probe_grunt_luminance.gd` generalises past this one fix —
   worth reaching for whenever a future rank/faction palette needs
   tuning against real lighting without a full world boot.

---

## Round 2 — coordinator work order, JUDGE-3-2026-08-30.md sec1b/1e/2b/3

A second work order arrived mid-session (round 1's work was already being
landed via `ralph/LAND-0830D`). Merged `origin/main` forward first (no-op,
main had not moved). Three items routed here.

### Campfire light (sec1b) — fixed, but not where I first looked

The complaint: "an unshaped blown-out disc on the ground... brighter at
its centre than the sky, in daylight. The point light has no daylight
attenuation." First fix attempt: `scripts/world/campfire_glow.gd`'s
`OmniLight3D` got `omni_attenuation 1.8` (softer falloff, same class of
fix as `torch.gd`'s `spot_attenuation`) and a day/night energy scale
(`DAY_ENERGY_SCALE 0.16`, full energy at night, read from
`world_look.gd::is_dark()` via the same lazy "day_cycle"-group lookup
`torch.gd`'s own OF18 fix uses).

**That fix was real but not the one the judged evidence needed.** A
same-tool before/after pixel diff of `tools/_capture_t1_camp.gd`'s
`01-camp-establishing.png` (the exact frame JUDGE-3 cited) came back at
0.01 mean-abs-diff — essentially nothing moved. Root cause:
`scripts/build/camp.gd::build_real()` (the PLAYER-BUILT camp, which is
what this evidence tool renders) never instantiates `CampfireGlow` at
all — it only calls its `ignite()`/`texture_logs()` static mesh-tinting
helpers, and builds its own **separate** `OmniLight3D` (energy 2.8,
default attenuation, no day/night gating) inline. That second, unrelated
light is what the judge actually photographed.

Applied the identical pair of fixes to `camp.gd`'s own light (new
`_process()`, same lazy "day_cycle" lookup, `FIRE_LIGHT_DAY_SCALE 0.16`,
`omni_attenuation 1.8`). Also found and fixed a second gap while
verifying: `tools/_capture_t1_camp.gd`'s own rig (`_capture_structures.gd`'s
isolated flat-sun stage) has no `WorldLook` at all, so neither fix could
ever be observed there — added `tools/_capture_day_stub.gd`, a two-line
node that answers `is_dark() -> false` (this stage's fixed sun is always
daytime), registered in the "day_cycle" group before the camp builds.

**Verified, same tool, before/after:** the ground disc is visually gone
(`ralph/reports/T1-LIGHT/shots/campfire/01-camp-establishing-{BEFORE,AFTER}.png`);
near-fire ground sampled +5.7 brighter than a control patch before, -14.7
darker (shadow-only) after. Separately re-verified the AUTHORED trail_camp
(real world, real `WorldLook`, `tools/capture_trail_camp.gd`) was already
clean with just the `campfire_glow.gd` half of the fix — no light-pool
blowout at that campfire either
(`ralph/reports/T1-LIGHT/shots/campfire/trail-camp-day-AFTER.png`), so
that fix is separately correct for every authored rest-point fire
(`props.gd`'s `glow: "campfire"` branch — trail_camp, river_lock, upper
meadows, stronghold) even though it wasn't what the judged frame needed.
The flame mesh itself (yellow faceted cones, no gradient) is unchanged —
content lane's own item, per the brief.

### Guardian den — fixed, real contact shadow now exists

The complaint (sec1e/sec3): "the guardian is a near-black lump... the rim
does not separate the animal from the wall" and "no contact shadow of any
kind... reads as sitting IN the ground" — measured on
`guardian-den-0830-full.png`, the SAME frame `burrow_warrens.json`'s own
`_comment_guardian_stand_wash_verified_0830` recorded a DIFFERENT blind
judge calling "yes, legible" one round earlier. Both verdicts are real;
recorded rather than silently overwritten — see that comment's own
successor, `_comment_guardian_shadow_and_wall_0830_t1_light`, for the full
account.

Root cause, found by reading `burrow_warrens.gd::_build_lights()`: every
light in the file was `shadow_enabled = false` by design ("shadowless
omni, broad wash" — the file's own `_comment_lights`). A cave interior has
no sun reaching in, so with every light shadowless, **nothing standing in
the room could ever cast a real contact shadow, at any energy** — the
three prior rounds (CONTENT-0828, T1-CREATURE's backlight, T1-CAST's
floor-wash) were all trying to solve a shadow-shaped problem with more
wash, which structurally cannot produce one.

Fix: `_build_lights()` now reads an opt-in `"shadow": true` key per light
(default false, so every other light's cost is unchanged); set it on the
guardian's own key light only, the same bounded-VRAM-cost pattern already
shipping in `cottage_interior.gd`/`grandpa_house.gd`/`inn_interior.gd`/
`shop_interior.gd`. Also moved the backlight and general den-fill energies
for the first time since CONTENT-0828 authored them (0.55→1.2, 0.4→0.6) —
the same ACES-toe reasoning `world_look.gd`'s own NIGHT-LIGHT history
already documents: three rounds of small energy nudges near the bottom of
the tonemap's flat region is why the room's own history shows an
inconsistent judged result on the identical mechanism.

**Verified with a same-viewpoint, same-stand-in-torch before/after**
(`tools/_probe_guardian_den_light.gd`, new — a single-stand fast rig
matching `capture_warrens_63.gd`'s `06-den-and-guardian` exactly, so
directly comparable to the committed evidence; guardian's wander put it
within 0.4m of its baseline position, a fair same-stand comparison):

| | before | after |
|---|---|---|
| guardian body luma | 26.6 | 43.6 (+64%) |
| wall behind guardian | 47.3 | 62.6 (+32%, now warm not flat grey) |
| floor at guardian's base | 53.0 (brighter than the wall — no shadow) | 49.8 |
| floor further from guardian | (not sampled) | 94.9 |

The floor number is the one that matters most: before, the base was
slightly *brighter* than the wall (no shadow pooling anywhere in the
room); after, there is a real ~45-point gap between the floor right at
the guardian's feet and the floor a few metres away — a genuine contact
shadow, not a value nudge. Visually the guardian now shows real
shell-plate texture and colour variation instead of a flat black cutout,
and the wall/ceiling behind it read warm and lit. Evidence:
`ralph/reports/T1-LIGHT/shots/guardian_den/guardian-den-{BEFORE,AFTER}-round2.png`.

### Contact shadows, general (sec2b) — investigated, not further fixed here

JUDGE-3's Creek Hollow evidence (`far_water_edge-CROP-embedded.png`) shows
two creatures "reading as cutouts pasted on the hillside" with no contact
shadow, routed to both ground (spawn Y/terrain-snap) and light. Checked:
Godot's directional sun already ships `shadow_enabled: true` by default
(`world_look.gd::_apply_sun`), SSAO is already on
(`art.json`'s `ssao_enabled: true`), and no creature/VFX script sets a
`cull_mask` or `light_cull_mask` that would exclude creature meshes from
shadow casting — grepped `scripts/creatures/`, `scripts/combat/`,
`scripts/world/encounter_director.gd` directly, found only VFX/aura
overlays correctly marked `SHADOW_CASTING_SETTING_OFF`, nothing on a
creature's own body mesh. I found no separate outdoor lighting-mechanism
gap to fix beyond what's already correctly configured.

The two specific creatures JUDGE-3 photographed are both described as
partly submerged in the terrain (one "lying completely flat with zero
volume," one "sunk into the slope from the hindquarters back") — if a
creature's mesh root sits below the ground plane, whatever sliver of
geometry pokes through casts a negligible shadow onto ground it's already
inside of, correctly rather than as a bug. That reads as a direct
consequence of the placement/embedding defect the report's own routing
already sends to ground, not a second, independent light defect. Did not
invent a fix for a mechanism I could not find broken; the guardian-den fix
above is the one confirmed, real "no shadow-casting light source at all"
gap this round found, and it is fixed.

### Full file footprint, round 2

- `scripts/world/campfire_glow.gd` — `omni_attenuation`, day/night energy
  scale (superseded as the fix for the judged frame, kept because it's
  correct for the authored rest-point fires).
- `scripts/build/camp.gd` — the actual fix: same pair of changes on its
  own separate `OmniLight3D`.
- `tools/_capture_t1_camp.gd` — registers the new day-stub so its own
  rig can demonstrate the daylight fix.
- `tools/_capture_day_stub.gd` — new, two-line `is_dark()` stand-in for
  isolated capture rigs with no `WorldLook`.
- `scripts/world/burrow_warrens.gd` — `_build_lights()` reads an opt-in
  `shadow` key per light.
- `data/config/burrow_warrens.json` — guardian key light gets
  `"shadow": true`; backlight and den-fill energies raised (see the new
  `_comment_guardian_shadow_and_wall_0830_t1_light`).
- `tools/_probe_guardian_den_light.gd` — new, single-stand fast
  iteration rig for this den, same viewpoint/torch as
  `capture_warrens_63.gd`'s `06-den-and-guardian`.
- `ralph/reports/T1-LIGHT/shots/campfire/`,
  `ralph/reports/T1-LIGHT/shots/guardian_den/` — before/after evidence.
- Not touched: `scripts/creatures/*`, `scripts/world/encounter_director.gd`
  (checked, found no gap), any ground/terrain/scatter file (Creek Hollow
  embedding is ground-lane's), `species.json`, objectives/trainers.
- Tests: `tests/test_character_metallic.gd` (4/27), `test_build_catalogue.gd`
  (8/128), `tests/smoke_warrens.gd` all green.

### What I would do next, round 2

1. If a future judge still finds the Creek Hollow creatures shadowless
   AFTER the ground lane's own spawn-Y/terrain-snap fix lands, re-check
   contact shadows then — this round's read is that the embedding was
   the whole explanation, but that's unverified until the embedding fix
   exists to test against.
2. `tools/_capture_day_stub.gd` is a small, generic pattern (a
   `WorldLook`-shaped stub for isolated capture rigs) — worth reaching
   for again the next time an isolated rig needs to demonstrate a
   day/night-gated fix rather than silently falling back to "no day
   cycle exists."
3. Watch for other places that build their own standalone `OmniLight3D`
   for a fire/torch/lantern rather than going through `campfire_glow.gd`
   or `torch.gd` — `camp.gd`'s own light was exactly this pattern, found
   only by chasing a pixel diff that showed zero movement rather than by
   reading the call graph first.
