# Gate F — defects lane log

Branch `ralph/GATE-F-DEFECTS`. Tier 1 of
`ralph/COORDINATION_2026-08-27_POST_PHASE_B.md`, running parallel to the rig
lane. Nothing under `tools/gate_f/**` is touched by this lane.

Source items: `ralph/reports/gate-f-phase-b/FINAL_BACKLOG.md` (on
`origin/ralph/GATE-F-PHASE-B`; not present on `main` at the time of writing, so
it is read with `git show`).

Every claim below is a file, a config value, a container measurement or a frame
rendered in this container on llvmpipe. Composition, colour and silhouette are
trustworthy in those frames; **frame times are not**, and device frame rate,
GPU, VRAM and thermals are [OWNER-ONLY] and are never claimed here.

---

## `GF-B-010` — NPCs render as unlit black silhouettes in daylight — **ROOT CAUSE FOUND, FIXED**

### The cause

**Every one of the six humanoid rigs imports as a fully-rough metal.**

glTF 2.0's default for an **absent** `metallicFactor` is **1.0**, not 0. Read
straight out of the JSON chunk of all six .glb files:

| rig | `metallicFactor` | `roughnessFactor` | metallic/ORM texture |
|---|---|---|---|
| `trainer_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `grandpa_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `villager_male_lod0.glb` (2 materials) | absent → 1.0 | absent → 1.0 | **none** |
| `villager_female_lod0.glb` (2 materials) | absent → 1.0 | absent → 1.0 | **none** |
| `warden_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `grunt_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |

Confirmed as imported, in engine, via `tools/_probe_npc_materials.gd`:
`metallic=1.00 roughness=1.00` on every body surface of every rig.

A metal has **no diffuse term at all**. Its only response is a specular lobe,
and roughness 1.0 spreads that lobe over the whole hemisphere until it returns
almost nothing. So the body renders near-black whichever way the sun points —
which is exactly why the coordinator's sun-azimuth hypothesis could not explain
it, and why the same frame's grass, trees, terrain and props are fine.

### Why the props in the same frame are the proof, not the counter-example

They omit `metallicFactor` too. Measured in engine:

| object | `metallic` | metallic texture |
|---|---|---|
| `Crate_Wooden.gltf` surface 0 | 1.00 | `T_Trim_Furniture_ORM.png`, blue channel |
| `Crate_Wooden.gltf` surface 1 | 1.00 | `T_Trim_Metal_ORM.png`, blue channel |
| `creature_bramblebun_lod0.glb` | 1.00 | `..._metallic_roughness.jpg`, blue channel |

Their per-texel blue channel multiplies that 1.0 back down to dielectric. Every
Tetherbound creature .glb is in the same position. **The six humanoid rigs are
the one class in the project that carries a metallic factor with no texture to
modulate it** — which is precisely the condition the fix tests for.

### The A/B

`tools/_probe_npc_metallic_ab.gd`. Six rigs plus a wooden crate as the control,
under the game's own `art.json` `day` block applied by `world_look.gd` — not a
hand-made sun. Both halves are built through `character_model.gd`, and the
BEFORE half differs from the AFTER half by exactly one property, so the
comparison cannot be about the height fit, the hair part or the accessories.

- `before-as-imported.png` — six jet-black cut-outs, correctly lit crate a metre
  away. This reproduces the coordinator's frame in a controlled scene.
- `after-character-model.png` — every rig shows folds, straps, boots, hair, the
  Warden's coat and the grunt's oxblood. Crate unchanged.

### The fix

`scripts/characters/character_model.gd`, two changes:

1. `_apply_palette()` now walks **every** character, not only the tinted ones.
   The four rigs that needed the correction most (trainer — which is also the
   PLAYER's own body — Grandpa, the Warden, the grunt) declare neither `palette`
   nor `tint` and so returned before touching a material. An absent tint reads
   as the identity multiply `#ffffff`, which `art.json` already writes
   explicitly for all five villagers, so no colour changes anywhere.
2. `_shared_variant_material()` sets `metallic = 0.0` when the source material
   has `metallic > 0` and **no** metallic texture, and only when the caller's
   `finish` dict did not ask for metal itself. A rank badge that deliberately
   asks for a specular falloff keeps it; a rig that later ships a real ORM map
   keeps whatever that map says.

Roughness is deliberately left at the imported 1.0. It is the same absent-
default, but a fully rough dielectric is correct matte cloth, and picking a
sheen for six rigs is a look decision this defect does not license.

### Regression coverage

`tests/test_character_metallic.gd`, four tests, 27 assertions. Asserts against
`config_for()`'s real production configs rather than a fixture — the defect was
in what the shipped rigs import as, and a fixture would have passed throughout.
Verified to actually fail without the fix: reverting the one assignment turns
`test_every_rig_body_surface_builds_dielectric` red and leaves the other three
green.

`tests/smoke_art.gd` and `tests/test_character_hair_split.gd` /
`test_character_lying.gd` pass unchanged.

### Two findings this turns up, recorded rather than acted on

- **The rank value ramp exists to compensate for this bug.** `smoke_art.gd`'s
  own comment records that Team Tether's palette was rebuilt as
  grunt `#8a8a8a` → officer `#c2c2c2` → captain `#ffffff` because the old bottom
  rung (`#4a5049`) "was crushing Team Tether NPCs to black on screen". So was
  every other rung; the body had no diffuse term. With the metal corrected that
  ramp is now brightening bodies that no longer need it, and the faction may
  read washed. Re-judging it is a look decision, not this defect, and it needs a
  visual pass rather than a number.
- **`character_model.gd`'s emission prose is stale.** The long `NP2` /
  `STRANDED-P3` comment describes rigs whose materials ship
  `emission_enabled = true` with an emission texture. Measured on today's six
  .glb files: `emission_enabled` is **false** on every one, `emission_texture` is
  null, `emission_operator` is 0. The rigs were rebuilt since. The block is dead
  for every character in the game today. Annotated in place rather than deleted —
  it is still correct for a rig that does arrive carrying emission, and it is the
  only written record of why an emission floor has to be additive.

### In-world confirmation

Same viewpoints, `tools/_probe_grass_pass.gd`, before and after the fix, day
pinned and frozen. `docs/evidence/gate-f-defects/GF-B-010-inworld/`.

**Band 4, high pasture, an NPC about a metre from the player.** Before: a
jet-black cut-out with only its rank badge readable, beside a dull player.
After: a Team Tether officer in oxblood with a cap, a mask, a chest badge,
gloves and boots, beside a player whose satchel, collar and jacket all read.
This is the frame `GF-B-010`'s acceptance criteria ask for.

**Band 2, forest floor.** The player's median luminance over its own image
region goes **9.9 → 64.9** (max 207 → 231). That is the same rig, the same
frame position, the same sun.

The band-2 NPC, ~35m away, moves much less (median 0.0 → 4.1) and still reads
dark at normal exposure. That is a SECOND cause and it is worth stating
separately rather than folding into this one: brightened 3.2x, the same crop
shows a complete, correctly shaded figure — cap, face, cross-straps, badge,
belt, boots. The materials are right; the surface is genuinely very dark.
`grunt_lod0_texture_0.png` measures mean luminance **0.148** against the
trainer's 0.280 and Grandpa's 0.309, and the rank palette then MULTIPLIES it
(grunt `#8a8a8a` = 0.54), so the body lands near 0.08. See the note below on
the rank ramp: it is a look decision, it needs a visual pass, and it is a
different item from this one.

### Status

**Fixed, pushed, and confirmed in-world.**

---

## `GF-B-005` — quickbar shows d-pad badges, not contents — **FIXED (the half that is not owner-blocked)**

### What was in the frame

Five slots, each drawing the binding badge at 36px on the TOP line and the item's
own icon at an inlined 28px beneath it. So the largest, first-read element in
every slot was the button, and on a controller four of the five buttons are d-pad
directions.

`HIST-018`'s finding is the other half and it stands: every d-pad variant in the
Kenney pack (Default, Double, `_outline`, `_round`, Xbox, Gamecube) uses the same
plus-sign-with-one-differentiated-arm, none of them readable at true render size,
and `Generic/` has no d-pad art at all. **Replacing that art is owner-blocked** —
`CLAUDE.md` forbids spending a generation without owner-supplied reference art,
and the register's ruling is that no suitable asset exists. Not attempted here.

### The fix

`playground_hud.gd::_update_hotbar()`: the item icon leads at `HOTBAR_ICON_PX`
(64, was an inlined 28) and the badge moves under it with the count. The badge
keeps `HOTBAR_GLYPH_PX` (36) rather than shrinking to make the point — 36
authored is exactly `MIN_PHYSICAL_GLYPH_PX` at the Ally's content scale
(36 × 0.667 = 24), so it is already at this HUD's legibility floor.

Three stacked lines at 64 + 36 + 36 do not fit a 152px slot, so the slots grew to
180 (`playground_hud.tscn`). Width could not give: `smoke_prompt_hotbar_dock.gd`
fails the build if the dock reaches the central 440px focus lane, and it measured
172px of clearance below the dock, which is what the 28px comes out of. That test
passes on the new height, reporting the gap still at 172px.

### Evidence

`docs/evidence/gate-f-defects/GF-B-005-006/`, 1920×1080, gamepad pinned, a
stocked bar (orb ×10, potion ×3, berries ×12, revive ×2, axe 40/40 — the axe
because a tool draws a durability pair, the widest thing a slot ever holds).
Before: five near-identical crosses over item art too small to identify. After:
orb, potion, berries, revive and axe are each identifiable, with the binding
underneath.

---

## `GF-B-006` — team roster over the centre of the screen — **FIXED**

### What was in the frame, and why

`TEAM 0/5` and five `OPEN SLOT` rows, 250×540, at x 505–755 on the authored
1920 canvas. Two separate faults:

1. **It revealed with an empty roster.** `_update_party_strip()` calls
   `show_strip()` on any change to the party's index, revision or called-out
   state — including the first poll after the HUD mounts, when the change-guard
   is still comparing against its `-999` sentinel. With no creatures caught that
   put five empty slots on screen at world load, and it is the player's state for
   the whole opening, from the first step out of the village until the first
   catch.
2. **Where it rested.** The HUD-POPUP pass had moved it to "its own screen
   region" to the right of the creature panel, fixing a real compositing defect.
   The panel's real width is 435, so that region begins at x 505 — and the
   central third begins at 640. It also crosses the full-height 440px
   trainer/camera focus lane that `smoke_prompt_hotbar_dock.gd` already forbids
   the hotbar from touching.

### There is no third region

Measured at the authored canvas: creature panel x 56–491; minimap x 1624–1864,
y 56–296; objective block x 1444–1864, y 310–480; bottom dock from y 620.
Anything placed right of the creature panel and wide enough to hold a species
name at this HUD's legibility floor is inside the central third by construction.

### The fix

- **Empty rosters do not reveal.** `update_from_party` still runs, so the rows are
  current the moment the first catch gives the strip something to say — and that
  catch is itself a `revision` change, so it reveals then, which is the right
  moment.
- **The strip returns to the left column**, bottom-aligned a gap above the vitals
  cluster's backing plate. Two changes make it fit: each row lays the name, level
  and status tags on ONE line instead of two (`TOTAL_HEIGHT` 540 → 370, no font
  size changed and nothing dropped), and the single-creature panel stands down
  for as long as the reveal is up (`_yield_creature_block_to_party_strip()`).
- Rows widen 250 → 420 to pay for the one-line layout. A first render of the
  change photographed the roster reading "Te / Rip / Lv 1 KO / Bro / Tus" — every
  name elided to its first syllable, worse than the defect. At 420 the name gets
  ~220px against the ~238 it had on its own line before, so no name that fitted
  before stops fitting. 56 + 420 = 476, and the central third starts at 640.
- **Glyph language**, the item's second half: `party_cycle` had a gamepad glyph
  and no keyboard one, so the persistent exploration legend drew `M` / `I` / `R`
  as keycap images beside a bare bracket `[C]`. `keyboard_c.png` extracted from
  the already-vendored CC0 Kenney pack (`docs/ASSET_LEDGER.md` carries the row);
  the binding really is C, the keycap was simply never pulled.

### Two things this turned up

- **`TOTAL_HEIGHT` was a lie waiting to happen.** A `PanelContainer` grows past
  its `custom_minimum_size`, so a declared row height under the real one makes
  every bound derived from it wrong. Measured with real entries, the rows report
  62 (selected, which carries a border), 60 (showing the KO badge) and 58
  (vacant); `ROW_SIZE.y` is now the largest of those, not a guess at the common
  one. A first render at 58 drew the fifth row 10px into the vitals plate.
- **The vitals plate is drawn outside the vitals rect.** 8px on every side, and
  it is what the player sees. Every rect check in the suite was against the
  CLUSTER, so the overlap above passed its tests. Named as
  `VITALS_PLATE_OVERHANG` and used by both the plate and the strip's bound.

### Regression coverage

`test_hud_widgets.gd` gains `test_party_strip_clears_the_centre_of_the_viewport`
(the central third AND `smoke_prompt_hotbar_dock.gd`'s own 440px focus lane, so
the two widgets are held to one rule) and
`test_party_strip_fits_the_left_column_above_the_vitals_cluster`.
`test_party_strip_no_longer_overlaps_the_creature_panel` is replaced rather than
deleted: the two now share a rect on purpose, so
`smoke_hud_handheld_legibility.gd` checks MUTUAL EXCLUSION on the live scene
instead — reveal the strip, pump frames, the panel must be gone. That is
strictly stronger than disjoint rects, which still both draw. Verified
non-vacuous: disabling the stand-down turns it red.

Passing: `test_hud_widgets` (28/110), `smoke_hud_handheld_legibility`,
`smoke_prompt_hotbar_dock`, `smoke_exploration_legend`, `smoke_hud_no_sixth_slot`,
`smoke_dpad_hotbar_vs_cycle`, `smoke_satchel_owns_hotbar`.

`HIST-036` (`OBJECTIVE-HINT-ON-HUD`) was sequenced after this item and is now
unblocked.

---

## `GF-B-013` — signpost text does not read — **FIXED**

### The cause

Two numbers, and the second one is the loud half.

`_label_scale()` fits the label to the plank, so the board's dimensions ARE the
text size. At `ARM_LENGTH` 0.95 × `ARM_HEIGHT` 0.16 the two constraints bound
almost exactly together for a real destination name — "Watchtower Spur" fitted at
0.00261 m/px by width and 0.00207 by height, so ~7cm letters on a sign the player
is expected to read at walking speed.

But the reason it read as a *smear* rather than as *small* is `outline_size = 10`.
`Label3D`'s outline is in the same font pixels as `font_size`, so 10 against a
48pt face is an outline ~21% of the em thick, growing outward from every contour —
including the inside ones. It floods the counter of an `o` or an `e` shut and
closes the gaps between adjacent letters, so a word stops being letters and
becomes one pale blob with dark marks in it. Bigger boards alone would not have
fixed this: the ratio is what breaks, and the ratio does not care how large the
glyphs are.

### The fix

`scripts/world/signpost.gd`: `outline_size` 10 → 4 (~8% of the em — still a
legibility edge against both the pale sky and the dark structures these labels
cross, which is the job it was added for), `ARM_LENGTH` 0.95 → 1.20,
`ARM_HEIGHT` 0.16 → 0.24, and the text's share of the board 0.62 → 0.68.

`POST_HEIGHT` is untouched at 2.35. R9.4 cut this assembly down after a blind
critic measured it ~1.5x oversized against the 1.4m well beside it, and that
ruling stands — a 0.24m board on a 2.35m post is the proportion a real fingerpost
carries. The four arms still clear each other (`ARM_SPACING` 0.44 − 0.24 = 0.20m
of air) and the topmost still sits under the post cap.

### Evidence

`docs/evidence/gate-f-defects/GF-B-013/`, band 4 high pasture, same viewpoint
before and after. Before: `ntchtoxxer` — letters merged, counters gone. After:
`Watchtower Spur`, every letter distinct. (The leading `W` sits behind the post
from this exact camera, which is a property of reading a fingerpost from beside
its post; the label runs post-to-tip on this face by design — see `_build_arm()`'s
own comment on why each face reads left-to-right from its own side.)

---

## `GF-B-001` — ~50 s frozen screen on New Game — **MEASURED AND ATTRIBUTED on current `main`; not yet reduced**

### The re-measurement the coordinator asked for

`tools/_probe_new_game_stall.gd`, headless (renderer OFF — the same
configuration Phase B measured in, and the reason no GPU change touches this).
Drives the real front door: the configured title scene, its own focused Start New
Game button, activated through the same physical joypad binding
`tests/smoke_title_new_game.gd` uses.

**The grass field did NOT fix it.** Press → settled on current `main`, grass ON:
**40,954 ms**. Phase B measured 49,230–50,720 ms with the field off. It has moved
some, in this container, and it is still the better part of a minute.

One correction to how this has been described: **"press → world in tree" is
2,214 ms and means nothing.** `playground_world.gd::_ready()` awaits
`process_frame` twice while Terrain3D builds its data, so the scene is in the
tree long before it has stood up, and everything expensive happens after. The
honest figure is press → settled.

### Where it goes

`scripts/boot/boot_log.gd` grew a `phase()` alongside its existing `line()`, so
each boot line now carries the cost of the step that just finished, and
`boot_phase_ms()` hands the same figures back in-process. The world, the water
build and the settlement build are marked up. One measured launch:

| ms | % | phase |
|---:|---:|---|
| 10,120 | 26.6% | vegetation scatter |
| 9,384 | 24.6% | **water: river** |
| 5,763 | 15.1% | **water: shader material + height bake** |
| 3,698 | 9.7% | **water: pond** |
| 3,422 | 9.0% | terrain `data_directory` assigned |
| 2,089 | 5.5% | settlement remainder (signpost, landmark, perimeter, harvest nodes) |
| 975 | 2.6% | settlement: grandpa house |
| 643 | 1.7% | ground materials/shader |
| 611 | 1.6% | settlement: props |
| 392 | 1.0% | settlement: village NPCs |
| 341 | 0.9% | settlement: village |
| 294 | 0.8% | water: jetty |
| 241 | 0.6% | first frame presented |
| <60 | | shoreline fan, shore flora, dressing, stream, terrain node |
| **38,079** | | **total of the phases** |

**`HIST-085` points at the scatter, and the scatter is a quarter of it. Water is
19,230 ms — half the stall — and nothing in the register has ever looked at it.**
The single largest line item in the whole boot is `_build_river()`.

### What is not claimed

These are container numbers on llvmpipe with the renderer off. They are directly
comparable to Phase B's, which were taken the same way, and they are **not** a
device measurement — boot time on the ROG Ally is [OWNER-ONLY].

### Status

Instrumentation landed; the stall itself is not yet reduced. The next pass has a
ranked target list and a probe that reports whether a change moved the number.
