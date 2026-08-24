# VIS-CAST — the cast and roster lane, D3 round 3 and D4 round 2

Branch `ralph/VIS-CAST`, off `ralph/VISUAL-CORRIDOR`. Two domains, judged blind
by Fable critics per `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 (blind review is
Fable-only and never judges evidence it produced). This lane produced the
evidence and did not judge it.

| domain | round | A (keyart) | B (Palworld) |
|---|---|---|---|
| D3 creatures | 3 | **no** | **yes** (trying to be), not yet at the bar |
| D4 characters | 2 | **no** | **no** |

Neither domain is converged. Both rounds named many NEW defects, which is
`ralph/conventions.md`'s own definition of a round that improved.

---

## The finding that outranks both verdicts: the survey was lying about colour

**The creature stage was over-exposing every subject by a measured 2.3x, and
three consecutive blind rounds spent their top-ranked finding on the result.**

Round 3's number-one verdict was that the roster "floats in high-key pastel",
with 25–50% of body highlight regions clipped to pure white, `14-duskhush.png`
called "candy lavender", and `17-veridian.png` a "uniformly bright jade deer".
Round 2 had said the same thing in different words. Round 1 too.

Duskhush's own albedo texture measures **mean 65.6, 95th percentile 135** — a
genuinely dark plum owl, exactly what the owner's board paints. The art was
never pastel. The photograph was.

The proof is inside the frame and costs nothing to re-check:

| element | authored | rendered | factor |
|---|---|---|---|
| backdrop (`BG_COLOR`, **unlit**) | (51,56,61) | (51,56,61) | **1.00** |
| floor (albedo 0.30/0.33/0.30, **lit**) | ~(77,84,77) | (174,200,184) | **2.26 / 2.38 / 2.39** |

Anything unlit was exact; anything lit was 2.3x out. The cause was plain
addition — ambient 1.5 at a near-white colour is ~1.17 of light before a 1.6 key
adds ~0.91 more, and these creature materials are self-lit on top of that (the
painted albedo is wired into the emission slot). Three sources summing past 3.0
where a neutral stage wants ~1.0.

Both stages are now calibrated against their own floor, in measured passes
(2.3x → 1.26x → 1.02x). **The floor is documented in both tools as the
calibration target**, so the next change re-measures rather than eyeballs.

What it bought, with no art change at all: creature subject means moved from
174–193 into the board's own 90–135 band, `13-galecrest-alpha.png`'s clipping
went 12.3% → 5.3%, and duskhush became the dark plum owl the board draws.

**The lesson for the whole sweep, not just this lane:** a survey that is not
exposure-calibrated cannot be asked a colour question, and every colour verdict
taken off it inherits the error. `VISUAL_LEDGER.md` already records six cases of
a survey photographing the wrong subject. This is a seventh shape of the same
failure — photographing the right subject wrongly — and it is cheaper to detect
than any of them, because every one of these stages contains a known-albedo
surface that can be measured in one line.

---

## The other harness defects this round found

The character cast tool had **no ground plane and no shadows**. `shadow_enabled`
defaults to false and only the creature tool was ever fixed. A blind round
measured sole lines disagreeing by 24px under a camera the tool's own header
calls identical, so every height derived from those frames carried that error.
Ported, with measured ground seating.

**Heights were printed to stdout, never into the frame.** The rubric's criterion
8 is entirely about scale and tells the critic to measure against the 1.80 m
trainer — and the critic reading PNGs never sees a terminal. It had to derive
every height from silhouette pixels. Now burned into each frame.

**The line-up rendered the whole cast as a 58-pixel strip** in an 800px frame —
the one shot whose entire job is comparing the cast at one scale. Fixed by
closing the ranks for that frame only (the portraits still need their spacing)
and dropping to eye level.

**The creature survey had one front-on camera.** Several species carry their
board signature on the BACK — terrapup's leaf growth, burrowback's plates,
trailpup's shoulder growth, and every overlay whose `where` selects on `up_min`,
which is most of them. Raising terrapup's leaf coverage tripled its green texels
(3.8% → 11.3% of chromatic pixels) and barely moved the front-on frame. A rear
three-quarter view is now shot for every species and variant.

---

## The emission floor was never additive

`character_model.gd`'s floor has claimed to be additive since STRANDED-P3 and
was not. It lerped `material.emission`, which Godot uses as a **multiplier** over
`emission_texture` whenever `emission_operator` is MULTIPLY — probed directly on
the built rank materials, the operator is MULTIPLY on every one of them,
inherited from the glTF import.

So the floor raised a multiplier over a near-black texture and the product
stayed near-black, for exactly the reason its own comment gives for albedo: *"a
straight multiply can only ever DARKEN a source pixel, never brighten one."* The
floor was subject to the law it was written to escape. Raising its blend from
0.5 to 0.72 moved the rendered uniform by about one value point, which is how it
was caught.

What it cost: a blind round measured every Team Tether body at **0.11–0.18
lightness** and reported the faction collapsing into *"interchangeable near-black
smears"* at thumbnail size — the reserved oxblood was, in practice, absent from
the faction it exists to identify.

Switched to `EMISSION_OP_ADD` with a small constant add. Team Tether's torso
lightness went **0.14 / 0.16 / 0.17 → 0.27 / 0.29 / 0.31**, with a real value
ladder up the ranks. The luminance gate means the trainer, Grandpa and every
villager render bit-identical — measured, not assumed — so the game's style
anchor is untouched.

---

## D4 characters — what landed, and what the round still says

**Landed.** The faction colour now reaches the three named captains a player
actually fights: `trainer_npc.gd::model_config()` merges `palette` per surface
instead of replacing the dictionary wholesale, and the three site hexes moved
into the captain rank's own family. The cast capture now photographs those three
captains at all — it only ever shot the generic `rank-captain`, so a blind round
would have confirmed the oxblood had landed while every captain in the game
still had none of it.

**Landed.** The rank badge stopped reading as a debug gizmo. The captain's box
was itself a fix for "officer and captain differ by 26 points in one colour
channel", and it introduced something worse: a cube shows one flat face, a plane
takes one shade under one key, and the accessory material was matte by default,
so the insignia photographed as a flat pure-red untextured rectangle over the
chest straps. Now a `disc` with real metal, smaller (13cm was a placard), off
full saturation. Badge pixel variance went from flat to std 20–34 per channel.
The Warden keeps the literal reserved hex and gains a polish that makes
near-black insignia findable on a dark green coat.

**Still open, ranked by the round's own verdict:**

1. **One cast, three art languages.** Measured head counts off the capture:
   villagers 4.87–4.98, trainer 5.21, **grunt rig 6.50**. The faction a player
   fights for a whole chapter is a quarter longer-limbed than the game's own
   style anchor — a consequence of NP2-grunt-wire, which was correct and
   necessary and bought that at this price.
2. **Faces do not survive meeting distance.** The Warden's eyes read as two dark
   hollows inside his mask; the villagers and every Team Tether body wear the
   same vinyl-doll face. The critic calls the facial language a mesh gap, not a
   paint gap.
3. **The three named captains are one person three times.** This is now
   deliberate and recorded in the band files: the rigs carry one fused material,
   so the body palette is the ONLY dial, and it is spent on faction identity.
   Three accents held inside one reserved colour at one luminance moved the
   rendered torso by 1–5 points per channel — not a difference a player can see.
   Real per-site separation needs a dial that is not the faction colour.
4. Warden cape lining renders as a translucent membrane (alpha/material
   artifact).
5. **The villager male's sock artefact is a MESH interpenetration, not a texture
   bug** — diagnosed here because two rounds have now called it "an orange
   emissive scribble" and a repaint would not have touched it. `villager_male_lod0.glb`
   carries TWO meshes, `char1` (the body, 14,257 verts, `Material_1`/`texture_0`)
   and a separate `trousers` (3,741 verts, `Trousers`/`trousers_tex`). The
   sock belongs to the body mesh. `texture_0` contains **zero** orange pixels
   (`r>170, g 70-175, b<95, r-b>110` matches 0 of 4,194,304), so nothing painted
   on the sock is orange — but the streaks measure (191,127,64) in the render
   against the trousers leather's (204,132,67) in its own texture. It is the
   trouser hem showing through the sock. Both materials are self-lit
   (`emissiveFactor [1,1,1]` with an emissive texture each), which is why the
   overlap reads as bright flame-like streaks rather than as a dull clip, and
   it appears on one leg only, which points at the idle pose rather than at
   the modelling. **Fix is a mesh or skinning correction on the trousers hem,
   or a depth/priority change on that material — not a repaint.**

---

## D3 creatures — what landed, and what the round still says

**Landed.** Duskhush is the board's dark plum (exposure fix). Galewisp is off
hue 200 and out of the white-and-blue bird cluster. Galecrest's inverted rarity
is fixed — *without* swapping its colourways, because the board defines the
ORDINARY galecrest as the white-and-blue noble eagle and a swap would contradict
the owner's own reference; the RARE moved to storm-dark instead. Reedwing takes
the board's navy crane colouring. Terrapup carries the board's real quantity of
leaf growth. Five failed shinies were rebuilt as PATTERN changes rather than hue
rotations, which is what the owner asked for originally.

**Fixed this round, from the round-3 verdict:** the three water species measured
within ~20 RGB of each other and read as one animal — ripplet to cobalt,
paddlenewt to bright cyan, brooktail to deep navy with a bright tail. Pipwing to
the board's cream (it had duplicated reedwing's blue). Galewisp's gold moved
from a colourway rule to an anatomical overlay, because a rule keyed on
saturation cannot say "tips" and gilded the whole bird. Reedwing's rare off gold
(three yellow birds). Veridian to a charcoal hide so its already-authored
emissive crown has something to glow against. Mosshell's rare off raw-flesh
pink. Burrowback's and bramblebun's rares rebuilt again — both had collided with
this same lane's other fixes.

**Still open:** the two-art-styles split (photoreal wildlife recolours beside
glossy chibi toys) is the round's own top-three item and is called not fixable
by paint. See `ralph/BLOCKED.md`.

---

## A correction to a round-2 finding this lane was briefed with as fact

Round 2 reported that terrapup and burrowback **"share one badger mesh"**, and
concluded *"recoloring cannot make the starter a different species from the
tank; only geometry can."*

Checked against the installed assets, **it is false**: the two glbs differ in
size, md5, vertex count (15,616 vs 17,204), POSITION bounds and POSITION
accessor bytes. Sweeping all seventeen species finds no two sharing a mesh file.
What they share is a skeleton template — 17 nodes, 15 joints, 6 clips — which is
the rig pipeline working as designed.

The observation underneath was still right: they read as the same animal at
thumbnail size. But they read that way because they are two meshes of one
**archetype**, which is a casting problem rather than a mesh-sharing one, and
the distinction changes the prescription — "only geometry can" said paint was
powerless, and it is not.

Also recorded: the briefed **"grunt armband"** defect does not exist. No armband
in `scripts/`, `data/` or `tools/`; zero saturated-red pixels in the grunt
texture (0 of 4,194,304). The description fits the captain's box badge, which is
fixed.

---

## What is now in BLOCKED.md rather than fixed

- The creature board contradictions paint cannot reach: burrowback's shell,
  brooktail's swirl tail, ripplet's fin frills, reedwing's crane build. Recorded
  with the board's own implementation notes quoted, because *"Use existing
  meshes/rigs/animations"* and *"Keep silhouettes and anatomy the same"* change
  what those findings mean — the board is a colour and material refresh, not a
  commission.
- **The missing small creature tier.** Real and measured (1.35–2.60 m, 1.93x
  over 17 species, ten of seventeen at or above the player's height). Recorded
  rather than fixed because the fix reverses `D19`, an owner decision made at the
  controller after he played and found his creature felt small. Canon precedence
  puts owner-play evidence above a critic's reading.
- **Are the villagers adults or youths?** A design question with two opposite
  one-number fixes. Not this lane's to answer.
