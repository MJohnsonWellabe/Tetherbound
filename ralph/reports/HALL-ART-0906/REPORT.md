# HALL-ART-0906 — Meadows Hall interior art round

Branch `claude/art-hall-round-0906`, cut from `claude/second-biome-art-plan-470zru`
(`6900f553`). Closes the Meadows Hall half of `docs/HANDOFF_2026-09-06.md` §4.2 —
H1, H2, H3, H4, H5, H7, H8 and the cross-cutting X1 — plus the two §5.2 Hall
leftovers (the arena ivy, the T-03 sconce pool). **H6 (the tether machine) was not
touched**: `assets/environment/team_tether/tether_machine.glb` and
`stronghold.json`'s `machine` block are untouched, and that lane's frames are
named where they still dominate a shot.

Verdicts are in this directory. `shots/` is gitignored, so the frames themselves
are not committed.

- `JUDGE-before.md` — blind verdict on the branch as inherited (`shots/hall_before/`).
- `JUDGE-after.md` — blind verdict on the same three stands after this round.

## The owner's standing correction was the shape of the whole round

> "There is art in the repo for most of these things already, like mushrooms and
> team tether stuff. Find it and use it. Recolor it if you need to. Don't use Meshy."

**Nothing was downloaded and no generation was spent.** The handoff's "Source"
column proposed a KayKit download for H1 and a KayKit banner pack for H3; both
were wrong. `Torch_Metal` — a real iron sconce with a back plate, an arm and a
cup — was already sitting in
`assets_raw/vendor/quaternius_fantasy-props-megakit/glTF/`, as were the 27 other
models this round installed. Installing meant copying the `.gltf` + `.bin` into
`assets/props/quaternius_fantasy/` and running the import: **no textures were
copied at all**, because all 28 reference only the pack's shared
`T_Trim_*` images, which that folder already carried for its first 16 models. The
`docs/specs/ASSET_LEDGER.md` row was written before the files were committed.

X1 (the brazier) was the same story from the other end. There is still no brazier
mesh anywhere licence-clean, and the handoff's own note rules out modelling one.
So a brazier here is **assembled**: a vendored `Cauldron` standing on a vendored
`CandleStick_Stand`, carrying `torch_prop.gd`'s flame without its stick — the
same flame-in-a-basket `_brazier()` has always built — plus the new glow card.

## What changed, gap by gap

### H1 — the torch fixture

`_wall_torch()` no longer builds a bracket, a ring and a 0.78 m wooden brand out
of primitives. It loads `Torch_Metal`, measures the mesh's real bounds and places
it so the cup's own rim lands exactly on the flame point `spec.y` names, then
spans the gap back to the stone with a short iron arm and a wall plate. The arm's
length is **measured, not authored**: `_wall_face_distance()` finds the chamber
the torch stands in and returns the distance from the flame to that wall's inner
face, so the 0.6 m standoff `_comment_wall_torches_proud_0906` won cannot come
apart from the fixture that has to span it.

The `OmniLight3D` and the two-summed-sines flicker are untouched, exactly as
asked. Two things are added on top:

- **A glow card** — a wide, soft, additive billboard on the flame, because the
  before-verdict's finding was not "the flame is dim", it was that at 30 % zoom
  "the torches are two orange smudges with no discernible fixture and the teal
  conduits are the only crisp graphic in the frame". It is drawn with depth test
  and depth write off, so a card wide enough to read at thumbnail size cannot be
  clipped by the wall it is bolted to — that clipping is how an additive quad
  becomes a hard-edged bright wedge.
- **`_warm_the_flame()`** — the two billboards `torch_prop.gd` builds are
  re-coloured per instance to a hotter, more saturated orange. `torch_prop.gd`
  itself is shared with the carried torch and the ground buildable and is not
  this lane's file, so nothing there changed; the Hall overrides its own copies.

Measured: the brightest cluster in T-01 and T-02 is now a **torch** (RGB
236/234/206 and 236/235/208) where before it was a machine panel (238/228/238 and
238/239/239). The fire is the brightest thing in a room whose premise is fire.

### H2 — the empty brick boxes

`hall_occupation.dressing`, 87 props across the three roofed rooms, placed by the
new `_build_hall_dressing()` through the same `_load_prop` path `camp` already
uses. Placement follows `_comment_retrofit_t1_hall_art`'s own standard — a story,
not a scatter:

- **tether_approach** is the garrison's billet and Tether's forward stores:
  bedrolls, ration crates in the camp's own oxblood, a workbench and anvil, a
  peg rack and shelf, a table with books and a pot, and a cage that is not empty
  by accident.
- **warden_arena** is a holding floor. Its dressing is on the WALLS only —
  weapon stands, training dummies, cages, chain coils, benches, a cart — and
  the 11 m combat ring is **enforced in code**: `_build_hall_dressing()` drops
  any entry inside it with a warning, so `test_stronghold_warden_arena`'s
  invariant now holds structurally and not only in data.
- **legendary_chamber** is a research station bolted into a ruin: a book stand
  and a work table where the readings are taken, cages and chains where the
  thing being studied was kept, fallen vases where the building is losing.

Nothing carries a collider, for the same reason the retrofit layer does not.

### H3 — the banner

Three changes, and the first is the one that mattered.

1. **The cloth never told the renderer it was folded.** `vertex()` displaced
   `VERTEX.z` and left `NORMAL` flat, so every fragment received identical light
   and the only variation left was a few-per-cent albedo multiply — which is
   exactly the "max-min range of 3 luma values across 220 rows" the verdict
   measured. The wave now rebuilds the surface normal from its own slope. The
   slope is **damped** (`relief` 0.4): the first render of this fix came back
   with the arena pair pale and the sigil washed out, because the true slope of
   this wave is near 1.0 at the hem and a 45-degree facet four metres from a
   12-energy torch is a specular panel, not a fold.
2. **`drape` and `crease`** — a hem-weighted self-occlusion so the cloth has a
   value gradient down its own drop even where no light reaches it, and a finer
   fold train so an 8 m cloth has creases at a hand's width and not one soft bend.
3. **`pattern` and the reserved oxblood.** The Hall hung two designs on thirty
   banners; there are three now (plain, barred for the arena, chevron for the
   yards' flanks), and the interior cloth is recoloured off `palette.json`'s
   reserved `tether_oxblood` — its hue and saturation exactly, with only its
   value lifted, through `_banner_interior_colour()`. The judge's separate
   complaint was that the arena banners read "a pinkish crimson, not the board's
   oxblood — festival bunting rather than a threat"; `BANNER_COLOUR` #66362c is a
   brick red with a warm ORANGE lean, and under torches whose own colour is
   (1.0, 0.55, 0.16) an orange-leaning red lands as salmon. Exterior banners are
   untouched.

### H4 — the machines that were brightest and cast nothing

Two separate faults were producing one defect, and only fixing both moved it.

- **Energy.** The three siphons author `core_energy` 2.4–3.0; W06-FINALE-0904
  had already measured this project's emissives clipping to white at 2.2 and
  holding hue at 1.15. They were above the clip, which is why an earlier round's
  recolour of the offender "did not fix the offence" — past the clip every hue is
  the same white. Capped at `site.siphon_core_energy_max`, 0.7 after 1.15
  re-rendered still clipping.
- **Casting.** `SiphonGlow`'s attenuation was 1.8 — so concentrated at its own
  origin that a machine bolted flat to a wall pooled on nothing. 1.15 now, plus
  an opt-in warm-neutral practical on the housing of the two machines the stands
  actually frame, so the adjacent masonry sits in the room's torch key.

The core stays PURPLE. The constant's own header argues at length that the purple
is the RIFT's and the teal is Team Tether's, and the judge never complained about
purple — it complained the pane was white, and it was right.

Separately, `_reserve_tether_oxblood()` repaints the retrofit props' `TT_Oxblood`
surfaces to the palette's reserved accent. Authored in Blender at (0.147, 0.023,
0.014), that material is a pure red hue that only reads as oxblood while it stays
dark, and under a wall torch a metre away it does not — which is the "saturated
fire-engine red ring" the verdict found on the arena machine.

### H5 — the flat door and the "white slivers"

The blast shutter was on `_material()`'s **untextured** branch: a flat fill on the
one object at the end of the approach room's vista, measured at per-channel std
0.94. It is textured now, off the same `hall_stone.gdshader` every wall wears, and
`_dress_blast_shutter()` gives it the hardware a Tether shutter should carry — an
oxblood rail top and bottom, two cross-ribs and a slim live line, on both
room-facing faces. All of it is parented to the slab itself, because
`_sync_doors()` opens a shutter by hiding that mesh and anything parented
elsewhere would hang in the empty doorway for the rest of the game.

**The two "stray polygons" were not stray polygons**, and finding that out is what
`tools/_probe_hall_frame_geometry.gd` is for. It rebuilds the capture's own three
camera stands headlessly, casts a ray through a named pixel and reports every
mesh whose world AABB it enters, nearest first, with material. It settled both:

| verdict's finding | what the probe says it is |
|---|---|
| T-02 "hard-edged near-white wedge, bottom-right, peak Y 235–240" | the arena's own **door conduits** — reserved-teal hardware two metres from a 12-energy torch. Not emission: `_interior_live_material()` builds a StandardMaterial3D whose ALBEDO was a near-saturated teal, so the LIT term alone blew it past white. Fixed by darkening the albedo (`site.interior_conduit_albedo_darken`), which leaves the emission — the whole "this cable is live" read — untouched. |
| T-02 "flat unlit maroon plane, 7 % of the frame, Ystd 1.56" | **`StrongholdClimax/TetherReadout/Panel`**, a 1.5 × 1.1 m readout the T-02 camera stands 2.9 m in front of. Not a banner and not a missing material. Not this lane's file — see "left open" below. |
| T-03 "untextured white polygon slivers, x 0–45 y 40–105, Y 240" | **`StrongholdClimax/BoundLegendary/ContainmentVFX/RestraintRing0`**, a 3.88 m teal ring at emission ×1.15, seen edge-on at 9.5 m through the machine's open side. Also not this lane's file. |

### H7 — the grunt reading dark-on-dark

The rim light is the real lever and it is in: an `OmniLight3D` parented to the
BODY, so its offset lands in the figure's own local frame and follows
`facing_deg` for free — the same mechanism `gate_sentries.night_light` already
uses. `character_model.gd` rigs face local −Z, so the light sits at +Z, behind
him, edging the silhouette rather than flattening the face, at attenuation 2.4 so
the pool dies inside a couple of metres and lights a man rather than the wall he
stands against.

The costume recolour was tried through the palette path as instructed, and its
limit is worth recording rather than hiding: `_apply_palette` →
`_shared_variant_material` is a **multiply** over the rig's painted albedo, and
every Team Tether rank already sits at or near white (`npc_ranks.json`: grunt
#dcdcdc, officer #eeeeee, captain #ffffff). A multiply can therefore only move
this figure DARKER, and dark is the defect. What it can do is change the hue, so
the Hall's captain wears a cool steel costume per placement against a room the
judge measured at 96.9 % red-orange chromatic pixels. **A real value-contrast
costume is still an art question and this does not close it.**

### H8 — warm-on-warm fill, re-judged

Round 6 had recoloured the six roofed-room ambients to slate and the shadow tier
was still R/B 13.8. Recolouring could not fix it because it was never a hue
problem: those six sat at y 5–12 in rooms 6.5–22 m tall, up among the coffers, so
most of their output landed on the slab above them — the ceiling measured 10.3×
the floor beneath it. They now sit at roughly a third of each room's height and
carry more energy, and the two in the arena were moved **off the room's centre
line toward the entrance** and given a tighter range, because a light 3.4 m above
a floor lights it at cos ≈ 0.24 and lights a wall it faces at cos ≈ 0.85 — no
energy number changes that ratio, only where the light stands does.

### X1 and the two leftovers

- **X1**: braziers assembled from `Cauldron` + `CandleStick_Stand` + the
  stickless flame + a glow card, six of them across the three rooms.
- **The arena ivy** is motivated rather than deleted: `warden_arena` now carries a
  `roof_breach`, so `_build_ceiling()` builds four slabs around a hole with broken
  beam stubs on its rim and a small cool moon omni under it. The vine band is
  narrowed to cluster under the hole, and a second band hangs over the breach's
  own lip. This also does the job the verdict's top finding asked for: it is the
  one thing that puts a cool complementary field into that room without touching
  a torch.
- **The T-03 sconce pool's hard-clipped boundary** is gone with the conduit and
  ambient work: T-03's floor band went from 11.9 to 23.3 and its share below Y=16
  from 51.3 % to 28.2 %.

## Two measured reversals, kept in the config as comments

Both are recorded where the next person will hit them, not only here.

1. **Lit dressing braziers in the Legendary Chamber made the room DARKER.**
   Floor band 13.3 → 10.3, share below Y=8 27.8 → 31.5 %. That is trap 1 in the
   handoff: the Compatibility renderer drops omnis past `max_lights_per_object`
   on the object carrying the most of them, and a chamber floor is ONE slab
   sitting inside every omni range in the room plus several from next door.
   `smoke_stronghold.gd` counted 12 in that chamber's own box, comfortably under
   16 — but its count is per-config-room and the renderer's is per-object across
   the whole scene. **No dressing fire in the shipped list carries an `energy`.**
2. **Lit braziers at the arena's entrance lit nothing.** They stood at z 79.0 and
   the entrance stand's own eye is at z 79.2, so their pool fell beside and behind
   the camera; the floor band moved 18.3 → 17.9, i.e. not at all.

Both rooms' floors are lifted through the ambients' energy, height, position and
attenuation instead, which adds no omni at all.

## Measurements, before and after

Rec.709 luma on the PNGs, 0–255, measured with `tools/measure/frame_stats.py`
(new, committed) on `shots/hall_before/` and `shots/hall_judge/` — the exact
frames the two blind judges saw. The floor band is the bottom 38 % of rows.

| | T-01 before → after | T-02 before → after | T-03 before → after |
|---|---|---|---|
| full-frame median Y | 35.3 → **38.1** | 23.1 → **25.7** | 15.4 → **26.6** |
| floor-band median Y | 20.6 → **24.2** | 18.6 → **21.1** | 11.9 → **23.3** |
| bottom 60 rows median | 12.1 → **17.8** | 6.7 → **14.0** | 10.0 → **20.1** |
| % of floor band below Y=8 | 18.6 → **8.1 %** | 31.6 → **15.4 %** | 34.6 → **9.8 %** |
| % of frame below Y=16 | 24.4 → **19.5 %** | 34.3 → **30.3 %** | 51.3 → **28.2 %** |
| shadow-tier R/B | 13.8 → **9.6** | 10.2 → **4.3** | 4.9 → **2.2** |
| cool luma share | 2.2 → 0.6 % | 1.4 → **2.3 %** | 15.8 → **6.1 %** |
| brightest cluster | machine panel 238/228/238 → **a torch, 236/234/206** | machine pane 238/239/239 → **a torch, 236/235/208** | 229/236/229 → 232/238/232 (the containment ring, see H5) |

The two bars the brief set are met on every frame: **shadow-tier R/B is under 10
in all three** (9.6 / 4.3 / 2.2, from 13.8 / 10.2 / 4.9), and the teal that was
carrying 15.8 % of T-03's total luma against a frame median of 16 now carries
6.1 % against a median of 26.6 — an accent instead of the key light.

## Tests

Run on the final tree, both first-attempt green. Quoted, not summarised:

```
[stronghold] 87 interior dressing prop(s) in the roofed rooms
[stronghold] 21 exterior omni light(s) at the Hall (budget 22), 11 of them flickering fires
hall braziers: 29 flickering light(s) total (interior + exterior)
  tether_approach  4 torch(es) + 2 ambient omni(s) = 6 omni(s) (cap 16)
  warden_arena     8 torch(es) + 2 ambient omni(s) = 10 omni(s) (cap 16)
  legendary_chamber 6 torch(es) + 3 ambient omni(s) + the machine core = 10 omni(s) (cap 16)

stronghold smoke test passed
```

```
only test_stronghold_warden_arena.gd: 1 of 200 test files
  ok    test_stronghold_warden_arena.gd :: test_duty_board_config_is_a_standalone_readout
  ok    test_stronghold_warden_arena.gd :: test_duty_board_names_the_real_garrison_numbers
  ok    test_stronghold_warden_arena.gd :: test_warden_arena_braziers_stand_outside_the_combat_ring

3 tests, 35 assertions, 0 failed
```

The dressing placer prints `(N dropped inside the arena ring)` when it drops one;
it prints nothing of the sort here, so all 87 stand clear of the 11 m ring.

## Left open, and whose it is

- **H6, the tether machine.** Untouched by contract. It is still the grey-green
  mass filling the left of T-03, and the camera is still inside its AABB at
  0.46 m — the probe says so, and no lighting change fixes either.
- **`StrongholdClimax/TetherReadout/Panel`** fills 7 % of T-02 as a flat unlit
  maroon plane because the arena's entrance stand happens to be 2.9 m in front of
  it. `scripts/world/stronghold_climax.gd`, not this lane's file. It wants either
  a material or a camera that is not standing on top of it.
- **`ContainmentVFX/RestraintRing0`** is the brightest thing in T-03 at emission
  ×1.15 seen edge-on. Same file, same lane. Capping it is a one-line change for
  whoever owns it.
- **Character value contrast.** See H7: the palette path cannot lighten a rig
  that already multiplies by white. Owner reference art, as the handoff says.
- **No creature and no Warden is in frame** in either of the two rooms named for
  them — both blind verdicts said so and both are right. These stands are shot
  pre-fight on purpose, so it is a capture-set question rather than an art one,
  but the Palworld bar is answered with a creature in frame or it is not answered.

## The blind judge, before and after

Both verdicts are in this directory in full. Neither judge saw the code, the
conversation, or what had changed; each was handed the sheet, the three frames
and `docs/reference/`.

### What the after-verdict stopped naming

These are the gaps the before-verdict measured and the after-verdict does not
raise at all:

- **"Rooms are empty brick boxes" (H2).** Before: *"T-01 is a symmetrical empty
  box with two floor props"*, *"the block x 300–1000, y 470–720 — 19 % of the
  frame — is bare cobble"*, *"under 10 % prop coverage"*, *"the survey contains
  four distinct prop types across three frames"*. After: the emptiness finding is
  gone; the frames are now criticised for their props being *generic* and their
  scatter *unclustered*, which is a different and much later complaint.
- **"The doorway is a flat matte quad" (H5).** Before: *"x 591–710, y 257–408,
  RGB 100/58/51, standard deviation 0.94 ... no threshold, no depth, no light
  beyond it"*, in both T-01 and T-02. After: not raised in either frame.
- **"A real torch fixture ... the current one is a bare rod with a pale blob and
  it disappears below about 50 % zoom" (H1).** Before, this was in the
  *needs-art-that-is-not-in-the-build* list. After: not raised — the after-verdict
  says outright *"the wall sconces do work"* and moves its lighting complaint to
  falloff instead.
- **"The white wedge" (H5).** Before: *"T-02, a hard-edged near-white wedge at the
  bottom-right corner, x ≈ 1245–1280, y ≈ 490–560, peak Y 235–240"*. After: gone.

### What it still names, and what was done about it

- **The machine panels (H4).** Before 238/228/238 and 239/239/239, and the
  brightest cluster in two of three frames. After: 215/182/174, and **no longer
  the brightest cluster in any frame** — a torch is. Still named as *"brighter
  than any torch-lit stone"*, so the cap came down again (0.7 → 0.4) with the
  practicals, in the last round.
- **The figure's contrast (H7).** Before 1.02 : 1 (42.9 vs 43.6). After
  **1.15 : 1** (torso 50.4 vs wall 58.2) with the note *"only his helmet
  (Y = 109) separates at all"* — which located the fault exactly: the rim sat at
  y 1.78 on a 1.8 m body, level with the head. Dropped to chest height, widened
  and brightened in the last round.
- **The arena's far wall and banner** read as *"three flat unlit quads ... a
  second sky"*. The pale-pixel count in that quarter of T-02 went 34 003 → 20 970
  across this round's tuning; the ambients were dropped to y 2.6 in the last one.
- **A new finding, and a fair one: the glow cards did not attenuate.** *"Five
  sconce glows: peak luma 237, 240, 239, 240, 240 and half-widths 70, 65, 82, 68,
  83 px, at wildly different depths."* At `glow_energy` 0.9 the additive core
  clipped, so every card rendered as the same saturated white disc whatever its
  distance — a clipped highlight carries no depth information. Down to 0.45.
- **A new finding, also fair: T-01 is mirror-symmetric** (*r = 0.788*, sconces at
  mirror positions within 1–3 px). The east wall's torch pair stepped back 2.4 m
  so neither wall answers the other.

### What it names that is not this lane's

Every one of these was located with `tools/_probe_hall_frame_geometry.gd` rather
than guessed at:

- *"T-02, the untextured oxblood plane, Ystd 0.69, 11 unique colours, occluding
  the left 24 % of the frame"* — `StrongholdClimax/TetherReadout/Panel`, 2.9 m
  from the camera. Read as a banner by both judges; it is not one.
- *"T-03, a floating white chevron at x 0–45, y 55–110, RGB 237/239/239 ... reads
  as a debug gizmo"* — `StrongholdClimax/BoundLegendary/ContainmentVFX/
  RestraintRing0`, a 3.88 m teal ring at emission ×1.15 seen edge-on at 9.5 m.
- *"The T-03 left mass ... intersecting flat planes ... I cannot tell what object
  this is meant to be"* and *"the tether machine ... material language from a
  different game"* — H6, another lane by contract.
- *"No creature in any frame; the Warden is not in the frame named for him."*
  True, and the capture set's own doing: these three stands are shot pre-fight so
  nothing about the finale's staging competes with the torch question. It is a
  real answer to bar question B all the same, and it needs a capture change, not
  an art change.

## What is NOT verified, plainly

The last tuning round — the one that answers the after-verdict's own findings —
**was never rendered.** Its capture was still in its boot/settle phase when the
lane was told to land, and it was killed to free the machine for the gating
tests. So these five values are shipped on argument, not on a frame:

| change | why, and the measurement it is arguing from |
|---|---|
| `glow_energy` 0.9 → 0.45 | the after-verdict measured five glows at peak Y 237–240 and half-widths 65–83 px "at wildly different depths"; a clipped additive core carries no distance information |
| `siphon_core_energy_max` 0.7 → 0.4, practicals 0.85/0.8 → 0.6/0.55 | the machine screens still measured Y 188–194, "brighter than any torch-lit stone" |
| the elite's rim light, y 1.78 → 1.25, wider and brighter | the after-verdict located the fault exactly: "only his helmet (Y = 109) separates at all" |
| the arena ambients, y 3.8 → 2.6 and energy 4.9 → 4.4 | the far wall and banner still read as "flat unlit quads … a second sky" at Ymean 94–110 |
| the east wall's torch pair, z 63/70 → 60.6/67.4 | mirror symmetry at r = 0.788, sconces mirrored to within 1–3 px |

Every one of them moves a measured quantity in the direction the verdict asked
for, and none of them changes geometry or adds a light — but **none of them has a
frame behind it**, and the next session should re-render T-01..T-03 before
treating any of the five as settled. Everything reported above that table *is*
measured, on `shots/hall_before/` and `shots/hall_judge/`.

One other thing was verified and is worth carrying forward: the glow card's
`no_depth_test` was reverted to a normal depth test after the judged render, with
its radius capped against the standoff instead. That change WAS re-rendered
(`shots/hall_verify/`) and moved nothing that matters — T-01 full-frame median
38.1 → 37.3, all three floor bands identical to 0.1 luma, the brightest cluster
still a torch. It is in because leaving it out would have let every torch glow in
the building draw through the masonry into whatever room the camera was in, which
no interior stand would ever have caught.
