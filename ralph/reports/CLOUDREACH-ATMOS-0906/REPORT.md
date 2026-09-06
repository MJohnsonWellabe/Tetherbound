# CLOUDREACH-ATMOS-0906 — lane report

**Branch** `claude/art-cloudreach-atmosphere-0906`
**Head** `8e5cdb115ee51b4bb129dc851acd6f48c48b538e`
**Base** `claude/second-biome-art-plan-470zru` @ `6900f553` (main merge + cliff option A +
realm-wide turf fill + crown relief). **Not** cut from `main`.
**No pull request opened.**

Scope: the Cloudreach Cliffs atmosphere and verticality gaps — **C4** (thin horizon),
**C5** (floating islands read as unrendered slabs), **C3** (a region named for cliffs never
shows one), plus the `HANDOFF_2026-09-06.md` §5.2 leftovers belonging to this lane.

Read `EVIDENCE.md` beside this file for the full numbers and the reasoning per change;
`JUDGE-before.md` and `JUDGE-after.md` are the two blind verdicts in full, and
`JUDGE-after-round2.md` / `JUDGE-after-round3.md` are the interim rounds that redirected the
work. This file is the cold-pickup summary.

---

## 1. Verdict summary — did the judge stop naming the gap?

The acceptance bar was "done is the judge no longer naming the gap". Four render rounds,
three blind judge rounds. **One of the three gaps clears the bar, one moved, one did not.**

| gap | before (judge's words) | after (judge's words) | closed? |
|---|---|---|---|
| **C5** islands | "no underside, no roots, no mist, no anchor — it reads as **a mesh that lost its parent and is a bug** to any player who sees it"; "four or five **detached rock blobs hanging in the air beneath it** connected to nothing" | asked the question directly and blind: "**authored, not a rendering failure.** It has a deliberate, non-random silhouette … **failures do not produce that shape or that supporting detail**." Absent from the after-judge's list of things that read as broken; the falling debris is not mentioned in any round after the fix. | **YES** |
| **C4** horizon | "past the grass edge, there is a flat pale blue-grey void — **no distant ranges, no lower cloud deck, no further spires, nothing**"; "in a region named for reaching clouds, there are **no clouds**" | cloud below eye level "**yes in three, no in one**" (01/02/11 yes, 04 no); terrain lower than the player "**yes in three, no in one**"; haze band "partial, and absent where it matters most". **But**: "even where present they are rendered as **flat cutouts**, so the horizon carries *layers* without carrying *depth*", and "the cloud sea is **opaque white cardboard**". | **PARTLY** |
| **C3** verticality | "the whole habitable world stopping at a grass edge with flat grey nothing beyond"; "no drop, no valley below, no cloud layer beneath the player" | "**No, and no.** In all four frames the player stands in the middle of a broad, gently rolling green field." | **NO** |

Bar questions A (key art) and B (Palworld) are **no** in both the before and after verdicts.
The after-judge's own top three gaps are ground-cover density, untextured rock surfaces, and
"nothing is happening and nobody is posed" — none of which is this lane's.

The before-judge's single largest finding — "the references have a top end; these frames do
not" — **is closed on its own numbers**; see §4.

Judged stands: `01-arrival-first-reveal`, `02-broken-causeways`, `04-high-roost-before-fly`,
`11-aerie-ground-connection`, via `tools/_capture_cloudreach_cliff_options.gd` at native
1280×800, production camera, day, clock frozen. `shots/` is gitignored, so the frames are
not committed — verdicts are.

---

## 2. Ground truth — the hard constraint

Zero new holes was non-negotiable. **Held, and buried came out better than baseline.**

| | samples | holes | mismatches | buried | crown triangles |
|---|---|---|---|---|---|
| **before** (branch point `6900f553`) | 41,219 | **0** | 33 | 914 | 727,157 |
| intermediate (C3 terraces + C4 + C5) | 41,219 | **0** | 33 | 920 | 727,157 |
| **after** (head `8e5cdb11`) | 41,219 | **0** | 33 | **888** | 727,157 |

Exact output, `godot --headless --path . --script tests/smoke_cloudreach_ground_truth.gd`.

**Before** (run on the unmodified branch point, before any edit):

```
CLOUDREACH GROUND TRUTH: colliders=2012 trimesh_colliders=1783 trimesh_triangles=727157
CLOUDREACH GROUND TRUTH: 41219 sample points checked, 0 holes, 33 height mismatches (>0.15m), 914 buried under visible geometry
CLOUDREACH GROUND TRUTH: mismatch rate 0.08% (holes + mismatches over samples)
CLOUDREACH GROUND TRUTH: worst offenders (largest gap first):
CLOUDREACH GROUND TRUTH: PASS
```

**After** (run on the committed head):

```
CLOUDREACH GROUND TRUTH: colliders=2012 trimesh_colliders=1783 trimesh_triangles=727157
CLOUDREACH GROUND TRUTH: 41219 sample points checked, 0 holes, 33 height mismatches (>0.15m), 888 buried under visible geometry
CLOUDREACH GROUND TRUTH: mismatch rate 0.08% (holes + mismatches over samples)
CLOUDREACH GROUND TRUTH: worst offenders (largest gap first):
CLOUDREACH GROUND TRUTH: PASS
```

Zero new holes, zero new mismatches, zero change in crown triangles, 26 **fewer** buried
samples than baseline. The 33 mismatches are the pre-existing set (Ridge000 near the
Galefoot settlement terrace, Ridge003 at the observatory and the upper plateau circuit);
they were 33 before this lane and are the same 33 after.

Why nothing moved: every terrain metre this lane added goes through `_crown_relief_at`, the
shared height model `_mesa` emits its **visible crown and its collision copy** from, and
which every shoulder reaches through `_walkable_height`. The route-shoulder edge deepening
is emitted into the same station vertices the walkable rows, the wall attachment and the
collision copy are all built from. Nothing was written into a single emitter, so the render
cannot walk away from the collider and the OP-0905-24/25 hole/sink class stays closed.

Buried moved twice: +6 when the crown terraces put road samples fractionally under their own
crown, then −32 when the deeper shoulder edge dropped samples out from under geometry that
had been over them. Buried means "this sampled surface lies under other visible geometry",
not a defect.

---

## 3. Frame time and the other smokes

`tools/probe_cloudreach_wild_performance.gd`, run on the committed head:

```
CLOUDREACH WILD PERFORMANCE COMPLETE: 12 phases, 0 failures
frame_interval_ms across all twelve 600-sample phases:
  mean  16.6650 - 16.6680      (baseline at the branch point: 16.67)
  p50   16.658  - 16.674
  p90   16.741  - 16.904
  p99   16.836  - 18.313       (baseline: ~17.8)
-> ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json
```

Held. The mean matches the baseline to three decimals; the worst p99 across twelve phases is
18.313 ms against a ~18 ms bar.

| smoke | result |
|---|---|
| `smoke_cloudreach_foundation` | `CLOUDREACH FOUNDATION OK regions=6 landmarks=12 bridges=5 player=(0.0, 105.0302, -260.0)` |
| `smoke_cloudreach_look` | `CLOUDREACH LOOK OK bridges_rails=14 posts=798 moorings=9 cover_main=128288 cover_far=24606 cover_alpine=4193 cover_fill=171117 trees=86 stones=79 settlement_overrides=420 guy_ropes=16` |
| `smoke_cloudreach_ground_truth` | `PASS` (§2) |
| `smoke_cloudreach_arrival_walk` | `CLOUDREACH ARRIVAL WALK OK player=(-275.156, 180.0296, 517.4778)` |

Render cost per stand, from the capture tool's own `performance.json`. Software GL, so the
*times* there are meaningless; the counters are not:

| stand | draw calls before → after | primitives before → after |
|---|---|---|
| 01-arrival-first-reveal | 5473 → 5495 (+0.4 %) | 8.02 M → 8.27 M (+3.1 %) |
| 02-broken-causeways | 3866 → 3899 (+0.9 %) | 6.65 M → 6.98 M (+4.9 %) |
| 04-high-roost-before-fly | 625 → 640 (+2.4 %) | 1.91 M → 2.13 M (+11.6 %) |
| 11-aerie-ground-connection | 678 → 703 (+3.7 %) | 1.93 M → 2.20 M (+13.9 %) |

Two cloud sheets are one draw call each and 760 billows are one MultiMesh, which is why a
layer covering the whole realm costs a couple of dozen draw calls. The primitive rise
concentrates in the two sparse stands, where the new layer is a large share of a small
frame.

**Not verified, and nobody should claim it is:** none of this ran on a GPU. Frame time here
is a headless physics/process measurement, not a rendered one, and the visual judging ran
under llvmpipe. The ROG Ally numbers for the added geometry are unknown.

---

## 4. Exposure — measured before spawning any judge

`HANDOFF_2026-09-06.md` trap 9. Rec.709 luminance percentiles and mean saturation over the
whole frame:

| set | frame | p50 | p90 | p99 | sat % |
|---|---|---|---|---|---|
| before | 01-arrival-first-reveal | 114 | 144 | 187 | 56.3 |
| before | 02-broken-causeways | 113 | 144 | 194 | 50.4 |
| before | 04-high-roost-before-fly | 99 | 125 | 160 | 60.1 |
| before | 11-aerie-ground-connection | 99 | 136 | 168 | 60.5 |
| **after** | 01-arrival-first-reveal | 130 | **217** | **231** | 44.8 |
| **after** | 02-broken-causeways | 148 | **220** | **231** | 36.1 |
| **after** | 04-high-roost-before-fly | 143 | **223** | **231** | 38.5 |
| **after** | 11-aerie-ground-connection | 106 | **194** | **228** | 51.8 |
| reference | palworld-02-open-field-path | 133 | 210 | 225 | 41.8 |
| reference | palworld-04-plateau-landmark | 105 | 226 | 242 | 41.3 |

The before-judge measured this itself and made it its single largest finding ("saturated and
darker at the same time, which is the specific combination that reads as muddy"). The after
set is inside the reference band on both the top decile and the top percentile, and
saturation has come **down** toward the references rather than up.

The lever was `sky_profile.energy` 1.0 → 1.30 — scoped to this realm's profile, because
`art.json`'s global sky drives the Meadows too. The scene runs
`ambient_light_sky_contribution` 0.52, so it lifts the sky and the ambient fill together.

---

## 5. What was closed, and how

### C5 — floating islands (CLOSED)

Three literal causes, all found by reading the code rather than inferring from the picture:

1. **No underside.** `_mesa` closes its crown and its four wall bands and had **never**
   capped the bottom ring. On a region `CliffMass`, built down to `landmass.geology_base_y`,
   that is free and invisible; a `LandmarkLedge` is a 72 m stub in open sky and an
   open-ended tube. `_emit_mesa_root` now gives an airborne mass a tapering root on a
   quarter-ellipse profile down to a keel, wearing the same geology shader as the wall.
   **Visual only** — the collision copy is still emitted from the crown alone.
2. **The falling pebbles were real geometry.** `_build_embedded_rock_shelves` measures
   outcrop `depth` down from the crown and never bounded it by the mass's own height: on a
   72 m monumental ledge `9 + 4 × 22 = 97` put four of thirteen outcrops **25–61 m below the
   bottom ring**. The two `i >= 3` shelves did the same, reaching local y = −62 against a
   bottom ring at −36. Both clamped, and **only** the visual ones: `_mesa(..., i < 3)` is the
   shelf collision flag and the outcrops carry no collider, so no walkable surface moved.
3. **No mist, no anchor.** A collar of billows at each airborne base; and the mooring lines
   were never missing — they were 0.16 m of rope read at 800–900 m, under one pixel at
   1280×800. Widened to a hawser, fallback anchor pylon deepened.

"Airborne" = a `LandmarkLedge` whose base sits more than `airborne_gap_m` (120 m) above
`geology_base_y`, so every region mass — built down **to** that datum — is excluded
automatically and pays nothing.

**A regression this lane introduced and then fixed.** The round-3 judge: "the white cloud
puffs draw *through* it — cloud sprites intersect its body front and back. It reads as
unrendered geometry." The first mist collar drew from 0.55× the radius and up to 13 m
**above** the base with puffs up to 0.66×, so half of them were inside the island. It is now
strictly outside the footprint (`mist_inner_fraction` 1.08) and strictly below the base.

### C4 — thin horizon (PARTLY)

- **A cloud sea that follows the land.** The existing `CloudSea` plane could not move:
  `cloudreach_world_runtime.gd::_mount_fall_recovery` measures the fall-recovery kill plane
  off that node's own Y. It is also 340–1340 m under every stand. So `_build_cloud_decks`
  adds a second layer — two sheets whose height at each cell is the local region tier minus
  `drop_below_tier_m` (190 m), clamped under anything `ground_height_at` knows is walkable,
  with 760 lit cumulus billows on the upper one in one MultiMesh.
- **The tier model needs its non-decreasing envelope, and that is load-bearing.**
  `high_roost_sky_shrine` sits at z=2920 y=1020 between `windscar_ravine` (2850, 470) and
  `upper_cloudreach` (4200, 850). It is a Fly-only pinnacle, not the local ground, and
  interpolating through it spikes the model to 1020 exactly where the stands at z≈3260 stand
  at ~610 — hanging the sheet **115 m over the player's head**. `_region_tiers()` drops any
  crown standing above every crown further up the realm.
- **`tools/_probe_cloudreach_cloud_decks.gd`** exists because that failure is invisible in
  every counter the smokes print and glaring in a picture that costs ~11 minutes on this box.
  It reads `cloud_sheet_height_at`, the same function the mesh is built from, so it cannot
  report a height the mesh does not have. Committed. Last run:

  ```
  CLOUD DECK PROBE  worst clearance 135.0 m at 01-arrival-first-reveal
  CLOUD DECK PROBE OK: the sheet is below every authored stand
  ```

- **Distant lower terrain.** `horizon_ranges` already put ten ranges on the skyline, but
  every one is a peak **above** the player. `_build_distant_relief` adds 24 wide, low masses
  past the realm footprint with tops 170–430 m **below** the local tier.
- **Aerial perspective as a material, not more fog.** This realm's fog is deliberately
  scaled down by `distant_fog` to stop the islands washing grey, so the skyline ranges and
  the new lower relief wear hazed tiers (`haze_near`, `haze_far`) instead of the near
  geology shader.
- **The sky.** `sky_profile` was not dressing the Meadows sky, it was flattening it:
  `cloud_lit_contrast` 0.10 against `art.json`'s own 6.0 is what turns a lit cumulus into a
  wisp, and `cloud_sun_gain` 0.35 against 1.1 removes the brightening that gives a cloud a
  top and a base. Round 1 overcorrected to total overcast; round 2 was re-measured off the
  render, not guessed. Colours are deliberately **not** set here — this profile is merged
  into the night and dawn presets too.

### A real bug found on the way (fixed)

`cloudreach_look.gd::_process` re-applied this realm's fog deltas by multiplying the
environment's **current** value by the scale every frame. That is only correct while
something else keeps resetting the base first — and `world_look.gd::_process` returns on its
**first line** when its clock is frozen, which is what every capture tool calls before it
renders. Nothing reset the base, so it compounded at 0.55 per frame for 12+ frames before
the first shutter: **Cloudreach has had effectively no distance fog in any judged frame to
date.** Now scaled only when the value is one this function did not itself write, which is
correct both when WorldLook refreshes the base and when nobody does.

Worth flagging to whoever owns the Meadows: the same "reapply on top of the owner" pattern
is used elsewhere in `world_look.gd` for weather, and the frozen-clock early-return applies
there too.

### C3 — verticality (NOT closed; see §6)

`_crown_terrace_at` steps a region crown down from its centre to its rim in three broad
benches with walkable risers, and `_route_ridge`'s outer edge drop went from 4–22 m to
14–54 m (`landmass.route_edge_drop_min_m` / `_range_m`). Both go through the shared height
model.

The terraces are **negative on purpose**: `_surfaces` registers a region as one ellipse at
its authored `top` and `ground_height_at` answers that flat number for the whole disc, so a
crown that rose above it would spawn a loaded player or an evidence camera inside a hill;
one that falls below it only drops them a little. That is the direction `_mesa`'s eroded
crown already takes (its rim is authored up to 48 m below the registered top).
`crown_relief.min_radius_m` dropped 40 → 28 so the rugged spur crowns flanking every road
(span 31–43 m) shape too; a `LandmarkLedge` (span 20.7 m), a transition ledge (20 m) and
every landing pad stay under the threshold and are untouched.

### §5.2 leftovers

- **Sky-bleed slab at stand 01 — reduced, not fixed.** It was `RealmKeyGlow`, a
  7 m × 0.45 m bar wearing the shared 1.35-energy `heart` material; edge-on it blows through
  the day exposure and reads white. It and `WaterwardGlow` now use `key_glow` (same hue, a
  third of the energy); the cylinders `BeaconFire`/`MarkerLight` keep full-energy `heart`.
  **The after-judge still names it** ("an untextured cyan slab on the keep").
- **Faceted terrain at 03/06/08 and green wedges at 01/05 — NOT attempted.** See §6.

---

## 6. What was NOT closed, and why — pickup notes

Written so someone else can continue without me.

### C3 is not closed at the judged stands, and here is the reason

The four judged stands (01, 02, 04, 11) **all sit mid-crest on route shoulders between
regions, not on region crowns.** Verified against the authored region footprints in
`cloudreach_world.json`: of the twelve capture stands, only `06-summit-final-approach`
(inside `summit_final_stronghold`) and `08-upper-cliffhold-east-arrival` (inside
`upper_cloudreach`) fall within a region ellipse. So the crown terraces change every region
**silhouette** in every frame but put no new drop under the player at 01/02/04/11.

Stand 04 is additionally unreachable by any terrain change: its camera pitch is **+24°**
(looking up) from the middle of a route crest, so everything below the tier is out of frame
by construction.

**To actually close C3, someone needs one of:**
1. terrain that drops within ~60 m of where the player stands at 01 and 02 — i.e. narrowing
   the route crest or cutting a real ravine beside it, which touches `_route_ridge`'s wall
   bands and is the change most likely to disturb the shoulder colliders the ground-truth
   gate protects. **A/B the ground truth on every step of that.**
2. or different / additional judged stands placed on real edges. The brief for this lane
   forbade camera moves, so I did not.
3. or the causeway actually spanning a gap: the judge's "the wooden ramp runs from the
   player's hill onto the next hill over continuous, unbroken grass … nothing is spanned."
   `_ground_sections_for_segment` already cuts ground that overlaps a bridge deck; the
   shoulder appears to fill back in around it. Worth a probe before assuming.

### C4's remaining half is a material problem, not a placement one

The judge: "the cloud sea is opaque white cardboard … hard-edged, near-pure-white lumps with
no internal value and no soft transition." The sheets and billows are opaque geometry with
hard silhouettes. **More billows will not fix this** — it needs alpha falloff at the billow
edge (a soft-particle depth fade or a fresnel-faded material). That is the single change
that would move C4 from "layers" to "depth", and it is a shader job of maybe an hour.

Also open: stand 04 has no haze band, no cloud below eye level and nothing lower than the
player, for the pitch reason above.

### The spiral scratches on the stand-11 spire — my hypothesis was WRONG

I added `normal_scale` to `shaders/cloudreach_cliff.gdshader` on the hypothesis that a normal
map sampled at `texture_scale` 0.055 (one repeat per ~18 m of world) was stretching across a
46 m ledge and producing the judge's "white-cyan curved scratch lines". **It did not remove
them.** The hypothesis is therefore wrong, and the real cause is the albedo path:

```glsl
float bend = noise3(world_position * 0.027) * 8.0;
float face = abs(sin(world_position.x*0.019 - world_position.z*0.024 + bend*0.04));
vec3 stone = mix(stone_dark, stone_light, 0.30 + macro*0.45 + face*0.15);
```

`bend` is itself a sine of a sine, so `face` is two nested low-frequency sines over a 46 m
mass — which is exactly a concentric swirl. The fix is to weaken or replace that term (one
line), **but it is part of the look the owner approved as option A**, so it wants a
deliberate decision rather than a quiet tune. `normal_scale` is kept because finer normal
relief is right on its own merits and it is opt-in (defaults to 0.0 = "use `texture_scale`",
so the shader with no config is exactly the shipped look and no colour of option A is
touched).

### Not attempted at all

- **The green wedge on the mesa flank at 01/05.** It is the arrival road's own shoulder
  ridge climbing the slope, drawn in the flat `upland` material with a hard straight
  silhouette against rock. Making it read as ground is a ground-cover/material job in
  `_dress_ground_cover_finish` and `ENVIRONMENT_MATERIALS.ground` — **the dressing lane's
  files**, explicitly out of this lane.
- **Faceted terrain at 03/06/08.** Same root: `_route_ridge`'s wall bands. Not attempted for
  the collider risk above.
- **Near-black rock on unlit faces.** `sky_profile.energy` 1.30 lifted the landmark masses
  out of literal black (they sampled (22,15,8) before), but a face away from the sun still
  has only ambient. Going further means the scene's own `ambient_light_sky_contribution` in
  `cloudreach_cliffs.tscn` or a rim term in the cliff shader — the first is outside this
  lane.

### One thing verified as NOT a regression

The round-3 judge's worst defect was frame 11's "exposed terrain backface … a flat dull
grey-brown plane, then sky" right of the black slab. **I cropped the identical pixels in the
before-frames and it is present there too** — it is the route shoulder's outer wall seen
slightly from above with no cliff face under it, pre-existing on the branch point. It became
more visible only because the frame got brighter and the horizon behind it gained contrast.
Do not chase it as something this branch broke.

---

## 7. Files touched

| file | what |
|---|---|
| `scripts/world/cloudreach_world.gd` | `_build_cloud_decks`, `cloud_sheet_height_at`, `_region_tiers`, `_tier_height_at`, `_add_cloud_sheet`, `_add_cloud_billows`, `_build_distant_relief`, `_is_airborne_mass`, `_emit_mesa_root`, `_build_island_mist`, `_crown_terrace_at`, `_unshaded_material`; haze/cloud materials in `_build_materials`; `material_key` on `_visual_rock_mass`; outcrop and shelf depth clamps; route shoulder edge drop; `key_glow` |
| `scripts/world/cloudreach_look.gd` | the compounding-fog fix in `_dress_fog`/`_process` |
| `shaders/cloudreach_cliff.gdshader` | `normal_scale` uniform (opt-in, defaults to shipped look) |
| `data/config/cloudreach_visual.json` | `sky_profile` expanded; new `cloud_sea`, `distant_relief`, `island_roots`; `crown_relief` terrace keys; `landmass` route-edge keys; `geology.normal_scale` |
| `data/config/cloudreach_look.json` | `mooring.rope_radius`, `mooring.pylon_drop_m` |
| `tools/_probe_cloudreach_cloud_decks.gd` | new probe (+ `.uid`) |
| `docs/CURRENT_STATE.md` | one appended section (in `ca039784`) |
| `ralph/reports/CLOUDREACH-ATMOS-0906/` | this report, `EVIDENCE.md`, four judge verdicts |

Every tunable is data. `cloud_sea.enabled`, `distant_relief.enabled`, `island_roots.enabled`
are single-flag reverts; `crown_relief.terrace_drop_m` → 0 and
`landmass.route_edge_drop_min_m`/`_range_m` → 4.0/9.0 revert C3 exactly; deleting
`geology.normal_scale` reverts the shader to its shipped behaviour.

## 8. Environment notes for the next session

Nothing is preinstalled in this container: no repo (clone it) and no Godot. Install:

```
mkdir -p ~/godot-bin && cd /tmp && curl -sSL -o godot.zip \
  https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -oq godot.zip && mv Godot_v4.7-stable_linux.x86_64 ~/godot-bin/godot && chmod +x ~/godot-bin/godot
cd <repo> && ~/godot-bin/godot --headless --path . --import      # ~8 min, ~1160 resources
```

`tools/sheet.py` needs `pip install pillow`; the exposure measurements above also need
`numpy`. Costs measured here: a four-stand render ~11 min, a world smoke ~2–4 min,
`smoke_cloudreach_look` ~9 min (the turf fill is 15 s of it), the wild-performance probe
~12 min, a blind judge round ~8–9 min. Never two Godot processes at once.
