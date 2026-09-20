extends Node3D

## A visual consequence for the Upper Meadows lost-creature request. This node
## owns no interaction or reward: it displays one ordinary Meadowhart body at
## the patrol before rescue, then beside Juno after the existing defeat flag.

const CONFIG_PATH := "res://data/config/lost_companion_reunion.json"
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

var _world: Node3D
var _trainers: Node3D
var _body: Node3D
var _config: Dictionary = {}
var _progression: RefCounted
var _revision := -1


func build(world: Node3D, trainers: Node3D) -> void:
	_world = world
	_trainers = trainers
	add_to_group("progression_restore")
	if bool(world.get("simulation_only")):
		return
	_config = _load_config()
	if _config.is_empty():
		return
	_body = CREATURE_SCENE.instantiate() as Node3D
	_body.name = "RescuedMeadowhart"
	_body.set_script(CREATURE_BODY)
	add_child(_body)
	_body.call("setup", str(_config.get("species", "meadowhart")), false)
	# Run after creature_body's own visibility callback, which would otherwise
	# re-enable physics when the realm is shown. Leave the model's AnimationPlayer
	# processing normally while this parent supplies its idle role below.
	_body.visibility_changed.connect(_disable_simulation)
	_disable_simulation()
	refresh_position(true)


func _disable_simulation() -> void:
	_body.set_physics_process(false)
	_body.set("collision_layer", 0)
	_body.set("collision_mask", 0)
	var collider := _body.get_node_or_null("Collision") as CollisionShape3D
	if collider != null:
		collider.set_deferred("disabled", true)


func _process(delta: float) -> void:
	if _body == null:
		return
	# Physics is disabled for this display; keep the existing creature animator's
	# idle motion without running locomotion, gravity or a second AI.
	var animator: RefCounted = _body.get("_animator") as RefCounted
	if animator != null:
		animator.call("tick", delta, 0.0, 1.0)
	var current := _progression_store()
	var revision := int(current.get("revision")) if current != null else -1
	if current != _progression or revision != _revision:
		refresh_position()


func restore_progression_from_game(_game: Node) -> void:
	refresh_position(true)


## Small verification seam: returns whether the reunited placement is active.
func refresh_position(force: bool = false) -> bool:
	if _body == null or _config.is_empty():
		return false
	var current := _progression_store()
	var revision := int(current.get("revision")) if current != null else -1
	if not force and current == _progression and revision == _revision:
		return is_reunited()
	_progression = current
	_revision = revision
	var reunited := is_reunited()
	var id_key := "owner_trainer_id" if reunited else "patrol_trainer_id"
	var offset_key := "reunited_offset" if reunited else "waiting_offset"
	var yaw_key := "reunited_yaw_deg" if reunited else "waiting_yaw_deg"
	var trainer_id := str(_config.get(id_key, ""))
	var anchor := _trainer_anchor(trainer_id)
	var authored_offset := _offset(offset_key)
	var offset := Vector3(authored_offset.x, 0.0, authored_offset.y).rotated(Vector3.UP, float(anchor.yaw))
	var anchor_at: Vector2 = anchor.position
	var x := anchor_at.x + offset.x
	var z := anchor_at.y + offset.z
	var ground := float(_world.call("ground_height_at", x, z))
	if not is_finite(ground):
		push_warning("lost companion has no finite ground beside trainer '%s'" % trainer_id)
		_body.visible = false
		return reunited
	_body.global_position = Vector3(x, ground, z)
	_body.rotation.y = anchor.yaw + deg_to_rad(float(_config.get(yaw_key, 0.0)))
	_body.visible = true
	return reunited


func is_reunited() -> bool:
	return _progression != null and bool(_progression.call("has", str(_config.get("defeat_flag", ""))))


func presentation_position() -> Vector3:
	return _body.global_position if _body != null else Vector3.ZERO


func _trainer_anchor(id: String) -> Dictionary:
	if _trainers != null and _trainers.has_method("body_for"):
		var body := _trainers.call("body_for", id) as Node3D
		if body != null:
			return {"position": Vector2(body.global_position.x, body.global_position.z), "yaw": body.global_rotation.y}
	var spec := TRAINERS.trainer(id)
	var position: Array = spec.get("position", [])
	return {
		"position": Vector2(float(position[0]), float(position[1])) if position.size() >= 2 else Vector2.ZERO,
		"yaw": deg_to_rad(float(spec.get("facing_deg", 0.0)))
	}


func _offset(key: String) -> Vector2:
	var values: Array = _config.get(key, [])
	return Vector2(float(values[0]), float(values[1])) if values.size() >= 2 else Vector2.ZERO


func _progression_store() -> RefCounted:
	var game := get_node_or_null("/root/Game")
	return game.get("progression") if game != null else null


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("cannot open %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		push_error("%s is not a JSON object" % CONFIG_PATH)
		return {}
	return parsed as Dictionary
