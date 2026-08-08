extends Node3D

## A rigged human, loaded from a block in data/config/art.json and fitted to the
## height that block declares.
##
## Extracted from `scripts/player/trainer_model.gd`, which was the only thing in
## the project that could do this and is now one of two — Grandpa is the same
## rig, the same fitting problem, and the same five clip names. The trainer's
## own subclass keeps everything that is about the TRAINER (reading the
## controller's state to pick a clip, the throw animation) and nothing else.
##
## Nothing here reads gameplay state. A subclass decides what the body should be
## doing and calls `play()`; this decides how big it is and where its clips came
## from.

const CONFIG_PATH := "res://data/config/art.json"

var _art: Node3D = null
var _anim: AnimationPlayer = null
var _clips: Dictionary = {}
var _current: String = ""

var _height: float = 1.8
var _model_yaw: float = 0.0
var _config_key: String = ""


## Load the named block and stand the body up. False means nothing loaded and
## whatever placeholder the scene carries should stay visible.
func build(config_key: String) -> bool:
	_config_key = config_key
	var cfg := config()
	_height = float(cfg.get("height", _height))
	_model_yaw = float(cfg.get("model_yaw", 0.0))
	_clips = cfg.get("clips", {})
	if not _build_art(str(cfg.get("model", ""))):
		return false
	_hide_placeholders()
	return true


func config() -> Dictionary:
	return config_for(_config_key)


static func config_for(key: String) -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var entry: Variant = (parsed as Dictionary).get(key, {})
	return entry if entry is Dictionary else {}


func has_model() -> bool:
	return _art != null


func height() -> float:
	return _height


func clip_for(role: String, fallback: String = "idle") -> String:
	return str(_clips.get(role, fallback))


func animation_player() -> AnimationPlayer:
	return _anim


## Every sibling of the loaded art, hidden. The scenes keep a capsule as the
## fallback, so a missing asset is a character who looks wrong rather than a
## character who is not there — but once the real body is up, the capsule is
## just a capsule standing inside it.
func _hide_placeholders() -> void:
	for child in get_children():
		if child != _art and child is Node3D:
			(child as Node3D).visible = false


func _build_art(path: String) -> bool:
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
	var paths: Array = config().get("animation_libraries", [])
	if paths.is_empty():
		return
	var added := 0
	for entry: Variant in paths:
		var path := str(entry)
		if not ResourceLoader.exists(path):
			push_error("%s animation library missing: %s" % [_config_key, path])
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
	print("[%s] merged %d animation clips" % [_config_key, added])


func _library() -> AnimationLibrary:
	# Godot 4 keeps clips in named libraries; the imported character has an empty
	# default one, or none at all if it shipped with no clips.
	if not _anim.has_animation_library(""):
		_anim.add_animation_library("", AnimationLibrary.new())
	return _anim.get_animation_library("")


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


## Same measure-and-fit as pal_body: the model is scaled to the size the game
## already believes in, never the other way round. A character whose art is a
## head taller than the capsule the camera frames on is a character who floats.
func _fit() -> void:
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
		push_warning(("%s model measured %.5fm tall and needs a x%.1f correction " % [
			_config_key, box.size.y, fit
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


## Cross-faded rather than cut. A body that snaps between walk and idle reads as
## broken even when the states are correct.
func play(clip: String) -> void:
	if _anim == null or clip == _current or not _anim.has_animation(clip):
		return
	_current = clip
	_anim.play(clip, 0.18)
