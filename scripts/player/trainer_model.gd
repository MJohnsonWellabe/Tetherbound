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
		# KayKit's characters ship with no clips at all, so Godot creates no
		# AnimationPlayer for them. One is added here for the libraries to be
		# merged into; its root is the character, which is what the library
		# clips' track paths are relative to.
		_anim = AnimationPlayer.new()
		_anim.name = "AnimationPlayer"
		_art.add_child(_anim)
		_anim.root_node = _anim.get_path_to(_art)
	_merge_libraries()
	return true


## Pull clips from separate animation files onto this character.
##
## KayKit ships the mesh and the motion apart: the character .glb carries a
## 23-bone rig and zero clips, and the clips live in shared libraries built on
## that same rig. Godot will not connect them on its own, so the libraries are
## loaded and their animations copied across.
##
## They must share a skeleton for this to mean anything. If a library is built
## on a different rig the clips load and drive nothing, which looks exactly like
## a model with no animations — hence the count in the log.
func _merge_libraries() -> void:
	var paths: Array = _load_config().get("animation_libraries", [])
	var added := 0
	for entry: Variant in paths:
		var path := str(entry)
		if not ResourceLoader.exists(path):
			push_error("trainer animation library missing: %s" % path)
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var source: Node = packed.instantiate()
		var player := _find_animation_player(source)
		if player != null:
			for clip in player.get_animation_list():
				var animation: Animation = player.get_animation(clip)
				if animation != null and not _anim.has_animation(clip):
					_library().add_animation(clip, animation.duplicate())
					added += 1
		source.queue_free()
	print("[trainer] merged %d animation clips" % added)


func _library() -> AnimationLibrary:
	# Godot 4 keeps clips in named libraries; the imported character has an empty
	# default one, or none at all if it shipped with no clips.
	if not _anim.has_animation_library(""):
		_anim.add_animation_library("", AnimationLibrary.new())
	return _anim.get_animation_library("")


## Same measure-and-fit as pal_body: the model is scaled to the collider, never
## the other way round. A trainer whose art is a head taller than the capsule
## the camera frames on is a trainer who floats.
## The mesh's transform relative to `_art`, from LOCAL transforms only.
##
## This used to use `mesh.global_transform`, and that is a race. A global
## transform is only correct once the node is in the tree and the transform has
## propagated, and `_fit()` is called on the line after `add_child()`. Measured:
## the trainer's box came back 1.8000 immediately after `add_child` and 0.0180
## one frame later — a factor of exactly 100, because the rigged models carry an
## internal 0.01 scale node.
##
## Both readings then produce a plausible-looking scale factor and one of them
## is catastrophic: measure 0.018, compute a fit of 100, and the internal x100
## is applied on top, rendering a 180-metre trainer. That is the "he is enormous
## and all you can see are his shoes" the owner hit in the exported build, and
## it is invisible in a headless test that happens to win the race.
##
## Walking the parent chain uses only `transform`, which is valid the instant a
## node exists, so the answer cannot depend on when it is asked.
func _relative_transform(from: Node3D) -> Transform3D:
	var chain := Transform3D()
	var node: Node3D = from
	while node != null and node != _art:
		chain = node.transform * chain
		node = node.get_parent() as Node3D
	return chain


func _fit() -> void:
	# Same measurement as pal_body._bounds, and for the same reason: a skinned
	# mesh's resource AABB and its local transform say nothing about how big it
	# renders.
	var box := AABB()
	var started := false
	for mesh in _mesh_instances(_art):
		var local: AABB = _relative_transform(mesh) * mesh.get_aabb()
		if started:
			box = box.merge(local)
		else:
			box = local
			started = true
	if not started or box.size.y <= 0.0001:
		return
	var fit := _height / box.size.y
	# A large factor is NOT suspicious here: the rigged models are authored at
	# about 0.018 units with the compensating scale on the scene root, which
	# this measurement deliberately excludes and this line replaces. So x100 is
	# normal and correct. Only a wildly degenerate reading is worth a word.
	if fit > 1000.0 or fit < 0.001:
		push_warning(("trainer model measured %.5fm tall and needs a x%.1f correction " % [
			box.size.y, fit
		]) + "to reach %.2fm. That is almost certainly a bad measurement." % _height)
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
