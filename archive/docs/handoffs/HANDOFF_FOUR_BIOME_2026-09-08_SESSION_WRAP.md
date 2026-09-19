# Four-biome handoff — 2026-09-08 session wrap

## GitHub preservation update — supersedes local-only notes below

Owner subsequently requested all source work on GitHub before archiving. This
handoff, all local commits, the two formerly dirty Shellwatch composition files,
the known-red Brine candidate diagnostic, character-picker capture tool and
validated source UID sidecars are now included in the preservation push to
`codex/four-biome-wave0` / PR80. Use the latest branch head, not the earlier
`c3cd1ac82` CI head. The new push needs its own CI verdict; next session must
inspect that run before any further push. Nothing has been merged to main.

The Shellwatch composition now passes parser/loading and focused3 tests/26
assertions (`github-handoff-shellwatch-tests-20260908.log`); actual Shellwatch
runtime remains unproven. Brine candidate and character-picker tools parse
cleanly. Brine's recorded admission failure remains unfixed and is prominently
marked WIP in its source. No new world smoke was started for this preservation.

Generated `.artifacts/`, per-frame PNGs and telemetry captures remain local,
excluded under repository evidence-hygiene rules. Their written verdicts and
reproduction tools are in GitHub. Preserve this workspace if those raw captures
are needed; do not claim they were uploaded. No private API key was added.

The remaining sections describe the exact state at the original wrap, before
this preservation update; references to dirty/untracked source are historical.

Owner requested stop and handoff. Do not treat this as goal completion. Resume
in **C:\Projects\Tetherbound**, not a fresh clone: local commits and two deliberate
uncommitted Water edits are newer than the remote branch. No new session was
created. No further push was made during wrap-up.

## Read and inspect first

Read CLAUDE.md, docs/00_START_HERE.md, every docs/owner file (newest wins), prompts
78 then77, CURRENT_STATE sections0–3 and DEVELOPMENT_ROADMAP. Those were read in
this run; prompt77 section4 is established evidence, not a task to rederive.
The playable-first owner directive supersedes full exit bars for this run:
fresh save opening through Tidewake ending, no debug travel/reload to advance;
no freezes, crashes, softlocks or save corruption; solo; all named fights and
no dead travel over120m. Full visuals/density/performance/MP depth are explicit
SECOND_PASS_BACKLOG items, not silently passed. Five total creatures, human
never fights, real-time piloted combat remain hard rules.

Inspect `git status`, local log and actual processes before acting. Fetch main;
merge any newer main before another push, preserving dirty Water files. Do not
reset/checkout away local work or stage all the untracked artifacts/UIDs.

## Repository and CI

- Branch: `codex/four-biome-wave0`, draft PR80:
  https://github.com/MJohnsonWellabe/Tetherbound/pull/80
- PR79 landed at `7ab4a12647a377a400c43335b64aff8b03ca6d43`.
- Last fetched main: `f6b79a6b32983d3b60f7333d8b44706736701474`, included through
  merge **`01f85b2b356de72689eb90e42242e42ae64d5dfb`**. Verified again before last push.
- Last pushed head: **`c3cd1ac827655c765dd66f0a0d811b861d51f63a`**.
- CI **34218809408**, tested merge `3ab8caf7`, finished green:26 successful jobs,
  three skips. Every successful job log reviewed; every smoke first-attempt.
  https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34218809408
- `ralph/reports/FOUR-BIOME-BUILD/CI-34218809408.md` is the job ledger. Previous
 34216463559 also green26/3 and reviewed. Earlier34213024669 failed Livewire timing.
- **Local Tovin, Varga and later evidence commits are NOT covered by that CI.**
  `git log origin/codex/four-biome-wave0..HEAD` lists the exact unsent set.
- No running CI to cancel at wrap. Future: one coherent push, let it finish,
  read every job. Never push main. No merge/readiness claim for PR80 yet.

## Resume order

1. Finish the corrected Brine candidate admission diagnosis from its actual logs;
   do not rerun its same failed lifecycle strategy unchanged. No production spawn
   coordinates have been changed yet. This is bounded alongside player-path coding.
2. Run the committed Varga-repaired Stormwood continuation; prove Varga and Ondra,
   then compose the prepared paid Crown helper only after Ondra's recipe is earned.
3. Review/parse/test the two **dirty** Shellwatch composition files below. Then run
   opening through Shellwatch, preserving earned Brine state and party.
4. Continue Stormwood's Crown/Dynamo and Water's Tidal/Salt/Sluice/Veilfall ending;
   compose/prove a genuinely fresh four-biome path. Existing chapter fixtures are
   not that proof. Do not stop at the already-green parts.
5. Use a fresh code-blind critic for saved map frames. Prior tree hit its agent
   limit; informed agents/root must not substitute as judges.

## Runtime queue is empty

No Godot process or resumable local run at wrap. Agents were explicitly told not
to launch more work. Full-world Terrain3D runs serialize for RAM only. Import,
re-import, export and render take the cache-writer lock; normal tests/probes that
only read imported resources do not. Prioritize playable path, not build-size.
Use a unique engine `--log-file` every invocation. Never combine headless with a
rendering driver. Do not restart a live process because a polling call times out.

Godot executable:
`C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`

All following logs are in `C:/Users/mattj/AppData/Local/Temp/` on this machine.
No GitHub CLI on PATH; public REST works. The GitHub connector exposes workflow
job log retrieval (discover via ALL_TOOLS), with text in structuredContent.content.

## Stormwood: Varga repair committed, runtime pending

- `e78a76080` resolves only an actual roaming wild winning a trainer button edge,
  then reapproaches. It never counts that fight as the requested trainer win.
- Last run `stormwood-continuous-e78a76080-20260908.log`, session54132, exit1:
  Hesk/Tamsin, sheltered Break, pairA, Maren3 rounds/Verge rod, ordinary wild loss
  and recovery, Dace3 rounds/Hollows rod, Pools charged window, both exact glass
  receipts/wear, pairB, route07 pickup and ActI completion all proved.
- Pools wait68.025wall seconds yielded131.966sim seconds open. Nodes036/037 each
  yielded+3 glass/durable receipt/one pickaxe wear. Do not re-diagnose this as
  missing payout without a new reproduction.
- First failure: Varga challenge loses every stance to Bryn. Both authored bodies
  were exactly `[-700,44.18,2300]`. **`efa2a92b0`** moves trainer Varga to the
  production-heightfield road midpoint `[-630,56.45764165,2390]`, ordinary114m walk
  from Bryn; story NPC remains separate. Root focused5tests/28assertions clean.
- Same commit binds a unique scratch save BEFORE yield/reset. Default-save
  baseline:8 files, aggregate SHA256
  `C1B17A987B5E2B7C3D1EECA13F828BFD574ABF69ED0D67B1797DDB8E2E04CC28`.
  Compare fingerprint before/after next runtime; source/report has procedure.
- Run `--headless --path . --log-file <unique> --script tests/smoke_stormwood_continuous.gd`.
  Require Varga exact activation/all3 rounds/durable win, then Ondra recipe.
  Existing20min outer bound is scope-derived; do not weaken per-step assertions.
- Crown helper `tests/helpers/stormwood_crown_build_segment.gd` (`5fc680337`) is
  prepared, not composed/runtime-proven: named Capacitor fight, six real glass,
  real wood/vine harvest, two paid frames, paid green-ghost Crown arch. No state
  grants. See STORMWOOD-CROWN-NEXT.md and STORMWOOD-CONTINUOUS-PREFIX.md in build reports.
- Last lane handoff commit `0cd1360eb`; no owned dirty Stormwood source at wrap.

## Water: Tovin proved; Shellwatch partial deliberately dirty

- **`657fd49ef`** moves Tovin from inaccessible summit to `(395,809)` beside p5.
  Actual nine Terrain rays and ordinary p3/p4/p5 approach pass; zero resets;
  actionable production challenge wins the live arbiter. First probe failure was
  missing controller deployment, corrected via real recall input, not a gate change.
- **`0ab14b837`** records full Water opening→Tovin pass, exit0:
  `water-opening-brine-tovin-repaired.log` (session27627, terminal).
  Pell dialogue,64.488m lesson, Reedhaven crossing/four real harvest receipts/
  paid6reed+4drift repair,107.088m Brine crossing, graded p1–p5 approach, Tovin's
  two opponents, ally294.5/358, durable defeat and dock trial, failures[].
  No native ERROR/SCRIPT ERROR; ordinary010/011 spawn warnings remain separate.
- Fixture disclosure: chapter starts with synthetic carried level44 five-member
  party and knife/axe, before arrival. No post-arrival grants. **Not an earned
  Stormwood handoff and not full Water completion.**
- `313702f86` prepared Shellwatch helper/test/report. It uses ordinary93.320m
  crossing, real camp bed/rest, Solm2 opponents/release, camp, Irva2/pump, combined
  flag and removal of `shellwatch_to_tidal_cradle_dockBarrier`. Baseline requires
  that barrier present; never count the already-open inbound dock as success.
  Bed uses controller focus to the retained creature instance, not first row.
- **Dirty, unvalidated partials to preserve:**
  `tests/smoke_water_opening_continuous.gd` and
  `tests/test_water_opening_continuous_args.gd` add `--through-shellwatch`.
  They were intentionally left uncommitted when the owner requested wrap.
  Review, parse, run args/helper tests, update WATER-SHELLWATCH-NEXT.md, then run
  `--headless --path . --log-file <unique> --script tests/smoke_water_opening_continuous.gd -- --through-shellwatch`.
  Shorter flags/defaults must remain unchanged. No reset between segments.
- Later Water synthetic suffix already reached Venn/Calder in prior diagnostics,
  but finale and recovery remain unproved. Read WATER-LATE-CONTINUOUS.md rather
  than assuming those fixtures can stand in for earned opening-to-ending play.

## Brine ordinary010/011: retain the measured findings, admission still red

Source JSON Y is NOT the live failure: runtime already normalizes it. Original
physical footprints are steep/missing support, all3 table species return INF.
Candidate smoke found all-species exact-XZ support (production margin):

| Site | Candidate XYZ | Move | Road centre clearance |
|---|---|---|---|
|010|340.8148,58.2118,638.7739|10m|19.120m|
|011|473.6123,41.12988,747.8559|4m|6.738m|

Both ordinary affected spine walks past a real-size inert Riptusk pass with
zero confined resets. Neither is a committed production placement or continuous
forward-view proof. First and corrected-r2 candidate runs both exit1 at admission:
010 has failed=true,members0,spawned=false. Original010 warning occurs during
the walk before candidate mutation. Sticky `_site_failures` makes the unchanged
admission loop skip it. Merely yielding at First Shore did NOT fix the lifecycle.
Logs `water-brine-common-candidate-{engine,stdout}-20260908[-r2].log`.

Next diagnostic must establish pristine candidate admission before any original
site is attempted (or explicit fresh fixture-only IDs with seed caveat), not
clear production failure flags to manufacture a pass. Preserve same species,
count, ordinary physical checks. The agent's final report records latest exact
source attribution. See BRINE-ORDINARY-FOOTING.md and candidate smoke.
Final lane evidence commit: `4586f41f1`. The exact untracked source to preserve
is `tests/smoke_water_brine_candidate_footing.gd` (no UID yet); do not mistake
its parser-green result for a runtime pass. Wait for the director's actual
`population_ready` signal at First Shore rather than guessing a frame count:
base `_ready` awaits process, then `_spawn_creatures` awaits physics. Assert
target IDs pristine and install candidates before any Brine approach. This
repair was identified but deliberately NOT implemented at wrap.

## Stability, map and other proof to retain

- Meadows startup hold `7d8d6b30b`: local fresh boot, repeated boot, ordinary
  Cloudreach return pass grounded/ready/no runaway warning. Report
  AGGRESSION-STAGING-WARNING.md. One old invocation omitted engine log flag;
  wrapper captured output, explicitly recorded deviation.
- Map actual drawing contract restored `8f0584cda`; tests fail closed on missing
  constants. Full-world capture exits0 (`root-map-world-reopen-20260908.log`):
  controller first-open/close/second-open/close, valid clipped canvas, three
 1920x1080 images, zero native errors. **Pixels unjudged; corruption not visually
  closed.** See MAP-WORLD-REOPEN-20260908.md and preserved image folder beside it.
- Root never judged these frames. Fresh next-session critic gets only frames
  and docs/reference under `.claude/skills/visual-judge/SKILL.md`.
- Dialogue detached camera guard `8af6c5576`: CI all13 portrait tests pass with no
  script errors. Native fixture/teardown errors elsewhere remain in CI ledger.
- Runner guard `fe07d4515`: malformed test base now counts failure/exits1 rather
  than aborting before quit and orphaning Godot. Actual negative probe exits1;
  all4 unit shards pass. Does not intercept arbitrary test runtime exceptions.
- Livewire two latest CI runs first-attempt pass, latest samples346/315ms and
  gaps58/46ms inside unchanged180–350ms bounds. Prior379ms gap/186ms sample means
  scheduling sensitivity is not conclusively eliminated. Do not lower bounds.
- Settings teleport already proved all58 destinations after recovery-anchor fix;
  CURRENT_STATE and `.artifacts/realm-teleport-anchor-reset58.log` retain evidence.
- Build-size measured16.31% pack reduction; visual comparison deferred in backlog.
  Creature palette/scale/visibility work and failed blind verdicts are also logged.
  Do not repeat scene polish loops. No art credits spent during this wrap; do not
  copy the previously supplied secret into docs. Recheck balance/ceiling before
  any future authorized generation. Galecrest mesh rounds remain as prior ledger.

## Safe next-session practices

Use existing reports and current tree as evidence, not agent self-report alone.
Give fresh agents bounded file ownership and stop conditions. Do not assume old
agent/session IDs remain callable. Never stage all: many unrelated untracked UID
files, `.artifacts/`, and per-frame captures are intentionally preserved. Use
`rg ... -g '*.gd'` with directory arguments on PowerShell, not wildcard paths.
Do not mark the goal complete or blocked merely because this session wrapped.
