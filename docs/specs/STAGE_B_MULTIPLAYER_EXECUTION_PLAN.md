# Stage B execution plan — playable 1–4 player co-op

**Status:** approved execution plan for `docs/DEVELOPMENT_ROADMAP.md` Stage B, written 2026-09-05
against `main` at `55c64aaa`. It sits under the directive it executes,
`docs/MULTIPLAYER_DIRECTIVE.md`, and above every Stage B lane brief. Where a lane brief and this
plan disagree, this plan wins until a `docs/decisions/` record says otherwise. Update the wave
tables as lanes land; do not fork a second plan.


## Context

`docs/DEVELOPMENT_ROADMAP.md` names Stage B as the current next action: execute
`docs/MULTIPLAYER_DIRECTIVE.md` until Tetherbound is a playable Valheim-style 1–4 player co-op
game, starting from `main` at `55c64aaa` (every branch consolidated, zero open PRs, Cloudreach
folded in). The directive is complete on product rules (§5, twenty settled owner decisions) and on
milestones (M0–M7). It is silent on two things this document settles: **how** to execute on this
codebase, and **who** (which model tier) does which piece. It ends the way the directive demands:
playable 1/2/3/4-player evidence, not a networking-ready architecture.

Nothing here changes a hard rule in `CLAUDE.md`: five creatures per player, no storage, no
friendly fire, no creature trading, Godot 4.7, controller-first, Windows/Ally primary.

This plan was adversarially reviewed once before approval; the review's findings (a hollow
validation path in the first authority design, a spawner constraint that sinks realm delegation,
seven directive clauses with no test, four lane collisions, nine factual slips) are folded in below.

---

## 1. Architecture facts the plan stands on (verified 2026-09-05)

**One autoload, `Game` (`autoload/game_state.gd`, 1,816 lines).** Everything else is a composed
`RefCounted` it preloads: `inventory.gd`, `party.gd`, `map_state.gd` (+ `cloudreach_map_state.gd`),
`progression_state.gd` (the flat flag store, 49 `set_flag` sites in 27 files), `realm_heart_state.gd`,
`player_equipment.gd`, `quest_log.gd`, `save_game.gd`. The pure modules never touch the scene tree;
only `Game` does. **That seam is the conversion strategy: keep the pure modules, re-home them under
a per-world and a per-player container, and route tree side effects through an authority layer.**

**Already world-shaped on `Game`:** `progression`, `current_realm`, `pending_realm_entry`, `day`,
`clock_elapsed_seconds`, `placed_buildings` (chest contents ride inside a record's `state`),
`farm_plots`, `death_satchels` (no owner field today, `game_state.gd:919`), `harvested_vegetation`,
`felled_vegetation`, `world_seed`. **Already player-shaped:** `party`, `inventory`,
`player_equipment`, `hotbar`, `equipped_tool`, `satiety`, `saved_player_pose`, `pending_catch`,
`pending_build`, `objective_text/hint`, `realm_hearts._active_id`. **Personal by directive but
world-shaped today:** map fog/landmarks/dynamic markers/alpha pins, and the personal story flags
(`opening:beat:*`, tutorial, home, creature-bed, team objectives) that share the `progression`
dictionary with world flags.

**Save:** `scripts/save/save_game.gd`, `VERSION = 22`, one monolithic JSON per slot in
`user://saves/`, slot 0 autosave, a `_migrate_v<n>` loop, never fatal on load. Autosave fires from
`game_state.gd:612` (`_tick_autosave`, 180 s), `:1049` (`enter_realm`), `:1113`
(`complete_realm_entry`) and `scripts/world/night_rest.gd:97` (whichever peer rests).

**Realms:** `data/config/realm_hearts.json` maps `meadows` → `meadows_playground.tscn`, `cloudreach`
→ `cloudreach_cliffs.tscn`. `Game.enter_realm()` calls `get_tree().change_scene_to_file()` — a
whole-tree teardown. Each world root builds itself procedurally in `_ready()` across awaited
frames. **Meadows** ground is Terrain3D with collision granted only within 256 m of one `Camera3D`
(`playground_world.gd:596`, radius clamp at `:477`), while the heightfield is also a pure function
(`ground_height_at`, D09) that the director already trusts over physics
(`encounter_director.gd:1781`, `creature_body.gd:1796`). **Cloudreach** has no Terrain3D: ground
is analytic (`cloudreach_world.gd:212`) plus authored mesh collision.

**The world scene is a flat list of named singleton siblings** (`CameraRig` is a sibling of
`Player`, not its child): `Player`, `CameraRig`, `CombatManager`, `EncounterDirector`,
`InteractionArbiter`, `RidingController`, `SequenceDirector`, `PlaygroundHUD`, `CombatHUD`,
`DialoguePanel`, `WorldLook`, `WorldWeather`, `WorldAudio`. Fifteen-plus sites plus both world
roots' `$Player` find the player by node name; `Game._find_player()` (`game_state.gd:716`) is the
existing lookup to promote. `camera_rig.set_target(node, profile)` is the universal camera hand-off.

**Combat:** `combat_manager.begin(player, wild, ally_body, party, camera_rig, best, opponent_owned)`
is the single entry; one trainer body, one wild body, one ally body time-shared by the party's stat
instances; damage in `_resolve_player_strike()` (`:838`, `MATH.move_connects` on live geometry, one
`_rng.randf()`); enemy strikes at `:1244` against `_ally_body.centre()`; catch decided once in
`_on_orb_struck()` (`:1430`, `CATCH.resolve(rate, hp_fraction, orb_id, offset, radius, rng)`); the
creature joins the party in `encounter_director._resolve_catch()`. `throw_aim.gd` and `orb.gd` carry
pure statics (`ballistic_direction`, `predict_launch_point`, `closest_approach`) that let a host
re-derive an orb's closest approach from launch parameters. Wild vs trainer vs boss differ only by
`_enemy_owned` and data. `EncounterDirector` holds one `_ally_body` named `"AllyCreature"`, streams
clusters off `_player.global_position` (`:1726`), and its spawn plan is a pure function of
`(world_seed, order)`. `Game._process` (`game_state.gd:634`) ticks buffs and nourishment and relies
on tree pause to stop them while a panel is open.

**Input/pause:** `input_owner.gd::current(tree)` is a tree-global single answer; six panels also
`get_tree().paused = true` (`craft_panel, storage_panel, swap_panel, game_menu, creature_bed_panel,
shop_panel`); 29 files poll `Input.*` directly (`combat_manager.gd` at `:735, :972, :1014, :1035,
:1041`); `build_menu.gd` is the one deliberate non-pauser. Menu tabs are data-driven
(`data/config/menu.json` + a script extending `menu_tab.gd`; the shell is not edited to add one).

**Process-global hazards:** `progression_feed.gd` is all `static var`; `map_state.gd` caches the
world extent in statics; `death_satchel.gd:38`, `storage_container.gd:20` and `creature_bed.gd:366`
each hold a `static var _panel`.

**Networking:** none. Godot 4.7's high-level multiplayer (`ENetMultiplayerPeer`, `@rpc`, server
relay, `MultiplayerSpawner`, `MultiplayerSynchronizer` with per-peer visibility) needs no addon.
Constraints that shape the design: a spawner spawns on *every* peer under a `spawn_path` that must
already exist there (visibility filters gate synchronizer updates, not spawns); a client cannot
spawn its own node — it asks the host, which spawns and sets authority before the node enters the
tree; authority transfer must be applied on every peer in the same tick.

**Testing:** no multi-process pattern exists; the precedent is `tools/flake_rate.sh`'s per-process
`XDG_DATA_HOME` isolation. CI runs only via PR (push trigger is `main`-only since 2026-09-05);
a PR runs 46 smokes across six shards plus `verify-gate-b-core`; the other ~103 smokes run only by
hand. A full run is 35–45 min; the unit suite is 28–39 min. `ubuntu-latest` is 4 vCPU. Godot is not
installed in this container; the first lane installs 4.7-stable as previous lanes did.

---

## 2. The central simplification

**Every process keeps exactly one local player.** Split-screen is not a requirement. The scene
singletons therefore do not become multi-player *within* a process: they key on the local rig,
tolerate remote trainer/creature bodies, and route every consequential outcome through the host.
A multi-pilot boss fight is N processes each running its own local `CombatManager` against one
host-simulated opponent. This keeps `smoke_combat`, `smoke_catching`, the Gate F harness and the
existing smokes meaningful as solo regression throughout.

**Solo is a one-peer session.** Start/Load World on the title screen calls `Session.host()`; the
host talks to its own authority layer in-process. `smoke_playground` asserts
`multiplayer.is_server()` so the "no second implementation" claim is checked, not asserted.

---

## 3. Decisions Fable records before any lane starts

Each becomes a `docs/decisions/D95+` record (D91 is used twice; continue numbering, renumber
nothing) and is summarised in `docs/specs/MULTIPLAYER_CONVERSION_MAP.md`.

| # | Decision | Why |
|---|---|---|
| D-MP1 | **Transport:** Godot ENet, listen server (host = server), direct IP + LAN beacon (`PacketPeerUDP`). Two channels: one for ledger/encounter traffic, one for snapshots, so a late-join snapshot never blocks movement. Port, max players 4, timeouts, downed window in `data/config/multiplayer.json`. No Steam/relay this pass. | Directive §6 accepts LAN/direct-IP. No addon, no service, testable headless. |
| D-MP2 | **The host simulates every non-player body; peers simulate only their own trainer and deployed creature.** Wild creatures, trainer creatures and bosses run on the host in a **kinematic heightfield mode** of `creature_body.gd`: ground from the analytic heightfield (`ground_height_at` in Meadows, `cloudreach_world.ground_height_at` in Cloudreach), no Terrain3D dependency, structure collision from the always-present built nodes, arena `hold_inside` unchanged. Peer-owned bodies replicate their transform to the host continuously, so at strike time the host holds an independent position for both attacker and target. Strike intents carry only `(move, origin, facing)`; the host tests `move_connects` against **its own** opponent position with a latency tolerance decided in the brief. Catch attempts carry launch parameters; the host re-derives the closest approach with `orb.gd`'s statics against its own body position and rolls `CATCH.resolve` with host RNG. | Directive §4: the server decides enemies, damage, catches. The first draft delegated opponent simulation to the engaging peer and was rejected in review: the same peer would author both the hit and the target snapshot, leaving the host a counter, not an authority. The heightfield route needs no full-map Terrain3D collision; its cost (active clusters keyed on the union of occupants) is measured by spike S2. Known limitation, recorded: host-simulated bodies outside the host's own scatter-collision radius do not collide with vegetation; the visual judge watches for clipping. |
| D-MP3 | **Different biomes at once = one headless realm shell per occupied realm on the host.** A realm shell is the world scene instanced under `Session/Realms/<realm>` in simulation-only mode: heightfield, encounter director, world records, pickups/gates/NPC triggers, spawn containers; no grass, water rendering, VFX, HUD or audio. Spawn containers (`Spawned/Trainers`, `Spawned/Creatures`, `Spawned/Items`) are **authored in both `.tscn` files**, so a spawn arriving during a peer's procedural build has a path. Replication is realm-scoped through synchronizer visibility plus per-realm spawners. Every ledger intent and world record carries an explicit `realm` (no reliance on `Game.current_realm`). Until Wave 6 lands, `enter_realm()` is **refused in a multi-peer session** with a message. | The first draft delegated an unhosted realm's simulation to its first occupant; review showed the host has no spawner path for that realm and that an owner's disconnect mid-fight loses state nothing else holds. Directive rule 16 permits the interim limitation only during development. Shell cost is measured by S2 before Wave 6 commits to it. |
| D-MP4 | **State containers under the one autoload.** `Game.world: WorldState`, `Game.local: PlayerState`, `Game.players: Dictionary[peer_id → PlayerState]` (host holds all). `Game.party`, `Game.inventory`, etc. **stay as forwarding properties** — `Game.party` permanently means "the local player's party". `Game.progression` becomes a merged view whose `revision` is the sum of both stores' revisions (so the objective line still redraws on world deltas) and whose `set_flag(id)` routes by scope. Only authority-side code addresses `Game.players[peer]`. | Directive §3 allows adapters and forbids rewriting working systems for purity. |
| D-MP5 | **Every flag id has a declared scope; an undeclared id is a test failure, never a default.** `objectives.json` entries and a `data/progression/flag_scopes.json` table classify each id `world` or `player`. World: bosses, gates, relay, Heart earned/placed, trainer `defeat_flag`, pickups/harvest/cache taken, once-only alphas, `legendary_freed`. Player: `opening:beat:*`, tutorial, `tournament_*_ready/fed`, `player_slept_at_home`, saddle-fitted, `legendary_joined`. **Home and creature-bed objectives** (`home_built`, `creature_bed_built*`, `home_materials_gathered`) are player flags **granted to every connected peer when the world gains the pieces** — a shared camp is everyone's camp. `pass_the_night` on the host writes `player_slept_at_home` into each sleeper's store via a per-peer delta. | Directive §16, rule 14. The residual classifications are Fable's call and recorded in D-MP5. |
| D-MP6 | **Save split, Valheim-shaped.** `user://worlds/<world_id>/world.json` (host-owned) and `user://characters/<character_id>/character.json` (portable). A v≤22 slot is split on first load into one world + one character; **the original file is never modified or deleted.** Key coverage is a test: the union of the two new key sets equals the v22 key set, the intersection is empty. Autosave: host writes the world file; each peer writes only its own character; a client never writes a world file. | Directive §14. |
| D-MP7 | **Per-player rig.** `scenes/player/local_rig.tscn` = Player + CameraRig + FlyController + HUD binding; `scenes/player/remote_trainer.tscn` = model, animation state, nameplate, synchronizer, no camera, no input. `Game._find_player()` is promoted to `Game.local_player()`; name lookups go through it or the `local_player` group. | Fixes the name lookups once; the camera belongs to the peer that renders. |
| D-MP8 | **Menus never pause a multi-peer session.** `Session.pause_local(bool)` pauses the tree only in a one-peer session. In a session the `input_owner` group stops world verbs; buffs and nourishment keep ticking while a panel is open (a deliberate behaviour change, recorded). | Directive §13. Solo keeps true pause. |
| D-MP9 | **Catch, pickup, storage, trade are host transactions with versions.** First committed claim wins; the loser gets an explicit refusal; storage carries `expected_revision`. | Rules 4, 5, 7, 17. |
| D-MP10 | **Downed → revive → death; satchels have an owner.** `died` becomes `downed` for a configurable window; a teammate's `interact` revives; on timeout the existing satchel-drop/respawn runs. A death satchel is a world entity tagged with the owner's character id; only the owner can open it, others see it labelled. Solo has no window. One player's death never touches the encounter or the world. | Directive §12, rule 19. |
| D-MP11 | **Sleep is a vote.** Host tracks sleeping peers; `pass_the_night` runs on the host when every connected, non-downed peer is in a bed; the day/clock is host truth replicated to peers (`Game.day`, `clock_elapsed_seconds`, `world_look` resume). | Rule 9. |
| D-MP12 | **Scaling is composition-first; rewards are per participant.** Per participant count: extra opponents/roles and targeting rules from `multiplayer.json`, plus a modest stat multiplier; never HP × players. An encounter's mandatory personal rewards (XP, items, key flags that are player-scoped) are granted to every participant through a per-encounter `reward_grant` in the ledger — no such mechanism exists today (Cloudreach's "receipts" are HUD banner events), so it is built in 4.A/4.E. | Rules 6, 15, 20. |
| D-MP13 | **Creature trading is out; item trading is in.** Direct offer/accept plus drop-to-world entities, both through the ledger. | Rules 17–18. |

---

## 4. Model tiers for this stage, and why

The repo's tiers (`docs/AGENT_WORKFLOW.md` §1) are Fable / Sonnet / Haiku. This stage adds
**Opus** as a named tier, because the conversion has a class of work the existing tiers are wrong
for: bounded but deeply coupled changes inside 2,000-line files whose invariants the lane must hold
for the whole task, and contracts other lanes build on. The project has paid for handing that
shape to Sonnet — GRASS-CULL stopped at the first plausible fix, W05 failed two rounds against
`main`, several lanes "verified a comment against another comment". Fable cannot do all of it
personally and remain the orchestrator.

**The rule, applied mechanically:** a lane is **Opus** if it edits any collision-list file
(`game_state.gd`, `save_game.gd`, `combat_manager.gd`, `encounter_director.gd`,
`playground_world.gd`, `cloudreach_world.gd`, `playground_hud.gd`, `sequence_director.gd`, either
world `.tscn`) **or** defines a signature, RPC or JSON shape that two or more later lanes consume.
Otherwise **Sonnet**. **Haiku** never writes code that has to run. **Fable** writes specs,
decisions, seam contracts and characterization tests, lands waves, and judges; it implements
nothing a tier below can do from a written contract.

| Tier | Owns in Stage B |
|---|---|
| **Fable** | The thirteen decisions; the conversion map; the **seam spec** for the M1 split (property list, forwarding rules, scope table, the characterization tests that must go red); the Encounter protocol spec; the scaling table; every wave landing; every gate verdict; Stage B acceptance. |
| **Opus** | Net-harness control protocol review; the M1 split implementation; the save split; `Session`; the rig split; `WorldLedger`; creature ownership; encounter core, catch arbitration and shared trainer/boss paths (serialized); story triggers in a session; realm shells and transitions; late-join/reconnect/host-exit. |
| **Sonnet** | Spikes; the net harness from a written control-protocol contract; host/join UI; non-pausing panels; local-rig wiring; pickups/harvest; building; storage consumers; trading; movement sync; revive; scaling data; Hearts; map/fog; sleep vote; riding; Fly; remote-body presentation; Cloudreach runtimes; solo regression sweeps; owner kit; every code-blind judge. |
| **Haiku** | The assumption inventory; `flag_scopes.json` data entry from Fable's table; ledger and doc updates; the acceptance template skeleton; contact sheets; report filing. |
| **Codex** | Not used in Stage B (the roadmap assigns Stage B to Fable; Codex resumes at Stage E). |

Verification discipline is unchanged: a self-report is not evidence; Fable reads the branch and
the run; a check counts only after someone saw it red for the right reason; the two-no-yield-attempt
rule applies to every narrow net defect.

---

## 5. Wave plan

Eight waves, each landing as **one consolidated PR** (owner instruction 2026-09-05: one branch, one
CI run, one PR per landing). Wave branch `ralph/MP-W<n>-<date>`; lanes branch from it and merge
back; lanes verify locally; the wave PR gets full CI. Core-file lanes serialize; Sonnet lanes run
in parallel once their contract has landed on the wave branch. Every lane ends with the §4
completion report at `ralph/reports/<LANE>-<date>/REPORT.md`. Sizes: S ≈ one session, M ≈ one to
two, L ≈ several with checkpoints.

### Wave 0 — Instruments and decisions (directive M0)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **0.A Decisions, conversion map, harness contract, seam spec** | Fable | `docs/decisions/D95–D107`, `docs/specs/MULTIPLAYER_CONVERSION_MAP.md`, `docs/specs/MP_NET_HARNESS_CONTRACT.md`, `docs/specs/MP_STATE_SEAM.md` | The thirteen decisions; the map lists every system → (world/player/session/transient), owning wave/lane, proving test; the harness contract (control protocol, step vocabulary, isolation, budgets, desync detector, jitter knob); the seam spec 1.A implements (property list, forwarding rules, merged-revision rule, scope routing) with Fable's residual flag-scope table. Waits on 0.B, S1, S2. |
| **0.B Assumption inventory** (S) | Haiku | `docs/specs/MP_ASSUMPTION_INVENTORY.md` | Per file: `Game.<field>` reads/writes; player name lookups (incl. `$Player`); `get_tree().paused` sites; `Input.*` polls; `get_viewport().get_camera_3d()`; singleton group lookups; every `static var`; every `set_flag` site with the flag id. Counts reproduce from the greps it records. |
| **0.C Spike S1 — ENet in this repo** (S) | Sonnet | `tools/net/_spike_enet.gd`, report | Two headless processes, RPC both ways, spawner spawn seen by the client, authority set before tree entry, `OS.create_process` + per-process `XDG_DATA_HOME`. Exact invocation and timings. |
| **0.D Spike S2 — host cost and shells** (S) | Sonnet | report only | Memory/wall-clock for 2 and 4 concurrent headless Meadows boots plus one Cloudreach on the 4-core box; host tick cost with active clusters keyed on 1/2/4 occupant positions; a stripped "simulation-only" Meadows boot (no grass/water/VFX) memory and time. Feeds D-MP2/D-MP3 numbers and the CI budget. |
| **0.E Solo regression fence** (S) | Sonnet | `.github/workflows/ci.yml` (fence job list), `tools/run_all_smokes.sh`, `tests/test_characterize_*.gd` | `verify-solo-regression` = the existing 46 CI smokes; `run_all_smokes.sh` runs all 149 locally with a log and a summary (used once per wave by 7.B-style sweeps); characterization tests pinning `progression_feed` epochs, `map_state` round-trip, pickup/harvest flag keys, `party.add` cap, buff ticking under pause. Lands before 0.F. |
| **0.F Net harness** (M) | Sonnet from 0.A's contract, **Opus reviews** | `tests/helpers/net_harness.gd`, `tools/net/peer_runner.gd`, `tools/net/run_net_smoke.sh`, `tests/smoke_net_two_peers_boot.gd`, `ci.yml` `verify-multiplayer-shard` | Coordinator launches N isolated peer processes and drives each over a local TCP control channel; `press`/`hold`/`stick` reach `Input.parse_input_event` inside the peer (the same seam Gate F uses in-process); `move_to` uses `stick_navigator.gd`; `assert`, `wait_flag`; per-peer JSON verdicts and logs; orphan kill; wall-clock budget; **desync detector** (each peer hashes `WorldState.save_data()` every N s, coordinator asserts equality); a UDP proxy knob for delay/jitter/loss. Peers run real-time physics (no fast-forward) with tolerances stated in the contract. CI job runs 2-peer smokes on PRs; 3/4-peer smokes are `workflow_dispatch` nightly and the owner kit. |

Exit: decisions and map landed; Godot installed; the fence job exists; the harness boots two
peers in CI (this proves the instrument only — nothing about the game yet).

### Wave 1 — State and save separation (M1)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **1.A Scope table data** (S) | Haiku from Fable's table | `data/progression/flag_scopes.json`, `objectives.json` `scope` fields | Every id in `objectives.json`, `trainers.json`, pickups, gates, and the 49 writer sites is classified. `test_flag_scopes.gd` (written by 1.B) fails on any undeclared id. |
| **1.B World/Player split + facade** (L) | **Opus** from `MP_STATE_SEAM.md` | `autoload/game_state.gd`, new `autoload/world_state.gd`, `autoload/player_state.gd`, `progression_state.gd` (scope routing), `progression_feed.gd`, `map_state.gd` statics, the writer sites that need an explicit store (`night_rest.gd`, `home_progress.gd`, `stronghold_climax.gd`, `realm_heart_state.gd`) | D-MP4/D-MP5. Forwarding properties keep call sites working; `progression_feed` and the map extent become instances on `PlayerState`; merged revision. Characterization tests from 0.E seen red on a deliberate break, then green; full unit suite; the 46 CI smokes green first attempt; `run_all_smokes.sh` once on the lane head with the summary in the report. |
| **1.C Save split + migration** (M, + Sonnet sub-lane for slot UI) | Opus | `save_game.gd` → `world_save.gd`, `character_save.gd`; `tab_save.gd`, `title_screen.gd` | D-MP6. `test_world_save_format`, `test_character_save_format`, `test_legacy_slot_split_never_touches_the_original`, `test_split_key_coverage_equals_v22` (all seen red first); `smoke_save_persistence`, `smoke_title_load_game`, `smoke_finale_persistence`, `smoke_cloudreach_persistence_tail` green. Title/menu show Worlds and Characters with controller navigation. |
| **1.D Ledger docs** (S) | Haiku | `docs/CURRENT_STATE.md`, `docs/TECHNICAL_ARCHITECTURE.md` §2/§8/§10 | Stale counts corrected (tests/ is 184 + 149; VERSION 22; autoload composition; Cloudreach has no Terrain3D), Stage B row added. |

Exit: solo plays exactly as before on the split state; an old save loads as a world + a character;
no flag id is unscoped.

### Wave 2 — Networking shell (M2)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **2.A Session** (L) | Opus | new `scripts/net/session.gd` (child of `Game`), `scripts/net/peer_registry.gd`, `data/config/multiplayer.json`, the four autosave sites in `game_state.gd`/`night_rest.gd`, `enter_realm()` guard, host clock replication | Host/join/leave/kick; peer ↔ character ↔ realm registry; handshake (character summary up, world snapshot down on the snapshot channel); late-join snapshot; reconnect by character id; host-exit → save world, notify, everyone returns to title; **autosave ownership per D-MP6**; **`enter_realm` refused in multi-peer sessions until 6.A**; `Game.day`/clock as host truth. `test_peer_registry.gd`, `smoke_net_host_join_leave.gd`, `smoke_net_host_exit_saves.gd` (asserts the client's `user://worlds/` stays empty), `smoke_playground` asserts `is_server()`. |
| **2.B Host/Join UI** (M) | Sonnet | `title_screen.gd` (host/join screen; Start/Load World → `Session.host()`), new `menu.json` tab + `scripts/ui/tab_players.gd`, LAN beacon. **Does not edit `game_menu.gd`** (tabs are data-driven). | Controller-only host, join-by-IP (reuse the name-prompt keyboard), LAN list, Players tab with kick. `smoke_net_menu_controller.gd`, `test_menu_data` green. |
| **2.C Rig split + remote trainers** (L) | Opus | `local_rig.tscn`, `remote_trainer.tscn`, both world `.tscn` (spawn containers authored), `playground_world.gd`, `cloudreach_world.gd`, `interactable.gd` LOS exclusion, the name-lookup sites, exported `*_path`s | D-MP7 + D-MP3's authored spawn containers. Host spawns trainers with authority set before tree entry; remotes interpolated; nameplate. Tolerance for "sees the other within N m" fixed in the brief. `smoke_net_movement_two_peers.gd`, `smoke_playground`, `smoke_input`, `smoke_traversal`, `smoke_cloudreach_arrival_walk` green. |
| **2.D Non-pausing UI** (M) | Sonnet | the six pausing panels, `game_menu.gd`, `tab_build.gd` | D-MP8 via `Session.pause_local()`; buff/nourishment ticking under an open panel in a session recorded as intended. `test_panels_pause_only_when_solo.gd`, `smoke_net_menu_does_not_freeze_peer.gd`, `smoke_menu`, `smoke_post_modal_control`, `smoke_modal_stacking` green. Lands after 2.B's tab so the two never touch `game_menu.gd` concurrently. |
| **2.E Local-rig world wiring** (S) | Sonnet | `grass_field.gd` bind, scatter collision streaming call, `world_weather.gd`, `world_perimeter.gd`, `minimap.gd`, `structure_visibility_range.gd` | Everything camera- or player-keyed reads the local rig; no solo behaviour change. |

Exit: two people on a LAN see each other walk around the Meadows; a menu on one does not freeze
the other; host quits and both return to title with saves intact; a client never writes a world file.

### Wave 3 — Player/world verbs (M3)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **3.A WorldLedger** (L) | Opus | new `scripts/net/world_ledger.gd` (pure), `scripts/net/ledger_rpc.gd`, `world_state.gd` apply-delta, `realm` on every record | D-MP9. Intents: `claim_pickup`, `harvest`, `deplete_vegetation`, `place_building`, `dismantle`, `storage_txn(expected_revision)`, `set_world_flag`, `grant_player_flag(peer)`, `transfer_item`, `drop_item`, `reward_grant`. Host validates, commits, broadcasts deltas; clients apply and re-run `restore_progression_from_game`; solo path in-process. `test_world_ledger_races.gd` with deterministic interleavings (two claims on one pickup, two withdrawals of one stack, double gather, stale-revision storage write) — each seen red first. |
| **3.B Pickups + harvest** (M) | Sonnet | `item_cache_pickup.gd`, `key_pickup.gd`, `tm_pickup.gd`, `harvest_node.gd`, `vegetation_harvest_point.gd`, `felled_resource.gd`, `vegetation.gd` sync, `band_pickups.gd` keys | Shared/first-come pickups; yield to the gatherer; removal replicated. `smoke_net_pickup_race.gd`, `smoke_net_gather_no_duplication.gd`, `test_harvest`, `smoke_pickup_glow_lifecycle` green. |
| **3.C Building + satchels** (M) | Sonnet | `build_placer.gd`, `scripts/world/player_death.gd` drop path, `scripts/world/death_satchel.gd` (owner tag) | Placement replicated via the authored spawner; **client-placed structures survive host save + reload + late join**; satchel owner tag. `smoke_net_shared_building.gd` (with the reload half), `smoke_gate_a_build_house` green. |
| **3.D Storage consumers** (S) | Sonnet | `scripts/world/storage_state.gd`, `storage_container.gd`, `storage_panel.gd` | Versioned deposits/withdrawals through 3.A's `storage_txn`; friends use each other's chests. `smoke_net_storage_concurrency.gd`. |
| **3.E Item trading** (M) | Sonnet | `tab_backpack.gd` offer flow, new `scripts/world/dropped_item.gd` | D-MP13. `smoke_net_trade.gd` (offer/accept; drop/pick up; disconnect mid-offer duplicates nothing). |
| **3.F Movement sync + validation** (M) | Sonnet | synchronizer config on `remote_trainer.tscn`, `scripts/net/movement_validator.gd` | Sync set (position, yaw, anim, sprint, carried, fly state), interpolation, host speed/heightfield check with tolerances fixed in the brief. `test_movement_validator.gd`. |

Exit: two players gather, build a camp, share a chest and trade; the ledger tests prove no
duplication under races; the desync detector stays quiet through every Wave 3 smoke.

### Wave 4 — Creatures and combat (M4)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **4.A Encounter protocol spec** (M) | **Fable** | `docs/specs/MP_ENCOUNTER_PROTOCOL.md`, D-MP12 table in `multiplayer.json` | Encounter record (id, realm, opponent, participants, authoritative HP, phase); intents `engage`, `strike_intent(move, origin, facing)`, `catch_attempt(launch params)`, `switch`, `disengage`; validation tolerances; join-in-progress; opponent targeting among participants; friendly-fire rejection; `reward_grant` per participant; tournament and Warden rules; scaling by composition. |
| **4.B Creature ownership + host bodies** (L) | Opus | `encounter_director.gd` (summon/dismiss/streaming), `follower_creature.gd`, `creature_body.gd` (kinematic heightfield mode), `creature.tscn` spawner, `playground_hud.gd` minimap read | Deployed creatures spawned by the host with the owner's authority set before tree entry; remotes interpolate; followers follow their own trainer; `"AllyCreature"` → per-owner naming; cluster streaming keyed on the union of realm occupants; host bodies in heightfield mode. `smoke_net_deploy_two_creatures.gd`, `smoke_creature_control`, `smoke_wild_streaming`, `smoke_aggression`, `smoke_cloudreach_wild_leash` green. |
| **4.C Encounter core + catch arbitration** (L) | Opus | `combat_manager.gd`, `encounter_director.gd` fight paths, `throw_aim.gd` launch hand-off, new `scripts/net/encounter_host.gd`, `scripts/net/catch_arbiter.gd` (pure) | D-MP2 + 4.A. Host-simulated opponent; validated strikes with host RNG; enemy strikes resolved on the host against replicated creature positions; friendly fire rejected; join-in-progress; catch re-derived and rolled on the host, first committed catch owns, loser told why. `test_encounter_host_rejects_friendly_strike.gd`, `test_catch_arbitration.gd` (two simultaneous attempts → exactly one owner), `smoke_net_shared_wild_fight.gd`, `smoke_net_friendly_fire_is_zero.gd`, `smoke_net_catch_race.gd`; `smoke_combat`, `smoke_combat_camera`, `smoke_arena_contain`, `smoke_catching`, `smoke_catch_retry`, `smoke_party_count_after_catches` green; **`smoke_combat_baseline` solo numbers within a stated tolerance of the pre-wave numbers**. |
| **4.D Trainers, bosses, tournament, per-player rewards** (M) | Opus (serialized after 4.C) | trainer paths in `encounter_director.gd`, `trainer_npc.gd`, `tournament.gd`, `stronghold_climax.gd`, Cloudreach captains/finale controller | World defeat flag once; `reward_grant` to each participant; multi-pilot Warden. `smoke_net_shared_trainer_fight.gd`, `smoke_net_shared_boss.gd`, `smoke_net_boss_rewards_each_participant.gd`; `smoke_trainer_battle`, `smoke_tournament_bracket`, `smoke_boss`, `smoke_gate_e_finale`, `smoke_cloudreach_finale` green. |
| **4.E Downed / revive** (M) | Sonnet | `player_controller.gd` death signal path (bounded), `player_vitals.gd`, new `scripts/player/downed_state.gd`, `multiplayer.json` window | D-MP10. `smoke_net_revive.gd`, `smoke_net_death_does_not_reset_encounter.gd`, `smoke_net_satchel_is_owners.gd`; `smoke_unstick` and fall-death solo regression. |
| **4.F Scaling data + baseline** (S) | Sonnet | `multiplayer.json` `scaling`, `smoke_combat_baseline.gd` participant variant | Fable's table applied; measured danger at 1/2/4 participants recorded as W23 did. |

Exit: two players fight one wild together, race a catch and only one owns it, beat a trainer and
both get their reward, one goes down and the other revives them; solo combat numbers unchanged.

### Wave 5 — Shared progression (M5)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **5.A Story triggers and dialogue in a session** (L) | Opus | `sequence_director.gd`, `dialogue_panel.gd` effects drain, `trainer_npc.gd` prompt/relabel, gate/bridge/relay/shrine restore paths | Dialogue is local; its effects commit through the ledger; `_refresh_lockout` locks only the local rig; world deltas re-run `restore_progression_from_game` on every peer. **A behind-progress character joins a post-boss world and can act at once** (rule 3). `smoke_net_gate_opens_for_both.gd`, `smoke_net_behind_character_joins_ahead_world.gd`; `smoke_opening`, `smoke_relay`, `smoke_stronghold`, `smoke_cloudreach_act_one` green. |
| **5.B Realm Hearts** (S) | Sonnet | `realm_heart_shrine.gd`, Heart `place()` via ledger `set_world_flag` | Earned/placed world through the ledger; active per player; two peers with different powers. `smoke_net_hearts.gd`. |
| **5.C Map, fog, alpha pins, quest scopes** (M) | Sonnet | `map_state.gd` per player, `alpha_pins.gd`, `tab_map.gd`, `quest_log.gd` | Fog personal; alpha pin discovery personal, clear world-driven; joining reveals nothing of the host's map. `smoke_net_fog_is_personal.gd`, `smoke_alpha_pins`, `smoke_gate_a_map_cycle` green. |
| **5.D Sleep vote** (M) | Sonnet | `night_rest.gd`, `player_bed.gd`, `creature_bed.gd` rests; consumes 2.A's clock contract | D-MP11. `smoke_net_sleep_vote.gd`, `smoke_home_sleep`, `smoke_clock_survives_a_reload`, `smoke_night_ecology` green. |

Exit: shared main story advances once for the world; personal maps and tutorials stay personal;
night falls when everyone sleeps; a late character is not locked out.

### Wave 6 — Travel and multi-realm (M6)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **6.A Realm shells and transitions** (L) | Opus | `Game.enter_realm()`, `Session/Realms`, simulation-only mode in both world roots, per-realm spawners and synchronizer visibility, despawn-before-swap | D-MP3. A client swaps its world scene without leaving the session (host despawns it for others first); the host hosts a headless shell for any occupied realm it is not in; replication is realm-scoped. `smoke_net_split_realms.gd` (host Meadows, client Cloudreach, both fight and gather, then swap), `smoke_net_realm_owner_disconnect_mid_fight.gd`, `smoke_cloudreach_transition`, `smoke_meadows_realm_handoff` green; shell memory/tick cost recorded against S2. |
| **6.B Riding replication** (M) | Sonnet | `riding_controller.gd`, remote mount visuals | Rider visible on the mount for remotes; mount ownership; **peer B gathers and fights during peer A's ride**. `smoke_net_riding.gd`, `smoke_riding`, `smoke_riding_saddle` green. |
| **6.C Fly replication** (M) | Sonnet | `fly_controller.gd` state sync, carrier creature sync, landing-anchor validation | Same concurrent-actor rule. `smoke_net_fly.gd`, `smoke_fly_traversal`, `smoke_environment_velocity`, `smoke_cloudreach_continuous` green. |
| **6.D Presentation on remote bodies** (S) | Sonnet | VFX hooks (`_flash_at`, level-up flourish), `companion_presence.gd`, `world_audio.gd` | Hits, KO puffs, catch sparkle, level-up and companion reactions on remote creatures. `smoke_vfx_lifecycle`; code-blind judge on a 2-peer capture sheet. |
| **6.E Cloudreach runtimes, farming, camps** (M) | Sonnet | `cloudreach_physical_runtime.gd`, `cloudreach_chapter.gd`, `rest_point.gd`, `farm_*`, `home_progress.gd` | All remaining world mutations through the ledger. Cloudreach smoke shard green. |

Exit: rule 16 met — players in different biomes at the same time — and a shell survives a
client's disconnect mid-fight.

### Wave 7 — Reliability and shipping (M7)

| Lane | Tier | Owns | Deliverable / evidence |
|---|---|---|---|
| **7.A Late join, reconnect, host exit, portability, jitter, 3/4 peers** (L) | Opus | `Session` snapshot/diff, harness 3/4-peer mode | Snapshot completeness proven by diffing a late joiner's world hash against the host's; reconnect restores the character from its own file plus world delta; **a character carries items and a creature into a second world and that world's flags are untouched**; host exit under load; `smoke_net_shared_wild_fight` and `smoke_net_catch_race` pass under 150 ms delay / 30 ms jitter. `smoke_net_three_peer_session.gd`, `smoke_net_four_peer_session.gd` (nightly/owner kit), `smoke_net_late_join_modified_world.gd`, `smoke_net_reconnect_keeps_character.gd`, `smoke_net_character_joins_second_world.gd`. |
| **7.B Solo regression + performance** (M) | Sonnet | `run_all_smokes.sh` sweep, `tools/perf_render_stats.gd` stands | All 149 smokes on the wave head with the summary committed; draw calls at `band1_open` with 4 trainers + 4 creatures against the 7,500 budget; host tick cost with 4 peers from the harness. |
| **7.C Owner kit + acceptance template** (S) | Sonnet (+ Haiku template) | `tools/owner/MULTIPLAYER_KICKOFF.cmd` + `.ps1`, `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` | One double-click launches a host plus three windowed clients on one PC, or a host on the Ally joined from a PC, and writes `fps.json` on the host; the template is the directive's §17 twenty-four items plus an **owner-measured Ally frame-time cell** and the §21 list, one evidence cell each. |
| **7.D Stage B acceptance** | **Fable** | `docs/CURRENT_STATE.md`, `docs/DEVELOPMENT_ROADMAP.md` | Reads every net smoke run and the owner's LAN evidence; fills the template; moves the roadmap to Stage C only when an outside tester has hosted, been joined by three, fought, gathered, built, progressed, saved and reconnected without developer help. |

---

## 6. Sequencing and parallelism

```
W0  0.B ∥ 0.C ∥ 0.D ∥ 0.E  ──▶  0.F (after 0.E)  ──▶  0.A lands
W1  1.A (Haiku data) ──▶ 1.B (Opus) ──▶ 1.C (Opus) ──▶ 1.D
W2  2.A (Opus) ──▶ 2.C (Opus) ──▶ 2.B ──▶ 2.D ; 2.E ∥ 2.B
W3  3.A (Opus) ──▶ 3.B ∥ 3.C ∥ 3.D ∥ 3.E ∥ 3.F
W4  4.A (Fable) ──▶ 4.B (Opus) ──▶ 4.C (Opus) ──▶ 4.D (Opus) ; 4.E ∥ 4.F after 4.C
W5  5.A (Opus) ──▶ 5.B ∥ 5.C ∥ 5.D
W6  6.A (Opus) ──▶ 6.B ∥ 6.C ∥ 6.D ∥ 6.E
W7  7.A (Opus) ──▶ 7.B ∥ 7.C ──▶ 7.D (Fable)
```

- Parallel lanes in one wave own disjoint files by construction (listed above); 2.B/2.D and
  4.C/4.D are serialized precisely because they would not.
- One Godot render at a time on the box; the harness runs headless peers only; 3/4-peer runs
  are budgeted from S2 and never on PR CI.
- Each wave re-verifies integrated `main` before the next wave branches (directive §22).
- Anti-grind: two no-yield attempts on one narrow net defect → record, reframe, hand to a fresh
  bounded lane; a wave-blocking P0 still must be solved, by a different method.

---

## 7. Verification

**CI is the gate.** A lane proves its own change; the shards prove the rest. Rewritten
2026-09-06 on the owner's instruction after Wave 1 spent real time on sampling that could not
have changed a decision.

**Per lane:** the unit tests the change touches (`--only=`), **three to six** smokes chosen for
what the change actually reaches, and for a net lane its own `smoke_net_*`. Add
`smoke_playground` only when the change touches world, spawn, creature or encounter code (the
rule `AGENT_WORKFLOW.md` §6 already states), and read its `^ERROR:` set once — no repeat
sampling. A new **`smoke_net_*` keeps its negative control** (run against the previous wave's
head, must fail there): that is the one check that catches a green which proves nothing, and it
costs one run. New unit tests are still seen red once on a deliberate break. Tolerances are
numbers in the brief before implementation. Fable reproduces one claim per lane, not all of them.

**Per wave (the PR):** full CI, code jobs confirmed to have run. That is the bar. Add the full
unit suite only when the wave changed `game_state.gd`, a save format or a flag scope.

**Not evidence, do not chase:** engine exit-time notices (`resources still in use at exit`,
leaked `ObjectDB` instances, RID allocations at exit) print after the game has run and cannot
reach a player. Record one line if a new one appears; never sample runs to compare their
frequency. Likewise a smoke that fails identically on the lane's base is a routed finding in one
sentence, not an investigation.

**The full 151-smoke sweep runs once per STAGE, not per wave** (`ralph/reports/MP-W0-SMOKE-SWEEP-0906/`
is Stage B's). Its purpose is to find the ~104 smokes CI never runs and tell Stage C which are
dead, slow or already broken — a census, not a gate.

**Stage exit (directive §17, §21, §23):** every minimum-experience item has a named smoke:

| §17 item | Smoke / test |
|---|---|
| 1 host/load · 2 join up to three · 21 reconnect · 22 late join · 23 solo host · 24 host exits safely | `smoke_net_host_join_leave`, `smoke_net_three_peer_session`, `smoke_net_four_peer_session`, `smoke_net_reconnect_keeps_character`, `smoke_net_late_join_modified_world`, `smoke_net_host_exit_saves`, `smoke_playground` (`is_server()`), every solo smoke |
| 3 move and see each other | `smoke_net_movement_two_peers` |
| 4 deploy/control own creatures · 5 shared wild fight · 6 first-catch rule · 7 trainer together · 8 boss together · friendly fire · per-player rewards | `smoke_net_deploy_two_creatures`, `smoke_net_shared_wild_fight`, `smoke_net_catch_race`, `smoke_net_shared_trainer_fight`, `smoke_net_shared_boss`, `smoke_net_friendly_fire_is_zero`, `smoke_net_boss_rewards_each_participant` |
| 9 gather without duplication · 10 shared pickups · 11 shared structures (incl. reload) · 12 shared storage · 13 trade | `smoke_net_gather_no_duplication`, `smoke_net_pickup_race`, `smoke_net_shared_building`, `smoke_net_storage_concurrency`, `smoke_net_trade` |
| 14 down/revive · 15 sleep · 16 menus don't freeze others · satchel personal | `smoke_net_revive`, `smoke_net_death_does_not_reset_encounter`, `smoke_net_sleep_vote`, `smoke_net_menu_does_not_freeze_peer`, `smoke_net_satchel_is_owners` |
| 17 ride and Fly while others act · 18 independent transitions · 19 different biomes at once · owner disconnect | `smoke_net_riding`, `smoke_net_fly`, `smoke_net_split_realms`, `smoke_net_realm_owner_disconnect_mid_fight` |
| 20 world save + portable characters · join a farther-ahead world · portable across worlds | `test_world_save_format`, `test_character_save_format`, `test_legacy_slot_split_never_touches_the_original`, `test_split_key_coverage_equals_v22`, `smoke_net_behind_character_joins_ahead_world`, `smoke_net_character_joins_second_world` |
| latency/jitter · target hardware | 7.A's jittered runs; the owner kit's `fps.json` and the Ally frame-time cell |

Plus the human half the directive's exit names: the owner runs `MULTIPLAYER_KICKOFF.cmd`, and at
least one session where an outside tester hosts and three join over a LAN, recorded in
`docs/owner/` like a playtest. Stage B is done when the template reads PASS on every row, solo
Meadows and Cloudreach still play end to end, and everything is on `main`.

---

## 8. What this plan deliberately does not do

- No host migration, dedicated servers, Steam/relay transport, voice, PvP, or creature trading
  (directive rules 11, 12, 18).
- No split-screen; no second local player in one process.
- No rewrite of the pure modules (`inventory`, `party`, `creature_instance`, `catch_math`,
  `combat_math`); they are re-homed and wrapped, not replaced.
- No new creature meshes, no Meshy, no visual work beyond making existing VFX render on remote
  bodies; the visual bar is Stage C's.
- No Biome 3 work.

---

## 9. Carry-overs for Stage C (recorded during Stage B)

- **Smoke consolidation.** `tests/` holds 151 `smoke_*.gd` (2026-09-06): 76 boot the full Meadows
  world, 37 are Cloudreach-specific, 51 are per-incident regression pins carrying an owner-report
  id, and only 47 run in CI — which is how Cloudreach shipped unbuildable on `main`. They test
  real behaviour and should not be culled during Stage B; the Wave 0 sweep
  (`ralph/reports/MP-W0-SMOKE-SWEEP-0906/`) gives each one's duration and verdict. Stage C/D
  folds the per-incident pins into per-system smokes on the `smoke_playground` model (one boot,
  many checks), targeting 30–40 files all gating in CI.
