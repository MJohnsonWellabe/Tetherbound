# Handover — T1-RIG-2, 2026-08-30

Branch `ralph/T1-RIG-2`, off `origin/main` at `5d171130`.

Read first: `CLAUDE.md`, `ralph/conventions.md` (the hard rules and the art
pipeline traps), `docs/art/HUMANOID_ASSET_INVENTORY.md`,
`ralph/reports/handover-T1-CREATURE-RIG-2026-08-30.md`,
`ralph/reports/NPC_CAST_INSTALL_2026-08-30.md`.

## The brief's premise was wrong, and the correction matters

The brief said the previous lane (T1-CREATURE-RIG) stood down on this work
because `MESHY_API_KEY` was unset. **It did not.** That lane's own handover says
plainly that the key "turned out not to be the actual blocker": creature rigging
in this project has never gone through Meshy at all. Meshy's auto-rigger is
humanoid-only (`meshy.py::cmd_rig`'s own docstring) and `CLAUDE.md` forbids a
Meshy generation for a Meadows creature regardless. The five creatures rig
through `tools/art_pipeline/finish.py rig <species> --kind quadruped`, a local
offline Blender pipeline, and always could have.

What was actually true on `main`: **none of that lane's work had landed.**
`ralph/T1-CREATURE-RIG` merged into `ralph/LAND-0830G`, and neither is an
ancestor of `origin/main`. Checked directly rather than assumed —
`git merge-base --is-ancestor 1886271d origin/main` says no, and the five
meshes on `main` still parsed as `skins: 0`, `animations: []`. So this lane
re-derived the work on top of `main` rather than merging a branch whose other
half (15 NPC placements) is out of this lane's scope.

**Zero Meshy credits were spent.** Full API-call log below.

## Priority 1 — the five creature meshes: DONE, and proved in the Meadows

`sparkit`, `cindercub`, `shadelet`, `frostclaw`, `bramblebun_redesign` all now
carry a 15-bone quadruped skeleton and the six clips (`idle`, `walk`, `run`,
`attack`, `hit`, `faint`) every other production creature ships.

```
cp assets/creatures/tetherbound/<s>/models/creature_<s>_lod0.glb \
   assets_raw/<s>/build/textured.glb
python3 tools/art_pipeline/finish.py rig <s> --kind quadruped
python3 tools/art_pipeline/finish.py install <s>
godot --headless --path . --import          # the import-cache trap, see below
```

`species.json`'s `animations` block already mapped exactly those six role names
for all five, and `animate_quadruped.py` produces clips with exactly those
names, so no data edit was needed beyond `bramblebun`'s model path and the
provenance comments.

### `bramblebun` now uses the redesign mesh

`placeholder.model` points at `bramblebun_redesign/`. T3-INSTALL tried this
swap on 2026-08-30 and reverted it in the same pass for exactly one reason —
the redesign was an unrigged static export, and the game's most-seen creature
would have become a frozen mesh. That reason is gone. `height` was already
moved 0.96 → 1.00 for this mesh's own size guide and is untouched. The old
`bramblebun` mesh stays on disk.

### One skinning defect, and an honest account of how much it mattered

Automatic weights left **35 vertices on cindercub and 20 on frostclaw with no
bone influence at all**. That is not benign in principle: Blender's glTF
exporter invents a static `neutral_bone` at the armature origin and binds
orphans to it, so the patch hangs in bind pose while the body moves — which is
the tear `rig_quadruped.py::weight_report`'s own docstring says to reject
before animating. Both meshes exported with 16 joints instead of 15 for that
reason; that extra joint was the tell.

`rig_quadruped.py` gained `repair_unweighted()`: every zero-weight vertex takes
the weights of its nearest weighted neighbour. All five now report `0
unweighted` and a clean 15-joint skin.

**What it did not do.** The previous lane accepted these two on a single
rendered frame that showed no tearing. That judgement was right, and this lane
can now say so with a measurement instead of an eyeball: cindercub was rigged
**both ways** and both rigs were put through `pose_test.py`'s four extreme
poses and differenced pixel by pixel — **seven of the eight views are
identical, the eighth differs by ten pixels.** So the orphan patch was not
producing a visible artefact, and this change should not be sold as fixing one.
It is worth keeping because it closes a latent failure for free and lets the
rigger's own zero-unweighted contract actually hold. Both sets of frames are
kept side by side under `ralph/reports/T1-RIG-2/pose_test/` (`cindercub/` and
`cindercub_BEFORE_REPAIR/`) so anyone can re-check that claim.

The pass cannot regress a mesh that was already clean: it only ever touches
vertices with zero total weight. Verified, not asserted — sparkit, shadelet and
bramblebun_redesign re-rigged **byte-identically** with the pass in place
(md5 before/after).

### Evidence: the shipping world, not a preview stage

This is the part the brief was right to insist on, and the part the previous
lane could not deliver. Its evidence was `pose_check` renders in Blender and
`preview_creatures.gd`'s isolated stage — both of which answer "does this rig
deform", neither of which answers "does this creature move in the Meadows".

`tools/_capture_t1_rig2_meadows.gd` (new) boots `meadows_playground.tscn`,
spawns the five through `encounter_director.spawn_wild()` — the same call the
Burrow Warrens uses, whose own docstring says "there is no second kind of wild
creature" — and photographs them in Band 1's open basin. **Every shutter is
gated on `CAPTURE_CHECK.require`**, so a frame that silently lost the grass
field aborts the run instead of being committed; all frames below passed it.

Two independent kinds of evidence, because a render alone cannot tell a moving
creature from a still one photographed twice:

- `ralph/reports/T1-RIG-2/shots/*.png` — real terrain, real grass field, real
  light, real props.
- `ralph/reports/T1-RIG-2/shots/motion.json` — per shot, per creature: the clip
  its `AnimationPlayer` is on, the position within that clip, and a pose
  signature summed over every bone in its `Skeleton3D`. A frozen creature
  reports the same signature at every shot.

The tool's own pass/fail line (`_verdict`) is stricter than `smoke_art.gd`'s
"has an AnimationPlayer": every one of the five must change its pose signature
across the idle sequence **and** report a real clip. All five pass, on five
independent runs of the tool.

The shot set, and what each frame is for:

| Frame | What it shows |
|---|---|
| `idle-0/1/2.png` | The five standing in the open basin, three shots a third of a second apart. `motion.json` shows the same `idle` clip advancing 0.26 → 0.93 → 1.59 and every signature moving with it. |
| `walk-live.png` | Uncontrolled: whatever each animator resolved from its own real speed. Two of five read `walk`; the other three read `idle` and that is **correct** — a body pressed against a bush has a real speed of zero and `creature_animator.tick` calls that standing still. Kept precisely because it is the unflattering one. |
| `walk-held.png` | All five pinned to the same point of their own `walk` clips, so the five gaits are comparable in one frame. |
| `attack.png` | All five held at 35% of their own `attack` clip — the clip `combat_manager` triggers on a real swing. |
| `close-<species>.png` | One creature per frame, framed off its own measured bounds, held at the same attack pose. This is where a skinning failure would show. |

The held frames are seeked and paused rather than caught live, and that is a
container workaround stated plainly: an `AnimationPlayer` advances on real
elapsed time, one llvmpipe frame here costs seconds, and a 0.96s attack clip
runs to its end during the three pose frames before the shutter. It is the
game's own clip on the game's own player, stopped at a frame the player passes
through every swing — not a pose staged by hand. `motion.json` flags every held
row with `"paused": true`, so no reader has to take that on trust.

### Also checked, cheaply and for every species

`tools/_probe_creature_clips.gd` (new) loads each species' model through
`species.json`'s own `placeholder.model` and resolves its declared role map the
same way `creature_animator._resolve` does at runtime. **25 species checked, 0
failed** — every one has a skeleton, an `AnimationPlayer`, and a real clip for
all six roles. Before this lane, five of those 25 had no `AnimationPlayer` at
all. It runs headless in seconds and is a probe, not a replacement for
`smoke_art.gd` (which also checks scale, colliders, shiny variants and human
fit, none of which this touches).

### The import-cache trap, paid for again

Overwriting a `.glb` on disk does not reach the game until Godot re-imports it.
The previous lane recorded this and it is still true — `godot --headless
--path . --import` after `finish.py install`, before any test or capture, or
you are testing the old mesh. This container starts with no `.godot/` at all,
so the first import is a full cold pass (~25 minutes here, 683 MB).

## Priority 2 — the two humanoids: diagnosed, NOT re-run, and the inherited diagnosis is wrong

`campfire_traveler` and `traveling_merchant`. The brief asked for a diagnosis
before any retry, which is exactly right, because the retry the record implies
would have been the wrong move.

### First, the fact that decides everything else: there is nothing to re-rig

Both meshes were fetched to `assets_raw/**`, which `.gitignore` excludes, and
were **never committed on any branch** (`git log --all --diff-filter=A` over
both paths returns nothing). They existed only inside the container that made
them, and that container is gone. `assets/characters/` has 22 of the 24 NPC
bodies and neither of these two; `art.json` has no entry for either.

So "re-run the rigger" is not an option that exists. There is no GLB to submit.
**Every path forward begins with a new generation**, which is a spend, which is
an owner decision — and the brief's own instruction is to stop and write it up
rather than spend it.

### Second, the two failures do not have the same cause

The inherited one-liner (`NPC_CAST_INSTALL_2026-08-30.md`) says both meshes
"have a genuinely non-standard arm pose baked in from generation" —
`campfire_traveler` "holding a crossbow prop that bridges her two hands into
one fused shape", `traveling_merchant`'s "arms crossed over her body" — and
concludes both need "another full generation round each" against a
resting-pose reference. Half of that is right.

**`traveling_merchant`: the record is correct.** Board 17 draws her once,
three-quarter, both hands on a fully-drawn handcart that takes up more of the
panel than she does, with her lower body behind the cart. There is no second
angle and no crop that removes the cart without removing her arms. That lane
tried a tighter crop (40 credits, failed the same way), correctly root-caused
it to the single viewpoint rather than the crop, and fell back to text-to-3D —
which is where the crossed arms came from. They are a text-to-3D artefact, not
something the board asked for.

**`campfire_traveler`: the record is wrong, and it is wrong in the direction
that costs money.** Her panel (board 22, kept at
`assets/creatures/tetherbound/campfire_traveler/reference/board_panel_source.png`)
is an ordinary front-and-back turnaround, standing, arms down at her sides.
**There is no crossbow in the reference and nothing bridges her hands** — she
holds a small lantern in one hand in the back view, that is all. Her crop set
(`front.png` + a back view filed as `side.png`) is the *same* set, in the same
house style, as `lost_traveler`, `courier` and `alpha_tracker`, all three of
which rigged cleanly on the first attempt. The fused shape the report describes
is a property of the mesh that generation produced, not of the art it was given.

What is actually unusual about her: she wears a long open coat whose front
panels hang between her arms and her legs, so her arm silhouette merges into
the coat's in **both** views. That is a plausible reason a limb-landmark
estimator fails on her and not on the courier, and it is untested.

The practical consequence: a straight regeneration of `campfire_traveler` from
the existing board is **not** the "second identical attempt that fails
identically" the brief warned about — her reference is fine and the failure was
downstream of it. A straight regeneration of `traveling_merchant` from the
existing board **is** exactly that, and should not be run.

### Owner question — no credits spent, three costed options

Balance is **515 credits** (checked live at the start of this session, and
again nothing was spent). Per subject a full path is 55 credits: preview 20 +
refine 30 + rig 5.

| | What it costs | What you get |
|---|---|---|
| **A. Reuse an installed body** | 0 credits | Both NPCs in the game now, animated, differentiated per material. `lost_traveler` is the nearest neighbour for the campfire traveller, `trader` or `courier` for the merchant. This is what `CLAUDE.md`'s NPC production rule prescribes by default. Cost: two of your 24 board designs never get their own mesh. |
| **B. Regenerate `campfire_traveler` only** | ~55 credits | Her board is sound, so this has real odds; the coat is the untested variable. `traveling_merchant` falls back to A. |
| **C. New reference art, then regenerate both** | ~110 credits + your drawing time | Highest odds. What is needed is specific: for the campfire traveller, the same figure with her arms held clear of the coat; for the merchant, the same figure **without the cart**. |

**This lane's recommendation is B, with A as the immediate fallback for the
merchant** — it is the only option that spends anything on a subject whose
reference is actually good, and it leaves the one genuinely-blocked subject
blocked rather than paying 50 credits to rediscover that.

Not actioned unilaterally: swapping in a repainted `lost_traveler` and calling
it the campfire traveller is a visible step down from the other 22 bodies, and
the owner funded 24 distinct designs on purpose. That is a decision, not an
implementation detail.

## Meshy API call log

Complete, as the brief asked.

| Call | Endpoint | Credits | Result |
|---|---|---|---|
| `meshy.py check` | `GET` balance | **0** | key accepted, balance 515 |

**That is the entire log. One read-only call, zero credits, balance unchanged
at 515.** No generation, refine, retexture, rig or animate call was made. The
key was read from `$MESHY_API_KEY` in the environment and is not written to any
file, config, fixture, commit message or this handover.

One bookkeeping fix in the same area: `meshy.py`'s `COSTS` table gained
`"rig": 5`. It had **no** `rig` entry at all despite T1-NPC-CAST measuring it
cleanly at 5 credits across 22 calls plus a resubmit and naming the omission as
worth fixing. A rig call costing nothing in that table is how a rig round gets
costed at zero in a plan. `retexture` is deliberately left at 30 — the same
report measured one call at 10 and declined to correct the table on a single
data point, and that judgement stands.

## Tests

**`tests/run_tests.gd`, the whole suite: 1545 tests, 282,894 assertions, 0
failed.** Run exactly as `verify-unit-tests` runs it, minus the sharding:

```
godot --headless --path . --script tests/run_tests.gd \
  -- --skip=test_veg_corridor.gd,test_scatter_rules.gd,test_harvest.gd
```

The three skips are the three CI gives their own jobs and their own ceilings;
they cover vegetation corridors, scatter rules and harvesting, none of which
this branch touches. (The `Parse JSON failed` lines in the log are
`test_gate_f_rig.gd` feeding malformed JSON to its own parser on purpose, and
the leaked-instance warnings at exit are the suite's usual teardown noise —
neither is a failure, and the summary line is the authority.)

**`tools/_probe_creature_clips.gd`: 25 species checked, 0 failed** — every
species reaches the game with a skeleton, an `AnimationPlayer` and a real clip
for all six declared roles. Five of the 25 failed this before the branch.

**`tools/_capture_t1_rig2_meadows.gd`: 0 failures, on five separate runs.**
Every shutter passed `CAPTURE_CHECK.require`; all five creatures changed pose
signature across the idle sequence every time.

`tests/smoke_art.gd` was not run — see "What is still dark".

## What is still dark

1. **`campfire_traveler` / `traveling_merchant`** — the owner question above.
   Unchanged in the game: not installed, not wired, not placed.
2. **The 15 civilian/trail NPC placements** that `ralph/T1-CREATURE-RIG` did
   and that have not landed on `main` either. Out of scope for this lane, but
   they are sitting finished on that branch and will be lost if it is never
   merged — worth a coordinator decision separate from this one.
3. **`tests/smoke_art.gd` was not run to completion here.** Two previous lanes
   recorded it running for tens of minutes in a software-rendered container
   without finishing, and this container is the same shape (a cold Godot import
   alone is ~25 minutes). `tools/_probe_creature_clips.gd` covers the specific
   check that matters for this lane's change — every species' model, skeleton
   and declared clips — in seconds, and is committed so the next lane does not
   have to choose between a 40-minute gamble and no answer. It does **not**
   cover smoke_art's scale, collider, shiny-variant or human-fit checks; CI runs
   the real thing.
4. **The locomotion evidence is the weakest of the three.** See the frames: a
   wild creature pressed against a bush has a real speed of zero and
   `creature_animator` correctly calls that standing still, so a live
   uncontrolled frame does not reliably catch all five mid-stride. The
   `walk-held` frame pins all five to the same point of their own walk clips to
   compensate. Both are in the shot set, labelled, and `motion.json` says which
   is which.
