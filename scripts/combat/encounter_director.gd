extends Node

## Everything around a fight that is not the fight: spawning the wild creature,
## offering the engage prompt, suspending exploration, and putting the world
## back afterwards.
##
## Split from CombatManager on purpose. The manager knows how a fight resolves
## and nothing about the world it happens in; this knows about the world and
## nothing about damage. M3 adds catching to the manager and M4 adds a party,
## and neither should have to touch spawn placement or the interact prompt.
##
## Split from the playground world too, which is about terrain. This node can be
## dropped into the real Meadows scene unchanged.

const MATH := preload("res://scripts/combat/combat_math.gd")
const PERF_TRACE := preload("res://scripts/world/perf_trace.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
## D30: wild creatures spawn inside a level band rather than at one fixed level.
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
## GATEC-CURVE: which level band that spawn's REGION rolls in. `PROGRESSION`'s
## own `level.wild_band` is one global band for the whole 7.5km corridor and
## stays the fallback for callers with no position; this decides the band from
## where the cluster actually stands.
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
## OF27: the shiny roll's odds. A pure data reader, same static-cache shape as
## PROGRESSION/MATH/CATCH above, so this stays a one-line addition to the
## existing config-loading pattern rather than a new one.
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const BUILD_HOLD := preload("res://scripts/build/build_hold.gd")
## R8.1: the trainer table's own reader. `trainer_npc.gd` places the people;
## this only ever asks it for numbers and teams.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
## WORLD-LIFE-0903. Pure `RefCounted`, offline-constructible (no live
## Terrain3D needed -- see its own header), so this is safe to build in the
## unit suite too. Used only for `path_factor()`'s road query below.
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
## OP21-03/OP21-06: shared input-ownership answer, the same one
## `playground_hud.gd::_world_input_allowed()` already asks. Without this,
## `_read_creature_control_input()` read the party-cycle action
## unconditionally whenever no fight/trainer-round/arbiter gate applied — and
## those actions are bound to gamepad d-pad left/right (project.godot,
## joypad buttons 13/14), the same physical d-pad `ui_left`/`ui_right` drive
## Build menu grid focus with. Build deliberately does not pause the tree
## (OW10), so one d-pad press both navigated Build and cycled the active
## creature underneath it — the owner's exact repro.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
## Mirrors CombatManager.OUTCOME_CAUGHT. Declared rather than typed twice so a
## renamed outcome cannot silently stop matching here.
const CAUGHT := "caught"
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
## creature.tscn carries no script; one body shape serves both roles and the script
## is chosen here. The alternative is two near-identical scenes, which means
## M11's real creature model has to be wired into the game twice.
const WILD_SCRIPT := preload("res://scripts/creatures/wild_creature.gd")
## The player's own creature walks around the world now instead of appearing for a
## fight, so it gets the follower subclass rather than the bare body.
const FOLLOWER_SCRIPT := preload("res://scripts/creatures/follower_creature.gd")
## Stage B lane 4.B: the replicated proxy every OTHER peer draws for a deployed
## creature, and the outbound proxy its owner pushes state through. Its own
## header carries the ownership rules.
const REMOTE_CREATURE_SCRIPT := preload("res://scripts/creatures/remote_creature.gd")
## Stage B lane 4.C. The two pure arbiters this node is the transport for --
## `ledger_rpc.gd` is to `world_ledger.gd` exactly what this node is to these.
## No rule from either file is repeated here: if a refusal reason lives in two
## files, the two files eventually disagree.
const ENCOUNTER_HOST_SCRIPT := preload("res://scripts/net/encounter_host.gd")
const CATCH_ARBITER_SCRIPT := preload("res://scripts/net/catch_arbiter.gd")
## Lane 4.D. What a beaten trainer owes, as plain intents -- pure, so the
## arithmetic (and above all the division that does NOT happen) is asserted
## against no world at all in `tests/test_encounter_rewards.gd`.
const ENCOUNTER_REWARDS := preload("res://scripts/net/encounter_rewards.gd")
## For `host_move_profile()` only -- the ONE copy of what a move reaches, so the
## host rebuilding a peer's named move cannot disagree with what that peer's own
## manager built for itself.
const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const OPENING_CONFIG := "res://data/config/opening.json"

## Where lane 2.A mounts the session: a `Node` child of the `Game` autoload
## (the one-autoload rule). Identical in every process, which is what makes
## this node's RPCs resolve at all -- `EncounterDirector` sits at the same
## path under the world scene on every peer.
const SESSION_PATH := ^"/root/Game/Session"
## D95's reliable channel. Declared here rather than imported from
## `scripts/net/session.gd` because that file belongs to another lane; the
## number is the wire contract, and a mismatch is a dropped intent.
const CHANNEL_LEDGER := 1
## D97's authored spawn container for creature bodies, relative to the world
## scene root. Authored in `meadows_playground.tscn` and
## `cloudreach_cliffs.tscn`, never built here, so a spawn that arrives while a
## peer is still running its procedural world build finds a `spawn_path` that
## already exists.
const CREATURE_SPAWNER_PATH := ^"Spawned/CreatureSpawner"

signal prompt_changed(text: String)

## The creature the player starts the SANDBOX with.
##
## This was `const STARTER_SPECIES := "terrapup"`, which meant the player's creature
## was decided in code and the starter choice had nowhere to attach. It is a
## sandbox convenience now and nothing else: `meadows_playground.tscn` is the
## combat testbed and five smoke tests need something to fight with the moment
## they boot.
##
## The real game does not use it. `scripts/story/sequence_director.gd` calls
## `suspend_default_starter()` before this node spawns anything, and the creature the
## player actually owns arrives through `adopt_starter()` — chosen by walking up
## to one of three creatures, and named.
@export var default_starter: String = "terrapup"

## The wild population lives in data, not here. Which species, how many, where
## they cluster and how fast they come back are exactly the numbers the owner
## will want to retune after walking the meadow, and every one of them should be
## an edit to this file rather than to code.
const SPAWNS_CONFIG := "res://data/config/spawns.json"

## BAND-SPLIT. The `spawns` array itself is cut per corridor band under
## `data/config/bands/<band>/spawns.json`; `SPAWNS_CONFIG` now holds only
## `respawn_seconds` and `roles`. `band_content.gd` merges them back, and the
## merged array is identical to the pre-split one.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## T3-ENCOUNTER. The weighted tables the ROLLED half of the population draws
## from, and the pure function that turns them into a plan. Owner directive,
## 2026-08-30: "We should build the new encounter system that spawns the
## creatures randomly, but some of the alphas and such will always get placed in
## the same spots as that's part of the storyline."
##
## Reused rather than paralleled, per CLAUDE.md: this is the same director, the
## same spawn table, the same alpha/elder/gate/cooldown machinery. The only new
## idea is that an entry may name a `table` instead of committing to its own
## species -- and an entry that does not is an ANCHOR, untouched, which is every
## entry that carries authored design (see `_spawn_plan`).
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")

## Fallback if spawns.json is missing or does not give respawn_seconds. Matches
## the file's own value rather than M2's old 6.0: with a whole meadow of
## creatures there is always another fight to walk to, so a beaten one staying
## down for a while reads as consequence rather than as a locked door.
const DEFAULT_RESPAWN_DELAY := 45.0

@export var player_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath

var _player: CharacterBody3D = null
var _manager: Node = null
var _camera_rig: Node = null
var _wild_creatures: Array[Node3D] = []
var _engaged_with: Node3D = null
var _ally_body: Node3D = null
var _ally: RefCounted = null

## --- Stage B lane 4.B: one deployed creature PER OWNER -----------------------
##
## `_ally_body` above is still exactly what it was: the body THIS process
## pilots, built locally, driven by `follower_creature.gd`, untouched by the
## session. Solo therefore plays byte-for-byte as it did.
##
## What is new is that in a live multi-peer session every peer's deployed
## creature also gets a REPLICATED PROXY, spawned by the host through D97's
## authored `CreatureSpawner` with the owner's authority set inside the spawn
## function. On the owner that proxy is invisible and pushes the local body's
## transform onto the wire; on everyone else it is the body they actually see.
## That is lane 2.C's trainer shape (`scripts/net/trainer_spawn.gd`), applied
## to creatures rather than a second design.
##
## Nothing here runs at all until a second peer is in the session.
var _session: Node = null
var _creature_spawner: MultiplayerSpawner = null
## peer id -> the proxy node standing for that peer's deployed creature. Host
## side only; a client receives its copies through the spawner and never
## indexes them here.
var _creature_proxies: Dictionary = {}
## HOST TRUTH: peer id -> {species_id, shiny, character_id} for every peer that
## currently has a creature out. The host is the only process that holds this,
## and it is what a late joiner's proxies are rebuilt from.
var _deployed_by: Dictionary = {}

## --- Stage B lane 4.C: the encounter, and who decides it ---------------------
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md`. Two players fight one opponent
## together, the host decides every outcome, and exactly one player can win a
## catch.
##
## HOST ONLY: the two arbiters. Both are pure `RefCounted`s that never touch the
## tree, `multiplayer` or `Game`, which is what lets
## `tests/test_encounter_host_rejects_friendly_strike.gd` and
## `tests/test_catch_arbitration.gd` prove the two rules that matter with no
## networking at all. They are constructed on every peer and simply never
## consulted off the host -- a null check per call would be a second way to ask
## "am I the host" and the answer to that question has exactly one home
## (`_is_host()`).
var _encounter_host: RefCounted = null
var _catch_arbiter: RefCounted = null

## THIS peer's live fight: the record it is rendering. On the host it is the
## same Dictionary the arbiter holds; on a client it is the last copy the host
## broadcast. Empty when this peer is not in a networked fight.
var _encounter: Dictionary = {}

## Host-side: how long since the opponent's position was last sampled into the
## record (§5 step 3's history). Sampling every physics frame would put 60
## entries a second into a 250 ms window for no accuracy the connect test can
## use; a sample every other frame covers the window with ~7 entries.
var _encounter_sample_countdown: int = 0

## Host-side: the peer whose catch is currently being performed, so §8 step 4
## can tell everybody ELSE who got it.
var _catch_claimant: int = 0
## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2. Resolved once in `_ready()` for
## `_scatter_clear_spot()`'s spawn-siting check. `Vegetation` is a runtime
## child `playground_world.gd::_dress_the_meadow()` adds by name, not a saved
## scene node, so this is a lookup rather than an `@export`ed NodePath -- see
## that function's own comment. Left null harmlessly on any world/test rig
## that never dresses a meadow (`has_solid_scatter_near` is simply never
## asked).
var _vegetation: Node = null

## WORLD-LIFE-0903. Built lazily by `_wander_target_clear_of_road()`, once,
## and reused for the life of this director -- `HEIGHTFIELD.new()` parses the
## whole terrain config, which is wasted work to repeat per wander tick.
var _road_field: RefCounted = null

var _engage_range: float = 6.0
var _prompt: String = ""

## `CO1`. The last `Game.party.revision` `_sync_active_creature()` acted on, so a
## party-screen re-activation is caught exactly once instead of every frame.
var _party_revision_seen: int = -1

## Set when the scene has an InteractionArbiter to hand the prompt line to.
##
## Null in the combat sandbox, where this node is the only thing in the world
## with anything to say and owning the line outright costs nothing. In the
## opening scene Grandpa and three starters want the same line, so the decision
## moves out to the arbiter and this becomes one voice among several.
var _arbiter: Node = null

## Creatures waiting on their faint to clear, and on their respawn. Keyed by node, so
## two creatures can be knocked out at once without one cancelling the other's
## timer — which is the bug a single shared `_respawn_left` would have.
var _faint_timers: Dictionary = {}
var _respawn_timers: Dictionary = {}

## R5.3: which wild nodes are conditionally present. Keyed by node, holding
## whichever of spawns.json's `time`/`weather` fields that entry carried;
## a wild with no entry here is unconditional, exactly like every spawn
## before this item. Kept separate from `_wild_creatures` (which is every
## wild, gated or not) so `_sync_spawn_gates()` only iterates the ones that
## actually need a check.
var _wild_gates: Dictionary = {}

## T3-CREATURES. Per-creature respawn cooldown in seconds, for the wilds whose
## spawns.json entry names one. Keyed by node exactly like `_wild_gates`, and
## absent for every ordinary creature -- which is all 881 of them that existed
## before the owner's creature-expansion brief, so the default path is
## untouched.
##
## The brief's Spawn Protection Rules ask for "cooldowns after rare variant
## spawns", and this is the ONE protection on that list the build did not
## already have. Habitat, weather, time-of-day and geographic restriction are
## all just where an entry is authored plus the `time`/`weather` gate that
## already existed; a "weighted spawn table" has nothing to weight, because
## this director does not ROLL a species -- every cluster names its own, so
## rarity here is headcount, not probability (the reasoning is in
## ralph/reports/handover-T3-CREATURES-2026-08-30.md). What genuinely could not
## be expressed was "the one Nightburrow in the Meadows comes back on the same
## 45-second timer as a Mudsnout", which would turn an apex encounter into a
## farmable resource within a minute of beating it.
var _wild_respawn: Dictionary = {}

## WARRENS-ONCE. Wild node -> progression flag id, for the bodies this
## director must never bring back once they leave the field the honest way
## (beaten, caught, or freed). Populated only for a spawn that named one:
## a band's `alpha`/`elder` entry (`_spawn_creatures()`, keyed off the
## entry's own unique `order`) or a caller of `spawn_wild()` that passed an
## explicit `once_id` in `opts` (`burrow_warrens.gd`'s guardian and its
## nicknamed residents). An ordinary wild is never in this map, so nothing
## here changes the respawn/faint machinery for the meadow's population.
var _once_only: Dictionary = {}

## --- STREAM-D: distance-based activation ------------------------------------
##
## The owner has directed wild density up from ~70 to roughly 700-1100 across
## the chapter (`archive/ralph/DONE.md` carries the exact wording). Two things do not
## scale to that: `_spawn_creatures()` below instantiates and never despawns
## anything, and `wild_creature.gd`'s `_physics_process()` ticks
## unconditionally regardless of distance. This is the fix for the second one
## -- the first is deliberately NOT touched here (see `_tick_streaming()`'s
## own header for why boot cost is a smaller, separate problem this pass
## leaves alone).
##
## One entry per `spawns.json` CLUSTER (matching the seeded-scatter loop in
## `_spawn_creatures()` one-for-one), not per creature: `centre`/`radius`
## already exist for each entry, so checking against those scales with band
## count rather than population -- the same reasoning the task itself names.
## Keys: `centre` (Vector3), `radius` (float), `members` (Array[Node3D]),
## `active` (bool, the last activation state this cluster's members were set
## to, so `_tick_streaming()` only touches a cluster's members on an actual
## transition instead of every member every frame).
var _clusters: Array[Dictionary] = []

## O(1) member -> cluster lookup, built alongside `_clusters` in
## `_spawn_creatures()`. Needed by `_tick_respawn()`: a creature that just
## `revive_at_home()`d turns its own physics_process back on regardless of
## streaming state (that call is older than this feature and rightly does not
## know about it), and without this lookup a revived creature whose cluster
## is still far away would stay awake until the NEXT cluster-level distance
## transition happened to fire -- which might be never, if the player never
## approaches or leaves that exact cluster again. A hand-placed creature
## (`spawn_wild()`) has no entry here, and `.get(wild, {})` reads that as "not
## streamed", which is correct: hand-placed creatures are never deactivated.
var _wild_cluster: Dictionary = {}

## Cached result of `_activation_radius_margin()`. Negative means "not yet
## computed" -- 0 is a value the config could plausibly produce and would
## wrongly look uncached forever.
var _activation_margin: float = -1.0

## --- R8.1: trainer battles -------------------------------------------------
##
## A trainer battle is not a second combat system. It is the SAME fight this
## node already runs against a wild creature, entered from a person instead of
## from a prompt on an animal, with three differences: the opponent's creature
## belongs to somebody (so it cannot be caught), there can be several of them
## in a row (so the fight re-opens against the next one rather than ending),
## and beating the last of them writes a progression flag (so it cannot be
## fought again into an XP faucet).
##
## Everything else — the arena, the camera, piloting, switching, XP, the
## fainted body on the ground — is `combat_manager.gd` and is untouched. That
## is deliberate: spec §12 wants 12-17 of these across the chapter, and a
## parallel fight loop would be 12-17 chances for the two to drift.

## The trainers.json entry being fought right now, or {} between battles.
## This, not `_manager.is_fighting()`, is what "a trainer battle is happening"
## means — it stays true across the beat between one of their creatures
## falling and the next stepping up, which is a gap the fight itself is not
## running in.
var _trainer_spec: Dictionary = {}
## The NPC who issued the challenge; their creatures are sent out from beside
## them. Null is legal (a battle started by a test or a tool), in which case
## the opponent is placed relative to the player instead.
var _trainer_node: Node3D = null
## Their team, minus whoever has already been sent out. Instances, built once
## at the start of the battle so a creature's damage is not undone by it being
## rebuilt.
var _trainer_queue: Array[RefCounted] = []
## The opponent body currently on the field.
var _trainer_body: Node3D = null
## Bodies waiting to be cleared: the ones that have fallen, and — once the
## battle is over — whichever was still standing.
var _trainer_fallen: Array[Node3D] = []
## Seconds until the next creature is sent out, and (after the battle) until
## the bodies are freed. Only one of the two ever runs at a time.
var _trainer_send_delay: float = 0.0
var _trainer_cleanup_delay: float = 0.0
## How many of their creatures have been sent out, ever. Names the bodies; see
## `_send_out_next_creature()` for why it is not derived from a list that empties.
var _trainer_sent: int = 0

## T3-COMBAT. Where the trainer was standing when this battle was accepted, and
## where every round of it re-forms from.
##
## A trainer battle is ONE encounter that happens to have several creatures in
## it, but `combat_manager.begin()` is called once per creature and has no idea
## the previous round existed. Its `_place_fighters()` anchors both fighters off
## `_player.global_position`, and `_stand_the_trainer_aside()` at the end of that
## same call MOVES the player — about 3.9m forward and 6.05m to the side with the
## shipped `arena` block, roughly 7.2m per round. So round two anchored off where
## round one had left the trainer, round three off round two, and the fight
## walked out of the room it started in.
##
## Five rounds of that is what put the Warden's creatures ~5.6m under the Warden
## Arena's floor: out past the slab, `built_floor.gd`'s deliberately generous
## 10m claim margin still answers the room's floor height, so `place_on_ground()`
## sets the body down on a floor that has no collider under it and
## `creature_body._physics_process()` — which grounds on `is_on_floor()`, not on
## the claim — drops it to the terrain below. Found and diagnosed by T2-FLAKE
## (`ralph/reports/handover-T2-FLAKE-2026-08-30.md` §5).
##
## The margin is NOT the bug and must not be widened again; the drift is. This
## anchor removes it by giving every round of a battle the same starting point,
## which is also what the player sees: the arena stays where they accepted the
## challenge instead of creeping across the room between creatures.
var _trainer_battle_anchor: Vector3 = Vector3.ZERO
var _has_trainer_battle_anchor: bool = false

## Stage B Wave 4 lane 4.D. WHO FOUGHT THIS TRAINER -- every peer that has been
## in this battle's encounter record at any point since it began, host included.
##
## FINDING, recorded at the code rather than only in a report:
## `combat_manager.gd::_finish()` submits `disengage` at the end of EVERY round,
## which is right for a wild fight and is also what happens between two of a
## trainer's creatures. So "who is in the record right now", asked at the moment
## the last creature falls, is very nearly nobody -- the winner has just left it.
## The accumulated set is the honest answer to "who fought this trainer", it is
## what §7 means by "every participant", and it is what gets paid.
##
## Also §6's "arriving late costs nothing": a peer that joined for the ace alone
## is in here exactly like the one that was there from the first send-out.
var _trainer_battle_participants: Dictionary = {}


func _ready() -> void:
	_engage_range = float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	_player = get_node_or_null(player_path) as CharacterBody3D
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	if _player == null or _manager == null:
		push_error("encounter director needs a player and a combat manager")
		set_process(false)
		return
	_manager.connect("exited", _on_combat_exited)

	# `_ready` runs while the parent is still setting up its children, and
	# add_child() is refused during that. One frame is enough to be out of it.
	await get_tree().process_frame
	# `Vegetation` is a runtime child `playground_world.gd::_dress_the_meadow()`
	# adds during ITS OWN `_ready()`, which (children ready bottom-up) has not
	# necessarily run yet at the top of this function -- resolved here,
	# post-yield, rather than at the top, so the lookup runs after the world
	# has actually dressed the meadow instead of racing it.
	_vegetation = get_parent().get_node_or_null(^"Vegetation")
	_wire_creature_replication()
	await _spawn_creatures()


## Stage B lane 4.B. Wire this director to the session and to D97's authored
## `CreatureSpawner`, on EVERY peer.
##
## Every peer wires `spawn_function`, host and client alike: it is what turns
## the host's `spawn(data)` into a node locally, on each side (the same rule
## `trainer_spawn.gd::_ready()` states). Nothing is spawned here -- see
## `_is_host()` for why a spawn before a real peer exists is a phantom that
## breaks the session on join.
func _wire_creature_replication() -> void:
	var world := get_parent()
	if world != null:
		_creature_spawner = world.get_node_or_null(CREATURE_SPAWNER_PATH) as MultiplayerSpawner
	if _creature_spawner != null:
		_creature_spawner.spawn_function = _spawn_deployed_creature

	_session = get_node_or_null(SESSION_PATH)
	if _session == null:
		return
	if _session.has_signal("peer_joined") \
			and not _session.is_connected("peer_joined", _on_net_peer_joined):
		_session.connect("peer_joined", _on_net_peer_joined)
	if _session.has_signal("peer_left") \
			and not _session.is_connected("peer_left", _on_net_peer_left):
		_session.connect("peer_left", _on_net_peer_left)
	if _session.has_signal("session_ended") \
			and not _session.is_connected("session_ended", _on_net_session_ended):
		_session.connect("session_ended", _on_net_session_ended)


## Whether THIS process is the host of a real, LIVE session.
##
## Read `scripts/net/trainer_spawn.gd::_is_host()`'s comment in full before
## changing this; it carries the whole account of the defect that cost this
## project a day. The short of it: Godot installs an `OfflineMultiplayerPeer`
## by default, under which `multiplayer.is_server()` is **true** and
## `get_unique_id()` is **1** with no session at all, so any guard shaped "am
## I the server" passes in every headless test, capture tool and editor run.
## `Session.is_host()` alone is not enough either -- it is deliberately true
## when there is no session, because that is the honest answer for the D100
## autosave sites. Both questions together mean exactly `_mode == "host"`.
##
## Asked fresh at every call rather than cached, because this node is built
## before anybody hosts or joins and outlives the peer swap.
func _is_host() -> bool:
	if not is_inside_tree() or _session == null:
		return false
	if not _session.has_method("is_active") or not _session.has_method("is_host"):
		return false
	return bool(_session.call("is_active")) and bool(_session.call("is_host"))


## True once there is somebody else in the session. Below this nothing in this
## lane spawns, replicates or announces anything at all, which is what keeps
## solo identical.
func _is_multi_peer() -> bool:
	if _session == null or not _session.has_method("is_multi_peer"):
		return false
	return bool(_session.call("is_active")) and bool(_session.call("is_multi_peer"))


## This process's own peer id. 1 with no session and on the host (spike
## finding 2: only the listen server is 1; a joiner is a large random 32-bit
## number). Re-read rather than cached, for `_is_host()`'s reason.
func _local_peer_id() -> int:
	if _session != null and _session.has_method("local_peer_id"):
		return int(_session.call("local_peer_id"))
	return 1


## How many physics frames to keep trying to stand the wild creature on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and a raycast before then hits nothing. The first version of this
## spawned once on frame two, the ray missed, and the creature sat at the world
## origin under the terrain — where the player could neither see nor reach it,
## and where no error was printed. Retrying is the fix; the frame budget is so a
## scene with genuinely no ground fails loudly instead of looping.
const GROUND_WAIT_FRAMES := 300

## How far under the analytic ground a wild has to be before activation puts it
## back. Matches `tools/_probe_wild_grounding.gd`'s own threshold and is generous
## for the same reason: terrain the heightfield and the collider disagree about
## by a metre is a different and much smaller problem than a body in free fall.
const REGROUND_DEPTH_M := 5.0


func _spawn_creatures() -> void:
	var entries: Array = spawns_config().get("spawns", []) as Array
	if entries.is_empty():
		push_error("spawns.json has no spawn table; the meadow will be empty")

	# T3-ENCOUNTER. Decided once, for the whole table, before anything is
	# instanced -- the caps ("one major Alpha within a local region at a time")
	# and the rare-separation rule are global properties, and a decision made
	# per cluster at spawn time cannot see the clusters it has not reached yet.
	# Empty at the authored world seed, which is what makes seed 0 reproduce
	# today's world exactly rather than approximately.
	var plan := _spawn_plan(entries)

	for index in entries.size():
		var spawn: Dictionary = entries[index] as Dictionary
		# The ROLLED species where this cluster named a table and the world seed
		# asked for one; the authored species otherwise. Everything below reads
		# `spawn`, so the roll reaches the level band, the alpha treatment, the
		# gates and the cooldown through exactly the paths an authored entry
		# already uses -- there is no second kind of wild creature, the same
		# promise `spawn_wild()`'s own header makes.
		spawn = _apply_plan(spawn, plan)
		var species := str(spawn.get("species", ""))
		if not SPECIES.has(species):
			push_error("spawns.json names '%s', which is not in species.json" % species)
			continue
		var centre := _vector3_of(spawn.get("centre", []))
		var radius := float(spawn.get("radius", 0.0))
		var count := int(spawn.get("count", 1))

		# Seeded per entry, and NEVER randomize()d: the same table must produce
		# the same meadow every boot. A creature the owner met yesterday being
		# somewhere else today would read as it having wandered — fine — but a
		# smoke test walking to a spot that moves between CI runs is a flake
		# factory, and 'the world is deterministic' is the same promise the
		# terrain bake and the vegetation scatter already make (their seeds are
		# fixed in data too). The seed is derived from the entry's own `order`
		# so each cluster gets its own scatter rather than every cluster
		# sharing one.
		#
		# BAND-SPLIT changed this from the array index to `order`, and the two
		# are equal for every entry that existed at the split, so the meadow is
		# unchanged. The reason to change it at all is that the index stopped
		# being a safe identity the moment five agents could author five bands
		# at once: with the index, a Band 1 author appending one spawn shifts
		# every entry after it and silently moves, relevels and rerolls Band 3's
		# creatures -- a world change with no edit to Band 3 anywhere in the
		# diff. `order` is authored, reserved per band (see the band files' own
		# comment), and nobody else's edit can move it.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("wild_spawn_%d" % int(spawn.get("order", index)))

		# STREAM-D: one cluster entry per table row, built alongside the loop
		# that already walks it rather than reconstructed from `_wild_creatures`
		# afterwards -- `centre`/`radius` are already right here and a second
		# pass would just be re-deriving them.
		var cluster: Dictionary = {
			"centre": centre, "radius": radius,
			"members": [] as Array[Node3D], "active": true,
		}

		# WARRENS-ONCE, owner playtest 2026-09-03 item 9: "I can fight
		# multiple elders on there. After I fight it and catch it or kill it
		# I shouldn't get another chance." The same complaint the Warrens'
		# own guardian gets applies to every named `alpha`/`elder` individual
		# across the bands -- they are ordinary wild creatures
		# (`_comment_spawns` on every band file says so) and were fainting,
		# respawning and refilling on catch exactly like the rest of the
		# meadow. `order` is this entry's own stable, globally-unique
		# identity (the band files' own header), so the flag id needs no new
		# authored field.
		var once_alpha: Dictionary = spawn.get("alpha", {}) if spawn.get("alpha", {}) is Dictionary else {}
		var once_elder: Dictionary = spawn.get("elder", {}) if spawn.get("elder", {}) is Dictionary else {}
		var once_id := ""
		if not once_alpha.is_empty() or not once_elder.is_empty():
			once_id = "wild_once_%d" % int(spawn.get("order", index))
		var once_already_cleared := _once_cleared(once_id)

		for n in count:
			# The named individual is always the cluster's first member
			# (`_make_alpha()`/`_apply_elder()` below). Once it is beaten,
			# caught or freed, this spot simply spawns one fewer body -- the
			# rest of an ordinary-population cluster (`n > 0`) is untouched.
			if n == 0 and once_already_cleared:
				continue
			var wild: Node3D = CREATURE_SCENE.instantiate()
			# Indexed, because clusters exist now. Two nodes both named
			# "Wild_bramblebun" under one parent would be silently auto-renamed
			# by the engine, and a name nobody chose is a name no log line or
			# remote-tree screenshot can be matched against.
			# `order`, not just `n`. Indexing within the cluster fixed the
			# collision this comment describes only for ONE cluster: the moment
			# two clusters of the same species sit under this same parent, both
			# emit `Wild_burrowback_1..N` and the engine silently auto-renames
			# the second set to `@Wild_burrowback_1@123` -- reintroducing
			# exactly "a name nobody chose" that the comment above exists to
			# prevent. That was latent while a band held one cluster per
			# species; Band 5's density pass took the region to 22 clusters
			# with FIVE burrowback and FIVE duskhush among them, and made it
			# certain. Found when a probe counting `Wild_`-prefixed nodes
			# reported 6 creatures where 22 stood, because the auto-renamed
			# majority no longer started with `Wild_`.
			#
			# `order` is authored, unique across the whole merged table and
			# reserved per band (the band files' own header says so), so it is
			# already the identity this name wanted.
			wild.name = "Wild_%s_%d_%d" % [species, int(spawn.get("order", index)), n + 1]
			wild.set_script(WILD_SCRIPT)
			get_parent().add_child(wild)
			var spot := _pick_clear_spot(centre, radius, rng)
			if not await _stand_on_ground(wild, spot):
				push_error("no ground under the %s spawn point; it will be unreachable" % species)
			# PW2 (BAND1-D1): the optional per-entry `elder` descriptor, read
			# BEFORE populate because gameplay size has to be set before the
			# capsule is built. See `_apply_elder()` below for the whole shape.
			var elder: Dictionary = spawn.get("elder", {}) if spawn.get("elder", {}) is Dictionary else {}
			if not elder.is_empty():
				wild.set("body_scale", float(elder.get("body_scale", 1.0)))
			wild.call("populate", species, _player)
			# G-2. The alpha's block wins over the elder's when an entry
			# authors both, matching `_merge_named_individual`'s own precedence
			# for every other key the two blocks share.
			#
			# `has()` before the read, not `get("combat", {})`: the default a
			# missing key returns IS a Dictionary, so a type check on it passes
			# and the `and`'s right-hand side then indexes a key that was never
			# there. That is a SCRIPT ERROR on every world build, non-fatal and
			# therefore easy to ship -- it went red in CI (verify-gate-evidence-shard)
			# and not in any local test, because the seeded population this walks
			# is only built by a full world boot.
			var named_combat: Dictionary = {}
			var alpha_block: Dictionary = spawn.get("alpha", {}) if spawn.get("alpha", {}) is Dictionary else {}
			# Both halves of this loop were written twice, by G-2 and by
			# G3-OPENING-FIX, and the merge keeps each side's better half:
			# the typed array from theirs (an untyped literal infers
			# Array[Variant] and warns), and the `has()` guard from the G-2
			# fix. `get("combat", {})` also works here BECAUSE the result is
			# bound to a local first -- what broke in CI was reading
			# `block["combat"]` on the right of an `and` whose left side had
			# already passed on the default. Keeping the explicit guard so
			# the shape that failed cannot come back by editing one line.
			var named_blocks: Array[Dictionary] = [elder, alpha_block]
			for block in named_blocks:
				if not block.has("combat"):
					continue
				var block_combat: Variant = block["combat"]
				if block_combat is Dictionary and not (block_combat as Dictionary).is_empty():
					named_combat = (block_combat as Dictionary).duplicate(true)
			if not named_combat.is_empty():
				wild.set("combat_override", named_combat)
			# Audit B3: "" (no tier) for every authored anchor, which
			# `TIER_RIM_STRENGTH` resolves to `common`'s 0.0 -- only a rolled
			# spawn (`spawn_tables.gd::plan_for`) ever sets a real tier here.
			wild.call("set_tier", str(spawn.get("tier", "")))
			# The CLUSTER's centre, not this individual's scattered spot: a
			# cluster sitting on a region boundary must not hand two of its own
			# members different level bands, which is what reading the body's
			# own z would do.
			_roll_wild_level(wild, species, rng, centre.z)
			# GAME-11. An optional per-entry `level` pins this cluster's members
			# at an absolute level instead of leaving them to the region's band
			# roll. It exists for exactly one situation: a cluster whose ROLE the
			# chapter names, where the band's own spread contradicts it. Band 1's
			# practice cluster is that case -- `progression.json`'s award comment
			# states the chapter's enemy levels "run 2 at the practice fight to 22
			# in the stronghold gauntlet", and the band is [2,6], so the fight that
			# TEACHES combat was rolling anywhere from 2 to 6 against a level-3
			# starter. Gate F run 6 measured the result across five fresh saves:
			# the starter FAINTED in 4 of 5, and the catch it gates landed in 1.
			#
			# Applied AFTER the roll, never instead of it, and that is the whole
			# reason it is written this way. `_roll_wild_level()` draws seven
			# values from the CLUSTER's shared `rng` (level, three IVs, two traits,
			# shiny), and that same generator goes on to scatter and roll every
			# later member. Substituting `_set_fixed_level()` here -- which carries
			# its own name-seeded rng and consumes nothing from this one -- would
			# leave those seven draws untaken and silently move, relevel and reroll
			# every creature after it, which is exactly what this table's `order`
			# header warns against. Overriding the finished instance costs no draw
			# and leaves IVs, traits, shiny and the scatter bit-identical.
			# `_apply_elder()`'s `level_bonus` takes the same approach for the same
			# reason; `level` is its absolute counterpart, for the rarer case where
			# the chapter names a number rather than a relationship.
			var pinned := int(spawn.get("level", 0))
			if pinned > 0:
				var pinned_instance: Variant = wild.get("instance")
				if pinned_instance != null:
					pinned_instance.call("set_level", pinned, PROGRESSION.config())
			# GATE-D: BOTH of these landed, independently, in two lanes that
			# could not see each other -- Band 1 authored `elder` (PW2) and
			# Bands 2 and 3 authored `alpha` (WILD-ECOLOGY, prompt 60), each
			# with its own descriptor key and its own function. They are the
			# same idea and neither is redundant, because the spawn tables that
			# already ship use both keys: dropping either silently disarms
			# every entry that names it. Kept as two paths rather than merged
			# into one, because the keys differ in shape and rewriting a band's
			# data during a merge is how a region loses content nobody notices.
			#
			# Prompt 60: "a handful of special encounters across the chapter...
			# a reason to win even if the player does not catch it". The
			# cluster's FIRST member is its alpha when the entry asks for one --
			# one per cluster, never the whole group, so the rest stays the
			# ordinary population the band's level band describes.
			#
			# Presentation is scale, per CLAUDE.md: no new creature meshes for
			# the Meadows, differentiate with "materials, textures, modest
			# scale, animation, VFX, habitat, behavior, traits, and encounter
			# context". An alpha is a bigger, older, higher-level individual of
			# a species the player already knows.
			if n == 0:
				_make_alpha(wild, species, spawn, centre.z)
				if once_id != "" and not once_alpha.is_empty():
					# WARRENS-ONCE: remembers this exact body so
					# `_on_combat_exited()` can fire the flag and skip its
					# respawn timer the moment this alpha leaves the field.
					_once_only[wild] = once_id
			var wild_cfg: Dictionary = MATH.config().get("wild", {})
			# WORLD-LIFE-0903 (BAND1_ROUTE_CONTRACT.md). A cluster's own
			# `wander_radius` overrides `wild_creature.gd`'s open-meadow default
			# (7m) for every member of THIS cluster -- the herd/water-edge
			# clusters the route contract asks to read as visible life rather
			# than static props. Absent key means every cluster that existed
			# before this: unchanged. Applied BEFORE the elder merge below so an
			# elder's own `wander_radius` (a different lane's mechanism, PW2)
			# still wins if a cluster somehow carried both.
			if spawn.has("wander_radius"):
				wild_cfg = wild_cfg.duplicate()
				wild_cfg["wander_radius"] = float(spawn["wander_radius"])
				# The road clearance check only matters once a cluster's disc can
				# plausibly reach the road; every other cluster in the game (no
				# `wander_radius` key) never asks for it and pays nothing.
				wild.call("set_clearance_check", Callable(self, "_wander_target_clear_of_road"))
			if not elder.is_empty():
				wild_cfg = _apply_elder(wild, elder, wild_cfg)
				if once_id != "":
					_once_only[wild] = once_id
			wild.call("configure", wild_cfg)
			wild.set("home", wild.global_position)
			# An aggressive creature asks; this node decides. Keeping the decision
			# here means every route into a fight goes through one place, so a
			# new one cannot forget to suspend exploration or hand over the
			# camera.
			wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
			_wild_creatures.append(wild)
			(cluster["members"] as Array[Node3D]).append(wild)
			_wild_cluster[wild] = cluster

			var gate := _gate_for_spawn(spawn)
			if not gate.is_empty():
				_wild_gates[wild] = gate
				wild.visible = _gate_active(gate)

			# T3-CREATURES: the entry's own respawn cooldown, if it named one.
			# Read here rather than looked up from the spawn table at respawn
			# time because by then the only thing in hand is the node.
			var cooldown := float(spawn.get("respawn_seconds", 0.0))
			if cooldown > 0.0:
				_wild_respawn[wild] = cooldown

		_clusters.append(cluster)

	# Set every cluster's real activation state against the player's actual
	# starting position, rather than leaving the whole freshly spawned meadow
	# processing until the first `_process()` tick happens to run.
	_tick_streaming()

	if default_starter != "":
		# Awaited: `adopt_starter` waits for ground under the spawn point, so
		# calling it bare would hand back a coroutine and leave the creature unplaced.
		await adopt_starter(default_starter)


## T3-ENCOUNTER. The world seed this boot is building, resolved once.
##
## `Game.world_seed` is save state (save_game.gd VERSION 15), so a loaded save
## rebuilds the population it was saved with -- the roll is a pure function of
## (seed, order), which is why a rolled population needs no per-creature
## persistence and nothing to migrate. `TB_WORLD_SEED` in the environment
## overrides it for one process, which is how a Gate F run pins a world and how
## the system is playable while `roll_new_worlds` ships false.
##
## No `/root/Game` (the combat sandbox, and the unit suite, which starts no
## autoloads at all -- see `_party()`'s own header) reads as the authored seed.
## That is the right answer there and not merely a safe one: the sandbox is where
## five smoke tests boot expecting a specific meadow.
func world_seed() -> int:
	var game := get_node_or_null(^"/root/Game")
	var saved := int(game.get("world_seed")) if game != null and game.get("world_seed") != null else 0
	return SPAWN_TABLES.resolve_seed(saved)


## The rolled half of the population, decided for the whole table at once.
##
## `exceptional_species` is every species carrying `variant_of` -- the four
## aspect variants T3-CREATURES landed (Nightburrow, Stormtrail, Riftfrill,
## Ashtusk). They are ANCHORED individuals, and passing them here is what makes
## an anchored one spend its region's exceptional budget BEFORE any roll gets to,
## so a rolled rarity can never crowd the individual the story placed. Derived
## from species.json rather than listed, so a fifth variant is counted the day it
## lands with no edit here.
func _spawn_plan(entries: Array) -> Dictionary:
	var exceptional: Array = []
	for id: Variant in SPECIES.table():
		# `_`-prefixed keys are documentation, not species. `creature_species.gd`
		# does not filter them and a `_comment` inside the `species` object is
		# iterated as a real entry -- T3-CREATURES hit this exact trap twice and
		# wrote it up (its handover 7.7). Skipping them here costs one line.
		if str(id).begins_with("_"):
			continue
		if SPECIES.definition(str(id)).has("variant_of"):
			exceptional.append(str(id))
	return SPAWN_TABLES.plan_for(
		entries, world_seed(), SPAWN_TABLES.config(), CHAPTER_CURVE.config(), exceptional
	)


## Fold this entry's rolled result back into the entry, or hand it back
## untouched.
##
## Returns a COPY when the plan has something to say, so the loaded spawn config
## -- which is cached on this node and read by `_role_species()` and the tests --
## is never mutated. An entry with no plan result is returned as-is rather than
## copied, which is every anchor and, at the authored seed, every entry.
##
## `alpha` from the plan is only ever ADDED, never overwritten: an entry that
## authored its own alpha block is an anchor by definition and `plan_for()`
## refuses to promote it, but stating it here too costs one condition and means
## the invariant survives somebody changing their mind about the other end.
func _apply_plan(spawn: Dictionary, plan: Dictionary) -> Dictionary:
	var order := int(spawn.get("order", -1))
	if not plan.has(order):
		return spawn
	var rolled: Dictionary = plan[order]
	var merged := spawn.duplicate(true)
	merged["species"] = str(rolled.get("species", spawn.get("species", "")))
	if rolled.has("tier"):
		merged["tier"] = str(rolled["tier"])
	if rolled.has("time"):
		merged["time"] = str(rolled["time"])
	if rolled.has("weather"):
		merged["weather"] = (rolled["weather"] as Array).duplicate()
	if rolled.has("alpha") and not merged.has("alpha") and not merged.has("elder"):
		merged["alpha"] = (rolled["alpha"] as Dictionary).duplicate()
	return merged


## SD17: one wild creature, placed by somebody else.
##
## `_spawn_creatures()` above builds the MEADOW's population from
## `spawns.json` — a seeded scatter of clusters, rolled levels, deterministic
## across boots. A hand-authored place (the Burrow Warrens; anything later
## that wants a specific creature in a specific room) needs the opposite: an
## exact spot, an exact level, and a temperament its species does not have out
## in the field. This is that call, and it deliberately does NOT touch the
## seeded loop's own draw order — every existing save, screenshot and smoke
## test depends on those numbers landing exactly where they already do.
##
## What it shares with the loop is everything that matters afterwards: the
## body is an ordinary `wild_creature.gd`, it is registered in
## `_wild_creatures`, its `wants_to_engage` runs through the same one place
## every fight is started from, and it faints, respawns and can be caught like
## anything else. There is no second kind of wild creature.
##
## `opts` keys, all optional:
##   level      — a fixed level, instead of the wild band roll
##   aggressive — override the species' own temperament for THIS body
##   parent     — the node to add it under (defaults to this director's own
##                parent, the world root). A caller that provides its own
##                `ground_height_at` — the warrens' cave floor — parents its
##                creatures under itself so `creature_body.gd` finds it.
##   name       — the node name, so a log line or a remote tree can be matched
##   wander_radius — overrides `wild_creature.gd`'s open-meadow default (7m)
##                for THIS body. A hand-authored room is not the meadow: the
##                Burrow Warrens vault is 8m across, and `_rng.randomize()` in
##                `wild_creature.gd` means every boot rolls a different wander
##                path with no way to predict where a resident ends up before
##                `_quieten_the_residents()` freezes it in place. A resident
##                spawned near a room's own passage can wander INTO it and get
##                frozen there, mid-doorway, which is indistinguishable from a
##                sealed passage to a player walking up to it. Named callers
##                (`burrow_warrens.gd`) pass a radius that keeps their own
##                residents inside their own walls; left unset, behaviour is
##                unchanged for the open-world seeded population.
##   once_id    — WARRENS-ONCE. A progression flag id this individual owns.
##                Already fired (SB9's flag store, `_once_cleared()` above) →
##                this call spawns nothing and returns null, so a defeated/
##                caught guardian or named resident never comes back once its
##                scene rebuilds (leave and return, or reload a save). Not yet
##                fired → the body spawns as usual and is remembered
##                (`_once_only`), so `_on_combat_exited()` can set the flag
##                and skip its respawn timer the moment this fight resolves.
##                Omitted entirely for the ordinary seeded population, which
##                keeps fainting, respawning and being caught exactly as
##                before.
##   combat     — G-2 (docs/specs/GATE3_ENCOUNTER_CONTRACTS.md). A per-encounter
##                behaviour override merged over `combat.json`'s `enemy` block
##                for THIS body only, so a named opponent can fight differently
##                rather than merely bigger. Absent → today's behaviour byte for
##                byte, which is the contract's own failure condition. Authored
##                in the data that already describes the individual: a spawn
##                entry's `alpha`/`elder` block, `burrow_warrens.json`'s
##                `guardian`, or a trainer team member. See
##                `wild_creature.gd::combat_override`.
func spawn_wild(species: String, spot: Vector3, opts: Dictionary = {}) -> Node3D:
	if not SPECIES.has(species):
		push_error("spawn_wild('%s') names a species that is not in species.json" % species)
		return null
	var once_id := str(opts.get("once_id", ""))
	if _once_cleared(once_id):
		return null
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(WILD_SCRIPT)
	wild.name = str(opts.get("name", "Wild_%s_%d" % [species, _wild_creatures.size() + 1]))
	var parent: Node = opts.get("parent", null) as Node
	if parent == null or not is_instance_valid(parent):
		parent = get_parent()
	parent.add_child(wild)
	wild.call("populate", species, _player)
	# G-2: before anything can engage this body. `populate()` does not clear it
	# and a fresh instance starts empty, so an override cannot leak between
	# bodies -- the contract's "fails if the override reaches any body that did
	# not author it".
	var opt_combat: Variant = opts.get("combat", {})
	if opt_combat is Dictionary and not (opt_combat as Dictionary).is_empty():
		wild.set("combat_override", (opt_combat as Dictionary).duplicate(true))
	var level := int(opts.get("level", 0))
	if level > 0:
		_set_fixed_level(wild, species, level)
	if opts.has("aggressive"):
		wild.set("aggressive", bool(opts["aggressive"]))
	var wild_cfg: Dictionary = MATH.config().get("wild", {})
	if opts.has("wander_radius"):
		wild_cfg = wild_cfg.duplicate()
		wild_cfg["wander_radius"] = opts["wander_radius"]
	wild.call("configure", wild_cfg)
	# No `await` here, unlike the cluster loop: a placed creature's ground is
	# the caller's own floor, which exists the moment the node is in the tree.
	# The fallback keeps it out of the world origin if that ever fails.
	if not bool(wild.call("place_on_ground", spot)):
		wild.global_position = spot
	wild.set("home", wild.global_position)
	wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
	_wild_creatures.append(wild)
	if once_id != "":
		_once_only[wild] = once_id
	return wild


## Turn a rolled wild creature into its cluster's alpha, if the entry asks.
##
## Reads `alpha` off the spawn entry, which is optional everywhere: a cluster
## without it is untouched and every existing band file keeps the population it
## already had. The block carries `level_bonus` (added to whatever the band's
## own roll produced, so an alpha is always ahead of its neighbours rather than
## at some absolute level that would fight the curve) and `scale`.
##
## Deliberately additive over the rolled level rather than a fixed number:
## `chapter_curve.json` owns how strong a region's wild are, and an alpha that
## named its own level would drift out of the band the moment the curve moved.
func _make_alpha(wild: Node3D, species: String, spawn: Dictionary, centre_z: float) -> void:
	var alpha: Dictionary = spawn.get("alpha", {})
	if alpha.is_empty():
		return
	var bonus := int(alpha.get("level_bonus", 0))
	var instance: RefCounted = wild.get("instance")
	if instance != null and bonus > 0:
		var cfg: Dictionary = CHAPTER_CURVE.progression_config_at(
			centre_z, PROGRESSION.config(), CHAPTER_CURVE.config())
		instance.call("set_level", int(instance.get("level")) + bonus, cfg)
	# Gameplay size, not node scale. `creature_body.gd::apply_size_multiplier()`
	# grows `_height` and `_radius` and rebuilds the capsule, collider and art
	# from them -- setting `wild.scale` would grow only the art, leaving
	# `body_radius()` and `centre()` reporting the ordinary body, so throws that
	# visually struck an alpha would resolve as edge hits or misses.
	var scale := float(alpha.get("scale", 1.0))
	if scale != 1.0 and wild.has_method("apply_size_multiplier"):
		wild.call("apply_size_multiplier", scale)
	# Named so a log line, a smoke test or a remote tree can pick it out of its
	# own cluster -- the same reason the loop above indexes its ordinary names.
	wild.name = "Alpha_%s" % species
	wild.set_meta("alpha", true)
	# CREATURE-IDENTITY-2: and now it LOOKS like one. Until this, an alpha
	# differed from its neighbours only by level and by a size multiplier that
	# is unreadable unless an ordinary member of the same species happens to be
	# standing beside it -- so the player met a harder fight with no warning
	# available before the first exchange. `creature_body.set_alpha()` swaps to
	# the `*_alpha` colourway where one is authored, rims the silhouette and
	# starts the idle aura. Called AFTER the size multiplier above, because that
	# rebuilds the art and would otherwise discard the dressing.
	if wild.has_method("set_alpha"):
		wild.call("set_alpha", true)


## The fixed-level counterpart to `_roll_wild_level()`. Same instance build
## (IVs and traits still roll, from a seed derived from the body's own name so
## the same room produces the same creature every boot), then the level is set
## outright rather than drawn from `progression.json`'s wild band.
func _set_fixed_level(wild: Node3D, species: String, level: int) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placed_%s_%s" % [wild.name, species])
	var leveled: RefCounted = CREATURE_INSTANCE.from_species(
		species, SPECIES.definition(species), rng.randf(), cfg,
		[rng.randf(), rng.randf(), rng.randf()], [rng.randf(), rng.randf()]
	)
	leveled.call("set_level", level, cfg)
	var is_shiny: bool = rng.randf() < VISUAL.shiny_chance()
	leveled.shiny = is_shiny
	wild.set("instance", leveled)
	wild.call("set_shiny", is_shiny)


## Give a freshly `populate()`d wild creature a rolled level (D30), replacing the
## flat level-1 instance `populate()` just built with one rolled against
## `progression.json`'s `level.wild_band`.
##
## Rolled through THIS entry's own `rng` — the same generator the position
## scatter just above already used and never `randomize()`s — rather than a
## fresh unseeded roll. That is what keeps a creature met at a given spot the
## same rough strength across boots, matching the determinism promise
## `_spawn_creatures`'s own comment makes for position: a creature the owner
## met yesterday reads as having wandered if it moves, but reads as broken if
## its LEVEL is a different number every launch a smoke test happens to run.
##
## `wild_band` is a single global band in `progression.json`, not per-species
## or per-spawns.json-entry: nothing in D30 or the follow-up session that
## produced it asked for a rarer species to skew stronger, and adding that
## split here would be inventing a rule nobody asked for. spawns.json stays
## untouched by this change.
##
## GATEC-CURVE made it per-REGION, which is a different split and one the
## chapter did ask for. `centre_z` is the cluster's own world z;
## `chapter_curve.json` names the band each region rolls in and
## `chapter_curve.gd` returns a copy of the progression config carrying it, so
## every line below is unchanged and the rng draw ORDER -- level, three IVs, two
## traits, shiny, in that order -- is byte-for-byte what it was. Band 1's band
## is still `[2, 6]`, so the opening meadow every smoke test walks through
## rolls exactly the levels it rolled before. What changes is that a creature
## standing in the stronghold approach is no longer level 4. Species are still
## not skewed against each other; only where they stand matters.
##
## Also rolls individuality and a trait pair (R4.2) through this same `rng` —
## the wild encounter is where GAME_DESIGN.md 11's "same-species creatures
## have slightly different underlying stat quality" is actually met by the
## player, and MEADOWS_PROGRESSION_SPEC.md 11 names "seek better traits/
## appraisal" as one of the good reasons to keep catching. Consuming more of
## the same seeded, never-`randomize()`d generator changes nothing about the
## determinism promise above — a creature met at a given spot still rolls
## the same way across boots, just for three more numbers than before.
##
## OF27: one more `rng.randf()`, drawn LAST, decides whether this individual
## is shiny. Deliberately the final draw in the sequence rather than mixed in
## earlier — every draw before it (the three IVs, the two trait rolls, the
## level) has to keep landing on the exact numbers every existing save,
## smoke test and screenshot already depends on, and appending a draw is the
## only order that leaves all of them untouched. `VISUAL.shiny_chance()` is
## OF27's own tunable, not the wild band's — the same "one config file per
## kind of number" split `PROGRESSION`/`MATH`/`CATCH` already keep. The body
## does not yet have this instance's shiny status when it was built in
## `populate()` above (that happened before this roll), so it is told
## directly via `set_shiny`, which re-tints the model already standing in
## the world rather than rebuilding it.
func _roll_wild_level(wild: Node3D, species: String, rng: RandomNumberGenerator, centre_z: float) -> void:
	var cfg: Dictionary = CHAPTER_CURVE.progression_config_at(
		centre_z, PROGRESSION.config(), CHAPTER_CURVE.config())
	var definition: Dictionary = SPECIES.definition(species)
	var iv_rolls: Array = [rng.randf(), rng.randf(), rng.randf()]
	var trait_rolls: Array = [rng.randf(), rng.randf()]
	var leveled: RefCounted = CREATURE_INSTANCE.from_species(
		species, definition, rng.randf(), cfg, iv_rolls, trait_rolls
	)
	var is_shiny: bool = rng.randf() < VISUAL.shiny_chance()
	leveled.shiny = is_shiny
	wild.set("instance", leveled)
	wild.call("set_shiny", is_shiny)


## PW2 (BAND1-D1). An `elder` block on a spawns.json entry turns that cluster's
## creatures into memorable individuals of a species that is otherwise ordinary
## — not a new species, not a boss, and still catchable, which PW2 requires and
## which falls out for free here because nothing about the wild path changes.
##
## The block is read in two places because its fields land at two different
## moments. `body_scale` has to be set before `populate()` builds the capsule
## (see `creature_body.gd::body_scale` for why scaling the art instead would be
## wrong); everything below happens after, once there is a rolled instance to
## adjust. Absent block means an ordinary creature, which is every entry in the
## table but the ones that say otherwise — the same shape as R5.3's `time` and
## `weather` gates.
##
##   body_scale   — gameplay size multiplier; art, reach and catch odds follow
##   level_bonus  — added to the level the region's own band just rolled, so
##                  an elder stays relative to its region instead of pinning a
##                  number that goes stale when `chapter_curve.json` moves
##   title        — nameplate prefix ("Elder Mosshell"). PW2's readability rule
##                  asks the player to know this is unusual before or very
##                  early in combat; the name is the plainest way to say it and
##                  costs no new UI
##   any `wild` config key (`wander_radius`, `notice_range`, ...) — merged over
##                  the shared wild config for this creature only, which is
##                  where PW2's REQUIRED behavioural distinction comes from.
##                  Stats and scale alone are explicitly not enough.
##
## Returns the config `configure()` should be called with.
func _apply_elder(wild: Node3D, elder: Dictionary, base_cfg: Dictionary) -> Dictionary:
	var instance: Variant = wild.get("instance")
	var bonus := int(elder.get("level_bonus", 0))
	if instance != null and bonus != 0:
		var cfg: Dictionary = PROGRESSION.config()
		instance.call("set_level", int(instance.get("level")) + bonus, cfg)

	var title := str(elder.get("title", ""))
	if instance != null and title != "":
		instance.set("display_name", "%s %s" % [title, str(instance.get("display_name"))])

	var merged := base_cfg.duplicate()
	for key: Variant in elder:
		# The three fields above are this director's own; anything else is a
		# `configure()` key and is passed straight through, so a new tunable in
		# wild_creature.gd needs no edit here to become elder-overridable.
		if key in ["body_scale", "level_bonus", "title"]:
			continue
		if str(key).begins_with("_"):
			continue
		merged[key] = elder[key]
	return merged


## Positions in spawns.json are absolute world metres — [x, y, z] with y always
## 0, because nothing here trusts a hand-written height: everything is stood on
## the ground by asking the world (docs/decisions/D09).
func _vector3_of(raw: Variant) -> Vector3:
	var list: Array = raw if raw is Array else []
	if list.size() < 3:
		return Vector3.ZERO
	return Vector3(float(list[0]), float(list[1]), float(list[2]))


## Do not spawn the sandbox's default creature; the story is granting one.
##
## Called from the sequence director's `_ready`, which is guaranteed to have run
## by the time `_spawn_creatures` gets here: the spawn is behind
## `await get_tree().process_frame`, and every `_ready` in the tree completes
## before the next idle frame does.
func suspend_default_starter() -> void:
	default_starter = ""


## Give the player a creature, and put it in the world beside them.
##
## This is the inversion the opening needed. The creature used to be instanced with
## `visible = false` and switched on for the length of a fight; now it is
## visible, standing on the ground, and following. A creature that exists only
## while you are hitting something with it is a weapon, not a companion.
##
## Returns false for an unknown species rather than leaving a body with no
## health in the world.
func adopt_starter(species_id: String, nickname: String = "") -> bool:
	if _ally_body != null and is_instance_valid(_ally_body):
		push_error("the player already has a creature; adopt_starter is not a swap")
		return false

	var creature: RefCounted = SPECIES.spawn(species_id)
	if creature == null:
		push_error("starter species '%s' is missing from species.json" % species_id)
		return false
	# D30: a starter arrives a little ahead of the wildest thing in the yard.
	var progression_cfg: Dictionary = PROGRESSION.config()
	creature.set_level(int(progression_cfg.get("level", {}).get("starter_level", 3)), progression_cfg)
	if nickname != "":
		# nickname, not display_name — the same bug already fixed in
		# party_seam.gd. creature_instance.label() reads nickname first and falls
		# back to display_name, so overwriting display_name instead loses the
		# species name for good: a Terrapup named "Bud" would show as "Bud"
		# everywhere, including the places that specifically want to say what
		# kind of creature it is.
		creature.nickname = nickname

	return await _spawn_ally_body(creature)


## Instances a following body for `creature` and stands it up beside the trainer.
## Shared by `adopt_starter()` (the very first creature, a brand new instance) and
## `summon_active_creature()` (`CO1` — recalling a creature the party already owns). The
## RefCounted stats are the caller's; this only ever builds the visible body
## around them.
func _spawn_ally_body(creature: RefCounted) -> bool:
	_ally = creature

	# Instanced hidden and only shown once it is standing on the ground. An
	# invisible body is switched off entirely (creature_body._on_visibility_changed),
	# and a VISIBLE one at the world origin is a solid capsule inside the
	# terrain — or inside the trainer, which is the overlap that once launched
	# the player off the playground at 500 m/s.
	_ally_body = CREATURE_SCENE.instantiate()
	# Stage B lane 4.B. The NAME is no longer the key to "the deployed
	# creature": `creature_body.gd::DEPLOYED_GROUP` plus `is_local_deployment()`
	# is, because one hardcoded name cannot address one creature per owner and
	# a session has one per player. This string survives only as a legacy alias
	# for `scripts/build/build_placer.gd::_bodies_that_are_not_buildings()`,
	# which is another lane's file this wave and still looks the node up by
	# name; the handover to move it onto the group is recorded in
	# `ralph/reports/MP-4B-CREATURES-0906/REPORT.md`. Every other peer's
	# creature is a `remote_creature.gd` proxy named `AllyCreature_<peer id>`
	# under `Spawned/Creatures`, so no two bodies ever contend for one name.
	_ally_body.name = "AllyCreature"
	_ally_body.set_script(FOLLOWER_SCRIPT)
	_ally_body.visible = false
	get_parent().add_child(_ally_body)
	_ally_body.call("setup", creature.species_id, bool(creature.get("shiny")))
	_ally_body.call("configure_following", _follower_config())
	# ITS OWN trainer, not "the player": in a session every peer has a body
	# standing in this world, and `_player` is this process's own rig -- which
	# is exactly the trainer this process's creature belongs to. A peer's
	# creature is followed home by that peer's own director, in that peer's own
	# process, so the leader is right by construction on every side.
	_ally_body.set("leader", _player)
	_ally_body.set("owner_peer_id", _local_peer_id())

	# Behind the trainer's right shoulder, which is where it will settle anyway.
	var spot := _player.global_position - _player.global_basis.z * 2.4 + _player.global_basis.x * 1.2
	if not await _stand_on_ground(_ally_body, spot):
		push_error("no ground beside the trainer to put their creature on")
	_ally_body.visible = true
	_ally_body.call("face_towards", _player.global_position)
	_ally_body.call("set_following", true)
	_announce_deployment(creature)
	return true


# --- Stage B lane 4.B: replicating the deployed creature ----------------------

## Tell the session this process has a creature out, so the host can stand up a
## proxy of it for everybody else. A no-op in solo and in a one-peer session,
## which is the whole of why nothing below changes single-player behaviour.
func _announce_deployment(creature: RefCounted) -> void:
	if not _is_multi_peer():
		return
	var row := {
		"species_id": str(creature.get("species_id")),
		"shiny": bool(creature.get("shiny")),
		"character_id": _local_character_id(),
		# Stage B lane 4.C. The creature's COMBAT CARD, announced once with the
		# species rather than quoted per swing -- see `_creature_card_for()` for
		# why the host needs it and why this is the only honest place to get it.
		"card": _creature_card(creature),
	}
	if _is_host():
		_host_set_deployed(_local_peer_id(), row)
		return
	rpc_id(1, "_rpc_creature_deployed", row)


## The mirror: this process put its creature away.
func _announce_recall() -> void:
	if not _is_multi_peer():
		return
	if _is_host():
		_host_clear_deployed(_local_peer_id())
		return
	rpc_id(1, "_rpc_creature_recalled")


## Client -> host, ledger channel. A peer reporting what it has out.
##
## The host does not take the peer's word for anything but the SPECIES it
## deployed: position, and every number a fight turns on, stay host truth
## (`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2). This is the one fact only the
## owner can know, because its party is its own (D100).
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_creature_deployed(row: Dictionary) -> void:
	if not _is_host():
		return
	_host_set_deployed(multiplayer.get_remote_sender_id(), row)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_creature_recalled() -> void:
	if not _is_host():
		return
	_host_clear_deployed(multiplayer.get_remote_sender_id())


func _host_set_deployed(peer_id: int, row: Dictionary) -> void:
	if peer_id == 0:
		return
	_deployed_by[peer_id] = row.duplicate(true)
	_despawn_creature_proxy(peer_id)
	_spawn_creature_proxy(peer_id)


func _host_clear_deployed(peer_id: int) -> void:
	_deployed_by.erase(peer_id)
	_despawn_creature_proxy(peer_id)


## One proxy per peer that has a creature out, including the host's own --
## a client has to see the host's creature just as much as the other way
## round. Idempotent; safe to call on every join.
func _reconcile_creature_proxies() -> void:
	if not _is_host() or _creature_spawner == null:
		return
	# The host's own deployment was never announced while it was alone in the
	# session (there was nobody to announce it to), so record it now.
	if _ally != null and _ally_body != null and is_instance_valid(_ally_body):
		_deployed_by[_local_peer_id()] = {
			"species_id": str(_ally.get("species_id")),
			"shiny": bool(_ally.get("shiny")),
			"character_id": _local_character_id(),
			"card": _creature_card(_ally),
		}
	var live := _session_peer_ids()
	for peer_id in _deployed_by.keys().duplicate():
		if not live.has(int(peer_id)):
			_host_clear_deployed(int(peer_id))
			continue
		if not _creature_proxies.has(peer_id):
			_spawn_creature_proxy(int(peer_id))
	for held in _creature_proxies.keys().duplicate():
		if not _deployed_by.has(held):
			_despawn_creature_proxy(int(held))


func _spawn_creature_proxy(peer_id: int) -> void:
	if not _is_host() or _creature_spawner == null or _creature_proxies.has(peer_id):
		return
	var row: Dictionary = _deployed_by.get(peer_id, {})
	if row.is_empty():
		return
	var at := _proxy_spawn_position(peer_id)
	var data := {
		"peer_id": peer_id,
		"species_id": str(row.get("species_id", "")),
		"shiny": bool(row.get("shiny", false)),
		"character_id": str(row.get("character_id", "")),
		"at": [at.x, at.y, at.z],
	}
	print("[creatures] spawning %s's creature '%s' at (%.1f, %.1f)"
		% [peer_id, str(data["species_id"]), at.x, at.z])
	var node: Node = _creature_spawner.spawn(data)
	if node != null:
		_creature_proxies[peer_id] = node


func _despawn_creature_proxy(peer_id: int) -> void:
	var node: Variant = _creature_proxies.get(peer_id)
	_creature_proxies.erase(peer_id)
	if node is Node and is_instance_valid(node):
		# Freeing on the host is what the spawner replicates as a despawn.
		(node as Node).queue_free()


## Where a proxy stands before its first replicated position arrives: beside
## the trainer body that owns it, so a joiner never sees a creature flash in at
## the origin. The owner's own trainer body is the `remote_trainer` node
## carrying that peer id (lane 2.C); the host's own is its local rig.
func _proxy_spawn_position(peer_id: int) -> Vector3:
	if peer_id == _local_peer_id() and _player != null and is_instance_valid(_player):
		return _player.global_position
	if is_inside_tree():
		var tree := get_tree()
		if tree != null:
			for body in tree.get_nodes_in_group(&"remote_trainer"):
				if body is Node3D and is_instance_valid(body) \
						and int((body as Node3D).get("peer_id")) == peer_id:
					return (body as Node3D).global_position
	if _player != null and is_instance_valid(_player):
		return _player.global_position
	return Vector3.ZERO


## THE ONE PLACE a deployed creature's authority is set. Runs on EVERY peer,
## identically, before the node is added to the tree.
##
## Setting authority after tree entry raises nothing and silently changes it on
## the calling peer only -- authority is not a replicated property (ENet spike
## finding 3, and `trainer_spawn.gd::_spawn_trainer()`'s own header). A body
## that exists with the wrong authority looks like a FROZEN creature, not like
## an error, which is why `tests/smoke_net_deploy_two_creatures.gd` asserts the
## authority and not merely the presence.
func _spawn_deployed_creature(data: Variant) -> Node:
	var d: Dictionary = data if data is Dictionary else {}
	var peer_id := int(d.get("peer_id", 0))
	var node := CREATURE_SCENE.instantiate()
	node.set_script(REMOTE_CREATURE_SCRIPT)
	# One name per owner, a pure function of the peer id, so the same node has
	# the same name in every process and two bodies can never contend for one.
	node.name = "AllyCreature_%d" % peer_id
	node.set("owner_peer_id", peer_id)
	node.set("owner_character_id", str(d.get("character_id", "")))
	# Read back by `remote_creature.gd::_ready()`, which calls `setup()` after
	# `super()` -- the same instantiate/enter-tree/setup ordering
	# `_spawn_ally_body()` uses on the local body.
	node.set("deploy_species", str(d.get("species_id", "")))
	node.set("deploy_shiny", bool(d.get("shiny", false)))
	var at: Variant = d.get("at", [])
	if at is Array and (at as Array).size() == 3:
		var a: Array = at
		(node as Node3D).position = Vector3(float(a[0]), float(a[1]), float(a[2]))
		node.set("net_position", (node as Node3D).position)
	# Built here rather than authored into `creature.tscn`, because that scene
	# is also every one of the ~900 wild creatures in the chapter and none of
	# them may carry a synchronizer. Constructed identically on every peer,
	# before `add_child`, so the spawn packet carries matching sync ids.
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = ^".."
	sync.replication_config = _creature_replication_config()
	node.add_child(sync)
	if peer_id != 0:
		# Recursive by default, which is what is wanted: the child
		# `MultiplayerSynchronizer` has to carry the same authority or its
		# deltas are refused at the far end.
		node.set_multiplayer_authority(peer_id)
	print("[creatures] built %s for peer %d, authority %d (this peer is %d)"
		% [node.name, peer_id, node.get_multiplayer_authority(), multiplayer.get_unique_id()])
	return node


## Position and yaw, every tick. Nothing else needs to cross the wire: the
## animator derives its gait from the velocity the interpolation produces, and
## every number a FIGHT turns on is host truth rather than a replicated
## property (`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §3).
func _creature_replication_config() -> SceneReplicationConfig:
	var cfg := SceneReplicationConfig.new()
	for path in [^".:net_position", ^".:net_yaw"]:
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	return cfg


func _session_peer_ids() -> Array:
	var out: Array = []
	if _session == null or not _session.has_method("peers"):
		return out
	var raw: Variant = _session.call("peers")
	if not (raw is Array):
		return out
	for entry in (raw as Array):
		if entry is Dictionary:
			var row: Dictionary = entry
			out.append(int(row.get("peer_id", row.get("id", 0))))
		elif entry is int or entry is float:
			out.append(int(entry))
	return out


func _local_character_id() -> String:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return ""
	var local: Variant = game.get("local")
	if local == null:
		return ""
	return str((local as RefCounted).get("character_id"))


## A join is the first moment the host may spawn anything at all: before it
## there is no live peer under the spawner and a body spawned without one is
## the phantom `_is_host()` exists to prevent. Reconciling here covers the
## joiner AND the host's own already-standing creature in one idempotent pass.
func _on_net_peer_joined(_peer_id: int, _character_id: Variant = null) -> void:
	if not _is_host():
		return
	_reconcile_creature_proxies()


func _on_net_peer_left(peer_id: int, _reason: Variant = null) -> void:
	if not _is_host():
		return
	_host_clear_deployed(int(peer_id))


## The mirror of the boot-time defect (`trainer_spawn.gd::_on_session_ended`).
## When the session ends the multiplayer peer goes back to the offline default,
## and any body still tracked by the spawner is a spawn held under a peer that
## is not the one it was made under. Drop them all, on host and client alike.
func _on_net_session_ended(_reason: Variant = null) -> void:
	_creature_proxies.clear()
	_deployed_by.clear()
	if _creature_spawner == null:
		return
	var root := _creature_spawner.get_node_or_null(_creature_spawner.spawn_path)
	if root == null:
		return
	for child in root.get_children():
		child.queue_free()


# --- Stage B lane 4.C: the encounter transport --------------------------------
#
# `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §4. Intents up, the record down, all
# reliable on `CHANNEL_LEDGER` (D95), all answered with `world_ledger.gd`'s
# verdict shape so no caller branches on the type of the answer.
#
# There is ONE entry point (`submit_encounter_intent`) and the host runs its own
# intents through it exactly as a client's arrive -- the shape
# `ledger_rpc.gd::_commit_here()` uses, for its reason: a "host fast path" is a
# second copy of the rules, and the copy nobody ever tests against a peer.

## Whether THIS process arbitrates the fight. Asked fresh every call, never
## cached, for `_is_host()`'s reason -- and it goes through `_is_host()` rather
## than `multiplayer.is_server()`, which is TRUE with no session at all.
func is_encounter_host() -> bool:
	return _is_host()


## This process's own peer id, for the manager to compare a host decision
## against. 1 solo and on the listen server; a large random 32-bit number on a
## joiner.
func local_encounter_peer_id() -> int:
	return _local_peer_id()


## The record this peer is rendering, or {}. Read by the net harness probe.
func encounter_record() -> Dictionary:
	return _encounter


## THE ONE DOOR. Host and solo-in-a-session commit here and now; a client sends
## and gets a pending verdict, and the real answer arrives later on
## `_rpc_encounter_verdict`.
func submit_encounter_intent(intent: Dictionary) -> Dictionary:
	if _is_host():
		return _host_commit_encounter(intent, _local_peer_id())
	if not _can_encounter_rpc():
		return _encounter_pending(intent, false, "You are not connected to this world.")
	rpc_id(1, "_rpc_encounter_intent", intent)
	return _encounter_pending(intent, true, "")


## Client -> host. Never trusted with a decision: the sender id comes from the
## transport and not from the payload, so a peer cannot strike "as" somebody
## else -- the same rule `ledger_rpc.gd::_rpc_intent()` states.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_intent(intent: Dictionary) -> void:
	if not _is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var verdict := _host_commit_encounter(intent, sender)
	if not bool(verdict.get("ok", false)):
		# The whole verdict crosses, not three strings pulled out of it.
		rpc_id(sender, "_rpc_encounter_verdict", verdict)
		return
	if str(intent.get("kind", "")) == "strike_intent" \
			or str(intent.get("kind", "")) == "catch_attempt":
		# An accepted strike or throw carries numbers only its own author needs
		# (the damage it did, the wobble it earned). Everybody else gets the
		# record.
		rpc_id(sender, "_rpc_encounter_verdict", verdict)


## Host -> the one peer whose intent it answers.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_verdict(verdict: Dictionary) -> void:
	_deliver_encounter_verdict(verdict)


## Host -> every participant. §3: this is the hit points, and the only thing
## that changes a client's copy of them.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_record(rec: Dictionary) -> void:
	_encounter = rec
	if _manager != null:
		_manager.call("apply_encounter_record", rec)


## Host -> the one peer whose creature the opponent hit (§5's other half).
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_enemy_hit(encounter_id: String, payload: Dictionary) -> void:
	if _manager == null or str(_encounter.get("encounter_id", "")) != encounter_id:
		return
	_manager.call("apply_host_enemy_hit", payload)


## Host -> everybody who did NOT win the catch. §8 step 4: their HUD says who
## got it rather than their fight silently ending.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_caught_by(encounter_id: String, peer_id: int, species_id: String) -> void:
	if _manager == null or str(_encounter.get("encounter_id", "")) != encounter_id:
		return
	_manager.call("note_caught_by", peer_id, species_id)


func _deliver_encounter_verdict(verdict: Dictionary) -> void:
	if _manager == null:
		return
	match str(verdict.get("kind", "")):
		"strike_intent":
			if bool(verdict.get("ok", false)):
				_manager.call("apply_host_strike_verdict", verdict.get("delta", {}))
			else:
				_manager.call("note_encounter_refusal", verdict)
		"catch_attempt":
			_manager.call("apply_host_catch_verdict", verdict)
		_:
			if not bool(verdict.get("ok", false)):
				_manager.call("note_encounter_refusal", verdict)


# --- the host's side ------------------------------------------------------------

## Every intent §4 names, arbitrated. `peer_id` is who asked -- the requesting
## peer for a remote intent, this process for its own.
func _host_commit_encounter(intent: Dictionary, peer_id: int) -> Dictionary:
	_ensure_encounter_arbiters()
	var kind := str(intent.get("kind", ""))
	var encounter_id := str(intent.get("encounter_id", ""))
	match kind:
		"engage":
			return _host_engage(intent, peer_id)
		"strike_intent":
			return _host_strike(intent, peer_id)
		"catch_attempt":
			return _host_catch(intent, peer_id)
		"catch_finished":
			return _host_catch_finished(intent, peer_id)
		"disengage":
			var out: Dictionary = _encounter_host.call("leave", encounter_id, peer_id)
			_host_after_encounter_change(encounter_id)
			return out
	return {"ok": false, "kind": kind, "peer": peer_id, "code": "unknown_intent",
		"reason": "That is not something a fight knows how to do.", "pending": false,
		"delta": {}}


## §6. `engage` with an `encounter_id` joins a live fight; without one it mints
## a record for the fight the host is already standing in.
func _host_engage(intent: Dictionary, peer_id: int) -> Dictionary:
	var encounter_id := str(intent.get("encounter_id", ""))
	if encounter_id.is_empty():
		return {"ok": false, "kind": "engage", "peer": peer_id, "code": "malformed",
			"reason": "That fight did not say which fight it was.", "pending": false,
			"delta": {}}
	var verdict: Dictionary = _encounter_host.call("join", encounter_id, peer_id,
		"", str(intent.get("character_id", "")))
	if bool(verdict.get("ok", false)):
		_host_after_encounter_change(encounter_id)
	return verdict


## §5. The host takes its OWN position for both bodies, rebuilds the move from
## its own config, and rolls with its own `_rng`.
func _host_strike(intent: Dictionary, peer_id: int) -> Dictionary:
	var encounter_id := str(intent.get("encounter_id", ""))
	var striker := deployed_body_for(peer_id)
	if striker == null:
		return {"ok": false, "kind": "strike_intent", "peer": peer_id,
			"code": "not_participant", "reason": "You have nothing out to fight with.",
			"pending": false, "delta": {}}
	var wild := _engaged_with
	if wild == null or not is_instance_valid(wild):
		return {"ok": false, "kind": "strike_intent", "peer": peer_id,
			"code": "unknown_encounter", "reason": "That fight is over.",
			"pending": false, "delta": {}}

	# The move the peer NAMED, built from the host's own numbers and the host's
	# own two body radii. A peer cannot post itself a longer reach.
	var card: Dictionary = _creature_card_for(peer_id)
	var slot := str(intent.get("slot", "quick"))
	var move: Dictionary = COMBAT_MANAGER.host_move_profile(
		_manager.get("_moves") as RefCounted,
		"player_quick" if slot == "quick" else "player_charged",
		str(intent.get("move_id", "")),
		_body_radius(striker), _body_radius(wild))

	# The host's own position for the striking creature, never the intent's.
	var host_intent := intent.duplicate()
	host_intent["move"] = move
	var view := {
		"now_ms": Time.get_ticks_msec(),
		"origin": striker.call("centre"),
		"bodies": _encounter_body_rows(),
	}
	var verdict: Dictionary = _encounter_host.call("validate_strike", host_intent, peer_id, view)
	if not bool(verdict.get("ok", false)):
		return verdict
	var delta: Dictionary = verdict["delta"]
	if not bool(delta.get("hit", false)):
		return verdict

	var rolled: Dictionary = _manager.call("host_roll_damage", card,
		str(intent.get("move_id", "")), float(move.get("power", 9.0)))
	if rolled.is_empty():
		return verdict
	delta.merge(rolled, true)
	_encounter_host.call("set_opponent_hp", encounter_id,
		float(rolled.get("hp", 0.0)), float(rolled.get("hp_max", 1.0)))
	if bool(rolled.get("killed", false)):
		_encounter_host.call("set_phase", encounter_id, "resolving")
	_host_after_encounter_change(encounter_id, peer_id)
	return verdict


## §8, entirely delegated: `catch_arbiter.gd` owns the race and the roll, this
## function owns only handing it host truth.
func _host_catch(intent: Dictionary, peer_id: int) -> Dictionary:
	var encounter_id := str(intent.get("encounter_id", ""))
	var wild := _engaged_with
	var opponent: Dictionary = (_encounter_host.call("record", encounter_id)
		as Dictionary).get("opponent", {}) as Dictionary
	if opponent.is_empty() or wild == null or not is_instance_valid(wild):
		return {"ok": false, "kind": "catch_attempt", "peer": peer_id,
			"code": "unknown_encounter", "reason": "That fight is over.",
			"pending": false, "delta": {}}
	var hp_max := maxf(1.0, float(opponent.get("hp_max", 1.0)))
	var verdict: Dictionary = _catch_arbiter.call("attempt", encounter_id, peer_id, {
		"kind": str(_encounter_host.call("kind", encounter_id)),
		"phase": str(_encounter_host.call("phase", encounter_id)),
		"opponent_fainted": float(opponent.get("hp", 0.0)) <= 0.0,
		"species_id": str(opponent.get("species_id", "")),
		"hp_fraction": float(opponent.get("hp", 0.0)) / hp_max,
		"body_radius": _body_radius(wild),
		# The HOST's own position for the creature. Never the thrower's.
		"target_position": wild.call("centre"),
		"launch_point": intent.get("launch_point", []),
		"direction": intent.get("direction", []),
		"orb_id": str(intent.get("orb_id", "")),
		"roll": _encounter_roll(),
	}, Time.get_ticks_msec())
	if bool(verdict.get("ok", false)):
		_catch_claimant = peer_id
		_encounter_host.call("set_phase", encounter_id, "catching")
		_host_after_encounter_change(encounter_id)
	return verdict


## The winner's wobble ended. On a catch the record goes `resolving` and §8 step
## 4's `caught_by` goes to everybody else; on a breakout the fight goes back to
## `active` and anybody may throw again.
func _host_catch_finished(intent: Dictionary, peer_id: int) -> Dictionary:
	var encounter_id := str(intent.get("encounter_id", ""))
	_catch_arbiter.call("release", encounter_id, peer_id)
	var caught := bool(intent.get("caught", false))
	if caught:
		_encounter_host.call("set_phase", encounter_id, "resolving")
		_catch_claimant = 0
		for other: int in (_encounter_host.call("participants_of", encounter_id) as Array):
			if other == peer_id:
				continue
			if _can_encounter_rpc():
				rpc_id(other, "_rpc_encounter_caught_by", encounter_id, peer_id,
					str(intent.get("species_id", "")))
	else:
		_catch_claimant = 0
		if str(_encounter_host.call("phase", encounter_id)) == "catching":
			_encounter_host.call("set_phase", encounter_id, "active")
	_host_after_encounter_change(encounter_id)
	return {"ok": true, "kind": "catch_finished", "peer": peer_id, "code": "",
		"reason": "", "pending": false, "delta": {"caught": caught}}


## §5, the opponent's swing. Which PARTICIPANT the host's opponent just hit, or
## {} for a swing that connected with nobody. Tested against the host's own copy
## of each participant's deployed body -- never a client's report of where it is.
##
## Lane 4.D, §10 and 4.C's handover H6: the geometry is decided here and the
## CHOICE between the participants the swing reached is decided by
## `encounter_host.gd::pick_struck()`, which prefers whoever has been hit least
## so far. Nearest-only was the honest one-opponent behaviour and it is also
## exactly what §10 names as the failure -- "one player tanking by standing
## still" -- because two players fighting one creature meant whoever stepped
## closest absorbed the whole fight while the other watched.
##
## The count is taken HERE, at the pick, rather than after the damage roll,
## because on this path a pick IS a hit: `move_connects` is the miss test, and
## both branches of `combat_manager.gd::_host_resolve_enemy_strike_for_a_
## participant()` deal damage once a participant has been picked. Counting
## later would mean counting in two places.
func host_pick_struck_participant(encounter_id: String, cfg: Dictionary,
		origin: Vector3, facing: Vector3) -> Dictionary:
	_ensure_encounter_arbiters()
	var candidates: Array = []
	for peer_id: int in (_encounter_host.call("participants_of", encounter_id) as Array):
		var body := deployed_body_for(peer_id)
		if body == null or not is_instance_valid(body):
			continue
		var at: Vector3 = body.call("centre")
		if not MATH.move_connects(cfg, origin, facing, at):
			continue
		candidates.append({"peer_id": peer_id, "distance": origin.distance_to(at)})
	var best: Dictionary = _encounter_host.call("pick_struck", encounter_id, candidates)
	if best.is_empty():
		return {}
	var struck := int(best.get("peer_id", 0))
	_encounter_host.call("note_struck", encounter_id, struck)
	return {"peer_id": struck, "card": _creature_card_for(struck)}


## Deliver a blow the host rolled to the peer whose creature took it.
func host_deliver_enemy_hit(encounter_id: String, peer_id: int, payload: Dictionary) -> void:
	if peer_id == _local_peer_id():
		if _manager != null:
			_manager.call("apply_host_enemy_hit", payload)
		return
	if _can_encounter_rpc():
		rpc_id(peer_id, "_rpc_encounter_enemy_hit", encounter_id, payload)


## The record changed, so everybody in it is told. §3: nothing else is
## authoritative, so this is the only broadcast a participant's HUD needs.
func _host_after_encounter_change(encounter_id: String, author_peer_id: int = 0) -> void:
	var rec: Dictionary = _encounter_host.call("record", encounter_id)
	if rec.is_empty():
		return
	_encounter = rec
	if _manager != null:
		# When the host is the AUTHOR of the change, the hit reaction is left to
		# the strike render that follows a moment later
		# (`apply_host_strike_verdict`), or the body flinches twice for one blow.
		_manager.call("apply_encounter_record", rec, author_peer_id == _local_peer_id())
	if not _can_encounter_rpc() or not _is_multi_peer():
		return
	for peer_id: int in (_encounter_host.call("participants_of", encounter_id) as Array):
		if peer_id == _local_peer_id():
			continue
		rpc_id(peer_id, "_rpc_encounter_record", rec)


## §5 step 3's history, taken on the host's own clock from the host's own body.
func _tick_encounter(_delta: float) -> void:
	if not _is_host() or _encounter.is_empty():
		return
	var encounter_id := str(_encounter.get("encounter_id", ""))
	if encounter_id.is_empty() or _engaged_with == null or not is_instance_valid(_engaged_with):
		return
	_encounter_sample_countdown -= 1
	if _encounter_sample_countdown > 0:
		return
	_encounter_sample_countdown = 2
	_encounter_host.call("note_opponent_position", encounter_id,
		_engaged_with.call("centre"), Time.get_ticks_msec())
	if trainer_battle_active():
		_note_trainer_participants(encounter_id)


func _ensure_encounter_arbiters() -> void:
	if _encounter_host == null:
		_encounter_host = ENCOUNTER_HOST_SCRIPT.new(_local_peer_id())
	if _catch_arbiter == null:
		_catch_arbiter = CATCH_ARBITER_SCRIPT.new()


## The host's own die for a catch. Deliberately the MANAGER's `_rng`, not a
## second generator: §5 and §8 both say "the host's `_rng`", and two generators
## in one process would make "the host rolled it" ambiguous.
func _encounter_roll() -> float:
	if _manager == null:
		return 0.5
	var rng: Variant = _manager.get("_rng")
	if rng == null:
		return 0.5
	return float((rng as RandomNumberGenerator).randf())


## Every deployed body the host holds, as the plain rows `encounter_host.gd`
## tests ownership against (4.B's H5). Node names appear nowhere: the owner is
## read off the body.
func _encounter_body_rows() -> Array:
	var rows: Array = []
	for node in deployed_bodies():
		if not (node is Node3D) or not is_instance_valid(node):
			continue
		var body: Node3D = node
		# A peer's own outbound proxy stands in the same spot as the body it
		# mirrors (4.B's finding F3: three bodies per peer, two sharing an
		# owner). Including both would be harmless -- they resolve to the same
		# owner -- but the trainer rows below would then be outnumbered, so the
		# invisible mirror is skipped and the piloted body is the one row.
		if not body.visible:
			continue
		rows.append({
			"owner_peer_id": int(body.get("owner_peer_id")),
			"position": body.call("centre") if body.has_method("centre") else body.global_position,
			"role": "creature",
		})
	for node in get_tree().get_nodes_in_group(&"remote_trainer"):
		if not (node is Node3D) or not is_instance_valid(node):
			continue
		var trainer: Node3D = node
		rows.append({
			"owner_peer_id": int(trainer.get("peer_id")),
			"position": trainer.global_position,
			"role": "trainer",
		})
	if _player != null and is_instance_valid(_player):
		rows.append({"owner_peer_id": _local_peer_id(),
			"position": _player.global_position, "role": "trainer"})
	return rows


## The COMBAT CARD of a peer's deployed creature, as the host holds it.
##
## FINDING, recorded here rather than in a report alone: the protocol's §5 step
## 4 says the host rolls damage, and does not say where the host gets the
## STRIKER's attack stat. It cannot come from the intent -- that would be a peer
## authoring half of its own damage, which is the same class of thing §2
## forbids for positions. And it cannot be read off the creature, because a
## peer's party is its own (D100) and the host has never seen it.
##
## So it comes from 4.B's deployment announcement, extended: a peer announces
## what it has out ONCE, when it deploys, and the card rides along with the
## species. Announced once at deploy rather than quoted per swing is what makes
## it un-tunable mid-fight.
func _creature_card_for(peer_id: int) -> Dictionary:
	if peer_id == _local_peer_id() and _ally != null:
		return _creature_card(_ally)
	var row: Dictionary = _deployed_by.get(peer_id, {}) as Dictionary
	return row.get("card", {}) as Dictionary


func _creature_card(creature: RefCounted) -> Dictionary:
	if creature == null:
		return {}
	var cfg: Dictionary = PROGRESSION.config()
	return {
		"level": int(creature.get("level")),
		"attack": float(creature.call("effective_attack", cfg)),
		"defence": float(creature.call("effective_defence", cfg)),
		"creature_type": str(creature.get("creature_type")),
		"secondary_type": str(creature.get("secondary_type")),
		"move_quick": str(creature.get("move_quick")),
		"move_charged": str(creature.get("move_charged")),
		"hp": float(creature.get("hp")),
		"max_hp": float(creature.get("max_hp")),
	}


static func _body_radius(body: Node3D) -> float:
	if body != null and body.has_method("body_radius"):
		return float(body.call("body_radius"))
	return 0.5


## Whether an rpc on this node can reach anybody. False solo and in every
## headless test, where `rpc()` with no peer is an error rather than a no-op --
## `ledger_rpc.gd::_can_rpc()`'s reason, restated because that file is another
## lane's.
func _can_encounter_rpc() -> bool:
	if not is_inside_tree():
		return false
	var api := multiplayer
	return api != null and api.has_multiplayer_peer()


func _encounter_pending(intent: Dictionary, pending: bool, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": str(intent.get("kind", "")), "peer": _local_peer_id(),
		"code": "pending" if pending else "offline", "reason": reason,
		"pending": pending, "delta": {},
	}


## Every deployed creature standing in this world right now -- this process's
## own and every other peer's proxy. THE replacement for looking a single
## hardcoded node name up in the scene root.
func deployed_bodies() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(&"deployed_creature"):
		if is_instance_valid(node):
			out.append(node)
	return out


## The deployed body belonging to `peer_id`, or null. The local player's own
## body answers for the local peer id; everyone else's is their proxy.
func deployed_body_for(peer_id: int) -> Node3D:
	for node in deployed_bodies():
		if node is Node3D and int((node as Node3D).get("owner_peer_id")) == peer_id:
			return node as Node3D
	return null


func _follower_config() -> Dictionary:
	var file := FileAccess.open(OPENING_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var entry: Variant = (parsed as Dictionary).get("follower", {})
	return entry if entry is Dictionary else {}


## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2. Draws a candidate spawn point the
## same way this always has (uniform over the cluster disc's AREA -- sqrt on
## the radius fraction, or points bunch at the centre) and retries, from the
## SAME per-cluster `rng` so the meadow stays seeded/deterministic, if it
## lands inside `vegetation.gd`'s baked scatter. See
## `vegetation.gd::has_solid_scatter_near()`'s own comment for why this exists
## and why it is siting rather than clearing.
##
## Bounded and falls back to spawning anyway rather than never spawning --
## `CLEAR_ATTEMPTS` retries covers ordinary sparse-to-moderate scatter; a
## cluster whose whole disc happens to be dense enough to fail every attempt
## still gets its creature, on whichever candidate was tried last, because a
## creature that fails to appear is a worse defect than one that spawns
## partly occluded.
const CLEAR_ATTEMPTS := 6
## Added to each solid placement's own collision radius. Not the creature's
## own collider (unknown at this point -- `populate()` has not run yet, and
## running it early just to size this check would reorder the per-cluster
## `rng` draws this whole file's own comments already warn is load-bearing).
## A flat, conservative margin instead: bigger than any small creature's own
## radius, smaller than a cluster's own disc, so the retry meaningfully moves
## the candidate without exhausting the disc in ordinary spawn areas.
const CLEAR_MARGIN := 0.8

## WORLD-LIFE-0903. True when `pos` is clear of every authored road/trail --
## `playground_heightfield.gd::path_factor()`, the same road geometry the
## terrain bake and the vegetation scatter already agree on, returns 0.0 past
## a road's shoulder and rises to 1.0 on its painted centreline. Handed to
## `wild_creature.gd::set_clearance_check()` for a cluster whose `wander_radius`
## was widened enough to reach the road (see `_spawn_creatures()` below), so a
## wide wander disc can visibly cross the road without ever settling a
## destination standing on it.
func _wander_target_clear_of_road(pos: Vector3) -> bool:
	if _road_field == null:
		_road_field = HEIGHTFIELD.new()
	return float(_road_field.call("path_factor", pos.x, pos.z)) <= 0.0


func _pick_clear_spot(centre: Vector3, radius: float, rng: RandomNumberGenerator) -> Vector3:
	var spot := centre
	for attempt in CLEAR_ATTEMPTS:
		var angle := rng.randf_range(0.0, TAU)
		var distance := radius * sqrt(rng.randf())
		spot = centre + Vector3(sin(angle), 0.0, cos(angle)) * distance
		if _vegetation == null or not bool(_vegetation.call("has_solid_scatter_near", spot, CLEAR_MARGIN)):
			return spot
	return spot


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(body.call("place_on_ground", spot)):
			return true
		await get_tree().physics_frame
	return false


## The spawn table, loaded once. Cached because wild_creature()/aggressive_creature() are
## called from prompts and tests every frame, and re-reading a file per frame to
## answer "which species is the practice one" would be absurd.
var _spawns_cfg: Dictionary = {}


func spawns_config() -> Dictionary:
	if not _spawns_cfg.is_empty():
		return _spawns_cfg
	_spawns_cfg = BAND_CONTENT.load_config(SPAWNS_CONFIG, "spawns")
	return _spawns_cfg


func _respawn_delay() -> float:
	return float(spawns_config().get("respawn_seconds", DEFAULT_RESPAWN_DELAY))


## How long THIS creature waits before coming back.
##
## Its spawn entry's own `respawn_seconds` when it declared one, and the table's
## global delay otherwise -- so a creature with no override behaves exactly as
## every creature did before this existed. See `_wild_respawn`'s comment for
## why a rare aspect variant needs its own number.
func _respawn_delay_for(wild: Node3D) -> float:
	return float(_wild_respawn.get(wild, _respawn_delay()))


## Which species currently plays a ROLE — "practice", "aggressor". The roles
## block exists so this node and the smoke tests never name a species directly:
## retuning the table (swapping the ambusher, moving the tutorial creature) is
## then a data edit that cannot silently strand code pointing at a creature that
## no longer spawns.
func _role_species(role: String) -> String:
	var roles: Dictionary = spawns_config().get("roles", {}) as Dictionary
	return str(roles.get(role, ""))


## The peaceful practice creature. Named for what it is used for rather than by
## species or index, so tests and tools do not silently start pointing at a
## different creature when the spawn table changes.
func wild_creature() -> Node3D:
	return _wild_of_species(_role_species("practice"))


func aggressive_creature() -> Node3D:
	return _wild_of_species(_role_species("aggressor"))


func wild_creatures() -> Array[Node3D]:
	return _wild_creatures


## The NEAREST live instance of a species, now that a species can spawn as a
## cluster. First-found was fine when each species existed exactly once; with
## three bramblebuns, "the practice creature" has to mean the one the player is
## actually standing next to, or the engage-prompt tests would assert against a
## creature forty metres away.
func _wild_of_species(id: String) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for wild in _wild_creatures:
		if not is_instance_valid(wild) or str(wild.get("species_id")) != id:
			continue
		if _player == null:
			return wild
		var distance := _player.global_position.distance_to(wild.global_position)
		if distance < best_distance:
			best = wild
			best_distance = distance
	return best


func ally_body() -> Node3D:
	return _ally_body


## The trainer's creature currently ON THE FIELD, or null between rounds.
##
## Beside `ally_body()` and for the same reason: something that needs the body
## in the fight should be told which one it is rather than searching the tree
## for it by name. `_on_trainer_round_ended()` deliberately leaves a beaten
## creature standing in the world for a beat (`_trainer_fallen`, so it slumps
## rather than blinking out), which means a `find_child("TrainerCreature_<id>_*")`
## during round two returns the ROUND ONE corpse -- the oldest match in tree
## order, not the one being fought.
func trainer_body() -> Node3D:
	if _trainer_body != null and is_instance_valid(_trainer_body):
		return _trainer_body
	return null


func ally_instance() -> RefCounted:
	return _ally


## `CO1`. `Game.party`, the same autoload `tab_creatures.gd` reads and writes.
## Reached through `/root/Game` rather than the bare `Game` autoload name —
## `scripts/story/party_seam.gd`'s header explains why: the unit suite runs
## scripts under `--script`, which starts no autoloads at all, and this exact
## mistake has already been paid for once on this project.
func _party() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("party") if game != null else null


## WARRENS-ONCE. `_progression()` (below, already existed for trainer-defeat
## flags) is SB9's flat flag store, the same one `burrow_warrens.gd::
## is_cleared()`/`grant_clear_reward()` already read and write for the
## dungeon's own clear flag.
##
## True once `id` has fired. Empty `id` always reads false, which is what
## keeps an ordinary wild (no once-id at all) untouched by every call site
## below.
func _once_cleared(id: String) -> bool:
	if id == "":
		return false
	var progression := _progression()
	return progression != null and bool(progression.call("has", id))


## Sets `id`, idempotently — the same guarantee `progression_state.gd::
## set_flag()` already gives every other caller in the game.
func _mark_once_cleared(id: String) -> void:
	if id == "":
		return
	var progression := _progression()
	if progression != null:
		progression.call("set_flag", id)


## `CO1`: put the current follower away without releasing it from the party.
## Refuses mid-fight — the combat manager drives this same body while a fight
## is running, and freeing it out from under one is exactly the failure mode
## `_set_exploration_active()`'s own comment already warns about.
func dismiss_active_creature() -> bool:
	if _ally_body == null or not is_instance_valid(_ally_body):
		return false
	if _manager != null and bool(_manager.call("is_fighting")):
		return false
	# R8.1: and never between two rounds of a trainer battle, which is the
	# same window for the same reason — the next round re-deploys this body.
	if trainer_battle_active():
		return false
	_ally_body.queue_free()
	_ally_body = null
	_ally = null
	_announce_recall()
	return true


## `CO1`: bring `Game.party`'s active creature out, if none is out already. Which
## slot is active is the party screen's own idea — set from "send this one out
## first", `tab_creatures.gd::_read_activate()` — and until this, nothing ever read
## it back: choosing a different creature there had no effect on who was actually
## standing beside the trainer.
func summon_active_creature() -> bool:
	if _ally_body != null and is_instance_valid(_ally_body):
		return false
	if _manager != null and bool(_manager.call("is_fighting")):
		return false
	if trainer_battle_active():
		return false
	var party := _party()
	if party == null:
		return false
	var creature: RefCounted = party.call("active")
	if creature == null or bool(creature.get("fainted")) or bool(creature.get("resting")):
		return false
	return await _spawn_ally_body(creature)


## `CO1`: the third of "dismissed, recalled and swapped" — a party-screen
## re-activation reaching the creature actually on the ground. Polled against
## `party.revision` rather than a signal, the same choice `autoload/party.gd`
## and `autoload/inventory.gd` already made and explain in their own headers:
## a focused menu Button eats events, so the thing that has to notice a change
## made from inside one polls instead.
func _sync_active_creature() -> void:
	var party := _party()
	if party == null:
		return
	var revision: int = int(party.get("revision"))
	if revision == _party_revision_seen:
		return
	_party_revision_seen = revision
	if _ally_body == null or not is_instance_valid(_ally_body):
		return  # Nothing out to swap; the new active creature comes out on next recall.
	if _manager != null and bool(_manager.call("is_fighting")):
		return  # Never mid-fight — `_start_fight` already snapshotted who is in it.
	if trainer_battle_active():
		return  # Nor between its rounds; the next round re-deploys the same body.
	var active_creature: RefCounted = party.call("active")
	if _ally != null and bool(_ally.get("resting")):
		dismiss_active_creature()
		if active_creature != null and not bool(active_creature.get("resting")):
			summon_active_creature()
		return
	if active_creature == null or active_creature == _ally:
		return  # The change wasn't to the creature that is actually out.
	dismiss_active_creature()
	summon_active_creature()


## `CO1`'s bound action, read whenever nothing else owns it. Guarded the same
## way `_read_engage_input()` is: no reading past a running fight, since the
## combat manager drives `_ally_body` for the length of one.
##
## OF25: also deaf while `_arbiter` is (a conversation, the naming prompt, the
## starter picker) -- `R` is bound to `creature_recall`, so typing a name that
## happened to contain one used to summon or dismiss the ally out from under
## the panel. Reuses the same `enabled` flag `_read_engage_input()` already
## defers to above, rather than a second modal check invented here.
func _read_creature_control_input() -> void:
	if _manager != null and bool(_manager.call("is_fighting")):
		return
	if trainer_battle_active():
		return
	if _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):
		return
	# OP21-03/OP21-06: a non-pausing panel (Build) owning input must own the
	# d-pad exclusively. A tree-pausing panel needs no entry here -- this node
	# is PROCESS_MODE_PAUSABLE like the rest of the world, so it has already
	# stopped running while one of those is up.
	if INPUT_OWNER.current(get_tree()) != null:
		return

	# CONTROLLER-MAP: one verb, one button. "Cycle party member" and "switch
	# which creature you are piloting" are the same action on LB, so the two
	# directional `combat_switch_*` actions collapsed into `party_cycle` and the
	# d-pad went back to being the hotbar in every context, combat included.
	# Party.revision drives the existing _sync_active_creature() path, so a
	# visible follower is recalled and replaced cleanly rather than a second
	# body being spawned.
	if Input.is_action_just_pressed("party_cycle"):
		var party := _party()
		var game := get_node_or_null(^"/root/Game")
		if party != null and bool(party.call("cycle_active", 1)):
			var active: RefCounted = party.call("active")
			if game != null and active != null:
				game.call("push_world_message", "Active creature: %s" % str(active.call("label")))
		elif game != null:
			game.call("push_world_message", "No other available creature")
		return

	if not Input.is_action_just_pressed("creature_recall"):
		return
	if _ally_body != null and is_instance_valid(_ally_body):
		dismiss_active_creature()
	else:
		summon_active_creature()


## The non-actionable status line `interaction_offer()` falls back to once
## nothing nearby is offering anything else — see that function's own comment
## on why `PROMPTS`'s single line can carry a second button's prompt at all.
##
## Priority -2, one below `riding_controller.gd::RIDE_PRIORITY` (-1) — this is
## the true floor: a plain status line that does nothing when pressed must
## never win a tie against an offer that DOES something, riding's own included.
func _creature_control_offer() -> Dictionary:
	# OWNER DIRECTIVE 2026-08-23 §3: with the build hammer out, this line moves
	# to the party-cycle button context for the duration, and Build has the
	# interact prompt to itself. Nothing is lost -- `_handle_creature_control()`
	# reads `creature_recall` straight off the pad and never consulted this
	# offer, and `playground_hud.gd::_exploration_legend_text()` puts the verb
	# up beside Change Creature with the right word on it, which is the one
	# place it had no on-screen home before.
	if BUILD_HOLD.hammer_is_out(get_tree()):
		return {}
	if _ally_body != null and is_instance_valid(_ally_body):
		if _ally == null:
			return {}
		return PROMPTS.offer(
			"%s%sPut %s away" % [INPUT_GLYPH.icon("creature_recall"), PROMPTS.GAP, _ally.label()],
			0.0, -2, false
		)
	var party := _party()
	var creature: RefCounted = party.call("active") if party != null else null
	if creature == null or bool(creature.get("fainted")):
		return {}
	return PROMPTS.offer(
		"%s%sCall out %s" % [INPUT_GLYPH.icon("creature_recall"), PROMPTS.GAP, creature.label()],
		0.0, -1, false
	)


## The line the HUD draws. Still asked of this node even when the arbiter is
## deciding it, so `combat_hud.gd` keeps one source for the prompt and does not
## have to know whether the scene it is in has arbitration.
func prompt() -> String:
	if _arbiter != null and is_instance_valid(_arbiter):
		return str(_arbiter.call("prompt"))
	return _prompt


## `EV9-double-prompt`: is `prompt()` right now genuinely this node's own
## offer (engage, the fainted statement, the creature-control fallback), or is it
## mirroring whatever unrelated provider is winning the shared arbiter
## (Grandpa, a starter, a harvest node)? `combat_hud.gd` needs this to know
## whether its prompt row should draw at all outside a fight — the row exists
## to keep showing "Engage X" before a fight starts, never to repeat a line
## `PlaygroundHUD` is already showing for something else entirely.
## No arbiter (the combat sandbox) means this node is the only source of a
## prompt there is, so it always owns whatever it is showing.
func owns_active_prompt() -> bool:
	# True when this node's own offer is the winning line (or there is no
	# arbiter at all — the combat sandbox). CombatHUD renders director-owned
	# lines; PlaygroundHUD skips them for exactly that reason (see its
	# `_prompt_belongs_to_combat()`) — that split, not a blanket blank, is
	# what keeps one prompt on screen. `tests/smoke_no_double_prompt.gd`
	# pins both halves: a bed offer must not echo on CombatHUD, and an
	# engage offer must still show there before a fight.
	if _arbiter == null or not is_instance_valid(_arbiter):
		return true
	return _arbiter.call("winning_provider") == self


## Hand the prompt line, and the interact button, to a scene-wide arbiter.
func set_arbiter(node: Node) -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		_arbiter.call("unregister", self)
	_arbiter = node
	if _arbiter != null:
		_arbiter.call("register", self)
		# Whatever this node had published is no longer the whole truth.
		_prompt = ""
		prompt_changed.emit("")


## --- the provider contract, see scripts/world/interaction_arbiter.gd --------

func interaction_offer(from: Vector3) -> Dictionary:
	if _manager == null or bool(_manager.call("is_fighting")):
		return {}
	# R8.1: nothing this node offers is available between two rounds of a
	# trainer battle. The fight is not running for that beat and every gate
	# below would open — engage a passing wild creature, put your creature
	# away — in the middle of somebody else's challenge.
	if trainer_battle_active():
		return {}
	# T2-GATEF-RUN4 (GAME-0, T2-BUILDPLACE finding 2026-08-30): this used to
	# carry priority 100 at distance 0.0, and prompt_arbiter.gd's own
	# priority-before-distance rule made that outrank EVERY other offer in
	# the world, permanently, from the instant the tracked ally fainted --
	# not just wild-engage (the one thing this statement is actually about)
	# but every village greeting, every trainer's own challenge prompt and
	# every harvest node's prompt too, with no proximity gate at all and no
	# recovery until a fresh save/load. A player whose only creature fainted
	# during the S03 tutorial's own catch loop could not interact with
	# ANYTHING afterward. Ordinary priority (0, `interactable.gd`'s own
	# default) and a distance past any real interact radius keep the
	# statement winning -- and still telling the player why nothing else is
	# responding -- when it is the only offer on the table, but let it lose
	# the tie-break to any real, closer offer instead of substituting for
	# one.
	if _ally != null and _ally.fainted:
		return PROMPTS.offer("%s is out of the fight." % _ally.display_name, 9999.0, 0, false)
	var candidate := _engageable()
	if candidate != null:
		return PROMPTS.offer(
			"Engage %s" % str(candidate.get("display_name")),
			from.distance_to(candidate.global_position)
		)
	return _creature_control_offer()


func interaction_activate() -> void:
	var candidate := _engageable()
	if candidate == null:
		return
	# For a PEACEFUL creature this press is the only way in. GAME_DESIGN.md §14
	# forbids proximity starting a fight with one.
	_start_fight(candidate)


func _process(delta: float) -> void:
	_tick_respawn(delta)
	_tick_trainer_battle(delta)
	_tick_encounter(delta)
	_sync_spawn_gates()
	# After the gate sync, not before: a gate that just opened calls
	# `creature_body.gd::_on_visibility_changed()` via `wild.visible = true`,
	# which turns `physics_process` back ON regardless of distance. Running
	# streaming second means a still-distant, newly-gated-visible creature is
	# put back to sleep in the same frame instead of one frame late.
	_tick_streaming()
	_sync_active_creature()
	_show_a_revived_follower()
	_update_prompt()


## A creature that stops being fainted has to come back out.
##
## `combat_manager.gd::_finish()` hides the shared deployed body on its way out
## of every fight, and `_set_exploration_active(true)` -- the one thing that
## shows it again -- refuses to for a fainted creature, correctly: a knocked-out
## creature should not be standing beside the trainer. But that is a HANDOFF,
## and it is the last one that runs. Nothing was watching for the creature
## getting back up afterwards, so a Revive used out of the belt (D40's whole
## point) cleared `fainted` on a body that stayed invisible until the player
## happened to recall and re-summon it, or walked into another fight --
## `begin()` shows it again, so the state repaired itself only by being fought
## through, which is exactly the thing a revived-but-invisible creature makes
## you not want to do.
##
## Found while closing CAP-1 (ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md):
## the opening's own faint recovery goes through the same door, so this is what
## makes any un-fainting outside a fight visible at all.
##
## Deliberately only the visibility. `set_following` is already true from the
## exploration handoff, and re-running the rest of that handoff every frame is
## what its own comment warns against.
func _show_a_revived_follower() -> void:
	if _ally == null or _ally_body == null or not is_instance_valid(_ally_body):
		return
	if _ally_body.visible:
		return
	# The three states that own the body's visibility themselves, in the order
	# the rest of this file already checks them.
	if _manager != null and bool(_manager.call("is_fighting")):
		return
	if trainer_battle_active():
		return
	if bool(_ally.get("fainted")) or bool(_ally.get("resting")):
		return
	_ally_body.visible = true


## Engage is read on the physics tick, not the idle tick.
##
## `Input.is_action_just_pressed()` is scoped to whichever frame the press was
## recorded in, and reading it from `_process` while CombatManager reads its own
## actions from `_physics_process` means one press can be seen by one and missed
## by the other depending on where in the frame it landed. It cost a survey run
## that captured four frames of a fight that had never started.
func _physics_process(_delta: float) -> void:
	_read_engage_input()
	_read_creature_control_input()


## Two clocks per knocked-out creature: how long its body lies there, and how
## long until it is back. Kept per-node so two faints cannot cancel each other.
func _tick_respawn(delta: float) -> void:
	for wild: Node3D in _faint_timers.keys().duplicate():
		var left: float = float(_faint_timers[wild]) - delta
		if left > 0.0:
			_faint_timers[wild] = left
			continue
		_faint_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("clear_faint")

	for wild: Node3D in _respawn_timers.keys().duplicate():
		var left: float = float(_respawn_timers[wild]) - delta
		if left > 0.0:
			_respawn_timers[wild] = left
			continue
		_respawn_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("revive_at_home")
			# `revive_at_home()` unconditionally turns physics_process back ON
			# (it predates streaming and is right to, on its own terms — a
			# creature standing still fainted is not what "revived" means).
			# STREAM-D: if this creature's cluster is still marked inactive, put
			# it back to sleep immediately rather than leave it awake until the
			# next time the player's distance to this exact cluster happens to
			# cross the activation radius — which, for a cluster the player has
			# already walked away from, may be a very long time.
			var cluster: Dictionary = _wild_cluster.get(wild, {})
			if not cluster.is_empty() and not bool(cluster.get("active", true)):
				wild.set_physics_process(false)
			# Orbs deliberately do NOT refill here any more. They are real
			# satchel items now — Grandpa's gift is the starting supply, and
			# running dry is a real state the game is allowed to reach.


## R5.3 (D20's deferred schema extension). Extracts spawns.json's optional
## per-entry `time`/`weather` gate into the small dict `_wild_gates` stores,
## or {} for an ungated entry -- callers check is_empty() rather than typing
## the field names twice.
func _gate_for_spawn(spawn: Dictionary) -> Dictionary:
	var gate := {}
	var time_req := str(spawn.get("time", ""))
	if time_req != "":
		gate["time"] = time_req
	var weather_req: Variant = spawn.get("weather", [])
	if weather_req is Array and not (weather_req as Array).is_empty():
		gate["weather"] = weather_req
	return gate


## True if the wild(s) this gate describes should be present RIGHT NOW.
##
## `time` and `weather` are independent axes, same as world_look.gd/
## world_weather.gd themselves -- both must hold when both are set.
func _gate_active(gate: Dictionary) -> bool:
	if gate.has("time"):
		var wants_night := str(gate["time"]) == "night"
		if wants_night != _is_night():
			return false
	if gate.has("weather"):
		var allowed: Array = gate["weather"]
		if not allowed.has(_current_weather()):
			return false
	return true


## Group lookup, not a NodePath -- see world_look.gd's own GROUP comment.
## Missing (a scene with no WorldLook, e.g. the combat sandbox) reads as
## "day never became night", which keeps every gated spawn exactly as
## reachable as an ungated one used to be.
func _is_night() -> bool:
	var look: Node = get_tree().get_first_node_in_group(&"day_cycle")
	return look != null and look.has_method("is_dark") and bool(look.call("is_dark"))


## Same pattern as _is_night(); missing WorldWeather reads as "clear",
## world_weather.gd's own default state.
func _current_weather() -> String:
	var weather: Node = get_tree().get_first_node_in_group(&"weather")
	if weather != null and weather.has_method("weather"):
		return str(weather.call("weather"))
	return "clear"


## Show/hide every gated wild against the current time/weather. Skips a wild
## mid-fight (`_engaged_with`) or mid-faint/respawn (already own its
## visibility via `_faint_timers`/`_respawn_timers`) -- toggling a creature
## out from under either would read as it vanishing mid-encounter rather than
## as the meadow's population changing between encounters.
func _sync_spawn_gates() -> void:
	for wild: Node3D in _wild_gates.keys():
		if not is_instance_valid(wild):
			continue
		if wild == _engaged_with or _faint_timers.has(wild) or _respawn_timers.has(wild):
			continue
		wild.visible = _gate_active(_wild_gates[wild])


## Distance beyond a cluster's own scatter radius at which its members start
## ticking.
##
## Must clear the largest range at which a member could plausibly first need
## to react to the player — aggression's own `notice_range` (the distance at
## which an aggressive creature starts closing) and the peaceful "stops and
## looks at you" `notice_range` in `wild.json`'s wild config — with room to
## spare, so a creature is never activated already inside its own detection
## range with no runway to notice anything. Read from the same two config
## blocks `_roll_wild_level()`'s neighbours already load (CATCH's own
## `aggression` block, MATH's `wild` block) instead of hard-coded, so
## retuning either range in data keeps this buffer honest with no matching
## code change. Cached: this is read from `_tick_streaming()`, which runs
## every `_process()` tick.
func _activation_radius_margin() -> float:
	if _activation_margin >= 0.0:
		return _activation_margin
	var aggro_notice := float(CATCH.config().get("aggression", {}).get("notice_range", 14.0))
	var peaceful_notice := float(MATH.config().get("wild", {}).get("notice_range", 9.0))
	_activation_margin = maxf(aggro_notice, peaceful_notice) + 10.0
	return _activation_margin


## STREAM-D. Distance-based activation, ticked per CLUSTER rather than per
## creature — see `_clusters`'s own header for why that is the unit.
##
## Ticks a cluster's whole membership together, and only on an actual
## transition: two creatures from the same cluster reading a different
## activation state mid-transition is not a bug worth guarding against (they
## are within one cluster radius of each other; the player cannot be
## meaningfully "in range" of one and not the other), and re-touching every
## member of every cluster every frame is exactly the per-creature cost this
## exists to avoid paying.
##
## Guards the same three states `_sync_spawn_gates()` above already guards,
## for the same reason: a creature `_engaged_with` (a fight — which is also
## where a catch happens), fainting (`_faint_timers`) or respawning
## (`_respawn_timers`) owns its own physics_process state already, and
## switching it off from under any of those would be exactly the "deactivated
## mid-catch" bug this task was warned against. A gated-invisible creature
## (`_wild_gates`) is skipped for a different reason: its own visibility is
## `_sync_spawn_gates()`'s business, and `creature_body.gd`'s
## `_on_visibility_changed()` already ties that visibility to
## physics_process — fighting over the same flag from two systems would just
## mean whichever ran last in `_process()` wins.
##
## Deliberately does NOT touch position, level, IVs, traits or the shiny
## roll, and never frees or rebuilds a body: activation only ever flips
## `set_physics_process` — the one existing precedent for switching a wild
## creature's tick off, `wild_creature.gd::notify_fainted()`. Nothing here
## consumes the per-cluster `rng` `_spawn_creatures()` seeds and never
## `randomize()`s, so a creature that walks back into range is the exact node
## it was, not a fresh draw — which is what keeps this compatible with
## `_spawn_creatures()`'s own determinism promise: that rng is spent once, at
## boot, and streaming never asks it for anything.
func _tick_streaming() -> void:
	if _player == null:
		return
	if PERF_TRACE.enabled:
		var t0 := Time.get_ticks_usec()
		_stream_clusters()
		PERF_TRACE.record("wild cluster streaming", Time.get_ticks_usec() - t0)
		return
	_stream_clusters()


## Stage B lane 4.B. A cluster is awake if ANY occupant of this realm is near
## it, not if the local player is.
##
## This used to read `_player.global_position` alone. With two players in one
## realm that starves whoever is not the host: the wild creatures around the
## second player never tick, so the meadow they are standing in is empty of
## anything that moves, notices them or can be fought -- and it reads as a
## dead world rather than as a bug, because a creature that never ticks also
## never falls over.
##
## The union is the local player plus every replicated trainer body standing
## in this scene (lane 2.C's `remote_trainer` group). Being in this tree is
## what "in this realm" means: D97 gives each realm its own world scene and
## its own `Spawned/Trainers` container, so a peer in another realm has no
## body here at all. In solo the group is empty and the answer is the local
## player's position exactly as before.
func _stream_clusters() -> void:
	var occupants := _realm_occupant_positions()
	var margin := _activation_radius_margin()
	for cluster: Dictionary in _clusters:
		var centre: Vector3 = cluster["centre"]
		var radius: float = cluster["radius"]
		var reach := radius + margin
		var should_be_active := false
		for at: Vector3 in occupants:
			if at.distance_to(centre) <= reach:
				should_be_active = true
				break
		if should_be_active == bool(cluster["active"]):
			continue
		cluster["active"] = should_be_active
		for wild: Node3D in (cluster["members"] as Array[Node3D]):
			_set_wild_active(wild, should_be_active)


## Where the people in this realm are standing. The local player first,
## because in solo it is the only entry and this must stay one distance test
## per cluster there.
##
## The local peer's OWN outbound trainer proxy is deliberately not filtered
## out: it sits on top of `_player` by construction (`remote_trainer.gd`
## keeps it co-located), so including it costs one extra distance test and
## can never change an answer -- where filtering it would mean asking each
## body whether it is ours, per body, per frame.
func _realm_occupant_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if _player != null and is_instance_valid(_player):
		out.append(_player.global_position)
	if not is_inside_tree():
		return out
	var tree := get_tree()
	if tree == null:
		return out
	for body in tree.get_nodes_in_group(&"remote_trainer"):
		if body is Node3D and is_instance_valid(body):
			out.append((body as Node3D).global_position)
	return out


func _set_wild_active(wild: Node3D, active: bool) -> void:
	if not is_instance_valid(wild):
		return
	if wild == _engaged_with or _faint_timers.has(wild) or _respawn_timers.has(wild):
		return
	if _wild_gates.has(wild) and not wild.visible:
		return  # the gate owns this one's visibility, and with it its process state
	if active:
		_reground_if_fallen(wild)
	wild.set_physics_process(active)


## GATE-D. Put a creature back on the ground if it is under it, before handing
## it back its physics.
##
## Found by `tools/_probe_wild_grounding.gd` (authored by the Band 3 lane, whose
## driven run met 11 of that region's 155 creatures). `creature_body.gd`
## subtracts gravity on any frame `is_on_floor()` is false, and Terrain3D builds
## collision dynamically around the CAMERA within a granted radius --
## `playground_world.gd` hands it the player's camera. So a creature spawned
## kilometres away has no floor on the frame it spawns, and falls at 26 m/s^2
## for as long as the world runs. The probe measured 137 of Band 3's 155
## creatures 190-200m under the terrain and still descending, with Bands 4 and 5
## at 100%.
##
## Nothing reported it, which is why 155 authored creatures and a region that
## plays empty were both true at once: `_stand_on_ground` succeeds --
## `place_on_ground` puts the body at the analytic height and returns true --
## and the fall happens afterwards, in physics, silently.
##
## Distance activation is most of the cure: a creature that never ticks never
## falls, and merging it took the probe's worst band from 88% underground to 0%.
## This closes the case activation cannot: the moment a cluster DOES activate,
## the player is walking toward it, and Terrain3D may not have built collision
## there yet. Without this the creature would resume physics with no floor and
## start the same fall, now in front of the player.
##
## Re-placed at its CURRENT x/z, not at `home`: a creature that wandered while
## active and then slept is legitimately where it stopped, and dragging it back
## to its authored spot on every activation would undo the wandering. Only a
## body that is genuinely under the ground is moved.
func _reground_if_fallen(wild: Node3D) -> void:
	var world := get_parent()
	if world == null or not world.has_method("ground_height_at"):
		return
	var at := wild.global_position
	var ground := float(world.call("ground_height_at", at.x, at.z))
	if is_nan(ground) or at.y >= ground - REGROUND_DEPTH_M:
		return
	wild.call("place_on_ground", Vector3(at.x, 0.0, at.z))


## The nearest wild creature the player could choose to fight right now.
func _engageable() -> Node3D:
	if _ally == null or _manager == null or _ally.fainted:
		return null
	if bool(_manager.call("is_fighting")) or trainer_battle_active():
		return null

	var best: Node3D = null
	var best_distance := _engage_range
	for wild in _wild_creatures:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance := _player.global_position.distance_to(wild.global_position)
		if distance <= best_distance:
			best = wild
			best_distance = distance
	return best


func _update_prompt() -> void:
	# The arbiter is drawing the line now, from `interaction_offer` below.
	# Computing a second answer here would be a second opinion nobody reads.
	if _arbiter != null and is_instance_valid(_arbiter):
		return
	var text := ""
	if bool(_manager.call("is_fighting")):
		text = ""
	elif _ally != null and _ally.fainted:
		text = "%s is out of the fight." % _ally.display_name
	else:
		var candidate := _engageable()
		if candidate != null:
			text = "%s   Engage %s" % [INPUT_GLYPH.icon("interact"), str(candidate.get("display_name"))]
		else:
			text = str(_creature_control_offer().get("label", ""))
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


func _read_engage_input() -> void:
	# One reader of `interact` per scene. With an arbiter present it does the
	# reading and calls `interaction_activate()`; two nodes each calling
	# `is_action_just_pressed` is how one press starts a fight AND talks to
	# Grandpa.
	if _arbiter != null and is_instance_valid(_arbiter):
		return
	if not Input.is_action_just_pressed("interact"):
		return
	var candidate := _engageable()
	if candidate == null:
		return
	# For a PEACEFUL creature this press is the only way in. GAME_DESIGN.md §14
	# forbids proximity starting a fight with one, and nothing but this line
	# starts a fight with Bramblebun.
	_start_fight(candidate)


## An aggressive creature has reached the trainer and is starting the fight itself.
##
## §14 lists "Aggressive creature initiates" beside the player's own routes in, and
## scopes the "not simple proximity" rule to peaceful creatures. This is that other
## route, and it is guarded rather than trusted: the creature asks, and gets
## refused if a fight is already running or the player has nothing to fight with.
func _on_wild_wants_to_engage(wild: Node3D) -> void:
	if not bool(wild.get("aggressive")):
		push_error("%s asked to initiate but is not aggressive" % wild.name)
		return
	if _ally == null or _ally.fainted or bool(_manager.call("is_fighting")):
		return
	if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
		return
	_start_fight(wild)


## One way in, whoever started it. A second route that forgot to suspend
## exploration or hand over the camera would be a bug that only shows up when
## something ambushes you. R8.1's trainer battles come through here too, with
## `opponent_owned` true — that flag is the whole of what a trainer's creature
## does differently once the fight is running.
func _start_fight(wild: Node3D, opponent_owned: bool = false) -> void:
	var party_obj := _party()
	var best: RefCounted = party_obj.call("best") if party_obj != null else null
	if not bool(_manager.call(
		"begin", _player, wild, _ally_body, _fight_party(), _camera_rig, best, opponent_owned
	)):
		return
	_engaged_with = wild
	_set_exploration_active(false)
	_open_encounter_if_networked(wild, opponent_owned)


## Stage B lane 4.C. Stand a host-arbitrated encounter record up behind the
## fight that just started, and tell the world it exists so a second player can
## join it (§6).
##
## HOST ONLY, and that is a scope statement rather than an oversight. 4.B's
## handover H1: Terrain3D FULL_GAME collision is unimplemented and wild
## creatures are not replicated, so a CLIENT's wilds are its own local
## simulation and the host has never heard of the one it is standing in front
## of. There is therefore nothing for the host to mint a record ABOUT. A
## client's own fight against its own wild is left exactly as it was before this
## lane -- local, unarbitrated, and unchanged -- and what a client CAN do is
## join a fight the host is holding, which is §6 and the thing two players
## actually do. When wild replication lands, minting from a client's `engage`
## becomes one more branch here.
##
## Solo is not merely unaffected: `_is_multi_peer()` is false, so not one line
## below runs.
func _open_encounter_if_networked(wild: Node3D, opponent_owned: bool) -> void:
	if not _is_multi_peer() or not _is_host():
		return
	_ensure_encounter_arbiters()
	var instance: Variant = wild.get("instance")
	if instance == null:
		return
	var at: Vector3 = wild.call("centre")
	var opponent := {
		"species_id": str((instance as RefCounted).get("species_id")),
		"display_name": str((instance as RefCounted).get("display_name")),
		"level": int((instance as RefCounted).get("level")),
		"hp": float((instance as RefCounted).get("hp")),
		"hp_max": float((instance as RefCounted).get("max_hp")),
		"owner_npc": str(_trainer_spec.get("id", "")) if opponent_owned else "",
		"position": [at.x, at.y, at.z],
	}
	# Lane 4.D. The trainer's NEXT creature is the same fight, not a new one: a
	# record minted per round would drop a joiner between rounds and pay them
	# for none of a boss they fought two thirds of. `set_opponent()` carries the
	# participants across; only a battle that has no live record yet mints one.
	var live_id := str(_encounter.get("encounter_id", ""))
	if opponent_owned and _resume_trainer_encounter(live_id) \
			and bool(_encounter_host.call("set_opponent", live_id, opponent)):
		_encounter = _encounter_host.call("record", live_id)
		_encounter_sample_countdown = 0
		_manager.call("bind_encounter", self, live_id, str(_encounter.get("kind", "trainer")))
		_host_after_encounter_change(live_id)
		_note_trainer_participants(live_id)
		return
	var rec: Dictionary = _encounter_host.call("open", _local_peer_id(),
		_encounter_realm(),
		_encounter_kind(opponent_owned),
		opponent,
		"", _local_character_id())
	_encounter = rec
	_encounter_sample_countdown = 0
	_manager.call("bind_encounter", self, str(rec["encounter_id"]), str(rec["kind"]))
	if opponent_owned:
		_note_trainer_participants(str(rec["encounter_id"]))
	if _can_encounter_rpc():
		rpc("_rpc_encounter_opened", rec)


## §3's `kind`. A boss is DATA, not a code path: `trainers.json`'s `boss_ranks`
## decides, one encounter record covers all three, and the only thing being a
## boss changes is what the record says it is.
func _encounter_kind(opponent_owned: bool) -> String:
	if not opponent_owned:
		return "wild"
	return "boss" if TRAINERS.is_boss(_trainer_spec) else "trainer"


## D97: the realm this fight belongs to, stamped explicitly. Never a global
## "current realm" -- from Wave 6 two peers stand in two realms at once and a
## record stamped with whichever one the host happens to be in files a
## Cloudreach fight in the Meadows.
func _encounter_realm() -> String:
	# Lane MP-REALM-REOPEN. This asked `Game.current_realm` -- the exact thing
	# the paragraph above forbids, and harmless only for as long as the host
	# could not be standing anywhere else. It can now: a host in Cloudreach
	# runs a headless MEADOWS shell (`scripts/net/realm_shells.gd`), and that
	# shell holds a director of its own whose fights are Meadows fights. Ask
	# the WORLD this director belongs to, which answers `world_realm()` in both
	# world roots and in a shell answers the shell's realm.
	var node: Node = get_parent()
	while node != null:
		if node.has_method("world_realm"):
			var owned := str(node.call("world_realm"))
			if not owned.is_empty():
				return owned
		node = node.get_parent()
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return "meadows"
	var realm := str(game.get("current_realm"))
	return realm if not realm.is_empty() else "meadows"


## Host -> everybody in the session. §3's "a non-participant in the same realm
## receives only enough to draw the bodies": this is the announcement that a
## fight EXISTS and can be joined. It is not the authoritative record for
## anybody who is not in it, and nothing here binds a manager.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_encounter_opened(rec: Dictionary) -> void:
	_joinable_encounters[str(rec.get("encounter_id", ""))] = rec


## Every fight this peer has been told about and is not in. Keyed by id, so a
## re-announcement replaces rather than duplicates.
var _joinable_encounters: Dictionary = {}


## Fights this peer could join right now, newest announcement last.
func joinable_encounters() -> Array:
	var out: Array = []
	for id: Variant in _joinable_encounters.keys():
		out.append(_joinable_encounters[id])
	return out


## §6. Join a fight already running. No reset, no re-intro camera for anyone
## already in it: the only thing that happens on the host is that this peer is
## added to `participants`.
##
## The body this peer FIGHTS BESIDE is its own nearest wild, and that is a
## stand-in, not the opponent -- see `_open_encounter_if_networked()`'s note on
## 4.B's H1. Everything that decides an outcome comes off the record and off the
## host: the hit points this peer's HUD draws, whether its swings connect,
## whether its orb catches. The stand-in is what its creature stands next to and
## what the camera frames, and when wild replication lands it stops being a
## stand-in without anything here changing.
func join_encounter(encounter_id: String) -> bool:
	if encounter_id.is_empty() or _manager == null:
		return false
	if bool(_manager.call("is_fighting")):
		return false
	if _ally == null or _ally_body == null or not is_instance_valid(_ally_body):
		return false
	var stand_in := nearest_live_wild()
	if stand_in == null:
		push_warning("no creature here to stand in for encounter '%s'" % encounter_id)
		return false
	var party_obj := _party()
	var best: RefCounted = party_obj.call("best") if party_obj != null else null
	if not bool(_manager.call("begin", _player, stand_in, _ally_body, _fight_party(),
			_camera_rig, best, false)):
		return false
	_engaged_with = stand_in
	_set_exploration_active(false)
	_manager.call("bind_encounter", self, encounter_id,
		str((_joinable_encounters.get(encounter_id, {}) as Dictionary).get("kind", "wild")))
	submit_encounter_intent({"kind": "engage", "encounter_id": encounter_id,
		"character_id": _local_character_id()})
	return true


## The nearest wild creature this peer could fight, or null. Public because the
## join path and the net harness both need the same answer, and two copies of
## "which creature is nearest" would eventually differ.
func nearest_live_wild() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for wild: Node3D in _wild_creatures:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance: float = _player.global_position.distance_to(wild.global_position)
		if distance < best_distance:
			best_distance = distance
			best = wild
	return best


## Who is IN this fight: the creature standing beside the trainer first,
## then the rest of the living party behind it.
##
## The deployed creature has to be index 0 — `combat_manager.begin()` pilots
## `_party[0]` and says so — and which slot `Game.party` has it in is the
## party screen's own business, so the order here is the fight's, not the
## belt's. Everything that indexes into it (D32's `switchable_indices()` /
## `request_switch()`, the HUD's party strip, `_award_victory`'s bench share)
## reads that same array, so the two cannot disagree.
##
## This used to be `[_ally]` — the single deployed creature — which meant D32's
## switching had nothing to switch to and `_award_victory`'s documented bench
## share reached nobody, in wild fights and trainer fights alike. Fixed in one
## place rather than two, because a trainer battle where switching works and a
## wild one where it does not is a rule the player would have to discover.
func _fight_party() -> Array[RefCounted]:
	var out: Array[RefCounted] = []
	if _ally != null:
		out.append(_ally)
	var party_obj := _party()
	if party_obj != null:
		for member: Variant in party_obj.call("members"):
			var creature := member as RefCounted
			if creature == null or creature == _ally or bool(creature.get("fainted")):
				continue
			out.append(creature)
	return out


func _on_combat_exited(outcome: String) -> void:
	# A voluntary combat switch reuses the same body but changes which live
	# CreatureInstance it represents. Carry that choice back into exploration
	# before any wild/trainer exit path runs; otherwise the body remains skinned
	# as the incoming creature while this director and Game.party still call the
	# old one active, and the next encounter silently pilots mismatched data.
	var deployed: RefCounted = _manager.call("active_creature") as RefCounted
	if deployed != null and deployed != _ally:
		_ally = deployed
		var party := _party()
		if party != null and not bool(deployed.get("fainted")) \
				and not bool(deployed.get("resting")):
			var members: Array = party.call("members")
			var party_index := members.find(deployed)
			if party_index >= 0 and party.call("active") != deployed:
				party.call("set_active", party_index)

	# R8.1: a round of a trainer battle resolves on its own terms — the next
	# creature may still be coming, and exploration must not come back if it
	# is. Checked before anything else here so the wild path below never sees
	# a trainer's creature.
	if _trainer_body != null and _engaged_with == _trainer_body:
		_on_trainer_round_ended(outcome)
		return

	_set_exploration_active(true)
	# Stage B lane 4.C. The fight is over for THIS peer. The manager has already
	# sent `disengage` from `_finish()` -- §9's "a disconnect, a downed trainer
	# and walking away are the same event" -- so all that is left here is to
	# stop rendering a record this peer is no longer in. On the host the record
	# itself survives until its last participant leaves, which is exactly what
	# keeps a second player's fight running when the first one dies.
	var finished_id := str(_encounter.get("encounter_id", ""))
	_encounter = {}
	if _is_host() and not finished_id.is_empty() and _encounter_host != null:
		if str(_encounter_host.call("phase", finished_id)) == "done":
			_encounter_host.call("forget", finished_id)
			_catch_arbiter.call("forget", finished_id)
		_joinable_encounters.erase(finished_id)

	var wild := _engaged_with
	_engaged_with = null

	if wild != null and is_instance_valid(wild):
		# WARRENS-ONCE: a guardian, alpha or elder leaving the field the
		# honest way (beaten or caught) is gone for good, not on the usual
		# cooldown — the flag fires here and no respawn timer is ever set for
		# it, so it cannot come back for the rest of this session, and
		# `spawn_wild()`/`_spawn_creatures()` will not spawn it again once
		# the scene rebuilds (leave and return, or a reload). A wild that was
		# never given a once-id (`_once_only.has(wild)` false) is untouched —
		# same faint/respawn/catch path as before.
		var once_id: String = str(_once_only.get(wild, ""))
		match outcome:
			"won":
				# It stays on the ground for a moment before it clears. §15: the
				# body is the feedback for having over-damaged something you
				# might have caught.
				wild.call("notify_fainted")
				_faint_timers[wild] = float(CATCH.config().get("faint", {}).get("linger_seconds", 4.0))
				if once_id != "":
					_mark_once_cleared(once_id)
				else:
					_respawn_timers[wild] = _respawn_delay_for(wild)
			CAUGHT:
				_resolve_catch(_manager.call("caught_instance") as RefCounted)
				wild.visible = false
				if once_id != "":
					_mark_once_cleared(once_id)
				else:
					# The spawn POINT refills with a new wild individual on the
					# usual delay — the caught instance now lives in the party (or
					# on the ceremony's seam), and the meadow does not empty out
					# one catch at a time.
					_respawn_timers[wild] = _respawn_delay_for(wild)

	# R2.5: the M2 auto-heal above this comment used to run here. It was a
	# placeholder for a healing system, camp rest and potions that did not
	# exist yet. All three exist now (R2.4's crafting, the campfire's rest,
	# tab_backpack.gd's use verb), so HP persists after a fight and is
	# restored only by those — not by walking away from a win.


## R4.10: an ordinary catch reaches the real party, or forces the release
## ceremony. This was the plumbing gap the whole ceremony sat behind — until
## it, `_caught` here was a dead-end list nothing read, so no creature caught
## outside the opening ever reached `Game.party` at all.
##
## The same null-checked `/root/Game` lookup `_party()` uses, for the same
## reason its own comment gives. When the belt is full the creature is parked
## on `Game.pending_catch` — exactly one, never saved, not storage — and the
## Game autoload's `_watch_pending_catch()` opens the Team screen's release
## ceremony on it. Play never resumes with six creatures owned.
func _resolve_catch(kept: RefCounted) -> void:
	if kept == null:
		push_error("combat ended as a catch with nothing caught")
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the caught creature exists but nobody owns it")
		return
	var party: RefCounted = game.get("party")
	if party == null:
		push_error("the Game autoload has no party")
		return

	# Prompt 67's history: stamp the day it joined you, once, at the moment it
	# does. Set here rather than at spawn because a wild creature the player
	# never caught has no day it joined them, and this is the one path every
	# catch takes -- the tutorial's included.
	if int(kept.get("caught_on_day")) <= 0:
		kept.set("caught_on_day", int(game.get("day")))

	if not bool(party.call("is_full")):
		if not bool(party.call("add", kept)):
			push_error("the caught %s never reached the party" % str(kept.get("species_id")))
		return

	if game.get("pending_catch") != null:
		# Holding two overflow catches would be a second creature past the cap
		# — storage, in exactly the form CLAUDE.md forbids. The first catch
		# keeps its claim on the ceremony; this one goes back to the wild. In
		# practice unreachable: the ceremony pauses the tree within a frame of
		# the first one, but a silent overwrite here would lose a creature the
		# player fought for, so the refusal is loud.
		push_error("a second catch resolved while one was already waiting on the ceremony; the %s went free" % str(kept.get("species_id")))
		return
	game.set("pending_catch", kept)


## --- R8.1: trainer battles --------------------------------------------------

## Is a trainer battle running right now, including the beat between one of
## their creatures falling and the next being sent out?
##
## Read by this node's own gates above, and by `sequence_director.gd`, which
## keeps the interaction arbiter and the trainer's locomotion locked for as
## long as this is true — otherwise the player could walk away mid-battle
## during that beat, which is when the fight itself is not running.
func trainer_battle_active() -> bool:
	return not _trainer_spec.is_empty()


## Which trainer, for a HUD or a test. "" when no battle is running.
func trainer_battle_id() -> String:
	return str(_trainer_spec.get("id", ""))


## How many of the trainer's creatures are still to be sent out, the one on
## the field not included.
func trainer_creatures_left() -> int:
	return _trainer_queue.size()


## May this trainer be fought right now? A separate question from
## `begin_trainer_battle()` succeeding, because the NPC has to ask it before
## it opens its mouth — a beaten trainer greets you instead of challenging
## you, and that decision is made from this.
func can_challenge(spec: Dictionary) -> bool:
	if spec.is_empty() or TRAINERS.team_of(spec).is_empty():
		return false
	if _manager == null or bool(_manager.call("is_fighting")) or trainer_battle_active():
		return false
	if _ally == null or _ally.fainted or _ally_body == null or not is_instance_valid(_ally_body):
		return false
	# CL-W4 / owner amendment A-4. The FIFTH reason, and the only one that is
	# not about the player being unable to fight at all: this particular person
	# will not take this particular challenge yet. Refused here rather than
	# inside `begin_trainer_battle()` so `trainer_npc.gd` can say so in
	# character before a fight is ever offered -- "gate just make the fight not
	# start unless you're a certain level."
	if too_low_to_challenge(spec):
		return false
	return not TRAINERS.already_beaten(spec, _progression())


## CL-W4. Is `can_challenge()` refusing because of THIS trainer's level
## condition, rather than any of the other four reasons?
##
## A sibling query in exactly the shape `no_usable_ally()` already established,
## and for the same reason its own header gives: `can_challenge()`'s bare-bool
## contract is read from 8+ call sites and must not grow a reason code, but
## `trainer_npc.gd` has to tell the refusals apart or a too-low player hears
## the already-defeated line instead of the taunt (the dark-features T1 note).
##
## `min_level` is a property of the trainer and the party, not of the fight, so
## this is true whether or not anything is deployed -- a player with a level-20
## bench and nothing out is not too low, they simply have nothing out, and
## `no_usable_ally()` is the query that says so.
func too_low_to_challenge(spec: Dictionary) -> bool:
	return TRAINERS.below_challenge_level(spec, _party())


## Is the ONE reason `can_challenge()` just refused "nothing to fight with",
## rather than "already beaten" or the battle-manager-busy/malformed-spec
## cases? A sibling query, not a change to `can_challenge()`'s own bool
## contract (8+ call sites across scripts/ and tests/ read it as a bare
## bool) -- added so `trainer_npc.gd` can tell a fainted-or-undeployed ally
## apart from a real "defeated" greeting instead of collapsing every refusal
## reason into one line (dark-features T1).
func no_usable_ally() -> bool:
	return _ally == null or _ally.fainted or _ally_body == null or not is_instance_valid(_ally_body)


## G3-OPENING-FIX-0904 (2.10). Which of `no_usable_ally()`'s two real causes
## applies, so the refusal line can name it instead of always guessing "hurt".
##
## `_ally.fainted` and `_ally_body == null` used to collapse into one line --
## "get it back on its feet... a bed will do it" -- which is only true for the
## first cause. The second is a healthy creature that simply is not out (a
## fresh save load never auto-deploys anything, or the active creature was
## put away): telling that player to go rest a creature that is not hurt
## points at the wrong fix entirely. `_ally == null` reads as "undeployed"
## too -- it is the same "nothing is out" state `dismiss_active_creature()`
## and a fresh load both leave, just without even a stale reference around to
## ask whether it is fainted.
##
## Returns "" when nothing is wrong, so a caller can treat an unexpected ""
## as a bug rather than silently falling through to one of the two lines.
func usable_ally_blocker() -> String:
	if _ally != null and _ally.fainted:
		return "fainted"
	if _ally == null or _ally_body == null or not is_instance_valid(_ally_body):
		return "undeployed"
	return ""


## Take up a trainer's challenge. `trainer` is the body that issued it, used
## to decide where their creatures come from; null is legal.
##
## Returns false rather than half-starting: a battle that began with an empty
## team, or with the player having nothing to fight with, would suspend
## exploration and never give it back.
func begin_trainer_battle(spec: Dictionary, trainer: Node3D = null) -> bool:
	if not can_challenge(spec):
		return false

	var team: Array = TRAINERS.team_of(spec)
	_trainer_queue.clear()
	for entry: Variant in team:
		var creature := TRAINERS.creature_for(entry as Dictionary)
		if creature == null:
			push_error("trainer '%s' fields a creature species that is not in species.json" % str(spec.get("id", "")))
			continue
		_trainer_queue.append(creature)
	if _trainer_queue.is_empty():
		push_error("trainer '%s' has no creatures that could be built; the battle was refused" % str(spec.get("id", "")))
		return false

	_trainer_spec = spec
	_trainer_node = trainer
	_trainer_send_delay = 0.0
	_trainer_cleanup_delay = 0.0
	_trainer_battle_participants = {}
	# Taken BEFORE the first round places anyone, so it is where the player was
	# actually standing when they accepted — not where the first fight's
	# `_stand_the_trainer_aside()` will shortly put them. See
	# `_trainer_battle_anchor`.
	_trainer_battle_anchor = _player.global_position if _player != null else Vector3.ZERO
	_has_trainer_battle_anchor = _player != null
	if not _send_out_next_creature():
		_finish_trainer_battle(false)
		return false
	return true


## Put the trainer's next creature on the field and open a fight against it.
##
## The body is `wild_creature.gd` — the same script the meadow's own creatures
## use — because it is already everything the combat manager talks to: an
## instance, a telegraph, a strike, a faint. What it is NOT given is a wander
## radius it will use or a respawn: it is engaged from the frame it appears
## and freed when the battle ends. It is also never aggressive, whatever its
## species says: this creature does not decide when the fight starts, its
## trainer already did.
func _send_out_next_creature() -> bool:
	if _trainer_queue.is_empty():
		return false

	# Put the trainer back where the battle started, BEFORE anything is placed
	# off their position. `_send_out_spot()` below reads it, and so does
	# `combat_manager._place_fighters()` a few lines later through
	# `_start_fight()` — so this has to happen first or the round is already
	# staged from the last one's leftovers. See `_trainer_battle_anchor` for
	# what that drift did to the Warden.
	#
	# Restored verbatim, Y included, rather than re-asking the world for a
	# ground height: this is not a horizontal move to somewhere new (which is
	# what D09 is about) but a return to a spot the player was standing on
	# moments ago in this same scene. Asking again would invite a different
	# answer inside a building, which is the failure this is fixing.
	if _has_trainer_battle_anchor and _player != null:
		_player.global_position = _trainer_battle_anchor
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO

	var creature: RefCounted = _trainer_queue.pop_front()
	_scale_opponent_for_the_session(creature)

	var body: Node3D = CREATURE_SCENE.instantiate()
	# Numbered off a counter that only ever goes up, never off `_trainer_fallen`
	# — that list is emptied when the previous body is cleared, so an index
	# derived from it repeats, and `add_child()` silently renames a colliding
	# name to `@CharacterBody3D@2179`. A name nobody chose is a name no log
	# line, remote-tree screenshot or smoke test can match against, which is
	# exactly how this was found.
	_trainer_sent += 1
	body.name = "TrainerCreature_%s_%d" % [str(_trainer_spec.get("id", "trainer")), _trainer_sent]
	body.set_script(WILD_SCRIPT)
	get_parent().add_child(body)
	body.call("populate", str(creature.get("species_id")), _player)
	body.set("instance", creature)
	# G-2, before the fight can open. A trainer creature with no `combat` block
	# in trainers.json carries an empty dictionary and fights exactly as it did.
	body.set("combat_override", creature.get("combat_override"))
	# W23-DIFFICULTY (D77): a trainer's body fights off `combat.json`'s
	# `enemy_trainer` baseline under its own `combat` block; a wild never does.
	body.set("trainer_owned", true)
	body.call("set_shiny", bool(creature.get("shiny")))
	body.set("aggressive", false)
	body.call("configure", MATH.config().get("wild", {}))

	var spot := _send_out_spot()
	if not bool(body.call("place_on_ground", spot)):
		# No ground reading (a bare test scene, a gap in the collision bake) is
		# a placement to take as given rather than a battle to refuse — the
		# fight itself re-places both fighters a frame later anyway.
		body.global_position = spot
	body.set("home", body.global_position)
	body.call("face_towards", _player.global_position)

	_trainer_body = body
	_start_fight(body, true)
	if not bool(_manager.call("is_fighting")):
		body.queue_free()
		_trainer_body = null
		return false
	return true


## §10 / D-MP12. What a trainer's creature costs when more than one person is
## fighting it.
##
## Composition first, health second, and NEVER HP x players: this function does
## not read `hp` or `max_hp` and does not write them. A boss with four times the
## health is four times as LONG, not four times as interesting, and that is the
## one scaling knob §10 forbids outright.
##
## What it does write is the modest end of §10:
##
##   * `attack` and `defence` -- `creature_instance.gd`'s own multipliers, which
##     `effective_attack`/`effective_defence` fold in, so one number reaches
##     both sides of the damage roll and nothing else has to know;
##   * `attack_cooldown` on the per-creature `combat_override` -- the other half
##     of composition for an opponent that is ONE body. It swings more often
##     because there is more than one thing to swing at, and
##     `encounter_host.gd::pick_struck()` spreads those swings across the
##     participants instead of letting whoever stands closest absorb all of
##     them.
##
## It is NOT a level bump. Spec §11 / D30: a level is a real level and the world
## does not move to meet you. D-MP12 scales by how many people turned up, which
## is a different axis from scaling to how strong they are, and that distinction
## only survives if nothing here touches a level.
##
## Solo returns on the first line, so a solo trainer battle is byte-for-byte the
## fight it was.
func _scale_opponent_for_the_session(creature: RefCounted) -> void:
	if creature == null or not _is_multi_peer() or not _is_host() \
			or _encounter_host == null:
		return
	var encounter_id := str(_encounter.get("encounter_id", ""))
	if encounter_id.is_empty():
		return
	var row: Dictionary = _encounter_host.call("scaling", encounter_id)
	var stat := float(row.get("stat_multiplier", 1.0))
	var cooldown := float(row.get("attack_cooldown_multiplier", 1.0))
	if is_equal_approx(stat, 1.0) and is_equal_approx(cooldown, 1.0):
		return
	creature.set("attack", float(creature.get("attack")) * stat)
	creature.set("defence", float(creature.get("defence")) * stat)
	if is_equal_approx(cooldown, 1.0):
		return
	# G-2's per-creature override is where a trainer's creature already says how
	# it fights, so the swing rate is written there rather than into a second
	# channel `wild_creature.gd::configure()` would have to learn about.
	var override: Dictionary = (creature.get("combat_override") as Dictionary).duplicate(true)
	var base := float(override.get("attack_cooldown",
		float((MATH.config().get("enemy_trainer", {}) as Dictionary).get("attack_cooldown",
			float((MATH.config().get("wild", {}) as Dictionary).get("attack_cooldown", 1.4))))))
	override["attack_cooldown"] = maxf(0.1, base * cooldown)
	creature.set("combat_override", override)


## Beside the trainer, a stride toward the player — so their creature comes
## out from where they are standing rather than materialising in the middle of
## the field. With no trainer body (a test, a tool) it comes out in front of
## the player instead, which is where a wild creature would have been.
func _send_out_spot() -> Vector3:
	var reach := float(TRAINERS.flow().get("deploy_offset", 3.0))
	if _trainer_node != null and is_instance_valid(_trainer_node):
		var toward := _player.global_position - _trainer_node.global_position
		toward.y = 0.0
		if toward.length() < 0.01:
			toward = Vector3.FORWARD
		return _trainer_node.global_position + toward.normalized() * reach
	var forward := -_player.global_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	return _player.global_position + forward.normalized() * (reach * 2.0)


## One round is over. Won means their creature fell; anything else (your
## creature fainted, you ran) ends the whole battle then and there, with no
## flag and no reward — exactly what a wild loss costs, which is the fight and
## nothing else. Nobody dies over it: the human never fights (CLAUDE.md), so
## losing a trainer battle is the same "your creature is out of the fight"
## state a wild loss leaves behind, and `player_death.gd` — which is about
## falling off things — is not involved.
func _on_trainer_round_ended(outcome: String) -> void:
	var body := _trainer_body
	_trainer_body = null
	_engaged_with = null
	if body != null and is_instance_valid(body):
		_trainer_fallen.append(body)
		if outcome == "won":
			# §15's own rule, applied to somebody else's creature: the body
			# stays down for a moment rather than blinking out.
			body.call("notify_fainted")

	if outcome != "won":
		_finish_trainer_battle(false)
		return
	if _trainer_queue.is_empty():
		_finish_trainer_battle(true)
		return
	# Their next one steps up. Exploration deliberately stays suspended
	# through this beat — `trainer_battle_active()` is still true.
	_trainer_send_delay = float(TRAINERS.flow().get("send_out_seconds", 1.6))


## The two clocks a trainer battle runs between fights: the beat before the
## next creature is sent out, and the one after the battle that clears the
## bodies. Only ever one at a time, and both are cheap no-ops otherwise —
## same shape as `_tick_respawn` above, and kept separate from it because a
## trainer's creature never respawns.
func _tick_trainer_battle(delta: float) -> void:
	if _trainer_send_delay > 0.0:
		_trainer_send_delay -= delta
		if _trainer_send_delay > 0.0:
			return
		_clear_fallen_bodies()
		if not _send_out_next_creature():
			_finish_trainer_battle(false)
		return

	if _trainer_cleanup_delay > 0.0:
		_trainer_cleanup_delay -= delta
		if _trainer_cleanup_delay <= 0.0:
			_clear_fallen_bodies()


## End the battle, whoever won it. Exploration comes back here and only here,
## so no exit from a trainer battle can leave the player unable to walk.
func _finish_trainer_battle(won: bool) -> void:
	var spec := _trainer_spec
	_trainer_spec = {}
	_trainer_node = null
	_trainer_queue.clear()
	_trainer_send_delay = 0.0
	_trainer_cleanup_delay = float(TRAINERS.flow().get("linger_seconds", 2.4))
	# The battle is over, so the anchor stops applying. Deliberately NOT used to
	# teleport the player home on the way out: the trainer stays where the last
	# round left them, exactly as they did before this change, so winning a
	# battle still ends with the player standing beside the fight they just won.
	_has_trainer_battle_anchor = false
	_set_exploration_active(true)
	if won:
		_record_trainer_defeat(spec)
		call_deferred("_present_trainer_victory", spec)
	# NOW the battle's one encounter record is over, and not one creature
	# earlier. Cleared after the payout because §7 pays the people who fought
	# it, and dropped from the joinable list because a fight nobody can join is
	# a fight nobody should be offered.
	_close_trainer_encounter()


## Optional data-driven post-victory story beat.  Most trainers need only the
## ordinary reward toast; realm bosses can name what changed immediately after
## the fight instead of requiring the player to interact with the defeated NPC
## a second time and possibly miss a chapter-critical grant.
func _present_trainer_victory(spec: Dictionary) -> void:
	var conversation := str(spec.get("victory_conversation", ""))
	if conversation == "":
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null or not panel.has_method("start"):
		push_warning("trainer '%s' has victory dialogue but no dialogue panel is available" % str(spec.get("id", "")))
		return
	if bool(panel.call("is_open")):
		push_warning("trainer '%s' victory dialogue found the panel busy" % str(spec.get("id", "")))
		return
	panel.call("start", conversation)


## SB9's flag, and SC15's payout hook.
##
## The flag is written FIRST-time-only semantics by nature — it is a set, not
## a counter — and the reward is paid only if it was not already set, so a
## trainer marked `rechallenge: true` later cannot be farmed for items. XP
## needs nothing here: it was awarded per creature felled, by the ordinary
## victory award, while the battle was still running.
func _record_trainer_defeat(spec: Dictionary) -> void:
	if _record_trainer_defeat_for_the_session(spec):
		return
	var flag := str(spec.get("defeat_flag", ""))
	var progression := _progression()
	if progression == null:
		push_error("no progression store; the defeat of trainer '%s' was recorded nowhere" % str(spec.get("id", "")))
		return
	var already: bool = flag != "" and bool(progression.call("has", flag))
	if flag != "":
		progression.call("set_flag", flag)
	else:
		push_warning("trainer '%s' names no defeat_flag; beating them changes nothing" % str(spec.get("id", "")))
	if already:
		return
	for extra: String in TRAINERS.reward_flags(spec):
		progression.call("set_flag", extra)
	_pay_trainer_reward(spec)


## The authored payout (spec §17 P1 step 9; D39: payouts include coins). SC15
## is the item that tunes what a trainer is worth; this is the plumbing it
## tunes. A full satchel is warned about rather than swallowed, same as
## `sequence_director.gd::_give_items()` -- and, unlike that quieter grant,
## what actually landed is read back to the player in one line through the
## same one-shot toast a refused gather or a full satchel already surfaces
## (`Game.push_world_message()`, polled by `playground_hud.gd`), because a
## trainer's reward is a moment worth a line and not just a satchel that
## quietly got heavier.
func _pay_trainer_reward(spec: Dictionary) -> void:
	var coins := TRAINERS.reward_coins(spec)
	var items: Array = TRAINERS.reward_items(spec)
	var xp_bonus := TRAINERS.reward_xp_bonus(spec)
	if coins <= 0 and items.is_empty() and xp_bonus <= 0:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a trainer's reward was given to nobody")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return
	var catalogue: RefCounted = game.get("items")
	var won: Array[String] = []

	if coins > 0:
		var leftover := int(inventory.call("add", "coin", coins))
		if leftover > 0:
			push_warning("the satchel was full; %d of the %d coin from a trainer did not fit" % [leftover, coins])
		var landed := coins - leftover
		if landed > 0:
			won.append("%d %s" % [landed, str(catalogue.call("item_name", "coin")) if catalogue != null else "coin"])

	for entry: Variant in items:
		var item := entry as Dictionary
		var id := str(item.get("id", ""))
		var count := int(item.get("count", 1))
		if id == "" or count <= 0:
			continue
		if catalogue != null and not bool(catalogue.call("has", id)):
			push_error("trainer '%s' rewards '%s', which data/items/items.json does not define" % [
				str(spec.get("id", "")), id
			])
			continue
		var leftover := int(inventory.call("add", id, count))
		if leftover > 0:
			push_warning("the satchel was full; %d of the %d %s from a trainer did not fit" % [leftover, count, id])
		var landed := count - leftover
		if landed > 0:
			won.append("%d %s" % [landed, str(catalogue.call("item_name", id)) if catalogue != null else id])

	if xp_bonus > 0:
		var party := _party()
		if party != null:
			var cfg: Dictionary = PROGRESSION.config()
			for i in int(party.call("size")):
				var member: RefCounted = party.call("at", i)
				if member != null and not bool(member.get("fainted")):
					member.call("gain_xp", xp_bonus, cfg)

	if not won.is_empty():
		game.call("push_world_message", "%s's reward: %s" % [str(spec.get("name", "Trainer")), ", ".join(won)])


# --- §7: the world fact once, the personal reward per participant ---------------
#
# The whole of lane 4.D in one sentence: **a trainer beaten by two people is
# beaten once for the world, and pays both of them.**
#
# The two halves are deliberately different mechanisms, because they are
# different facts:
#
#   * the WORLD half is a `set_world_flag` intent per fact, committed once by
#     the host and mirrored to everybody. A second peer arriving later finds the
#     trainer already beaten because that is what the world says, and
#     `world_ledger.gd` answers a re-commit with `code: "noop"` rather than an
#     error a player is shown;
#   * the PERSONAL half is a `reward_grant` per component, addressed to every
#     participant, guarded per participant per source by
#     `world_ledger.gd::reward_flag()`. Nothing is divided by how many people
#     turned up (§7) -- a fight that pays half as much for having a friend along
#     teaches people to play alone.
#
# XP is the one component that cannot be an op: a peer's party is its own
# (D100), the host has never seen it, and the host must not pretend to add a
# level to somebody else's creature. So the ledger holds the RECEIPT and the
# host TELLS each newly-paid participant, who applies the bonus to its own
# party. The guard is durable; the payment is a message.


## True when this defeat has been handled as a session's, so
## `_record_trainer_defeat()`'s solo body must not also run.
##
## Solo returns false on the first line and not one line below it runs, so
## nothing a solo player has ever seen changes here.
func _record_trainer_defeat_for_the_session(spec: Dictionary) -> bool:
	if not _is_multi_peer():
		return false
	var realm := _encounter_realm()
	# D103/D99: a trainer's defeat is a WORLD fact and the only way a world fact
	# may change is an intent -- `alpha_pins.gd::clear_alpha()` is the precedent.
	# Submitted whether this peer is the host or a client, because either can be
	# the one who won: a client's trainer battle is still its own local fight
	# (4.C's F1) and the flag it produces is still the world's.
	for fact: Variant in ENCOUNTER_REWARDS.world_facts(spec, realm):
		_submit_reward_intent(fact as Dictionary)
	if not _is_host() or _encounter_host == null:
		# On a client the personal half is this peer paying itself for a fight
		# it ran itself, which is exactly what the solo path already does
		# correctly. Fall through to it rather than growing a second copy.
		return false
	var participants: Array = ENCOUNTER_REWARDS.unique_peers(
		_trainer_battle_participants.keys())
	if participants.is_empty():
		return false
	_pay_every_participant(spec, realm, participants)
	return true


## §7's personal half. One `reward_grant` per component, each addressed to every
## participant; the ledger hands back `paid` -- the participants who had not
## already been paid for that source -- and those are the people who are told.
##
## Deliberately NOT gated on whether the defeat flag was already set. The solo
## path uses that flag as its anti-farm guard because solo there is only ever
## one player; here the guard is the per-participant receipt, and reading the
## world flag instead would refuse to pay a second player for a trainer their
## friend had beaten earlier -- who is exactly the person §7 exists to pay.
func _pay_every_participant(spec: Dictionary, realm: String, participants: Array) -> void:
	var paid_any: Dictionary = {}
	for raw: Variant in ENCOUNTER_REWARDS.grants(spec, realm, participants):
		var verdict: Dictionary = _submit_reward_intent(raw as Dictionary)
		if not bool(verdict.get("ok", false)):
			continue
		for peer: Variant in (verdict.get("paid", []) as Array):
			paid_any[int(peer)] = true
	if paid_any.is_empty():
		return
	var payload := {
		"trainer": str(spec.get("name", "Trainer")),
		"xp": ENCOUNTER_REWARDS.xp_bonus(spec),
		"line": _trainer_reward_line(spec),
	}
	for peer: Variant in paid_any.keys():
		_tell_participant_they_were_paid(int(peer), payload)


## The one line a newly-paid participant is shown, built from the AUTHORED
## payout rather than from what landed.
##
## That is a stated difference from the solo path, which reads back the leftover
## `inventory.add()` returned and can therefore say "the satchel was full". The
## ledger's `item_grant` op does not carry a leftover back to the host, and
## inventing one here would mean the host describing the contents of somebody
## else's satchel -- which it has never seen (D100). Naming what the trainer
## owed is the honest thing the host actually knows.
func _trainer_reward_line(spec: Dictionary) -> String:
	var game := get_node_or_null(^"/root/Game")
	var catalogue: RefCounted = game.get("items") if game != null else null
	var won: Array[String] = []
	var coins := TRAINERS.reward_coins(spec)
	if coins > 0:
		won.append("%d %s" % [coins,
			str(catalogue.call("item_name", "coin")) if catalogue != null else "coin"])
	for entry: Variant in TRAINERS.reward_items(spec):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id := str((entry as Dictionary).get("id", ""))
		var count := int((entry as Dictionary).get("count", 1))
		if id.is_empty() or count <= 0:
			continue
		won.append("%d %s" % [count,
			str(catalogue.call("item_name", id)) if catalogue != null else id])
	if won.is_empty():
		return ""
	return "%s's reward: %s" % [str(spec.get("name", "Trainer")), ", ".join(won)]


## Host -> one participant. The local host applies it in-process for the reason
## `ledger_rpc.gd::_commit_here()` gives about its own local player: one code
## path, and no "the host is special" branch to rot.
func _tell_participant_they_were_paid(peer_id: int, payload: Dictionary) -> void:
	if peer_id == _local_peer_id():
		_apply_trainer_reward(payload)
		return
	if _can_encounter_rpc():
		rpc_id(peer_id, "_rpc_trainer_reward", payload)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_trainer_reward(payload: Dictionary) -> void:
	_apply_trainer_reward(payload)


## The half of a reward only the peer that owns the party can apply. The items
## and the flags arrived as ledger ops; this is the XP and the line about it.
func _apply_trainer_reward(payload: Dictionary) -> void:
	var xp := int(payload.get("xp", 0))
	if xp > 0:
		var party := _party()
		if party != null:
			var cfg: Dictionary = PROGRESSION.config()
			for i in int(party.call("size")):
				var member: RefCounted = party.call("at", i)
				if member != null and not bool(member.get("fainted")):
					member.call("gain_xp", xp, cfg)
	var line := str(payload.get("line", ""))
	if line.is_empty():
		return
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		game.call("push_world_message", line)


## `Game.ledger` -- lane 3.A's transport, mounted at an identical path in every
## process. A verdict is ALWAYS returned in `world_ledger.gd`'s shape so no
## caller branches on the type of the answer.
func _submit_reward_intent(intent: Dictionary) -> Dictionary:
	if intent.is_empty():
		return {"ok": false, "pending": false, "code": "malformed", "paid": []}
	var game := get_node_or_null(^"/root/Game")
	var ledger: Node = game.get("ledger") as Node if game != null else null
	if ledger == null or not ledger.has_method("submit"):
		return {"ok": false, "pending": false, "code": "offline", "paid": []}
	return ledger.call("submit", intent)


## Remember everybody who is in this trainer battle's record right now. Called
## while a round is LIVE -- the round teardown empties the record's own list, so
## sampling after the win would find nobody. See `_trainer_battle_participants`.
func _note_trainer_participants(encounter_id: String) -> void:
	if _encounter_host == null or encounter_id.is_empty():
		return
	for peer_id: int in (_encounter_host.call("participants_of", encounter_id) as Array):
		_trainer_battle_participants[peer_id] = true


## The same fight, one creature later: bring `encounter_id` back to `active` and
## put the people who are still fighting this trainer back in it. False when
## there is no such record to resume, which sends the caller down the mint path.
##
## Both halves exist because of one line in somebody else's file:
## `combat_manager.gd::_finish()` submits `disengage` at the end of EVERY round,
## which is correct for a wild fight and is also what a trainer's creature
## fainting looks like from inside the manager. So by the time the next creature
## steps up, §9 has emptied the record's participant list and marked it `done`.
## That `done` describes a round boundary, not the end of the battle -- the
## battle is still running, `trainer_battle_active()` is still true, and the
## alternative is minting a fresh record per creature, which drops a joiner
## between rounds and pays them for none of a boss they fought two thirds of.
##
## Only peers the session still holds are re-seated: somebody who disconnected
## mid-battle is remembered for the payout, because they fought it, but is not
## put back into a fight they cannot be in. `join()` is idempotent by contract
## and does not re-stamp `joined_seq`, so a re-seat cannot make anybody look
## like a later or an earlier arrival than they were.
func _resume_trainer_encounter(encounter_id: String) -> bool:
	if _encounter_host == null or encounter_id.is_empty():
		return false
	if (_encounter_host.call("record", encounter_id) as Dictionary).is_empty():
		return false
	if str(_encounter_host.call("phase", encounter_id)) != "active":
		_encounter_host.call("set_phase", encounter_id, "active")
	var live := _session_peer_ids()
	_encounter_host.call("join", encounter_id, _local_peer_id(), "", _local_character_id())
	for peer: Variant in _trainer_battle_participants.keys():
		var peer_id := int(peer)
		if peer_id == _local_peer_id() or not live.has(peer_id):
			continue
		_encounter_host.call("join", encounter_id, peer_id, "", "")
	return true


## The battle is over: stop holding its record and stop advertising it.
func _close_trainer_encounter() -> void:
	var id := str(_encounter.get("encounter_id", ""))
	_encounter = {}
	_trainer_battle_participants = {}
	if id.is_empty():
		return
	_joinable_encounters.erase(id)
	if _is_host() and _encounter_host != null:
		_encounter_host.call("close", id)
		_encounter_host.call("forget", id)
		if _catch_arbiter != null:
			_catch_arbiter.call("forget", id)


func _clear_fallen_bodies() -> void:
	for body: Node3D in _trainer_fallen:
		if is_instance_valid(body):
			body.queue_free()
	_trainer_fallen.clear()


## `Game.progression`, SB9's flat flag store. Same null-tolerant `/root/Game`
## lookup `_party()` uses, for the reason its own comment gives.
func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


## Hand control back and forth between exploration and combat. One place, so a
## new way of entering a fight cannot forget half of it.
func _set_exploration_active(active: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", active)
	# The combat manager drives the same body while a fight is running. Two
	# things calling `request_move` on one creature in one frame is one of them
	# silently losing, and the one that loses is the one the player is piloting.
	if _ally_body != null and is_instance_valid(_ally_body) and _ally_body.has_method("set_following"):
		_ally_body.call("set_following", active)
		# CombatManager hides the shared deployed body while it tears down the
		# arena. A healthy creature must become the visible follower again when
		# exploration resumes; begin() makes it visible on the other handoff.
		if active and _ally != null and not bool(_ally.get("fainted")) \
				and not bool(_ally.get("resting")):
			_ally_body.visible = true
