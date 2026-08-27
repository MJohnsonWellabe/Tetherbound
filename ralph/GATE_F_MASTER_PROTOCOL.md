# Gate F — Master Playtest Protocol (Phase A)

**Author:** Fable, Playtest Director. **Date:** 2026-08-25.
**Mandate:** `ralph/GATE_F_PROTOCOL.md` §2–§12. This document is the executable
protocol the Sonnet operator follows during the authoritative run. It is
written before execution so that evidence cannot be cherry-picked and so the
operator never has to improvise what to test.

**The bar is `docs/TETHERBOUND_GAME_VISION.md` plus current owner decisions,
not "better than the last build."** The authoritative question, from §18:
*if this were handed to a real player as a finished Meadows chapter, what would
make them confused, bored, frustrated, distrust the game, or stop playing —
and what evidence proves that assessment?*

**Role separation is absolute.** Fable designed this protocol and will analyze
its output blind (Phase B). Fable does not execute, capture, or fix. Sonnet
executes exactly this protocol, records honestly, and changes no code, data,
or config during the run (§13). Developer agents build the §I instrumentation
BEFORE the candidate SHA is frozen and then touch nothing until Phase B's
backlog exists.

---

## 0. The execution envelope, stated honestly

This Gate F pass is **agent-driven** (owner decision, 2026-08-25). The
operator is a Sonnet agent driving a scripted harness in a Linux container.
That changes what this protocol can honestly claim, and every claim below is
tagged with one of:

- **[ENV-OK]** — fully exercisable in this envelope with real evidence.
- **[ENV-PARTIAL]** — exercisable with a stated caveat; the caveat travels
  with the evidence into Phase B.
- **[OWNER-ONLY]** — cannot be honestly produced here. Recorded as a known
  coverage gap for the owner's own hardware pass (§K). **The operator must
  not fabricate these numbers or substitute a proxy without labeling it.**

Envelope facts every segment inherits:

1. **Input is synthetic.** All input enters through Godot's input system as
   `InputEventJoypadButton`/`InputEventJoypadMotion`/`InputEventKey`/
   `InputEventMouseButton` via `Input.parse_input_event`, plus
   `Input.action_press/release` where a poll-based reader needs it.
   **UI focus navigation MUST use `Input.parse_input_event` — action-press
   alone does not move focus** (`ralph/conventions.md`, pattern in
   `tests/smoke_menu.gd`). The standing rule for every menu/UI step in this
   protocol: **send both** — the parsed physical event first, the action
   press/release beside it — so both poll-readers and focus navigation see
   the input. A poll-only test reports a working menu while the stick moves
   nothing; that defect class is exactly what §8 hunts.
2. **Rendering runs under xvfb + opengl3 (software rasterizer), never
   `--headless` with a rendering driver** — that combination hangs forever
   (`ralph/conventions.md`). Logic-only segments may run `--headless` (no
   rendering driver). Canonical capture invocation:
   `xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path .
   --rendering-driver opengl3 --resolution 1920x1080 --script <harness>`.
   1920×1080 matches ROG Ally native; if the capture smoke
   (`tools/capture_diag_minimal.gd`) fails at that size, fall back to
   1280×800 and record the substitution in run metadata. Kill zombie Godot
   processes before and after every capture batch (conventions has the
   `pgrep` recipe).
3. **Continuous video is not practical.** The §H continuous-evidence plan
   substitutes timed frame sequences + dense JSONL correlation, and says so.
4. **No ROG Ally, no GPU measurement.** This box rasterizes in software;
   Compatibility renderer counts MultiMesh *batches*, not instances. Device
   frame rate, GPU frame time, VRAM, thermals: **[OWNER-ONLY]**, full stop.
   What IS measurable: CPU frame/physics time and directly-timed subsystem
   costs (`tools/perf_profile.gd`), draw calls/primitives under the render
   mode, placement/instance counts, boot/save/load/transition durations.
5. **The run uses the Linux editor binary, not the shipped Windows export.**
   Run metadata records this. `tools/verify_export.sh`/CI prove the Windows
   export builds; export-identity behavior on Windows is **[OWNER-ONLY]**.
6. **Production paths only.** `free_build` OFF, debug teleport unused, no
   granted items/levels/flags — except in segments explicitly prefixed
   `DIAG-`, which exist for audits that are not player-experience claims
   (§0.1). No pacing, navigation, difficulty, or economy claim may ever be
   sourced from a `DIAG-` segment.
7. **A segment that cannot produce its evidence must refuse to start.**
   Added 2026-08-27 from CD-1. The 2026-08-27 run against `f082bdf6` was
   launched without the fact-2 invocation above; every capture step silently
   no-opped, 9,231 planned frames were written as `file: null`, and every one
   of those steps reported **PASS**. The harness now runs a capture pre-flight
   before step 1 of any segment declaring a capture or a continuous record —
   display server, `capture_diag_minimal.gd` PNG, and its own framebuffer
   readback — and BLOCKs on any of the three. `tools/gate_f/run_segment.sh`
   refuses the same combination before Godot starts.
8. **`wait` is priced in RENDERED frames in capture mode.** Added 2026-08-27
   from CD-7. `_step_wait` converts seconds to physics frames, and under xvfb
   every physics frame is a rendered 1920×1080 frame; at llvmpipe's measured
   ~10.5 s/frame one `{"seconds": 90}` step costs ~15.75 hours. X07 stopped at
   step 184 of 266 with two of them still ahead. **A protocol written in
   seconds must be costed in frames before it is launched, or run on hardware
   with a GPU.** The pre-flight measures the frame cost on the box, prices the
   step-script, records both in `RUN_METADATA.json`, and refuses a segment
   over the configured ceiling. The fix for a refused segment is a GPU or a
   re-cadenced script — **not** a shorter wait; the waits exist so fights
   resolve.
9. **A candidate is a build *and* its configuration.** Added 2026-08-27 from
   CD-8. `data/config/grass_field.json` has `"enabled": false` on the
   2026-08-26 candidate, so the procedural ground cover is absent from every
   frame of that run — and no artefact anywhere says so. A reviewer judging
   ground cover from those frames was judging the baked scatter while
   believing they were judging the shipped ground system. **A flag that
   decides which subsystem renders the world is part of the freeze, and a
   reviewer must never have to infer it from source.**

### 0.1 Two lanes of segments

- **JOURNEY segments (S01–S10)** — one naturalistic fresh-save playthrough,
  in player order, production paths only, chained by save handoff. This is
  the run that pacing, economy, difficulty, navigation, objective-clarity
  and progression claims come from.
- **STUDY/DIAG segments (X01–X08)** — deep-coverage studies (input matrix,
  abuse, catch lab, combat lab, build lab, world audit, perf, save
  lifecycle). They branch from journey saves. Segments prefixed `DIAG-` in
  their step tables may use the Settings debug-teleport to reach sites,
  because they audit the world/instrument, not the player's route. Stress
  testing lives here so it never contaminates the journey telemetry.

### 0.2 Blind-first rule for the operator

Per §16.1: the operator is not told to look for any historical backlog item.
This protocol was designed from the vision and the systems as specified. The
operator records **what happens**, expected-vs-actual, and severity
candidates — not diagnoses, not fixes, not references to old bug IDs.

---

## A. Preconditions and freeze record

Before S01, the coordinator (not the operator) must:

1. Land the §I instrumentation and freeze a candidate `main` SHA.
2. Write `ralph/reports/gate-f-run-<stamp>/RUN_METADATA.json`:
   `candidate_sha`, `godot_version` (4.7), `binary` (linux editor, path,
   sha256), `renderer` (opengl3/compatibility under xvfb, software), `resolution`,
   `input_mode` ("synthetic joypad + keyboard via parse_input_event"),
   `save_state` ("fresh user:// dir"), `date`, `operator` ("sonnet-agent"),
   `free_build` (false), `instrumentation_overhead_note` (§I.7 measurement),
   and **`config_flags`** — the state of every gameplay- or render-affecting
   flag under `data/config/`, read from the files MECHANICALLY rather than
   hand-listed (CD-8; §1.2 calls these graphics settings, and a boolean that
   decides which of two ground systems dresses the whole world is one). Any
   flag that is OFF is called out in its own field so a reviewer sees it
   without diffing. The harness writes both into every segment's own
   `RUN_METADATA.json` as well, because a run cannot amend a freeze record it
   did not write.

   **A metadata field asserting a capability is not evidence that the
   capability existed** (CD-8b). This record claimed `"display_server": "X11
   under xvfb-run"` while all 9,231 frame-manifest rows in the same run said
   "headless: this process has no display server", and nothing reconciled them
   for the length of the run. The capture pre-flight now reads this record's
   claim, writes back what it observed, and BLOCKs on a contradiction.
3. Snapshot unresolved historical items for §16 reconciliation (coordinator
   bookkeeping; the operator never reads it).
4. Verify the capture smoke writes a PNG (`tools/capture_diag_minimal.gd`)
   and the full test suite is green at the SHA. A red suite is a blocker
   before the run, not a finding of the run.

**Blocker rule (§1):** if a segment cannot continue, the operator preserves
the failed evidence (telemetry, shots, save, log), reports a BLOCKER, and
stops that segment. The fix happens outside the run; a new SHA is frozen;
**only the affected segment restarts, from its entry save**. Pre-fix and
post-fix evidence are never combined: the run directory gains a
`RESTARTS.md` naming segment, old SHA, new SHA, and reason, and the
superseded segment directory is renamed `<segment>-superseded-<n>/`, never
deleted.

---

## B. Segment structure

Segments are resumable via save handoff: each journey segment ends by
saving to a dedicated slot through the **production Save tab** and copying
the resulting `user://` slot file into the run directory
(`saves/<segment>-exit.json`). The next segment boots fresh, restores that
file into `user://`, and loads it through the **production title-screen
Load path** (driven with synthetic input — this is itself save/load
coverage). Note: `scripts/save/save_game.gd` has 5 slots, slot 0 =
autosave; segment handoffs use slot 4 to avoid colliding with natural play
in slots 1–3.

| ID | Name | Span (entry → exit) | Entry save | Handoff |
|---|---|---|---|---|
| S01 | Boot & front door | process start → title verified, New Game chosen | none (fresh) | in-memory (no save yet exists pre-starter) |
| S02 | Opening | wake upstairs → starter caught & named → first wild catch → road gate open | continues S01 process | `S02-exit` |
| S03 | Village tutorial ladder | Tam's tools → team of 3 → training → gathering → home + 3 creature beds → sleep → feed | `S02-exit` | `S03-exit` |
| S04 | Tournament | sign-up → quarter → semi → final → win → South Bridge objective | `S03-exit` | `S04-exit` |
| S05 | Lower Meadows / Band 1 | leave village → pond → optional detour → South Bridge fight → cross | `S04-exit` | `S05-exit` |
| S06 | Stone & Root / Band 2 | bridge → Old Quarry → rootstone → Burrow Warrens → guardian → exit toward river | `S05-exit` | `S06-exit` |
| S07 | River & Relay / Band 3 | river arrival → relay pickets → officer → relay captain → captive → Old Mill Crossing restored | `S06-exit` | `S07-exit` |
| S08 | Upper Meadows / Band 4 | crossing → ironwood → saddle & riding → three captains → three Sigils | `S07-exit` | `S08-exit` |
| S09 | Stronghold approach / Band 5 | Sigil gate → outer watch → checkpoint → final camp decision → Hall threshold | `S08-exit` | `S09-exit` |
| S10 | Finale | Hall entry → gauntlet → recovery → elite → Warden → legendary → release ceremony → world healing → chain terminates | `S09-exit` | `S10-exit` (post-win) |
| X01 | Controller/menu exhaustion matrix (§8) | matrix over all contexts | `S03-exit` (all systems unlocked in village) + `S08-exit` (riding/late menus) | none |
| X02 | Build/craft/gather lab (§7) | 2×2 enclosed structure, dismantle, refunds | `S03-exit` | none |
| X03 | Catching lab (§6) | throw physics, edge cases, party-full | `S05-exit` (band 1 field) + `S08-exit` (party of 5) | none |
| X04 | Combat lab (§5) | loss, faint, switching, camera/arena stress | `S04-exit`, `S06-exit`, `S09-exit` | none |
| X05 | Save/session lifecycle | save/quit/load at multiple progression states, awkward saves | every `S0n-exit` | none |
| X06 | Abuse & failure sweep (§2) | mash, leakage, invalid actions, water, early routes | `S03-exit`, `S05-exit` | none |
| X07 | DIAG world & regional audit (§10) | every region, day/night/weather variants | any; teleport permitted | none |
| X08 | DIAG performance audit | perf sites, counts, durations | any; teleport permitted | none |

Why this shape: journey cuts fall on the chapter's own gates (tournament,
South Bridge, Warrens, Crossing, Sigils, Hall) so a blocker restarts at the
last gate rather than the whole chapter, and each cut point doubles as a
natural save/load coverage point. Studies branch from journey saves so
stress never pollutes the naturalistic record, and so each study starts
from a *real* player state rather than a granted one.

Execution order: S01→S10 first (the naturalistic run is the most fragile
evidence; take it before the world has been abused), then X01–X08 in any
order. `tools/gate_f_chapter_run.py`'s existing head/corridor/tail chaining
and `tools/_probe_gate_f_corridor.gd`'s cross-band dead-walk counter remain
valid instruments and are reused inside §D and X08 — they are inputs to,
not substitutes for, this protocol.

---

## C. Instrumentation schema (§3)

All telemetry goes to `ralph/reports/gate-f-run-<stamp>/telemetry/`.
Formats: JSONL for events, CSV for the fixed-rate route trace, Markdown for
operator notes, JSON for the screenshot manifest. Timestamps are seconds
from segment start (`t`) plus wall-clock ISO-8601 (`wall`). Every record
carries `run_id`, `sha`, `segment`.

### C.1 `events.jsonl` — one object per meaningful event

Field-by-field. Availability tags say what this envelope can honestly fill.

| Field | Type | Content | Avail |
|---|---|---|---|
| `run_id` | str | `gate-f-run-<stamp>` | ENV-OK |
| `sha` | str | candidate SHA | ENV-OK |
| `segment` | str | segment ID (S01…X08) | ENV-OK |
| `t` | float | seconds from segment start | ENV-OK |
| `wall` | str | ISO-8601 | ENV-OK |
| `type` | str | enum: `objective`, `dialogue`, `combat_start`, `combat_hit`, `combat_switch`, `combat_end`, `catch_throw`, `catch_result`, `gather`, `craft`, `build_place`, `build_cancel`, `build_dismantle`, `rest`, `feed`, `menu_open`, `menu_close`, `tab_change`, `save`, `load`, `region_enter`, `landmark_discover`, `flag_set`, `level_up`, `faint`, `input_probe`, `screenshot`, `note`, `defect` | ENV-OK |
| `objective` | obj | `{id, text}` of the currently tracked objective, read from the live quest log | ENV-OK |
| `region` | str | region id from `data/config/map_landmarks.json` containment, or `corridor` | ENV-OK |
| `pos` | [f,f,f] | player global x,y,z | ENV-OK |
| `heading` | float | player yaw, degrees | ENV-OK |
| `camera` | obj | `{yaw, pitch, distance, fov}` of the live gameplay camera | ENV-OK |
| `party` | list | per creature: `{species, name, level, xp, hp, max_hp, fed, rested, bond}` read from live party state | ENV-OK |
| `active_creature` | str/null | deployed/piloted creature name | ENV-OK |
| `player` | obj | `{hp, stamina, satiety}` from live vitals | ENV-OK |
| `inventory` | obj | on `gather`/`craft`/`build_*`/`save`: full slot snapshot `{item: count}`; otherwise the delta | ENV-OK |
| `equipped` | obj | `{hotbar_slot, item}` | ENV-OK |
| `input_context` | str | current modal/input owner as the game resolves it (§I.4 accessor over `input_owner.gd` + context) — the single most important field for §8 | ENV-OK |
| `input` | obj | `{device: "synthetic", raw: "JoyBtn:2", action: "interact", edge: "press"}` — the physical event injected and the action it resolved to. `device` is honest: no physical controller exists here | ENV-PARTIAL (synthetic, no analog feel) |
| `combat` | obj | `{opponent_id, opponent_species[], opponent_hp[], phase, my_hp, target_on_screen: bool}` | ENV-OK |
| `flags` | list | progression flags set/cleared this event | ENV-OK |
| `clock_hour` | float | in-game hour from the day cycle | ENV-OK |
| `light` | obj | `{sun_energy, ambient, preset}` from WorldLook | ENV-OK |
| `weather` | str | `clear/cloudy/fog/rain` | ENV-OK |
| `perf` | obj | `{frame_ms_avg, frame_ms_p95, frame_ms_max}` over the trailing window (CPU, this box); render mode adds `{draw_calls, primitives}` | ENV-PARTIAL (CPU shape only; device fps [OWNER-ONLY]) |
| `vram` | — | **not recorded — [OWNER-ONLY]**; field intentionally absent rather than fabricated | — |
| `distance_m` | float | cumulative meters walked this segment | ENV-OK |
| `since_interaction_s` | float | seconds since last meaningful interaction | ENV-OK |
| `dead_travel_m` | float | current encounter-free/interaction-free travel run (resets on any POI within 30 m or any interaction) | ENV-OK |
| `duration_ms` | float | on `save`/`load`/`region_enter`/boot: measured operation duration | ENV-OK |
| `artifacts` | list | screenshot/frame-seq IDs correlated to this event | ENV-OK |
| `expected` | str | what the protocol step said should happen | ENV-OK |
| `actual` | str | what happened (operator words, terse) | ENV-OK |
| `observation` | str | free operator note | ENV-OK |
| `severity_candidate` | str/null | `BLOCKER/SHIP/QUALITY/POLISH/null` — candidate only; Fable rules in Phase B | ENV-OK |
| `repro` | obj/null | `{attempted: n, reproduced: n}` when a bounded repro was performed | ENV-OK |

### C.2 `route.csv` — fixed-rate trace, 2 Hz, journey segments

`t, wall, x, y, z, heading, region, clock_hour, weather, frame_ms,
physics_ms, dead_travel_m, nearest_poi_dist_m, input_context`

This is the pacing study's raw material (§D) and the §12 correlation spine.

### C.3 `notes/<segment>.md` — operator notes

One dated block per protocol step:

```
### <step id> — <protocol step title>
- expected: <verbatim from this protocol>
- actual: <what happened>
- events: <t-range in events.jsonl>
- shots: <IDs>
- verdict: PASS / FAIL / PARTIAL / BLOCKED  (against the step's stated expectation only)
- observation: <anything a player would feel that the schema cannot carry>
```

The operator's verdict is per-step mechanical expectation only. Experience
judgments (fun, fair, boring, confusing) are recorded as *observations*,
never as verdicts — those are Fable's Phase B calls.

### C.4 `shots/manifest.json`

Per capture: `{id, class, segment, t, trigger, pos, camera_kind, clock_hour,
weather, hud, intended_proof, file}`. The §G plan defines every non-defect
entry BEFORE play; the operator adds only `DEF-` entries (defects at first
occurrence) and may not delete or re-stage planned ones. A planned shot
that cannot be taken is recorded in the manifest with `file: null` and a
reason — an absent frame is evidence too.

**Amended 2026-08-27 (CD-1).** "Evidence too" was never a licence to call a
missing picture a pass, and it was read as one: the harness returned "capture
… skipped", which does not begin with FAIL, so the step recorded PASS — 9,231
times, across a whole run. So:

> **A planned capture that cannot be taken is a FAIL. A segment that cannot
> take any of its planned captures is a BLOCKER at step 1.** `file: null` is
> evidence of absence only when the absence is **unavoidable and singular**;
> 9,231 of them is a run that did not happen.

The `file: null` row is still written — the rule above is about the VERDICT,
not about deleting the row.

### C.5 Instrumentation honesty

Telemetry reads **live game state** (real quest log, real party, real
vitals, real input owner), never a parallel reimplementation. If the
2 Hz trace or capture cadence measurably alters frame times, the harness
records that in `RUN_METADATA.json` (`instrumentation_overhead_note`)
rather than hiding it (§3 last clause).

**Added 2026-08-27 (CD-6).** *A schema field that no code writes is an
instrumentation defect, and Phase B may not treat its absence as evidence.*
Thirteen of §C.1's twenty-nine event types — `dialogue`, `combat_hit`,
`combat_switch`, `catch_throw`, `gather`, `craft`, `build_place`,
`build_cancel`, `build_dismantle`, `rest`, `feed`, `landmark_discover`,
`defect` — were in the schema and in nothing else, so their absence from the
2026-08-27 run proved nothing, and the inferences most available from that
evidence ("no gathering happened", "no orb was thrown") were unsupportable.
Every type in the §C.1 enum must now be emitted by something or explicitly
marked `not-instrumented`; `tests/test_gate_f_rig.gd` parses the enum out of
this document and fails the suite otherwise. Half a schema is worse than a
small one.

The same clause covers a field that is written but wrong.
`inventory_snapshot()` read each stack's `count` where `autoload/inventory.gd`
writes `n`, so every `inventory` field in the run carried the right item ids
with every quantity zero.

---

## D. Pacing, timing and distance study (§4)

Runs *inside* the journey segments — the numbers come from `route.csv` of
S02–S10, never from a DIAG segment and never from harness wall time (the
2026-08-23 evidence records exactly why harness wall time lies).

Named routes (coordinates from `data/config/map_landmarks.json` and band
trainer files; the operator navigates by in-game means per §F, these
anchors define where each measurement starts/stops):

| Route ID | From → To | Anchors (x,z) | Segment |
|---|---|---|---|
| RT-01 | Grandpa's house → village center | (-22,-16) → (10,-10) | S02 |
| RT-02 | Village traversal (Tam → Oskar → Mira → tournament ground) | (8,-16)→(22,-6)→(19,-1)→(20,12) | S03 |
| RT-03 | Village → pond | (10,-10) → (-342,507) | S05 |
| RT-04 | Tournament win → next objective start (South Bridge road) | (20,12) → leaving village southbound | S05 |
| RT-05 | Pond → South Bridge | (-342,507) → (0,1330) | S05 |
| RT-06 | Bridge → Old Quarry → Warrens mouth | (0,1330) → (403,1794) → (-420,2470) | S06 |
| RT-07 | Warrens interior (entry → guardian → exit) | interior | S06 |
| RT-08 | Warrens exit → river → Tether Relay | → (350,3760) | S07 |
| RT-09 | Relay → Old Mill Crossing → Upper Meadows entry | (350,3760) → (-152,4203) | S07/S08 |
| RT-10 | Upper Meadows circuit (ironwood grove → captains → sigil gate) | (-345,5060), (170,5590), (-100,4350), (-280,6460) | S08 |
| RT-11 | Stronghold approach (sigil gate → Hall threshold) | → (150,7595) | S09 |
| RT-12 | Stronghold/finale interior | Hall spaces | S10 |
| RT-13 | Backtrack: any mid-chapter return home (rest/craft decision if the journey takes one) + post-win S10 walk-back to the healed meadow | as played | as played |

Per route, from telemetry: **actual distance**, **elapsed time**,
meaningful interactions (count + type), wild/trainer encounters, resource
stops, landmark/visual pulls noted on screen, objective updates, wrong
turns (§F definition), **longest uninterrupted walk**, **longest
dead-travel interval** (with its start/end coordinates), and moments of
uncertainty (operator note: "did not know where to go for N seconds").

Thresholds for flagging (recording, not tuning): any dead-travel interval
≥ 250 m is a finding; 150–250 m is a watch item. Classification of each
interval as *intentional breathing room*, *exploration opportunity*, or
*dead time* is *Fable's Phase B call* — the operator supplies the interval,
its shots, and what was visible.

Chapter totals: cumulative journey play time vs the 3–4 h D42 target.
**[ENV-PARTIAL]**: an agent operator does not read dialogue at human speed
or hesitate like a first-timer; record raw time plus the model inputs
(`tools/_probe_pacing.py` beats, dialogue word counts) and let Phase B
state the projection with its multiplier visible. A human first-clear time
is an [OWNER-ONLY] confirmation.

---

## E. The studies

### E.1 Combat study (§5) — X04 plus in-journey records

Every journey fight already emits `combat_*` telemetry. The lab adds the
cases natural play avoids. Required coverage:

| CB ID | Case | Where / how | Evidence |
|---|---|---|---|
| CB-01 | Early wild combat | first ambush, S02 | telemetry + GF-14 shots |
| CB-02 | Early trainer | practice_trainer (13,9) L2–3, then Mira | telemetry |
| CB-03 | Tournament rounds | S04, quarter/semi/final | telemetry + GF-04 |
| CB-04 | Representative fight per band | S05: south_bridge_grunt (14,1314); S06: quarry_picket_dorn, warrens guardian; S07: relay ladder + relay_captain; S08: captain_field, captain_ridge, captain_riverwatch; S09: stronghold_outer_watch, checkpoint | telemetry |
| CB-05 | Warrens fight (enclosed geometry) | inside Burrow Warrens chambers | telemetry, camera fields |
| CB-06 | Stronghold fights | patrol → courtyard → elite → warden_aldis (90.2,7569.4) — **combat camera must be verified at battle start for every stronghold fight**: `target_on_screen` at t=0 and every switch | telemetry + GF-14 |
| CB-07 | Intentional loss | X04: take an under-leveled team into south_bridge_grunt; record the full defeat → consequence → recovery loop (satchel, respawn, party state) | telemetry + shots |
| CB-08 | Creature faint mid-fight | X04: let active faint; record faint feedback, forced switch, post-fight condition/bed pressure | telemetry |
| CB-09 | Switching under pressure | X04 + at least one journey fight: party_cycle (LB) mid-combat while taking hits; verify pilot handoff, camera handoff, no input loss | telemetry |
| CB-10 | Camera stress near geometry | X04: fight pressed against Warrens wall, stronghold interior wall, and a large tree/rock in band 1; record `target_on_screen` ratio and camera correction count | telemetry + shots |
| CB-11 | Arena-edge stress | X04: drive fight to arena boundary; verify containment (no phasing out), boundary readability | telemetry + shots |
| CB-12 | Size/range spread | fight smallest (pipwing/bramblebun class) and largest (meadowhart/tuskroot class) wilds; melee vs ranged movesets | telemetry |
| CB-13 | Lighting variants | at least one night fight (torch conditions) and one rain/fog fight, as natural play allows; else X07 pins and labels DIAG | shots |

Per fight record: duration, attacks/damage exchanges (hit events), switches,
camera corrections, `target_on_screen` dropouts, pathing stalls (opponent
stationary > 3 s while aggro), boundary violations, difficulty read
(HP margin at end), recovery consequence, XP/reward, and the operator's
observation on whether the fight read as fair/readable/purposeful
(observation, not verdict). **[ENV-PARTIAL]**: synthetic piloting cannot
feel responsiveness/latency; twitch-feel is [OWNER-ONLY].

### E.2 Catching study (§6) — X03 plus in-journey catches

Catch config: `data/config/catching.json` (throw speed 17, gravity 14,
max flight 4 s, cooldown 0.9 s; orbs basic/greater/prime; D31 explicit
percent). Required:

| CT ID | Case | How | Evidence |
|---|---|---|---|
| CT-01 | Tutorial/required catch | S02, production path | telemetry + GF-15 |
| CT-02 | Close throw (< 5 m) / long throw (near max range) | X03 band 1 field | `catch_throw` events with distance |
| CT-03 | Deliberate miss | aim wide; record miss feedback and orb loss | telemetry + shot |
| CT-04 | Aim cancel | enter aim (combat_aim context), cancel via `menu_cancel`; verify clean return to combat context, no orb spent | telemetry |
| CT-05 | Moving target / weakened target | throw at full-HP moving wild vs weakened one; record shown percent vs result | telemetry |
| CT-06 | Invalid states | throw at fainted wild; throw at a **trainer-owned creature (must be refused — hard rule)**; own deployed creature must not eat the orb (existing invariant) | telemetry + shot of refusal feedback |
| CT-07 | Body sizes | small (pipwing), medium (mudsnout), large (meadowhart), aggressive (tuskroot) | telemetry |
| CT-08 | Party-not-full → catch → count | verify party count increments, HUD **shows exactly five slots maximum — nothing may imply a sixth** | telemetry + GF-19 shot |
| CT-09 | Party-full catch attempt | X03 from S08-exit (5/5): record exactly what the game offers; catching while full is a designed decision point, verify the flow neither silently discards nor implies storage | telemetry + shots |
| CT-10 | Catch → party UI → cycling | open Creatures tab, cycle in world (LB), deploy new catch | telemetry |
| CT-11 | Save/load after catch | save slot 1, quit to title, load; party intact with nickname | telemetry |

Per throw record: aim time, throw count, distance, target species/size,
hit/miss and stated reason, shown percent, result, party count after,
feedback observed, camera behavior during aim/throw/resolve.

### E.3 Building, crafting and gathering study (§7) — X02 plus S03

**Authoritative economy rule (verified from current decisions, not
inferred):** building and crafting are **resource-bound**. `free_build` is
D16 temporary dev scaffolding, default OFF, and the Build tab banners when
it is on; OP21-10 separately established free build never implies free
craft. The authoritative run keeps `free_build` OFF everywhere; X02 step 12
toggles it on/off once purely to verify the banner and the setting, then
restores OFF and says so in telemetry.

S03 already builds the tutorial home + three creature beds under the real
economy (owner directive 2026-08-23: the village gatherable budget must
afford **three** beds before sign-up — the journey verifies that budget by
actually paying it). X02 is the deep lab, at a flat site near the village:

1. Gather under the current economy with **visible tool use**: craft axe
   (4 wood/3 stone/2 fiber) and pickaxe (3/4/2) if not carried over;
   record swing animation firing, pickup feedback, felled-resource behavior.
2. Build the required **2×2 enclosed structure**: 4 floors (4 stone each),
   perimeter walls (6 wood/2 stone each), **one doorway with a usable
   door** (5 wood), roof pieces (4 wood/3 stone each) to full cover.
   Exercise **repeat-place** (place multiple floors without re-opening the
   catalogue), **rotation** (build_rotate, both directions), **snapping**
   (build_snap_cycle; record snap failures), **cancel** (build_cancel with
   a ghost armed).
3. Enter and exit the structure through its door; close the door; verify
   interior camera behavior; shot GF-17 interior + exterior.
4. Place camp (12/8/10) and a creature_bed inside; rest a creature in it;
   record the bed's unavailability window.
5. Dismantle one wall and the camp (build_dismantle); **verify the refund
   arithmetic against `data/items/buildables.json` costs** in the
   inventory snapshot.
6. Exit Build and **immediately** resume normal play: move, jump, open
   Satchel, cycle party — recording `input_context` on every step (input
   leakage is the target).
7. Abuse (see §E.6 for the full list): rapid rotate/place/cancel; invalid
   placements (in water, intersecting a tree, on steep slope, overlapping
   the existing structure); placement while a creature stands in the
   footprint.

Record: construction time, failed placements + why, correction attempts,
snap failures, collision defects, final dimensions, camera obstruction
during placement, input leakage events, full resource ledger
(gathered/spent/refunded).

### E.4 Controller/menu exhaustion matrix (§8) — X01

**Amended 2026-08-27 (CD-4).** *A cell is coverage only if the probe happened
in the named context.* Each cell is `enter(context) → assert(context) → probe
→ restore`; a cell whose context assert fails is **`SKIPPED (context not
reached)`**, never PASS and never FAIL — those are different facts and the
2026-08-27 run conflated them. Report **in-context coverage as a headline
number beside the pass rate**: that run's matrix injected 303 of 418 cells
(72.5%) in a context other than the one the step named — eight surfaces were
all actually probed inside `menu_map` and twelve were never entered at all —
and its "1085 PASS / 118 FAIL" therefore describes mostly nothing. **A matrix
at 27% in-context coverage must not be reported as 87.9% behaving.** Its only
trustworthy content was the 115 in-context cells, which were 115/115 clean.
`input_probe` carries `intended_context` and `context_before` as first-class
fields so this is one query rather than a regex over `expected`.

**Goal: input ownership collisions.** The authoritative context map is
`data/config/input_contexts.json`; the physical map is `project.godot`
`[input]` (authoritative; D68: no held-button chords exist). The matrix
crosses every physical control with every context.

Physical controls (Godot joypad indices): A(0), B(1), X(2), Y(3),
View/Back(4), Menu/Start(6), L3(7), R3(8), LB(9), RB(10), D-pad
Up(11)/Down(12)/Left(13)/Right(14), MISC1(15, auto-run), LT(axis 4),
RT(axis 5), left stick (axes 0/1), right stick (axes 2/3); plus keyboard
WASD/E/I/M/B/L/F/Esc/Tab and mouse buttons/wheel for the KBM sweep.

Contexts/surfaces (each entered through its production path):
`world`, `combat`, `combat_aim`, `build_placement`, `build_catalogue`,
pause shell + each of the seven tabs (Satchel, Creatures, Map, Quests,
Build, Save, Settings), dialogue (`narrative_modal`), shop (Bram),
starter picker (S02 only — record there), naming grid (S02), craft panel,
storage panel, creature-bed panel, swap panel, tournament sign-up/bracket
UI, riding (mounted world, from S08-exit), title screen.

For **every (control, context) cell** the harness records:
`{focus_before, input_raw, resolved_action, world_side_effect,
ui_side_effect, focus_after, recoverable}`. A cell fails when one press
produces **two** owners' effects (e.g. a d-pad press that both moves menu
focus and fires a hotbar slot), when a world verb fires under a modal, or
when focus is lost/unrecoverable. Known-by-design shared buttons (LB =
party_cycle/menu_tab_left, RB = creature_recall/menu_tab_right, Start =
game_menu/backpack_drop, A = jump/confirm, B = hotbar_1/cancel, X =
interact/build_place, RT = quick/map_zoom_in…) are exactly where the
matrix looks hardest: the *context boundary frames* (open edge, close
edge) get a dedicated same-frame and next-frame probe each way.

For **every menu**: open through production path; visit every reachable
tab (RB full cycle forward, LB reverse); reach first AND last focusable
element (parse_input_event navigation — the poll trap is the defect class
this hunts); scroll the longest list to both ends (Settings' 126+ binding
cells is the stress case; the ScrollContainer must follow focus); change a
representative setting and change it back; confirm/cancel/back at each
depth; reopen; close; **verify immediate world control resumes** (move +
camera within 2 frames of close, mouse-capture state restored on KBM).

Tap vs press-vs-release distinctions: for `interact` (dialogue advance),
`combat_charged` (hold to charge), throw aim (hold/release), sprint (L3),
and every A/B edge at a modal boundary, probe tap (1 frame), short hold
(10 frames), and long hold (60 frames) separately; record which edge the
game acts on and whether a release leaks into the surface below.

**[ENV-PARTIAL]**: stick feel, deadzone quality, and rebinding on a
physical pad are [OWNER-ONLY]; the matrix proves routing/ownership, not
feel. The Settings rebind flow itself IS tested (capture a rebind, cancel
a capture, panic reset).

### E.5 Navigation, map and objective clarity (§9) — in-journey, every major objective

**No-developer-knowledge rule, adapted honestly to an agent operator.**
The operator inevitably *has* the coordinates (the harness scripts
movement). The rule is therefore procedural: at each major objective the
operator must first make and record a routing decision **using only
player-visible information** — the tracked objective line, the rendered
full map and minimap (screenshots taken and cited as the basis), visible
signposts, landmarks and roads in rendered frames — and write that
decision (`note` event: "objective says X; map shows Y; choosing route Z
because…") BEFORE consulting any authored coordinate. Only after a
recorded navigation failure ("could not determine where to go from
player-visible information") may the anchor coordinates be used to
continue, and that failure is itself the finding. Every navigation note
must cite the screenshot IDs it reasoned from. **This is weaker than a
genuinely blind human navigator and is flagged as such in §K** — but it
still detects the big failures: objectives that name nothing findable,
maps that show nothing, signage that points nowhere.

At each of the 24 main-chain objectives (`data/progression/objectives.json`:
`opening_first_catch` … `see_what_changed`), record: objective wording
(verbatim), does it say **what** and **where**; visible landmarks from the
player's position; minimap usefulness (what it actually shows there);
full-map usefulness (open Map tab, zoom in/out with LT/RT, verify pan/
centering behavior and **zoom persistence across close/reopen**);
time-to-route-decision; wrong turns (a committed heading > 50 m that had
to be reversed); time lost; signage encountered and whether it helped;
destination readability on arrival ("does the place announce itself").
Fog-of-war: record what a fresh save shows revealed (village + roads per
the 2026-08-22 ruling is the current design intent — record what IS
visible, as rendered, not what the config claims) and how reveal grows
along the journey. Exploration vs confusion is Fable's Phase B
distinction; the operator records the raw signals.

### E.6 Abuse and failure cases (§2) — X06 and embedded

All on production paths, each with expected/actual telemetry:

1. Mash all buttons during: title→world load, dialogue open/close edge,
   combat start/end edge, save/load, region transitions, tournament round
   transitions, the release ceremony.
2. Press world controls while each modal owns input (matrix cells above,
   plus the "mash" variant: 10 presses in 10 frames).
3. Open/close each menu 20× rapidly; verify no drift in pause state,
   mouse capture, focus, or time-of-day.
4. Build: rapid rotate/place/cancel loops; place-cancel-place same piece;
   dismantle the piece under an armed ghost.
5. Invalid placements: water, cliff, tree, NPC, inside own structure,
   mid-air edge of terrain.
6. Collision edges: walk the village building perimeters, bridge
   railings, quarry lips, Warrens walls, stronghold walls; jump against
   each; record any clip/soft-lock with position (GF-22 defect shots).
7. Push a fight to the arena boundary and hold there 10 s (CB-11).
8. Throw orbs badly: at ground, at sky, at max range, into water, during
   cooldown spam.
9. Invalid catches (CT-06).
10. Fully submerge in the pond and the river: verify submersion damage /
    hazard behavior and that vegetation/waterline reads correctly; try to
    swim across the river pre-crossing (locked-route probe).
11. Approach locked routes early: South Bridge before the key
    (`south_bridge_grunt` gate), Old Mill Crossing before the relay,
    sigil gate with 0–2 Sigils, Hall shutter before the elite. Expected:
    the world explains the lock diegetically; record what actually
    communicates it.
12. Attempt tournament interactions before requirements met (unrested/
    unfed/short team): the guided chain should point at the next missing
    prerequisite; record the exact line shown for each unmet state.
13. Save in awkward but legal states: mid-Warrens, on the bridge, at
    night while a creature is bedded, with satchel full, during
    aim-cancel frame; then load each (X05) and verify full restoration
    (position, party, flags, satiety, time of day, placed buildings,
    tracked objective).
14. Revisit completed areas: tournament ground after winning, relay after
    clearing, Warrens after the guardian; record what re-offers, what is
    correctly spent, what dialogue acknowledges progress.
15. Backtrack across story transitions: walk back over the South Bridge
    after crossing; return home mid-chapter; verify Grandpa's dialogue
    state advances with the chapter (home-relevance check).
16. Play naturally through day→night→day at least twice in the journey
    (day is ~600 s): record the transition's continuity (no snap), night
    legibility with and without torch (GF-20), and dawn recovery.

### E.7 World and regional audit (§10) — X07 (DIAG) plus journey arrivals

Journey segments capture every **arrival** shot naturally (§G classes
2–13). X07 then revisits each region under DIAG teleport for the audit
grid — allowed because this audits the world, not the route:

Regions (from `map_landmarks.json`): Grandpa's Village, The Rise, The
Pond, The Old Quarry, The Burrow Warrens, The Tether Relay, The Long
Water, The Ironwood Grove, The Ridgeline Watch, plus the Stronghold
approach and Hall.

Per region: arrival view (from the intended entry route direction),
normal-gameplay frame (HUD on), signature landmark, terrain/ground close
view, ecology/activity frame (wilds visible behaving), and any obvious
defect. Day/night/weather variants where materially relevant (village,
pond, stronghold approach at minimum; pin-and-freeze the WorldLook clock
using the `capture_band3_region.gd` pattern — never the unpinned variant
that produced the 2026-08-23 crimson artefact — and record every pin in
telemetry as DIAG).

Recorded per region (telemetry + notes): vegetation density impression
with a paired frame, creature/trainer/resource cadence within the region
(counts from live queries), empty areas (position + frame), invalid prop
placement, water intrusion, collision anomalies, repetition, sightlines
to the next landmark, path/road legibility, environmental storytelling
present or absent, regional identity ("could a player name where they are
from this frame alone" — operator observation), and vision fit (Fable's
Phase B judgment; the operator supplies frames, including unflattering
ones — **do not take only flattering screenshots**; the shot plan's fixed
positions exist precisely so the frame is the frame).

### E.8 Save/session lifecycle — X05

From every journey exit save: save via tab (all 3 player slots exercised
across the run), quit to title, load, verify restoration (checklist in
E.6.13); measure `duration_ms` for each save and load; boot-to-title and
title-to-world durations; autosave (slot 0) observed firing and loading;
load-the-wrong-older-slot check (loading S03-exit after playing to S06
must restore the older state cleanly, not merge). Title-screen New Game
over an existing save must not destroy slots without confirmation.

### E.9 Performance audit — X08 (DIAG), what is honestly measurable

- `tools/perf_profile.gd` at its six sites (village, band1, band2, band3,
  band4, stronghold) in both modes: `--headless` for CPU frame/physics
  and directly-timed subsystem costs; `--mode=render` under xvfb for draw
  calls/primitives. JSON output archived per site.
- Placement/instance counts vs the 260,000 budget
  (`test_scatter_perf_budget.gd` context).
- Boot, save, load, and region-transition durations from X05/journey
  telemetry; worst frame-time spikes correlated to position and event
  from `route.csv` across the whole journey.
- **Explicitly recorded as [OWNER-ONLY], unverified: handheld frame
  rate, GPU frame time, VRAM, battery/thermal.** The report states the
  CPU-shape numbers and the structural counts and stops there. No test in
  this protocol may output a "device FPS" number, because no honest one
  can exist here.

---

## F. Definitions the operator applies mechanically

- **Meaningful interaction:** dialogue, combat, catch, gather, craft,
  build, rest, feed, objective change, landmark discovery, item pickup,
  shop/trade.
- **POI (for dead-travel):** any wild creature, trainer, harvest node,
  TM, key item, or interactable within 30 m of the player's path.
- **Dead-travel interval:** continuous meters with no POI within 30 m and
  no meaningful interaction. Reset on either.
- **Wrong turn:** a committed heading (> 50 m) abandoned and reversed.
- **Camera correction:** any scripted camera input needed solely to
  restore the target/route to view.
- **Pathing stall:** an AI combatant stationary > 3 s while in combat.
- **Input leakage:** an input consumed by a surface producing an effect
  in a second surface, either same-frame or on the release edge.
- **Reached** (added 2026-08-27, CD-5): within interaction range of the
  **entity**, with its prompt live. **Not** within a radius of a literal
  coordinate. `move_to` compared x and z only: Grandpa's bed is 0.89 m from
  him in plan view and **3.3 m above him**, so `S02-15` "arrived" and pressed
  `interact` 31 times through the floor, and the same shape recurs as 65
  `did not reach (x,z)` failures. A journey step written as "go to the
  trainer" is transcribed with `move_to_entity` and `interact_with`, which
  resolve a thing and assert its prompt, not with a pair of numbers.

---

## G. Prescribed screenshot plan (§11)

**Amended 2026-08-27 (CD-1, CD-2).** Two rules sit above everything in this
section, because the 2026-08-27 run satisfied the whole of it on paper and
produced no prescribed screenshot anywhere:

> 1. A planned capture that **cannot** be taken is a **FAIL**, and a segment
>    that can take none of them is a **BLOCKER at step 1**.
> 2. A capture is **"completed" only when its file exists on disk** (§11).
>    X07's own `WHY_INCOMPLETE.md` reported "captures completed: 79" for
>    artefacts that do not exist — and 23 of those 79 timestamps have no
>    background frame within 3 s of them either (worst gap 257 s), including
>    the §E.7-required HUD-on `-gameplay` frame for **all 11 regions**.

Both are enforced by the harness rather than promised by the operator: see
§M's inventory.

Defined before play. IDs are `GF-<class>-<seq>`; every capture logs a
`screenshot` event carrying its telemetry timestamp. **HUD rule default:
HUD ON** — these frames prove real play. `hud:off` is permitted only
where marked (composition audit frames), and each hud:off frame requires
a paired hud:on context frame within 30 s. Camera is the live gameplay
camera unless marked `probe` (X07 DIAG only). Time/weather: `natural`
means whatever the journey produced (recorded); `pinned` (X07 only) means
pin-and-freeze with the pin logged. Defect shots (`GF-22/DEF-…`) are the
only operator-added captures: context frame first, then a diagnostic
close view if useful, at first occurrence, as-found.

| ID | Class (§11) | Trigger | Location / camera | Time/weather | Intended proof | HUD |
|---|---|---|---|---|---|---|
| GF-01-TITLE-01 | 1 | title screen fully loaded, S01 | title cam | n/a | front door is a real game's front door; save slots legible | as shipped |
| GF-01-TITLE-02 | 1 | Load list populated (X05 revisit) | title cam | n/a | load path exists and is legible | as shipped |
| GF-02-START-01 | 2 | wake beat, before leaving bed area | bedroom, gameplay cam | opening default | opening stages correctly (incl. player body presence as-shipped) | on |
| GF-02-START-02 | 2 | Grandpa conversation mid-dialogue | farmhouse | natural | mandatory opening reads; dialogue UI | on |
| GF-02-START-03 | 2 | starter picker open, an orb focused | farmhouse | natural | starter choice presentation | on |
| GF-03-VILLAGE-01 | 3 | first arrival at village center (10,-10) | wide, gameplay cam facing village spine | natural | village reads as a settled place from the entry route | on |
| GF-03-VILLAGE-02 | 3 | street-level walk mid-S03 | between Tam/Oskar/Mira | natural | street scale, NPC presence | on |
| GF-04-TOURN-01 | 4 | sign-up dialogue with marshal | tournament ground (20,12) | natural | sign-up flow | on |
| GF-04-TOURN-02 | 4 | mid-final-round combat | tournament arena | natural | tournament fight staging | on |
| GF-04-TOURN-03 | 4 | victory/bracket resolution moment | arena | natural | payoff presentation | on |
| GF-05-MEADOW-01 | 5 | first open-meadow stretch south of village | broad sightline frame on RT-04/05 | natural | open land is authored, not empty; distant pulls visible | on |
| GF-05-MEADOW-02 | 5 | same class, band 4 high pasture | RT-10 | natural | upper meadow identity differs from lower | on |
| GF-06-POND-01 | 6 | pond first visible on approach | RT-03 approach vector | natural | approach reads; lush pocket vs open contrast | on |
| GF-06-POND-02 | 6 | pond shore, water edge in frame | (-342,507) shore | natural | water/edge/vegetation quality | on |
| GF-07-BRIDGE-01 | 7 | South Bridge first visible | RT-05 northbound view | natural | gate landmark visible before reached | on |
| GF-07-BRIDGE-02 | 7 | on the bridge after it opens | (0,1330) | natural | crossing payoff | on |
| GF-08-QUARRY-01 | 8 | quarry arrival | (403,1794) entry | natural | quarry identity; rootstone visibly present | on |
| GF-09-WARRENS-01 | 9 | Warrens mouth | (-420,2470) | natural | dungeon entrance announces itself | on |
| GF-09-WARRENS-02 | 9 | interior chamber mid-clear | interior | natural | interior readability, lighting | on |
| GF-09-WARRENS-03 | 9 | guardian encounter | guardian chamber | natural | memorable-encounter staging | on |
| GF-10-RELAY-01 | 10 | river first visible | RT-08 | natural | the river reads as a regional barrier | on |
| GF-10-RELAY-02 | 10 | relay compound approach, pylons in frame | (350,3760) approach | natural | Team Tether occupation escalation | on |
| GF-10-RELAY-03 | 10 | captive rescue / crossing restored moment | relay & (-152,4203) | natural | world visibly changes | on |
| GF-11-UPPER-01 | 11 | Upper Meadows entry across the crossing | RT-09 end | natural | region shift is felt | on |
| GF-11-UPPER-02 | 11 | riding on Meadowhart | RT-10 | natural | riding payoff exists and stages correctly | on |
| GF-12-APPR-01 | 12 | sigil gate opening | gate site | natural | 3-Sigil payoff | on |
| GF-12-APPR-02 | 12 | Hall dominant on horizon, drained land in frame | RT-11 mid | natural | escalating dread; occupied/drained grammar | on |
| GF-13-FINALE-01 | 13 | Hall interior gauntlet space | Outer Works/Courtyard | natural | occupation/industrialization read | on |
| GF-13-FINALE-02 | 13 | Warden pre-fight dialogue | Warden Arena | natural | climax staging | on |
| GF-13-FINALE-03 | 13 | legendary chamber / tether machine | Legendary Chamber | natural | reveal lands visually | on |
| GF-13-FINALE-04 | 13 | release ceremony decision screen | team screen | natural | the chapter's core choice presented with ceremony | on |
| GF-13-FINALE-05 | 13 | healed meadow post-win | S10 walk-back | natural | visible world healing | on |
| GF-14-COMBAT-01…n | 14 | one per CB-01…CB-13 case | as scheduled | natural | per-case | on |
| GF-15-CATCH-01…n | 15 | aim reticle frame + resolve frame per CT class | as scheduled | natural | throw/feedback quality | on |
| GF-16-GATHER-01 | 16 | axe mid-swing on a tree | X02 site | natural | visible tool use | on |
| GF-16-GATHER-02 | 16 | pickaxe on rootstone deposit | quarry | natural | tier material gathering | on |
| GF-17-BUILD-01 | 17 | 2×2 exterior complete | X02 site | natural | structure coheres (planes/junctions visible) | on |
| GF-17-BUILD-02 | 17 | interior with door, camp, creature bed | inside | natural | interior usable; bed occupied | on |
| GF-17-BUILD-03 | 17 | armed ghost + placement UI | during build | natural | placement affordances | on |
| GF-18-MAP-01 | 18 | Map tab at S03 (fresh-ish save) | menu | n/a | what a new player's map actually shows | on |
| GF-18-MAP-02 | 18 | Map tab at S08 (late chapter), both zoom extremes | menu | n/a | reveal growth, zoom behavior | on |
| GF-18-MAP-03 | 18 | minimap in world at a route decision point | HUD crop context | natural | minimap usefulness at the moment it matters | on |
| GF-19-UI-01…07 | 19 | each pause tab, first-open state | menu | n/a | each tab is game UI, not debug tooling | on |
| GF-19-UI-08 | 19 | HUD in ordinary exploration | world | natural | HUD footprint/legibility at 1080p | on |
| GF-19-UI-09 | 19 | party strip at 5/5 | world | natural | exactly five slots, no sixth implied | on |
| GF-19-UI-10 | 19 | first level-up moment, announcement on screen | wherever the journey levels first (S03) | natural | the level-up actually announces itself to the player | on |
| GF-20-NIGHT-01 | 20 | first natural nightfall, no torch | wherever the journey is | natural | night legibility floor | on |
| GF-20-NIGHT-02 | 20 | same position, torch drawn | same | natural | torch value and hold pose as-shipped | on |
| GF-21-WEATHER-01…n | 21 | each weather preset first naturally encountered (clear/cloudy/fog/rain) | as-played | natural | weather identity; palette holds | on |
| GF-22-DEF-<nnn>a/b | 22 | every defect at first occurrence | as found | as found | context frame (a) then diagnostic close (b) | on |
| GF-AUD-<region>-… | audit | X07 grid per E.7 (6 frames/region + variants) | fixed positions per region, probe cam allowed | pinned, logged | regional audit | off allowed with paired on |

Fable does not produce, stage, select or edit any of these images. A
planned frame that cannot be captured is a manifest entry with a reason.

**Coordinator amendment, 2026-08-25 (pre-freeze, recorded not silent).**
`GF-19-UI-10` was added to this table by the Gate F coordinator before the
candidate freeze. It is not new coverage: §L.4 already requires "first level-up
moment captured; announcement verified visible ... shot + event" in S03, but
§G defined no row for it, and §C.4 forbids the operator inventing a planned
shot id. Without the row the requirement was unsatisfiable by anyone — the
operator may not create it and the transcriber may not either. The row states
§L.4's own words and adds nothing beyond them.

This is the only amendment made to Fable's Phase A protocol by the coordinator.
It resolves an internal inconsistency; it does not change what is tested, and
it was made before any evidence was gathered.

**Coordinator amendment 2, 2026-08-25 (pre-freeze, recorded not silent).**
Four ids were each claimed by a capture step in **both** the journey and the
study lane, because §E's own wording assigns them to both:

| id | why both lanes took it |
|---|---|
| `GF-14-COMBAT-09` | CB-09 is "X04 **plus** at least one journey fight" |
| `GF-14-COMBAT-12` | CB-12 is "smallest **and** largest" |
| `GF-14-COMBAT-13` | CB-13 is "as natural play allows; **else** X07 pins and labels DIAG" |
| `GF-19-UI-08` | class 19's world HUD frame, reachable from either lane |

In the first three the two frames are genuinely different evidence and both are
wanted; the collision is only in the naming. Manifests are per-segment so no
file collides, but two rows carrying one id in a single run directory is how a
reader cites the wrong frame — the same hazard §G's own cadence rule guards
against.

Resolved by the `GF-14-COMBAT-04a…04e` precedent already in this table:
**journey takes `a`, study takes `b`, and the bare id stays what §G planned so
neither lane claims it.** No frame was added or dropped; only the labels changed.
Renaming one side alone would have been worse than the collision, which is why
the transcribers correctly refused to do it unilaterally and referred it up.

Together with amendment 1 these are the only coordinator edits to Fable's
Phase A artefacts, alongside the `record_hz` keys set in eight segment files per
§H's mandatory list. All are recorded in-file with their reasoning. None adds or
removes coverage. Whether they were the coordinator's to make is for the
reconciliation to judge, not for this document to assert.

---

## H. Continuous evidence plan (§12)

Full-run video is not practical in this envelope. The mandated substitute,
per §12's "equivalent evidence" clause — declared here, not improvised:

- **Frame-sequence recording**: PNG every 2 s (0.5 Hz) plus a forced frame
  on every JSONL event, filed `frames/<segment>/<t>.png`, correlated by
  the `timestamp → player state → input → event → frame` chain through
  `events.jsonl` + `route.csv`.
- Mandatory for the highest-risk segments: **S01+S02 (opening), S04
  (tournament), X02 (build), X01 (controller/menu stress), CB-06 +
  CB-07 + Warden (representative combat), every band handoff ±60 s
  (region transitions), X05 (save/load), S10 (finale)**.
- Journey segments outside that list run at 0.1 Hz (one frame per 10 s)
  plus event-forced frames, to keep the record continuous without
  drowning the run directory.
- If frame capture measurably distorts frame timing, the overhead note
  records it and the perf audit (X08) runs without capture.

---

## I. Instrumentation build list (pre-freeze; §1.5)

Implemented by a developer agent BEFORE the candidate SHA freeze; the
operator changes nothing during the run. Full implementable spec:
`ralph/GATE_F_INSTRUMENTATION_REQUEST.md`. Summary:

1. **Operator harness** `tools/gate_f/operator_harness.gd` — boots the real
   main scene, executes a segment step-script, injects input via
   `Input.parse_input_event` (+ paired action press/release), captures
   screenshots/frame sequences, writes `events.jsonl` and `route.csv`.
2. **Live-state telemetry accessors** (read-only) for: tracked objective
   {id,text} from the real quest log; party/vitals/inventory/equipped;
   current input context/modal owner (the game's own resolution, via
   `input_owner.gd` + context state); combat opponent state;
   clock/weather/light; camera pose. No parallel logic — read what the
   game reads.
3. **Save handoff support**: harness-side only (copy `user://` slot files
   in/out; drive title-screen Load with synthetic input). Verify no game
   code change is needed; if one is, it lands pre-freeze.
4. **Duration timers**: boot→title, title→world, save, load, region
   transition, measured in-harness.
5. **Input-cell probe** for X01: a harness routine that, per (control,
   context) cell, snapshots focus/context before, injects, snapshots
   world+UI effects after, emits one `input_probe` event.
6. **Segment step-scripts** encoding S01–S10/X01–X08 from this protocol.
7. **Overhead self-measurement**: harness measures its own frame-time
   footprint (telemetry+capture on vs off over the same 60 s idle) and
   writes the note §3 requires.
8. **Zombie/invocation guards**: capture smoke gate + pgrep cleanup wired
   into the runner (`tools/gate_f/run_segment.sh`).

Constraint: instrumentation must be **non-invasive** — no gameplay code
paths altered; accessors are additive; telemetry activates only under a
CLI flag (`--gatef-telemetry=<dir>`), so the shipped game is untouched.

---

## J. Operator rules (§13 restated for this envelope)

Follow the protocol; production paths; `free_build` OFF; teleport only in
DIAG segments; record defects before any diagnostic rerun; change no
code/data/config; never skip a failed step silently — a failed step gets
its FAIL verdict, its evidence, and the run continues if continuation is
possible; **never substitute a unit-test result for failed player-path
evidence**; capture first occurrence; bounded reproduction only where a
step directs (repro budget: 3 attempts unless the step says otherwise);
preserve saves/logs/images associated with failures; report inability to
continue as a BLOCKER (§A) rather than improvising around it. The
operator does not diagnose root causes, does not consult historical
backlog/DONE, and does not read this repo's defect history mid-run.

**Added 2026-08-27 (CD-3).** *No step may encode a guessed repetition count
for a state-changing UI. Reach a state, then assert it.* Dialogue advance was
scripted as a fixed press count, which is wrong in both directions: under-press
and the modal sits open for the next step to press a world control at;
over-press and the extra `interact` reaches the interaction arbiter and
re-opens the conversation the previous press closed (the operator recorded it
at `S02-28`: *"every tap past the third can re-open the conversation the
previous tap just closed"*). The downstream cost was total — `X01-463` held
**3,601 frames** in `narrative_modal` 15.8 m short of Bram, and every X01
surface after it (Settings, rebind, panic reset, shop, tournament, craft,
storage, swap, bed, combat_aim, riding) was probed inside that dialogue.
`advance_dialogue_until_closed` replaces the count with a predicate over the
panel's own line, and **after any dialogue step `input_context` must not be
`narrative_modal`**.

**And its general form.** A step must verify the input context it expects
actually owns input **before** acting, and fail loudly when it does not. A
failed `require_context` records one FAIL at the step that could not drive the
game; every step after it is `SKIP`ped with the derail named, until one
resynchronises. §1.6's "the run continues" is a rule about verdicts on the
GAME; a step that could not be PERFORMED invalidates the ones after it, and
forty assertions taken in the wrong context are forty findings about the
harness.

---

## K. Known coverage gaps — owner's own pass required

Named honestly so §16.4's coverage-defect loop can work. Nothing below is
claimed by this run; each is pre-registered as **[OWNER-ONLY]** in the
final report:

1. **Handheld frame rate / GPU cost / VRAM / thermal / battery** on ROG
   Ally. This run supplies CPU shape, structural counts, and durations
   only (X08).
2. **Real controller feel**: analog deadzone/curve quality, latency,
   rumble, grip ergonomics, tap-vs-hold *feel* (routing is covered;
   feel is not).
3. **Handheld legibility at 7"**: 1080p frames are captured and HUD
   metrics exist (`smoke_hud_handheld_legibility.gd` class), but
   readability at arm's length on the physical panel is owner judgment.
4. **First-time-human navigation and pacing**: the E.5 procedure is a
   disciplined approximation, not a blind human; the D study's
   first-clear projection carries a modelled multiplier. A real first
   clear timing/confusion log is owner evidence.
5. **"Would a player voluntarily keep playing"** — Fable will judge
   engagement signals from evidence in Phase B, but the sole authentic
   source is the owner playing voluntarily.
6. **Audio** (cues, mix, silence where music should be): no audio path
   exists in this envelope at all; `test_audio_cues.gd` covers wiring
   only. Any audio judgment is owner-only.
7. **Windows export identity**: this run uses the Linux editor binary;
   export-specific behavior (file paths, controller hotplug, window
   focus, save location) is owner/CI territory.
8. **Continuous video**: substituted per §H; true video capture of feel
   (camera smoothness, animation blending under motion) is owner-side.
9. **Long-session soak** (2+ hour single process, memory growth on
   device): partially proxied by the journey's process lifetimes;
   device soak is owner-only.
10. **Mouse-look feel** on PC: synthetic mouse events verify routing and
    capture/restore, not hand feel.

Anything Phase B's reconciliation classifies as `MISSED BY GATE F` that
traces to one of these ten is a *declared* gap (protocol limitation), to
be closed by the owner pass or new instrumentation — distinct from an
undeclared protocol hole, which is a §16.4 coverage defect proper.

---

## L. Coverage matrix (§2)

Every meaningful player-facing requirement → test action → evidence.
"Evidence" means JSONL events + the named shots; each row also names its
owning segment. Rows marked ✻ are additionally exercised in the abuse
sweep (E.6) or matrix (E.4).

### L.1 Controls and verbs

| Requirement | Test action | Segment | Evidence |
|---|---|---|---|
| Every controller button, meaningful combos ✻ | E.4 full matrix, every context | X01 | `input_probe` events, matrix table |
| Tap / press / release distinctions ✻ | E.4 edge probes (1/10/60 frames) on interact, charged, throw, sprint, A/B at modal edges | X01 | `input_probe` |
| Movement, sprint, jump, auto-run | journey traversal; auto-run engaged on a long RT leg, disengaged by stick | S05 | route.csv, events |
| Camera control + recenter (R3) | journey; recenter during walk, combat, riding | S05/X04/S08 | camera fields |
| Every exploration action | interact, gather, torch draw/holster/redraw, torch place, party cycle (LB), recall (RB), tool use | S03/S05 | events + GF-16/GF-20 |
| Every hotbar action (B, d-pad ×4) | assign tools/food/orbs via Satchel; fire each slot in world and in combat (d-pad = consumables in combat by design) | S03/X01/X04 | events |
| Mouse/KBM parity | X01 KBM sweep: WASD/E/I/M/B/L/F/Esc, mouse look capture/release across menu open/close | X01 | `input_probe` |

### L.2 Menus and UI

| Requirement | Test action | Segment | Evidence |
|---|---|---|---|
| Every menu/submenu/tab; every open/close path ✻ | E.4 per-menu sweep incl. shell shortcuts (Y satchel, View map direct) | X01 | `menu_*` events, GF-19 |
| Scroll/focus/confirm/cancel/settings adjustment | E.4: Settings 126-cell walk, rebind + cancel + panic reset, longest-list both ends | X01 | `input_probe` |
| Map/minimap zoom, pan, centering, navigation | E.5 at every major objective; GF-18 pair; zoom persistence across reopen | journey | events + GF-18 |
| Satchel/inventory (drop, split, move/assign, use) | S03 assignments; X01 Satchel cells; drop-confirm cancel path | S03/X01 | events |
| Party/creature UI + cycling | CT-10; Creatures tab reorder; world cycling LB/RB | S02+/X01 | events |
| HUD: five slots max, no sixth implied | GF-19-09 at 5/5 party | S08 | shot |
| Quest log / guided ladder surfacing current step | E.5 at each rung; verify only the current step surfaces per OP-directive design | S02–S04 | events + shots |

### L.3 Build / craft / gather

| Requirement | Test action | Segment | Evidence |
|---|---|---|---|
| Build open/navigate/repeat-place/rotate/snap/cancel/dismantle ✻ | E.3 lab steps 2, 5, 7 | X02 | events + GF-17 |
| 2×2 enclosed structure, door usable, roof, enter/exit | E.3 steps 2–3 | X02 | GF-17-01/02 |
| Crafting (workbench, tools, orbs, potions, tier recipes) | S03 basics; S06 orb_greater + reinforced tools; S08 saddle + orb_prime — each paid at real cost | journey | inventory snapshots |
| Gathering with visible tool use | E.3 step 1; journey wood/stone/fiber/berries; rootstone (pickaxe), ironwood | journey/X02 | GF-16 |
| Refund/resource verification on dismantle | E.3 step 5 arithmetic vs buildables.json | X02 | inventory delta |
| Free-vs-resource rule verified not inferred | E.3 preamble: free_build OFF for run; one labeled toggle check of banner | X02 | events |

### L.4 Creatures: care, rest, catching, combat

| Requirement | Test action | Segment | Evidence |
|---|---|---|---|
| Creature care/rest; bed occupancy/unavailability/overnight recovery | S03 three beds + sleep; E.3 step 4; CB-08 aftermath | S03/X02/X04 | events |
| Player rest / sleep → next day | S03 sleep rung; rest→day-advance verified in flags + clock | S03 | events |
| Feeding / satiety (light, no starvation death) | S03 feed rung; observe drain over journey; low-satiety soft drawback recorded, death never | journey | vitals fields |
| Catch success/miss/cancel/failure states ✻ | E.2 CT-01…07 | S02/X03 | events + GF-15 |
| Party-full behavior | CT-09 | X03 | events |
| Trainer creatures uncatchable (hard rule) | CT-06 | X03 | refusal shot |
| Required trainer fights + representative optional | CB-02/03/04; optional: old_champion_bram (195,905), patrol_ridgeline | journey | combat events |
| Intentional loss + faint | CB-07/08 | X04 | events |
| Switching, camera, arena boundaries ✻ | CB-09/10/11 | X04 | events + shots |
| Level-up communication | first level-up moment captured; announcement verified visible | S03 | shot + event |
| Bond/traits visible and explained | Creatures tab: trait text presence; bond movement over journey | X01/journey | shots, party fields |
| Evolution (Mudsnout→Tuskroot) | if the journey's catches allow, pursue level+bond+item condition; else record as NOT NATURALLY ENCOUNTERED with the state achieved — do not grant it | S06–S08 | events |
| Riding (saddle, mount, dismount, speed, no stamina cost) | S08: craft saddle, mount Meadowhart, ride RT-10 leg, dismount, remount; menus while mounted in X01 | S08 | events + GF-11-02 |
| Release ceremony under full belt | S10: legendary join with 5/5 → ceremony; verify three-beat ceremony, history shown, choice is real and permanent | S10 | GF-13-04 |

### L.5 World, story, progression

| Requirement | Test action | Segment | Evidence |
|---|---|---|---|
| Torch / day/night / weather | E.6.16; GF-20/21; torch redraw after holster | journey | events + shots |
| Tournament qualification, bracket, win, representative failure ✻ | S04 full; E.6.12 unready states; X04 optional: lose a round and record the offered path | S04/X06 | events + GF-04 |
| Every required story conversation / objective transition | all 24 main-chain objectives traversed with E.5 record at each | journey | objective events |
| Every gate/crossing | road gate, South Bridge, Warrens vault, Mill Crossing, sigil gate, Hall shutter — each locked-probe (E.6.11) then legitimately opened | journey/X06 | events + shots |
| Every meaningful named location/region | journey arrivals + X07 grid over all 9 regions + Hall | journey/X07 | GF-03…13, GF-AUD |
| Stronghold/Warden/legendary/resolution | S10 full path incl. recovery point | S10 | GF-13 set |
| Post-win world change | S10 walk-back: healed ground, lights out, patrols withdrawn, NPC acknowledgment, Grandpa's post-win line | S10 | GF-13-05 + events |
| Save/quit/load/resume at multiple progression states ✻ | X05 at every segment exit + awkward saves | X05 | duration + restore checks |
| Shipped website/front door | static audit of `site/index.html` + `site/img/*`: claims vs current build, stale references, broken links; rendered-in-browser look is [OWNER-ONLY] | X05 (desk check) | notes |
| Performance (measurable subset) | X08 | X08 | perf JSON |

### L.6 State-transition coverage (§2)

Each row: expected **input owner** (context), **focus**, **camera**,
**outcome**. Probed in X01 with the boundary-frame method; also crossed
naturally in the journey.

| # | Transition | Expected owner after | Expected focus | Camera | Expected outcome |
|---|---|---|---|---|---|
| T01 | exploration → Satchel → exploration | `menu_backpack` → `world` | first usable slot; none after close | frozen behind pause → live | pause on, mouse released; on close: unpause, capture restored, movement live within 2 frames |
| T02 | exploration → Build (hammer or tab) → exploration | `build_catalogue`→`build_placement`→`world` | first enabled build cell | live placement cam | ghost armed on pick; cancel/close returns cleanly; **with hammer out, Build owns Interact; deployed creature "Put away" moves to party-cycle button** |
| T03 | Build + party-cycle/hotbar inputs | `build_placement` | n/a | placement cam | d-pad = build verbs (snap 11 / rotate 12), NOT hotbar; LB does not open creature UI mid-placement; no double-fire |
| T04 | Satchel + hotbar inputs | `menu_backpack` | slot focus | frozen | d-pad moves focus only; hotbar does NOT fire; assign uses backpack_assign (L3) |
| T05 | dialogue → combat → exploration | `narrative_modal` → `combat` → `world` | dialogue line → none → none | dialogue cam → combat cam acquires both combatants **at fight start incl. stronghold/teleport-staged fights** → world cam | trainer flow stages send-out; on victory, rewards + control return with no stuck modal |
| T06 | combat → switch → combat | `combat` throughout | none | camera hands off to new active without losing opponent | party_cycle swaps pilot; HP/cooldown states coherent |
| T07 | map/settings/menu → exploration | `menu_map`/`menu` → `world` | canvas/tab focus → none | frozen → live | zoom level persists on reopen; settings changes persist; B chain closes exactly one layer per press |
| T08 | rest → next day | modal (bed) → `world` | bed panel row | fade | day advances, party heals per rules, flags set, weather re-rolls legally |
| T09 | save → title → load → world | `menu` → title → `world` | Save slot → title buttons → none | menu → title cam → world | restore checklist E.6.13 passes; durations recorded |
| T10 | tournament dialogue → fight → bracket update | `narrative_modal` → `combat` → `narrative_modal`/world | dialogue → none → bracket | staged | bracket advances exactly one round; re-entry offers next round only |
| T11 | catch → party count/full → cycling | `combat_aim` → resolve → `world` | none | aim cam → resolve cam → world | count increments; at 5/5 the designed full-flow runs; LB cycles including newest |
| T12 | tool equip → gather → hotbar switch | `world` | none | world | swing animation plays; pickup feeds inventory; switching mid-swing does not orphan the swing or duplicate yield |
| T13 | torch equip → holster → redraw | `world` | none | world | light attaches/detaches/re-attaches; night visibility delta real (GF-20) |
| T14 | region transition → encounter | `world` | none | world | streaming activates wilds without pop-under-player; an encounter within the handoff window behaves identically to mid-band |
| T15 | objective completion → next guidance | unchanged | unchanged | unchanged | tracked line advances immediately; guided ladder surfaces exactly the next rung; HUD and quest log agree |

Every T-row failure is a defect capture (GF-22) plus an `input_probe`/
event record; T05's stronghold clause and T03/T04's shared-button cells
are the highest-priority collision probes in the matrix.

---

## M. What Phase B receives

At run end the coordinator hands Fable, unedited: this protocol; the
frozen vision/spec docs; `RUN_METADATA.json`; all telemetry, notes,
manifests, frames, shots, saves and logs; `RESTARTS.md`. **No developer
commentary, no proposed fixes, no historical backlog** until Fable's
provisional backlog is versioned (§16.2).

**The inventory check is a harness step, not an operator promise, and its
output is a committed artefact** (amended 2026-08-27, CD-2). It was a sentence
addressed to a human — *"the operator's final act is an inventory check that
every planned artifact exists or carries a recorded reason it does not"* — and
the human it was addressed to reported a complete run in which no prescribed
screenshot existed anywhere on the branch. It now runs as code on every
segment close, blocked segments included, and writes
`<run>/<segment>/INVENTORY.json`:

```
{ "segment", "complete",           # `complete` is COMPUTED, never claimed
  "blocked", "derailed", "derailed_at", "preflight",
  "captures": { "planned", "present", "absent",
                "rows": [ { "id", "step", "action", "class", "intended_proof",
                            "file", "exists", "bytes", "reason" } ] },
  "frames":   { "baseline_hz", "written", "absent", "absent_reasons" },
  "steps":    { "total", "ran", "pass", "fail", "skipped" },
  "harness_errors": [ ] }
```

`exists` and `bytes` are read off **disk**, not copied from the manifest row:
a manifest naming a file that is not there is exactly the claim CD-2 found.
**A segment cannot be marked complete without it**, `INCOMPLETE.md` is written
whenever `complete` is false, and a missing artefact exits the process
non-zero (a failed *expectation* still does not — §1.6).

The other half of CD-2 was outside the harness entirely: `.gitignore` matched
`shots/` unanchored, so `ralph/reports/gate-f-run-*/<segment>/shots/` was never
tracked. The harness wrote the PNGs and git declined to commit them. The
pattern is now anchored to the repository root.
