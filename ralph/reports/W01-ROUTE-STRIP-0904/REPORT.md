# W01-ROUTE-STRIP-0904 — the route strip photographs the game, not empty scenery

Phase 0.1 / CL-H9 / task 2.15. Branch `ralph/W01-ROUTE-STRIP-0904`, from `origin/main`
at `ef16544f`. Brief: `ralph/briefs/0904/W01-ROUTE-STRIP.md` on
`origin/claude/codex-merge-meadows-finish-dq12jj`.

## Files changed

| File | Change |
|---|---|
| `tools/capture_check.gd` | New `readable_problems()` / `readable_problems_for_camera()` (creature present and readable), `project_point()` / `projected_rect()` / `body_box()` (pure projection and a body's own standing box, same arithmetic as `Camera3D.unproject_position`), `fit_distance()` / `camera_transform_at()` (camera distance solved against every subject's projected bounds, with optional min/max height caps and a minimum on-screen gap between marked "fighter" subjects). Existing checks untouched. |
| `tools/_capture_route_strip.gd` | Rewritten around the same trail walk: summons the party companion through the production path, stands the pair on every road stand, one real `CombatManager` fight per band with a solved three-subject camera, projection-based refusal, unconditional post-guard flee with an input-context assertion, richer `manifest.json`. New flags `--no-fight`, `--fight-search=<m>`. Existing flags unchanged; `tools/owner/kickoff.ps1`'s two invocations still work as written. |
| `tests/test_capture_check.gd` | 20 tests (up from the pre-existing 3): projection agreement, empty frame, behind camera, too small, cropped, side-by-side pass, one bad subject fails the frame, on-screen overlap, close-up cap, screen-gap requirement, `fit_distance` minimality / three-subject-vs-two / no-fit / height caps / a subject exempt from the size floor. |
| `tests/test_route_strip_subject_boxes.gd` | New. 8 tests pinning subject-box sizing and fight-framing geometry against the shipped `species.json` and the arena's own numbers: a creature's box is its collider radius, not its spawn-spacing allowance; two fighters at the arena's authored separation and at melee range read as separate; one standing behind the other is still caught; two standing inside each other are reported as interpenetrating (not as screen overlap); a required on-screen gap is enforced and is asked of fighters only, never the trainer. |
| `docs/CURRENT_STATE.md` | Exit-note paragraph updated; new §2 row "Route strip / creature evidence (2.15, CL-H9)". |
| `docs/VISUAL_PARITY_PROGRESS.md` | "Route-strip investigation" rewritten as landed; "Exact resume point" now starts at the GPU strip. |
| `ralph/reports/W01-ROUTE-STRIP-0904/` | This report, `_sheet_route_strip.png` (final sheet, run 8), and `JUDGE-ROUND-1.md` through `JUDGE-ROUND-4.md` (one verbatim code-blind verdict per round). Run logs (`run1.log`–`run8.log`) are `*.log` and ignored by the repo's evidence rules; the numbers that matter are quoted below. |

Not touched: anything under `scripts/`, `autoload/`, `data/`, `docs/owner/`,
`tools/vp_capture_windows.ps1` (that script never ran the route strip and the strip's
existing CLI is unchanged). No new probe was needed: the game deployed the companion
after a fresh boot every time, so the GAME-2 class of defect the brief warned about did
not reproduce here.

## What the strip does now (player-visible terms)

1. **The trainer's real companion is on the road.** Before the first frame the strip
   grants a Terrapup to `Game.party` the way the opening does (`CreatureSpecies.spawn` +
   `Game.party.add`) and calls `EncounterDirector.summon_active_creature()` — the party
   screen's own "send this one out". A party that already has members is used as it is.
   Every road frame has the trainer on the road at the stand's arc metre and the companion
   1.8 m to their right, both facing the way the road goes. Measured on every run from 3
   through 8, unchanged: trainer 21.2–21.6 % of frame height, Terrapup 29.4–30.4 %.
2. **One real fight per band, framed for three, against a matched opponent.** At the first
   stand of a band with a live wild within 150 m, the strip picks the **tallest** live wild
   in range (not merely the nearest) and engages it through the player's own `interact`
   press (the arbiter → `interaction_activate` → `_start_fight` path; the director's own
   entry points are recorded fallbacks). Ten physics ticks after `begin()` — past
   `_place_fighters()`'s own construction, before the combat AI has time to close the
   arena's authored separation — the strip solves its camera: for each of seven bearings
   (front quarters first, then broadsides, rear quarters, behind the ally) the smallest
   distance at which trainer, companion and opponent all fit the safe area, nobody exceeds
   half the frame's height, nobody is under 18 % of it, and the two fighters keep at least
   4 % of the frame's width clear between their silhouettes.
3. **A frame that fails "creature present and readable" is refused, not saved.** The check
   projects each subject's own standing box — species height and collider radius for a
   creature, the collision capsule for the trainer, never a skinned mesh's bind-pose AABB
   and never the spawn-spacing `footprint_allowance` a species carries for prop clearance —
   and faults: no subject named; a corner behind the camera; under 12 % of frame height (18 %
   in a fight); over 50 % of frame height in a fight; more than a quarter cropped; both
   occlusion rays stopped by geometry; two subjects overlapping on screen by more than half
   the smaller (or, if their world boxes actually intersect, reported as standing inside
   each other, since no camera angle fixes that); and, for the two fighters specifically,
   less than the required on-screen gap. `capture_check`'s existing world checks (grass
   bound, terrain streaming, camera above ground and outside geometry, weather pinned) run
   on every frame too. A refused frame is printed with its reasons, listed under
   `manifest.json: rejected`, and the run exits non-zero.
4. **Fight cleanup is unconditional.** Nothing between `begin()` and `_end_fight()` returns
   early; a refused frame still flees. The flee waits past `combat.json`'s 0.25 s
   `flow.input_guard` (a press inside it is silently dropped), presses `combat_run` up to
   twice with a 90-tick bound, lets process frames run so `sequence_director._refresh_lockout`
   can hand the arbiter back, then asserts `gate_f_probe.input_context() == "world"` and that
   the companion is visible again. Every run from 3 through 8: `fled after 1 press(es);
   input context is back to 'world'`.

## Tests

```
godot --headless --path . --script tests/run_tests.gd -- \
  --only=test_capture_check.gd,test_route_strip_subject_boxes.gd
```

**31 tests, 69 assertions, 0 failed (final).** Seen red for the right reason five separate
times over the course of the lane, each tied to a real runtime finding (see the run table
below for what each one was reproducing):

1. Empty-subject refusal removed, height floor zeroed: 3 of 14 failed, restored to 14/14.
2. Overlap threshold zeroed, close-up cap disabled: 2 of 18 failed, restored to 18/18.
3. Minimum-height bound removed from `fit_distance`: 1 of 20 failed, restored to 20/20.
4. Subject boxes built from the old `footprint_allowance` formula: 2 of 4 (then, after the
   trainer-floor-exemption draft was corrected) 2 of 25 failed, restored to 25/25.
5. World-box interpenetration reporting disabled: 2 of 27 failed, restored to 27/27.
6. On-screen fighter-gap requirement disabled: 1 of 28 failed, restored to 28/28.

The unit suite runs under `--script`, with no main loop, so every check above is pure
geometry — the strip proves on its own first frame that this geometry agrees with the
engine's: every run logs `[projection] engine (...) vs capture_check (...): 0.00 px apart`
(a delta over 1.5 px fails the run; none ever has).

## Runtime validation — eight bounded xvfb runs

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_route_strip.gd -- \
  --bands=1 --max=3 --fast --out=res://shots_route_w01
```

Brief-named bound (`--bands=1 --max=3`), run to completion eight times as the strip and the
check were corrected against what each run actually produced. Every run is a real fight
entered by a real `interact` press against a live wild in `data/config/bands/band1_lower_meadows/spawns.json`.

| Run | Wall time | Result | What it found, and the fix |
|---|---|---|---|
| 1 | 28m58s | 0 saved / 62 refused, exit 1 | Companion summoned, mudsnout fight entered, one bearing fit all three — but every frame was refused on "WorldWeather is still processing" (the world's own boot coroutine re-enables it after the strip's pin), `--max` counted saved frames so a fully-refused band walked to its end, and the post-flee input context read `locked` because it was read on the same physics tick the fight ended, before `sequence_director._refresh_lockout` had run. All three are tool defects. Fixed in `eba93958`. |
| 2 | 12m42s | 3 road + 1 fight, 0 refused, exit 0 | Road frames correct. The fight frame passed every check and was not readable: the companion at 69 % of frame height with the fight behind it, the mudsnout overlapping its front, the trainer's whole box inside the companion's silhouette (the occlusion rays passed through its narrower collider). The flee's "You backed off." toast, on a second canvas layer, bled into the next road frame. Fixed in `6d8926f1`: on-screen overlap rule, a 50 % height cap, a higher eye, front-quarter bearings first, every canvas layer hidden for road shots, a refused fight retried at the next stand. |
| 3 | ~11m | 3 road + 1 fight, 0 refused, exit 0 | **First code-blind judge** (`JUDGE-ROUND-1.md`). Accepted the road frames — trainer and companion both present, scale legible, `band1_00040m` named as the strongest frame in the set. Rejected the fight frame: the mudsnout at 14.5 % of frame height read as "terrain dressing... ambiguous with a background prop." |
| 4 | ~9m | 3 road + 2 refused fight attempts, exit 1 | Added a minimum on-screen height (18 %) beside the existing maximum. Both bounds together proved the mudsnout matchup itself unphotographable — no bearing at any distance puts a 0.95 m mudsnout, a 2.30 m companion and the 1.80 m trainer all inside those two bounds at once. Not a bad camera; an unphotographable pairing. Fixed by choosing the opponent by size (`_best_opponent()`, tallest live wild in range) rather than by proximity, and by clearing the flee toast before a fight shutter (`dbb69ea0`). |
| 5 | ~9m | 3 road + 1 refused fight (galecrest), exit 1 | The size-based choice picked a 2.10 m galecrest — and every one of the seven bearings was refused for "overlap on screen by 74–80 % of the smaller one," with nothing actually hidden in the frame. The subject boxes were built with `_capture_life.gd`'s bbox formula, `radius * max(1, footprint_allowance * 0.65)` — a spawn-spacing number, not a visual width, which inflates a galecrest's 1.30 m body into a 3.55 m box. Fixed in `15832da1`: boxes are now the collider radius only (`capture_check.body_box()`), pinned against the shipped species data in `test_route_strip_subject_boxes.gd`. |
| 6 | 8m27s | 3 road + 1 fight (galecrest), 0 refused, exit 0 | **Second code-blind judge** (`JUDGE-ROUND-2.md`). Accepted the road frames again. Opened on the fight frame with "the two creatures interpenetrate and merge into one silhouette... a single beige-and-blue lump" — the combat AI had closed the arena's authored 5 m separation to contact during the strip's own 40-tick pre-shutter settle (a number copied from `_capture_combat_moments.gd`, which needs it to wait out a real camera rig this strip does not use). Fixed in `1aa64698`: the settle drops to 10 ticks, plus a belt-and-braces rule reporting two subjects whose world boxes actually intersect as standing inside each other. |
| 7 | 7m38s | 3 road + 1 fight (galecrest), 0 refused, exit 0 | **Third code-blind judge** (`JUDGE-ROUND-3.md`), asked directly whether the two creatures read as separate animals. No more interpenetration, but still "they do not read as two separate animals... even at full size they separate by hue alone" — a galecrest's spread wings reach well past its collider radius, so boxes that merely fail to overlap can still leave the silhouettes touching. Fixed in `ac22de7e`: a required on-screen gap (4 % of frame width) between subjects marked as fighters, exempting the trainer. |
| 8 | 7m27s | 3 road + 1 fight (galecrest), 0 refused, exit 0 | **Fourth code-blind judge** (`JUDGE-ROUND-4.md`, run against the same galecrest matchup as runs 6–7 for a direct before/after). This is the frame judged as final; see below. |

`SCRIPT ERROR` count across every run: **0**. `^ERROR:` set across every run: `Condition
"status < 0"` ×1 (ALSA, no audio device in the container) and `Parameter "material" is null`
×4–12 (the known alpha-creature-build set named in `docs/AGENT_WORKFLOW.md` §6, whose count
varies with what streamed in but whose set never grew).

## Final evidence (run 8)

```
band1_00000m            trainer 0.212  companion:terrapup 0.294
band1_fight_galecrest   entered_by=interact  bearing=front-quarter-trainer-side  6.0 m
                        trainer 0.394  companion:terrapup 0.213  opponent:galecrest 0.276
                        context_in_fight=combat
band1_00040m            trainer 0.213  companion:terrapup 0.303
band1_00080m            trainer 0.216  companion:terrapup 0.304
rejected: []   failures: []
```

`ralph/reports/W01-ROUTE-STRIP-0904/_sheet_route_strip.png` is the run-8 sheet (four
frames, `tools/contact_sheet.gd`). My own inspection: all three road frames show the
trainer and Terrapup side by side facing down the road, no HUD, no stray toast; the fight
frame shows the trainer in the foreground watching, Terrapup and a blue-and-teal Galecrest
standing apart with visible ground between them, wings spread, the combat HUD (nameplate,
party panel, move bar) on.

## The blind judge, four rounds

Every round used a fresh sub-agent given only the current sheet, that run's four PNGs,
`docs/reference/` and `.claude/skills/visual-judge/SKILL.md` — nothing about what changed,
what any earlier round said, or this lane's existence. Verdicts are committed verbatim:
`JUDGE-ROUND-1.md` (run 3), `-2.md` (run 6), `-3.md` (run 7), `-4.md` (run 8, final, with
extra weight on the fight frame's separation and readability).

**The two bar questions never passed in any round**, and that was expected and out of
scope: the brief is explicit that this lane is "graded on whether the frames finally
contain the subjects," not on the bars themselves. Bar A (belonging to the keyart's world)
and Bar B (the same kind of game as Palworld) were answered **no** and **yes-with-caveats**
respectively across all four rounds, on the same grounds every time — thin, evenly-scattered
ground cover and a single repeated tree silhouette with no grove structure, no landmark at
the end of any sightline, a compressed value range with no cast shadows or aerial
perspective, and no combat VFX. None of that is this lane's surface (`tools/capture_check.gd`,
`tools/_capture_route_strip.gd`, `tests/`); every round says so explicitly, splitting each
finding into "fixable by scene changes" and "needs art not in the build."

**What did change, round over round, is exactly what this lane was for — whether a
creature is actually in the frame, at a readable size, beside the trainer:**

- Round 1 (run 3): both road frames "readable," the fight frame's opponent "too small...
  ambiguous with a background prop."
- Round 2 (run 6): road frames again accepted; the fight frame's two creatures
  "interpenetrate and merge into one silhouette."
- Round 3 (run 7): no more interpenetration, but "they do not read as two separate
  animals... even at full size they separate by hue alone" and the trainer read as "a
  spectator standing outside the shot."
- Round 4 (run 8, final): **"At full size... they read as two distinct creatures, not a
  merged blob"**; the opponent is "unambiguously" identifiable as an avian creature at a
  size "comparable to Terrapup's... appropriate for a same-or-higher-level wild opponent";
  the trainer is "fully visible... not cropped... not clipped by the HUD... reads as
  watching the fight." The one qualifier the judge raised — that separation at
  contact-sheet size still leans partly on the two creatures' hues differing, and a same-hue
  matchup at this same staging distance might not clear it — is recorded under Known
  limitations below; the geometric gap rule itself (§4 gap threshold) does not depend on
  colour and would still require a bearing where the two silhouettes have space between
  them regardless of hue.

## Known limitations and what was deliberately not done

- **Container frames only.** Every frame here is llvmpipe/Compatibility software rendering.
  The GPU route strip is the owner's kickoff (`tools/owner/kickoff.ps1` runs the strip day
  and night with this same, unchanged CLI); it has not run since this landed, and D73 puts
  the actual bar verdicts on those frames, not these.
- **One band, three stands.** `--bands=1 --max=3 --fast`, as the brief specified. Bands 2–5
  were not walked in-container (a full band-1 walk alone is 62 stands at ~25 s/stand under
  llvmpipe in fast mode). The fight-search, size-based opponent choice, and bearing/gap
  solver are band-agnostic code but have only been exercised against band 1's spawn table
  (mudsnout, then galecrest as the tallest candidate in range).
- **The fourth judge's own caveat stands as a real limitation, not just a quote:** the
  required on-screen gap is a hard geometric floor and does not depend on colour, but with
  only ~4 % of frame width required, a same-hue matchup (two creatures of similar tone) at
  this same distance and bearing could still be a harder read than the galecrest/Terrapup
  pairing tested here. Nothing in this lane's scope adjusts silhouette contrast (rim
  lighting, outline shaders); the fix, if the GPU strip ever surfaces this on a same-hue
  pairing, is either a larger required gap or a contrast-based check, neither of which this
  branch adds speculatively.
- **Fight readability is a check, not a guarantee.** If no bearing satisfies every bound for
  a given band's live wilds, the frame is refused, listed, and the band retries the fight at
  its next stand against a different (untried) opponent; a band can end with no fight frame
  at all, which fails the run rather than silently omitting it.
- **The fight frame keeps the combat HUD** (nameplate, party panel, move bar) because 2.15
  asks for nameplates and level tags where the game has them; road frames hide every canvas
  layer, including the one-shot toast strip, which is why the flee message from a previous
  stand no longer bleeds into the next frame (run 2's finding).
- **Not a game change.** No file under `scripts/` or `autoload/` was touched. The two
  game-side observations, both left to the tool rather than fixed at the source since fixing
  them was outside this lane's ownership: `WorldWeather` is re-enabled during the world's own
  boot coroutine after any tool freezes it early (a trap for every capture tool that pins
  weather before the settle, now handled here by re-pinning immediately before every
  shutter); and the combat AI closes an engaged fight's arena-authored separation to contact
  within roughly two thirds of a second, which any capture tool photographing a fight from
  its own camera (rather than the real rig, which has its own retarget delay) needs to
  account for.
- **`.import` side-effects.** The container's import step generates untracked
  `assets/creatures/tetherbound/*/reference/*.png.import` files; they are outside this
  lane's ownership (`scripts/`/`autoload/`/`data/`/assets are not owned by this lane) and
  were not committed.

## Commits

```
2e0d7a8b capture_check: creature-present-and-readable projection check and a three-subject framing solver
4db63dd0 route strip: deploy the party companion, one solved three-subject fight frame per band, refuse unreadable frames
eba93958 route strip: re-pin weather before every shutter, cap counts attempted stands, read the post-flee context after a process frame
6d8926f1 route strip: refuse on-screen overlap and close-ups, front-quarter bearings from a higher eye, retry a refused fight at the next stand
fe7dfff6 docs: record the landed route strip in CURRENT_STATE (2.15/CL-H9) and the VISUAL_PARITY_PROGRESS resume point
84fe3643 W01-ROUTE-STRIP report draft and route-strip contact sheet (superseded by this report)
4b4619e9 route strip: the smallest fighter may not be a smudge either, and the fight eye comes down
1bf24079 W01-ROUTE-STRIP: code-blind verdict on the run-3 frames, verbatim
dbb69ea0 route strip: pick the fight opponent by size, and clear the toast before a fight shutter
15832da1 route strip: measure a subject's box from its own body, not its spawn allowance
92dcffb5 W01-ROUTE-STRIP: contact sheet from run 6 (3 road frames + galecrest fight, 0 refused)
1aa64698 route strip: shoot the fight before the AI closes, and refuse bodies standing inside each other
bd90a6d1 W01-ROUTE-STRIP: code-blind verdict on the run-6 frames, verbatim
109b1e99 W01-ROUTE-STRIP: contact sheet from run 7 (fighters separated, 0 refused)
ac22de7e route strip: a fight frame needs daylight between the two fighters
caf370a7 W01-ROUTE-STRIP: code-blind verdict on the run-7 frames, verbatim
61648f6b W01-ROUTE-STRIP: contact sheet from run 8 (fighters separated with a clear gap, 0 refused)
2c995b3c W01-ROUTE-STRIP: final report and round-4 code-blind verdict
f713c00e W01-ROUTE-STRIP: record this report's own final commit hash
```

Last code+evidence commit (the state everything above was measured against): **61648f6b**.
This report and the round-4 verdict landed at **2c995b3c**; the branch tip, after this
line was corrected to name that hash, is **f713c00e**. `git log --oneline -3` on
`ralph/W01-ROUTE-STRIP-0904` is the authoritative check.

Branch: `ralph/W01-ROUTE-STRIP-0904`, pushed to `origin` after every commit above.
