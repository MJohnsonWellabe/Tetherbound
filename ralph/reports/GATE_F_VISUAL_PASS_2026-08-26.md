# Gate F — visual pass on the X07 world audit, 2026-08-26

**Source frames:** 79 real in-game 1920×1080 captures,
`ralph/reports/gate-f-run-20260825T201354Z/X07/shots/`, contact sheet at
`.../X07/_sheet.png`. Candidate `a3f61b60`. Compatibility renderer under llvmpipe
— which is also the renderer the game ships (D01), so this is the real pipeline,
minus SSAO and volumetrics.

**Method:** `ralph/conventions.md`'s blind-critic rule. The critic saw the sheet,
the frames and `docs/reference/`, and was told nothing about the session, the
build, or what anyone hoped it would say.

---

## Operator caveats — read these before actioning the critique

Three of the critique's findings are **artefacts of how X07 captures**, not defects
in the game. I am flagging them because acting on them would create false work; I
am **not** using them to soften anything else.

1. **"There are no creatures — every HUD reads `TEAM 0/5`."** X07 is a **DIAG**
   segment: it boots a fresh world and teleports between region centres. The player
   therefore has an empty party by construction. The absence of *party* creatures in
   these frames says nothing about the game.

   **What does survive**: across 79 frames of eleven regions, the only *wild*
   creatures visible are two rabbits ~20 px tall and two quadrupeds ~35 px tall.
   That is a statement about world population and it stands.

2. **"`GF-14-COMBAT-13b.png` contains no combat."** Correct, and expected — X07
   reuses shot ids from the §G plan while auditing regions. It is not a combat
   segment. No finding attaches.

3. **"`arrival`, `gameplay` and `landmark` are the same camera in every region —
   they differ by 0.1–2.3% of pixels."** This one is **not** a game defect and
   **is** a real defect: it is a fault in `tools/gate_f/segments/X07.json`, which
   spends three of its six variant slots on one shot. Three regional variants of
   the audit grid are therefore not being captured at all. Instrument bug, logged
   as such.

Everything below this line stands as written.

---

## The critique

### Measured, and the most actionable finding in the set

**Night and weather variants render as midday.** Mean luminance:

| frame | day | "night" |
|---|---|---|
| `grandpas_village-*-arrival` | 96.6 | **99.2** |
| `the_pond-*-arrival` | 82.3 | **82.0** |
| `stronghold_approach-*-arrival` | 110.7 | **110.8** |

Six night frames, zero night. `the_pond-weather-arrival` differs from
`the_pond-arrival` by **2.2% of pixels** — camera drift, not weather. The art
board names DAY and NIGHT as separate panels with separate moods and lists "day
and night create different moods" as one of its five notes.

This is objective, reproducible from the committed frames, and independent of the
renderer.

### Value and palette

- **The trainer renders as a near-black cutout** in `grandpas_village-arrival`,
  `the_pond-arrival`, `stronghold_approach-arrival`, `hall-arrival` — jacket,
  trousers, hair, gloves and boots all in one value; only the shirt panel
  separates him from the ground. At 4× the face has no readable feature and the
  fingers merge into dark talons.
- **The Team Tether grunt in `the_tether_relay-arrival` is 100% silhouette**,
  whose most legible feature is a pair of white shoes.
- **Oxblood has been replaced by teal on Team Tether.** The relay pylons, beams
  and banner plates are the same cyan-teal used for `ACTIVE COMPANION`, the
  minimap player arrow and every friendly HUD frame. The faction reads as friendly
  infrastructure. The board reserves oxblood for Team Tether and nothing else.
- **No cloud in any of 79 frames**; sky is a two-stop vertical ramp with a hard
  horizon band.
- Mean luminance spans 34 (`the_ridgeline_watch`) to 111 (`stronghold_approach`)
  under the same sun — a 3× exposure spread between regions.

### Composition and world-building

- `stronghold_approach-arrival`: six trees, one silhouette, all within a 20%
  height band, evenly spread on a bare hill, one bush. No cluster, no clearing,
  no hero tree, no undergrowth.
- `the_pond-arrival`: treeline runs the crest in strict single file, as if
  scattered along a spline.
- `the_long_water-arrival`: an anvil, a workbench and a barrel alone in open grass
  — no camp, no fire, no worn ground.
- `the_ironwood_grove-arrival`: grass tufts occur in one narrow band and nowhere
  else on the visible floor.
- **Every tree is a lollipop** — full crown on a thin untapered stick with no
  branching, which is why they cannot resolve as trees at distance.
- **Named regions do not contain the thing they are named for**: `the_pond` has no
  pond, `the_long_water` no water, `the_ridgeline_watch` no ridgeline,
  `the_old_quarry` no quarry, `stronghold_approach` no stronghold,
  `grandpas_village` one fence rail. Part framing, part content.

### Artefacts that read as bugs

- A **brown box containing a white square floats above the trainer's head** in
  every day frame of `grandpas_village`. Placeholder.
- `hall-arrival`: a **solid black unshaded sphere in the sky** through the arch;
  windows are black quads with no frame or sill; the interior is untextured
  blockout.
- `the_rise-arrival`: **the camera is inside the hillside**; ~70% of frame is one
  smeared slope with a circular blend seam.
- `the_long_water-arrival`: cobbles are flat discs sitting *on* the grass with
  hard alpha cuts; diagonal chunk/tile seams visible in the ground.
- `the_burrow_warrens-arrival`: the "Stone Gate Spoke" sign intersects the
  trainer's chest; a bare post carries no sign; "Warren Undertrail" is an
  illegible smear. Signs read as debug labels.
- `the_ridgeline_watch-arrival`: a detached branch floats at upper-left; trunks
  lean up to ~20° off vertical.
- Shadows detach — the tree at right of `stronghold_approach-arrival` casts an
  ellipse offset ~40 px from its own trunk.

### HUD

Safe area and legibility are fine; hierarchy is not. The **"MAIN STORY / Catch
your first wild creature" panel is the largest type on screen in all 79 frames** —
larger than the health readout. The `TEAM 0/5` column sits over the play space.
The hotbar is an opaque slab lying across a character in `the_tether_relay-arrival`.
**Glyph sets are mixed** — controller glyphs in one frame, `M / I / R / [C]`
keyboard keys in all the others. Hotbar item icons are white `+` placeholders.

### What is working

The palette family is right — yellow-green olive ground with warm sand paths sits
inside the board's swatch row. `the_burrow_warrens-arrival` is a genuinely
competent composition: raking low sun, long shadows across a dirt path, a treeline
with real depth. `the_ironwood_grove-arrival` has the only tree with real canopy
mass. **The tether pylons are the one asset that clearly reads as authored to a
brief**, and the only thing that resolves at 30%.

---

## The two bar questions

> **A. Do these frames read as belonging to `tetherbound-meadows-keyart.png`?**

**No.** The palette family is close enough that they are not from a different game,
but the board's world has cumulus skies, oak groves with clustered scale variety, a
settlement with houses and a well and a banner, a ruined stone gate hung with
oxblood, and a companion at the player's shoulder. This build has a cloudless
ramp, one tree silhouette evenly scattered, a village of one fence rail, an
untextured blockout hall, and teal where the oxblood should be.

> **B. Beside the Palworld screenshots, would someone say these are trying to be
> the same kind of game?**

**No.** Palworld's frames are unmistakably about creatures at readable size doing
something. A viewer shown both would place these in different genres, not at
different quality levels of one. *(Caveat: X07 cannot stage party creatures — see
operator caveat 1. The wild-population point stands regardless.)*

---

## Split: work vs. purchase

**Fixable by changing the scene**

- Make night and weather states actually apply — six variant frames render as midday.
- Key/fill balance so the trainer and the Tether grunt are not black cutouts;
  separate them from ground by hue as well as value.
- Add a cloud layer, a real sky gradient, and distance haze.
- Return oxblood to Team Tether; pull teal back to friendly/HUD use only.
- Ground-cover density and **clustering** — clearings, thickets, scale variety,
  a hero tree per region. Kill the even scatter and the single-file crest line.
- Cluster props into scenes (the anvil/bench/barrel want a camp).
- Reframe region cameras so the named landmark is in shot; get `the_rise`'s camera
  out of the hillside; make the three variant slots three different shots
  (**and fix `X07.json`, which is why they are identical**).
- Attach shadows to objects; bed the cobbles in; chase the diagonal chunk seams.
- Delete the black sphere in `hall-arrival` and the placeholder above the
  trainer's head; fix the sign placements.
- HUD: demote MAIN STORY below health, move TEAM out of the play space, drop
  hotbar opacity, unify the glyph set, replace the `+` item icons.

**Not fixable without art that is not in the build**

- **Designed Tetherbound creatures.** The photoreal rabbits and wolves in world are
  a third art style agreeing with neither the flat world nor the stylised trainer.
- **The trainer's face and hands** — featureless face, merged claw fingers. Mesh
  and texture, not lighting.
- **Meadows Hall / the stronghold** — untextured blockout with black-quad windows.
- **A tree kit** — one lollipop silhouette carries eleven regions. Needs a second
  and third species, a hero-scale oak, and trunk-to-canopy branching.
- **Grandpa's village** — no village buildings in the region named for one.
- **Signage and small props styled to the world.**
