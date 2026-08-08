extends Node

## What happens when the trainer dies.
##
## `player_controller.gd` has declared `signal died()`, emitted it on a lethal
## fall since M1, and had NOTHING LISTENING. Reaching 0 HP did nothing at all: the
## meter sat at zero, the player kept walking, and the game had no opinion. This
## is the opinion.
##
## GAME_DESIGN.md §22, line by line, is the whole design of this file:
##
##   * carried inventory drops into a satchel at the death location
##   * old satchels do not move, and several can coexist  → `satchel.gd` is a list
##   * each remains marked on map/minimap                 → `world_map.gd` reads it
##   * NO XP LOSS, NO LEVEL LOSS                          → nothing here touches a
##     pal's xp, level, stats or party slot. Not as an oversight: there is no line
##     in this file that reads or writes any of them, and `tests/test_satchel.gd`
##     asserts a party comes through a death unchanged.
##   * pals go home                                       → §16 says the same thing
##     from the other side, and adds "no pal loss; preserve their damage/fainted
##     state as appropriate". So they are put to bed, not healed.
##
## WHERE THE PLAYER WAKES UP is the one thing §22 does not say, and §20 does: the
## base is for "safety, recovery, respawn and rest". So it is the bed — a placed
## piece whose station answers `is_respawn_point()`, which `home.gd` already finds
## and calls `respawn_point()` in as many words. A player who has not built one
## yet wakes where their journey started, because the alternative is waking in the
## jaws of whatever killed them and there is nowhere else that is theirs.
##
## ONE FILE, so a second way of dying cannot forget half of it — the same "one
## door in and out" `encounter_director` uses for fights and `screen_stack` for
## menus. Anything that kills the trainer goes through `player.hurt()`, `hurt()`
## emits `died`, and this is what `died` means.

const CONFIG_PATH := "res://data/config/survival.json"
const SATCHELS := preload("res://scripts/player/satchel.gd")

## The trainer wakes up this far above the ground under the respawn point, so a
## metre of terrain-versus-collider disagreement drops them rather than embedding
## them (`player_controller._stay_above_ground()` documents the disagreement).
const RESPAWN_CLEARANCE := 1.2

## Emitted after everything: the satchel that was left, and where the player woke
## up. For a UI that wants to say "you fell" — nothing draws it yet, and this is
## the seam rather than a screen invented here.
signal died_and_woke(satchel: RefCounted, at: Vector3, dropped_stacks: int)

@export var player_path: NodePath = NodePath("../Player")
@export var inventory_path: NodePath = NodePath("../TrainerInventory")
@export var satchels_path: NodePath = NodePath("../Satchels")
@export var party_path: NodePath = NodePath("../Party")
@export var recovery_path: NodePath = NodePath("../Recovery")
@export var home_path: NodePath = NodePath("../Home")
@export var world_path: NodePath = NodePath("..")
## The save director, so dying is a checkpoint. Losing a death to a crash and
## coming back alive with your items is a worse bug than dying.
@export var save_director_path: NodePath = NodePath("../SaveDirector")

## The trainer. Typed as `Node` rather than `Node3D`, and read through `get()` /
## `set()`, because a `Node3D`'s global transform only exists once it is inside
## the scene tree — and `run_tests.gd` runs inside `SceneTree._init()`, where
## nothing is. The alternative was to leave the whole of §22 untested at the unit
## level, which is not a trade worth making for one type annotation.
var _player: Node = null
var _config: Dictionary = {}

## Where the player was standing when the world started, and the fallback respawn.
var _origin: Vector3 = Vector3.ZERO
var _have_origin: bool = false

## Set for the duration of one death. `died` is emitted from two places in
## `player_controller` (a lethal fall and `hurt()`), and a second one arriving
## mid-respawn would drop a second satchel holding the nothing the first one left.
var _dying: bool = false

var _deaths: int = 0


func _ready() -> void:
	_player = get_node_or_null(player_path)
	if _player == null:
		push_warning("nothing is listening for the player's death; there is no player wired")
		return
	if _player.has_signal("died"):
		_player.connect("died", _on_died)
	# DEFERRED, and it has to be. `_ready` propagates children first, so the world
	# node's own `_ready` — which is where `playground_world._place_player()` drops
	# the trainer onto the terrain — has not run yet when this one does. Reading the
	# position here would record the scene file's placeholder height as the spot the
	# player wakes up at, which works until the first time somebody dies before
	# building a bed and comes back forty metres in the air.
	_capture_origin.call_deferred()


func _capture_origin() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_origin = where_the_trainer_is()
	_have_origin = true


## Where the trainer is standing. Through `get()` so that anything with a
## `global_position` answers, whether or not it is a `Node3D` in a live tree.
func where_the_trainer_is() -> Vector3:
	if _player == null or not is_instance_valid(_player):
		return Vector3.ZERO
	var at: Variant = _player.get("global_position")
	return at if at is Vector3 else Vector3.ZERO


## --- the death --------------------------------------------------------------

func _on_died() -> void:
	die()


## Run the whole of §22, in order. Public so a test and a session harness can kill
## the trainer without arranging for a fall.
##
## The ORDER matters and is not arbitrary: the satchel is filled from the bag
## BEFORE the player is moved, because the satchel belongs where they fell and not
## where they woke up; the pals are sent home BEFORE the respawn, because being
## home is about the base and not about the trainer's position; and the save is
## last, because it has to record all three.
func die() -> void:
	if _dying:
		return
	_dying = true
	_deaths += 1

	var fell_at := where_the_trainer_is()
	var satchel: RefCounted = _drop_what_they_carried(fell_at)
	var sent := _send_pals_home()
	var woke_at := _respawn()

	print("[death] fell at %.0f, %.0f, %.0f — %d stack(s) in satchel, %d pal(s) sent home, woke at %.0f, %.0f, %.0f" % [
		fell_at.x, fell_at.y, fell_at.z,
		0 if satchel == null else int(satchel.count()),
		sent, woke_at.x, woke_at.y, woke_at.z,
	])

	_checkpoint()
	_dying = false
	died_and_woke.emit(satchel, woke_at, 0 if satchel == null else int(satchel.count()))


## Everything CARRIED goes into the bag on the ground. §22.
##
## Worn equipment does not: §22 drops the carried inventory, and armour is on the
## trainer rather than in their hands. There is no armour in the game yet, so
## today this is a sentence about a rule rather than an exemption anybody can
## notice — which is exactly when it is cheapest to get right.
##
## `death.keeps` in survival.json is §22's "exact item exemptions can be tuned",
## and it is EMPTY by default. The satchel is permanent and mapped, so the cost of
## dying is the walk back rather than the loss, and an exemption list would make
## that walk optional.
##
## Stacks are moved WHOLE rather than re-created by id, so a 40%-worn axe is 40%
## worn when it comes back out.
func _drop_what_they_carried(where: Vector3) -> RefCounted:
	var satchels: Node = get_node_or_null(satchels_path)
	var bag: Object = get_node_or_null(inventory_path)
	if satchels == null or bag == null or not bag.has_method("inventory"):
		push_warning("the trainer died with no satchel field or no inventory wired; nothing was dropped")
		return null

	var inventory: RefCounted = bag.call("inventory")
	var keeps := kept_items()
	var falling: Array = []
	for i in inventory.slot_count():
		var stack: RefCounted = inventory.at(i)
		if stack == null or stack.is_empty():
			continue
		if keeps.has(str(stack.item_id)):
			continue
		# `take_stack` lifts it out as a copy carrying its own wear. Handing the
		# LIVE stack to the satchel and then clearing the slot empties the very
		# thing that was handed over — see the note on that function.
		var lifted := SATCHELS.take_stack(inventory, i)
		if lifted != null:
			falling.append(lifted)

	if bag.has_signal("changed"):
		bag.emit_signal("changed")
	return satchels.call("drop", where, falling)


## §16: "When the player dies: owned pals return home to their beds; no pal loss;
## preserve their damage/fainted state as appropriate."
##
## So this calls `recovery.rest()` and NOTHING ELSE. No healing, no reviving, no
## clearing of a faint — the bed does that over time, at the rate party.json sets,
## which is what makes a faint cost something. A pal that is already at full health
## is refused by `rest()` with `nothing_to_do` and that is a correct refusal, not a
## failure: it has nothing to recover from.
##
## Returns how many actually lay down. Zero is the normal answer for a player who
## has not built a pal bed, and the refusal is logged rather than swallowed so
## "my pals did not go home" has an explanation.
func _send_pals_home() -> int:
	var party: Node = get_node_or_null(party_path)
	var recovery: Node = get_node_or_null(recovery_path)
	if party == null or recovery == null or not recovery.has_method("rest"):
		return 0
	var members: Variant = party.call("members")
	if not members is Array:
		return 0

	var sent := 0
	var last_refusal := ""
	for entry: Variant in members as Array:
		var pal: RefCounted = entry as RefCounted
		if pal == null:
			continue
		if bool(recovery.call("rest", pal)):
			sent += 1
		elif recovery.has_method("last_refusal"):
			last_refusal = str(recovery.call("last_refusal"))
	if sent == 0 and not last_refusal.is_empty():
		print("[death] no pal went home (%s)" % last_refusal)
	return sent


## Wake up. At the bed if there is one, at the start of the journey if there is
## not.
func _respawn() -> Vector3:
	var where := respawn_point()
	if _player != null:
		_player.set("global_position", where)
		# A body that keeps the velocity it died with resumes the fall it died from
		# the instant it wakes up.
		if _player is CharacterBody3D:
			(_player as CharacterBody3D).velocity = Vector3.ZERO
		var vitals: Variant = _player.get("vitals")
		if vitals is RefCounted:
			(vitals as RefCounted).call(
				"revive", respawn_health_fraction(), respawn_stamina_fraction()
			)
	return where


## Where the trainer would wake up right now.
##
## The placed bed first — `home.respawn_point()` returns `NOWHERE` unless a player
## bed whose station answers `is_respawn_point()` has been built. Otherwise where
## they started, lifted onto the terrain.
func respawn_point() -> Vector3:
	var home: Node = get_node_or_null(home_path)
	if home != null and home.has_method("respawn_point"):
		var bed: Vector3 = home.call("respawn_point")
		if bed != Vector3.INF:
			return _above_ground(bed)
	return _above_ground(_origin if _have_origin else Vector3.ZERO)


## D09: never raycast for ground. `ground_height_at` reads the heightmap, which is
## the one source of truth that cannot disagree with the collider about which side
## of the ground you are on.
func _above_ground(point: Vector3) -> Vector3:
	var world: Node = get_node_or_null(world_path)
	if world == null or not world.has_method("ground_height_at"):
		return point + Vector3(0.0, RESPAWN_CLEARANCE, 0.0)
	var ground: float = float(world.call("ground_height_at", point.x, point.z))
	if is_nan(ground):
		return point + Vector3(0.0, RESPAWN_CLEARANCE, 0.0)
	return Vector3(point.x, ground + RESPAWN_CLEARANCE, point.z)


## Dying is a checkpoint.
##
## Through `SaveDirector`, never `SaveManager.save()` directly — its header is
## emphatic that it is the one place that knows a save is in flight. `request_save`
## coalesces, so a death that lands inside the write gap is still written a few
## seconds later rather than skipped.
func _checkpoint() -> void:
	var director: Node = get_node_or_null(save_director_path)
	if director != null and director.has_method("request_save"):
		director.call("request_save", "died")


## --- config -----------------------------------------------------------------

func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("survival.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


func _death_config() -> Dictionary:
	return config().get("death", {})


## Item ids the satchel does not take. Empty by default; see the note above.
func kept_items() -> Array:
	var keeps: Variant = _death_config().get("keeps", [])
	return keeps if keeps is Array else []


func respawn_health_fraction() -> float:
	return clampf(float(_death_config().get("respawn_health_fraction", 0.6)), 0.05, 1.0)


func respawn_stamina_fraction() -> float:
	return clampf(float(_death_config().get("respawn_stamina_fraction", 0.5)), 0.0, 1.0)


func deaths() -> int:
	return _deaths


## The seam a test binds through, so the rules above need no scene.
func bind(player: Node, origin: Vector3) -> void:
	_player = player
	_origin = origin
	_have_origin = true
