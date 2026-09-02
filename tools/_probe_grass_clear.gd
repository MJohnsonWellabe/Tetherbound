extends SceneTree

## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2. Isolates the new `grass_clear`
## group join (`creature_body.gd`) from everything else on this branch: same
## camera, same site, same creature, WITH vs WITHOUT group membership, so the
## clearing radius's own effect is visible on its own rather than mixed in
## with `field_degreen`'s colour change.
##
## The field's `built[]` uniform (what `grass_clear` feeds) is only
## recomputed when the ring's anchor cell changes (`grass_field.gd::
## _follow_camera`), which happens on camera movement -- a probe with a
## static camera stand never triggers it on its own, so this calls the
## field's own `_apply_built()` directly after each spawn to force the same
## refresh a walking player would get for free.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_clear.gd -- --species=bramblebun

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://ralph/reports/hud-catch/grass_clear_probe"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 40
const RANGE := 6.5
const EYE_HEIGHT := 1.78

var SPECIES_ID := "bramblebun"
var _world: Node = null
var _camera: Camera3D = null
var _field: Node = null
var _body: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			SPECIES_ID = arg.substr(10)

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	# Same stand `_probe_grass_separation.gd` uses -- open meadow, real field.
	var stand := Vector3(36.0, 0.0, -50.0)
	stand.y = _ground(stand)

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.global_position = stand + Vector3(0.0, EYE_HEIGHT, 0.0)
	var look_at := stand + Vector3(RANGE, 0.0, 0.0)
	look_at.y = _ground(look_at)
	_camera.look_at(look_at + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	_camera.fov = 52.0
	_camera.make_current()

	_field = _find_grass_field(_world)
	if _field == null:
		print("WARNING: no GrassField in the scene; these frames do not test the field")
	else:
		_field.call("bind", _field.get("_terrain"), _camera)
		for i in 30:
			await physics_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# WITHOUT: spawn, group membership left at its new default (off --
	# `set_grass_clear_active()` is opt-in now, driven by
	# `encounter_director.gd`'s own cluster-activation signal in the real
	# game, which this direct-spawn probe bypasses entirely).
	_body = _spawn(look_at)
	if _field != null:
		_field.call("_apply_built", _field.get("global_position"))
	for i in POSE_FRAMES:
		await physics_frame
	_save("without-clear")

	# WITH: same spot, same creature, explicitly toggled on -- what
	# `encounter_director.gd::_set_wild_active()` does for a wild creature
	# whose cluster the player has actually approached.
	if _body != null and is_instance_valid(_body):
		_body.queue_free()
		await process_frame
	_body = _spawn(look_at)
	if _body != null and _body.has_method("set_grass_clear_active"):
		_body.call("set_grass_clear_active", true)
	if _field != null:
		_field.call("_apply_built", _field.get("global_position"))
	for i in POSE_FRAMES:
		await physics_frame
	_save("with-clear")

	print("done")
	quit(0)


func _save(tag: String) -> void:
	var path := "%s/%s-%s.png" % [OUT, SPECIES_ID, tag]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("wrote %s" % path)


func _spawn(at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	if scene == null:
		return null
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "GrassClearProbe_%s" % SPECIES_ID
	_world.add_child(body)
	body.global_position = at
	body.call("populate", SPECIES_ID, null)
	body.global_position = at
	return body


func _find_grass_field(node: Node) -> Node:
	if node.get_script() != null \
			and String(node.get_script().resource_path).ends_with("grass_field.gd"):
		return node
	for child in node.get_children():
		var found := _find_grass_field(child)
		if found != null:
			return found
	return null


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
