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
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
## D30: wild creatures spawn inside a level band rather than at one fixed level.
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
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


func _spawn_creatures() -> void:
	var entries: Array = spawns_config().get("spawns", []) as Array
	if entries.is_empty():
		push_error("spawns.json has no spawn table; the meadow will be empty")

	for index in entries.size():
		var spawn: Dictionary = entries[index] as Dictionary
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
		# fixed in data too). The seed is derived from the entry's index so each
		# cluster gets its own scatter rather than every cluster sharing one.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("wild_spawn_%d" % index)

		for n in count:
			var wild: Node3D = CREATURE_SCENE.instantiate()
			# Indexed, because clusters exist now. Two nodes both named
			# "Wild_bramblebun" under one parent would be silently auto-renamed
			# by the engine, and a name nobody chose is a name no log line or
			# remote-tree screenshot can be matched against.
			wild.name = "Wild_%s_%d" % [species, n + 1]
			wild.set_script(WILD_SCRIPT)
			get_parent().add_child(wild)
			# sqrt on the radius fraction makes the points uniform over the
			# disc's AREA; without it they bunch at the centre.
			var angle := rng.randf_range(0.0, TAU)
			var distance := radius * sqrt(rng.randf())
			var spot := centre + Vector3(sin(angle), 0.0, cos(angle)) * distance
			if not await _stand_on_ground(wild, spot):
				push_error("no ground under the %s spawn point; it will be unreachable" % species)
			wild.call("populate", species, _player)
			_roll_wild_level(wild, species, rng)
			wild.call("configure", MATH.config().get("wild", {}))
			wild.set("home", wild.global_position)
			# An aggressive creature asks; this node decides. Keeping the decision
			# here means every route into a fight goes through one place, so a
			# new one cannot forget to suspend exploration or hand over the
			# camera.
			wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
			_wild_creatures.append(wild)

			var gate := _gate_for_spawn(spawn)
			if not gate.is_empty():
				_wild_gates[wild] = gate
				wild.visible = _gate_active(gate)

	if default_starter != "":
		# Awaited: `adopt_starter` waits for ground under the spawn point, so
		# calling it bare would hand back a coroutine and leave the creature unplaced.
		await adopt_starter(default_starter)


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
## Also rolls individuality and a trait pair (R4.2) through this same `rng` —
## the wild encounter is where GAME_DESIGN.md 11's "same-species creatures
## have slightly different underlying stat quality" is actually met by the
## player, and MEADOWS_PROGRESSION_SPEC.md 11 names "seek better traits/
## appraisal" as one of the good reasons to keep catching. Consuming more of
## the same seeded, never-`randomize()`d generator changes nothing about the
## determinism promise above — a creature met at a given spot still rolls
## the same way across boots, just for three more numbers than before.
func _roll_wild_level(wild: Node3D, species: String, rng: RandomNumberGenerator) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var definition: Dictionary = SPECIES.definition(species)
	var iv_rolls: Array = [rng.randf(), rng.randf(), rng.randf()]
	var trait_rolls: Array = [rng.randf(), rng.randf()]
	var leveled: RefCounted = CREATURE_INSTANCE.from_species(
		species, definition, rng.randf(), cfg, iv_rolls, trait_rolls
	)
	wild.set("instance", leveled)


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
	_ally_body.call("setup", creature.species_id)
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
	var file := FileAccess.open(SPAWNS_CONFIG, FileAccess.READ)
	if file == null:
		push_error("spawns.json missing at %s" % SPAWNS_CONFIG)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_spawns_cfg = parsed
	return _spawns_cfg


func _respawn_delay() -> float:
	return float(spawns_config().get("respawn_seconds", DEFAULT_RESPAWN_DELAY))


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
	var party := _party()
	if party == null:
		return false
	var creature: RefCounted = party.call("active")
	if creature == null or bool(creature.get("fainted")):
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
	var active_creature: RefCounted = party.call("active")
	if active_creature == null or active_creature == _ally:
		return  # The change wasn't to the creature that is actually out.
	dismiss_active_creature()
	summon_active_creature()


## `CO1`'s bound action, read whenever nothing else owns it. Guarded the same
## way `_read_engage_input()` is: no reading past a running fight, since the
## combat manager drives `_ally_body` for the length of one.
func _read_creature_control_input() -> void:
	if _manager != null and bool(_manager.call("is_fighting")):
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
func _creature_control_offer() -> Dictionary:
	if _ally_body != null and is_instance_valid(_ally_body):
		if _ally == null:
			return {}
		return PROMPTS.offer(
			"%s%sPut %s away" % [INPUT_GLYPH.icon("creature_recall"), PROMPTS.GAP, _ally.label()],
			0.0, -1, false
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
	# A statement rather than an offer, and it outranks everything: with no creature
	# on its feet there is nothing to fight with, and a "[X] Engage" line the
	# button refuses is worse than being told why.
	if _ally != null and _ally.fainted:
		return PROMPTS.offer("%s is out of the fight." % _ally.display_name, 0.0, 100, false)
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
	_sync_spawn_gates()
	_sync_active_creature()
	_update_prompt()


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


## The nearest wild creature the player could choose to fight right now.
func _engageable() -> Node3D:
	if _ally == null or _manager == null or _ally.fainted:
		return null
	if bool(_manager.call("is_fighting")):
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
## something ambushes you.
func _start_fight(wild: Node3D) -> void:
	var party: Array[RefCounted] = [_ally]
	var party_obj := _party()
	var best: RefCounted = party_obj.call("best") if party_obj != null else null
	if not bool(_manager.call("begin", _player, wild, _ally_body, party, _camera_rig, best)):
		return
	_engaged_with = wild
	_set_exploration_active(false)


func _on_combat_exited(outcome: String) -> void:
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
				_respawn_timers[wild] = _respawn_delay()
			CAUGHT:
				_resolve_catch(_manager.call("caught_instance") as RefCounted)
				wild.visible = false
				# The spawn POINT refills with a new wild individual on the
				# usual delay — the caught instance now lives in the party (or
				# on the ceremony's seam), and the meadow does not empty out
				# one catch at a time.
				_respawn_timers[wild] = _respawn_delay()

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
