# D5 — blind visual pass, round 1

Sheet: `shots/band5_approach/_sheet.png` (12 tiles — six camera positions, each
day and night). Critic: independent sub-agent, given the sheet, the frames and
`docs/reference/`, told nothing about what changed or what the lane hoped to
hear, per `.claude/skills/visual-judge/SKILL.md` and `ralph/lanes/COMMON.md` §8.

**Verdict: A — no. B — no.** Both bar questions failed.

## The finding that outranks the verdict: the survey itself is invalid

> "There is not a single creature, and not a single trainer, in any of the
> twelve frames… Scale agreement (criterion 8) is therefore **unjudgeable** in
> this set, and that is itself a defect of the survey."

This is the lane's own fault, not the region's. `_probe_band5_approach.gd`'s
capture pass moves the CAMERA down the route and leaves the player at spawn
(0,0,0), 7 km away. Creature spawning is driven off the player, so a route with
22 authored clusters and 75 creatures rendered as empty meadow, under a bare
boot's own "TEAM 0/5 — catch your first wild creature" card.

So the single criterion the owner's bar is actually about — creatures and
characters — was never put in front of the critic, and everything the verdict
says about emptiness is measuring the harness, not the world. The frames also
carry a burned-in HUD with an open rest menu ("Get up") eating the bottom
quarter of all twelve.

**Round 1 is therefore not a usable pass/fail on this region.** It is still
useful, because the artefact findings below are real and several are new.

## Defects that are real regardless of the staging

Numbered as the critic gave them.

1. **The storm slabs are worse than this lane reported.** Corroborates §5a
   independently — the critic reached "untextured proxy geometry… reads as
   unfinished blockout" from the pixels alone, with no knowledge of
   `rift_collapse.gd`. It escalates the severity: *"Worst at night: the
   brightest object in the frame is the proxy slab — unlit ghost-white geometry
   glowing in the dark like a projection screen."* Nine of twelve frames.
   **This is now the top visual defect on the route, not a background one.**

2. **The stronghold masonry reads as television static.** *"The dark wall panels
   are covered in white speckle noise — it looks like a corrupted texture or
   per-pixel dither, not masonry… This is an artefact, not a choice."*
   (04-before-the-gate-day, 06-the-waystop-day, 04-night.) This lane saw the
   speckle and filed it as taste. It is not: it is the `STRONGHOLD-MAT` fix's
   own triplanar tiling aliasing on very large wall boxes. **`stronghold.gd` is
   this lane's file and this is this lane's bug.**

7. **The conduit cable reads as a debug line, not a cable.** *"The cable rises
   from the distant pylon in a smooth mathematical swoop to the top of the
   frame — it reads as a bezier debug line, not a hanging cable; cables sag,
   they do not soar."* A direct hit on §2's own measured choice: raising the
   pylons to 10.0 m bought the ground clearance the probe demanded, and the
   side effect is a steeper cable read from 1.7 m eye height. The critic also
   calls the pylons *"the best thing in the survey"* and says *"the wire
   connecting them undoes them"* — so the fix is the wire, not the pylons.

8. **A hard-edged black shadow band** across the lower right of
   03-mid-route-day with no visible caster, its interior nearly valueless.

3. **Night is near-black and unreadable** — ~80% pure black in three frames, no
   moonlight terrain modelling, no warm source anywhere, and the moon is *"a
   soft grey smudge with no disc… a lens smear, not a moon."* Corroborates and
   sharpens §5e: this lane found there is no warm light to survive the ending;
   the critic finds there is barely any light to begin with.

6. **Style disagreement between the pylon and the foliage.** *"These cartoon-
   broccoli trees sit poorly beside the pylon, which is a detailed, painterly,
   gilded prop — the one finished asset and the vegetation do not agree on what
   game they are in."*

4, 5, 10. Cloudless dusk-blue sky; ground cover *"a lawn"* with visible diagonal
tiling stripes and a repeated hero sprout; the six day frames not obviously one
hour of one place.

9. **HUD**, in every frame — oversized central TEAM stack overlapping world
   geometry, MAIN STORY panel over the hero pylon, ragged text, an orphaned
   progress bar, an empty minimap showing neither path nor pylons nor gate.

## Ranked, the critic's own three

1. **Nothing lives here.** — invalid, see above; the harness caused it.
2. **The destination is placeholder** — the slabs and the static walls.
   *"The closer you get, the worse it looks."*
3. **Surface density and lighting richness.**

## What this makes work

Lane's own, and blocking a round 2:

- Stage the survey properly: drive the PLAYER down the route so creatures
  spawn, and suppress the HUD/rest menu. Round 1 cannot be repeated as-is.
- Fix the masonry aliasing in `stronghold.gd`.
- Fix the cable read without giving back the measured ground clearance.

Not the lane's, now better evidenced:

- The storm slabs, escalated to top defect and confirmed in both lighting states.
- Night exposure, moonlight and the moon disc.
- Sky/clouds, ground scatter density, day-palette consistency, foliage style.
- HUD composition.

Round 2 must not be graded against round 1's verdict: the two surveys will not
be measuring the same thing.


---

# D5 — round 2: what the lane changed

Round 1's three lane-owned items, all fixed. Round 2 is a **fresh survey judged
by a fresh critic**; it is not graded against round 1's verdict, because round 1
was not photographing the same thing.

## 1. The survey now photographs the region

Round 1's fatal flaw. `_probe_band5_approach.gd` moved the camera and left the
player at spawn, so nothing spawned. Now:

- the **player is carried to each viewpoint** and given 150 physics frames to
  stand there before the shutter, so the world populates around them the way it
  would in play;
- the **camera stands 4.2 m back and 2.4 m up, over their shoulder**, so the
  trainer is in shot — criterion 8 explicitly needs them as the 1.80 m ruler;
- **every `CanvasLayer` is hidden**, which removes the HUD, the "TEAM 0/5" card
  and the open rest menu that ate the bottom quarter of all twelve frames.

## 2. The masonry static — two compounding causes, both real

The critic called it "a corrupted texture or per-pixel dither, not masonry" and
was right; this lane had filed it as taste, which was wrong.

- **The tiling was ~11× too fine.** In triplanar `uv1_scale` multiplies world
  position, so `STONE_TILE = 3.2` repeated the tile every **0.31 m**. Counted
  off the texture itself, `T_UnevenBrick` is ~9 stones across — so each stone
  rendered at **3.5 cm**. That is gravel. Real stones of that shape run
  0.3–0.5 m, putting the tile at ~3.6 m of wall and the scale at **0.28**.
- **The texture had no mipmaps** (`mipmaps/generate=false` on all three maps,
  now `true`). Every stone in it is outlined in a thin bright white highlight —
  the worst possible thing to minify without a mip chain. ~100 repeats across a
  30–41 m wall, each highlight thinner than a pixel at distance, *is* the white
  speckle.

Fixing one alone would not have worked: mipmaps alone blur 3.5 cm pebbles into
grey mud, rescaling alone still shimmers at distance.

`severed_spokes.gd` uses the same 3.2 and escapes it only because its stone
objects are sub-metre to ~6 m. **Reported, not changed** — it is not this lane's
file and its objects may genuinely want fine tiling. Likewise the other 19
textures in `assets/buildings/quaternius_medieval/` all ship
`mipmaps/generate=false`; only the three this lane's material samples were
changed.

## 3. The cable — the wire, not the pylons

The critic called the pylons "the best thing in the survey" and the wire "a
bezier debug line… the wire connecting them undoes them." So the wire was fixed.

Sag is **proportional to span**. `severed_spokes.gd`'s default `1.0` was tuned
on the spokes' and quarry's ~14 m spans, where it droops 0.7 m and reads; over
this run's 35 m spans it drooped 1.8 m across five times the length — a straight
diagonal. `_build_pylons` now reads an optional **`sag_scale`** from the pylons
config, defaulting to the 1.0 every existing caller already gets, so nothing
else in the chapter moves.

Sag and ground clearance pull directly against each other, so both were swept
(`tools/_sweep_cable.gd`) instead of either being guessed:

| height | sag_scale | sag over 35.4 m | worst ground clearance |
|---|---|---|---|
| 10.0 (round 1) | 1.0 | 1.77 m | 3.14 m |
| 10.0 | 2.2 | 3.90 m | **1.01 m — under a walking player** |
| **12.0** | **2.2** | **3.90 m (11% of span)** | **2.33 m** |

12.0 m is the smallest swept height that keeps a 2.2× sag clear of 2.2 m. The
cost is a pylon 20% taller than the one the critic liked — taken deliberately,
as a decisive fix round 2 can actually see rather than a timid one that changes
nothing.
