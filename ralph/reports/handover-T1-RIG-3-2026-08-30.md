# Handover — T1-RIG-3, 2026-08-30

Branch `ralph/T1-RIG-3`, off `origin/ralph/T1-RIG-2` (`ed6b35d4`), with
`origin/main` merged in (see §0).

**This is a verification lane, not a rigging lane.** `T1-RIG-2` rigged and
animated the five expansion creatures. Nothing here re-does that work.

Read first: `ralph/reports/handover-T1-RIG-2-2026-08-30.md`. This file assumes
it and only records what independent testing found.

---

## Verdict

**T1-RIG-2's central claim — "proved in the Meadows" — holds.** Re-tested from
scratch with an instrument written without reference to its tooling, against
its binaries, in the real world. All five animate: idle, locomotion, attack,
hit and faint. Table in §2.

**Its two open humanoids are still open, and its own diagnosis of one of them
is incomplete in a way that makes the fix much cheaper than it costed.** §3.

---

## 0. A base correction, and a merge that was not in the brief

`origin/ralph/T1-RIG-2` was one commit ahead of its own start point and **56
commits behind `origin/main`** — it branched from `5d171130` and `main` moved
on. Verifying "it works in the shipping world" against a world 56 commits stale
would not have been worth much, and landing the branch as it stood would have
reverted everything `main` gained in between.

So `origin/main` is merged into this branch. It is now 0 behind. Four conflicts,
all resolved deliberately:

- **`cindercub` and `frostclaw` `.glb`** — the only two binary conflicts, which
  is itself a confirmation: `T1-RIG-2`'s commit message claims the other three
  meshes "re-export byte-identically", and git agrees, because they merged
  without a conflict at all. **Resolved to T1-RIG-2's versions**, which are the
  ones carrying `repair_unweighted()`. `main`'s copies come from
  `T1-CREATURE-RIG`, which rigged the same five independently and did not fix
  the unweighted vertices.
- **`data/creatures/species.json`** — five conflicts, all of them provenance
  comment prose, no functional difference. Resolved to T1-RIG-2's text.
- **`docs/ASSET_LEDGER.md`** — two additive sections claiming the same work from
  two lanes. **Both kept**; `T1-CREATURE-RIG`'s section also covers the 15 NPC
  placements, which are real and on `main`.

Flagging this because it is a judgement call the brief did not ask for. If the
coordinator intended this branch to land as a narrow diff against the old base,
the merge commit is the first thing to drop.

### Two lanes rigged the same five creatures

Worth stating plainly for whoever lands this: `T1-CREATURE-RIG` (on `main`) and
`T1-RIG-2` (this base) both rigged all five, the same day, through the same
local Blender pipeline, without knowing about each other. The outputs are
identical for three species and differ for `cindercub` and `frostclaw` only.

**T1-RIG-2's are the better ones**, and this is measurable rather than a matter
of preference — see the bone counts in §2.

---

## 1. What was verified, and how

Two instruments, both written for this lane, neither derived from T1-RIG-2's.

**`tools/_probe_creature_animation_in_world.gd`** — boots
`scenes/world/meadows_playground.tscn`, spawns each species through the real
`encounter_director.spawn_wild()`, and asks whether a **bone pose actually
changes**, sampled off the live node in the live world. Skeleton-*local*
transforms, so a frozen creature slid across terrain cannot pass. Measured for
idle, for a real `request_move`, and for each of the three combat one-shots
(`play_attack`/`play_hit`/`play_faint` — peak deviation, since a one-shot is a
round trip). `terrapup` and `pipwing` run as controls.

This is deliberately a different question from T1-RIG-2's `motion.json`, which
records a per-bone pose *signature at shot time*. A signature proves the
skeleton is posed; a delta proves it is moving. The two agree, which is worth
more than either alone.

**`tools/_capture_creature_animation_world.gd`** — the same question as frames,
shot as A/B pairs, `CAPTURE_CHECK.require` at every shutter (12 of 12 clean:
"grass field bound to this camera and drawing").

---

## 2. Results — all five move

| species | | bones | idle | locomotion | attack | hit | faint |
|---|---|---|---|---|---|---|---|
| terrapup | control | 15 | 0.261 | 4.87 | 8.95 | 3.49 | 11.24 |
| pipwing | control | 19 | 3.237 | 6.60 | 11.47 | 12.47 | 14.12 |
| **sparkit** | | 15 | 0.259 | 3.44 | 3.50 | 1.73 | 11.21 |
| **cindercub** | | **15** | 0.261 | 5.12 | 9.12 | 3.05 | 11.88 |
| **shadelet** | | 15 | 0.258 | 5.09 | 8.75 | 3.10 | 11.21 |
| **frostclaw** | | **15** | 3.393 | 1.91 | 3.93 | 3.44 | 11.51 |
| **bramblebun** | | 15 | 0.260 | 3.45 | 6.71 | 6.72 | 11.21 |

**PASS — every species animates in the real world, on every role the game
drives.** The five are indistinguishable from the two long-shipping controls.

### The bone counts independently confirm `repair_unweighted()`

`cindercub` and `frostclaw` read **15 bones here and 16 on `main`.** That
difference is the whole of T1-RIG-2's mesh fix, showing up in a measurement
taken for another purpose entirely.

The extra bone on `main` is the glTF exporter's static `neutral_bone`, which it
synthesises to bind vertices that automatic weights left with no influence — 35
on cindercub, 20 on frostclaw. It sits at the armature origin and never moves,
so those vertices are anchored to a fixed point while the rest of the mesh
animates around them. T1-RIG-2 called this "a latent failure, not a visible
artefact" and its own before/after pose renders back that up. The repaired
meshes have no such bone because they have no unweighted vertices. Its claim is
correct and now has a second, independent line of evidence.

### The frames

`ralph/reports/T1-RIG-3/shots/<species>-{a,b}.png`, six species, real Meadows —
real terrain, real grass, real scatter, real light. Looked at, not just counted:
in the `cindercub` pair the head, ear angle and body all shift between
exposures, with no tearing and nothing anchored at the origin.

**Honest caveat on the printed pair-difference percentages (26–41%):** they are
*not* a clean measure of creature motion. The world's grass moves in the wind
between exposures and fills most of the frame, so it dominates. The frames are
corroborating evidence that the creature is really in the world and really
changes pose; the bone probe is the measurement.

### T1-RIG-2's own evidence was checked, not assumed

`ralph/reports/T1-RIG-2/shots/close-frostclaw.png` is a genuine 1280×720 Meadows
frame — grass field present and drawing, real terrain, real water, the village
building in shot, frostclaw clearly mid-stride. Its `motion.json` records
`bones: 15` for all five, matching §2 exactly. **The claim was not overstated.**

### Two measurement bugs, both caught by a control disagreeing

Recording these because both produced confident, well-evidenced, wrong answers.

1. **Sampling bone *position* instead of transform.** The first probe reported
   **six of seven creatures frozen, including `terrapup`**, which has animated
   since it shipped. Skeletal clips animate rotation almost exclusively, so a
   good walk cycle has an identical position signature every frame. `pipwing`
   was the lone "pass" only because bird-rig wing clips carry translation keys.
   Without a control this lane would have reported a fictional roster-wide
   regression.
2. **Comparing endpoints instead of peak, on the one-shots.** An attack is a
   round trip. The first run reported *"shadelet: HIT one-shot drove no bones."*
   It drives bones fine; it measures 3.10 once peak deviation is tracked.

### One flagged observation, not fixed

Every quadruped idle measures **~0.26** against **~5.0** for its own locomotion,
and against `pipwing`'s bird-rig idle of 3.2. This is deliberate —
`animate_quadruped.py::author_idle` says so: *"Amplitudes tiny: idle is what the
player stares at in camp, and big motion reads as agitation"*, keys of 1.2°–6.0°.

Flagged because a nearly-invisible idle is the most plausible way a player could
still call a correctly-animated creature a statue. **Not changed**: it is a
settled art call with a written rationale, it would mean re-baking every
quadruped in the roster rather than this lane's five, and it is visual-affecting
work that `ralph/conventions.md` requires a blind visual-judge pass for.

---

## 3. The two humanoids — finished as far as it can go without a spend

T1-RIG-2's diagnosis is right about the important thing and I confirmed it
independently: **the meshes were never committed** (`assets_raw/` is gitignored
and tracks 14 subjects, neither of these), so "re-run the rigger" was not an
option that existed. It is also right that the inherited "crossbow fused across
both hands" line for `campfire_traveler` is false — her board draws a plain
arms-down turnaround, and the long open coat merging her arm silhouette is the
better hypothesis.

Three things this lane adds.

### 3a. The rigging history has no failed task, confirming a submit-time reject

`GET /openapi/v1/rigging` returns **23 tasks, all `SUCCEEDED`.** Neither subject
appears. The `422 Pose estimation failed` was a synchronous rejection at submit,
not a task that ran and failed — so there is nothing server-side to resume, and
no partial output to recover from the rig step.

### 3b. `traveling_merchant`'s geometry is still on Meshy, and free

Its two `text-to-3d` tasks are still live, `SUCCEEDED`, **`expires_at: null`**.
Both `.glb`s downloaded (free, signed asset URLs) and inspected: 1.5 MB,
single-mesh, `skins: 0`, untextured — preview tier, as expected.

So T1-RIG-2's "there is nothing to re-rig" is true of the repository and of
`campfire_traveler` (image-to-3D, list returns empty), but **not** of
`traveling_merchant`. Its geometry is recoverable at zero cost.

### 3c. The wrong candidate was rigged — and this changes the recommendation

Both recovered candidates were rendered through
`tools/art_pipeline/blender/turntable.py` and looked at. Frames committed at
`ralph/reports/T1-RIG-3/merchant_candidates/`.

- **Candidate 1** (`01a04f33-0c76…`): arms **folded across her chest**, one hand
  up near her chin. This is the "arms crossed over her body" the record
  describes. This is the mesh that failed.
- **Candidate 0** (`01a04f33-162c…`): arms **down at her sides**, slightly bent,
  hands resting near a satchel at the waist. The side view confirms both arms
  hang clear alongside the torso. **This is close to a rest pose, and there is
  no evidence it was ever submitted to the rigger.**

Two candidates were paid for and only one was tried. The crossed arms are, as
T1-RIG-2 correctly says, a text-to-3D artefact rather than something the board
asked for — but the artefact only landed on one of the two rolls.

**This does not make the merchant fixed.** It makes the next step a 5-credit
rig call on a mesh already paid for, instead of the 55-credit regeneration
T1-RIG-2 costed. The arms still rest close to the hips, which is the same class
of limb-landmark problem as the coat, so it may still fail — but it is the
cheapest possible decisive test and it has never been run.

### Revised owner question

Balance **515 credits**, unchanged. Costs: rig 5, retexture 10, preview 20,
refine 30.

| | Cost | What you get |
|---|---|---|
| **B′. Rig merchant candidate 0, then retexture it** | **~15** | The likeliest cheap win. Geometry already paid for; the untried candidate has a near-rest pose. Fails → you have spent 5 to learn the rigger cannot take this cast at all, which is worth knowing before any future NPC round. |
| **B. Regenerate `campfire_traveler`** | ~55 | T1-RIG-2's recommendation, still sound — her reference is good and the failure was downstream of it. The coat is the untested variable. |
| **A. Reuse an installed body** | 0 | `CLAUDE.md`'s default rule. Costs two of your 24 board designs their own mesh. |
| **C. New reference art, then regenerate** | ~110 + drawing time | Highest odds. For the merchant specifically, C is now **hard to justify** — B′ has not been tried. |

**Recommendation: B′ first, then B.** B′ was not run by this lane: the brief
scoped it to diagnosing before re-running anything, and a rig call is a spend of
the owner's credits on a hypothesis rather than an implementation of a settled
directive.

---

## 4. How to re-run any of this

Fresh container, in order:

```
tools/art_pipeline/setup.sh all              # Blender 4.2.9 + Godot 4.7-stable
apt-get update && apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers xvfb
godot --headless --path . --import           # ~45 min here; required
godot --headless --path . --script tools/_probe_creature_animation_in_world.gd
xvfb-run -a -s "-screen 0 800x450x24" godot --path . \
  --rendering-driver opengl3 --resolution 800x450 \
  --script tools/_capture_creature_animation_world.gd
```

Probe ~6 min, no display needed. Capture ~25 min.

### A number for the next lane's render budget

**A full-Meadows frame at 1280×720 under llvmpipe costs about twenty seconds
here.** The first capture attempt used 1280×720 and let real time pass between
each pair's two exposures — 38 rendered frames per species — which came to
roughly two hours and was killed having written nothing. Two changes fixed it:

1. **800×450** — a quarter of the pixels, still ample to see a limb move.
2. **Pose the AnimationPlayer with `seek()` instead of waiting.** The gap
   between exposures need not be real time; `anim.seek(t, true)` winds the
   skeleton to an exact point in the clip for free. 38 rendered frames per
   species became 2, and the pair became a *better* comparison — an exact,
   repeatable distance into the clip, with nothing else in the world given a
   chance to drift.

Any future tool needing "the same thing at two moments" should reach for the
second trick before budgeting frames.

---

## 5. Tests

No production code was changed by this lane. The diff is the merge of `main`,
two new `tools/` scripts, evidence frames, and this handover — so the probe and
the capture above are the tests that matter, and both are recorded in full.
T1-RIG-2's own suite run (1545 tests, 282,894 assertions, 0 failed) stands.

Neither new tool is wired into CI, matching every other `_probe_*`/`_capture_*`
tool's convention.

---

## 6. Meshy API call log

Every call, and what it cost. **Total spend: 0 credits. Balance 515 before and
after.**

| # | Call | Purpose | Cost |
|---|---|---|---|
| 1 | `meshy.py check` (`GET /openapi/v1/balance`) | verify the key | 0 — read-only |
| 2 | `GET /openapi/v1/rigging?page_size=100` | look for the two failed rig tasks | 0 — read-only |
| 3 | `GET /openapi/v2/text-to-3d?page_size=100` | find recoverable geometry | 0 — read-only |
| 4 | `GET /openapi/v1/image-to-3d?page_size=100` | same, image-to-3D subjects | 0 — read-only |
| 5 | `GET /openapi/v1/retexture?page_size=100` | same, textured outputs | 0 — read-only |
| 6 | `GET /openapi/v1/text-to-texture` | same | 0 — read-only |
| 7 | 9 × asset thumbnail downloads | identify which subject each retexture belongs to | 0 — signed asset URLs |
| 8 | 2 × `merchant` `.glb` downloads (`assets.meshy.ai`) | recover and inspect the two candidates (§3b, §3c) | 0 — signed asset URLs |

No generation, refine, retexture, rig or animate call was submitted.

**No API key appears in this repository.** It was exported into the shell and
read from `$MESHY_API_KEY` only; every commit on this branch was scanned for the
literal before pushing.
