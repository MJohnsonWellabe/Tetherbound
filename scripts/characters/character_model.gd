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
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

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
	var tint := str(cfg.get("tint", ""))
	if tint != "":
		_apply_tint(Color(tint))
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


## Same measure-and-fit as pal_body: the model is scaled to the size the game
## already believes in, never the other way round. A character whose art is a
## head taller than the capsule the camera frames on is a character who floats.
##
## Measured in RENDER space (`render_bounds.gd`), which is the third and final
## form of this fix. The first version raced `global_transform`; 1ebd434
## replaced it with a local-transform chain — which is race-free and, for a
## SKINNED mesh, measures a chain the renderer does not use. The humans carry
## their real scale inside the skin (inverse binds ×100, Armature ×0.01), so
## the chain measurement read 0.018m, "corrected" by ×100, and the skeleton —
## which the renderer actually follows — was blown up to 180m. Every test
## measured the same chain and agreed the trainer was 1.80m while the owner's
## screen was full of his boots. render_bounds pushes the bind AABB through the
## SKELETON's chain and the collapsed skin transform instead, which is what the
## GPU does at rest pose, so a correctly-authored human measures ~1.8 and gets
## fit ≈ 1.0.
func _fit() -> void:
	var box: AABB = RENDER_BOUNDS.measure(_art)
	if box.size.y <= 0.0001:
		return
	var fit := _height / box.size.y
	# With render-space measurement the fit really is a small correction: the
	# humans measure ~1.8 and need ~×1.0, the creatures likewise. A fit near
	# ×100 means a measurement crossed an armature compensation again — the
	# exact bug this warning is a tripwire for.
	if fit > 10.0 or fit < 0.1:
		push_warning(("%s model measured %.5fm tall and needs a x%.2f correction " % [
			_config_key, box.size.y, fit
		]) + "to reach %.2fm. A rigged model should need ~x1; " % _height +
			"a factor like x100 means the measurement missed the skin's scale.")
	_art.scale = Vector3.ONE * fit
	_art.position = Vector3(
		-(box.position.x + box.size.x * 0.5) * fit,
		-box.position.y * fit,
		-(box.position.z + box.size.z * 0.5) * fit
	)


## A palette swap on an existing rig (R7.2's villagers) rather than a second
## Meshy generation: `docs/ASSET_LEDGER.md`'s only other free humanoid, KayKit's
## Ranger, is a ~2-heads-tall toon character next to the trainer/Grandpa/Warden's
## photoreal-ish proportions, and picking it would silently settle the open
## question in `ralph/BLOCKED.md` ("Creature and human art-pipeline cohesion")
## that CLAUDE.md says not to invent. This keeps the same mesh, skeleton and
## clips and only multiplies each surface's albedo, so a texture keeps its
## detail (cloth weave, skin shading) and only shifts hue/value — a StandardMaterial3D
## with just `albedo_color` set and no texture would flatten the model to a
## single flat colour, which is a worse look than the one being avoided.
func _apply_tint(colour: Color) -> void:
	if _art == null:
		return
	_tint_node(_art, colour)


func _tint_node(node: Node, colour: Color) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			var source: Material = instance.get_active_material(surface)
			var material: BaseMaterial3D = (source.duplicate() as BaseMaterial3D) \
				if source is BaseMaterial3D else StandardMaterial3D.new()
			material.albedo_color = material.albedo_color * colour
			instance.set_surface_override_material(surface, material)
	for child in node.get_children():
		_tint_node(child, colour)


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
##
## `looping` sets the underlying Animation resource's loop mode before playing
## it, the same way `pal_animator.gd`'s `_play()` already does for creatures.
## Every clip `animate_humanoid.py` bakes ships as LOOP_NONE — a bare export
## default, never set per-clip — so without this, a continuous state like
## "walk" (1.38s) plays its cycle once and freezes mid-stride for as long as
## the state holds, which reads as "the character has no animation" even
## though the clip exists, resolves, and the caller is asking for it every
## frame. Confirmed directly against the trainer's own .glb: idle, walk,
## sprint, jump and throw all measured `loop_mode == LOOP_NONE`.
func play(clip: String, looping: bool = true) -> void:
	if _anim == null or clip == _current or not _anim.has_animation(clip):
		return
	_current = clip
	var animation := _anim.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	_anim.play(clip, 0.18)
