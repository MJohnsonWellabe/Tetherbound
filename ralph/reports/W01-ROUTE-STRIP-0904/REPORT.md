# W01-ROUTE-STRIP-0904 — the route strip photographs the game, not empty scenery

Phase 0.1 / CL-H9 / task 2.15. Branch `ralph/W01-ROUTE-STRIP-0904`, from `origin/main`
at `ef16544f`. Brief: `ralph/briefs/0904/W01-ROUTE-STRIP.md` on
`origin/claude/codex-merge-meadows-finish-dq12jj`.

## Files changed

| File | Change |
|---|---|
| `tools/capture_check.gd` | New `readable_problems()` / `readable_problems_for_camera()` (creature present and readable), `project_point()` / `projected_rect()` (pure projection, same arithmetic as `Camera3D.unproject_position`), `fit_distance()` / `camera_transform_at()` (camera distance solved against every subject's projected bounds, with an optional height cap). Existing checks untouched. |
| `tools/_capture_route_strip.gd` | Rewritten around the same trail walk: summons the party companion through the production path, stands the pair on every road stand, one real `CombatManager` fight per band with a solved three-subject camera, projection-based refusal, unconditional post-guard flee with an input-context assertion, richer `manifest.json`. New flags `--no-fight`, `--fight-search=<m>`. Existing flags unchanged; `tools/owner/kickoff.ps1`'s two invocations still work as written. |
| `tests/test_capture_check.gd` | 15 new tests (18 total): projection, empty frame, behind camera, too small, cropped, side-by-side pass, one bad subject fails the frame, on-screen overlap, close-up cap, `fit_distance` minimality / three-subject vs two-subject / no-fit / height cap. |
| `docs/CURRENT_STATE.md` | Exit-note paragraph updated; new §2 row "Route strip / creature evidence (2.15, CL-H9)". |
| `docs/VISUAL_PARITY_PROGRESS.md` | "Route-strip investigation" rewritten as landed; "Exact resume point" now starts at the GPU strip. |
| `ralph/reports/W01-ROUTE-STRIP-0904/` | This report and `_sheet_route_strip.png` (one sheet, four frames). Run logs are `*.log` and ignored by the repo rules; key lines are quoted below. |

Not touched: anything under `scripts/`, `autoload/`, `data/`, `docs/owner/`,
`tools/vp_capture_windows.ps1` (that script never ran the route strip and the strip's
existing CLI is unchanged). No new probe was needed: the game deployed the companion
after a fresh boot every time, so GAME-2 did not reproduce here.

## What the strip does now (player-visible terms)

1. **The trainer's real companion is on the road.** Before the first frame the strip
   grants a Terrapup to `Game.party` the way the opening does (`CreatureSpecies.spawn` +
   `Game.party.add`) and calls `EncounterDirector.summon_active_creature()` — the party
   screen's own "send this one out". A party that already has members is used as it is.
   Every road frame has the trainer on the road at the stand's arc metre and the
   companion 1.8 m to their right, both facing the way the road goes, the eye 6.5 m
   behind them at 2.2 m. Measured on the three run-3 frames: trainer 21 % of frame
   height, Terrapup 29–30 %.
2. **One real fight per band, framed for three.** At the first stand of a band with a
   live wild within 150 m, the trainer is stood 4 m from it, `interact` is pressed (the
   arbiter → `interaction_activate` → `_start_fight` path; the director's entry points
   are fallbacks and the manifest records which one opened the fight — run 3: `interact`).
   After 40 physics ticks the strip's own camera is solved: for each of seven bearings
   (front quarters first, then broadsides, rear quarters, behind the ally) the smallest
   distance at which trainer, companion and opponent all fit the safe area and none
   exceeds half the frame's height; the tree is paused, the boxes re-measured, and the
   full check run. Run 3: `front-quarter-trainer-side` at 6.5 m, trainer 34 %, Terrapup
   22 %, mudsnout 14.5 %, `context_in_fight: combat`.
3. **A frame that fails "creature present and readable" is refused, not saved.** The
   check projects each subject's declared-size box (species height/radius for creatures,
   the collision capsule for the trainer — never a skinned mesh's bind-pose AABB) and
   faults: no subject named; a corner behind the camera; under 12 % of frame height;
   more than a quarter cropped; both occlusion rays stopped by geometry; two subjects
   overlapping on screen by more than half the smaller; and, in a fight, any subject over
   50 % of frame height. `capture_check`'s existing world checks (grass bound, terrain
   streaming, camera above ground and outside geometry, weather pinned) run on every
   frame too. A refused frame is printed with its reasons, listed under
   `manifest.json: rejected`, and the run exits 1.
4. **Fight cleanup is unconditional.** Nothing between `begin` and `_end_fight` returns
   early; a refused frame still flees. The flee waits 20 physics ticks past the shutter
   (over `combat.json` `flow.input_guard` 0.25 s, which drops a press made inside it),
   presses `combat_run` up to twice with a 90-tick bound, lets two process frames run
   so `sequence_director._refresh_lockout` can hand the arbiter back, then asserts
   `gate_f_probe.input_context() == "world"` and that the companion is visible again.
   Run 3: `fled after 1 press(es); input context is back to 'world'`.

## Tests

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_capture_check.gd
```

18 tests, 39 assertions, 0 failed (final). Seen red for the right reason twice:

- with the empty-subject refusal removed and the height floor set to 0: 3 of 14 failed
  (`test_an_empty_frame_is_refused`, `test_a_subject_too_far_away_is_too_small_to_read`,
  `test_one_unreadable_subject_fails_the_whole_frame`), restored to 14/14;
- with the overlap threshold set to 0 and the close-up cap disabled: 2 of 18 failed
  (`test_a_subject_hidden_inside_another_subjects_silhouette_is_refused`,
  `test_a_subject_that_fills_the_frame_is_a_close_up_not_a_scene`), restored to 18/18.

The unit suite has no main loop, so the check is pure geometry; the strip proves on its
first frame that it agrees with the engine: run 3 `[projection] engine (1101.266,
603.4813) vs capture_check (1101.266, 603.4813): 0.00 px apart` (a delta over 1.5 px fails
the run).

## Runtime validation — the bounded xvfb run

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_route_strip.gd -- \
  --bands=1 --max=3 --fast --out=res://shots_route_w01
```

| Run | Result | What it taught |
|---|---|---|
| 1 (28m58s) | 0 saved, 62 refused, exit 1 | Companion summoned, fight entered by `interact`, `broadside-far-side` at 5.2 m fitted all three — but every frame was refused on "WorldWeather is still processing" (the boot coroutine thaws it after the pin), `--max` counted saved frames so the whole band walked, and the post-flee context read `locked` because it was read on the physics tick the fight ended, before `_refresh_lockout` ran. All three are tool defects; fixed in `eba93958`. |
| 2 (12m42s) | 3 road + 1 fight saved, 0 refused, exit 0 | Road frames right. The fight frame passed the check and was **not** readable: Terrapup 69 % of the frame at the minimum fit, mudsnout overlapping its front, trainer's whole box inside the Terrapup's silhouette (the occlusion rays passed through the narrower collider). The flee's "You backed off." toast, on a second canvas layer, bled into the next road frame. Fixed in `6d8926f1`: on-screen overlap rule, 50 % cap, 3.2 m eye, front-quarter bearings, all canvas layers hidden for road shots, fight retried at the next stand if refused. |
| 3 (10m50s) | 3 road + 1 fight saved, 0 refused, exit 0 | The frames judged below. `SCRIPT ERROR`: 0. `^ERROR:` set: `Condition "status < 0"` ×1 (ALSA, no audio device) and `Parameter "material" is null` ×4 (the known alpha-build set, `docs/AGENT_WORKFLOW.md` §6); the set did not grow. |

Manifest (run 3):

```
band1_00000m          trainer 0.212  companion:terrapup 0.294
band1_fight_mudsnout  entered_by=interact  bearing=front-quarter-trainer-side  6.5 m
                      trainer 0.340  companion:terrapup 0.218  opponent:mudsnout 0.145
                      context_in_fight=combat
band1_00040m          trainer 0.213  companion:terrapup 0.303
band1_00080m          trainer 0.216  companion:terrapup 0.304
rejected: []   failures: []
```

My own inspection of the four frames: trainer and Terrapup side by side on the road in
all three road frames, no HUD, no toast; the fight frame has the trainer in the
foreground left, the Terrapup centred, the mudsnout beside it, the combat HUD (nameplate,
party panel, moves) on. The party panel's top edge touches the trainer's boots.

## Contact sheet and blind judge

`ralph/reports/W01-ROUTE-STRIP-0904/_sheet_route_strip.png` (`tools/contact_sheet.gd`,
four frames). The judge was an `opus` sub-agent given only the sheet, the four frames,
`docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, and told the frames are
llvmpipe road frames with one fight; nothing about what changed.

### Verdict (verbatim)

VERDICT_PLACEHOLDER

## Known limitations and what was deliberately not done

- **Container frames only.** Every frame here is llvmpipe. The GPU route strip is the
  owner's kickoff (`tools/owner/kickoff.ps1` runs the strip day and night with the
  unchanged CLI); it has not run since this landed, and D73 puts the bars on those frames.
- **One band, three stands.** `--bands=1 --max=3 --fast` as the brief asked. Bands 2–5
  were not walked in-container (a full band is ~25 s per stand under llvmpipe in fast
  mode; band 1 alone is 62 stands). The fight-search and bearing logic is band-agnostic
  but has only been exercised against band 1's mudsnout.
- **Fight readability is a check, not a guarantee.** If none of the seven bearings fits
  a band's fighters (a very small species beside a looming companion), the frame is
  refused, listed, and the band retries at the next stand against a different wild; a
  band can end with no fight frame, which fails the run rather than hiding it.
- **The fight frame keeps the combat HUD** (nameplate, party panel, moves) because 2.15
  asks for nameplates and level tags where the game has them; road frames hide every
  canvas layer. The party panel overlaps the trainer's boots in run 3 — a HUD safe-area
  finding, not a capture one.
- **Not a game change.** No file under `scripts/` or `autoload/` was touched. The one
  game-side observation is that `WorldWeather` is re-enabled during the world's boot
  coroutine after a tool freezes it — a trap for every capture tool that pins weather
  before the settle, now handled in the strip by re-pinning before each shutter.
- **`.import` side-effects.** The container's import step generated untracked
  `assets/creatures/tetherbound/*/reference/*.png.import` files; they are outside this
  lane's ownership and were not committed.

## Commits

```
2e0d7a8b capture_check: creature-present-and-readable projection check and a three-subject framing solver
4db63dd0 route strip: deploy the party companion, one solved three-subject fight frame per band, refuse unreadable frames
eba93958 route strip: re-pin weather before every shutter, cap counts attempted stands, read the post-flee context after a process frame
6d8926f1 route strip: refuse on-screen overlap and close-ups, front-quarter bearings from a higher eye, retry a refused fight at the next stand
fe7dfff6 docs: record the landed route strip in CURRENT_STATE (2.15/CL-H9) and the VISUAL_PARITY_PROGRESS resume point
FINAL_COMMIT_PLACEHOLDER
```

Branch: `ralph/W01-ROUTE-STRIP-0904`, pushed to `origin`.
