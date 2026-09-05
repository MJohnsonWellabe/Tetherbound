extends Node3D

## A durable, physical gate between realms.
##
## The key is a progression entitlement, not a carried inventory item.  It is
## therefore impossible to drop, overflow from a full satchel, or lose on the
## frame the Warden reward is granted.  Unlocking writes its own progression
## flag and takes one deliberate interaction; entering takes the next.
##
## `Game.enter_realm(destination_realm, destination_entry_id)` owns scene
## transition/loading.  This component only proves the gate state, changes its
## physical presentation, and asks Game to travel.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const STATE_LOCKED := "locked"
const STATE_UNLOCKABLE := "unlockable"
const STATE_UNLOCKED := "unlocked"

const STONE := Color("4b5660")
const STONE_EDGE := Color("77848a")
const SEALED := Color("4ec2cb")
const OPEN := Color("a8e9d1")

@export var destination_realm: String = "cloudreach"
@export var destination_entry_id: String = "meadows_gate"
@export var destination_label: String = "Cloudreach Cliffs"
@export var key_flag: String = "realm_key_cloudreach"
@export var unlock_flag: String = "realm_gate_cloudreach_unlocked"
@export var interaction_radius: float = 4.0

var _prompt: Node3D = null
var _barrier_shape: CollisionShape3D = null
var _sealed_visual: Node3D = null
var _open_visual: Node3D = null
var _open_material: StandardMaterial3D = null
var _built := false
var _observed_progression: RefCounted = null
var _progression_revision := -1


## Configure before adding to the scene tree.  The destination entry id names
## the authored arrival point in the destination realm; it is not a position
## copied across unrelated coordinate spaces.
func setup(
		p_destination_realm: String,
		p_destination_entry_id: String,
		p_destination_label: String,
		p_key_flag: String,
		p_unlock_flag: String
	) -> void:
	destination_realm = p_destination_realm
	destination_entry_id = p_destination_entry_id
	destination_label = p_destination_label
	key_flag = p_key_flag
	unlock_flag = p_unlock_flag
	if is_inside_tree():
		refresh_from_game()


func _ready() -> void:
	add_to_group("progression_restore")
	_build_visual()
	_build_prompt()
	refresh_from_game()


## Public, side-effect-free state query for tests and world sequencing.
func state_for(game: Node) -> String:
	if is_unlocked(game):
		return STATE_UNLOCKED
	if has_key(game):
		return STATE_UNLOCKABLE
	return STATE_LOCKED


func current_state() -> String:
	return state_for(_game())


func _process(_delta: float) -> void:
	var game := _game()
	var progression := _progression(game)
	if progression != _observed_progression \
			or (progression != null and int(progression.get("revision")) != _progression_revision):
		_refresh(game)


func has_key(game: Node) -> bool:
	var progression := _progression(game)
	return progression != null and key_flag != "" and bool(progression.call("has", key_flag))


func is_unlocked(game: Node) -> bool:
	var progression := _progression(game)
	return progression != null and unlock_flag != "" and bool(progression.call("has", unlock_flag))


## Writes the durable unlock only when the key entitlement exists.  The key is
## intentionally retained: it is the player's record of completing the prior
## realm, not a consumable tooth snapped off in this one lock.
func try_unlock(game: Node) -> bool:
	if is_unlocked(game):
		return true
	var progression := _progression(game)
	if progression == null or not has_key(game) or unlock_flag == "":
		return false
	progression.call("set_flag", unlock_flag)
	return is_unlocked(game)


## Calls the persistent realm router only after the durable unlock is set.
## Returning true means the request was issued; the asynchronous transition is
## still Game's responsibility.
func try_enter(game: Node) -> bool:
	if game == null or not is_unlocked(game) or destination_realm == "":
		return false
	if not game.has_method("enter_realm"):
		push_error("RealmGate: Game has no enter_realm(destination, entry_id) method")
		return false
	game.call("enter_realm", destination_realm, destination_entry_id)
	return true


func restore_progression_from_game(game: Node) -> void:
	_refresh(game)


func refresh_from_game() -> void:
	_refresh(_game())


func _on_activated() -> void:
	var game := _game()
	match state_for(game):
		STATE_UNLOCKABLE:
			if try_unlock(game):
				_refresh(game)
				if game != null and game.has_method("push_world_message"):
					game.call("push_world_message", "The way to %s is open." % destination_label)
		STATE_UNLOCKED:
			try_enter(game)
		_:
			pass


func _refresh(game: Node) -> void:
	if not _built or _prompt == null:
		return
	_observed_progression = _progression(game)
	_progression_revision = int(_observed_progression.get("revision")) if _observed_progression != null else -1
	var state := state_for(game)
	match state:
		STATE_LOCKED:
			_prompt.call("configure", "The passage to %s is sealed" % destination_label, interaction_radius, true)
			_prompt.set("actionable", false)
			_set_open_visual(false, false)
		STATE_UNLOCKABLE:
			_prompt.call("configure", "Unlock the way to %s" % destination_label, interaction_radius, true)
			_prompt.set("actionable", true)
			_set_open_visual(false, true)
		STATE_UNLOCKED:
			_prompt.call("configure", "Enter %s" % destination_label, interaction_radius, true)
			_prompt.set("actionable", true)
			_set_open_visual(true, true)


func _set_open_visual(opened: bool, key_present: bool) -> void:
	_sealed_visual.visible = not opened
	_open_visual.visible = opened
	_barrier_shape.set_deferred("disabled", opened)
	# Before the Warden reward the seal is cold blue-grey.  Once the player has
	# the key it brightens visibly, making the next interaction legible without
	# turning the progression requirement into floating UI text.
	var seal_material := _sealed_visual.get_meta("material") as StandardMaterial3D
	if seal_material != null:
		seal_material.albedo_color = SEALED if key_present else SEALED.darkened(0.58)
		seal_material.emission = SEALED if key_present else SEALED.darkened(0.68)
		seal_material.emission_energy_multiplier = 1.8 if key_present else 0.28
	if opened:
		_open_material.emission_energy_multiplier = 0.65


func _build_prompt() -> void:
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(0.0, 1.25, 0.72)
	_prompt.call("configure", "The passage is sealed", interaction_radius, true)
	_prompt.set("actionable", false)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)


func _build_visual() -> void:
	if _built:
		return
	_built = true
	var stone := _material(STONE)
	var edge := _material(STONE_EDGE)

	_add_box("LeftPillar", Vector3(-1.75, 2.2, 0.0), Vector3(0.72, 4.4, 0.86), stone)
	_add_box("RightPillar", Vector3(1.75, 2.2, 0.0), Vector3(0.72, 4.4, 0.86), stone)
	_add_box("Lintel", Vector3(0.0, 4.25, 0.0), Vector3(4.2, 0.72, 0.9), stone)
	_add_box("LeftCap", Vector3(-1.75, 4.45, 0.0), Vector3(0.98, 0.28, 1.05), edge)
	_add_box("RightCap", Vector3(1.75, 4.45, 0.0), Vector3(0.98, 0.28, 1.05), edge)

	_sealed_visual = Node3D.new()
	_sealed_visual.name = "RealmSeal"
	add_child(_sealed_visual)
	var seal_material := _glow_material(SEALED.darkened(0.58), 0.28, 0.72)
	_sealed_visual.set_meta("material", seal_material)
	_add_box_to(_sealed_visual, "EnergyVeil", Vector3(0.0, 2.15, 0.0), Vector3(2.95, 3.55, 0.06), seal_material)
	var lock := MeshInstance3D.new()
	lock.name = "KeySeal"
	var lock_mesh := CylinderMesh.new()
	lock_mesh.top_radius = 0.46
	lock_mesh.bottom_radius = 0.46
	lock_mesh.height = 0.12
	lock_mesh.radial_segments = 12
	lock.mesh = lock_mesh
	lock.position = Vector3(0.0, 2.2, 0.12)
	lock.rotation.x = deg_to_rad(90.0)
	lock.material_override = seal_material
	_sealed_visual.add_child(lock)

	_open_visual = Node3D.new()
	_open_visual.name = "OpenThreshold"
	add_child(_open_visual)
	_open_material = _glow_material(OPEN, 0.65, 0.16)
	_add_box_to(_open_visual, "OpenAirShimmer", Vector3(0.0, 2.15, 0.0), Vector3(2.95, 3.55, 0.025), _open_material)

	var body := StaticBody3D.new()
	body.name = "LockedBarrier"
	_barrier_shape = CollisionShape3D.new()
	var barrier := BoxShape3D.new()
	barrier.size = Vector3(3.15, 3.75, 0.64)
	_barrier_shape.shape = barrier
	_barrier_shape.position.y = 2.05
	body.add_child(_barrier_shape)
	add_child(body)


func _add_box(name_: String, at: Vector3, size: Vector3, material: Material) -> void:
	_add_box_to(self, name_, at, size, material)


func _add_box_to(parent: Node, name_: String, at: Vector3, size: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	parent.add_child(node)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.86
	return material


func _glow_material(colour: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(colour.r, colour.g, colour.b, alpha)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _progression(game: Node) -> RefCounted:
	if game == null:
		return null
	var value: Variant = game.get("progression")
	return value as RefCounted if value is RefCounted else null
