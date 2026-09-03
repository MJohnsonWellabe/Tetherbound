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
const OPENING_CONFIG := "res://data/config/opening.json"

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
	await _spawn_creatures()


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

		for n in count:
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
func spawn_wild(species: String, spot: Vector3, opts: Dictionary = {}) -> Node3D:
	if not SPECIES.has(species):
		push_error("spawn_wild('%s') names a species that is not in species.json" % species)
		return null
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(WILD_SCRIPT)
	wild.name = str(opts.get("name", "Wild_%s_%d" % [species, _wild_creatures.size() + 1]))
	var parent: Node = opts.get("parent", null) as Node
	if parent == null or not is_instance_valid(parent):
		parent = get_parent()
	parent.add_child(wild)
	wild.call("populate", species, _player)
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
	_ally_body.name = "AllyCreature"
	_ally_body.set_script(FOLLOWER_SCRIPT)
	_ally_body.visible = false
	get_parent().add_child(_ally_body)
	_ally_body.call("setup", creature.species_id, bool(creature.get("shiny")))
	_ally_body.call("configure_following", _follower_config())
	_ally_body.set("leader", _player)

	# Behind the trainer's right shoulder, which is where it will settle anyway.
	var spot := _player.global_position - _player.global_basis.z * 2.4 + _player.global_basis.x * 1.2
	if not await _stand_on_ground(_ally_body, spot):
		push_error("no ground beside the trainer to put their creature on")
	_ally_body.visible = true
	_ally_body.call("face_towards", _player.global_position)
	_ally_body.call("set_following", true)
	return true


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


func _stream_clusters() -> void:
	var player_pos := _player.global_position
	var margin := _activation_radius_margin()
	for cluster: Dictionary in _clusters:
		var centre: Vector3 = cluster["centre"]
		var radius: float = cluster["radius"]
		var should_be_active := player_pos.distance_to(centre) <= radius + margin
		if should_be_active == bool(cluster["active"]):
			continue
		cluster["active"] = should_be_active
		for wild: Node3D in (cluster["members"] as Array[Node3D]):
			_set_wild_active(wild, should_be_active)


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
	var wild := _engaged_with
	_engaged_with = null

	if wild != null and is_instance_valid(wild):
		match outcome:
			"won":
				# It stays on the ground for a moment before it clears. §15: the
				# body is the feedback for having over-damaged something you
				# might have caught.
				wild.call("notify_fainted")
				_faint_timers[wild] = float(CATCH.config().get("faint", {}).get("linger_seconds", 4.0))
				_respawn_timers[wild] = _respawn_delay_for(wild)
			CAUGHT:
				_resolve_catch(_manager.call("caught_instance") as RefCounted)
				wild.visible = false
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
	return not TRAINERS.already_beaten(spec, _progression())


## Is the ONE reason `can_challenge()` just refused "nothing to fight with",
## rather than "already beaten" or the battle-manager-busy/malformed-spec
## cases? A sibling query, not a change to `can_challenge()`'s own bool
## contract (8+ call sites across scripts/ and tests/ read it as a bare
## bool) -- added so `trainer_npc.gd` can tell a fainted-or-undeployed ally
## apart from a real "defeated" greeting instead of collapsing every refusal
## reason into one line (dark-features T1).
func no_usable_ally() -> bool:
	return _ally == null or _ally.fainted or _ally_body == null or not is_instance_valid(_ally_body)


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


## SB9's flag, and SC15's payout hook.
##
## The flag is written FIRST-time-only semantics by nature — it is a set, not
## a counter — and the reward is paid only if it was not already set, so a
## trainer marked `rechallenge: true` later cannot be farmed for items. XP
## needs nothing here: it was awarded per creature felled, by the ordinary
## victory award, while the battle was still running.
func _record_trainer_defeat(spec: Dictionary) -> void:
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
