extends SceneTree

## Does the art that is supposed to be in the game actually load, at the size
## the game thinks it is?
##
##   godot --headless --path . --script tests/smoke_art.gd
##
## Art has no unit tests; whether it is any good is a human's call from rendered
## frames. But whether it LOADED, whether it is the size its collider claims,
## and whether it silently fell back to a capsule are all mechanical, and all
## invisible in a passing combat test — a fight works perfectly against an
## invisible opponent.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

const SETTLE_FRAMES := 300
## How far a rendered model may sit under the collider that represents it.
##
## Was 0.35m, which is wide enough to hide a real bug and did. `pal_body._fit()`
## clamps a model's scale by its footprint, and a long quadruped tripped that
## clamp and rendered visibly shorter than its declared height while a compact
## creature beside it got its full size — so the largest creature in the game
## read as the smallest. The owner spotted it in a screenshot; this test did not,
## because a third of a metre of slack covered it.
##
## 0.08m is tight enough that any silent rescale fails here. A creature that
## genuinely cannot meet its height needs `footprint_allowance` raising in data,
## which is a decision somebody makes rather than a clamp applying quietly.
const HEIGHT_TOLERANCE := 0.08

## ...but only DOWNWARDS. Above the collider, a creature gets much more room.
##
## `_fit()` scales a model by its REST bounds, and this test measures it after
## three hundred frames of its idle clip — by which point an ear, a tail or a
## raised paw is legitimately above where the rest pose put it. A wolf measured
## 1.57m against a 1.45m collider for exactly that reason, and it was correct.
##
## The failure this test exists to catch is the opposite sign: the footprint
## clamp quietly scaling a creature DOWN so the art no longer fills the collider
## that gameplay reaches with. Being asymmetric keeps that catch at 8cm while
## letting an animation breathe.
const HEIGHT_OVERSHOOT := 0.30

var _failures: Array[String] = []
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_every_species_has_art()
	_the_creatures_in_the_world_loaded_their_models()
	_the_trainer_has_a_model_and_animations()
	_the_meadow_was_dressed()
	_report()


## Species data must name a model, and the model must exist. A typo here shows
## up as a capsule in a screenshot and nowhere else.
func _every_species_has_art() -> void:
	for id: String in SPECIES.table().keys():
		var look: Dictionary = SPECIES.placeholder(id)
		var path := str(look.get("model", ""))
		if path == "":
			_fail("species '%s' names no model" % id)
			continue
		if not ResourceLoader.exists(path):
			_fail("species '%s' names a model that does not exist: %s" % [id, path])


## The creatures actually standing in the world, checked as they are rendered
## rather than as they are configured.
func _the_creatures_in_the_world_loaded_their_models() -> void:
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("no encounter director; no creatures to check")
		return

	var bodies: Array[Node3D] = []
	for wild in (director.call("wild_pals") as Array):
		bodies.append(wild as Node3D)
	var ally: Node3D = director.call("ally_body") as Node3D
	if ally != null:
		bodies.append(ally)
	if bodies.is_empty():
		_fail("no creature bodies were spawned at all")
		return

	for body in bodies:
		var id := str(body.get("species_id"))
		if not bool(body.call("has_model")):
			_fail("'%s' fell back to the placeholder capsule; its model did not load" % id)
			continue

		# Fitted, not assumed. The three shipped models arrived at 263, 94 and
		# 3.8 units tall with two of the three centred on their origin rather
		# than standing on it, so "it loaded" and "it is the right size" are
		# genuinely separate questions.
		var wanted := float(body.call("body_height"))
		var actual := _rendered_height(body.call("model_pivot") as Node3D)
		if actual <= 0.0:
			_fail("'%s' has a model with no measurable size" % id)
		elif actual < wanted - HEIGHT_TOLERANCE:
			_fail("'%s' renders only %.2fm tall against a %.2fm collider. " % [id, actual, wanted] +
				"Something scaled it DOWN — check the footprint clamp in pal_body._fit().")
		elif actual > wanted + HEIGHT_OVERSHOOT:
			_fail("'%s' renders %.2fm tall against a %.2fm collider; that is more than an " % [
				id, actual, wanted
			] + "animation should add, so the model is not fitted to its gameplay size.")
		else:
			print("  %-16s model %.2fm, collider %.2fm" % [id, actual, wanted])
		_the_creature_has_the_clips_it_claims(body, id)


## Every clip a species names must exist on its model, under that exact name.
##
## Clip names are per-pack — the shipped creatures use `Armature|Frog_Attack`
## and `Armature|Triceratops_Run` — so a rename in data or a swapped model
## silently produces a creature that never animates. Nothing that reads game
## state can see that: the fight resolves perfectly against a creature frozen
## mid-pose.
func _the_creature_has_the_clips_it_claims(body: Node3D, id: String) -> void:
	var clips: Dictionary = SPECIES.placeholder(id).get("animations", {})
	if clips.is_empty():
		_fail("'%s' declares no animations; it will stand rigid through every fight" % id)
		return

	var anim := _find_animation_player(body)
	if anim == null:
		_fail("'%s' has no AnimationPlayer despite declaring %d clips" % [id, clips.size()])
		return

	for role: String in clips.keys():
		var clip := str(clips[role])
		if not anim.has_animation(clip):
			_fail("'%s' names a '%s' clip called '%s', which its model does not have" % [id, role, clip])

	# The four combat actually drives. A creature with no attack clip swings
	# invisibly, which reads as the hit not happening.
	for required in ["idle", "attack", "faint"]:
		if not clips.has(required):
			_fail("'%s' has no '%s' clip; combat drives that one" % [id, required])


func _the_trainer_has_a_model_and_animations() -> void:
	var model: Node3D = _world.get_node_or_null(^"Player/Model") as Node3D
	if model == null:
		_fail("the player has no Model node")
		return

	var anim := _find_animation_player(model)
	if anim == null:
		_fail("the trainer has no AnimationPlayer; it will stand rigid in every frame")
		return

	# Every clip the config asks for has to exist under the name it asks for.
	# A mistyped clip name is a trainer frozen in a T-pose, which no test that
	# reads state can see.
	var cfg: Dictionary = _art_config().get("trainer", {}).get("clips", {})
	for role: String in cfg.keys():
		var clip := str(cfg[role])
		if not anim.has_animation(clip):
			_fail("the trainer's '%s' clip is named '%s', which the model does not have" % [role, clip])
	print("  trainer: %d clips available" % anim.get_animation_list().size())


func _the_meadow_was_dressed() -> void:
	var vegetation: Node = _world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		_fail("no vegetation node; the meadow is bare")
		return
	var stats: Dictionary = vegetation.call("stats")
	var instances := int(stats.get("instances", 0))
	var batches := int(stats.get("batches", 0))
	print("  vegetation: %d props in %d batches" % [instances, batches])

	if instances <= 0:
		_fail("the scatter placed nothing; the meadow is bare")
		return
	# Instancing is not an optimisation here, it is the only way this layer can
	# exist on a handheld. One draw call per prop would be thousands.
	if batches > 0 and instances / batches < 20:
		_fail("%d props across %d batches; the scatter is not actually instancing" % [instances, batches])

	# Every layer in the config has to be present in the world. A layer that
	# silently placed nothing looks exactly like a layer nobody wrote.
	var drawn := {}
	for child in vegetation.get_children():
		drawn[child.name] = true
	for layer: String in RULES.config().get("layers", {}).keys():
		if layer.begins_with("_"):
			continue
		var models: Array = RULES.config()["layers"][layer].get("models", [])
		var any := false
		for entry: Variant in models:
			if drawn.has(str(entry).get_file().get_basename()):
				any = true
				break
		if not any:
			_fail("layer '%s' has no props in the world" % layer)


func _rendered_height(node: Node3D) -> float:
	if node == null:
		return 0.0
	var box := AABB()
	var started := false
	for mesh in _mesh_instances(node):
		var world_box: AABB = (node.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()
		if started:
			box = box.merge(world_box)
		else:
			box = world_box
			started = true
	return 0.0 if not started else box.size.y


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and node.visible:
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


func _art_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/art.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("art: OK — models loaded, sized to their colliders, and the meadow is dressed.")
		quit(0)
		return
	for line in _failures:
		print("art FAIL: %s" % line)
	quit(1)
