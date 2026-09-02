# Visual Parity Program — progress checkpoint

**This file is the single resume point for the Meadows visual-parity program**
(`docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`, `docs/TETHERBOUND_VISUAL_BIBLE_V2.md`).
A fresh session with only this file plus the repo must be able to continue.
Passes are `VP0…VP11` (visual passes) — never conflate with gameplay Gate A/B/….

## Branch and SHAs

| item | value |
|---|---|
| program branch | `claude/coordination-subagents-3fhz1x` (the owner prompt names `codex/meadows-visual-parity`; this session's harness pins the branch name, so this branch *is* the visual-parity branch — do not create a second one) |
| starting `main` SHA | `252ccc81` (2026-09-01, `origin/main` at program start) |
| current branch SHA | (updated at each pass, see per-pass table) |
| last successful push SHA | (see per-pass table) |

## Pass status

| pass | status | commit SHA | pushed SHA | evidence |
|---|---|---|---|---|
| VP-PRE | in progress | — | — | §VP-PRE below |
| VP0 baseline | pending | — | — | `ralph/reports/visual-parity/VP0-baseline/` |
| VP1 sky/light | pending | — | — | |
| VP2 terrain/ground | pending | — | — | |
| VP3 vegetation | pending | — | — | |
| VP4–VP11 | not started | — | — | |

**Current pass:** VP-PRE. **Next action:** (filled at end of each pass).

## VP-PRE — environment capability check

| check | result |
|---|---|
| 1. Godot binary + project imports | PASS — Godot 4.7.stable.official.5b4e0cb0f at `~/.cache/tetherbound-art/godot`; `--import` twice, 0 script errors (688 MB `.godot/`) |
| 2. real screenshot file on disk from the repo capture path | PASS — `tools/capture_diag_minimal.gd` wrote 1920x1080 via X11/llvmpipe GL 4.5; `tools/survey.gd` wrote 5 frames to `shots/` (copied to `ralph/reports/visual-parity/VP-PRE/`) |
| 3. image is a real rendered frame | PASS — opened `01-spawn-outward.png`/`03-rise-overlook.png`: real world frames (terrain, scatter, buildings, sky). FINDING: `05-spawn-low-sun` (golden) came back a flat frame (spread 0.000) — `apply_time("golden")` renders nothing under this pipeline; carried into VP1 as defect VP1-G0 |
| 4. test command runs | PASS — `tests/smoke_art.gd` headless: `art: OK` in 1m53s |
| 5. blind visual judge invocable from this environment | PASS — a fresh sonnet subagent given only the four VP-PRE frames, `docs/reference/`, the website board and the rubric produced a full critique: `ralph/reports/visual-parity/VP-PRE/JUDGE.md` (bar A: no, bar B: no). Not deferred. |

Environment notes for the next session (all verified 2026-09-01):
- Install Godot 4.7-stable: `tools/art_pipeline/setup.sh godot` → `~/.cache/tetherbound-art/godot`.
- Fresh container also needs: `apt-get update && apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers`
  (xvfb is preinstalled here) and `pip install pillow numpy` for `tools/frame_stats.py`.
- Import once (twice on a cold cache): `$GODOT --headless --path . --import`.
- Capture: `xvfb-run -a -s "-screen 0 1920x1080x24" $GODOT --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/<capture>.gd`.
  NEVER combine `--headless` with `--rendering-driver` (hangs forever, `ralph/conventions.md`).
- Tests: `$GODOT --headless --path . --script tests/run_tests.gd -- --only=<files>` and `tests/smoke_<name>.gd`.
- Blind judge: `.claude/skills/visual-judge/SKILL.md` — run as a fresh subagent given only the
  contact sheet, the frames and `docs/reference/`. Runnable here (Claude Code); record `DEFERRED` only if not.

## §6 acceptance numbers (PROVISIONAL — owner to confirm the placeholders)

| item | value |
|---|---|
| target platform | Windows / ROG Ally |
| renderer | Compatibility (`gl_compatibility`) |
| capture + measurement resolution | 1920x1080 for evidence frames; perf stands at 1280x720 (the repo's `tools/perf_render_stats.gd` series) |
| graphics preset | the shipped defaults: `project.godot` `[rendering]` (directional shadow 2048, positional atlas 2048, soft shadow filter 2, msaa_3d 2x) + `data/config/performance.json` as committed. There is no in-game preset system. |
| minimum sustained FPS | **45 (PROVISIONAL)** — cannot be measured in this container (software GL); owner measures on the Ally |
| minimum 1% low FPS | **30 (PROVISIONAL)** |
| container-enforced proxy per pass | `tools/perf_render_stats.gd`: primitives at `band1_open` ≤ 12.0M (baseline 9.25M with grass_field OFF; 31.7M produced the ~10 FPS owner report), draw calls at `band1_open` ≤ 7500, draw calls at `hall_approach` ≤ 4000 (`docs/PERFORMANCE_BUDGET.md` §0.5). Same tool, same resolution, every pass. |
| test command | `tests/smoke_art.gd`, `tests/smoke_playground.gd`, `tests/smoke_traversal.gd` + `run_tests.gd --only=` the tests owning changed files; full 4-shard unit suite at VP0 and at the end of VP3 |

## Parallel lanes (spawned 2026-09-02 00:39 UTC from 1ef3878a; contract in `docs/VISUAL_PARITY_LANES.md`)

| lane | pass | branch | session |
|---|---|---|---|
| SKY | VP1 | `claude/vp-sky` | session_01BGTw8d5sLdQA8V34RkTgou |
| GROUND | VP2 | `claude/vp-ground` | session_018GT9BkQfWZuu5kVdfmonw8 |
| VEG | VP3 | `claude/vp-veg` | session_01WF4HFAG7p6hPwuVQcjr8GY |
| VILLAGE | VP5 | `claude/vp-village` | session_01M1qiTLwxaFNJp9ZqgNbd52 |
| HALL | VP8 + VP7 | `claude/vp-hall` | session_01FvtyLa4Y6Kvib2fU8G84vM |
| WARRENS | VP6 | `claude/vp-warrens` | session_01XLcXZC6QjZV4mRn8rKC7Lk |

**Wrapped 2026-09-02 01:30 UTC by owner directive ("they're burning my usage").** All six Fable
lane sessions were interrupted and archived. What survived: code/config on `claude/vp-ground`
(24769eff: tiles A/B tile=0 measurement 31.67M primitives at band1_open, far_cover/grass shader edits),
`claude/vp-veg` (d6c0fe55), `claude/vp-village` (8d738af0), `claude/vp-hall` (992fbec7). No lane pushed
a single frame. SKY and WARRENS pushed nothing. Lane-branch code is reviewed and cherry-picked by the
coordinator, never merged blind.

**Area coordinators (Opus), spawned 2026-09-02 01:46 UTC from e3aba7d7** (owner directive: Opus
coordinates, Sonnet codes/renders, Fable judges/plans):

| area | passes | branch | session |
|---|---|---|---|
| WORLD | VP1 + VP2 + VP3 | `claude/vp-world` | session_01XigbWtMzp7EwN5SqzwLvYB |
| PLACES | VP5 + VP6 + VP7 + VP8 | `claude/vp-places` | session_0182PYdBscd4KZMdDfwmmu63 |

Round plans are delivered into the coordinator sessions by the program coordinator; each round ends
with pushed frames + REPORT.md and the session stopping.

**Operating model from here:** the coordinator (this session) judges and plans; rendering runs serially
on the coordinator's box; the code-blind judge is a cheap Sonnet subagent inside this session; remote
Sonnet coder sessions are spawned only for bounded, well-specified rounds when wall-clock parallelism
is worth their setup cost.

## Performance measurements

(filled per pass; baseline in VP0)

## Judge history

### VP-PRE (survey frames, shipped main @ 252ccc81, grass carpet OFF) — `ralph/reports/visual-parity/VP-PRE/JUDGE.md`
**Superseded as a baseline**: these frames were captured with `grass_field` off (the shipped state), which the owner rejected as unjudgeable. Kept only as the capability-check evidence; the program baseline is VP0 with the carpet on.
- Bar A (keyart world): **no**. Bar B (Palworld kind of game): **no**.
- Ranked gaps: (1) the ground does not resolve — grass dissolves into textureless blur a few metres out in 3 of 4 frames; (2) nothing casts a believable shadow — rocks float, and 01 carries a large hard-edged diagonal dark patch with no caster; (3) the palette never leaves a narrow desaturated mid-tone band, sky identical and smeared in every frame, no atmospheric depth (03 horizon is a hard flat line).
- Also: trees are identical ball-on-stick at regular intervals (02); scatter-blob clump with hard falloff (04); no creatures in the survey set (capture gap, not a verdict).
- Response: (1) → VP2; (2) shadows/contact → VP1 (shadow bias, ambient) + VP2 (ground darkening under objects); the 01 diagonal patch is investigated in VP1 (suspect: PSSM split / terrain macro); (3) → VP1. Creature frames are added in VP0's location/combat set.

### VP0 baseline, village + mill pond (carpet ON, main @ 252ccc81 + grass_field enabled) — `ralph/reports/visual-parity/VP0-baseline/JUDGE-village-pond.md`
- Bar A (keyart world): **no**. Bar B (Palworld kind of game): **no**.
- Ranked gaps: (1) the sky — tan/brown-streaked smeared clouds in 7 of 9 frames, a third of every wide shot, "reads as a broken shader"; (2) no creature anywhere in the set; (3) lighting disagrees with itself — clear sky but no ground shadows, flat hard-edged sun disc with no bloom, distant hills with no blue haze.
- Also: single broccoli tree silhouette at one scale everywhere; dead tree and boulder assets copy-pasted; flat plastic leaf cards close up; fenced paddocks enclose nothing; NPCs static (village reads populated, not lived-in); mill has no wheel/chute (frame named "wheel" shows none); tournament frame shows no event dressing.
- Response: (1)+(3) → VP1 (shader rewrite + light/aerial config, drafted); creature frames → added to VP0 via the combat/creature captures, and creature staging near capture stands is a VP9 item; tree variety/leaf cards → VP3; paddocks/tournament/mill dressing → VP5; NPC life → VP9.

## Implementation decisions

- `data/config/grass_field.json` is **ON** for this program (owner directive 2026-09-01: "I don't see how a
  judge can judge anything without the actual grass in the frame"). Current `main` ships it OFF after the
  ~10 FPS Ally report (`ralph/reports/OWNER-0901-PERFORMANCE-LAG-V2.md`, 31.8M primitives/frame at
  band1_open with it on vs 9.25M off). The carpet is the intended ground read, so every evidence frame
  carries it, and **VP2 owns the real fix that report asked for**: per-tile distance culling inside
  `grass_field.gd` so far tiles stop submitting, measured with `tools/perf_render_stats.gd` primitives
  at the fixed stands. The proxy budget in §6 is re-baselined in VP0 against the carpet-on numbers.
  Until VP2 lands, this branch is not an Ally shipping candidate.

## Regressions / unresolved problems

(none yet)

## Resume note

(written at the end of every pass)
