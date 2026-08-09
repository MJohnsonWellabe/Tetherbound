# Done

Append-only. Newest at the top. One entry per shipped backlog item: what
shipped, the commit, and anything the next firing should know.

---

## R0.6 — Tuskroot finished (first of the ten)
`6c6e479` · `tools/art_pipeline/finish.py clean → texture → rig → grade →
install`, then `species.json`'s `tuskroot.placeholder.model` pointed at the
real GLB. `tests/smoke_art.gd`: **model 2.00m, collider 2.00m, exact match,
footprint clamp not tripped.**

**Correction to R0.5, found while starting this task: every one of the ten
R0.5 outputs was textured in the wrong order and none of them can be used.**
`cleanup_mesh.py`'s voxel remesh is what makes a generated mesh manifold
enough for bone-heat rigging, and it destroys UVs — its own docstring says so
and it hard-refuses to run on a model that already carries image textures.
`finish.py`'s documented order is clean → texture → rig for exactly this
reason. R0.5 textured the raw candidates directly, skipping `clean`. Measured
on Tuskroot's R0.5 output: 54,077 triangles (the budget is 30,000), 9,969
non-manifold edges, 5,170 duplicate vertices — un-rigging-safe, and
un-cleanable without losing the texture. The fix, done here for Tuskroot and
needed for the other nine: clean the raw candidate first (28,000 tris, 0
non-manifold edges, 0 duplicates), *then* retexture the clean mesh — a second
Meshy charge, ~10 credits, same as the first. Balance after both of
Tuskroot's texture passes: **265** (was 275, R0.5's own number, before this
firing's correction pass; see this entry's own spend below for the arithmetic
that actually matters going forward).

Also found and fixed: `grade.py` had zero `SPECIES` entries for any of the
ten wild creatures (only the three starters), and `finish.py` never called
`grade.py` at all — `install` copied the animated GLB straight from `rig`,
skipping grading entirely. Added a `grade` subcommand to `finish.py`
(`clean → texture → rig → grade → install`, matching the docstring's promised
"six commands" for the first time) and a `tuskroot` entry to `grade.py`'s
`SPECIES` table: three eye-guard rectangles (located by visual inspection of
the 2048² base_color atlas — this species has no head-close-up reference to
threshold against, unlike Terrapup), roughness rescaled to `ROUGHNESS_BAND`,
emissive off, specular 0.20. **Deliberately no hand-tuned palette shifts** —
unlike Terrapup/Ripplet/Galewisp's entries, no blind gate has reviewed
Tuskroot's colour yet, so only the structural fixes every creature needs are
applied. Grade report: eye guard protected 38,373 texels (0.0/255 delta
inside, confirmed), roughness 0.31–0.73 → 0.60–0.86, emissive map measured 0%
emission and zeroed.

Rigging: `rig_quadruped.py` on the correctly-cleaned mesh gave **15 bones, 0
of 14,000 vertices unweighted** — the residual non-manifold edges/duplicate
verts that Meshy's own retexture re-unwrap reintroduces (6,750 and 3,538,
down from the original 9,969/5,170) did not break bone-heat in practice, so
that specific worry did not need a further workaround. 6 clips from
`animate_quadruped.py`: idle, walk, run, attack, hit, faint.

**Found along the way, not fixed here:** `finish.py rig`'s animate step is
hardcoded to `animate_quadruped.py` regardless of `--kind`, and no
`animate_bird.py` exists — recorded in `BACKLOG.md` as a blocker for the four
bird species (Galecrest, Duskhush, Pipwing, Reedwing), not a blocker for the
six quadrupeds still ahead of them in backlog order.

Blender 4.2.9 and Godot 4.7-stable were not cached in this container and had
to be fetched (`tools/art_pipeline/setup.sh`) — routine, not a finding, but
worth knowing if a future firing's first minutes look unexpectedly slow.

## R0.5 — Retextured the ten R0.4 winners
`7ac1f20` · `tools/art_pipeline/meshy.py texture`, `image_style_url` aimed at
each species' own reference crop under
`assets/pals/tetherbound/<species>/reference/`. All ten went through in one
pass, no stopping partway: **375 → 275 credits, ~10 each** — a third of the
~30/species estimate, so the ~300 budgeted for the whole roster covered it
with 100 to spare.

Force-added like R0.1's candidates — `model.glb`, `provenance.json`,
`thumbnail.png` per species under `assets_raw/<species>/textured/`, `.fbx`/
`.obj` left out as duplicate geometry. Balance check: **275 remaining**, no
`BLOCKED.md` entry needed.

Next up is R0.6 (cleanup/remesh → rig → clips → grade → install), which is
also where R0.4's flagged defects need addressing: brooktail's missing paddle
tail (a genuine hard fail carried forward, needs real sculpting), burrowback's
under-scale claws, tuskroot's plate edges, galecrest's blunt talons — none of
these are texture problems, so retexturing didn't and couldn't fix them.

## R0.4 — Blind critique, picked a winner per species
`46ea130` · Ten fresh subagent critics, each shown only one species'
`compare.png` and its canon text (roster one-liner + the capitalised
signature-feature brief from `meshy.py`'s `SPECIES_PROMPTS`), scored
silhouette, proportion and the signature feature on the untextured white
candidates. All ten scorecards filled (`shots/candidates/<species>-compare.md`)
and summarised in the new `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md`.

Winners: Brooktail a, Burrowback c, Duskhush a, Galecrest a, Meadowhart a,
Mosshell b, Paddlenewt a, Pipwing b, Reedwing a, Tuskroot a.

**Nine clean picks, one flagged defect carried forward:** Brooktail's winner
still has a HARD FAIL — every candidate for that species is missing the
canon's broad flat paddle tail (both give a round tapering tail instead).
Recorded honestly rather than hidden behind score totals; it ships into
R0.5/R0.6 with the defect flagged for a sculpting pass, since retexturing and
rigging don't touch the tail's shape. Several other species have shared,
non-blocking defects noted for the R0.6 cleanup/remesh step (burrowback's
claws, tuskroot's plate edges, galecrest's talons) — see the production
report's table.

Also wrote `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` for the first time
(R0.8 still owes it a provenance-row pass and the missing
Bramblebun/Mudsnout/Trailpup production record, both noted as known gaps in
the file itself).

## R0.3.5 — Fixed the `smoke_catching` flake
`5c919ba` · Three bugs in `tests/smoke_catching.gd` itself, no production combat
code touched:

1. `throw_aim.gd`'s silent 0.9s post-throw cooldown made `try_begin_aim()` fail
   with no signal; the test pressed Throw once and moved on, burning most of
   its 25 attempts on presses that never opened an aim. Now retries
   (`_open_aim()`) until the aim actually opens or a budget past the cooldown
   is exhausted.
2. The test computed pitch from the trainer's hand; production's
   `_aim_direction()` deliberately aims from the camera eye, ~1.5m away via
   `aim.shoulder_offset`. Fixed to read the camera's actual `global_position`.
3. Added lead compensation via the target's `CharacterBody3D.velocity`,
   projected over the aim settle + `throw.release_windup`, since the target
   keeps moving during the aim window.

Also dropped drop compensation entirely — `_aim_direction()` snaps the throw
straight to the target's centre whenever the ray is within a body-width of it,
discarding any elevation added on top, so arcing the aim only risked pushing
the ray outside that snap window. Aiming straight at the (leaded) centre from
the eye keeps it inside instead.

**Verified 11/11 consecutive headless green** (one standalone confirmation run,
then 10 more back to back — required bar was 10). CI on `ralph/R0.3.5` also
went green (run 31290404377).

The earlier "catch versus kill race" diagnosis recorded in a previous backlog
entry never reproduced and was retracted before this fix; it is not part of
what changed here.

## R0.3 — The ten comparison sheets
`5e0f1cc` · concept row over candidate rows, same four angles at one scale, plus
a blank scorecard with a HARD FAIL column per species. Meadowhart's sheet
confirms the `DROP_FOR_SPECIES` fix worked: all three candidates carry the
saddle, stirrup and leaf collar.

## R0.2 — `rig_bird.py` merged
`861c38a` · Proportion-driven bird armature emitting the roster's six standard
clips. Serves Reedwing, Pipwing, Duskhush and Galecrest. Written but **not yet
exercised on a real candidate** — R0.6 is its first real use, so treat its first
run as verification.

## R0.1 — The candidate models and renders are tracked
`1983352` · 26 GLBs and 104 renders force-added out of gitignored scratch
directories. They are 520 Meshy credits that cannot be regenerated on the 375
remaining. `assets_raw/.gdignore` added so Godot does not import them into the
Windows build.

## Pre-Ralph — the session that set this up

- **D17: an evolution is always larger**, with `tests/test_evolution_links.gd`
  enforcing it. Owner instruction.
- **Grading fixed.** One shared `grade.py` replaces three per-species scripts.
  Ripplet's clipped white 33.4% → 0.00%, Galewisp 28.5% → 0.00%, Ripplet's
  emissive (lighting 38% of itself) zeroed, Terrapup verified not to regress at
  0.36/255 outside the eye guard.
- **The sequence director written** — the file three places in the repo already
  claimed existed. Beat order driven from `opening.json`, not an enum.
- **`name_prompt.gd` did not parse** under Godot 4.7, so the naming panel was
  instantiating scriptless and beat 5 could never have worked. Found
  independently by two agents. Fixed.
- **The phantom party is gone.** `party_seam.gd` looked up `/root/GameState`
  against an autoload registered as `Game`, with a mismatched API, so it kept a
  second five-slot party beside the real one. A tautological assertion —
  `assert_true(answer or not answer)` — is why nothing ever said so.
- **Docs brought onto the wild-roster canon.** Ridgewolf and Terracrown retired,
  Mudsnout added, Tuskroot moved to the one evolution the biome has.
- **The negative prompt list stopped banning three creatures' own signatures** —
  a deer's long legs, a deer's saddle, an otter's paddle tail.
- **All ten species generated**: 895 → 375 credits, exactly the 520 planned, no
  re-rolls.

Suite went 247 → 277 tests over the session.
