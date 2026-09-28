# Fight visuals — C3 verdict (Tidewake trainer fights, round 1)

Reviewed: contact sheets for all three fights, all 27 tell-start frames, all 27
tell-ended frames (spot-checked), and 18+ periodic `t-` frames spread across
the full duration of each fight, at full 1920x1080 size.

## A. Per-fight findings

**1. Tess** (46 frames, opponents Mirejaw → Riverdrake → Sirenseal)
- Framing: **46/46 (100%)**. Ally (Ripplet) and the named opponent are both
  in frame and readable throughout. Soft note, not a fail: `t-000.00.png` opens
  with Ripplet's face pressed nose-to-nose into Mirejaw's jaw — the two
  silhouettes touch and briefly read as one shape before the color break (teal
  vs. grey) resolves it. Not occluded by terrain/camera/HUD, so it clears the
  bar, but it's an awkward first frame of the fight.
- Tells: **9/9 readable**. Every tell-start frame (`000.27`, `001.60`,
  `003.07`, `078.28`, `079.33`, `080.22`, `143.40`, `144.38`, `145.75`) shows a
  clear magenta ground ring plus the "! incoming — move" banner, with the
  landing spot legible.
- Presentation: clean. No exploration HUD, no camera-in-geometry, no
  floating/sunk fighters.

**2. Calder** (41 frames, opponents Riptusk → Torrentoad → Riverdrake)
- Framing: **41/41 (100%)**.
- Tells: **9/9 readable** (`000.27`, `001.67`, `002.93`, `072.12`, `073.10`,
  `074.40`, `128.82`, `130.13`, `131.50`), same clear ring + banner pattern.
- Presentation: a defeated, motionless creature (colored like the Mirejaw/
  Riptusk model) lies on the beach in the far background of many frames
  spanning `t-072.02` through `t-184.00` — over two minutes of fight time. It
  never blocks the ally/opponent, so it doesn't fail C3, but it reads as an
  un-cleared corpse prop rather than staged set dressing.

**3. Venn** (52 frames, opponents Cannonback → Riptusk → Riverdrake)
- Framing: **52/52 (100%)**. Holds up even after three of the player's
  creatures are KO'd and the much-smaller bird ally Pipwing is fighting the
  full-size Riverdrake (`t-224.00` onward) — both stay legible.
- Tells: **9/9 readable** (`000.27`, `001.57`, `003.07`, `096.12`, `097.23`,
  `099.68`, `207.65`, `208.50`, `209.87`).
- Presentation: same background corpse-prop pattern as Calder (visible from
  `tell-start-001.57.png` through `t-264.00.png`). Also, `t-232.00.png` and
  `t-264.00.png` pick up a heavy shoreline mist/bokeh-spray effect that
  softens contrast at the frame edges; it doesn't reach the fighters and
  isn't disqualifying, but it's the softest-looking frames in the set.

## B. C3 verdict per fight

- **Tess: PASS**
- **Calder: PASS**
- **Venn: PASS**

Framing and tell-readability both clear the stated 90% bar with no failing
frames, and no presentation break (exploration HUD, camera-in-geometry, empty
frame, floating/sunk fighter) was found in any fight.

## C. Three biggest defects, ranked

1. **No fight frame shows an attack landing.** Across all three contact
   sheets and every full-size frame opened, both combatants are always in a
   neutral standing pose — the only signals that combat is happening are HUD
   text ("it's open — hit it", "it missed you") and health-bar movement, e.g.
   `t-104.02` (Calder, Riptusk) and `t-096.02`/`t-168.00` (Calder, "it's
   open — hit it"). No hit VFX, stagger flinch, lunge or camera shake appears
   in any sampled frame. This is the single biggest reason the fights read as
   a dialogue exchange over a static diorama rather than the "real-time
   direct creature piloting" the pillar calls for.
2. **A defeated creature is left lying in the background for minutes,
   unrelated to the current fight** (Calder `t-072.02`→`t-184.00`; Venn
   `tell-start-001.57.png`→`t-264.00.png`). It reads as an un-cleared body,
   not an authored beat, and repeats near-identically across two different
   trainer fights.
3. **Awkward creature-to-creature framing at fight-open and a large
   ally/opponent scale gap late in Venn.** `t-000.00.png` (Tess) opens with
   the ally's face buried against the opponent's jaw; and once Pipwing (a
   small bird) is the active ally against Riverdrake (`t-232.00`,
   `t-264.00`), it reads noticeably shorter than the trainer nearby —
   camera depth makes an exact measurement uncertain, but it's worth a
   direct scale check against the 1.80 m trainer.

## D. Bar A / Bar B

**A — Do these read as the Tidewake world in the reference boards? No.**
The coastal geography and palette (sand, grass, blue water) plausibly match
the Veilfall board's "biome context" thumbnail, but the render style does
not: creatures and the trainer carry hard black cel outlines and flat toon
shading, where both the Meadows keyart and the Veilfall board are painted
with soft global illumination, layered atmospheric depth and no linework.
Side by side, these look like a different, flatter-shaded game than the
board's world.

**B — Beside the Palworld shots, is this trying to be the same kind of game?
No.** Palworld's boss-fight reference (`palworld-01`) is dense with weapon
fire, sparks, a leaning/attacking pose and a camera that's clearly reacting to
action. Every Tetherbound fight frame gathered here is calm and static by
comparison — defect #1 above. The vibrant natural palette and creature-forward
framing are on-model; the absence of any visible attack, hit reaction or
camera energy is not.

**Fix split**
- **Scene/camera/VFX/placement (buildable now):** add attack/impact
  animation and VFX so at least one sampled beat per fight shows a strike
  landing; despawn or hide the background corpse prop after its fight ends;
  soften or re-time the opening creature-to-creature approach so it doesn't
  start nose-to-nose; confirm Pipwing's scale against the 1.80 m trainer and
  adjust if it reads under.
- **Needs new art/pipeline work (not a scene fix):** the cel-outline/flat-shade
  look versus the painted board style is a shader/rendering-pipeline
  difference, not something scene dressing can close.
