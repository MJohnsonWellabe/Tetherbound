# Done

Append-only. Newest at the top. One entry per shipped backlog item: what
shipped, the commit, and anything the next firing should know.

---

## R0.8 — ASSET_LEDGER rows for the four shipped R0.6 creatures (partial)
`92fc1ae` · Not R0.8 complete — six R0.6 species (Mosshell, Brooktail, and the
four birds) have no model yet, so no row for them either; they land as each
model does, the same rule R0.7 already applies to `species.json` entries.
Rows added for Tuskroot, Meadowhart, Burrowback and Paddlenewt, matching the
existing table's per-creature style (Bramblebun/Mudsnout/Trailpup).

**Why this instead of R0.6/Mosshell**, which is the actual next item in
order: this firing's `send_later` self-resume did not carry
`MESHY_API_KEY` — only a cron-fired session's prompt does, a distinction
this session had to learn twice (see the R0.6 Paddlenewt entry above for the
first time, and `BLOCKED.md`'s current top entry for the fuller writeup).
Mosshell's `clean` step (Blender only, no key needed) was done and is not
committed — cheap to redo. Doing R0.8's ledger work instead of idling kept
the firing's context used on real, unblocked project state rather than
nothing.

CI green (run 31303384277), fast-forwarded to `main` at `92fc1ae` — verified
by fetching `origin/main` directly.

## R0.6 — Mosshell finished (fifth of the ten)
`e15a204` · Same pipeline as the previous four: clean raw R0.4 winner
candidate `b` (54,396 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 13,998 vertices unweighted, 6 clips) →
`grade.py` SPECIES entry → `finish.py grade` → `finish.py install` →
`species.json` entry from the Water Sheet's own Steady Tank/Shelter role and
build notes.

**Four eye-guard rectangles**, same duplicated-across-UV-islands pattern the
previous four species already showed, found by the same systematic
quadrant-by-quadrant scan of the full 2048² atlas. Several candidates
checked and rejected this time: a pair of uniform amber blobs matching the
ordinary scale/wart spots scattered across the rest of the shell texture (no
pupil at all), a tan almond/slit shape that reads plausibly as a closed
eyelid rendered into the stone-shell pattern but wasn't confident enough to
guard, and a dark crevice with an amber edge but no round iris.

**R0.4's report flagged a topology check** — a possible thin protrusion near
the hindquarters that might read as an errant tail/spike — that this pass
could neither confirm nor rule out: this container has no `libEGL.so.1`, so
`turntable.py` cannot render a single frame to actually look at (same gap
hit on both Burrowback's and Paddlenewt's containers, apparently a property
of the container rather than a one-off). `inspect_glb.py`'s structural
report on the graded model showed only the ordinary post-retexture
non-manifold-edge/duplicate-vertex noise that rigging already tolerated
fine (0 unweighted vertices) — nothing that specifically flagged a
hindquarters anomaly, but that report can't see silhouette either.
Documented honestly in `species.json`'s `_comment_art` for whoever next has
a rendered frame to check against.

**This task spanned two firings**, same shape as Paddlenewt's: the first
firing (a `send_later` self-resume) had no `MESHY_API_KEY` — confirmed this
is specific to self-scheduled resumes, not cron firings, which is now a
settled fact rather than a surprise each time it happens. That firing did
Mosshell's Blender-only `clean` step, recorded the block in `BLOCKED.md`,
and pivoted to real unblocked work instead of idling: `docs/ASSET_LEDGER.md`
had no per-creature row for any of the four R0.6 species shipped so far,
despite R0.8 asking for exactly that — added rows for Tuskroot, Meadowhart,
Burrowback and Paddlenewt (`92fc1ae`, `17b5caa`, both verified shipped to
`main`). The next firing was cron-fired, carried the key correctly, and the
same `clean.glb` survived in the same container so nothing was redone.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous four: **wanted 1.620m,
rendered 1.620m, exact match.** Not committed.

CI green (run 31304748414), fast-forwarded to `main` at `e15a204` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **225** (was 235).

## R0.6 — Paddlenewt finished (fourth of the ten)
`0f51b2a` · Same pipeline as the first three: clean raw R0.4 winner candidate
`a` (56,476 → 28,000 tris, manifold) → retexture via Meshy → `rig_quadruped.py`
(15 bones, 0 of 13,998 vertices unweighted, 6 clips) → `grade.py` SPECIES
entry → `finish.py grade` → `finish.py install` → `species.json` entry from
scratch.

**This task spanned two firings because `MESHY_API_KEY` was missing from the
first one's prompt.** That firing completed the Blender-only `clean` step
(no key needed), found `meshy.py check` reporting the key simply unset — not
rejected, not rotated, just absent — recorded it in `BLOCKED.md` as a genuine
blocker distinct from the credit balance, and pivoted to unblocked work
instead of guessing a key (that pivot is its own separate, uncommitted
tangent — see below). The next firing's prompt carried the key correctly;
the block was reverted since it no longer applied, and the same `clean.glb`
survived in the same container so nothing was redone.

**Five eye-guard rectangles, not one or two.** The 2048² base_color atlas
showed the same duplicated-across-UV-islands pattern Galewisp (six
rectangles) and Tuskroot (three) already showed: every guarded region
carries an identical amber/gold iris ring around a dark pupil, four of five
also with a white catchlight — a texel-for-texel-consistent signature no
ordinary skin blemish produces. Found by a systematic scan (five overlapping
crops, then all four quadrants of the full atlas checked for anything
missed) rather than stopping at the first eye found. Two other dark patches
were checked and rejected: one had no iris ring (a shadowed crease), the
other an amber smear with no black pupil.

`species.json` entry: height 1.50 (R0.7's list, `D13`), stats from the
**Water Sheet** (`docs/art/reference/wild/03_Meadows_Wild_Water_Sheet.png`)
rather than Ground Sheet B — Paddlenewt is the first Water-roster creature
finished. Its subtitle is "Quick Swimmer & Skirmisher" and build notes read
"agile amphibious body... webbed toes for quick bursts... soft fins", not a
sheet with the Ground trio's ROLE/STRENGTHS table format, so the stat
reasoning is transcribed from the subtitle and build notes instead: lowest
defence on the roster (12, soft-bodied and unarmoured), attack in the
upper-middle band (20, a skirmisher hits fast), HP on the low side for a
small creature (90). Non-aggressive — the sheet's own Water-roster design
notes call the whole group "friendly... calm spirits" and Paddlenewt's
listed actions are WATER DASH and PLAYFUL POUNCE, not a hunt.

**R0.4's report flags a cosmetic tail defect on this winner** (short/abrupt
paddle-fin rather than the canon's long taper) — not a hard fail, so per the
pipeline's iterate-on-what-exists philosophy it was documented in both
`grade.py`'s comment and the `species.json` `_comment_art` field rather than
sculpt-fixed, the same treatment Burrowback's claw-scale note and Tuskroot's
plate-edge note got.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous three: **wanted 1.500m,
rendered 1.500m, exact match.** Not committed.

CI green (run 31301653288), fast-forwarded to `main` at `0f51b2a` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **235** (was 245 at the start
of the second firing — 10 lower than the 255 recorded at the end of
Burrowback's firing, for reasons not accounted for here; balance is read
directly from `meshy.py check` each time rather than assumed, so this is not
a discrepancy in the record, just an unexplained gap between two firings).

## R0.6 — Burrowback finished (third of the ten)
`ccb295a` · Same pipeline as Tuskroot/Meadowhart: clean raw R0.4 winner
candidate `c` (52,818 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 14,004 vertices unweighted, 6 clips,
`hit` 12 frames / `faint` 36 frames) → `grade.py` SPECIES entry → `finish.py
grade` → `finish.py install` → `species.json` entry from scratch.

**Only one eye could be guarded with confidence.** The badger's dense
stone/moss camouflage pattern makes a second symmetric eye hard to
distinguish from ordinary texture noise in the 2048² base_color atlas —
rather than guess a rectangle and risk it landing on fur (grading destroys
whatever it is not told to protect), only the one confirmed amber/yellow
iris with a white catchlight is guarded. Documented in `grade.py` itself;
worth revisiting in a later pass if grading is seen eating a second eye.
Grade report: roughness rescaled 0.494–0.706 → 0.60–0.86, emissive off,
specular 0.20.

`species.json` entry: height 1.70 (R0.7's list, `D13`), stats from Ground
Sheet B's own printed ROLE (Defender/Excavator), SIZE CLASS (Medium) and
STRENGTHS (Defense, Digging, Control) lines — highest defence on the roster
so far (23, ahead of Tuskroot's attack lead), moderate HP (110) rather than
tanky-huge for a Medium size class, non-aggressive since a defender protects
territory rather than hunts. All flagged tunable; nobody has fought one yet.

**Burrowback is not in `EncounterDirector.WILD_SPAWNS`** (still only
`bramblebun`, `tuskroot`), so `smoke_art`'s shared run does not spawn it
directly — though its `_every_species_has_art()` pass does confirm the model
path resolves, and the run stayed green (`bramblebun`, `tuskroot`,
`terrapup`, trainer, vegetation all OK). Height-fit verified with the same
small standalone script as Meadowhart (`scenes/pals/pal.tscn` + `wild_pal.gd`
attached + `setup(id)`, then `smoke_art.gd`'s own `_rendered_height()` copied
verbatim): **wanted 1.700m, rendered 1.700m, exact match.** Not committed —
cheap enough (~15 lines) to rewrite per species.

CI green (run 31299327633), fast-forwarded to `main` at `ccb295a` — verified
by fetching `origin/main` directly, not by trusting the CI badge.

Meshy balance after this species' texture pass: **255** (was 265).

## R0.6 — Meadowhart finished (second of the ten)
`f1495d1` · Same pipeline as Tuskroot: `finish.py clean → texture → rig →
grade → install`, candidate a. `rig_quadruped.py`: 15 bones, 0 of 13,994
vertices unweighted. 6 clips.

**Unlike Tuskroot, Meadowhart had no `species.json` entry at all** — Tuskroot
came with a Plumberry placeholder to repoint, Meadowhart did not exist in the
table yet. Added one from scratch: height 1.95 (R0.7's list, `D13`), stats
from Ground Sheet B's own printed ROLE (Rideable/Pathfinder), SIZE CLASS
(Large) and STRENGTHS (Speed, Stamina, Navigation) lines — moderate HP for
its size class, attack/defence both below the roster's combat specialists
since nothing on the sheet says this creature fights. All flagged tunable.

**Meadowhart is not in `EncounterDirector.WILD_SPAWNS`**, so the shared
`smoke_art` run doesn't spawn it and its height-fit was never actually
checked by that pass. Verified instead with a small standalone script
(`scenes/pals/pal.tscn` + `wild_pal.gd` attached + `setup(id)`, then
`smoke_art.gd`'s own `_rendered_height()` copied verbatim) — **wanted 1.95m,
rendered 1.95m, exact match, 0.0000 diff.** Not committed; cheap enough
(~15 lines) to rewrite per species rather than add permanent test
infrastructure for a gap that R0.9's real spawn work may close anyway. Also
ran the full unit suite since a new species.json entry touches
`test_catch_math`/`test_evolution_links` territory: 277 tests, 0 failed.

Grade.py: two eyes, structural fixes only, no hand-tuned palette (same
first-pass philosophy as Tuskroot).

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
