# Gate F segment step-scripts — schema and action vocabulary

What `tools/gate_f/segments/*.json` may contain, and exactly what
`tools/gate_f/operator_harness.gd` does with each action. This is the contract
between the person transcribing `ralph/GATE_F_MASTER_PROTOCOL.md` §E's step
tables and the harness that plays them.

Written before the S01–S10 / X01–X08 files exist, on purpose: a vocabulary
invented one step at a time while transcribing ends up with three ways to press
a button and no way to say "hold it".

---

## File shape

```json
{
  "id": "S01",
  "title": "Wake, Grandpa, the starter",
  "lane": "journey",
  "steps": [
    { "id": "S01-01", "title": "boot the world", "action": "boot",
      "args": { "scene": "world" },
      "expected": "the Meadows stands up and the player has control" }
  ]
}
```

| Key | Required | Meaning |
|---|---|---|
| `id` | yes | Segment id. Must match the filename stem — `run_segment.sh` names the output directory from the filename and the harness stamps `segment` from this key, and a mismatch makes two names for one run. |
| `title` | no | Human title, copied into `notes/<segment>.md`'s heading. |
| `lane` | no | `journey` or `diag`. Informational; the per-step `diag` flag is what actually permits a shortcut. |
| `steps` | yes | Ordered array. Executed in order, no branching. |
| `record_hz` | no | §H background frame rate for the whole segment. Default 0.1 (journey); the mandatory high-risk list uses 0.5; `0` turns the continuous record off. See **Continuous evidence** below. |
| `record_hud` | no | `hud` value stamped on background frame rows. Default `on`. |
| `record_camera_kind` | no | `camera_kind` stamped on background frame rows. Default `gameplay`. |

### Step shape

| Key | Required | Meaning |
|---|---|---|
| `id` | yes | Step id, `<segment>-<nn>`. Appears in the notes file and is how a defect is cited. |
| `action` | yes | One of the vocabulary below. An unknown action is a **harness error** and stops the run — a typo'd action that was skipped would silently drop protocol coverage. |
| `args` | no | Action-specific, tables below. |
| `expected` | yes in practice | The protocol's own words for what should happen. Copied verbatim into the step's event as `expected` and into the notes block. Not machine-checked — `assert` steps do the checking; this is what a human compares against. |
| `observation` | no | Free operator note carried onto the event. |
| `severity_candidate` | no | `BLOCKER` / `SHIP` / `QUALITY` / `POLISH`. A *candidate* only; Fable rules in Phase B. |
| `diag` | no | `true` permits the shortcut actions (`teleport`). Absent or `false` refuses them with a recorded FAIL. |

### Verdicts and exit codes

A step whose result string begins with `FAIL` records verdict `FAIL` and **the
run continues** (request §1.6). A *harness* error — an unknown action, an
unopenable file, a missing control — stops the run and exits non-zero. The
distinction matters: a game-side failure is the evidence Gate F is collecting;
a harness failure means the machinery is broken and everything after it is
untrustworthy.

---

## Controls

Every `control` value is an **action name from the live InputMap**
(`project.godot`'s `[input]` section) — `interact`, `jump`, `game_menu`,
`menu_cancel`, `hotbar_2`, `ui_down`, `combat_quick`, … Never a button index and
never a key name. The harness resolves the action to a physical event by asking
`InputMap.action_get_events()` at run time, preferring a joypad binding, then a
key, then a mouse button. So a rebind moves the harness with it, and a segment
script cannot go stale against `project.godot`.

**Every injected control sends both halves, always:** the physical
`InputEventJoypadButton` / `InputEventJoypadMotion` / `InputEventKey` /
`InputEventMouseButton` through `Input.parse_input_event`, *and* the paired
`Input.action_press` / `action_release`. Neither half alone is enough, and each
half alone fails on a different part of the game:

- `Input.action_press` alone **cannot move UI focus**. Focus neighbours are
  walked from real InputEvents arriving through the viewport. A poll-only test
  reports a working menu while the stick moves nothing
  (`ralph/conventions.md`; `tests/smoke_menu.gd` is the worked example).
- A parsed `InputEventJoypadMotion` alone **cannot move the player**.
  `player_controller.gd` and `camera_rig.gd` read `Input.get_vector()`, a poll.
  Measured on `main`: the stick "held" in all eight directions moved the player
  0.00 m every time, and every walk in `gate_a_build_segment.gd` failed as a
  blocked route when it was a press that never arrived.

### Devices

`press` and `probe_cell` take `device`: `"joypad"`, `"key"` or `"mouse"`. Omitted,
the harness prefers joypad, then keyboard, then mouse — the order a
controller-first handheld build wants, and the order every script written before
this argument existed already got.

**Name a device whenever the cell is about the device.** The default preference
silently halved §L.1's KBM parity row: every dual-bound action — W/A/S/D, E, I,
M, Esc, Tab — resolved to its pad binding, so the keyboard half was unreachable
while the matrix cell read as covered. Only the five keyboard-or-mouse-exclusive
actions ever reached the KBM path at all.

An action with **no binding for the requested device is a recorded FAIL**, never
a fallback to another device. The FAIL text names the verb and the device
(`"action 'jump' has no key binding — that verb is unreachable on that device"`),
which is a real answer for the matrix. A silent fallback is exactly how this
stayed invisible, and a KBM cell that quietly injected a pad event is worse
evidence than an honest gap. `probe_cell` still emits its `input_probe` event on
a device miss — an empty cell is not an answer.

Every event's `input` object carries `device: "synthetic"` (honest: no physical
controller exists here) alongside `device_kind`, which names the binding actually
injected — derived from the event that was sent, so it is right even on a
default-device press.

### Hold lengths

`hold` accepts a word or a physics-frame count.

| Value | Frames | Use |
|---|---|---|
| `"tap"` | 1 | The default. A press and its release edge. |
| `"short"` | 10 | A press a human would call deliberate. |
| `"long"` | 60 | One second held — a hold-to-confirm, a charged attack. |
| `<integer>` | that many | Anything else. |

---

## Action vocabulary

### Setup and time

| Action | Args | Does |
|---|---|---|
| `boot` | `scene` (`"world"` \| `"title"`), `path` (overrides), `settle_frames` | Loads the real scene with the real autoloads, settles, primes the change detectors, scans for points of interest. Emits the boot duration in `duration_ms`. |
| `wait` | `seconds` or `frames` | Advances physics frames, ticking every counter. Use `wait` — never a sleep — because idle time is part of the pacing study. |
| `refresh_pois` | — | Rescans the world for points of interest. The harness does this on boot and on a region change and a fight ending; call it explicitly after anything else that adds or removes one. |

### Input

| Action | Args | Does |
|---|---|---|
| `press` | `control`, `hold`, `times`, `settle_frames`, `device` | One control, down-edge, held, up-edge. `times` repeats it with `settle_frames` idle frames between repeats — use it instead of N identical steps, which hide which press failed to land. `device` picks which binding to inject; see **Devices** below. |
| `press_multi` | `controls` (≥2), `hold` | Every down edge delivered **before any frame advances**, then held, then every up edge. The same-frame multi-press the §8 collision probes need. |
| `hold` | `control` | Down edge only. For a hold that has to span other steps. |
| `release` | `control` | Up edge only. Pair every `hold` with one. |
| `stick` | `stick` (`"left"`\|`"right"`), `x`, `y`, `frames` | Analogue deflection held for `frames`, then centred. `x`/`y` in stick space, −1..1, y negative = forward/up. |
| `focus_move` | `direction` (`up`/`down`/`left`/`right`), `times` | `ui_<direction>` taps. **FAILs if focus did not move**, which is the whole point: a focus step that silently did nothing is the defect this action exists to catch. |
| `type_name` | `name` | Types `name` into the live naming prompt on the pad's on-screen letter grid, then presses Done. See below. |

`type_name` exists because naming is mandatory (`docs/OPENING_SEQUENCE.md`) and
it is the one beat nothing else in this vocabulary can reach: `name_prompt.gd`
in pad mode is a letter grid driven by `ui_*` and `menu_confirm`, so "press
confirm until it goes away" types the same letter forever and never finds Done.
Without it the protocol's S01 could not be transcribed at all.

It is still production input — every press is a real physical event through the
live InputMap. The only thing it reads from the panel is **where the cursor is**
(`name_prompt.gd::entry()`'s row/column), because a blind walk of a grid whose
layout it cannot see would be guessing. Nothing is written into the panel and
`_confirm()` is never called directly.

### Travel

| Action | Args | Does |
|---|---|---|
| `move_to` | `at: [x, z]`, `budget_frames`, `held_budget_frames`, `close_enough`, `answer_prompts` | **Walks** there on the left stick via `tests/helpers/stick_navigator.gd`, which detours around geometry and pauses while locomotion is disabled. FAILs (does not error) if it cannot arrive. See the two budgets and `answer_prompts` below. |
| `face` | `yaw_deg` or `at: [x, z]`, `tolerance_deg`, `budget_frames` | Turns the camera on the right stick. Not by writing `rig.yaw`: a written yaw proves nothing about whether the stick can reach it, and §9's camera-correction count only means something if the corrections are real. |
| `teleport` | `at: [x, z]`, `resettle_frames` | **DIAG only.** Refused with a recorded FAIL unless the step carries `"diag": true`. Resets the distance and dead-travel accumulators, so a 2 km jump cannot appear in the pacing study as 2 km of dead walking. |
| `pin_clock` | `hour`, `preset`, `weather`, `freeze`, `settle_frames` | **DIAG only**, same refusal rule. Pins the world clock and weather, then freezes both. See **Pinning the clock** below. |

`move_to` keeps **two** budgets, because a walk stops for two different reasons.
`budget_frames` counts frames spent *walking*; `held_budget_frames` counts
frames spent unable to move at all — a fight, a fade, a conversation. The split
is `stick_navigator.gd`'s own rule (a budget on walking is not a budget on wall
clock), and the second budget exists because the navigator's answer to being
held is to wait ten minutes. A harness cannot afford that: a walk that hangs
produces *no* evidence, which is worse than one that reports where it stopped
and what was holding it. The FAIL message names the `input_context` that held it.

`answer_prompts` taps `interact` and `menu_confirm` alternately while a walk is
held — the buttons a player presses to answer a modal. Both, because the three
panels that own `input_contexts.json`'s `narrative_modal` context do not read the
same one: `dialogue_panel.gd` advances on `interact` and
`starter_picker.gd::_read_input` polls `menu_confirm`. Tapping only `interact`
walked past Grandpa's conversation and then sat in front of the starter picker
for a full held budget. It is **off by default and must stay
off** in any segment whose subject is whether something blocks travel — a
harness that quietly answered the dialogue would be hiding the finding. It is on
in the self-check walks only because walking out of the spawn point triggers
Grandpa's opening conversation, and the subject of those segments is the trace,
not the conversation.


### Menus

| Action | Args | Does |
|---|---|---|
| `open_menu` | `tab` (optional), `control` (optional) | Presses the bound action — `game_menu`, or the tab's own shortcut from `data/config/menu.json`'s `shortcuts` map. Never calls `game_menu.gd::open()`: calling `open()` proves `open()` works and nothing about whether the button reaches it. FAILs if the input context did not become a `menu*` one. |
| `close_menu` | `control` (default `menu_cancel`) | The same, in reverse. FAILs if the shell is still open. |

### Evidence

| Action | Args | Does |
|---|---|---|
| `capture` | `id`, `class`, `hud` (`on`/`off`), `camera_kind`, `trigger`, `intended_proof` | One PNG plus a `shots/manifest.json` row. Under a headless process it writes the row with `file: null` and a reason — an absent frame is evidence (§C.4), so a planned shot is never silently dropped. |
| `capture_seq` | `id`, `hz`, `seconds`, plus every `capture` arg | A timed run of frames, each its own manifest row, so a single missing frame is visible rather than averaged away. **Blocks** — nothing else happens while it runs. |
| `record_start` | `hz`, `label`, `hud`, `camera_kind` | Raises the §H background frame rate for a window. Does **not** block: frames are taken from the per-frame tick every other step already drives, so walking, fighting and menus keep happening. |
| `record_stop` | `baseline` | Ends the window, returning to the segment's baseline rate. `{"baseline": false}` stops the recorder outright — for X08's perf audit, which §H's last clause says runs without capture. |
| `note` | `text`, `severity_candidate` | An operator observation as a schema `note` event. |
| `assert` | `check` + per-check args, see below | Records PASS/FAIL. Never exits non-zero. |
| `probe_cell` | `control`, `expected`, `device` | §5's input-cell probe: snapshot, one tap, snapshot on the release edge, snapshot after settle, emit one `input_probe` event carrying the world-side and UI-side deltas. **Does not establish the context itself** — the steps before it must, through the production path, because a context the harness set up is not the context the player reaches. |

### Save handoff (§7)

Segment handoffs use **slot 4**; autosave is slot 0; slots 1–3 stay free for
natural play coverage.

| Action | Args | Does |
|---|---|---|
| `save_out` | `slot` (default 4), `name` | Copies the slot file out of `user://` into `<run>/saves/`. **Does not save anything** — the operator saves through the production Save tab, and this only preserves the artefact. |
| `seed_save` | `slot`, `from` | Copies a slot file back into `user://` before a title boot, so the next segment's Load Game finds the last one's ending state. |
| `wipe_saves` | `keep_slots` | Empties the live save directory. The wipe half of the round trip: a load that found the state still in memory would prove nothing. |

All three ask the **live** `Game.save_system` for the slot path rather than
hard-coding `user://saves/slot_N.json`, so a run using an isolated save
directory copies from the directory it actually used.

### `assert` checks

| `check` | Args | Passes when |
|---|---|---|
| `input_context` | `equals` | The probe's context name matches exactly. |
| `context_prefix` | `prefix` | It starts with `prefix` — `"menu"` matches `menu_backpack`, `menu_map`, … |
| `focus_owned` | — | Some Control holds GUI focus. The check a controller-only build lives or dies on. |
| `flag_set` | `flag` | That progression flag is set. |
| `objective_is` | `id` | The tracked objective's flag id matches. |
| `party_size` | `equals` | The live party holds that many. |
| `region_is` | `equals` | `map_state.gd`'s own containment puts the player in that region. |
| `near` | `at: [x, z]`, `within` | The player is within `within` metres. |
| `dead_travel_below` | `metres` | The current dead-travel run is at or under that. |
| `dead_travel_peak_above` | `metres` | The LARGEST dead-travel run this segment saw reached at least that. The current value is almost always small — a segment ends near something — so `dead_travel_below` alone can only prove the meter resets, never that it accumulates. |
| `distance_above` | `metres` | At least that much was actually walked this segment. Guards against a route that "passed" because nobody moved. |
| `route_rows_at_least` | `rows` | `route.csv` has at least that many rows — the trace is actually running. |
| `mouse_captured` | `equals` (bool) | Mouse-capture state matches. §E.4 requires it restored on menu close and §L.6-T01 requires it: a menu that does not give the mouse back leaves the camera dead afterwards, which reads as a camera bug rather than a menu one. |
| `satiety` | `equals`+`tolerance` / `at_least` / `at_most` | Player satiety against a comparator. |
| `clock_hour` | `equals`, `tolerance` (default 0.5) | In-game hour, **wrapping across midnight** — 23.9 and 0.1 are 0.2 apart, not 23.8. Tolerance rather than equality because a load restores an elapsed-seconds value, so the hour comes back close rather than identical. |
| `placed_buildings` | `equals`+`tolerance` / `at_least` / `at_most` | Count of the player's placed structures. Without it X05 records the number and verdicts nothing, and a load that silently dropped every building would read as PASS. |

`satiety` and `placed_buildings` take a **named comparator** — `equals` (with an
optional `tolerance`), `at_least`, or `at_most`. A check with none of them FAILs
saying so, rather than silently testing equality against zero.

---

## Pinning the clock (`pin_clock`, DIAG only)

§E.7's regional audit compares sites against each other, which it can only do if
the light is identical in every frame. The unpinned variant is not hypothetical:
the 2026-08-23 pass let `apply_time("day")` be undone by the day cycle's own
`_process` during the settle between shots, and the run came back with a crimson
artefact nobody could reproduce, because the clock had moved underneath it.

**The order is the instrument**, and it is `tools/capture_band3_region.gd`'s:
settle first, *then* pin, *then* stop both clocks. Pinning before the settle is
the bug — `world_look.gd::_process` re-blends every `BLEND_INTERVAL`, so a pin
that precedes a 240-frame settle has been overwritten four seconds later. So a
`pin_clock` step goes **after** the `boot` or `wait` that settles the scene.

- `preset` — a named keyframe from `art.json` (`day`, `golden`, `night`),
  applied through the game's own `apply_time()`.
- `hour` — an arbitrary float, applied through `_apply_blended()`, which is the
  continuous path `world_look.gd::_process` itself uses. Not a second
  interpolation written in the harness. Applied last, so it wins over `preset`.
- `weather` — a `weather.json` preset (`clear`, `cloudy`, `fog`, `rain`) through
  `WorldWeather::set_weather()`.
- `freeze` — default `true`. Stops `_process` **and** `_physics_process` on
  *both* `WorldLook` and `WorldWeather`: the look re-blends on idle and the
  weather rolls its own preset on a timer, so stopping one leaves the other free
  to move the light.

Nothing unfreezes them. A `pin_clock` segment is a DIAG segment and ends.

---

## Continuous evidence (§H)

§H's substitute for full-run video: a PNG at a background rate **plus a forced
frame on every JSONL event**, filed `frames/<segment>/<t>.png` and correlated
back through `events.jsonl` and `route.csv` on the shared `t` axis
(`timestamp → player state → input → event → frame`).

The recorder is **already running before any step asks for it** — the segment's
top-level `record_hz` is the baseline, defaulting to §H's 0.1 Hz for journey
segments. `record_start` *raises* the rate for a window and `record_stop` puts it
back to the baseline. That is why it is a rate change rather than an on switch:
§H wants the record continuous, with the mandatory list merely denser, and a
recorder that only ran between explicit pairs would leave the rest of the
segment with no frames at all. So "every band handoff ±60 s at 0.5 Hz" is a
`record_start`/`record_stop` pair around the handoff, inside a segment whose
baseline keeps recording either side of it.

Frames land in **`frames/`, never `shots/`**. The §G plan is evidence-of-record —
every non-defect entry defined before play, none to be deleted or re-staged — and
mixing a thousand cadence frames into that manifest would bury the twenty frames
somebody chose. Two directories, two manifests, one timestamp axis joining them.

Filenames are zero-padded seconds (`000092.69.png`) so the directory sorts in
time order instead of putting 100 s before 9 s.

**`capture`/`capture_seq` beat the recorder, deterministically.** The recorder
stands down for the whole of a capture step and its next cadence frame is pushed
past it. Two reasons, the first being the one that matters: a §H cadence frame
landing on the same frame as a §G shot would put two files of the identical image
into two manifests, which is how a reader ends up citing the wrong one. The
second is mechanical — both want the same framebuffer on the same frame, and
letting them race would make which file exists depend on step ordering.

Under a headless process every frame becomes a row with `file: null` and a
reason, the same rule as `capture`. The rows are still written, so a headless run
proves the recorder fired at the right times even though it could not draw.

Forced-frame latency is **at most one frame**: an event emitted from inside the
per-frame tick is recorded on that tick, one emitted from a step handler on the
next frame that step advances. Under 17 ms at 60 Hz. Stated rather than claimed
exact — the correlation §H asks for is by timestamp, and both records carry the
same `t`.

Multiple events on one tick coalesce into **one** frame whose `trigger` names all
of them (`event:combat_start,flag_set`). Two events on the same frame describe
the same image; writing it twice would inflate the record without adding a pixel.

---

## What the harness writes

Into `<run-dir>/<segment>/`:

```
telemetry/events.jsonl   one JSON object per event, protocol section C.1 fields
telemetry/route.csv      2 Hz trace, protocol section C.2 columns
shots/manifest.json      { "shots": [ ... ] }, protocol section C.4
shots/<id>.png           the prescribed section G frames that could be taken
frames/manifest.json     { segment, baseline_hz, written, absent, frames: [...] }
frames/<segment>/<t>.png the section H continuous record
notes/<segment>.md       one block per step, protocol section C.3
saves/                   slot files copied out by save_out
RUN_METADATA.json        run identity, environment, overhead note
```

### Two honest deviations from §C.1, stated rather than hidden

1. **`input_state` is an extra field on every event.** The schema has one
   `input_context` string. There is no single input-context resolver in this
   game to read it from — `data/config/input_contexts.json` says so in its own
   first line ("Nothing in the game reads this file at runtime"); the real
   behaviour is four independent booleans each world-verb poll asks for itself.
   So `input_context` is a *name over* those booleans and `input_state` carries
   the booleans themselves: modal owner, combat running/aiming, arbiter enabled,
   pending build, tree paused, focus owner and its label, mouse mode. If the
   name and the booleans ever disagree, believe the booleans — they are what
   the game ran. Inventing a fifth opinion about who owns input would have been
   the one thing the instrumentation request forbids outright.

2. **`vram` and any device frame rate do not exist**, in the file or in the
   code. `perf` carries CPU frame-time shape from `Performance` monitors on this
   container's software rasteriser. Both omissions are §C.1's own instruction,
   marked [OWNER-ONLY]; a plausible number under a real field name is worse than
   an absent field, because a reader cannot tell it was invented.

Fields not applicable to an event type are **omitted**, never emitted as zero or
an empty string.

---

## Diagnostic overrides

`--gatef-cfg=<key>=<value>` overrides one `tools/gate_f/harness_config.json` key
for a single run — `--gatef-cfg=trace_hz=4.0`, `--gatef-cfg=overhead_seconds=20`.
The value is parsed as JSON so numbers stay numbers, and a key the config does
not define is a harness error rather than a silently ignored flag. It exists so a
diagnostic rerun does not have to leave an edited config behind for the next
segment to inherit.

Every override is printed at startup and the effective values are what
`RUN_METADATA.json` records, so a run cannot be re-cadenced invisibly.
