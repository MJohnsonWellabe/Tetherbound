extends Node3D

## The trainer's body and its animation.
##
## Loads a rigged model, fits it to the capsule the controller actually walks
## with, and drives its clips from what the controller is doing. The trainer is
## on screen more than anything else in the game, so a white pill here costs
## more than a white pill anywhere else.
##
## Reads state rather than being told about it — the same arrangement as the
## combat HUD. A body that keeps its own idea of whether it is running can
## disagree with the character that is running.

const CONFIG_PATH := "res://data/config/art.json"

@export var player_path: NodePath

var _player: CharacterBody3D = null
var _art: Node3D = null
var _anim: AnimationPlayer = null
var _clips: Dictionary = {}
var _current: String = ""

var _height: float = 1.8
var _model_yaw: float = 0.0
## Set while the trainer is aiming a throw, so the body reads as throwing rather
## than as standing still watching its pal be hit.
var _throwing_for: float = 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	var cfg: Dictionary = _load_config()
	_height = float(cfg.get("height", _height))
	_model_yaw = float(cfg.get("model_yaw", 0.0))
	_clips = cfg.get("clips", {})
	if not _build(str(cfg.get("model", ""))):
		# The scene's capsule stays visible, so a missing trainer is a trainer
		# that looks wrong rather than a trainer who is not there.
		push_error("no trainer model; falling back to the placeholder capsule")
		return
	for child in get_children():
		if child != _art:
			(child as Node3D).visible = false


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("trainer", {})


func _build(path: String) -> bool:
	if path == "" or not ResourceLoader.exists(path):
		return false
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return false
	_art = packed.instantiate() as Node3D
	if _art == null:
		return false
	add_child(_art)
	_fit()
	_art.rotation.y = deg_to_rad(_model_yaw)
	_anim = _find_animation_player(_art)
	if _anim == null:
		push_warning("trainer model has no AnimationPlayer; it will not animate")
	return true


## Same measure-and-fit as pal_body: the model is scaled to the collider, never
## the other way round. A trainer whose art is a head taller than the capsule
## the camera frames on is a trainer who floats.
func _fit() -> void:
	var box := AABB()
	var started := false
	for mesh in _mesh_instances(_art):
		var local: AABB = mesh.transform * mesh.mesh.get_aabb()
		if started:
			box = box.merge(local)
		else:
			box = local
			started = true
	if not started or box.size.y <= 0.0001:
		return
	var fit := _height / box.size.y
	_art.scale = Vector3.ONE * fit
	_art.position = Vector3(
		-(box.position.x + box.size.x * 0.5) * fit,
		-box.position.y * fit,
		-(box.position.z + box.size.z * 0.5) * fit
	)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _process(delta: float) -> void:
	if _anim == null or _player == null:
		return
	_throwing_for = maxf(0.0, _throwing_for - delta)
	_play(_clip_for_state())


## What the trainer's body should be doing, from what the trainer is doing.
func _clip_for_state() -> String:
	if _throwing_for > 0.0:
		return str(_clips.get("throw", "pick-up"))
	if not _player.is_on_floor():
		return str(_clips.get("jump", "idle"))

	var speed: float = _player.call("ground_speed")
	if speed < 0.4:
		return str(_clips.get("idle", "idle"))
	if bool(_player.call("is_sprinting")):
		return str(_clips.get("sprint", "sprint"))
	return str(_clips.get("walk", "walk"))


func _play(clip: String) -> void:
	if clip == _current or not _anim.has_animation(clip):
		return
	_current = clip
	# Cross-faded rather than cut. A trainer who snaps between walk and idle
	# reads as broken even when the states are correct.
	_anim.play(clip, 0.18)


## Called when a throw is released, so the body commits to the animation for its
## duration rather than for exactly one frame.
func play_throw(seconds: float = 0.6) -> void:
	_throwing_for = seconds
