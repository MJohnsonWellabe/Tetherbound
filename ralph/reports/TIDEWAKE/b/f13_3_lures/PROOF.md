# F13#3: visible-lure witness and fixture disclosure for the six Tidewake local chains

Criterion: ACCEPTANCE §6.1 **F13#3**, "Six selected local chains, one per group, satisfy §5". The §5 activity rule has five parts: the player can **see the lure**, perform a distinct optional action, receive a useful once-only reward and acknowledgement, and reload the saved completion. The walked witness (`tests/smoke_tidewake_b_chain_route.gd`, evidence `ralph/reports/TIDEWAKE/b/f13_3_chain_route/PROOF.md`) covers the action, reward, acknowledgement and reload. This file covers the **lure** and states exactly which fixtures that witness still uses.

**Result: F13#3 stays OPEN.** The judge found the lure noticeable for 2 of 6 chains (Lastlight, and Cradle with a caveat). It found 3 weak and 1 not noticeable. The Codex rows are V-TW-2 to V-TW-6 in `ralph/reports/VISUAL/AUDIT.md`.

## A. Lure captures

- **Tool:** `tools/capture_water_chain_lures.gd`. It is new and capture-only; it changes no product code.
- **Scene and view:** the production `scenes/world/water_archipelago.tscn` with the production `CameraRig` at its normal framing (only its yaw is turned toward the lure) and the production HUD. The time is `day` with the clock frozen.
- **State:** each chain's lead flag is set, so the frame shows what a player who has been told about the place would see. The upstream story flags are the same set as `tools/capture_water_local_chains.gd`.
- **Stands:** the player is placed by position write:
  - frame 1 is the island's authored arrival landing (`water_world.json` `anchors[kind=arrival].safe_position`), facing the lure;
  - frame 2 is a point on the straight line from that landing toward the lure, ground-projected;
  - Lastlight's lamp is only 14 m from its landing, so its frame 2 stands 42 m **offshore** on the swim approach from Sluice Isle, with the trainer swimming.
- **Settling:** before each capture the tool waits 240 physics frames, re-poses the player, then waits 60 more, so terrain streams in. Every frame was inspected, and all have terrain.
- **Renderer and output:** Compatibility/opengl3 under xvfb (llvmpipe), 1280x720 JPG at quality 0.8.
- **Logs:** `capture.log` holds frames 1–8. That run hit its 1500 s timeout before Deep Watch, so Deep Watch and Lastlight were re-run with `--only=deep,lastlight` (`capture_deep_lastlight.log`).

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_water_chain_lures.gd -- --out=ralph/reports/TIDEWAKE/b/f13_3_lures [--only=deep,lastlight]
```

**Limit of this method:** the mid-approach stand is on a straight line, not the walked route. The Cradle mid stand (`cradle_2_approach.jpg`) ended up in a narrow rock slot, and the Garden and Lantern mid stands face over a crest. A walked-route stand could see more or less. The rows say "verify-first" where this matters.

## B. Code-blind judge

The Agent tool was not available to this subagent. The judge was therefore a **separate Claude process**, run as `claude -p` with only the `Read` tool allowed, started in an isolated scratch directory that held only:
- `frame_01..12.jpg`, the twelve frames renamed so that the file names carry no place or lure name;
- `_sheet.png`, the contact sheet from `tools/contact_sheet.gd`;
- `keyart.png`, a copy of `docs/reference/tetherbound-meadows-keyart.png`, the art-direction board named by the visual-judge skill.

It was not told what the lures are or what result was hoped for. The prompt is verbatim in `JUDGE_PROMPT.txt`, the answer is verbatim in `JUDGE_VERDICT.txt`, and the frame-to-file map is in `JUDGE_FRAME_MAP.txt`.

## Per-chain table

| Chain | Lure (WORLD / data) | Frames | Judge verdict (verbatim excerpt) | Noticeable? | Codex row |
|---|---|---|---|---|---|
| side_water_lantern_return | Lantern Cove's visible rock arch / dry nook cache (`water:lantern_cove:pickup:002`) | `lantern_1_landing.jpg` (162 m), `lantern_2_approach.jpg` (73 m) | 01 WEAK "only landmark is a single tree … nothing reads as a clear go-there beacon"; 02 NOT NOTICEABLE; place **NO** | **no** | V-TW-2 |
| side_water_gull_research | Adair's survey satchel site at Gull Rest | `gull_1_landing.jpg` (101 m), `gull_2_approach.jpg` (40 m) | 03 WEAK "nothing distinct or lit catches attention"; 04 NOTICEABLE, but for a distant rock spire, not the satchel; place **WEAK** | **weak** | V-TW-3 |
| side_water_cradle_care | Tidal Cradle shell nest / Reef Stone seam (`water:tidal_cradle:harvest:007`) | `cradle_1_landing.jpg` (406 m), `cradle_2_approach.jpg` (122 m) | 05 NOTICEABLE "campsite (tent, campfire…, tiny NPC)" (Otto's camp at the landing, the chain's requester); 06 NOTICEABLE (weak-side), a creature in a canyon; place **YES** | yes, for the requester camp; the nest itself was not seen | V-TW-6 (weak, verify-first) |
| side_water_garden_records | The Drowned Garden's exposed vault wall (always visible) | `garden_1_landing.jpg` (171 m), `garden_2_approach.jpg` (68 m) | 07 NOT NOTICEABLE "reads as empty transition space"; 08 WEAK "pretty but undirected vista"; place **WEAK** | **weak / no** | V-TW-4 |
| side_water_deep_watch_chart | Deep Watch chart / return-current control (`WaterDocks/deep_watch_chart`) | `deep_1_landing.jpg` (13 m), `deep_2_approach.jpg` (5 m) | 09 WEAK "beam and crate … low-contrast and easy to overlook"; 10 NOTICEABLE "clearly a small built object … something to interact with"; place **WEAK** | **weak** | V-TW-5 |
| side_water_lastlight_shelter | Halen's Lastlight lamp post at the Veilfall landing camp | `lastlight_1_landing.jpg` (14 m), `lastlight_2_approach.jpg` (42 m offshore) | 11 NOTICEABLE "lit campfire, a hanging lantern on a post, a tent, and a standing NPC"; 12 NOTICEABLE "camp (lantern, tent, NPC) still visible"; place **YES** | **yes** | none |

Under the owner's direction, art and visual changes belong to Codex, and this lane changed none. F13#3's "see the lure" clause remains open for Lantern, Gull, Garden and Deep Watch until V-TW-2 to V-TW-5 land and a code-blind judge re-scores them. Cradle stays open until V-TW-6 is recaptured from a walked-route stand.

## C. Fixtures of the walked witness

### Default mode (the landed PROOF runs)

`tests/smoke_tidewake_b_chain_route.gd` without flags behaves as landed.

1. **Inter-island travel is position writes, not swims.** Whenever the next target is on another island, the trainer is written onto that island's authored arrival landing (`anchors[kind=arrival].safe_position`), and each write is printed as `POSE`. First Shore has no arrival anchor, so a return there writes the trainer onto the world's start spawn. Deep Watch has one more write, to a dry stand within Tidecoil's reach.
   - **Complement:** `tests/smoke_water_hop_walked.gd` (F12#0, batch 30, `ralph/reports/TIDEWAKE/b/f12_0_walked_hops/PROOF.md`) independently proves that every mandatory hop (7 sheltered routes, 24 hops, plus 4 direct alternatives) is swimmable with real `move_forward` input at swimming level 0 with the original five (worst 30.19 % stamina). It does **not** cover the four optional crossings: Lantern Cove, Gull Rest, Drowned Garden and Deep Watch.
2. **Lastlight materials:** 4 driftwood and 4 reed fiber are **granted** into the satchel before the walk to the delivery prompt. They are not gathered.
3. **Lastlight rest:** the production bed's `assign_creature(0)` is **called directly**. The bed prompt and rest panel are not driven. A Brooktail is spawned into the party only if the reset party is empty.
4. **Tidecoil:** the fight is not played. The resident body is marked engaged and the director's `_on_combat_exited("won")` is invoked.
5. **Upstream story flags** are pre-set before load, and a carried pickaxe is placed on hotbar slot 1.
6. **Solo host only.**

### New `--continuous` mode (this branch)

This mode removes fixtures 1–4 where it can.

- **Swims:** inter-island legs are swum. The island path is a BFS over the authored `water_routes` (sheltered first, either direction). For each route the trainer:
  1. stick-walks to the route's start anchor;
  2. idles with no input and no write until stamina is full;
  3. holds the real `move_forward` action with the camera yawed at each polyline vertex, resting idle on any dry vertex, until the far anchor.

  Each crossing prints a `SWIM` line with the metres swum, minimum stamina, rest frames and health.
- **Lastlight materials** are gathered by walk + Interact:
  - reed fiber: `water:veilfall:harvest:005` by hand, plus `water:sluice_isle:harvest:012` if still short;
  - driftwood: `water:veilfall:harvest:007` and `:011`, with the carried axe equipped by the real `hotbar_2` action.
- **Lastlight rest** goes through the bed's `Rest a Creature` Interactable. Interact opens the production rest panel, `ui_accept` selects the focused first row, and `menu_cancel` closes the panel.
- **Tidecoil** is fought for real with `tests/helpers/tidewake_b_tidecoil_fight.gd`, from `tb/scratch-tidewake-b-f13-2-full` 4e04f079: a walk to the reef shore, deploy by `creature_recall`, engage, and a win through the production CombatManager and director.

Fixtures that remain in `--continuous`, all disclosed and printed:

- the retained five at level 43 are granted, the same as the pocket smoke's `--real-tidecoil`;
- the carried pickaxe and axe;
- the upstream story flags, plus `water_dock_shellwatch_residents_freed_and_pump_disabled` and `water_dock_sluice_isle_both_controls_disabled` so the swim chain may depart;
- **one position write** after the Tidecoil win, only when the trainer is stranded in the shallows under Deep Watch's cliff. The helper reports that there is no wading path up and that the swim back exceeds level-0 stamina; the intended route rides an owned swimmer, which this party does not have;
- the tool axe and pickaxe are not crafted;
- solo only.

Result of the continuous run: still in progress (WIP; no overall result claimed here). Its logs land with the continuous-run evidence.

## Finding: the Gull Rest crossing at swimming level 0 (reported, not tuned)

**Evidence status: not yet committed.** The continuous run B log (`../f13_3_continuous/`) is not on the branch yet, so treat this finding as unverified until that log lands. In that run, the route `reedhaven_to_gull_rest_sheltered` was swum with real input at level 0 with the retained five. It is 157.6 m of measured surface polyline with no rest shoal.

| Direction | Swum | Min stamina | Health | Result |
|---|---|---|---|---|
| Outbound | 151 m | 0.0 | 75 → 65 (10 HP lost to exhaustion) | arrived dry |
| Return (reversed) | 151 m | 0.9 | 65 → 65 | arrived dry |

The route row in `data/config/water_world.json` has `main_path: false` and `intended_traversal: "prepared_human_or_swim_mount"`. The design therefore marks this as an optional *prepared* crossing, not a level-0 one, and WORLD's lure line calls it a "safe optional crossing". WORLD/SYSTEMS own whether an unprepared level-0 swimmer should arrive at 0 % stamina with health damage. This lane did not change it.

The same run's earlier 25 HP drop (100 → 75) happened on First Shore before any swim, during the stalled Lantern walks. It is unexplained here, possibly a wild creature.

**What WORLD says:**
- WORLD §Tidewake human swimming (line 240) sets the 20 % reserve bar with 15 % steering deviation only for "the first and every **mandatory** human-swim hop". Gull Rest is optional (WORLD line 228: "Optional researcher branch").
- Line 252 says swim mounts "improve … marked optional routes".
- The Gull chain row (line 427) says "reach researcher/satchel via **safe** optional crossing".

**Reading:** this is not a violation of the mandatory-hop bar. It is in tension with the chain's own "safe optional crossing" wording, because an unprepared level-0 swimmer who starts at full stamina and steers straight, with no deviation, arrives at 0 % after 4 HP/s exhaustion damage. The finding is recorded as a **design question for WORLD/SYSTEMS**, not a defect.

## Continuous-mode status (in progress)

- **Run B** (`../f13_3_continuous/continuous_b_partial.log`, stopped by me mid-run):
  - Lantern failed. The straight stick leg between Pell's dock and the Lantern departure stalled on a First Shore slope; it succeeded in one run and stalled in another. The swims out and back themselves passed (95 m each way, min stamina 29.1 / 33.7).
  - Gull then ran by real swims: first_shore→reedhaven, reedhaven→brine_steps (Adair), brine_steps→reedhaven, and reedhaven→gull_rest. The satchel site and the Candy II were claimed by walk + Interact.
- **Fix:** in continuous mode a stalled walk retries from where it stopped: re-plan, else via the island landing, else direct. Each retry prints `RETRY`. Run D (`continuous_d.log`, with `--save-dir` checkpoints) verifies it.
- **Not done in this pass:**
  - the earned swimmer and saddle for the Drowned Garden and Deep Watch legs, and the ride back after Tidecoil. The lane lead's research points to main's `tests/helpers/water_earned_swimmer_preparation_segment.gd` / `water_earned_swimmer_segment.gd` / `water_earned_late_segment.gd`. Until those are wired in, Garden and Deep Watch are attempted by human swim, and the post-Tidecoil stranding uses the disclosed landing write;
  - a start from an earned Water-arrival save.
