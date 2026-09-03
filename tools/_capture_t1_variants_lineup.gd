extends SceneTree

## T1-VARIANTS 2026-08-30. Evidence for the JUDGE-3 5a/5b fix: each Aspect
## variant (Nightburrow, Stormtrail, Riftfrill, Ashtusk) rendered BESIDE its
## own base species, same stage, same light, at a wide "lineup" distance and
## a close head/shoulders crop, under both a day and a night light rig.
## Answers the judge's own question directly -- with the base standing right
## next to it, "is this a distinct animal or a retint" is something the frame
## itself can be judged on, not just described.
##
## A small purpose-built stage, not the full terrain -- same choice and same
## reasoning tools/_capture_aspect_variants.gd already documents (a
## comparable rig+creature scene renders in well under a minute; the full
## world's own known capture defect, silently missing grass geometry, cannot
## happen on a stage that never loads terrain/scatter in the first place).
## This lane's scope is materials/textures/VFX only -- no terrain, no
## species.json -- so the base species is spawned in its ordinary (vivid)
## colourway directly off its own species id, same call the existing aspect
## capture tool already makes for the variant half.
##
## xvfb invocation (docs/AGENT_WORKFLOW.md's own, copied verbatim):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_variants_lineup.gd
##
## NEVER --headless alongside a real rendering driver -- hangs forever with
## no error.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const NPC_BODY := preload("res://scripts/npc/npc_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUT_DIR := "res://ralph/reports/T1-VARIANTS-2/shots"

const TRAINER_HEIGHT := 1.8

## One stand per variant: source species (the base half of the comparison)
## and the gameplay body_scale the board asks for (Nightburrow/Stormtrail are
## Alphas, 15-25%/10-15% larger; Riftfrill/Ashtusk claim no size change).
const STANDS := [
	{"variant": "nightburrow", "source": "burrowback", "scale": 1.20},
	{"variant": "stormtrail", "source": "trailpup", "scale": 1.12},
	{"variant": "riftfrill", "source": "paddlenewt", "scale": 1.0},
	{"variant": "ashtusk", "source": "tuskroot", "scale": 1.0},
]

## Lineup: base on the left, variant on the right, trainer alongside for
## scale. Close: same pair, tight on both heads, no trainer.
const GAP := 1.35
const CAM_POS := Vector3(0.0, 1.55, 6.6)
const CAM_LOOK := Vector3(0.0, 1.2, 0.0)
const FOV := 42.0

## T1-VARIANTS-2 2026-08-30 (JUDGE-4 Q2-D12): the original 2.7/34 pairing put
## either subject's snout past the frame edge whenever its forward-facing
## rotation carried it outward from its seat offset (GAP * 0.55 = 0.74m) --
## confirmed directly, both close crops for Stormtrail (the larger alpha
## scale) showed only ONE eye in frame, the other cropped off-canvas
## entirely. Camera pulled back and the seat offset tightened so both whole
## heads clear the edge with margin, at a small cost to how tightly either
## fills the frame.
const CLOSE_CAM_POS := Vector3(0.0, 1.4, 3.1)
const CLOSE_CAM_LOOK := Vector3(0.0, 1.12, 0.0)
const CLOSE_FOV := 36.0
const CLOSE_SEAT_FRACTION := 0.42

const BOOT_FRAMES := 10
const SETTLE_FRAMES := 10
## VFX motes cycle up to a few seconds (Riftfrill's orbit is 9s) -- long
## enough settle that a shot does not always land on the same dead frame.
const VFX_SETTLE_FRAMES := 40
const POSE_FRAMES := 2

var _world: Node3D = null
var _trainer: Node3D = null
var _camera: Camera3D = null
var _env: Environment = null
var _key: DirectionalLight3D = null
var _rim: DirectionalLight3D = null
var _floor_mat: StandardMaterial3D = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame

	_world = Node3D.new()
	root.add_child(_world)
	_build_stage()

	for i in BOOT_FRAMES:
		await physics_frame
	print("[t1-variants] stage up, boot settled; starting the lineup pass")

	for stand in STANDS:
		await _shoot_stand(stand)

	print("")
	print("Lineup frames written to %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("colour and relative scale are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


func _build_stage() -> void:
	var env_node := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = _env
	_world.add_child(env_node)

	_key = DirectionalLight3D.new()
	_key.shadow_enabled = true
	_world.add_child(_key)

	_rim = DirectionalLight3D.new()
	_rim.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(158.0), 0.0)
	_rim.shadow_enabled = false
	_world.add_child(_rim)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	_floor_mat = StandardMaterial3D.new()
	floor_mesh.material_override = _floor_mat
	_world.add_child(floor_mesh)

	_trainer = Node3D.new()
	_trainer.set_script(NPC_BODY)
	_world.add_child(_trainer)
	_trainer.call("setup", "trainer", null)

	_camera = Camera3D.new()
	_camera.fov = FOV
	_world.add_child(_camera)
	_camera.make_current()


## Neutral daylight and a real night rig -- not per-variant mood lighting
## (the existing aspect-vfx stage's own choice), because this pass exists to
## compare base vs. variant fairly under the SAME light, not to flatter each
## variant's own intended habitat.
func _apply_time(is_night: bool) -> void:
	if is_night:
		_env.background_color = Color(0.05, 0.055, 0.08)
		_env.ambient_light_color = Color(0.28, 0.3, 0.4)
		_env.ambient_light_energy = 0.55
		_key.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(-30.0), 0.0)
		_key.light_energy = 0.28
		_key.light_color = Color(0.6, 0.65, 0.9)
		_rim.light_energy = 0.35
		_rim.light_color = Color(0.5, 0.55, 0.85)
		_floor_mat.albedo_color = Color(0.08, 0.11, 0.08)
	else:
		_env.background_color = Color(0.55, 0.68, 0.78)
		_env.ambient_light_color = Color(0.75, 0.8, 0.85)
		_env.ambient_light_energy = 0.5
		_key.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-35.0), 0.0)
		_key.light_energy = 1.05
		_key.light_color = Color(1.0, 0.98, 0.92)
		_rim.light_energy = 0.4
		_rim.light_color = Color(0.85, 0.9, 1.0)
		_floor_mat.albedo_color = Color(0.22, 0.34, 0.16)


func _shoot_stand(stand: Dictionary) -> void:
	var variant: String = stand["variant"]
	var source: String = stand["source"]
	var scale: float = float(stand["scale"])

	for time_label in ["day", "night"]:
		_apply_time(time_label == "night")

		var base_body := _spawn(source, 1.0, false, "")
		var variant_body := _spawn(source, scale, false, variant)
		base_body.global_position = Vector3(-GAP, 0.0, 0.0)
		_seat_on_ground(base_body, Vector3(-GAP, 0.0, 0.0))
		variant_body.global_position = Vector3(GAP, 0.0, 0.0)
		_seat_on_ground(variant_body, Vector3(GAP, 0.0, 0.0))
		base_body.rotation.y = deg_to_rad(20.0)
		variant_body.rotation.y = deg_to_rad(-20.0)

		_trainer.visible = true
		_trainer.global_position = Vector3(GAP * 2.2, 0.0, 0.0)
		_camera.fov = FOV
		_camera.global_position = CAM_POS
		_camera.look_at(CAM_LOOK, Vector3.UP)

		for i in VFX_SETTLE_FRAMES:
			await physics_frame

		var wide_path := "%s/%s-vs-%s-%s-wide.png" % [OUT_DIR, variant, source, time_label]
		if await _capture(wide_path):
			_report(variant, variant_body, source, base_body)

		# Close crop: both heads, no trainer -- where the crack/marking work
		# and eye-glow actually resolve at gameplay-relevant scale.
		base_body.rotation.y = 0.0
		variant_body.rotation.y = 0.0
		_seat_on_ground(base_body, Vector3(-GAP * CLOSE_SEAT_FRACTION, 0.0, 0.0))
		_seat_on_ground(variant_body, Vector3(GAP * CLOSE_SEAT_FRACTION, 0.0, 0.0))
		_trainer.visible = false
		_camera.fov = CLOSE_FOV
		_camera.global_position = CLOSE_CAM_POS
		_camera.look_at(CLOSE_CAM_LOOK, Vector3.UP)
		for i in SETTLE_FRAMES:
			await physics_frame
		await _capture("%s/%s-vs-%s-%s-close.png" % [OUT_DIR, variant, source, time_label])

		base_body.queue_free()
		variant_body.queue_free()
		await process_frame


func _spawn(source: String, scale: float, is_shiny: bool, variant: String) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "T1Variants_%s_%s" % [source, variant if variant != "" else "base"]
	body.set_script(BODY)
	_world.add_child(body)
	# body_scale must be set before setup()/populate() builds the collider --
	# see creature_body.gd's own comment on the field.
	body.set("body_scale", scale)
	body.call("setup", source, is_shiny)
	if variant != "":
		body.call("set_aspect_variant", variant, source)
	body.set_physics_process(false)
	return body


func _seat_on_ground(body: Node3D, at: Vector3) -> void:
	var pivot: Node3D = body.get_node_or_null(^"Model") as Node3D
	if pivot == null:
		return
	var box: AABB = RENDER_BOUNDS.measure(pivot)
	if box.size == Vector3.ZERO:
		return
	var foot: float = box.position.y * pivot.global_transform.basis.get_scale().y
	body.global_position = Vector3(at.x, at.y - foot, at.z)


func _capture(path: String) -> bool:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % path.get_file())
		return false
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % path.get_file())
		return false
	return true


func _measured_height(body: Node3D) -> float:
	var pivot: Node3D = body.call("model_pivot") as Node3D
	if pivot != null:
		var box: AABB = RENDER_BOUNDS.measure(pivot)
		if box.size.y > 0.0001:
			return box.size.y
	return float(body.call("body_height"))


func _report(variant: String, variant_body: Node3D, source: String, base_body: Node3D) -> void:
	var v_h := _measured_height(variant_body)
	var b_h := _measured_height(base_body)
	print("  %-12s %5.2fm  vs  %-12s %5.2fm  (trainer 1.80m)" % [variant, v_h, source, b_h])
