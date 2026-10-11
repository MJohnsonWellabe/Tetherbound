extends Node

## The marshal opens the bracket, but each opponent speaks their own lines.
## Stage a collider-free copy of their configured visual for this local shot.
## The actual NPC's collider, prompt, AI and transform remain at home on every
## peer; only its art is hidden until the conversation closes. No staging state
## is saved, and leaving the realm restores any surviving original visual.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

var _world: Node = null
var _conversations: Dictionary = {}
var _body: Node3D = null
var _original_art: Node3D = null
var _original_visible := true
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
	if actor == null or not actor.has_method("config"):
		return
	var original_art := actor.get("_art") as Node3D
	if not is_instance_valid(original_art):
		return
	var at: Array = spec.get("position", [])
	if at.size() < 2:
		return
	var z := float(at[2]) if at.size() >= 3 else float(at[1])
	var stand := Vector2(float(at[0]), z)
	var player: Node3D = actor.get("_player") as Node3D
	if is_instance_valid(player):
		var player_at := Vector2(player.global_position.x, player.global_position.z)
		# The human can move around the ring during a fight. Their opponent
		# approaches for the last line rather than speaking outside camera range.
		if player_at.distance_to(stand) > 6.0:
			stand = player_at + player_at.direction_to(stand) * 3.5
	var ground := float(_world.call("ground_height_at", stand.x, stand.y))
	if not is_finite(ground):
		return
	var proxy: Node3D = CHARACTER_MODEL.new()
	proxy.name = "TournamentSpeaker"
	proxy.visible = false
	add_child(proxy)
	# character_model has no NPC collider, interaction provider or AI. Reuse
	# the resolved appearance (including the actor's hair/palette/accessories).
	if not bool(proxy.call("build_from_config", actor.call("config"))):
		proxy.queue_free()
		return
	_copy_idle(actor, proxy)
	proxy.global_position = Vector3(stand.x, ground, stand.y)
	proxy.global_rotation.y = deg_to_rad(float(spec.get("facing_deg", 180.0)))
	_body = proxy
	_original_art = original_art
	_original_visible = original_art.visible
	original_art.visible = false
	proxy.visible = true
	_conversation = id
	if is_instance_valid(player):
		var toward := player.global_position - proxy.global_position
		if Vector2(toward.x, toward.z).length_squared() > 0.01:
			proxy.global_rotation.y = atan2(toward.x, toward.z)
	# line_presented is synchronous with opening, after the panel's generic
	# provider-based push-in. Replace Halda's shot before any frame is drawn.
	var camera := get_tree().get_first_node_in_group("conversation_camera")
	if camera != null:
		camera.call("end")
		var aftermath := id == str(spec.get("defeated", "")) or id == str(spec.get("victory_conversation", ""))
		camera.call("begin", proxy, "aftermath" if aftermath else "")


func _copy_idle(actor: Node3D, proxy: Node3D) -> void:
	var source: AnimationPlayer = actor.call("animation_player") as AnimationPlayer
	var target: AnimationPlayer = proxy.call("animation_player") as AnimationPlayer
	var idle := str(actor.call("clip_for", "idle"))
	if source != null and target != null and source.has_animation(idle):
		# The same installed asset has the same animation root/track paths.
		# Copy the resolved role idle too, including P2-050's private variant.
		var library := AnimationLibrary.new()
		library.add_animation("idle", source.get_animation(idle).duplicate(true) as Animation)
		target.add_animation_library("tournament", library)
		proxy.call("play", "tournament/idle")
		target.advance(0.0)
	else:
		proxy.call("play", str(proxy.call("clip_for", "idle")))


func _on_finished(_id: String) -> void:
	_restore()


func _restore() -> void:
	if is_instance_valid(_body):
		_body.visible = false
		_body.queue_free()
	if is_instance_valid(_original_art):
		_original_art.visible = _original_visible
	_body = null
	_original_art = null
	_conversation = ""


func _exit_tree() -> void:
	_restore()
