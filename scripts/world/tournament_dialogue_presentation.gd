extends Node

## The marshal opens the bracket, but each opponent speaks their own lines.
## Borrow the existing village actor for that local conversation; no second
## person, reward state, or network-owned gameplay body is created. A reload
## needs no staging state: closing or leaving the realm restores the actor.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

var _world: Node = null
var _conversations: Dictionary = {}
var _body: Node3D = null
var _home := Transform3D.IDENTITY
var _conversation := ""


func build(world: Node, rounds: Array) -> void:
	_world = world
	for raw: Variant in rounds:
		if not raw is Dictionary:
			continue
		var spec: Dictionary = TRAINERS.trainer(str(raw.get("trainer", "")))
		if spec.is_empty():
			continue
		for id: String in [str(raw.get("conversation", "")), str(spec.get("defeated", "")),
				str(spec.get("victory_conversation", ""))]:
			if not id.is_empty():
				_conversations[id] = spec
	# The world can build its settlement before the UI. Bind once it exists.
	set_process(true)
	_process(0.0)


func _process(_delta: float) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		return
	panel.connect("line_presented", _on_line)
	panel.connect("finished", _on_finished)
	set_process(false)


func _on_line(id: String, _is_last: bool) -> void:
	if id == _conversation:
		return
	_restore()
	if not _conversations.has(id) or not is_instance_valid(_world):
		return
	var spec: Dictionary = _conversations[id]
	var villagers := _world.get_node_or_null(^"VillageNPCs")
	if villagers == null:
		return
	var actor := villagers.get_node_or_null(NodePath(str(spec.get("name", "")))) as Node3D
	if actor == null or not actor.has_method("stand_at"):
		return
	var at: Array = spec.get("position", [])
	if at.size() < 2:
		return
	var home := actor.global_transform
	var z := float(at[2]) if at.size() >= 3 else float(at[1])
	var stand := Vector2(float(at[0]), z)
	var player: Node3D = actor.get("_player") as Node3D
	if is_instance_valid(player):
		var player_at := Vector2(player.global_position.x, player.global_position.z)
		# The human can move around the ring during a fight. Their opponent
		# approaches for the last line rather than speaking outside camera range.
		if player_at.distance_to(stand) > 6.0:
			stand = player_at + player_at.direction_to(stand) * 3.5
	if not bool(actor.call("stand_at", stand.x, stand.y)):
		return
	_body = actor
	_home = home
	_conversation = id
	actor.rotation.y = deg_to_rad(float(spec.get("facing_deg", 180.0)))
	if is_instance_valid(player):
		var toward := player.global_position - actor.global_position
		if Vector2(toward.x, toward.z).length_squared() > 0.01:
			actor.global_rotation.y = atan2(toward.x, toward.z)
	# line_presented is synchronous with opening, after the panel's generic
	# provider-based push-in. Replace Halda's shot before any frame is drawn.
	var camera := get_tree().get_first_node_in_group("conversation_camera")
	if camera != null:
		camera.call("end")
		var aftermath := id == str(spec.get("defeated", "")) or id == str(spec.get("victory_conversation", ""))
		camera.call("begin", actor, "aftermath" if aftermath else "")


func _on_finished(_id: String) -> void:
	_restore()


func _restore() -> void:
	if is_instance_valid(_body) and _body.is_inside_tree():
		_body.global_transform = _home
	_body = null
	_conversation = ""


func _exit_tree() -> void:
	_restore()
