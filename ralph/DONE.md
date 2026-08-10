# Done

Append-only. Newest at the top. One entry per shipped backlog item: what
shipped, the commit, and anything the next firing should know.

---

## VP2 — Fix `tools/preview_creatures.gd` rendering zero creatures
`ce6205d` on `ralph/VP2` (fast-forwarded to `main`, verified via `main`'s
commit log and CI: Release + Ralph auto-merge both green at `ce6205d`).
`tests: none` (as named on the backlog item).

Three real bugs, all found by actually running the tool under Godot 4.7
headless, not by reading the code:
1. `BODY.new()` built a bare `CharacterBody3D` instead of instantiating
   `scenes/pals/pal.tscn`, so every `@onready` child lookup
   (`$Collision`/`$Model`/`$Body`/`$Head`) failed silently. Fixed by
   instantiating `pal.tscn` and attaching the script before `add_child()`,
   matching `encounter_director.gd`'s own pattern.
2. Once building succeeded, `setup()`'s `is_inside_tree()` guard was still
   false through `_init()`'s whole synchronous burst. Fixed with one
   `await process_frame` before building anything — the same quirk
   `render_bounds.gd`'s header already names for `global_transform`.
3. With both fixed, models still didn't render: every body is a
   `CharacterBody3D` and the preview card has no floor collider, so
   gravity dropped each one out of frame over the 120-physics-frame wait
   before the screenshot. Fixed with `set_physics_process(false)` right
   after `setup()`.

Verified by looking at the actual rendered PNG: all 17 species visible at
their gameplay heights beside the trainer-height bars, zero engine errors.

This closes out the mechanical half of Phase -0.5's tooling debt — the
tool built to catch cross-species scale errors now works, ahead of R5.1/
R7.1/R7.2/R9.4 which need it.

## VP1 — Fix `tools/survey.gd`'s stale viewpoints
`153f802` on `ralph/VP1`. `tests: none` (as named on the backlog item).
Verified by actually running
`tools/survey.sh` against the live world (Godot 4.7-stable fetched fresh via
`tools/art_pipeline/setup.sh godot`, `libegl1`/`mesa-vulkan-drivers`
installed, import cache built) and inspecting all five rendered frames —
not just asserting the fix.

**Both bugs' real causes turned out to be different from what the backlog
entry and the 2026-08-09 review guessed, found by instrumenting the actual
running scene rather than reasoning from the code:**

- **01/05** ("renders the farmhouse interior"): not the farmhouse. The
  overhaul (D18) placed `village.json`'s Barn at world `(2, 2)` — 2.8m from
  an eye sitting at `(0, 0)` and lying almost exactly on the old
  `(150, 120)` target line (perpendicular distance 0.31m). The camera was
  nose-against the barn wall, rendering its unlit inside. Confirmed by
  dumping every Node3D within 30m of the eye position and reading off
  `Barn_Collision` at `(2, 2, 2)`. Fixed by moving the eye to `(-9, -7)`
  (nearest structure now 14m+ away) and re-aiming at the pond-valley path
  instead of back through the village.
- **03/04** ("camera embedded in terrain, stale heightfield"): the
  heightfield was never stale — `ground_height_at()` (the real baked
  Terrain3D query) and `playground_heightfield.gd`'s pure recomputation
  matched exactly (diff 0.00) at every point checked, including both
  viewpoints' eye and peak coordinates. The real bug: `_place_actor()`'s
  fallback for viewpoints with no `actor` key parked the player at a fixed
  `(9000, 200, 9000)`, nowhere near the baked 512m world. That silently
  broke Terrain3D's own mesh streaming for the whole scene, not just around
  the player — proven by re-rendering 03 and 04 with their *original*,
  unchanged eye/target/horizon and only the player left near the camera
  instead: both rendered correctly, real ground and all. Fixed by parking
  the player 500m straight down from the eye's own XZ instead — inside the
  region Terrain3D is already streaming for that shot, and far enough below
  ground to stay out of every authored frame. No coordinate changes were
  needed for 03 or 04 themselves.

All five frames now render real geometry (`_flatness` spread 1.41-1.57
across the board, comfortably above the 0.01 failure floor) and were
visually confirmed by eye, not just by the spread check. `tools/survey.sh`
exits clean with no `FAIL:` lines.

Next firing on `R9.4`/anything that re-runs the survey: the fix is in
`_place_actor()` itself, so any future viewpoint added without an `actor`
key is safe by default — no per-viewpoint parking logic needed.

## RB1 — Mouse look does not work
`1eeb4c1` on `ralph/RB1`. `tests: smoke_menu, smoke_opening` (no `tests:`
field was named on the backlog item; these were the two smoke tests that
already exercise `Input.mouse_mode` end to end, so they were the closest
thing to a relevant regression suite).

**Diagnosis, confirmed by reading the code (not by reproducing the bug —
that needs real Windows, see below):** `playground_world.gd`'s `_ready()`
set `Input.mouse_mode = MOUSE_MODE_CAPTURED` exactly once, unconditionally,
at the end of boot, and nothing ever re-asserted it. That is a known Godot/
Windows gotcha: a capture request made before the native window has
actually received OS input focus can be silently dropped — `Input.mouse_mode`
still reads back CAPTURED, so nothing downstream (including a test) can
tell the difference, but the cursor is never really confined and
`camera_rig.gd`'s `_unhandled_input` (which only turns mouse motion into
look when `Input.mouse_mode == MOUSE_MODE_CAPTURED`) never receives real
deltas. That matches the owner's report exactly: everything else worked,
mouse look did not, from the first frame.

**Fix:** `playground_world.gd` now connects to `Window.focus_entered` and
re-asserts capture on every focus gain (boot included), through a new
`_capture_mouse_if_free()` that backs off via `_mouse_wanted_elsewhere()`
whenever the pause menu, the dialogue panel or the naming prompt currently
owns the mouse — so a focus regain while one of those is open cannot yank
the cursor out from under it. This is additive: the original unconditional
boot-time call still happens (nothing was open yet), so no existing
behaviour changed; the new path is the retry on every subsequent focus
event, which is exactly the moment a dropped boot-time capture needs one.

**The Grandpa-interact report, checked as the item asked:**
`interaction_arbiter.gd` is purely proximity + button (`interaction_offer`
by distance, `Input.is_action_just_pressed("interact")`) — nothing in it
reads `Input.mouse_mode` at all, and `smoke_opening.gd`'s beat 3 (talking to
Grandpa) passes headless, so the arbiter's own logic is sound when the
player can reach him. The most likely explanation, not a confirmed one: if
the owner was playing mouse+keyboard with the camera stuck at its spawn
yaw, they may simply have been unable to turn toward Grandpa to get in
range — a symptom of RB1, not a second bug. Left unfixed on purpose: there
is no independent diagnosis to fix, and inventing one without evidence is
exactly what this loop is told not to do. Worth the owner specifically
re-checking after this fix, before anyone spends more time on it.

**What is NOT proven, and cannot be from here:** whether real OS-level
mouse capture actually happens on an exported Windows build. Per
`smoke_menu.gd`'s own long-standing note, the dummy `DisplayServer` under
`--headless` reports `Input.mouse_mode` as VISIBLE no matter what is
requested — it cannot even confirm the *original* boot-time capture landed,
let alone this fix's retry path. `smoke_menu.gd` gained a new check
(`_check_focus_recapture_respects_open_ui`) that proves what headless CAN
prove: `Window.focus_entered` is genuinely connected to the recapture
method, and `_mouse_wanted_elsewhere()` correctly tracks the menu's open/
closed state. Both `smoke_menu` and `smoke_opening` ran clean locally (Godot
4.7-stable, fresh import cache). **This item is not closed until the owner
confirms on the actual Windows build** that the mouse turns the camera from
the first frame, through menu open/close and the name-entry screen, and
stays captured — recorded here rather than claimed as tested coverage that
does not exist.

---

## RB2 — Player has no walk/run animation
`<pending>` on `ralph/RB2`. `tests: smoke_input` (extended to assert the
loop mode, not just that position changed).

**Superseded below.** This item was first marked "verified already fixed, no
code change needed" earlier in this same firing, on the strength of
`current_animation`/bone-delta checks and log traces alone. The owner played
the actual build, saw the animation was NOT there, and said so plainly: fix
it for real, don't just read the code. That correction was right — the
verification had a real hole in it (see below) and there was a real bug.
Leaving the wrong conclusion in place rather than retracting it would make
this log untrustworthy, so it stays, corrected in the open rather than
quietly edited away.

**The actual bug, found by getting real screenshots instead of trusting
`current_animation`:** every clip `tools/art_pipeline`'s `animate_humanoid.py`
bakes into a humanoid `.glb` ships with `Animation.loop_mode = LOOP_NONE` —
confirmed by loading `trainer_lod0.glb` directly and reading it off the
resource (idle, walk, sprint, jump, throw: all `LOOP_NONE`). `pal_animator.gd`
already knew to work around this for creatures — its `_play()` sets
`animation.loop_mode` on every call, per clip, based on whether the role is a
loop or a one-shot. `scripts/characters/character_model.gd`'s `play()` (the
equivalent for the trainer, Grandpa and the Warden) never did. Between them:
`play("walk")` plays the 1.38s clip once, then sits on `_current == "walk"`
and never calls `_anim.play()` again for as long as the trainer keeps
walking, because the guard that makes cross-fades not stutter (`clip ==
_current`) also silently swallows every repeat call a continuous state makes.
The clip is real, resolves, drives real bones, and the calling code asks for
it every frame exactly as it should — and the character still freezes after
1.38 seconds, because nothing ever told the `Animation` resource to loop.

**Why the earlier verification missed it:** `current_animation` still reads
back `"walk"` after the clip stops (Godot doesn't clear it), so a check that
only reads the animation NAME sees exactly what a correctly-looping walk
would report. Bone-delta checks against the raw `.glb` in isolation (
`tools/diag_animation_moves.gd`) sample fixed points across the clip's own
declared length and never hold past it, so they cannot see a clip that plays
once and then stops on its own final frame. Only watching real rendered
frames well past the clip's length — or reading `Animation.loop_mode`
directly — shows it.

**Fix:** `character_model.play()` now takes a `looping: bool = true` and sets
`Animation.loop_mode` (`LOOP_LINEAR` / `LOOP_NONE`) before calling
`_anim.play()`, the same pattern `pal_animator.gd` already used.
`trainer_model.gd` passes `looping = false` only while `_throwing_for > 0`
(the one genuinely committed one-shot on the trainer); idle/walk/sprint/jump
all loop by default. `npc_body.gd` (Grandpa's idle) gets this for free
through the same default — his 4.04s idle was freezing too, just slowly
enough that nobody had reported it yet.

**Verified for real this time:**
- `tests/smoke_input.gd` now asserts, the instant `current_animation` first
  reports `"walk"` during a held `move_right`, that
  `AnimationPlayer.get_animation("walk").loop_mode == Animation.LOOP_LINEAR`.
  Confirmed failing against the pre-fix code (`loop_mode == LOOP_NONE`,
  0) and passing after.
- A direct resource check (`loop_mode` read off `trainer_lod0.glb`'s
  `AnimationPlayer` with no game code involved) confirms all 5 clips were
  `LOOP_NONE` before, matching the bug exactly.
- Real rendered screenshots (`xvfb-run` + `--rendering-driver opengl3`,
  properly synced this time with `process_frame` × N + `RenderingServer.
  frame_post_draw` before reading the viewport texture — the fix for the
  black-PNG problem the first verification attempt hit and didn't resolve)
  show the trainer's legs in genuinely different poses between the start and
  a few frames later into a held walk, where the pre-fix code would have
  shown the identical frozen pose both times.

**Found along the way, not chased (out of scope for this item):** with
`SequenceDirector` disabled, `move_forward` from the raw scene's fallback
spawn point (`playground_world.gd`'s `(0, 2.6, 0)`, used only before the
opening's own beats reposition the player into the house) stalls after
~1.2m over a 90-frame hold, while `move_right` from the same point covers
5.85m in the same window (`tests/smoke_input.gd`'s own numbers, unchanged
by this firing). Very likely just scatter/vegetation collision sitting
directly in the +Z direction from world origin, and the real opening never
uses that raw spawn point for free movement — but worth a look if a future
firing sees anything move-forward-shaped acting strange near boot.

---

## R0.8.5 — Full blind visual review pass, against the overhauled build
`216ce54` (review + backlog updates) on `ralph/R0.8.5`, on top of `d318a55`
(incidental missing .uid/.import sidecars from this container's first-ever
import pass — same class of fix as R0.3.5's). No tests named for this item;
CI is import + Windows export only.

One complete current-state record: the five fixed meadow viewpoints, five
staged site frames, and serial Blender turntables (four angles each) for
the trainer, Grandpa, the Warden and all seventeen pal species, judged by a
blind sub-agent per `.claude/skills/visual-judge` with no knowledge of what
changed. Full write-up: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`.
Both bar questions came back no — top separators: no landmark in any
outdoor frame, the trainer/Warden art-pipeline gap, and flat lighting with
no time-of-day read.

What the next firing should know, all recorded in `BACKLOG.md`/`BLOCKED.md`
in more detail:
- Two real bugs found in the review harness itself (not the game):
  `survey.gd`'s viewpoints 01/05 render the farmhouse interior instead of
  the meadow, 03/04 render as if the camera is embedded in the terrain.
  `preview_creatures.gd` renders zero creatures (bypasses `pal.tscn`). Both
  are backlog items now, not fixed here.
- **Tuskroot is not still the songbird placeholder** — R4.5's backlog text
  was stale; corrected, needs `smoke_art` verification to close properly.
- Creature/human art-pipeline cohesion (Paddlenewt/Pipwing/Ripplet vs. the
  rest; trainer/Grandpa vs. the Warden) logged as a design question in
  `BLOCKED.md` — rework vs. replace is the owner's call, not invented here.

## R0.9 — Assembled the opening into the real scene. Phase 0 is done.
`6b8b572` (wiring + three opening-flow bugs) and `9dd8e38` (two more test
fixes CI caught after the first push) on `ralph/R0.9`. Both confirmed
merged by fetching `main` directly — `a414da7..9dd8e38` fast-forwarded.

Added `SequenceDirector`, `InteractionArbiter`, `DialoguePanel` and
`NamePrompt` to `scenes/world/meadows_playground.tscn` as children of the
world root, wiring the director's seven NodePath exports. Per the task's
own instructions: the arbiter's `player_path` was left unset (the
director calls `set_player()` itself once the tree is up), and neither
Grandpa nor the starters were placed in the scene (the director spawns
them from `opening.json`).

Five real bugs surfaced once the scene was genuinely wired and testable
for the first time — none were new; all were latent, waiting for the
first end-to-end run:

1. **Starter-vs-player collision blocked the walk to Grandpa.** The
   middle starter always sits on the dead-straight line from spawn to
   Grandpa (`starter_offsets()` centres the row on his facing, and that
   line *is* the approach). Sharing the default collision layer meant the
   player mounted its capsule and stopped short. Fixed by giving the
   opening's three temporary display bodies their own collision layer in
   `sequence_director.gd` — the real follower pal built later by
   `adopt_starter()` is a different instance with the ordinary setup.
2. **`smoke_opening.gd`'s own walk stopped on raw distance**, but the
   three starters' 2.6m radii overlap on purpose (3.5m spread), so a
   straight walk at an off-centre one could still leave a centred
   neighbour "winning" arbitration. Now requires proximity AND an actual
   arbitration win, matching what a real player experiences.
3. **`encounter_director.gd:186` wrote the chosen nickname to
   `display_name` instead of `nickname`** — the same bug already fixed
   once in `party_seam.gd`. `pal_instance.label()` reads `nickname` first,
   so this permanently lost the species name. This was already recorded
   in `BACKLOG.md`'s "found along the way" list; removed from there now.
4. **`smoke_combat.gd` assumed a default sandbox starter** that no longer
   spawns — `SequenceDirector`'s `_ready()` now unconditionally suspends
   it, since the opening is always in the scene. Fixed by having the test
   adopt a starter directly, the same call the opening itself makes.
5. **`combat_manager.gd`'s `_stand_the_trainer_aside()` teleported the
   trainer with a raw Y** carried from the arena's own centre instead of
   asking the world for ground height (violates `D09`). On ground uneven
   enough for the difference to clear collision, the trainer fell through
   the terrain forever. Only exposed once fix 4 shifted the engagement
   geometry. Fixed with a `_ground_height()` helper mirroring
   `pal_body.gd`'s pattern.

Bug 4's fix broke two more tests that share the same scene and the same
assumption — `smoke_catching.gd` and `smoke_aggression.gd` — caught by
real CI on the first push (`6b8b572` went red), not locally beforehand.
Both got the identical `_ensure_ally()` fix and shipped in the follow-up
commit (`9dd8e38`). **Lesson for next time a shared-scene change lands:
check every consumer of that scene, not just the task's own named test**
— `smoke_menu.gd`, `smoke_settings.gd` and `smoke_free_build.gd` were
also checked this time and confirmed unaffected.

Verified: `tests/smoke_opening.gd` passes end to end (walk, talk to
Grandpa, choose and name a starter, the pal reaches the real party).
`tests/smoke_combat.gd`, `smoke_catching.gd`, `smoke_aggression.gd`,
`smoke_menu.gd`, `smoke_settings.gd`, `smoke_free_build.gd` and the full
277-test suite (0 failed) all still pass. Real CI on `9dd8e38` green
end to end including the Windows export
(run 31318155566).

`EncounterDirector.WILD_SPAWNS` still spawns an aggressive Tuskroot that
can charge the player mid-opening, per the task's own note to decide and
say so: left as-is. `smoke_opening.gd` passing with it present confirms
it does not block the scripted flow, and an aggressive pal in the meadow
during the opening is consistent with `GAME_DESIGN.md` §14's own rule
that aggression is not gated on story state elsewhere in the game.

**Phase 0 — finish the roster is now complete.** R0.6, R0.7, R0.8 and
R0.9 are all done. The next item, R0.10, is a `▶` play gate: the owner
plays the first fifteen minutes themselves. The loop stops there, per
`ralph/PROMPT.md`.

## R0.6 — finished Reedwing (fourth and last bird species). R0.6 is complete.
`6c14a65` (shipped as `ralph/R0.6-reedwing-v2`, cherry-picked from the
original `ralph/R0.6-reedwing`'s `f97824a` after a base-mismatch — see
below). Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the fourth time running. Candidate a
(R0.4 winner), no hard-fail defect — only a minor neck-proportion note.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted**, idle
motion at 88% of walk. Five eye-guard rectangles added to `grade.py` —
Reedwing's eyes read differently from the other three birds: a dark
pupil-only mass with a soft catchlight rather than a bright iris ring,
consistent with a waterfowl's eye rather than a raptor's or owl's. A dark
beak-tip wedge and a glossy neck-feather specular highlight were checked
and rejected as non-eyes.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.65m exactly
(R0.7's fixed figure), no footprint clamp, all six clips present.

`species.json`: filed `type: water` per R0.7's explicit instruction
(canonically Water/Air per `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`,
but the schema takes one type) — worth restating plainly since it would
be easy to mistake the gameplay `type` field for the rig kind: Reedwing
is still a physical bird and `--kind bird` was correct regardless.
`aggressive: false`, moderate HP/attack/defence matching its "Swift
Glider & Messenger... support, utility" role per the Water Sheet — a
support creature like Brooktail, not a fighter.

**Second branch base-mismatch caught and fixed this session, same shape
as the Galecrest incident earlier:** `ralph/R0.6-reedwing` was branched
from what was believed to be current `main`, but `ralph/R0.6-flake-note`
(a sibling branch, docs-only) had merged moments earlier without a fresh
`git fetch` immediately before branching — `git merge-base --is-ancestor
origin/main ralph/R0.6-reedwing` confirmed the fast-forward would fail
before wasting a ~9-minute CI cycle finding out the hard way. Fixed by
cutting `ralph/R0.6-reedwing-v2` from the actually-current `main` and
cherry-picking the same commit (`f97824a` → `6c14a65`) rather than
force-pushing. The original `ralph/R0.6-reedwing` is abandoned, same as
the earlier `ralph/R0.6-bird-animation-fix-record` — harmless, cannot be
deleted from this session, safe to ignore. **Lesson restated plainly for
future firings: `git fetch origin main` immediately before creating any
branch pushed within a few minutes of a sibling branch, not "recently".**

Credit balance after this species' texture pass: **175** (was 185,
confirmed via `meshy.py check`).

**R0.6 is complete.** All twelve wild species plus the three starters now
have real production art (Tuskroot's evolved-form model remains the one
stand-in, tracked separately from R0.6's own scope). Nine species shipped
in this session alone: Burrowback, Paddlenewt, Mosshell, Brooktail,
Galecrest, Duskhush, Pipwing, Reedwing, plus the `finish.py` bird-rig fix
that unblocked the last four.

CI green, fast-forwarded to `main` at `6c14a65` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Pipwing (third bird species)
`babd64f` · Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the third time running. Candidate b
(R0.4 winner), no hard-fail defect — only a cosmetic thin/blade-like
crest note.

`rig_report.json`: 19 bones, 14,002 vertices, **0 unweighted**, idle
motion at 86% of walk (well clear of the frozen threshold). Four
eye-guard rectangles added to `grade.py` — Pipwing's own "oversized teal
eyes" are large enough relative to its tiny body that they dominate
several UV islands, the strongest signature of any species yet alongside
Duskhush's. One ambiguous dark shape right beside a confirmed eye was
checked and rejected as a likely shading/seam artifact rather than a
separate instance, same caution used on every prior species.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.20m exactly —
R0.7's fixed figure, the shortest in the roster — no footprint clamp, all
six clips present.

`species.json`: `aggressive: false` (Zippy Flier/Spotter, not a fighter);
lowest HP (78) and defence (10) of the wild roster so far — deliberately
fragile, matching "tiny and round" — with catch rate (0.5) set just under
Bramblebun's tutorial-only 0.55 so the tutorial creature keeps the
highest rate in the game.

Credit balance after this species' texture pass: **185** (was 195,
confirmed via `meshy.py check`).

CI green, fast-forwarded to `main` at `babd64f` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Duskhush (second bird species)
`a9d9282` · Same `clean → texture → rig --kind bird → grade → install`
sequence proved on Galecrest, no new code needed — the finish.py fix from
last firing just worked. Candidate a (R0.4 winner), no hard-fail defect,
only a cosmetic brow-ridge note in the production report.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted** — cleaner
than Galecrest's 6/14,004. Idle motion at 65% of walk (well clear of the
6%-is-frozen threshold `rig_bird.py` flags in its own self-check). Four
eye-guard rectangles added to `grade.py`: the clearest eye signature of
any species so far — a gold outer ring, a blue/teal inner ring, a black
pupil and a white catchlight, matching the Air Sheet's own "large
gold-ringed eyes" brief and unmistakable against the grey-blue plumage.
One dark round blob near a nostril was checked and rejected (no ring, no
catchlight).

Verified in Godot: `smoke_art.gd` passes, and a standalone script
(instantiating `pal.tscn` with `wild_pal.gd`, replicating `smoke_art.gd`'s
`_rendered_height()`) confirms the rendered model matches the declared
1.55m exactly (R0.7's fixed figure — checked before writing the number,
learning from Galecrest's mistake), no footprint clamp, all six clips
present.

`species.json`: `aggressive: false` — the sheet frames Duskhush as
"Silent Watcher & Night Scout", a stealth/observation role, not a striker
like Galecrest. Lowest attack of the air roster so far; defence and HP
sit closer together than Galecrest's spread. `footprint_allowance` reused
Galewisp's 3.4 (same height, similarly-proportioned owl/fox-bird build)
rather than Galecrest's 4.2 (a bigger hawk with a wider wingspan).

Credit balance after this species' texture pass: **195** (was 205,
confirmed via `meshy.py check`, not assumed).

CI green, fast-forwarded to `main` at `a9d9282` — verified by fetching
`origin/main` directly; the branch was auto-deleted post-merge, confirming
the fast-forward actually happened rather than just going green.

## R0.6 — fixed the bird-animation blocker, shipped Galecrest (first bird species)
`400f749`, `4d078e2` · Investigated the "R0.6's four remaining species need
`animate_bird.py`" blocker properly before writing anything, by reading
`animate_quadruped.py` and `rig_bird.py` (1546 lines) in full. Discovery:
`rig_bird.py` is not a bare rigging script the way `rig_quadruped.py`/
`rig_glider.py`/`rig_sitter.py` are — it authors all six standard clips
itself (`author_all()`), already proved end-to-end on three winged test
meshes per its own docstring, and its bone names deliberately overlap
`animate_quadruped.py`'s glider layout "so that script still produces
something sane if it is ever pointed at a bird." The real bug was in
`finish.py`'s `rig` subcommand: it called `animate_quadruped.py`
unconditionally after rigging, regardless of `--kind`. For a bird this
would have silently re-detected the already-animated rig as a glider and
overwritten `rig_bird.py`'s bird-specific animation with generic glider
animation, including `animate_quadruped.py`'s documented faint-spin bug
(root-bone yaw applied where the rig's local Y is world-up, so the
creature spins on the spot instead of toppling). **No new script was
needed** — `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`.

Proved by running Galecrest, the first bird species, through the fixed
path for real: `clean → texture (candidate a; needed despite an existing
committed `textured/model.glb` from R0.5 — see below) → rig --kind bird →
grade → install`. `rig_report.json`: 19 bones, 14,004 vertices, 6
unweighted (0.04%, same noise-level pattern as Brooktail's), idle motion
at 108% of walk (clear of `rig_bird.py`'s own 6%-is-frozen self-check).
Two eye-guard rectangles added to `grade.py` (a pair of glossy black
hooked-beak shapes checked and rejected — no iris ring, no pupil).

**Mistake made and caught within the same task, before the branch was
confirmed merged:** shipped Galecrest's `species.json` height as 1.85m,
picked from D13's looser "largest tier, alongside Meadowhart and Tuskroot"
language without re-reading `BACKLOG.md`'s R0.7 section, which fixes
Galecrest specifically at 2.00m in its height table. Caught on a second
pass through `BACKLOG.md` while updating it for this entry, fixed in
`4d078e2`, re-verified in Godot (rendered model matches 2.00m exactly, no
footprint clamp, all six clips intact). Lesson for future firings:
**R0.7's height table is the source of truth for a species' height figure,
read it before writing the number** — D13 only fixes the relative
ordering and rough tier, not the exact figure.

**Also checked and corrected a wrong assumption made mid-task:** briefly
believed Duskhush/Pipwing/Reedwing could skip `texture` entirely and reuse
their existing R0.5-committed `textured/model.glb` files, since Galecrest's
turned out to share that history. Wrong — `DONE.md`'s own Tuskroot entry
(below) already recorded that every one of the ten R0.5 outputs is
structurally unusable (textured before `clean`, so 50,000+ triangles
against a 30,000 budget, thousands of non-manifold edges). Caught before
being written into `BACKLOG.md`; that file states the correct instruction
(`clean` then `texture` fresh, same as every other species).

`species.json`: `aggressive: true` (rare — only Tuskroot has this among
the wild roster so far), reflecting the Air Sheet's own "fierce focused
eyes"/"Aerial Striker" language: a genuine predator, matching D13's
explicit requirement that Galecrest not read like the Air starter
Galewisp. Highest attack (28) and lowest defence (15) of the roster so
far, mirroring Galewisp's own thin-armour/high-attack profile pushed
further. `model_yaw` not visually verified — this container still has no
`libEGL.so.1`, so `turntable.py` cannot render a frame, the same
persistent limitation recorded for every species finished this session;
left at 0.0, the default every quadruped shipped with.

Balance after Galecrest's texture pass: **205** (was 215). Duskhush,
Pipwing, Reedwing each still need their own `clean`/`texture` pass,
~10 credits apiece — see `BLOCKED.md`.

CI was still running when this entry was written; verified separately
once green — see `ralph-status` for the real-time record, and do not
trust this line alone as proof of a merge.

## R0.8 — ASSET_LEDGER rows for Mosshell/Brooktail; missing-record gap closed
`b145f2d` · Extends the previous R0.8 partial entry (below) to all six now-
finished R0.6 wild quadrupeds — every one of Tuskroot, Meadowhart,
Burrowback, Paddlenewt, Mosshell, Brooktail now has an `ASSET_LEDGER.md`
row. Still not R0.8 complete: the four bird species have no model yet
(blocked on `animate_bird.py`), so no row for them.

**Also resolved `MEADOWS_WILD_PRODUCTION_REPORT.md`'s "known gap" note**,
open since it was written: the report said Bramblebun's, Mudsnout's and
Trailpup's candidate-selection records "did not survive into `ralph/`" and
asked whoever finished R0.8 to either find them or say plainly they don't
exist. They were never actually missing — they predate the Ralph loop
entirely, so they were never going to be in `ralph/DONE.md`, and looking
there was looking in the wrong place. The real record is in git history:
commit `d2520f0` ("Bramblebun stops being a duck...") and `9ec9eaa`
("Mudsnout and Trailpup...") both carry full candidate-selection reasoning
in their commit messages, and `ASSET_LEDGER.md`'s existing rows for those
three creatures already condense that same reasoning (they were written
from these commits at the time, just never cross-referenced back to them).
The report now cites both commits directly instead of asking a future
reader to re-find them. Also brought the report's "What's next" section
current — it still described R0.5 and R0.6 as not yet started.

CI green (run 31307762531), fast-forwarded to `main` at `b145f2d` —
verified by fetching `origin/main` directly.

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

## R0.6 — Brooktail finished (sixth of the ten, last of the six wild quadrupeds)
`20f8412` · Same pipeline as the previous five: clean raw R0.4 winner
candidate `a` (54,836 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` → `grade.py` SPECIES entry → `finish.py grade` →
`finish.py install` → `species.json` entry from the Water Sheet's own
Resourceful Diver/Helper role and build notes.

**This species carries two real defects, both documented rather than fixed —
worth reading before touching it again:**

1. **R0.4's report names Brooktail the one HARD FAIL of the ten wild
   species**, not a clean pick like the other five finished so far — every
   candidate is missing the canon's broad flat scaled paddle tail, giving a
   round tapering tail instead. This was **wrongly summarized as "no
   follow-up flagged" in the previous firing's handoff prompt** (a
   send_later message written without re-checking the report directly);
   the actual report entry was caught and corrected by reading
   `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` directly rather than
   trusting the handoff. The report's own instruction is explicit: ship it
   forward with the defect flagged rather than block or re-roll, since "the
   tail needs a real sculpting pass before this creature is considered
   done" — separate future work, not attempted here.

2. **`rig_quadruped.py` left 35 of 14,034 vertices (0.25%) unweighted** —
   the first species in this batch where that actually happened; the
   previous five all landed at exactly 0 despite carrying similar residual
   post-retexture mesh noise (this one: 6,075 non-manifold edges, 81
   microscopic disconnected components — same category every species
   carries after Meshy's retexture re-unwrap, see Tuskroot's entry above).
   Investigated rather than shipped blind: extracted the unweighted
   vertices' world positions and found them scattered across the entire
   bounding box, not concentrated near the tail — so this is likely NOT the
   same root cause as (1), just the same known noise pattern crossing a
   threshold this one time. `inspect_glb.py` and Blender's own
   `ARMATURE_AUTO` weighting have no built-in retry/repair for this;
   fixing it properly would mean a fresh clean/remesh pass (cost: another
   Meshy texture charge) or waiting for the eventual tail sculpt to
   naturally redo the mesh. Documented in `species.json`'s `_comment_art`
   rather than guessed at.

**Six eye-guard rectangles**, same duplicated-across-UV-islands pattern
every species has shown, found by the same full quadrant-by-quadrant scan.
One dark almond shape near the snout was checked and rejected — no teal
iris ring, reads as a nostril shadow.

**Finishes the quadruped half of R0.6.** All that remains is the four bird
species (Galecrest, Duskhush, Pipwing, Reedwing), and they are blocked:
`finish.py rig`'s animate step is hardcoded to `animate_quadruped.py`
regardless of `--kind`, and no `animate_bird.py` exists. Whoever picks up
R0.6 next needs to write one (or generalise `animate_quadruped.py`) before
any bird can move past the `rig` step — this is now the actual next blocker
for R0.6, not a credits or key problem.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green — the 35 unweighted vertices
do not block import or the test suite, only animation quality). Height-fit
verified with the same small standalone script as the previous five:
**wanted 1.450m, rendered 1.450m, exact match.** Not committed.

CI green (run 31306142495), fast-forwarded to `main` at `20f8412` —
verified by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **215** (was 225).

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
