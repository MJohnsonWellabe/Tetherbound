# CLOUDREACH-ATMOS-0906 — evidence

Branch `claude/art-cloudreach-atmosphere-0906`, cut from
`claude/second-biome-art-plan-470zru` at `6900f553` ("Cloudreach ground: the flat green
crowns, and grass that stops at a rim (C1)"), which is the tree that already carries the
main merge, cliff option A, the realm-wide turf fill and crown relief.

## 0. Did the judge stop naming the gap?

That is the acceptance bar, so it goes first. Both verdicts are committed here in full
(`JUDGE-before.md`, `JUDGE-after.md`) with the two interim rounds that redirected the work.

| gap | before, in the judge's words | after, in the judge's words | closed? |
|---|---|---|---|
| **C5** floating islands | "it has no underside, no roots, no mist, no anchor — it reads as **a mesh that lost its parent and is a bug** to any player who sees it"; "four or five **detached rock blobs hanging in the air beneath it** connected to nothing" | asked directly whether it is authored or a rendering failure: "**authored, not a rendering failure.** It has a deliberate, non-random silhouette ... and a cluster of small clouds is placed deliberately beneath it. **Failures do not produce that shape or that supporting detail.**" It no longer appears in the after-judge's list of things that read as broken, and the falling debris is not mentioned in any round after the fix. | **yes** |
| **C4** thin horizon | "past the grass edge, there is a flat pale blue-grey void — **no distant ranges, no lower cloud deck, no further spires, nothing**"; "in a region named for reaching clouds, there are **no clouds**" | cloud below eye level: "**yes in three, no in one**" (01, 02, 11 yes; 04 no). Terrain lower than the player: "**yes in three, no in one**". Haze band: "partial, and absent where it matters most". But: "even where present they are rendered as **flat cutouts**, so the horizon carries *layers* without carrying *depth*", and "the cloud sea is opaque white cardboard". | **partly** |
| **C3** never shows a cliff | "the whole habitable world stopping at a grass edge with flat grey nothing beyond"; "no drop, no valley below, no cloud layer beneath the player" | "**No, and no.** In all four frames the player stands in the middle of a broad, gently rolling green field." | **no** |

The honest reading: **C5 is closed on the charge that was made.** The island was called a
bug and is now called authored, by a judge asked the question directly and blind. C4 moved
from "nothing on the horizon" to "the layers are there but they read as cardboard" — real
movement, an unclosed gap, and a differently-shaped one. **C3 did not close at the judged
stands, and §6 says why.**

The exposure finding the before-judge made its own single largest point of — "the
references have a top end; these frames do not" — is closed on its own numbers; see §4.

## 1. Ground truth — the non-negotiable gate

`tests/smoke_cloudreach_ground_truth.gd`, run on this box at both ends of the change.

| | samples | holes | mismatches | buried | crown triangles |
|---|---|---|---|---|---|
| **before** (branch point) | 41,219 | **0** | 33 | 914 | 727,157 |
| after (C3 terraces + C4 + C5) | 41,219 | **0** | 33 | 920 | 727,157 |
| **after** (final, + shoulder edge) | 41,219 | **0** | 33 | **888** | 727,157 |

```
CLOUDREACH GROUND TRUTH: colliders=2012 trimesh_colliders=1783 trimesh_triangles=727157
CLOUDREACH GROUND TRUTH: 41219 sample points checked, 0 holes, 33 height mismatches (>0.15m), 888 buried under visible geometry
CLOUDREACH GROUND TRUTH: mismatch rate 0.08% (holes + mismatches over samples)
CLOUDREACH GROUND TRUTH: PASS
```

**Zero new holes. Zero new mismatches. Zero change in crown triangles.** Buried moved
twice and ended up *better* than the baseline: the C3 crown terraces put six more road
samples fractionally under their own crown (914 → 920), and then deepening the route
shoulder's outer edge dropped 32 samples out from under geometry that had been over them
(920 → 888). Buried is "this sampled surface lies under other VISIBLE geometry", not a
defect either way.

Crown triangles are unchanged because the terraces move crown *heights*, not the crown
subdivision: `_crown_steps` derives ring count from `mesh_step_m` and the band's span,
neither of which this touches.

The reason nothing moved: every terrace metre goes through `_crown_relief_at`, which is
the shared height model `_mesa` emits its VISIBLE crown and its COLLISION copy from, and
which every shoulder reaches through `_walkable_height`. Nothing was written into a single
emitter, so the render cannot walk away from the collider — the hole/sink class
OP-0905-24/25 closed stays closed.

## 2. Frame time

`tools/probe_cloudreach_wild_performance.gd`:

```
CLOUDREACH WILD PERFORMANCE COMPLETE: 12 phases, 0 failures

frame_interval_ms across all twelve phases (600-sample windows):
  mean  16.6650 - 16.6680   (baseline at the branch point: 16.67)
  p50   16.658  - 16.674
  p90   16.741  - 16.904
  p99   16.836  - 18.313    (baseline: ~17.8)
-> ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json
```

Baseline on the branch point was 16.67 ms mean / ~17.8 ms p99 with 0 failures. Held: the
mean is identical to three decimal places and the worst p99 across twelve phases is
18.313 ms against a ~18 ms bar.

Render cost per stand, from the capture tool's own `performance.json` (this is software
GL, so the *times* there are meaningless — the counters are not):

| stand | draw calls before → after | primitives before → after |
|---|---|---|
| 01-arrival-first-reveal | 5473 → 5495 (+0.4 %) | 8.02 M → 8.27 M (+3.1 %) |
| 02-broken-causeways | 3866 → 3899 (+0.9 %) | 6.65 M → 6.98 M (+4.9 %) |
| 04-high-roost-before-fly | 625 → 640 (+2.4 %) | 1.91 M → 2.13 M (+11.6 %) |
| 11-aerie-ground-connection | 678 → 703 (+3.7 %) | 1.93 M → 2.20 M (+13.9 %) |

The two cloud sheets are one draw call each and the 760 billows are one MultiMesh, which
is why a layer that covers the whole realm costs a couple of dozen draw calls. The
primitive rise is concentrated in the two sparse stands, where the new layer is a large
share of a small frame; on the dense stands it is under 5 %.

## 3. Smokes

| suite | result |
|---|---|
| `smoke_cloudreach_foundation` | OK — `regions=6 landmarks=12 bridges=5 player=(0.0, 105.03, -260.0)` |
| `smoke_cloudreach_look` | OK — `bridges_rails=14 posts=798 moorings=9 cover_main=128310 cover_far=24615 cover_alpine=4194 cover_fill=171007 trees=86 stones=79 settlement_overrides=420 guy_ropes=16` |
| `smoke_cloudreach_ground_truth` | PASS (above) |
| `smoke_cloudreach_arrival_walk` | OK — `CLOUDREACH ARRIVAL WALK OK player=(-275.156, 180.030, 517.478)` |

## 4. Exposure, measured before spawning a judge

Trap 9 of `docs/HANDOFF_2026-09-06.md`: the blind judge reads exposure off the PNG, so
measure it first. Rec.709 luminance percentiles and mean saturation over the whole frame:

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

The BEFORE judge measured this independently and made it its single largest finding
("the references have a top end; these frames do not"). The after set is inside the
reference band on both the top decile and the top percentile, and its saturation has
come *down* toward the references rather than up — the "saturated and dark at the same
time" combination the judge named is gone.

## 5. What changed, and why

### C4 — the horizon was thin

1. **A cloud sea that follows the land** (`cloudreach_world.gd::_build_cloud_decks`,
   `visual.cloud_sea`). The realm already had a `CloudSea` plane, but it is pinned at
   `world_bounds.min_y + 18` = −182 because `cloudreach_world_runtime.gd` measures the
   fall-recovery kill plane off that node's own Y — moving it moves the kill plane. It is
   also 340–1340 m under every stand. That plane is untouched. The new layer is two
   sheets whose height at each cell is the local region tier minus 250 m, clamped under
   anything `ground_height_at` knows is walkable, with 520 lit cumulus billows riding the
   upper one in a single MultiMesh.

   The tier model reduces the six authored region crowns to a **non-decreasing envelope**.
   That is not cosmetic: `high_roost_sky_shrine` sits at z=2920 y=1020 between
   `windscar_ravine` (z=2850, y=470) and `upper_cloudreach` (z=4200, y=850), and
   interpolating straight through it spikes the model to 1020 exactly where the stands at
   z≈3260 stand at about 610 — which would have hung the sheet 115 m *over* the player's
   head. `tools/_probe_cloudreach_cloud_decks.gd` exists because that failure is invisible
   in every counter the smokes print and glaring in a picture that costs eleven minutes:

   ```
   CLOUD DECK PROBE  stand                            ground      cloud        gap
   CLOUD DECK PROBE  01-arrival-first-reveal              105.0      -90.0      195.0
   CLOUD DECK PROBE  02-broken-causeways                  330.0      122.0      208.0
   CLOUD DECK PROBE  04-high-roost-before-fly             596.3      325.1      271.2
   CLOUD DECK PROBE  06-summit-final-approach            1160.0      905.0      255.0
   CLOUD DECK PROBE  11-aerie-ground-connection           610.0      319.4      290.6
   CLOUD DECK PROBE  worst clearance 195.0 m at 01-arrival-first-reveal
   CLOUD DECK PROBE OK: the sheet is below every authored stand
   ```

   It reads `cloud_sheet_height_at`, the same function the sheet mesh is built from, so it
   cannot report a height the mesh does not have.

2. **Distant lower terrain** (`_build_distant_relief`, `visual.distant_relief`).
   `horizon_ranges` already put ten ranges on the skyline, but every one is a peak *above*
   the player — which is why stand 08 read as "the world ends at a hard grey haze line".
   Twenty-four wide, low masses now sit out past the realm footprint with tops 170–430 m
   *below* the local tier, so a stand on a rim looks down onto them and the cloud sheet
   runs between.

3. **Aerial perspective as a material.** The skyline ranges and the new lower relief wear
   hazed tiers (`haze_near` / `haze_far`) instead of the near geology shader. This realm's
   fog density is deliberately scaled *down* by `distant_fog` to stop the islands washing
   grey, so distance has to be carried by what the far masses are painted with.

4. **The sky.** `sky_profile` was not dressing the Meadows sky, it was flattening it:
   `cloud_lit_contrast` 0.10 against `art.json`'s own 6.0 is what turns a lit cumulus into
   a wisp, and `cloud_sun_gain` 0.35 against 1.1 removes the brightening that gives a cloud
   a top and a base. Both restored and the coverage/altitude/haze retuned. Colours are
   deliberately not set here — this profile is merged into the night and dawn presets too.

5. **A compounding-fog bug, found on the way** (`cloudreach_look.gd::_process`). The realm
   re-applied its fog deltas by multiplying the environment's *current* value by the scale
   every frame. That is only correct while something else keeps resetting the base first —
   and `world_look.gd::_process` returns on its **first line** when its clock is frozen,
   which is what every capture tool calls before it renders. So in the evidence renders
   nothing reset the base and this compounded at 0.55 per frame for 12+ frames before the
   first shutter: **Cloudreach has had effectively no distance fog in any judged frame.**
   Now scaled only when the value is one this function did not itself write, which is
   correct both when WorldLook refreshes the base and when nobody does.

### C5 — floating islands read as flat grey slabs

Three literal causes, all named by the judge in one sentence ("no underside, no roots, no
mist, no anchor"), all fixed:

- **No underside.** `_mesa` closes its crown and its four wall bands and has never capped
  the bottom ring. For a region `CliffMass`, built down to `geology_base_y`, that is free
  and invisible; a `LandmarkLedge` is a 72 m stub in open sky and an open-ended tube.
  `_emit_mesa_root` now gives an airborne mass a tapering root on a quarter-ellipse
  profile down to a keel, wearing the same geology shader as the wall above. Visual only —
  the collision copy is still emitted from the crown alone.
- **The falling pebbles.** `_build_embedded_rock_shelves` measures outcrop `depth` down
  from the crown and never bounded it by the mass's own height: on a 72 m monumental ledge
  `9 + 4 × 22 = 97` put four of thirteen outcrops **25–61 m below the bottom ring** —
  loose rocks hanging in open sky under a floating island. The two `i >= 3` shelves did the
  same, reaching local y = −62 against a bottom ring at −36. Both clamped. Only the visual
  ones: `_mesa(..., i < 3)` is the shelf collision flag, and the outcrops have no collider
  at all, so no walkable surface moved.
- **No mist, no anchor.** A collar of soft billows at each airborne base, and the mooring
  lines that already existed were not missing — they were 0.16 m of rope read at 800–900 m,
  under one pixel at 1280×800. Widened to a hawser; the fallback anchor pylon deepened.

"Airborne" is `LandmarkLedge` whose base sits more than 120 m above `geology_base_y`, so
every region mass — built down *to* that datum — is excluded automatically and pays nothing.

### C3 — a region named for cliffs never shows one

`_crown_terrace_at`, in the shared height model beside the existing waves. The waves give a
crown texture, not structure: ±4.5 m over a 150 m radius is invisible from a stand. The
terraces step a crown down from its centre to its rim in three broad benches with walkable
risers.

**Down, and never up**, on purpose: `_surfaces` registers a region as one ellipse at its
authored `top`, and `ground_height_at` answers that flat number for the whole disc — so a
crown that rose above it would spawn a loaded player or an evidence camera inside a hill,
while one that falls below it only drops them a little. That is the direction `_mesa`'s
eroded crown already takes.

The terrace carries its own, much wider road suppression (`terrace_line_ease_m` 55 m against
the waves' `LINE_EASE_M` 6 m): 15 m of drop recovered over 6 m would be a wall across a
ribbon's shoulder. `min_radius_m` dropped 40 → 28 so the rugged spur crowns that flank
every road (crown span 31–43 m) are shaped too; a `LandmarkLedge` (span 20.7 m), a
transition ledge (20 m) and every landing pad stay under the threshold and are untouched.

**Honest limit.** Of the three beats the brief names, only the summit approach (stand 06)
and the upper cliffhold (stand 08) actually stand on a region crown; the arrival reveal
and the causeway stands sit on route shoulders between regions, which are governed by
`_route_ridge` and already drop 4–22 m at their outer edge. What those two stands were
missing was not relief under the player but anything to see below the edge, which is what
C4 supplies. The terraces change every region silhouette in every frame; they do not put a
new drop under stands 01 and 02.

### §5.2 leftovers

- **The sky-bleed slab at stand 01 — fixed.** `RealmKeyGlow` is a 7 m × 0.45 m bar wearing
  the shared `heart` material at 1.35 emission energy. Seen edge-on it blows straight
  through the day exposure and reads white, which is the judge's "a pale blue-white slab
  between the gatehouse crenels ... sky showing through a missing roof piece". It and
  `WaterwardGlow` now use `key_glow`: same hue, a third of the energy. The cylinders
  (`BeaconFire`, `MarkerLight`) keep the full-energy `heart` — they are meant to be the
  brightest thing around.
- **The white scratch lines on the landmark masses — addressed.** The cliff shader sampled
  its normal map at `texture_scale` 0.055, one repeat every ~18 m of world, which across a
  46 m ledge stretches one rock normal over the whole face and produces smeared curved
  streaks rather than stone. `normal_scale` gives the normal its own frequency (~4.5 m).
  It defaults to 0.0 meaning "use texture_scale", so the shader with no config is exactly
  the shipped look — **no colour of the owner's option A is touched.**
- **The faceted terrain at 03/06/08 and the flat green wedges at 01/05 are NOT fixed.**
  See §6.

## 6. What this lane did not close

- **The green wedge on the mesa flank at stands 01 and 05.** It is the arrival road's own
  shoulder ridge climbing the slope, drawn in the flat `upland` material with a hard
  straight silhouette against the rock. Making it read as ground rather than astroturf is a
  ground-cover/material job in `_dress_ground_cover_finish` and `ENVIRONMENT_MATERIALS.ground`,
  both of which belong to the dressing lane.
- **Faceted terrain at stands 03/06/08.** Same root: the route ridge's wall bands. Not
  attempted here; it needs `_route_ridge`'s wall subdivision, and moving that is the one
  change most likely to disturb the shoulder colliders the ground-truth gate protects.
- **The landmark masses are still dark on their unlit faces.** Raising `sky_profile.energy`
  to 1.30 lifted them out of black (they sample grey now, not (22,15,8)), because the
  scene runs `ambient_light_sky_contribution` 0.52. Getting further needs the scene's own
  ambient or exposure, which is `cloudreach_cliffs.tscn` / `art.json` and outside this lane.
- **Everything the before-judge raised about creatures, the trainer's bind pose, prop
  dressing and scatter regularity.** Those are the dressing and creature lanes.

## 7. What the after-judge still names that belongs to this lane

Recorded so the next reader does not have to re-derive it from the verdict.

- **"The cloud sea is opaque white cardboard"** (defect 12). The sheets and billows are
  opaque geometry with hard silhouettes. Making them read as cloud needs alpha falloff at
  the billow edge — a soft-particle or fresnel-faded material — not more billows. This is
  the single change that would move C4 from "layers" to "depth".
- **"Frame 04 has no haze band whatsoever ... no cloud below eye level ... nothing lower
  than the ground under the trainer's feet."** Stand 04 looks UP at 24 degrees of pitch
  from the middle of a route crest, so everything this lane added below the tier is out of
  frame by construction. Nothing short of terrain that drops within about 60 m of that
  stand, or a different stand, puts it in shot.
- **"A swirl artifact smeared across the landmark"** (defect 3, frame 11) — still named.
  `normal_scale` was added this round on the hypothesis that the stretched normal map
  caused it; it did not remove them, so that hypothesis is **wrong** and the cause is the
  albedo path instead: `face = abs(sin(x*0.019 - z*0.024 + bend*0.04))` in
  `cloudreach_cliff.gdshader`, where `bend` is itself a sine of a sine. Two nested
  low-frequency sines over a 46 m mass is exactly a concentric swirl. The fix is to weaken
  or replace that term — one line — but it is part of the look the owner approved as option
  A, so it wants a deliberate decision rather than a quiet tune. `normal_scale` is kept
  because finer normal relief is right on its own merits and it is opt-in.
- **"An untextured cyan slab on the keep"** (defect 5, frame 01) — still named, though the
  emissive energy is now a third of what it was. An emissive bar on a battlement reads as a
  placeholder at any energy; it probably needs to be inset into the masonry or replaced
  with a lit fixture rather than dimmed further.
- **"Near-black unlit rocks"** (defect 2, frame 11) and the under-lit island (question 3).
  `sky_profile.energy` 1.30 lifted the landmark masses out of literal black, but a face
  away from the sun still has only ambient. Going further means the scene's own
  `ambient_light_sky_contribution` or a rim term in the cliff shader.
- **"Frame 11's edge ... a thin flat-bottomed disc with a visible smooth grey underside."**
  Verified present in the BEFORE frames at the identical pixels — this is pre-existing, not
  a regression from this branch. It is the route shoulder's outer wall seen from slightly
  above with no cliff face under it.
