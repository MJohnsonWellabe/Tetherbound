# Domain coordinators — paste-ready session starters

Each block below is a complete first message for a fresh claude.ai/code
session on this repo. Start one per domain; each coordinator runs its own
worker sub-agents on its own machine and pushes `ralph/<task>` branches.
The meta-coordinator (or anyone with Actions access) dispatches
`ralph-sweep.yml` to land green branches; sweep is fast-forward-only, so
coordinators merge `origin/main` into a branch before final push.

Shared setup every coordinator gives its workers: install Godot 4.7
(`mkdir -p ~/godot-bin && cd ~/godot-bin && curl -sSL -o g.zip
https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
&& unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64`);
`--headless --import` once AND after every merge/bake (stale import cache
is a documented trap); NEVER `--headless` with `--rendering-driver
opengl3` (hangs forever — renders go through `xvfb-run -a`);
`apt-get install -y xvfb` for renders. Read order: CLAUDE.md →
ralph/START_HERE.md → ralph/ASSESSMENT_2026-08-23.md →
ralph/ACTIVE_TASKS.md → ralph/conventions.md.

Claim protocol: before starting, check `git branch -r` for the domain's
branches and read the newest DONE.md entries — if another coordinator's
work is already in flight on a branch, coordinate through the branch, not
around it. One coordinator per domain.

---

## COORDINATOR: GATE-B (finish the opening chapter's evidence)

You are the Gate B coordinator for Tetherbound. Do the shared setup and
read order from ralph/lanes/COORDINATORS.md, then own Gate B to green:
tests/smoke_gate_b_continuous.gd must run title → wake → starter → first
catch → village (Tam, gathering, Oskar, MIRA'S DOOR — the historical
stall; a pathing fix using a stick_navigator/waypoint approach may
already be on ralph/GATEB-PATH, and isolated tail verification on
ralph/GATEB-TAIL — both are HANDOFF branches from wound-down local lanes:
read their DONE/BACKLOG handoff notes first and ADOPT, don't re-derive.
Also read ralph/OWNER_PLAYTEST_2026-08-23.md: OP23-04's tutorial-chain
redesign touches the same opening beats — coordinate with any
ralph/TUTORIAL-CHAIN branch rather than collide) → home
build → creature bed → sleep → tournament → South Bridge, twice
consecutively. Method law: iterate on focused segment probes (minutes),
never on full 30-minute runs; each new stall gets its own probe. Spawn
worker sub-agents for parallel probes. When green: record the evidence in
DONE.md as Gate B's pass, merge origin/main, push, and state GATE B
PASSES plainly in your final report.

## COORDINATOR: VISUAL (the bar is Palworld; the judge is blind)

You are the visual coordinator for Tetherbound. Shared setup + read
order, plus ralph/conventions.md's blind-pass and convergence rules —
they are law: every visual change is judged by a blind critic (a
sub-agent told nothing about what changed) against docs/reference/
(Palworld bar + keyart), iterating until two rounds with no new defect
and no measured movement (tools/frame_stats.py). Your open ledger, in
priority order: (1) chapter day lighting — the sun is authored in the
NORTH sky (art.json pitch −44/yaw −40) while the chapter faces south;
day grade is dark dead-olive vs the high-key keyart (branch
ralph/VISUAL-LIGHT may exist — check); (2) ground-cover density
chapter-wide + flora rescale + band4 hero trees (ralph/VISUAL-GROUNDCOVER
may exist); (3) stronghold round 2: road to the gate, blue-firelight
night balance, wall-gap/sparks/window-rect artefacts, staged scale shots
(ralph/STRONGHOLD-R2 may exist); (4) creature identity round 2 per
docs/reference/owner-board-2026-08-15-creature-colors.png — fantasy
overlays, one roster eye language, alpha material variants, visible
legendary (ralph/CREATURE-IDENTITY-2 may exist; no new creature meshes,
ever); (5) band2 forest floor (ralph/BAND2-FLOOR in flight); (6) the
full-corridor blind pass that re-judges band4/band5 after the density
re-bake and rules on D5's bar question A. Spawn one worker per item;
serialize renders if a shared box loads above ~16. Each worker pushes its
own ralph/* branch with suite 0-failed.

## COORDINATOR: INTEGRATION (nothing lands by itself)

You are the integration coordinator for Tetherbound. Shared setup + read
order, plus ralph/conventions.md's Shipping section — merge is
fast-forward-only and dispatch-only. Continuously: (1) watch `git
branch -r` and CI for green ralph/* branches; when a branch is green but
behind main, merge origin/main into it (DONE.md collisions: keep both,
main's first) and re-push; (2) when several branches are green, build
integration waves (merge them into one ralph/integration-Wn, full suite
0-failed locally, push); (3) triage CI reds: pull failed-job logs, split
pre-existing/stale-base/flake from real defects, hand real defects back
to the owning coordinator via a BACKLOG entry, and maintain the flake
ledger (known: smoke_party_count_after_catches.gd PASS/FAIL/FAIL on one
commit); (4) keep ralph/reports/SUPERSESSION-*.md current as branches
land (patch-equivalence via `git cherry`); (5) if you hold Actions
tools, dispatch ralph-sweep.yml on main after each green integration and
verify `git log origin/main` moved. Never loosen a test to land a branch.

## COORDINATOR: GATE-F (the 3–4 hour proof — start only when Gate B is green)

You are the Gate F coordinator for Tetherbound. Precondition: Gate B's
continuous evidence passes on main (check DONE.md / ask the
meta-coordinator). Shared setup + read order, plus
docs/ralph-prompts/70-MEADOWS-full-chapter-integration-playthrough.md and
ralph/ACTIVE_GAME_PLAN.md §6 (the 14 completion conditions). Drive the
full fresh-save chapter continuously — title through post-Warden world
healing — via the harness (smoke_gate_b_continuous head +
smoke_gate_e_finale tail + the D-corridor evidence runs, chained; build
the chaining harness if none exists). Record per segment: pacing, XP
curve vs docs/MEADOWS_PROGRESSION_CURVE.md, travel/dead-walking
intervals, encounter density, rest usefulness, objective clarity, reward
economy. Fix SHIP-class findings immediately (spawn workers); file
QUALITY/POLISH in BACKLOG. The chapter passes when the full run
completes with the 14 conditions credibly met and the full-corridor
visual pass (VISUAL coordinator's item 6) has ruled. That is Prompt 70
and the end of the Meadows build.

---

## COORDINATOR: PERFORMANCE (OP23-01 — the #1 SHIP blocker)

You are the performance coordinator for Tetherbound. Shared setup + read
order above, then ralph/OWNER_PLAYTEST_2026-08-23.md — OP23-01 ("feels
like ten fps on the ROG") is yours. No container has ROG hardware: you
cannot measure device fps; you CAN measure and rank CPU-side per-frame
costs and RenderingServer stats (draw calls, primitives) headlessly.
Branch `ralph/PERF-ROG` from origin/main. (1) Build tools/perf_profile.gd:
drive the real world at village/band1/band4/stronghold, capture
per-subsystem frame costs (Performance monitors + instrumentation),
draw calls, physics body counts; readable report. (2) Rank: MultiMesh
batching integrity, collision streaming set size, wild tick costs at
density 0.05, vegetation update_mmis, HUD redraws, shadows under
Compatibility, particles. (3) Fix top wins that change nothing visible
(batching, tick strides, streaming radii, visibility ranges,
redraw-on-change HUD); tunables into data/config. Structural changes
(world density, renderer) are OWNER decisions — measure, record numbers
in BACKLOG, don't change the world unilaterally. (4) Ship a device-side
debug overlay/config flag showing frame time + top-3 costs so the next
owner playtest produces numbers. Full suite 0 failed; before/after cost
report committed; one survey render proving looks unchanged. Push once.

## LANE: TUTORIAL-CHAIN (OP23-04 — owner directive, Palworld-style opening)

Branch `ralph/TUTORIAL-CHAIN` from origin/main. Owner's words: the first
task ("find a way through the village gate") makes no sense; the opening
should tell you the NEXT thing to do (gather, catch a pal, ...) one step
at a time like Palworld's early game, walking you through every
tournament prerequisite until all are cleared — never fronting the full
list. Study objectives.json's 11 beats, quest_log.gd, and the real
tournament gates (rested/fed/happy + team of 3 at L3 —
test_tournament.gd, smoke_gateb_flags.gd). Re-order/re-present as a
guided one-step-at-a-time chain in a teaching order; each step names the
concrete action and controller verb; completing one surfaces the next.
Keep flags/chain completable — smoke_gate_b_continuous (may stall at the
known Mira point, that's another lane's), smoke_gateb_flags,
test_quest_log green (update presentation contracts, never loosen what
they prove). Full suite 0 failed. Push once.

## LANE: OP23-FIXPACK (systems/UX quick items)

Branch `ralph/OP23-FIXPACK` from origin/main. From
ralph/OWNER_PLAYTEST_2026-08-23.md: OP23-02 stronghold-battle camera
loss (extend smoke_trainer_battle_camera to a stronghold gauntlet fight,
fix the camera hand-off on that path); OP23-03 map reveal is
experientially invisible (raise starting-reveal radii until village +
roads VISIBLY read on the map; raise test_map_fog's floor to a
player-visible fraction; make zoom level persist across map opens);
OP23-16 HUD shows an empty sixth creature slot at five (hard rule: never
imply a sixth); OP23-13 auto-run (toggle on a spare controller input per
the authored map, no hold-chords); OP23-14 bond gain retune (curve in
data/config, meaningful per action); OP23-15 trait explanations next to
trait names in the UI (short descriptors from data). Each item: fix +
test. Full suite 0 failed. Push once.
