extends Node3D

const RETARGET := preload("res://scripts/player/animation_retarget.gd")

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
	# Bones are collapsed BEFORE fitting. `_fit` measures what the model is, and
	# until the props are gone the sword tip is the tallest thing on the knight
	# and the shield is the widest — so fitting first scales the SWORD to 1.8m
	# and centres the capsule between the man and the shield he is not holding.
	_hide_bones()
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


## Collapse bones that carry props the game must not show.
##
## The knight ships a sword and a shield welded into the same skinned mesh as
## his body, riding bones that no clip in the library touches: `DEF-shield`
## sits almost a metre to the side of the spine and the sword hangs off an
## unparented three-bone chain. So they float beside him, in bind pose, forever
## — visible in the very first preview frame.
##
## They cannot be hidden as surfaces: the mesh's two surfaces split by TEXTURE,
## not by object, and surface 1 holds the props and both legs. So the bones are
## collapsed instead, which removes exactly the vertices skinned to them.
##
## And they should go regardless of where they sat. The trainer cannot fight —
## that is a hard rule, not a milestone — so a trainer holding a sword is
## promising the wrong game before anything else in the frame is read.
func _hide_bones() -> void:
	var names: Array = _load_config().get("hide_bones", [])
	if names.is_empty():
		return
	var skeleton := _skeleton(self)
	if skeleton == null:
		return
	for entry: Variant in names:
		var index := skeleton.find_bone(str(entry))
		if index < 0:
			push_warning("trainer hide_bones: no bone '%s'" % entry)
			continue
		# Scaled to nothing AND pulled onto its parent, so what is left is a
		# sub-pixel speck inside the body rather than a sub-pixel speck floating
		# where the prop used to be.
		skeleton.set_bone_pose_position(index, Vector3.ZERO)
		skeleton.set_bone_pose_scale(index, Vector3.ONE * 0.0001)


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
	var cfg := _load_config()
	var paths: Array = cfg.get("animation_libraries", [])
	var bone_map: Dictionary = cfg.get("retarget_bones", {})
	var target := _skeleton(self)
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
			# Straight merge when the two rigs share bone names, RETARGET when
			# they do not. The Styloo characters are 216-bone Rigify skeletons
			# with no name in common with the 23-bone rig the clips are authored
			# on, so a plain merge adds twenty-five clips that all play the bind
			# pose — twenty-five clips that exist, run, and do nothing.
			var retargeted: Dictionary = {}
			if not bone_map.is_empty() and target != null:
				var source_skeleton := _skeleton(source)
				for problem in RETARGET.unmapped(source_skeleton, target, bone_map):
					push_warning("trainer retarget: %s" % problem)
				var clips: Dictionary = {}
				for clip in player.get_animation_list():
					clips[clip] = player.get_animation(clip)
				retargeted = RETARGET.retarget(
					clips,
					source_skeleton,
					target,
					bone_map,
					# Bone tracks are addressed as `node_path:bone`, and the node
					# path is relative to the AnimationPlayer's root — which is the
					# character, not the skeleton.
					_anim.get_node(_anim.root_node).get_path_to(target),
					_height_ratio(source_skeleton, target),
					# The bones whose two rest poses are different POSES rather
					# than different conventions — the arms, because KayKit rests
					# in a T-pose and the knight in an A-pose. Data, because it is
					# a fact about these two art packs.
					PackedStringArray(cfg.get("retarget_align_rest", []))
				)

			for clip in player.get_animation_list():
				if _anim.has_animation(clip):
					continue
				var animation: Animation = retargeted.get(clip, null) if not retargeted.is_empty() \
					else player.get_animation(clip)
				if animation != null:
					_library().add_animation(clip, animation.duplicate())
					added += 1
		source.queue_free()
	print("[trainer] merged %d animation clips%s" % [
		added, " (retargeted)" if not bone_map.is_empty() else ""
	])
	if added == 0:
		push_error("the trainer has no animation clips; it will stand in its bind pose in every frame")


## The AnimationPlayer drives bones through the Skeleton3D, so a retarget needs
## the target skeleton to read rest poses from.
func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _skeleton(child)
		if found != null:
			return found
	return null


## Scale the root's travel so a walk cycle authored for one body covers the
## right ground on another. Rotation needs no such correction; distance does.
func _height_ratio(source: Skeleton3D, target: Skeleton3D) -> float:
	if source == null or target == null:
		return 1.0
	var a := _reach(source)
	var b := _reach(target)
	return 1.0 if a <= 0.001 else clampf(b / a, 0.25, 4.0)


func _reach(skeleton: Skeleton3D) -> float:
	var lowest := INF
	var highest := -INF
	for i in skeleton.get_bone_count():
		var y: float = skeleton.get_bone_global_rest(i).origin.y
		lowest = minf(lowest, y)
		highest = maxf(highest, y)
	return 0.0 if lowest == INF else highest - lowest


func _library() -> AnimationLibrary:
	# Godot 4 keeps clips in named libraries; the imported character has an empty
	# default one, or none at all if it shipped with no clips.
	if not _anim.has_animation_library(""):
		_anim.add_animation_library("", AnimationLibrary.new())
	return _anim.get_animation_library("")


## Same measure-and-fit as pal_body: the model is scaled to the collider, never
## the other way round. A trainer whose art is a head taller than the capsule
## the camera frames on is a trainer who floats.
func _fit() -> void:
	# Same measurement as pal_body._bounds, and for the same reason: a skinned
	# mesh's resource AABB and its local transform say nothing about how big it
	# renders.
	var hidden := _hidden_bones()
	var box := AABB()
	var started := false
	var to_local := _art.global_transform.affine_inverse()
	for mesh in _mesh_instances(_art):
		var local: AABB = (to_local * mesh.global_transform) * _bounds(mesh, hidden)
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


## One mesh's bounds, ignoring the vertices that `hide_bones` collapsed.
##
## `MeshInstance3D.get_aabb()` returns the mesh RESOURCE's bind-pose box, which
## no bone pose can change — so collapsing the sword before fitting does not, on
## its own, stop the sword being measured. And on this model it is measured
## twice over: the sword tip at y 2.069 is taller than the head at 2.01, and the
## shield at x -1.14 against the body's -0.60 drags the centre 6.5cm sideways,
## which puts the whole trainer off-centre in his own capsule.
##
## So the vertices are read directly and each one is attributed to the bone that
## moves it most. Only its heaviest influence is consulted: a vertex on the
## sword's grip is partly weighted to the hand, and a rule that dropped anything
## touched by a hidden bone would take fingers with it.
func _bounds(mesh: MeshInstance3D, hidden: PackedInt32Array) -> AABB:
	if mesh.mesh == null:
		return AABB()
	if hidden.is_empty() or mesh.skin == null:
		return mesh.get_aabb()

	# Vertex bone indices address the SKIN's bind list, not the skeleton's bones.
	# For most glTF imports those orders agree, which is exactly why assuming it
	# is dangerous: it works until one model where they do not.
	var hidden_binds := {}
	for bind in mesh.skin.get_bind_count():
		if hidden.has(mesh.skin.get_bind_bone(bind)):
			hidden_binds[bind] = true
	if hidden_binds.is_empty():
		return mesh.get_aabb()

	var box := AABB()
	var started := false
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if points.is_empty():
			continue
		# Four or eight influences per vertex, depending on how the mesh was
		# authored. Derived rather than assumed.
		var per: int = bones.size() / points.size() if points.size() > 0 else 0
		for v in points.size():
			if per > 0:
				var best := 0
				var best_weight := -1.0
				for i in per:
					if weights[v * per + i] > best_weight:
						best_weight = weights[v * per + i]
						best = bones[v * per + i]
				if hidden_binds.has(best):
					continue
			if started:
				box = box.expand(points[v])
			else:
				box = AABB(points[v], Vector3.ZERO)
				started = true
	return box if started else mesh.get_aabb()


## Skeleton indices of the bones `hide_bones` collapses, plus their descendants
## — a child of a collapsed bone is collapsed with it, and its vertices must be
## excluded from the measurement for the same reason its parent's are.
func _hidden_bones() -> PackedInt32Array:
	var names: Array = _load_config().get("hide_bones", [])
	var out := PackedInt32Array()
	var skeleton := _skeleton(self)
	if names.is_empty() or skeleton == null:
		return out
	for entry: Variant in names:
		var index := skeleton.find_bone(str(entry))
		if index >= 0:
			out.append(index)
	for i in skeleton.get_bone_count():
		var walk := skeleton.get_bone_parent(i)
		while walk != -1:
			if out.has(walk):
				out.append(i)
				break
			walk = skeleton.get_bone_parent(walk)
	return out


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
