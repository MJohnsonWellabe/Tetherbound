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
| `record_hz` | no | §H background frame rate for the whole segment, **in play seconds** (§H.2). Default 0.1 (journey); the mandatory high-risk list uses 0.5; `0` turns the continuous record off. Forced to `0` on a logic lane. See **Continuous evidence** below. |
| `evidence_lane` | no | §H.1 evidence split (owner decision 2026-08-27). `"logic"`, `"capture"` or `"both"`. Default `"both"`, which is what every segment written before the split means. See **Evidence lanes** below. |
| `capture_lane` | on a logic lane with captures | The segment id that owes the §G frames this lane hands over. Checked, before step 1, to exist, to declare `evidence_lane: "capture"`, and to accept every id handed to it. |
| `owes` | on a capture lane | The §G ids this segment accepts responsibility for. Every one must actually be taken by a `capture`/`capture_seq` step in this file, or the segment is a BLOCKER at step 1. |
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
| `require_context` | no | The input context this step expects to act in, checked **before** the action runs. A string, or a list of them; a trailing `*` is a prefix (`"menu*"`), a leading `!` negates (`"!narrative_modal"`). A mismatch is a FAIL, the step does **not** run, and the segment derails — see **Derailing** below. |
| `resync` | no | `true` marks this step as a recovery point: it runs even while the segment is derailed and clears the derail. `boot` always resyncs. |

### Evidence lanes

Added 2026-08-27, owner decision, recorded in `ralph/GATE_F_MASTER_PROTOCOL.md`
§H.1 with the measurement behind it. In short: a rendered frame of the Meadows
costs 12,721 ms on the Gate F container against 6.1 ms in logic mode, and the
eighteen protocol segments ask for 4,607,802 physics frames. Continuous
recording of every frame is what is unaffordable, not capture — a targeted
probe took 14 real 1920×1080 frames in ~28 minutes on the same box.

| `evidence_lane` | runs | owes | `record_hz` |
|---|---|---|---|
| `"logic"` | headless, for mechanics, telemetry and step verdicts | step verdicts, `events.jsonl`, `route.csv`, saves | forced to `0` |
| `"capture"` | under xvfb, at named states | every id in its own `owes`, on disk | `0` baseline; bounded `record_start`/`record_stop` windows are fine |
| `"both"` | as before the split | its own §G frames **and** its own §H record | as declared |

On a logic lane a `capture`/`capture_seq` step is not skipped, refused or
failed — it is **DELEGATED**, which is its own verdict word, counted separately
from PASS, FAIL and SKIP, and written into `INVENTORY.json` under
`captures.delegated` with `captures.delegated_to`. The segment is complete when
it has done what **its lane** owes. Whether the handed-over frames exist is a
question about the whole run directory, answered by
`tools/gate_f/run_inventory.py` → `RUN_INVENTORY.json` / `RUN_INCOMPLETE.md`.

Three declarations are refused at step 1, because each of them is a debt that
would otherwise quietly stop existing:

* a logic lane with prescribed captures and no `capture_lane`;
* a `capture_lane` that does not exist, is not `evidence_lane: "capture"`, or
  whose `owes` does not accept every id handed to it;
* a capture lane whose `owes` names an id no step of it actually shoots.

`S01.json` (logic) and `S01C.json` (capture) are the worked pair.

### Verdicts and exit codes

A step whose result string begins with `FAIL` records verdict `FAIL` and **the
run continues** (request §1.6). A *harness* error — an unknown action, an
unopenable file, a missing control — stops the run and exits non-zero. The
distinction matters: a game-side failure is the evidence Gate F is collecting;
a harness failure means the machinery is broken and everything after it is
untrustworthy.

A third verdict, `SKIP`, exists for a step that was not run because an earlier
one derailed the segment. It is not a pass and not a finding: it is absence,
labelled.

### Derailing — why a context failure skips instead of continuing

`require_context` and `assert_context` behave differently from every other
failure in this file, and the difference is deliberate.

§1.6's rule that a segment does not stop at its first defect is a rule about
verdicts on **the game**. A step whose required context does not hold is not a
verdict on the game — it is a statement that the instrument is pointed at the
wrong thing. Running the next forty steps anyway does not collect forty more
findings; it collects forty fabrications, each one a world control pressed at
whatever actually owns input, recorded as though the game had done something
wrong.

That is not hypothetical. The Gate F run against candidate `f082bdf6` produced
202 journey failures, of which 118 in X01 and 21 in X02 were refuted in Phase B
from the run's own data: they were the harness pressing at a modal it did not
know was open. So:

* a failed `require_context` records **one** FAIL, at the step that could not
  drive the game, naming the context, the input owner, the focused control and
  the paused state;
* every step after it records `SKIP` with that reason attached;
* the segment resynchronises at the first step whose own `require_context`
  holds, or at any `boot`, or at any step carrying `"resync": true`;
* `INVENTORY.json` records `derailed` and `derailed_at`, so a segment that
  derailed can never read as complete.

The rule of thumb: put `require_context` on every step that presses a world
control, and `assert_context` at the seam between blocks.

### Matrix cells — `intended_context`, which does NOT derail

`probe_cell` is the exception, and the exception is deliberate.

X01 walks 418 (control, context) cells in sequence. A press that changes context
is not undone, so the next cell fires into whatever the last one opened. In the
`f082bdf6` run **303 of 418 cells (72.5%) were injected in a context other than
the one the step names**; eight different surfaces were all actually probed
inside `menu_map`, twelve named surfaces were never entered at all, and the
matrix's headline "1085 PASS / 118 FAIL" therefore describes mostly nothing. Its
only trustworthy content was the 115 in-context cells — which were 115/115 clean.

So a cell names `intended_context` rather than `require_context`:

* out of context, the cell is **SKIPPED** and the segment moves to the next cell;
* it does **not** derail, because a 418-cell matrix that stopped at the first
  drift would be worse evidence than one that reports which cells were real;
* `intended_context` and `context_before` are fields on the `input_probe` event,
  so counting in-context coverage is one query rather than a regex over prose.

Report in-context coverage as a headline number beside the pass rate. A matrix at
27% in-context coverage must not be reported as 87.9% behaving.

### Reaching a thing, not a coordinate

`move_to` compares x and z only, and that is a defect with a measured price.
Grandpa's bed is 0.89 m from him in plan view and **3.3 m above him**, so `S02-15`
"arrived" and then pressed `interact` 31 times through the floor. The same shape
recurs as 65 `did not reach (x,z)` failures, and it is why the chapter's first
wild fight never staged.

*Reached* means: within interaction range of the **entity**, prompt live. Not
within a radius of a literal coordinate. That is what `move_to_entity`
(3D arrival by default) and `interact_with` (prompt asserted before the press)
are for, and a journey step written as "go to the trainer" should be transcribed
with them rather than with a pair of numbers.

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
| `press_until` | `control`, `check` (an `assert` check dict), `skip_if` (an `assert` check dict), `max_presses` (default 4), `settle_frames` (default 20), `hold` | Press `control` until `check` holds, re-evaluating between presses. PASSes the instant it holds — **including on zero presses, when the world is already in the wanted state** — and reports the count; FAILs at `max_presses` naming the last state seen. Priced at its full budget, like a walk, so an early exit cannot talk the cost gate into launching a segment it cannot afford. Use it for any control that TOGGLES a state (`interact` arming the catch aim is the one this was written for): a fixed `times` on a toggle lands on a different parity depending on where the state already was, which is CD-3's own failure shape applied to a press. A predicate this envelope cannot evaluate is a SKIP, never a press storm. `skip_if` names the state in which the step is MOOT and returns SKIP before pressing — a retry block after the catch already landed has nothing to press at, and CD-4's rule is that a moot step is SKIPPED, never FAILed. |
| `chip_to_floor` | `control` (default `combat_quick`), `hold`, `settle_frames` (default 30), `max_presses` (default 15), `safety_factor` (default 1.25), `floor_fraction` (default 0.01), `skip_if` (an `assert` check dict) | Presses `control` against the live `CombatManager` enemy, reading its real `hp` before and after every swing, until throwing another swing could plausibly faint it — never a guessed hit count or a guessed HP-fraction floor. `combat_math.gd::rolled_damage()`'s only per-swing randomness against a fixed target is its `variance` roll (+/-10%); type/power/attack/defence are fixed for repeated hits from the same move against the same target, so one real hit already reveals, within +/-10%, what the next will cost. Stops BEFORE a swing once `current_hp - (largest hit seen so far * safety_factor) <= max_hp * floor_fraction` — i.e. once the worst plausible next hit could reach the floor. The first swing always goes in blind (no data yet). FAILs loud, naming every hit dealt, if the target faints anyway (widen `safety_factor`) or leaves the fight mid-chip. Reports presses taken, final HP/fraction, and the full per-hit damage list. `skip_if` is the same CD-4 escape `press_until` has. |
| `equip_tool` | `tool`, `control` (accepted, IGNORED — see below), `max_attempts` (default 3), `settle_frames` (default 60) | Reads `hotbar_slot_of(tool)` off the live probe to find WHICH hotbar control currently holds `tool`, presses it, then re-reads `equipped().item` until it equals `tool` — retrying up to `max_attempts` times, re-reading the slot on each retry in case it moved. Never a fixed hotbar control, and `control` (kept only so an older step script still parses) is not read: the same class of fix `focus_item` gave the satchel half of this sequence. Written for two failure modes measured directly, not guessed: (1) `playground_hud.gd`'s hotbar toggles — pressing the slot that is ALREADY equipped unequips it rather than re-selecting it — and a press landing while a tool swing (`tool_hold.gd`) is still in flight is dropped, not queued, either of which can silently leave the wrong tool (or nothing) equipped; (2) the hotbar slot a tool actually sits at is not fixed run to run — a step script's `control` is a claim about where one assign sequence put something, and a later run of the IDENTICAL assign sequence put the knife at a different slot, which a fixed `control` has no way to notice. Both read at the harvest node as a refused gather (`harvest_node.gd`'s "Needs a [tool]." toast, e.g. "Needs a Knife.") that this vocabulary previously had no way to see — a wrong-tool press and an unreachable node were indistinguishable from outside the game. PASSes immediately, reporting 0 presses, if the wanted tool is already equipped. FAILs immediately, without pressing anything, if `tool` is not on the hotbar at all. FAILs at `max_attempts` naming what is actually held. |
| `throw_until_caught` | `max_throws` (default 4), `aim_budget_frames` (default 240), `resolve_seconds` (default 6.0), `throw_control` (default `interact`), `skip_if` (an `assert` check dict) | Arms the aim, tracks the live target, throws, and waits for the verdict — repeating up to `max_throws` times against the SAME already-chipped target in the SAME fight, stopping the instant the party grows (caught) or the fight ends another way (fled, `is_fighting()` false). A missed throw does not end a wild fight (`combat_manager.gd::_finish_catch()`'s failure branch re-engages the same target; `catching.json`'s own `throw.cooldown` exists specifically so a failed catch can be re-thrown once the wobble clears), so a script that walked away after one orb was leaving real, intended-to-be-retried chances on the table. Internally re-uses `press_until`/`track_aim`/a plain throw press/`wait` per attempt — no separate implementation to drift from theirs. |
| `track_aim` | `budget_frames` (default 240), `skip_if` (an `assert` check dict) | RIG-F3. Steers the right stick every frame at the live catch target's CURRENT `centre()`, measured from the aim CAMERA's own eye (not the trainer — the aim camera sits off to one side, and steering from the trainer is off by exactly that parallax and never converges; measured before this correction) — while already inside `combat_aim`, reading eligibility off `throw_aim.gd::aim_report()`, the same live diagnostic the throw's own commit reads. PASSes the instant the reticle is confirmed `eligible` (on the body, unobstructed), reporting the frames that took; FAILs at `budget_frames` naming the last reason seen (`reticle_outside_body`, `line_of_sight_blocked`, …), or if the aim was left or the target vanished mid-track. CD-3's press-until-predicate rule, applied to a continuous analogue input instead of a press: `throw_aim.gd::_acquire_target()` only snaps the camera once, at aim entry, and a script that does anything else (a `capture` step, a `wait`) before the `press` that releases the throw is aiming at wherever the target stood at that snap, not where it is now. Place it between entering `combat_aim` and the `press` that throws — it only steers, it never presses the throw itself, so the release stays its own step and its own evidence. `skip_if` is the same CD-4 escape `press_until` has: a retry block reached after the catch already landed has nothing to aim at, and is SKIPPED rather than FAILed. Priced at its full budget like `press_until`. |
| `hold` | `control` | Down edge only. For a hold that has to span other steps. |
| `release` | `control` | Up edge only. Pair every `hold` with one. |
| `stick` | `stick` (`"left"`\|`"right"`), `x`, `y`, `frames` | Analogue deflection held for `frames`, then centred. `x`/`y` in stick space, −1..1, y negative = forward/up. |
| `focus_move` | `direction` (`up`/`down`/`left`/`right`), `times` | `ui_<direction>` taps. **FAILs if focus did not move**, which is the whole point: a focus step that silently did nothing is the defect this action exists to catch. |
| `focus_item` | `item` (id), `max_moves` (default 60) | Moves the SATCHEL cursor onto the cell holding `item`, one real `ui_left`/`ui_right` at a time, re-reading the cursor between presses. **FAILs if the bag does not hold the item, if the Satchel does not own focus, or if the cursor cannot reach the cell.** Use this, not `focus_move`, for anything that acts on a named item: a press count is only right for one arrangement of the bag, and a bag two Revives and two potions into a real run is not that arrangement (GAME-9/RIG-24 — three tool bindings landed on the wrong items in silence, every step reporting PASS). |
| `advance_dialogue_until_closed` | `max_presses` (default 60), `settle_frames` (default 90), `close_settle_frames` (default 30), `chain` (default `true`), `control` (override) | Advances an open narrative modal **by predicate, never by a press count**. Reads the panel's own line (`dialogue_runner.gd::line()`, or the starter picker's highlighted index), presses, waits for that line to change or the panel to close, and stops the moment it closes. Picks the button off the panel: `interact` for a conversation, `menu_confirm` for the starter picker; refuses the naming prompt and points at `type_name`. FAILs if no modal is open, if the panel stops responding (naming the line it stuck on), if it is still open at the budget, or if it closes and **re-opens** — the over-press signature. A different modal taking input afterwards is a chained conversation and is reported, not failed. |
| `fight_until_resolved` | `budget_frames` (default 9000), `switch_below` (default 0.35), `gap_frames` (default 18), `quiet_frames` (default 240), `until_flag` | Drives a fight **by predicate, never by a press count** — the same reason `advance_dialogue_until_closed` exists. Presses `combat_quick` only while the action machine reads READY (so it never mashes into the commitment guard `can_switch()` respects), and presses `party_cycle` ONCE when the piloted creature drops to `switch_below` of its max HP and the manager says a switch is possible. Stops when `is_fighting()` AND `EncounterDirector::trainer_battle_active()` have both been false for `quiet_frames` — both, because a trainer battle goes quiet BETWEEN its creatures and a driver that stopped on the first gap would abandon a five-creature Warden after his first one fell — or when `budget_frames` runs out, or when the cost gate stops the run. FAILs if `until_flag` is named and not set at the end. Opens no menu and uses no item: a fight it wins is won on levels, types and the belt. |
| `type_name` | `name` | Types `name` into the live naming prompt on the pad's on-screen letter grid, then presses Done. See below. |

`fight_until_resolved` exists for the reason the two actions above it do, and
it was paid for the same way. A fight's length is a function of both levels,
the type chart and a ±10% roll on every hit, so a counted run of
`combat_quick` presses is right for exactly one matchup. Measured on S10a
across three runs: a water pilot against a water defender spent every press
budgeted for a trainer's THREE creatures on the first one (46.8 s to clear
247 HP); the `party_cycle` presses meant to hand over between rounds then
landed mid-round and were refused by the commitment guard; and the fight was
lost to a single faint with three untouched creatures on the belt, because
`encounter_director.gd::_on_trainer_round_ended()` ends the whole battle when
the PILOTED creature falls. Every one of those steps reported PASS, because a
press step only ever asserts that input was injected — the same defect shape
RIG-26 found on engage steps.

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
| `move_to` | `at: [x, z]`, `budget_frames`, `held_budget_frames`, `close_enough`, `close_3d` (default `false`), `answer_prompts` | **Walks** there on the left stick via `tests/helpers/stick_navigator.gd`, which detours around geometry and pauses while locomotion is disabled. FAILs (does not error) if it cannot arrive. See the two budgets and `answer_prompts` below, and **RIG-F5** below for what `close_3d` does and why it does not fail the instant a 3D gap shows up. |
| `move_to_entity` | `entity`, `within` (default 2.5), `nearest` (default `true`), `rank` (default 0), `close_3d` (default `true`), plus every `move_to` arg | Walks to a **thing**, resolved by identity and re-read every frame so the walk tracks something that moves. Resolution order: exact node name, group membership, `label()`, `species_id`, then a name substring; ambiguity picks the nearest and says so in the result; **`rank` picks the Nth-nearest instead** (0 = nearest), clamping to what actually spawned and saying it clamped. `rank` is what makes a RETRY ladder retry something: `ralph/GATE-F-FULL` measured S03's ten-attempt engage ladder resolving the same creature ten times, walking 0.0 m each time because the player was already inside `within`, and losing the interaction arbiter to the same deadwood node on all ten. An entity that is not in the world is a FAIL naming the search — "I arrived and nothing was here" is a finding a coordinate walk cannot make. |
| `interact_with` | `entity` (optional), `expect_prompt`, `check_provider` (default `true`), `expect_change` (default `true`), `hold`, `settle_frames` | Presses `interact` **only when `interaction_arbiter.gd` has a live prompt**, and refuses otherwise with what the arbiter could see instead — including how far the named entity is in 3D and how much of that is vertical. Also refuses when the prompt belongs to a different provider, or when `expect_prompt` does not appear in it: a prompt from the wrong provider is how a step meaning to talk to Grandpa opens a chest, and it reads as a successful interaction either way. FAILs if the press changed nothing — `expect_change: false` acknowledges a press the operator knows is legitimately inert, and must be written down before playing so a quiet no-op can never be read as an expected one. |
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

**RIG-F5** (`move_to_entity` had this from the start; `move_to` gained it
2026-09-02). `move_to` compares x/z only by default — steering is flat, you
walk in a plane — because arrival is sometimes a 3D question: Grandpa's bed
was 0.89 m from the player in plan view and 3.3 m above him, so a walk
"arrived" and pressed `interact` 31 times through the floor. `close_3d: true`
makes arrival also require the real 3D distance to close.

The first version of that fix FAILed the instant flat arrival ≤ `close_enough`
but 3D distance was still over it — correct for Grandpa's bed (a floor
entirely between the player and the target, unclosable by walking) but wrong
for a slope: the identical shape also fires for a node standing a step higher
than the ground the walk approached it across, where a few more frames of
walking closes the gap fine. Measured on S03's gather ladder after the VP
terrain change (`FINDING-S03-POSTMERGE-TERRAIN-VARIANCE-2026-09-02.md` and
its correction): ordinary gather-node terrain started FAILing at this check
that used to pass, because "close in x/z but not yet in 3D" was being read as
"unreachable" on the very first frame it was seen, rather than given the rest
of the walk's budget to actually climb.

The corrected rule: once flat arrival is reached, if the *vertical* gap alone
is already ≥ `close_enough` (directly under or over the target — no amount of
flat walking changes a pure vertical offset), FAIL immediately, same message
as before, naming the 3D distance and how much of it is vertical. Otherwise
keep walking — the loop does not break, `stick_navigator` keeps steering
flat, and ground-following closes the rest as the player advances up the
slope — while tracking whether the *real* 3D distance is still shrinking.
FAIL only if it stalls: 90 frames without the 3D distance improving by more
than 2 cm, while the flat gap has also narrowed under 0.8 m (so it is not
just walking around an obstacle) — that combination is a plausibly real
unreachable gap, not a walk that has not finished climbing yet.

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
| `capture` | `id`, `class`, `hud` (`on`/`off`), `camera_kind`, `trigger`, `intended_proof` | One PNG plus a `shots/manifest.json` row, carrying that frame's own `luma` statistics (mean, spread, dark fraction) and **FAILing when the frame is degenerate** — see **A frame that photographs an obstruction** below. Under a headless process it writes the row with `file: null` and a reason — an absent frame is evidence (§C.4), so a planned shot is never silently dropped. |
| `capture_seq` | `id`, `hz`, `seconds`, plus every `capture` arg | A timed run of frames, each its own manifest row, so a single missing frame is visible rather than averaged away. **Blocks** — nothing else happens while it runs. |
| `record_start` | `hz`, `label`, `hud`, `camera_kind` | Raises the §H background frame rate for a window. Does **not** block: frames are taken from the per-frame tick every other step already drives, so walking, fighting and menus keep happening. |
| `record_stop` | `baseline` | Ends the window, returning to the segment's baseline rate. `{"baseline": false}` stops the recorder outright — for X08's perf audit, which §H's last clause says runs without capture. |
| `note` | `text`, `severity_candidate` | An operator observation as a schema `note` event. |
| `assert` | `check` + per-check args, see below | Records PASS/FAIL. Never exits non-zero. |
| `wait_until` | the same `check` + per-check args as `assert`, plus `budget_frames` (default 600) and `poll_frames` (default 5) | **CD-3 applied to waiting.** Polls the same predicate `assert` asks once, and PASSes the moment it is true, reporting how many physics frames that took; FAILs at the budget naming the last thing it saw. Use it instead of `wait` + `assert` wherever the state being asserted arrives asynchronously — a catch resolving, a fight ending, a flag the game sets a beat later. A `wait` with a guessed frame count is wrong in both directions and has cost this protocol at least three recorded false FAILs; `ralph/GATE-F-FULL` measured `S02-45` reading `party size 1 (wanted 2)` **0.53 s of play before the party became 2**. A check the envelope cannot evaluate is returned as a SKIP immediately rather than polled. |
| `assert_context` | `is` / `one_of` / `prefix` | The `require_context` predicate as a step of its own, for a checkpoint between blocks. Same matching rules. A mismatch **derails** the segment: it names the context, the input owner, the focused control, the paused state and any armed build ghost, and every following step is SKIPPED until one resynchronises. Use `require_context` to say "do not do this here"; use this to say "the previous block was supposed to leave the game here". |
| `defect` | `what`, `severity_candidate` (default `SHIP`), `observation`, `repro` | Records an operator-found defect as a first-class `defect` event. §C.1 has always had the type; nothing ever emitted it, so a Phase B reader had to re-derive defects from prose. |
| `probe_cell` | `control`, `expected`, `device`, `intended_context` | §5's input-cell probe: snapshot, one tap, snapshot on the release edge, snapshot after settle, emit one `input_probe` event carrying the world-side and UI-side deltas. **Does not establish the context itself** — the steps before it must, through the production path, because a context the harness set up is not the context the player reaches. `intended_context` names the context the cell is *about*: if input is somewhere else the cell is **SKIPPED (context not reached)**, never PASS and never FAIL, and `intended_context`/`context_before` are first-class fields on the `input_probe` event so in-context coverage is one query. See **Matrix cells** below. |

### Save handoff (§7)

Segment handoffs use **slot 4**; autosave is slot 0; slots 1–3 stay free for
natural play coverage.

| Action | Args | Does |
|---|---|---|
| `save_out` | `slot` (default 4), `name` | Copies the slot file out of `user://` into `<run>/saves/`. **Does not save anything** — the operator saves through the production Save tab, and this only preserves the artefact. |
| `seed_save` | `slot`, `from` | Copies a slot file back into `user://` before a title boot, so the next segment's Load Game finds the last one's ending state. |
| `await_save` | `slot` (default 4), `timeout_s` (default 30) | Place immediately **after** the Save tab's confirm press. Waits for the slot file on disk to change and emits a `save` event carrying the measured `duration_ms` — button to file, which is the interval a player experiences. FAILs if nothing lands: the confirm either did not reach the serializer or the write failed silently. Does not save anything itself. |
| `await_load` | `timeout_s` (default 180) | The other half. Place immediately **after** the title screen's Load press. Waits for a live world scene with a live Player, emits a `load` event with the measured `duration_ms`, and re-primes the change detectors the way `boot` does — otherwise everything on the loaded save reports as having just happened. |
| `wipe_saves` | `keep_slots` | Empties the live save directory. The wipe half of the round trip: a load that found the state still in memory would prove nothing. |

All three ask the **live** `Game.save_system` for the slot path rather than
hard-coding `user://saves/slot_N.json`, so a run using an isolated save
directory copies from the directory it actually used.

### `assert` checks

| `check` | Args | Passes when |
|---|---|---|
| `input_context` | `equals` | The probe's context name matches exactly. |
| `combat_running` | `equals` (default `true`) | `CombatManager::is_fighting()`. Use this after any engage step: `input_context == "combat"` says something combat-shaped owns input, this says a fight is actually running. A bare `press` on an engage asserts only that input was injected, which is how S02 PASSed its engage step into an unengaged world for six runs (RIG-26). |
| `enemy_hp_fraction` | `at_most` and/or `at_least` (0-1) | The live enemy's `hp/max_hp`. Pairs with `press_until`/`combat_quick` to chip a target down to a live HP threshold instead of a guessed hit count — a fixed `times: N` leaves wildly different HP% depending on the target's own defence (measured 57%-75% for the same species/level across one real run). |
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

**The rate is in PLAY seconds, and was wall seconds until 2026-08-28.** §H's
"PNG every 2 s (0.5 Hz)" is 2 s of the game's own elapsed time. Under the
12,721 ms rendered frame the run-2 BLOCKER measured, the old wall-clock cadence
fired on **every rendered frame**: S01 planned ~90 frames and was on course for
~5,400, about 10 GB, into 23 GB free. See §H.2.

**The continuous record is not what a segment relies on any more.** §H.1's
evidence split (owner decision 2026-08-27) moves prescribed frames to a capture
lane that takes them at named states. A logic lane keeps no record at all, and
a capture lane keeps only bounded windows. The mechanism below is unchanged and
is what those windows use.

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

### What the recorder costs, measured

§H's last clause asks whether frame capture distorts frame timing. It does, and
the amount decides the rate a segment can afford.

The **frame-time difference cannot answer this** in this container: llvmpipe at
1920×1080 renders with a spread of 6–21 ms/frame between two identical 30 s
windows, so a 1 ms/frame effect sits an order of magnitude below the noise
floor. Both the before/after deltas came back negative on the first attempt —
telemetry apparently making the game faster — which is drift, not a result.

So the readback and encode are **timed directly**, which is immune to that:

| | measured |
|---|---|
| one readback + PNG encode at 1920×1080 | **126.5 ms mean, 218.9 ms max** (n=32) |
| amortised at 0.1 Hz (journey baseline) | **0.21 ms/frame** — under the line |
| amortised at 0.5 Hz (§H mandatory list) | **1.05 ms/frame** — **over the ~1 ms line** |

Consequences, applied rather than noted:

- **X08 declares `record_hz: 0`.** §H names it: the perf audit runs without
  capture. A perf audit that recorded frames would corrupt the one number it
  exists to produce.
- The 0.1 Hz journey baseline is comfortably affordable and stays on everywhere
  else.
- A 0.5 Hz mandatory window is affordable *as a window* — it is a 1 ms/frame
  cost for the length of the window, not for the segment — but a segment that
  sets its whole baseline to 0.5 Hz is paying it throughout, and should say why.

Every run's `RUN_METADATA.json` carries `frame_grab_ms` with `mean_ms`, `max_ms`,
`n` and `amortised_ms_per_frame_at_hz`, so this is re-derivable per run rather
than a figure to trust. **The trace was not thinned to make any of it look
better.**

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
RUN_METADATA.json        run identity, environment, overhead note, feature flags
INVENTORY.json           the section M closing inventory, computed (see below)
INCOMPLETE.md            written only when the inventory says the segment is not complete
BLOCKER.md               written only when the capture pre-flight refused to start
```

### The capture pre-flight, and why a segment can refuse to start

Before step 1, a segment that declares any `capture`/`capture_seq` step or a
non-zero `record_hz` must prove it can take a picture. Three separate questions,
because they fail separately:

1. **Is there a display server?** `--headless` was passed, or xvfb was not.
2. **Did `tools/capture_diag_minimal.gd` write `capture_smoke.png` beside this
   run?** `run_segment.sh --capture` gates on it, so its absence means this
   segment did not come through the capture path — either started by hand, or
   started in logic mode.
3. **Can this process, in this scene, read back a frame and encode it?** A
   display server that exists and a viewport that returns an empty image are
   different faults with one symptom.

Any of the three failing is a **BLOCKER**: `BLOCKER.md` is written, a `defect`
event is emitted, no step runs, and the harness exits non-zero.

This exists because of coverage defect CD-1. The run against `f082bdf6` ran its
journey and study lanes in logic mode **by a recorded operator decision**, which
was legitimate — `run_segment.sh` applies xvfb only in capture mode, and logic
mode is deliberately `--headless` with no driver because `--headless` *with* one
hangs forever. What was not legitimate is that nothing stopped a
**capture-bearing** segment being run that way: every capture step silently
no-opped, 9,231 planned frames were written as `file: null`, and every one of
those steps reported **PASS**.

That an operator may legitimately choose logic mode is precisely why the
combination needs a gate rather than a convention — and why
`--gatef-allow-no-capture` exists, so the choice stays available and stays
recorded. A capture that cannot be taken is a FAIL; a segment that can
take none of its captures is a BLOCKER. `file: null` is evidence of absence only
when the absence is unavoidable and singular.

`--gatef-allow-no-capture` acknowledges the failure explicitly and lets a
developer run a capture-bearing segment for its logic. It does **not** make the
segment complete: the inventory still marks every planned shot absent and
`complete: false`, and the acknowledgement is recorded as a BLOCKER-severity
note in the event stream.

### A frame that photographs an obstruction is not evidence

Every prescribed capture carries its own luminance statistics — mean, standard
deviation, and the fraction below luma 24 — on its manifest and inventory row.
That is most of the value on its own: the 2026-08-27 run produced 79 X07 frames
and the only way to find the bad ones was to open them one at a time. Three
numbers per row makes *"show me the frames with no contrast"* a sort.

A capture whose frame is both very dark **and** very flat is a photograph of an
obstruction rather than of the game, and it FAILs. The check is on the **image**,
not on a physics query, so it catches a camera inside geometry, a near field
filled by something opaque, a fade caught mid-frame and a black screen alike —
without needing to know which.

**Calibrated against X07's own 79 recovered frames, and the separation is not the
one you would guess.** Mean luminance does *not* work: the two darkest frames in
that set are legitimate night captures.

| frame | mean | stddev | frac < 24 | |
|---|---|---|---|---|
| `the_pond-night-gameplay` | 25.1 | 41.1 | 0.584 | legitimate |
| `the_rise-gameplay` | 26.6 | 29.0 | **0.755** | degenerate |
| `the_rise-arrival` | 26.6 | 29.0 | **0.755** | degenerate |
| `the_pond-night-arrival` | 26.8 | 43.0 | 0.584 | legitimate |
| *next darkest of the other 75* | 48.2 | 48.8 | 0.284 | |

A night scene is *darker in the mean* and still holds its contrast — sky, moon,
silhouette. An obstruction is flat. So the gate is dark fraction **AND** spread,
with `degenerate_dark_fraction` (0.65) and `degenerate_stddev` (35.0) sitting
between the two populations.

Both conditions are required, and a real capture shows why: this repo's own
title screen measures mean 50.8 / spread **32.4** / 5.4% dark. Its spread is
*below* the gate — it is a deliberately flat dark UI — and only the dark-fraction
half keeps it from being thrown away.

The dark fraction tops out near 0.755 rather than 1.0 because the HUD is in the
frame. These numbers are measured against that reality, not against a bare
viewport.

### Costing a segment before launching it

`wait` is priced in **rendered frames** in capture mode: `_step_wait` converts
seconds to physics frames, and under xvfb every physics frame is a rendered
1920×1080 frame. On llvmpipe at ~10.5 s per frame, one `{"seconds": 90}` step
costs about 15.75 hours. X07 stopped at step 184 of 266 with two such steps still
ahead of it — roughly 31 more hours (CD-7).

So the pre-flight measures what a frame actually costs here, prices the whole
step-script against it, and records both in `RUN_METADATA.json` as
`measured_frame_cost_s` and `predicted_segment_cost_s`. A segment predicted over
`segment_cost_ceiling_s` (default 4 h, in `harness_config.json`) is a **BLOCKER**
and does not start.

The fix for a segment over the ceiling is a GPU or a re-cadenced script — **not**
a shorter wait. The protocol's waits exist so fights resolve.

### `INVENTORY.json` — §M's closing check, as code

§M's last sentence — "the operator's final act is an inventory check that every
planned artifact exists or carries a recorded reason it does not" — was a
sentence addressed to a human, and the human it was addressed to reported a
complete run in which no prescribed screenshot existed anywhere in the branch
(CD-2). It is now computed on every close, blocked runs included:

```
{
  "segment": "...", "complete": false,
  "blocked": "", "derailed": "", "derailed_at": "",
  "preflight": { ... },
  "captures": { "planned": 8, "present": 8, "absent": 0,
                "rows": [ { "id", "step", "action", "class", "intended_proof",
                            "file", "exists", "bytes", "reason" } ] },
  "frames":   { "baseline_hz", "written", "absent", "absent_reasons" },
  "steps":    { "total", "ran", "pass", "fail", "skipped" },
  "harness_errors": [ ... ]
}
```

`exists` and `bytes` are read off disk, not copied from the manifest row: a
manifest naming a file that is not there is exactly the claim CD-2 found.
`complete` is a computed field, true only when nothing was blocked, nothing
derailed, every planned capture is on disk, no continuous frame was missed, and
every step ran. When it is false, `INCOMPLETE.md` says why in the filename.

**Exit code.** A failed *expectation* never fails the process (§1.6) — that is
the evidence Gate F collects. A missing *artefact* does: the harness exits
non-zero when a planned capture is not on disk, when a continuous frame was
planned and not written, or when the segment was blocked. Absence of evidence is
not evidence.

**The freeze record is cross-checked.** The candidate's `RUN_METADATA.json`
recorded `"display_server": "X11 under xvfb-run"` while every frame manifest in
the run said the opposite, 9,231 times over (CD-8b). The pre-flight now reads the
freeze record's claim, writes back what it actually observed, and BLOCKs when the
record promises a display server this process does not have. A metadata field
asserting a capability is not evidence that the capability existed.

**Will git carry it?** This is what CD-2 actually was, and it is the last
question the inventory asks. `shots/` was ignored *unanchored*, and a bare
directory pattern matches at **any depth**, so
`ralph/reports/gate-f-run-*/<segment>/shots/` was never tracked. The harness
wrote the PNGs — X07 took 79 real 1920×1080 frames — and git declined to carry
them, while `git add <dir>` skipped them **silently**, exit 0, no output. That
is how fourteen per-segment evidence commits looked clean while carrying no
frames.

The pattern is now `/shots/`, anchored to the repository root. And at close the
inventory runs `git check-ignore -v` over every capture on disk: one git will
not carry is an **uncommittable artefact** — named with its rule in
`INVENTORY.json`/`INCOMPLETE.md`, `complete` false, exit non-zero. A file that
exists and can never be committed is not evidence; it lives on a container that
gets reclaimed.

`git_check` records what git was able to say. A git that cannot answer — a run
directory outside a work tree, say — reads `unknown: …` and does **not** fail
the segment: an unanswerable check is not an uncommittable file.

### Event types — §C.1's enum, restated here because CI cannot see the protocol

`ralph/GATE_F_MASTER_PROTOCOL.md` §C.1 is the source of truth for this list. It
is restated here for one concrete reason: **`verify-unit-tests` sparse-checks
out `!/ralph/`**, so a test that parses the enum from the protocol reads an
empty file in CI and can enforce nothing. That is not hypothetical — it is how
`test_every_schema_event_type_is_emitted_by_something` went red on run 2579
while passing locally.

So `tests/test_gate_f_rig.gd` parses this table, which is always in the
checkout, and asserts every member is emitted by something in
`operator_harness.gd` (GF-B-011). A second test cross-checks this list against
§C.1 **whenever the protocol is readable** — locally, and in any full-checkout
job — so the two cannot drift apart silently. Where the protocol is absent that
test says so in its message rather than passing quietly.

Adding a type to §C.1 means adding it here and giving it an emitter. A type
nobody emits is an instrumentation defect (§C.5): its absence from a run proves
nothing, and Phase B may not read it as evidence.

| Event type |
|---|
| `objective` |
| `dialogue` |
| `combat_start` |
| `combat_hit` |
| `combat_switch` |
| `combat_end` |
| `catch_throw` |
| `catch_result` |
| `gather` |
| `craft` |
| `build_place` |
| `build_cancel` |
| `build_dismantle` |
| `rest` |
| `feed` |
| `menu_open` |
| `menu_close` |
| `tab_change` |
| `save` |
| `load` |
| `region_enter` |
| `landmark_discover` |
| `flag_set` |
| `level_up` |
| `faint` |
| `input_probe` |
| `screenshot` |
| `note` |
| `defect` |

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
