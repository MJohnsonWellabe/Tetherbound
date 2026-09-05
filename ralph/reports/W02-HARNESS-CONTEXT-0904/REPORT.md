# W02-HARNESS-CONTEXT-0904 — CL-H13: the Gate F harness's `input_context` "misresolves" to `build_catalogue`

Branch `ralph/W02-HARNESS-CONTEXT-0904`, from `origin/main` at `ef16544f`.
Final commit: **see the last section** (filled in at the end of the lane).

## 1. Root cause, in one paragraph

`input_context` never misresolved. At every one of the three sites the segment pressed
`combat_charged` while **no fight was running**, the harness injected that action's physical
binding (LT, `JoyAxis:4`), and the engine marked every action bound to that axis pressed —
`combat_charged`, `build_shortcut`, `map_zoom_out`, `build_rotate_left` — exactly as it does
for a real trigger pull. In the `world` context LT is `build_shortcut`, which opens the Build
catalogue **by design** (HUD-INPUT-0903). The catalogue opened, the harness wrote
`pressed combat_charged x1 … PASS`, and every later step ran behind a menu nothing in the
script closes: LB became "category left", X became a pick. The probe's per-frame trace shows
the flip on the exact frame the LT event reaches the game, with the arbiter enabled, no fight,
no trainer battle, `input_context = world`, and the game reading
`build_shortcut + map_zoom_out + build_rotate_left` as just-pressed.

Why no fight was running is different at each site, and none of it is the game's context
router: at Oreth the lead had fainted earlier in the run (BAND4's own HP telemetry), so
`can_challenge()` refused and the "no usable creature" line ran instead of a battle; at Vance
the fight had ended (lost — `S07-60` flag NOT set) sixty-six blind `combat_quick` presses
before `S07-57`; "after Captain Riverwatch" is Oreth again (`captain_riverwatch` *is* Captain
Oreth), seen from G3-HARNESS's second run. So the premise in `FINISH_THE_MEADOWS.md` §0.2 and
the two status rows — "two of the three sites involve no charged attack at all" — was wrong:
`S08-93` is a joypad `combat_charged` hold and sits inside the Oreth block; all three sites
press LT. The shared-binding observation BAND3 made was correct as far as it went; what was
wrong was calling it player-facing (a player knows whether they are in a fight) and what was
missing was that the harness is context-blind.

The two shipped guards (`input_contexts.json`'s exclusivity, `_world_input_allowed()`) hold:
the traces show LT refused in `combat` and in the trainer send-out beat (`locked`, arbiter
disabled). **Nothing under `scripts/` changed for this lane.**

## 2. The fix, at the mechanism

`tools/gate_f/operator_harness.gd`:

- `_load_input_contexts()` / `_expand_context()` — read `data/config/input_contexts.json`
  (the game's own authored map of what is live where), `includes` expanded.
- `_resolve_press(control, context, device, contexts)` — static, pure: is `control` live in
  `context`? If not, which physical event would go in (`raw`) and which actions would it fire
  (`fires`), and which of those ARE live here (`fires_live` — the collision)? Unmapped contexts
  (`title`, `scene:*`, `panel:*`, `locked`, unlisted `menu_*` tabs) and unlisted actions
  (`ui_*`) come back `checked = false`.
- `_press_guard()` / `_press_refusal()` — the instance half: asks the probe's live
  `input_context`, and turns a refusal into a `FAIL press guard: …` result line (landed/wanted
  counts, context, binding, collision) plus a `note` event.
- Wired into the three script-facing blind primitives, re-resolved **before every
  repetition** (`press` — a fight can end on press 25 of 40), `press_until` (every attempt) and
  `hold`. Deliberately not in `_inject()`/`_edge()`: `advance_dialogue_until_closed`,
  `fight_until_resolved`, `chip_to_floor` and the menu walkers already check the state they
  are about, and `press_multi` exists to press across contexts on purpose.
- `_physical_binding()` became `static` (it only reads `InputMap`) so the resolver and the
  probe can share it. No behaviour change.

Not done, per the brief: no rebinding, no extra mouse routing, no segment JSON edits. S07-57's
mouse routing stays; out of a fight it is now refused as *inert* rather than silently doing
nothing. Recorded as `docs/decisions/D74-…`.

## 3. Files changed

| File | Change |
|---|---|
| `tools/gate_f/operator_harness.gd` | press guard (§2); `INPUT_CONTEXTS_PATH`; `_input_contexts` cache; `_physical_binding` static |
| `tests/test_gate_f_rig.gd` | four CL-H13 tests (§4) |
| `tools/gate_f/probe_press_context_flip.gd` | new: the per-frame reproduction / verification probe (§5) |
| `docs/decisions/D74-the-harness-refuses-a-press-the-live-context-does-not-list.md` | new |
| `docs/CURRENT_STATE.md` | §3 P1 row rewritten to fixed, with the evidence |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | CL-H13 row rewritten to fixed, with the evidence |
| `ralph/reports/W02-HARNESS-CONTEXT-0904/REPORT.md` | this file |

Not touched: anything under `scripts/`, `project.godot`, `data/config/`, any segment JSON,
`tools/gate_f/SEGMENT_SCHEMA.md` (not in this lane's ownership — its `press` row should gain
a sentence about the guard; the coordinator can route that).

Untracked and deliberately **not** committed: ten `*.png.import` sidecars Godot generated on
import for reference PNGs under `assets/creatures/tetherbound/{candy_pickup,meadows_bridge_section,meadows_signpost,mushroom_pickup}/reference/`,
committed by another lane without their `.import` files. Outside this lane's ownership.

## 4. Player-visible / operator-visible behaviour

Nothing player-visible changes. For the operator: a `press`, `press_until` or `hold` whose
control is not live in the current context is now **refused and FAILs**, naming the context,
the binding and what it would have done. Blind fight blocks whose count outlives the fight go
red at the first press after the fight ends ("25 of 40 landed before the refusal") instead of
green with the catalogue open. Presses in contexts the map does not describe carry
`[unchecked against input_contexts.json: …]` in their result line.

## 5. Tests

### Unit — `tests/test_gate_f_rig.gd`

```
godot --headless --path . --script tests/run_tests.gd -- --only=gate_f_rig
```

**53 tests, 210 assertions, 0 failed** (exit 0, zero `ERROR:` / `SCRIPT ERROR` lines). The four
new tests, each exercising real behaviour rather than source text:

| Test | What it drives |
|---|---|
| `test_the_physical_collision_the_press_guard_exists_for_is_real` | parses `combat_charged`'s real joypad binding through `Input.parse_input_event` and shows `build_shortcut` pressed by the same event, then released |
| `test_a_press_the_live_context_does_not_list_is_refused_and_names_the_collision` | `_resolve_press` against the real `InputMap` and `input_contexts.json`: `combat_charged`/`world` refused naming `build_shortcut`; `/combat` live; `/world/mouse` refused as inert; `party_cycle`/`build_catalogue` → `menu_tab_left`; `interact`/`build_placement` → `build_place` |
| `test_the_press_guard_passes_through_what_the_map_does_not_describe` | `title`, an unmapped tab, `ui_down` unchecked; `includes` expansion (`menu_backpack`) |
| `test_the_press_step_refuses_before_it_injects` | a harness instance with a stub context drives the real `_step_press` and `_step_hold`: FAIL returned synchronously, nothing injected |

**Seen red for the right reason** before being trusted, twice:

| Break applied | Result |
|---|---|
| `_resolve_press` always answers "live" | `…is_refused_and_names_the_collision` FAIL, `…refuses_before_it_injects` FAIL (2 failed) |
| `_step_press` skips the guard (the old wiring) | `…refuses_before_it_injects` FAIL (1 failed) — the suspended coroutine comes back as an object, not a String |

Restored → 53/0.

### Probe — `tools/gate_f/probe_press_context_flip.gd`

```
godot --headless --path . --script tools/gate_f/build_s08_entry_synthetic.gd -- --out <dir>/seed_s08
godot --headless --path . --script tools/gate_f/build_s07_entry_synthetic.gd -- --out <dir>/seed_s07
godot --headless --path . --script tools/gate_f/probe_press_context_flip.gd -- \
  --seed=<dir>/seed_s08/S07-exit.json --site=oreth --ally=<state> --mode=<blind|guarded> --out=<csv>
godot --headless --path . --script tools/gate_f/probe_press_context_flip.gd -- \
  --seed=<dir>/seed_s07/S06-exit.json --site=vance --ally=<state> --mode=<blind|guarded> --out=<csv>
```

Exit 0 = CLEAN, 2 = FLIPPED. `blind` injects exactly as `press` did before this lane;
`guarded` calls the harness's own `_resolve_press()` before each press, as `press` does now.

RESULTS_TABLE_PLACEHOLDER

### Segment runs through the real harness (logic lane)

Scratch segments (not committed; built from `S08.json` by id, no tracked JSON edited), run
with a run-local `RUN_METADATA.json` declaring the logic lane (`GATE3_EXECUTION_PLAN.md` §4b):

```
godot --headless --path . --script <harness> -- --gatef-out=<run>/<seg> --gatef-run-id=… \
  --gatef-sha=… --gatef-segment=<seg>.json
```

| Run | Harness | Steps | Result |
|---|---|---|---|
| `S08_oreth_block` (S08-01..11, DIAG teleport to (-100,4350), S08-88a..96 verbatim) | pristine `ef16544f` copy | 22 | 21 PASS / 1 FAIL (`S08-96` flag not set); `route.csv` contexts `title 2 · world 362 · narrative_modal 1 · combat 100 · locked 2` — with a fit lead the three-creature fight outlasts the shape, so the pristine harness does not flip here either; the flip needs the fight to END first (§5 probe, `weak`) |
| `S08_first30` (S08-01..S08-26) | fixed, `78ff8478` | 30 | **26 PASS / 4 DELEGATED / 0 FAIL**, complete; `route.csv` contexts `title 2 · world 729 · menu_map 3` — never `build_catalogue`. The guard let `map_zoom_in/out` through in `menu_map` (live there) and marked the title-screen `ui_accept` presses `[unchecked]` |

Side observation for the coordinator, not this lane's: in that run `S08-22` **walked cleanly**
(`839.5 m … in 10853 walking frames (0 held)`), i.e. CL-H14's freeze did not reproduce on this
commit in this container.

## 6. Runtime validation

- Import: `godot --headless --path . --import` on the fresh checkout, then `--check-only` on
  the harness and the probe (both exit 0).
- The unit file, the probe matrix and the two harness runs above. No smoke was named by the
  brief; none of the game's scripts changed.

## 7. Known limitations, and what was deliberately not done

- The guard is only as good as `input_contexts.json`. Contexts the map does not name are
  passed through unchecked (and say so). `locked` — the arbiter-disabled beat between a
  trainer's creatures, a fade — is one of them; the game refuses world hotkeys there itself.
- Steps in existing segments that were PASSing by pressing a combat verb at nothing will now
  FAIL. That is the honest reading (CL-H1's re-scripting to `fight_until_resolved` is the
  cure); `skip_if` exists for a press an author wants to read as moot.
- The harness does not close a catalogue a segment opened some other way; the guard removes
  the cause, not the symptom.
- The probe copies `_edge()`/`_inject()`'s timing rather than calling them (the harness is a
  `SceneTree`); the harness-side proof is the two segment runs and the wiring test.
- `SEGMENT_SCHEMA.md` (not owned) should mention the guard on its `press` row.
- Not done: no rebinding, no mouse routing, no segment edits, no game-script change.

## 8. Final state

FINAL_PLACEHOLDER
