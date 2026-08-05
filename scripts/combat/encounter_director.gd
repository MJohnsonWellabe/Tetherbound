extends Node

## Everything around a fight that is not the fight: spawning the wild pal,
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
const SPECIES := preload("res://scripts/pals/pal_species.gd")
## For the XP curve and the reward table, both of which live in
## data/config/party.json. Loaded through pal_instance so there is one reader of
## that file rather than two that can disagree about its defaults.
const PAL := preload("res://scripts/pals/pal_instance.gd")
## For the "is anyone still standing" questions. The party node forwards a small
## surface and `members()` is on it, so these are the static half of party.gd.
const PARTY := preload("res://scripts/pals/party.gd")
## So the prompt can name the revival item in the words items.json gives it,
## rather than hard-coding a display name that a data edit would falsify.
const DEFS := preload("res://scripts/items/item_defs.gd")
## Mirrors CombatManager.OUTCOME_CAUGHT. Declared rather than typed twice so a
## renamed outcome cannot silently stop matching here.
const CAUGHT := "caught"
## Team Tether. `tether_roster` puts the Meadows legendary into the species table
## before any save is restored; `stronghold_route` is the road they stand on and
## is mounted from `_mount_the_stronghold_route()` below.
const TETHER_ROSTER := preload("res://scripts/trainers/tether_roster.gd")
const STRONGHOLD_ROUTE := preload("res://scripts/trainers/stronghold_route.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
## pal.tscn carries no script; one body shape serves both roles and the script
## is chosen here. The alternative is two near-identical scenes, which means
## M11's real creature model has to be wired into the game twice.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
const WILD_SCRIPT := preload("res://scripts/pals/wild_pal.gd")

signal prompt_changed(text: String)

## A catch that could not be kept, with the party's refusal token. M5's release
## ceremony is what listens to this: capture-while-full is the only way that
## scene is ever reached.
signal caught_refused(token: String, instance: RefCounted)

## A pal was paid for a fight. `deployed` separates the one that fought from the
## ones that watched, because they are paid differently and a HUD that showed
## them the same way would be describing a rule the game does not have.
##
## Emitted as an EVENT rather than left for something to notice a stat moving:
## an evidence session can log "Bramblit gained 44 XP" honestly, and the M4 gate
## passed once already on a progression system whose only observable symptom
## would have been a number that never changed.
signal xp_awarded(pal: RefCounted, amount: int, deployed: bool)

## A pal levelled. Separate from `xp_awarded` because one award can buy several
## levels and each one is its own moment; `gained` is how many this award bought.
signal pal_levelled(pal: RefCounted, level: int, gained: int)

## Every pal the player owns is down. Emitted once, on the edge, when a fight
## ends that way.
##
## This is the emotional low point M6 exists to create, and it is announced
## rather than left to be discovered: with the blanket post-fight heal gone it is
## genuinely reachable, and a player who has just lost their last standing pal
## must be told what to do instead of finding a game that refuses every button.
## `_update_prompt()` below is what says it in words; this is for anything that
## wants to do more than write a line — a sting, a vignette, a camera move.
signal party_all_down()

## A wild creature landed a blow on the TRAINER. `amount` is the damage that
## actually went in, so a listener can flash the screen without recomputing it.
##
## Only ever emitted while every owned pal is fainted — see `Hunt` below.
signal trainer_struck(by: Node3D, amount: float)

## Ids into data/pals/species.json, so swapping any of them is a data edit.
##
## Two wild creatures in M3: one peaceful to practise throwing at, and one that
## comes at you. They are separated in the playground so the ambush is something
## you walk into rather than something that happens while you are aiming at the
## other one.
const STARTER_SPECIES := "starter_ground"
## Where the rest of the roster lives. See the file itself for why it exists.
const SPAWNS_PATH := "res://data/pals/spawns.json"

## The two the milestones depend on: M2 needs something peaceful to practise on
## and M3 needs something aggressive to be ambushed by, both near enough to spawn
## that the tutorial does not open with a hike. Three smokes walk to these exact
## offsets. Everything ELSE in the meadow comes from spawns.json.
const WILD_SPAWNS := [
	{"species": "wild_rabbit", "offset": Vector3(14.0, 0.0, -10.0)},
	{"species": "wild_bristler", "offset": Vector3(-6.0, 0.0, 26.0)},
]

## What the meadow does to a trainer with nothing left to fight with.
##
## GAME_DESIGN.md §14 protects the trainer absolutely: "Once combat mode begins,
## attacks are pal-vs-pal", and outside a fight an aggressive pal can "threaten"
## them. §16 does not say what happens when every owned pal is fainted and the
## player is fine. THE OWNER HAS AMENDED §14 FOR EXACTLY THAT CASE: with no pal
## able to fight, the trainer is a target in the world. They keep walking, they
## are not teleported and nothing is taken from them — but they are hunted, they
## bleed, and the honest answer is to get home and recover the party.
##
## What has NOT changed, and will not:
##
##   * The trainer cannot fight back. There is no attack on the human anywhere in
##     this file, no weapon, no combat verb. CLAUDE.md's "human cannot fight" is
##     a hard rule; being hurtable is a different thing from being a fighter.
##   * This is not Combat Mode. No arena opens, no camera transfers, the human is
##     never a party member and never has a slot in a fight. A creature that
##     would have started a fight harasses them in the world instead.
##   * One standing pal and the whole thing is off. §14's protection returns in
##     full the instant a pal is revived by an item or recovered at a bed, and
##     `tick()` below is written so that is a single check rather than a state
##     machine that could get stuck.
##
## An object rather than four loose fields on the director, for `Switchboard`'s
## reason: everything it decides is decidable from a clock, a distance and a
## flag, none of which needs a scene. That is what lets tests/test_recovery.gd
## prove the rules headlessly — including the one that matters most, which is
## that healing a pal ends it.
class Hunt extends RefCounted:

	## Which species come for a defenceless trainer. Data, not taste: see the
	## `hunters` note in data/config/combat.json.
	const HUNTERS_ALL := "all"

	var enabled: bool = true
	## Seconds after the last pal drops before anything lands a blow. There MUST
	## be one: being swarmed the instant you lose, with no chance to run, is a
	## worse experience than being hunted while you retreat.
	var grace_seconds: float = 6.0
	var strike_interval: float = 2.2
	var strike_range: float = 3.8
	var damage: float = 12.0
	var only_aggressive: bool = true

	var _grace_left: float = 0.0
	## Per-creature, so two hunters cannot share one cooldown and take it in turns
	## to be the only one that ever connects.
	var _cooldowns: Dictionary = {}

	func configure(cfg: Dictionary) -> void:
		enabled = bool(cfg.get("enabled", true))
		grace_seconds = maxf(0.0, float(cfg.get("grace_seconds", 6.0)))
		strike_interval = maxf(0.05, float(cfg.get("strike_interval", 2.2)))
		strike_range = maxf(0.5, float(cfg.get("strike_range", 3.8)))
		damage = maxf(0.0, float(cfg.get("damage", 12.0)))
		only_aggressive = str(cfg.get("hunters", "aggressive")) != HUNTERS_ALL
		_grace_left = grace_seconds
		_cooldowns.clear()

	## Advance the clocks. `defenceless` is "every owned pal is fainted", asked
	## fresh by the caller every frame. Returns true when the trainer is fair game
	## RIGHT NOW — defenceless AND out of grace.
	##
	## The recovery is unconditional and comes first: one available pal resets the
	## grace, forgets every cooldown and returns false, so there is no state left
	## for a healed party to be stuck in.
	func tick(delta: float, defenceless: bool) -> bool:
		if not defenceless or not enabled:
			_grace_left = grace_seconds
			_cooldowns.clear()
			return false
		for key: Variant in _cooldowns.keys():
			_cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)
		_grace_left = maxf(0.0, _grace_left - delta)
		return _grace_left <= 0.0

	## Seconds of head start left. What a HUD would count down.
	func grace_left() -> float:
		return _grace_left

	## Would this creature land a blow this frame? `tick()` has already decided
	## whether anything may.
	func may_strike(who: Object, aggressive: bool, distance: float) -> bool:
		if only_aggressive and not aggressive:
			return false
		if distance > strike_range:
			return false
		return float(_cooldowns.get(who, 0.0)) <= 0.0

	func struck(who: Object) -> void:
		_cooldowns[who] = strike_interval


## Seconds before a defeated wild pal is back on its feet. M2 only: the milestone
## exists to find out whether the owner wants another fight, and making them
## restart the game to have one would answer a different question.
const RESPAWN_DELAY := 6.0

@export var player_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath

var _player: CharacterBody3D = null
var _manager: Node = null
var _camera_rig: Node = null
var _wild_pals: Array[Node3D] = []
var _engaged_with: Node3D = null
var _ally_body: Node3D = null

var _engage_range: float = 6.0
var _prompt: String = ""

## Pals waiting on their faint to clear, and on their respawn. Keyed by node, so
## two creatures can be knocked out at once without one cancelling the other's
## timer — which is the bug a single shared `_respawn_left` would have.
var _faint_timers: Dictionary = {}
var _respawn_timers: Dictionary = {}

## Where a caught pal goes.
##
## This used to be `var _caught: Array[RefCounted]` — an unbounded list with a
## comment admitting it was "a milestone-local record that catching worked", and
## an accessor nothing ever called. It is gone. Caught pals now go to the party,
## which is capped at five and refuses a sixth, so CLAUDE.md's hard rule is
## enforced by the code that holds the pals rather than by prose above a list
## that could not enforce it.
@export var party_path: NodePath

## The node that answers `ground_height_at`. Found by walking up rather than
## exported, because every scene this director is dropped into has one somewhere
## above it and an export is one more path to wire wrong.
##
## D09 is why placement asks it at all instead of casting a ray downward: about a
## quarter of downward rays miss terrain that is demonstrably there, and a
## creature whose ray missed is left at the world origin under the map, where the
## player can neither see nor reach it and nothing is printed.
var _world: Node = null
var _party: Node = null
## M10's clock and weather. Optional — see `_ready()`.
var _sky: Node = null

## M13's Team Tether route, when one is mounted. Duck-typed and optional: the
## director works exactly as it did without one, which is what lets every
## existing smoke and the M2-M12 scenes carry on unchanged.
##
## It is asked rather than reading input of its own, because of what
## `_read_engage_input` below records: `is_action_just_pressed` is scoped to the
## frame the press was recorded in, and two systems reading it from different
## ticks will each sometimes see a different half of one press. There is one
## engage button in this game and this file owns it.
var _challenges: Node = null


func _ready() -> void:
	# SYNCHRONOUSLY, and first. The Meadows legendary is not in species.json (see
	# data/trainers/species_addendum.json for why), and `pal_instance.from_record`
	# rebuilds a saved pal by asking the species table for its id. `SaveDirector`
	# is the scene's FIRST child and waits a process frame before restoring, so
	# doing this here — not deferred, not awaited — puts the table in order before
	# any record is looked up. A legendary that saved and then vanished on load
	# would be the worst failure available to this milestone.
	TETHER_ROSTER.register()

	_party = get_node_or_null(party_path)
	_world = _find_the_world()
	# M10's clock, if the scene carries one. OPTIONAL and duck-typed: without a
	# SkyCycle every `spawn_weight` call is skipped and the meadow populates
	# exactly as it did before, which is what keeps every smoke that builds a
	# bare world working.
	_sky = get_parent().get_node_or_null(^"SkyCycle") if get_parent() != null else null
	if _sky != null and not _sky.has_method("spawn_weight"):
		push_warning("a SkyCycle is present but cannot answer spawn_weight; spawns will ignore the clock")
		_sky = null
	_engage_range = float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	_player = get_node_or_null(player_path) as CharacterBody3D
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	if _player == null or _manager == null:
		push_error("encounter director needs a player and a combat manager")
		set_process(false)
		return
	_manager.connect("exited", _on_combat_exited)
	_hunt.configure(MATH.config().get("defenceless", {}))

	# `_ready` runs while the parent is still setting up its children, and
	# add_child() is refused during that. One frame is enough to be out of it.
	await get_tree().process_frame
	await _spawn_creatures()
	_mount_the_stronghold_route()


## MOUNT M13/M14's TEAM TETHER ROUTE, AND MOVE THIS THE DAY THE SCENE CAN CARRY
## IT.
##
## `scripts/trainers/stronghold_route.gd` is a Node3D with no scene of its own.
## It belongs in `scenes/world/meadows_playground.tscn` beside `EncounterDirector`
## and `Structures`, as:
##
##   [node name="StrongholdRoute" type="Node3D" parent="."]
##   script = <res://scripts/trainers/stronghold_route.gd>
##
## with the four paths it needs bound the same way `Recovery` binds its five.
##
## It is created HERE instead for exactly the reason `build_mode._mount_field_
## systems()` gives above its own copy of this comment: the milestone that wrote
## it did not own that scene file and two other agents were editing it at the
## time. This is wiring, not design. It creates nothing if the scene already
## provides the node, so adding it properly is a scene edit and the deletion of
## this function, in either order.
##
## The alternative was shipping a trainer battle nothing in the running game
## could reach — the "written and never called" shape this project keeps getting
## bitten by, which `save_director.gd` and D13's dead `_caught` array both exist
## because of.
func _mount_the_stronghold_route() -> void:
	var world := get_parent()
	if world == null or world.get_node_or_null(^"StrongholdRoute") != null:
		return
	var route: Node3D = STRONGHOLD_ROUTE.new()
	route.name = "StrongholdRoute"
	# Bound BEFORE it enters the tree: its `_ready()` defers straight into raising
	# the posts, and that needs a player to face and a world to stand on.
	route.call("bind", _player, self, _manager, _world)
	world.add_child(route)
	set_challenge_source(route)


## How many physics frames to keep trying to stand the wild pal on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and a raycast before then hits nothing. The first version of this
## spawned once on frame two, the ray missed, and the creature sat at the world
## origin under the terrain — where the player could neither see nor reach it,
## and where no error was printed. Retrying is the fix; the frame budget is so a
## scene with genuinely no ground fails loudly instead of looping.
const GROUND_WAIT_FRAMES := 300


func _spawn_creatures() -> void:
	var origin := _player.global_position

	for entry: Variant in WILD_SPAWNS:
		var spawn: Dictionary = entry
		await _place_one(str(spawn["species"]), origin + (spawn["offset"] as Vector3), true)

	await _populate_the_meadow(origin)

	_report_population()

	# The player's pal exists as a body in the world the whole time and is simply
	# hidden outside combat. Instancing it at the moment a fight opens is a hitch
	# in the one frame that most needs to be smooth.
	_ally_body = PAL_SCENE.instantiate()
	_ally_body.name = "AllyPal"
	_ally_body.set_script(BODY_SCRIPT)
	get_parent().add_child(_ally_body)
	_ally_body.visible = false

	# The deployed pal comes FROM THE PARTY.
	#
	# It used to be a separately-spawned starter that the party never knew about,
	# which is how a fight could begin with `party size: 0` — a blind reviewer
	# spotted exactly that in the transcript and asked, reasonably, what was
	# fighting on the player's behalf when they owned nothing. The seam existed
	# because M3 needed something to fight with before a party existed; it should
	# have closed the moment one did.
	#
	# The starter is granted INTO the party rather than held beside it, so there
	# is exactly one answer to "which pals does the player have" and switching in
	# a fight is switching the same list the menu shows.
	if _party != null and int(_party.call("size")) == 0:
		var starter: RefCounted = SPECIES.spawn(STARTER_SPECIES)
		if starter == null:
			push_error("starter species '%s' is missing from species.json" % STARTER_SPECIES)
		elif not bool(_party.call("add", starter)):
			push_error("could not grant the starter: %s" % _party.call("last_refusal"))

	var deployed := _active_pal()
	if deployed == null:
		push_error("no pal to deploy: the party is empty and the starter could not be granted")
	else:
		# Dressing the body early is a courtesy to the first fight, not the
		# decision about who fights it. CombatManager.begin() re-deploys the body
		# from the party every time a fight opens, so changing the deployment in
		# the menu changes what walks out — which was the entire point of this
		# line and was not true while the answer was cached here.
		_ally_body.call("setup", deployed.species_id)


## --- populating the meadow -------------------------------------------------

## How many spawn points were asked for, and how many found ground. Printed at
## boot rather than kept quiet: a creature that could not be placed is a species
## the player will never meet, and the failure is otherwise invisible.
var _asked_for: int = 0
var _skipped_no_ground: int = 0
var _skipped_too_steep: int = 0
var _skipped_crowded: int = 0
## How many spawns the clock and the weather turned away. Counted and printed
## with the others, because "the meadow is emptier than usual" and "the spawner
## is broken" look identical from outside, and only this number tells them apart.
var _out_of_season: int = 0


static func spawn_config() -> Dictionary:
	var file := FileAccess.open(SPAWNS_PATH, FileAccess.READ)
	if file == null:
		push_error("no spawn table at %s; the meadow will hold only its starter pair" % SPAWNS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Scatter the roster across the meadow.
##
## The world used to hold TWO creatures, at two offsets hardcoded above, while
## species.json defined eight. Six species existed only in a data file. The owner
## played that build and called it "a version that had no creatures", which was
## very nearly the literal truth.
##
## Seeded, so the meadow is the same every launch — same reasoning as
## `scatter_rules.gd`, and D05's: the geography is authored rather than rolled
## per save, and inhabitants that reshuffle cannot be learned.
func _populate_the_meadow(origin: Vector3) -> void:
	var config := spawn_config()
	var population: Array = config.get("population", [])
	if population.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 20250805))
	var pad_clear := float(config.get("spawn_pad_clear", 22.0))
	var separation := float(config.get("min_separation", 9.0))
	var max_slope := deg_to_rad(float(config.get("max_slope_deg", 34.0)))
	var taken: Array[Vector3] = []

	for entry: Variant in population:
		var band: Dictionary = entry
		var species := str(band.get("species", ""))
		if species.is_empty() or not SPECIES.has(species):
			push_warning("spawn table names '%s', which is not in species.json" % species)
			continue
		var near := maxf(pad_clear, float(band.get("near", 40.0)))
		var far := maxf(near + 1.0, float(band.get("far", 160.0)))
		for i in int(band.get("count", 0)):
			_asked_for += 1
			# M10's habitat + time + weather gate (§24). `spawn_weight` is a FLOAT
			# rather than a bool so the roll happens here, against the seeded
			# generator this loop already owns — which keeps the meadow
			# reproducible from spawns.json's seed instead of depending on what
			# the sky happened to be doing.
			#
			# A species with no condition returns 1.0, so the common creatures are
			# unaffected and the whole gate is opt-in from data.
			if _sky != null and rng.randf() >= float(_sky.call("spawn_weight", species)):
				_out_of_season += 1
				continue
			var at: Variant = _find_a_home(origin, rng, near, far, max_slope, separation, taken)
			if at == null:
				continue
			taken.append(at as Vector3)
			await _place_one(species, at as Vector3, false)


## Look for somewhere in the band this creature can actually stand.
##
## Returns null rather than a fallback position. A creature dropped at a spot
## that failed its checks is a creature standing in a lake, on a cliff, or inside
## another one — all of which read as the world being broken, and all of which
## are worse than one fewer rabbit.
func _find_a_home(
	origin: Vector3, rng: RandomNumberGenerator, near: float, far: float,
	max_slope: float, separation: float, taken: Array[Vector3]
) -> Variant:
	if _world == null:
		return null
	for attempt in 24:
		var angle := rng.randf() * TAU
		# sqrt, so points spread evenly over the RING rather than bunching at its
		# inner edge — uniform radius puts far too many creatures close in.
		var t := sqrt(rng.randf())
		var radius: float = near + (far - near) * t
		var at := origin + Vector3(cos(angle), 0.0, sin(angle)) * radius

		var height: float = float(_world.call("ground_height_at", at.x, at.z))
		if is_nan(height):
			continue
		at.y = height

		if _slope_at(at) > max_slope:
			continue

		var crowded := false
		for other: Vector3 in taken:
			if Vector2(other.x - at.x, other.z - at.z).length() < separation:
				crowded = true
				break
		if crowded:
			continue
		return at

	# Which check ran out is worth knowing — "the band is all cliff" and "the band
	# is full" want different edits to the table.
	_skipped_crowded += 1
	return null


## Slope from the heightfield, never a ray. D09: about a quarter of downward rays
## miss terrain that is demonstrably there.
func _slope_at(at: Vector3) -> float:
	if _world == null:
		return 0.0
	const STEP := 1.5
	var here: float = float(_world.call("ground_height_at", at.x, at.z))
	var east: float = float(_world.call("ground_height_at", at.x + STEP, at.z))
	var north: float = float(_world.call("ground_height_at", at.x, at.z + STEP))
	if is_nan(here) or is_nan(east) or is_nan(north):
		return 0.0
	var fall := Vector2(east - here, north - here).length()
	return atan2(fall, STEP)


## One creature, standing on the ground, wired to the one route into a fight.
func _place_one(species: String, at: Vector3, required: bool) -> void:
	var wild: Node3D = PAL_SCENE.instantiate()
	wild.name = "Wild_%s" % species
	wild.set_script(WILD_SCRIPT)
	get_parent().add_child(wild)
	if not await _stand_on_ground(wild, at):
		_skipped_no_ground += 1
		if required:
			push_error("no ground under the %s spawn point; it will be unreachable" % species)
		wild.queue_free()
		return
	wild.call("populate", species, _player)
	wild.call("configure", MATH.config().get("wild", {}))
	wild.set("home", wild.global_position)
	# An aggressive creature asks; this node decides. Keeping the decision here
	# means every route into a fight goes through one place, so a new one cannot
	# forget to suspend exploration or hand over the camera.
	wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
	_wild_pals.append(wild)


func _report_population() -> void:
	var by_species: Dictionary = {}
	for wild: Node3D in _wild_pals:
		var id := str(wild.get("species_id"))
		by_species[id] = int(by_species.get(id, 0)) + 1
	print("[meadow] %d creatures live here: %s" % [_wild_pals.size(), by_species])
	if _skipped_no_ground > 0 or _skipped_crowded > 0:
		print("[meadow] %d spawn points asked for, %d found no ground, %d found no room" % [
			_asked_for, _skipped_no_ground, _skipped_crowded
		])
	if _sky != null:
		print("[meadow] %s, %s — %d spawn(s) were out of season" % [
			_sky.call("phase"), _sky.call("weather"), _out_of_season
		])


## Whichever pal the party currently has deployed.
##
## Read through the party rather than cached, so `set_active()` from the menu and
## the in-fight switch cannot disagree about who is out.
##
## That sentence used to sit above a function whose only caller cached the result
## at world load. Nothing calls it and keeps the answer now: the prompt asks per
## frame, the fight asks at the moment it opens, and CombatManager asks the party
## again on every switch.
func _active_pal() -> RefCounted:
	return (_party.call("active") as RefCounted) if _party != null else null


## The nearest ancestor that can answer for the ground.
func _find_the_world() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return node
		node = node.get_parent()
	return null


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(body.call("place_on_ground", spot)):
			return true
		await get_tree().physics_frame
	return false


## The peaceful practice pal. Named for what it is used for rather than by index,
## so tests and tools do not silently start pointing at a different creature when
## the spawn list changes.
func wild_pal() -> Node3D:
	return _wild_of_species("wild_rabbit")


func aggressive_pal() -> Node3D:
	return _wild_of_species("wild_bristler")


func wild_pals() -> Array[Node3D]:
	return _wild_pals


## What the player is holding. Answered by the party, which is the only place a
## pal can be.
func caught() -> Array:
	return _party.call("members") if _party != null else []


## Hand a caught pal to the party.
##
## The refusal is not swallowed. A full party refusing a sixth is the moment
## M5's release ceremony exists to resolve, and a director that quietly dropped
## the creature on the floor would make that ceremony unreachable — the player
## would simply never learn they had caught anything.
func _keep(instance: RefCounted) -> void:
	if _party == null:
		push_warning("caught %s with no party to put it in" % instance.species_id)
		return
	if not bool(_party.call("add", instance)):
		var token := str(_party.call("last_refusal"))
		push_warning("could not keep %s: %s" % [instance.species_id, token])
		caught_refused.emit(token, instance)


func _wild_of_species(id: String) -> Node3D:
	for wild in _wild_pals:
		if str(wild.get("species_id")) == id:
			return wild
	return null


## Register whatever offers challenges — `scripts/trainers/stronghold_route.gd`
## today. Optional, and separate from the mount above so a scene that provides
## the node itself can point this at it without going through `_ready`.
func set_challenge_source(node: Node) -> void:
	_challenges = node


## Start a fight against a creature somebody else brought.
##
## The public face of `_start_fight`, for `scripts/trainers/tether_trainer.gd`.
## A trainer battle is N ordinary fights in a row, and every one of them has to
## come through the same door a wild encounter does — the door that suspends
## exploration, hands over the camera, and deploys from the party. A second
## entrance that forgot half of that would be a bug that only appears when you
## are being fought by a person.
func engage(opponent: Node3D) -> bool:
	if opponent == null or not is_instance_valid(opponent):
		return false
	_start_fight(opponent)
	return _engaged_with == opponent


## A creature offered to the player by something that is not a catch.
##
## M14's legendary is the only caller. It goes through `_keep()`, which is the
## same function a capture goes through, which calls `Party.add()`, which refuses
## a sixth with `REFUSED_PARTY_FULL`, which is re-emitted as `caught_refused` and
## which `scripts/pals/release_prompt.gd` has opened the release ceremony on
## since M5.
##
## No second path, no second ceremony, no holding pen. D13 and D16 are explicit
## that the moment a pal can enter the party — or wait beside it — by any other
## route, the five-pal cap has an exception and the ceremony becomes optional.
## The most important creature in the region therefore arrives through the
## narrowest door in the codebase, and that is deliberate.
func offer_pal(instance: RefCounted) -> void:
	_keep(instance)


func ally_body() -> Node3D:
	return _ally_body


## The pal that would fight if a fight started now.
func ally_instance() -> RefCounted:
	return _active_pal()


func prompt() -> String:
	return _prompt


func _process(delta: float) -> void:
	_tick_respawn(delta)
	_update_prompt()
	_report_the_party_state()


## Engage is read on the physics tick, not the idle tick.
##
## `Input.is_action_just_pressed()` is scoped to whichever frame the press was
## recorded in, and reading it from `_process` while CombatManager reads its own
## actions from `_physics_process` means one press can be seen by one and missed
## by the other depending on where in the frame it landed. It cost a survey run
## that captured four frames of a fight that had never started.
func _physics_process(delta: float) -> void:
	_read_engage_input()
	_tick_hunt(delta)


## --- the trainer is the target --------------------------------------------

var _hunt := Hunt.new()
## The creature currently on the player, for the prompt. Null when nothing is.
var _hunter: Node3D = null


## Run the hunt for one physics step.
##
## On the physics tick and not the idle one, because it measures distances
## against creatures that move under `move_and_slide` — reading a position
## halfway through a physics step is how a blow lands from somewhere the creature
## was not.
func _tick_hunt(delta: float) -> void:
	_hunter = null
	if _player == null or _manager == null:
		return
	# Never during a fight. §14's protection inside Combat Mode is absolute and is
	# not what the owner amended — and a fight cannot be running with no pal to
	# fight it with anyway, so this is a belt to that brace.
	var open := _hunt.tick(delta, _defenceless() and not bool(_manager.call("is_fighting")))
	if not open:
		return

	for wild in _wild_pals:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance := _player.global_position.distance_to(wild.global_position)
		if not _hunt.may_strike(wild, bool(wild.get("aggressive")), distance):
			# Still the thing chasing you, even between blows — the prompt should
			# name it while it is winding back up, not only in the frame it hits.
			if _hunter == null and distance <= _hunt.strike_range * 2.0 and bool(wild.get("aggressive")):
				_hunter = wild
			continue
		_hunter = wild
		_strike_the_trainer(wild)


## Every pal the player owns is fainted.
##
## Asked fresh from the party every frame rather than latched, so reviving a pal
## ends the hunt on the next tick. A cached flag here is precisely how a player
## who has just healed a pal ends up still being chased.
func _defenceless() -> bool:
	return PARTY.none_standing(_party.call("members") if _party != null else [])


## One blow. The creature swings, the trainer takes it, and nothing else happens
## — no arena, no camera move, no fight.
func _strike_the_trainer(wild: Node3D) -> void:
	_hunt.struck(wild)
	if wild.has_method("face_towards"):
		wild.call("face_towards", _player.global_position)
	if wild.has_method("play_attack"):
		wild.call("play_attack")

	var dealt := 0.0
	if _player.has_method("hurt"):
		dealt = float(_player.call("hurt", _hunt.damage))
	else:
		# A player rig without the M6 damage entry point is a wiring mistake, not
		# a reason to silently make the trainer invulnerable — that would look
		# exactly like the hunt working.
		push_warning("the player has no hurt(); a defenceless trainer cannot be harmed")
	trainer_struck.emit(wild, dealt)


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
			# M3-only: the orb stock refills with the practice pal, because there
			# is no inventory until M8 and running dry mid-session would end the
			# testing rather than teach anything.
			_refill_orbs()


func _refill_orbs() -> void:
	var throw_aim: Node = _manager.call("throw_aim") as Node
	if throw_aim != null:
		throw_aim.call("refill")


## The nearest wild pal the player could choose to fight right now.
func _engageable() -> Node3D:
	var deployed := _active_pal()
	if deployed == null or _manager == null or deployed.fainted:
		return null
	if bool(_manager.call("is_fighting")):
		return null

	var best: Node3D = null
	var best_distance := _engage_range
	for wild in _wild_pals:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance := _player.global_position.distance_to(wild.global_position)
		if distance <= best_distance:
			best = wild
			best_distance = distance
	return best


## --- what the trainer is told ---------------------------------------------
##
## Three states, and the last two are new in M6. A downed pal used to produce
## "Bramblit is out of the fight." and stop there — true, and useless: it says
## what happened and nothing about what to do, and while the post-fight heal
## existed it was on screen for about a second anyway. Now that a faint lasts
## until the player does something about it, the prompt has to name the something.

const PROMPT_ENGAGE := "[X] / [E]   Engage %s"
const PROMPT_DEPLOYED_DOWN := "%s is out of the fight.    [Y] / [P]   Send out another"
## §16's two routes, in the order the player can act on them: the item is in
## their hand, the bed is a walk away.
const PROMPT_ALL_DOWN := "Every pal is down.    Use a %s, or rest them in a pal bed at home."
## And the same state once something has come for you. The verb changes because
## the situation has: reading a menu is no longer the first thing to do.
const PROMPT_HUNTED := "%s is on you and every pal is down.    Run for home — or use a %s."


## The line to show, given who is deployed, the whole roster, whatever is in
## engage range, and whatever is currently hunting the trainer.
##
## Static and pure so `tests/test_recovery.gd` can assert that the all-down
## message actually names both ways out. A player stranded in a field with five
## unconscious creatures is the one moment in this milestone where a missing
## sentence is indistinguishable from a broken game, and it is not something to
## find out about from a screenshot.
static func prompt_for(
	deployed: RefCounted, roster: Array, candidate_name: String, hunter_name: String = "",
	challenge: String = ""
) -> String:
	if PARTY.none_standing(roster):
		if not hunter_name.is_empty():
			return PROMPT_HUNTED % [hunter_name, revival_item_name()]
		return PROMPT_ALL_DOWN % revival_item_name()
	if deployed != null and deployed.fainted:
		# Someone else can still go out. The party menu is where that is done, so
		# the prompt names its button rather than describing the problem twice.
		return PROMPT_DEPLOYED_DOWN % deployed.display()
	# A person standing in front of you outranks a rabbit behind them. M13 puts
	# Team Tether ON the road, so a trainer and a wild creature are routinely in
	# range at the same time, and the press does the challenge — `try_engage`
	# below resolves it in this same order, so the line and the button agree.
	#
	# BELOW the two states above, not above them: with the whole party down there
	# is nothing to challenge anybody with, and offering the fight anyway would be
	# a prompt for a button that refuses.
	if not challenge.is_empty():
		return challenge
	if not candidate_name.is_empty():
		return PROMPT_ENGAGE % candidate_name
	return ""


## The revival item's name, in the words items.json gives it.
static func revival_item_name() -> String:
	var id := str(PAL.config().get("recovery", {}).get("revival_item", "revival_draught"))
	return DEFS.display_name(id)


func _update_prompt() -> void:
	var text := ""
	if not bool(_manager.call("is_fighting")):
		var candidate := _engageable()
		text = prompt_for(
			_active_pal(),
			_party.call("members") if _party != null else [],
			str(candidate.get("display_name")) if candidate != null else "",
			str(_hunter.get("display_name")) if _hunter != null else "",
			str(_challenges.call("prompt")) if _challenges != null else ""
		)
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


## Announce the all-down edge, once.
##
## Edge-triggered rather than per-frame: this is a signal something plays a sting
## on, and a sting once per frame is a noise.
var _reported_all_down: bool = false


func _report_the_party_state() -> void:
	var down := PARTY.none_standing(_party.call("members") if _party != null else [])
	if down and not _reported_all_down:
		party_all_down.emit()
	_reported_all_down = down


func _read_engage_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	# Team Tether first, and only when there is something to fight with. A player
	# whose whole party is down pressing X at a Warden must not open a battle they
	# cannot deploy into — `_engageable()` below already refuses that for wild
	# creatures and the same rule has to hold for a person.
	var deployed := _active_pal()
	if _challenges != null and deployed != null and not deployed.fainted \
		and not bool(_manager.call("is_fighting")):
		if bool(_challenges.call("try_engage")):
			return
	var candidate := _engageable()
	if candidate == null:
		return
	# For a PEACEFUL pal this press is the only way in. GAME_DESIGN.md §14
	# forbids proximity starting a fight with one, and nothing but this line
	# starts a fight with the Meadow Hopper.
	_start_fight(candidate)


## An aggressive pal has reached the trainer and is starting the fight itself.
##
## §14 lists "Aggressive pal initiates" beside the player's own routes in, and
## scopes the "not simple proximity" rule to peaceful pals. This is that other
## route, and it is guarded rather than trusted: the creature asks, and gets
## refused if a fight is already running or the player has nothing to fight with.
func _on_wild_wants_to_engage(wild: Node3D) -> void:
	if not bool(wild.get("aggressive")):
		push_error("%s asked to initiate but is not aggressive" % wild.name)
		return
	var deployed := _active_pal()
	if deployed == null or deployed.fainted or bool(_manager.call("is_fighting")):
		return
	if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
		return
	_start_fight(wild)


## One way in, whoever started it. A second route that forgot to suspend
## exploration or hand over the camera would be a bug that only shows up when
## something ambushes you.
func _start_fight(wild: Node3D) -> void:
	# The PARTY goes in, not a snapshot of it.
	#
	# This line used to build `[_ally]` — a one-element array holding a pal read
	# once at world load. Three things followed from that and all three read as
	# separate bugs: choosing a different pal in the menu did not change who
	# fought, the deployed BODY never changed species, and CombatManager's index
	# had nothing to move through, so the Switch command could not exist.
	var deployed := _active_pal()
	if deployed == null or deployed.fainted:
		return
	if not bool(_manager.call("begin", _player, wild, _ally_body, _party, _camera_rig)):
		return
	_engaged_with = wild
	_set_exploration_active(false)


func _on_combat_exited(outcome: String) -> void:
	_set_exploration_active(true)
	var wild := _engaged_with
	_engaged_with = null

	# Read BEFORE the match, because the match can change both.
	#
	# The roster especially: a creature caught in this fight joins the party
	# inside `_keep()` below, and paying it a share for its own capture would
	# hand the player a levelled newcomer for a fight it was on the wrong side of.
	var roster: Array = _party.call("members") if _party != null else []
	var deployed := _active_pal()
	var defeated: RefCounted = _manager.call("enemy") as RefCounted

	# A creature somebody else owns is not the meadow's to put back.
	#
	# `scripts/trainers/tether_trainer.gd` listens to the same `exited` signal and
	# decides what happens to its own team — recall it, send the next one, or
	# restore the lot if the player broke off. Running the wild bookkeeping over
	# it as well would be actively destructive, not merely redundant:
	# `_respawn_timers` fires `revive_at_home()`, which runs the world's own full
	# reset over the instance — so it would UN-FAINT a creature the player had
	# just knocked out, six seconds after they knocked it out, in the middle of
	# the battle. The trainer's team would put itself back up as the fight went
	# on. (`tests/test_recovery.gd` asserts that this file never names that reset
	# directly, which is why it is described rather than quoted.)
	#
	# The slump and the linger are left to the trainer too, for the same reason:
	# there is one owner of that body and it is not this file.
	var trainer_owned := wild != null and is_instance_valid(wild) \
		and wild.has_method("is_trainer_owned") and bool(wild.call("is_trainer_owned"))

	if wild != null and is_instance_valid(wild) and trainer_owned:
		if outcome == "won":
			# The body slumps where it fell — the same feedback a wild faint gives,
			# and the thing the player is looking at while the next one comes out.
			wild.call("notify_fainted")
	elif wild != null and is_instance_valid(wild):
		match outcome:
			"won":
				# It stays on the ground for a moment before it clears. §15: the
				# body is the feedback for having over-damaged something you
				# might have caught.
				wild.call("notify_fainted")
				_faint_timers[wild] = float(CATCH.config().get("faint", {}).get("linger_seconds", 4.0))
				_respawn_timers[wild] = RESPAWN_DELAY
			CAUGHT:
				var kept: RefCounted = _manager.call("caught_instance")
				if kept != null:
					_keep(kept)
				wild.visible = false
				# The creature comes back so the owner can keep testing throws.
				# It is a different individual from the one now in the party —
				# the party holds the instance that was caught, and this is the
				# world putting another of its species back on the hillside.
				#
				# That sentence sat here before anything made it true. The body
				# kept the very object the party had just taken, so the hillside
				# and the party shared one pal: reviving the body healed a party
				# member, and catching that species again came back
				# `already_held`. The handover below is what the comment always
				# claimed, and it happens NOW rather than at respawn — the moment
				# the party owns a pal, the world has to stop touching it.
				if wild.has_method("hand_instance_to_owner"):
					wild.call("hand_instance_to_owner")
				_respawn_timers[wild] = RESPAWN_DELAY

	# GAME_DESIGN.md §11: combat is the primary source of XP. Paid here, on the
	# way out of the fight, for both outcomes that mean the fight was won —
	# and before the heal below, so a level-up's HP is handed over on top of the
	# damage the fight did rather than into an already-full bar.
	if outcome == "won" or outcome == CAUGHT:
		award_xp(defeated, roster, deployed, outcome == CAUGHT)

	# NOTHING IS HEALED HERE, AND THAT IS THE MILESTONE.
	#
	# Until M6 this function ended by restoring the whole party's health, with a
	# comment saying it was a placeholder for pal beds. It was doing more damage
	# than it looked: GAME_DESIGN.md §16 says a pal at 0 HP "does not auto-revive
	# with time in the field", and a fight that ends by clearing every faint flag
	# means NOTHING IN THE GAME could ever put a pal into the state §16 describes.
	# `pal_instance.fainted` existed, `party_screen` had words for a downed pal,
	# `Switchboard` skipped one and `_engageable()` below refuses to deploy one —
	# four guards, none of them reachable.
	#
	# The two ways back are `scripts/pals/recovery.gd`: a revival item, or a pal
	# bed at home. Both cost something, which is the point.
	#
	# Whether the player is now out of pals is watched every frame in `_process`
	# rather than decided here, because recovery can undo it between fights and a
	# flag set once at the end of a fight would go stale in exactly that gap.


## --- rewards --------------------------------------------------------------
##
## GAME_DESIGN.md §11: "Combat is primary XP." Until this section existed,
## `pal_instance.grant_xp()` had no caller anywhere in `scripts/` — the level
## curve, the stat growth, the cap and six passing unit tests all worked
## perfectly on a number that never moved in a real session. Every pal the owner
## has ever played with was level 1.


## What beating this creature is worth, in XP, to the pal that finished the fight.
##
## Scaled off the DEFEATED creature, never off the player's own progress: §11
## forbids scaling wild levels to the player, and §27 asks for danger that rises
## with geography instead. A flat number would make the Thornback that ambushes
## you and the Hopper you practise on worth the same afternoon, which is exactly
## the difference §27 will need to express.
##
## Two things scale it, and only one of them can bite today:
##
##   * The creature's WEIGHT — its species' base HP, attack and defence added up
##     and measured against `reference_stat_total`. Nothing sets wild levels yet,
##     so every creature in the Meadows is level 1 and this is the only thing
##     that separates one fight from another. It is also the honest measure: a
##     kill is worth what it cost to make.
##   * The LEVEL DIFFERENCE, `defeated.level - earner.level`. Inert right now
##     (every difference is zero and the multiplier is exactly 1.0) and built in
##     anyway, because §27's deeper Meadows needs it and retrofitting it later
##     would silently rebalance every reward already in a save.
##
## `cfg` is passed in rather than read inside, for the reason catch_math.resolve()
## gives about its roll: a function that reaches for the shipping config cannot
## be tested against any other one, and a reward that cannot be tested against a
## known table is a reward nobody can prove came from the table at all.
static func xp_for_defeating(defeated: RefCounted, earner: RefCounted, caught: bool, cfg: Dictionary) -> int:
	if defeated == null or earner == null:
		return 0

	var reference := maxf(1.0, float(cfg.get("reference_stat_total", 160.0)))
	var weight: float = (
		float(defeated.base_hp) + float(defeated.base_attack) + float(defeated.base_defence)
	) / reference
	var level := float(maxi(1, int(defeated.level)))
	var difference := float(int(defeated.level) - int(earner.level))
	var multiplier := clampf(
		1.0 + float(cfg.get("level_difference_step", 0.12)) * difference,
		float(cfg.get("level_difference_min", 0.35)),
		float(cfg.get("level_difference_max", 2.0))
	)

	var award: float = float(cfg.get("win_base", 55.0)) \
		* pow(level, float(cfg.get("level_exponent", 1.2))) \
		* weight \
		* multiplier

	# A catch pays less than a kill, and not nothing.
	#
	# Nothing was the tempting answer — §15 and D08 already make catching cost
	# you orbs, a weakened target and seconds of your pal standing undefended,
	# and the creature itself is the reward. But a zero would mean the fastest
	# way to level is to kill the pals you would rather keep, which is a perverse
	# incentive pointed straight at the verb the game is named for.
	#
	# A fraction says the true thing instead: your pal did the work of wearing it
	# down and is paid for that, and the fight simply ended before the last blow,
	# so it is paid less. Winning stays the better XP route, catching stays the
	# better acquisition route, and the two verbs remain worth choosing between.
	if caught:
		award *= float(cfg.get("caught_fraction", 0.5))

	return maxi(int(cfg.get("minimum", 1)), int(round(award)))


## What the pals that did NOT fight are each paid.
##
## Not zero, and not the full share.
##
## Deployed-only is the obvious answer and it quietly breaks the five-pal design.
## The party is capped at five and CLAUDE.md says so twice; the whole emotional
## bet is that the owner knows all five. Pay only the one that fights and the
## first pal runs twenty levels ahead within an afternoon, the other four become
## too weak to deploy without losing, and the player settles on a party of one
## they are afraid to switch out of — which also makes the Switch command
## pointless, and §14 lists it as one of five.
##
## Paying everyone equally breaks it from the other side: deploying stops being a
## choice, and switching costs nothing.
##
## A full share for the pal that stood in the fight and a quarter for the ones
## that watched keeps deployment a real decision while stopping the rest of the
## five falling permanently out of the game. Fainted members are paid nothing —
## they were not watching.
static func xp_for_watching(award: int, cfg: Dictionary) -> int:
	if award <= 0:
		return 0
	var share := float(award) * float(cfg.get("bench_fraction", 0.25))
	return maxi(int(cfg.get("minimum", 1)), int(round(share)))


## Pay out a won fight.
##
## `roster` is the party as it stood when the fight ENDED, `deployed` is the pal
## that was out at the final blow, and `caught` says whether the fight ended in
## an orb rather than a faint.
##
## Public, and called from exactly one place. It takes everything it needs as
## arguments and touches no node, so tests/test_combat_rewards.gd can prove the
## payout — including the signals — without standing up a scene. The one thing
## worse than an untested reward is the reward this replaced, which was tested
## thoroughly and never called.
func award_xp(defeated: RefCounted, roster: Array, deployed: RefCounted, caught: bool) -> void:
	if defeated == null or deployed == null:
		return
	var cfg: Dictionary = PAL.config().get("rewards", {})

	var award := xp_for_defeating(defeated, deployed, caught, cfg)
	_grant(deployed, award, true)

	var share := xp_for_watching(award, cfg)
	for entry: Variant in roster:
		var pal: RefCounted = entry as RefCounted
		# `pal == defeated` is not paranoia: a caught creature is the opponent AND
		# a party member moments later, and the roster is snapshotted early
		# precisely so it cannot be both here.
		if pal == null or pal == deployed or pal == defeated or pal.fainted:
			continue
		_grant(pal, share, false)


func _grant(pal: RefCounted, amount: int, deployed: bool) -> void:
	if pal == null or amount <= 0:
		return
	# A capped pal is told nothing rather than told it gained XP it cannot spend.
	# grant_xp() correctly refuses at the cap; announcing an award it discarded
	# would put a number on screen that no bar can account for.
	if pal.level >= PAL.level_cap():
		return
	var gained: int = pal.grant_xp(amount)
	xp_awarded.emit(pal, amount, deployed)
	if gained > 0:
		pal_levelled.emit(pal, int(pal.level), gained)


## Hand control back and forth between exploration and combat. One place, so a
## new way of entering a fight cannot forget half of it.
func _set_exploration_active(active: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", active)
