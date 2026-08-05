extends Node3D

## The road to the stronghold, with Team Tether standing on it.
##
## MEADOWS_VERTICAL_SLICE.md M13's fourth bullet: "simple authored stronghold
## route". It is authored in `data/config/trainers.json` against the road that
## already exists — `trails.json`'s `meadow_spine` bends north out of the
## settlement and stops at the foot of the bluff — so walking the road IS the
## route and no terrain was touched to make it one. That matters beyond
## tidiness: the world scene and the terrain belonged to other agents for the
## whole of this milestone.
##
## Three posts, rising: a picket at the bend, a wrangler at the cable run, and
## the Warden at the gate. The ruin is on the skyline above the Warden and stays
## exactly what `settlement.json` says it is — a landmark whose 48-degree flanks
## are past the controller's 45-degree limit, unreachable by its own geography
## rather than by a wall. The measurement is in `trainers.json`.
##
## This node also owns M14's legendary rig, because the two are one piece of
## work: the Warden is the tether's guard, and beating him cuts it.

const DATA := preload("res://scripts/trainers/tether_data.gd")
const ROSTER := preload("res://scripts/trainers/tether_roster.gd")
const TRAINER := preload("res://scripts/trainers/tether_trainer.gd")
const OFFER := preload("res://scripts/trainers/legendary_offer.gd")

## How many physics frames to keep waiting for ground to exist under the first
## post. `encounter_director` records why this is not one frame: Terrain3D builds
## its collision over several frames after the data directory loads, and a
## placement before then puts a body at the world origin under the map where
## nothing is printed and nobody can reach it.
const GROUND_WAIT_FRAMES := 300

signal warden_beaten(trainer_id: String)

var _player: Node3D = null
var _director: Node = null
var _manager: Node = null
var _world: Node = null

var _trainers: Array[Node3D] = []
var _offer: Node3D = null
var _raised: bool = false


## Wired before entering the tree, `build_mode`-style, so `_ready` can defer
## straight into building the road.
func bind(player: Node3D, director: Node, manager: Node, world: Node) -> void:
	_player = player
	_director = director
	_manager = manager
	_world = world


func _ready() -> void:
	# Belt to `encounter_director`'s brace. The legendary's species has to be in
	# the table before anything asks for it, and this is the second of the two
	# call sites `tether_roster` mentions. Idempotent.
	ROSTER.register()
	_raise_the_road.call_deferred()


func _raise_the_road() -> void:
	if _raised:
		return
	if _player == null or _director == null or _manager == null:
		push_error("the stronghold route was not bound to a player, a director and a combat manager")
		return
	if not await _wait_for_ground():
		push_error("no ground under the stronghold route; Team Tether will not be on the road")
		return
	_raised = true

	var warden: Node3D = null
	for entry: Variant in DATA.route_posts():
		var post: Dictionary = entry
		var built := _raise_a_post(post)
		if built != null and bool((DATA.trainer(str(post.get("trainer", ""))) as Dictionary).get("holds_legendary", false)):
			warden = built

	if warden != null:
		_raise_the_legendary(warden)
	print("[tether] %d trainers on the road to the stronghold%s" % [
		_trainers.size(), "" if warden == null else ", and a legendary on the line"
	])


## Wait until the world can answer for the ground under the first post.
func _wait_for_ground() -> bool:
	var posts := DATA.route_posts()
	if posts.is_empty() or _world == null or not _world.has_method("ground_height_at"):
		return false
	var at: Array = (posts[0] as Dictionary).get("at", [0.0, 0.0])
	for i in GROUND_WAIT_FRAMES:
		var height: float = float(_world.call("ground_height_at", float(at[0]), float(at[1])))
		if not is_nan(height):
			return true
		await get_tree().physics_frame
	return false


func _raise_a_post(post: Dictionary) -> Node3D:
	var id := str(post.get("trainer", ""))
	var definition := DATA.trainer(id)
	if definition.is_empty():
		push_error("the route names trainer '%s', which has no file in data/trainers/" % id)
		return null

	var at: Array = post.get("at", [0.0, 0.0])
	var spot: Variant = _on_ground(float(at[0]), float(at[1]))
	if spot == null:
		push_error("no ground under trainer '%s' at %s" % [id, at])
		return null

	var node := Node3D.new()
	node.name = "TetherTrainer_%s" % id
	node.set_script(TRAINER)
	add_child(node)
	node.global_position = spot as Vector3
	if not bool(node.call("configure", definition, _player, _director, _manager, _world)):
		node.queue_free()
		return null
	# Facing back down the road, at whoever is walking up it. Derived from the
	# NEXT post rather than authored per trainer: the route already says which way
	# the road goes, and a hand-written facing is one more number to keep in step
	# with a coordinate.
	node.call("raise_the_post", _facing_down_the_road(spot as Vector3))
	_trainers.append(node)

	if bool(definition.get("holds_legendary", false)):
		node.connect("beaten", _on_warden_beaten)
	return node


## Which way a post at `spot` should look: back along the route, towards the
## first post, which is where the player comes from.
func _facing_down_the_road(spot: Vector3) -> Vector3:
	var posts := DATA.route_posts()
	if posts.is_empty():
		return Vector3.FORWARD
	var first: Array = (posts[0] as Dictionary).get("at", [0.0, 0.0])
	var to := Vector3(float(first[0]), spot.y, float(first[1])) - spot
	to.y = 0.0
	return Vector3.FORWARD if to.length() < 0.5 else to.normalized()


func _on_ground(x: float, z: float) -> Variant:
	if _world == null or not _world.has_method("ground_height_at"):
		return null
	var height: float = float(_world.call("ground_height_at", x, z))
	if is_nan(height):
		return null
	return Vector3(x, height, z)


func _raise_the_legendary(warden: Node3D) -> void:
	var cfg: Dictionary = DATA.legendary()
	var at: Array = cfg.get("at", [0.0, 0.0])
	var pylon: Array = cfg.get("pylon_at", at)
	var approach: Array = cfg.get("approach", at)

	var spot: Variant = _on_ground(float(at[0]), float(at[1]))
	if spot == null:
		push_error("no ground under the legendary at %s" % [at])
		return

	_offer = Node3D.new()
	_offer.name = "MeadowsLegendaryOffer"
	_offer.set_script(OFFER)
	add_child(_offer)
	if not bool(_offer.call("configure", _player, _director, _world)):
		_offer.queue_free()
		_offer = null
		return
	var approach_spot: Variant = _on_ground(float(approach[0]), float(approach[1]))
	_offer.call(
		"raise_the_rig",
		spot as Vector3,
		Vector3(float(pylon[0]), (spot as Vector3).y, float(pylon[1])),
		(approach_spot if approach_spot != null else spot) as Vector3
	)
	# Held so a `beaten` that arrives before the rig is up still cuts the tether.
	if warden.call("is_beaten"):
		_offer.call("cut_the_tether")


func _on_warden_beaten(trainer_id: String) -> void:
	if _offer != null:
		_offer.call("cut_the_tether")
	warden_beaten.emit(trainer_id)


## --- what the encounter director asks --------------------------------------
##
## The director owns the `interact` press and the world prompt, and has since M2.
## It asks here rather than this file reading input of its own, for the reason
## `encounter_director._read_engage_input` records at length: two systems reading
## `is_action_just_pressed` from different ticks will each sometimes see a
## different half of one press.

## The line to show, or "" for nothing. The legendary's offer outranks a
## trainer's challenge — if both are in range, the creature you have just freed
## is the thing you are looking at.
func prompt() -> String:
	if _offer != null:
		var line := str(_offer.call("prompt_line"))
		if not line.is_empty():
			return line
	var nearest: Node3D = _nearest_trainer()
	return "" if nearest == null else str(nearest.call("prompt_line"))


## Accept whatever is in range. Returns true when something was taken, so the
## director knows not to also engage a wild creature with the same press.
func try_engage() -> bool:
	if _offer != null and bool(_offer.call("can_accept")):
		return bool(_offer.call("accept"))
	var nearest: Node3D = _nearest_trainer()
	if nearest == null:
		return false
	return bool(nearest.call("challenge"))


## True while any trainer on the road has a battle running, so the director can
## leave the wild encounter prompt alone.
func battle_in_progress() -> bool:
	for trainer in _trainers:
		if is_instance_valid(trainer) and bool(trainer.call("is_active")):
			return true
	return false


func _nearest_trainer() -> Node3D:
	var best: Node3D = null
	var best_distance := DATA.engage_range()
	for trainer in _trainers:
		if not is_instance_valid(trainer):
			continue
		var distance: float = float(trainer.call("distance_to_player"))
		if distance <= best_distance:
			best = trainer
			best_distance = distance
	return best


## --- readouts for tests and transcripts ------------------------------------

func trainers() -> Array[Node3D]:
	return _trainers


func trainer_by_id(id: String) -> Node3D:
	for trainer in _trainers:
		if is_instance_valid(trainer) and str(trainer.get("trainer_id")) == id:
			return trainer
	return null


func legendary_offer() -> Node3D:
	return _offer
