# Gate F — Instrumentation Request (pre-freeze build list)

**From:** Fable, Playtest Director (Phase A). **Date:** 2026-08-25.
**For:** a developer agent. Implementable from this file alone; the full
protocol is `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` (§C schema, §I summary) if
context is wanted, but nothing here requires reading it.

**Deadline semantics:** per `docs/acceptance/GATE_F_PROTOCOL.md` §1.5, everything
below lands on `main` BEFORE the candidate SHA is frozen. After the
freeze, the operator may not change code; missing instrumentation then
means a blocker and a re-freeze, so build it all now.

**Prime directive — non-invasive:** no gameplay code path may change
behavior. Accessors are additive and read-only. Telemetry activates only
under an explicit CLI flag; with the flag absent, the shipped game runs
byte-for-byte identical logic. Telemetry reads live game state (the real
quest log, real party, real input owner) — never a parallel
reimplementation of the thing it reports.

Ship with tests where the repo's conventions require them, and run the
suite before pushing. Branch/CI per `docs/AGENT_WORKFLOW.md`.

---

## 1. Operator harness — `tools/gate_f/operator_harness.gd`

A `SceneTree` script (pattern: `tests/smoke_gate_b_continuous.gd`,
`tests/smoke_menu.gd`) that:

1. Boots the real main scene (`res://scenes/world/meadows_playground.tscn`
   or the title scene, per step-script) with the real autoloads.
2. Reads a **segment step-script** (see §6) naming ordered steps and
   executes them: move-to (by walking input, not teleport, unless the step
   is marked DIAG), press/hold/release control, open menu, capture shot,
   assert expectation, note.
3. **Input injection contract:** every step sends the physical event via
   `Input.parse_input_event` (`InputEventJoypadButton` /
   `InputEventJoypadMotion` / `InputEventKey` / `InputEventMouseButton` /
   `InputEventMouseMotion`) AND the paired
   `Input.action_press`/`action_release` — both, always, so focus
   navigation and poll readers both see it (`docs/AGENT_WORKFLOW.md` trap:
   action-press alone cannot move UI focus). Support tap (1 frame), short
   hold (10), long hold (60), and same-frame multi-press for collision
   probes.
4. Writes `events.jsonl` + `route.csv` (schemas §4 below) into a run
   directory given by `--gatef-out=<dir>`.
5. Captures screenshots on demand (`get_viewport().get_texture()` → PNG)
   with manifest entries, and timed frame sequences at a configurable Hz.
   Runs under xvfb + opengl3 — **never `--headless` with a rendering
   driver** (documented hang). Logic-only segments must also run under
   plain `--headless`, with capture steps becoming manifest entries
   marked `file: null, reason: "headless"`.
6. Exits nonzero on harness error; a game-side failed expectation is NOT
   a nonzero exit — it is a recorded FAIL event and the run continues
   where possible.

## 2. Read-only live-state accessors

Add a single debug singleton or static helper, e.g.
`scripts/debug/gate_f_probe.gd` (loaded only by the harness, not an
autoload in `project.godot`), exposing:

- `tracked_objective() -> {id, text}` — from the real quest log reader
  (the same one `tab_quest_log.gd` uses).
- `party_state() -> Array` — per creature: species, name, level, xp, hp,
  max_hp, fed, rested, bond (from the live party/condition objects).
- `player_vitals() -> {hp, stamina, satiety}`.
- `inventory_snapshot() -> Dictionary` and `equipped() -> {hotbar_slot, item}`.
- `input_context() -> String` — **the game's own current input owner**
  (resolve from `scripts/ui/input_owner.gd` + whatever state selects the
  `data/config/input_contexts.json` context; if the game has no single
  resolver, expose the modal-owner stack plus the booleans the readers
  poll — do NOT invent a new resolver that could disagree with the game).
- `combat_state() -> {opponent_id, opponent_hp[], phase, target_on_screen}`
  — target_on_screen computed from the live combat camera frustum.
- `camera_pose() -> {yaw, pitch, distance, fov}`.
- `clock_weather() -> {hour, weather, sun_energy, preset}`.
- `region_at(pos) -> String` — containment against
  `data/config/map_landmarks.json` regions.
- `nearest_poi_dist() -> float` — nearest wild/trainer/harvest/TM/key/
  interactable, same 30 m POI definition the corridor probe uses.

## 3. Timers and counters (harness-side)

- Durations: process start→title interactive, title→world playable,
  save-op, load-op, and band/region transition (enter event to streaming
  settled), each in ms on the relevant event.
- Distance accumulator, `since_interaction_s`, and a dead-travel meter:
  continuous meters with no POI within 30 m and no meaningful
  interaction, reset on either (definitions in the protocol §F; reuse
  `tools/_probe_gate_f_corridor.gd`'s logic where it fits).

## 4. Output schemas

`events.jsonl` — one JSON object per event, fields exactly as the
protocol §C.1 table (run_id, sha, segment, t, wall, type, objective,
region, pos, heading, camera, party, active_creature, player, inventory,
equipped, input_context, input, combat, flags, clock_hour, light,
weather, perf, distance_m, since_interaction_s, dead_travel_m,
duration_ms, artifacts, expected, actual, observation,
severity_candidate, repro). Omit a field when not applicable to the event
type; never emit fabricated values (no `vram`, no device fps — those
fields must not exist).

`route.csv` — 2 Hz (configurable): `t, wall, x, y, z, heading, region,
clock_hour, weather, frame_ms, physics_ms, dead_travel_m,
nearest_poi_dist_m, input_context`.

`shots/manifest.json` — per capture: `{id, class, segment, t, trigger,
pos, camera_kind, clock_hour, weather, hud, intended_proof, file}`.

## 5. Input-cell probe (for the §8 exhaustion matrix)

A harness routine `probe_cell(control, context_setup)` that: establishes
the context through the production path, snapshots
`{input_context, focus_owner}` , injects the control (tap, then
release-edge check next frame), snapshots
`{world_side_effect, ui_side_effect, focus_after, input_context_after}`,
emits one `input_probe` event, and restores the context. World side
effects detected from live state deltas (player moved, hotbar fired,
creature deployed, item dropped, camera moved), not from log scraping.

## 6. Segment step-scripts

`tools/gate_f/segments/*.json` (or `.gd` data) encoding the protocol's
S01–S10 and X01–X08 step tables: each step has `{id, action, args,
expected}`. The protocol's §E tables are the source; the developer
transcribes mechanically and does not add, remove, or reorder coverage.
Where a step needs an anchor coordinate (move-to), take it from the
protocol's route table — these are walk targets, not teleports, outside
DIAG steps.

## 7. Save handoff

Harness support to (a) copy a saved slot file out of `user://` into the
run directory after a production Save-tab save, and (b) seed `user://`
with a provided slot file before boot, then drive the production
title-screen Load path by synthetic input. Expected to need **zero game
code**; if any game change proves necessary (e.g. a CLI user-dir
override), it lands pre-freeze under this request. Segment handoffs use
slot 4; autosave is slot 0; slots 1–3 stay free for natural play
coverage.

## 8. Overhead self-measurement

A harness mode that runs 60 s idle at a fixed site with telemetry+capture
ON and again OFF, and writes the frame-time delta into the run metadata
note. If the 2 Hz trace or capture cadence costs more than ~1 ms/frame
mean, say so in the note; do not silently thin the trace.

## 9. Runner and guards — `tools/gate_f/run_segment.sh`

- Wraps the canonical invocations: logic mode
  (`godot --headless --path . --script …`) and capture mode
  (`xvfb-run -a -s "-screen 0 1920x1080x24" godot --path .
  --rendering-driver opengl3 --resolution 1920x1080 --script …`).
- Gates capture mode on `tools/capture_diag_minimal.gd` succeeding first.
- Before and after: kill orphan Godot processes whose cwd is deleted
  (pgrep recipe in `docs/AGENT_WORKFLOW.md`).
- Names the output directory `ralph/reports/gate-f-run-<stamp>/` and
  refuses to write into an existing segment directory (restart protection
  — a restarted segment gets `-superseded-<n>` renaming first, manually).

## 10. Explicitly NOT requested

- No changes to gameplay, UI, save format, input map, or data configs.
- No new asserts inside game scripts.
- No device-FPS or VRAM reporting of any kind — `tools/perf_profile.gd`
  already reports what this container can honestly measure and is used
  as-is.
- No modification of `tools/gate_f_chapter_run.py` /
  `tools/_probe_gate_f_corridor.gd`; they are reused as-is where the
  protocol cites them.

## Acceptance (developer self-check before freeze)

1. Harness boots the real scene, opens the pause shell via synthetic
   physical input, moves focus with parse_input_event, closes it, and the
   emitted `events.jsonl` shows `input_context` transitioning
   world→menu→world with focus fields populated.
2. A 60 s walk emits route.csv at 2 Hz with sane positions and a
   dead-travel meter that resets near a POI.
3. Capture mode writes a PNG + manifest entry under xvfb at 1920×1080.
4. Save handoff round-trips: save via tab → copy out → wipe user:// →
   seed → load via title → party/position/flags match.
5. Telemetry-off run leaves zero new files and zero behavior change.
6. Full test suite green.
