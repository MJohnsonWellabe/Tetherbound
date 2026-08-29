extends SceneTree

## T1-CREATURE-ART. Photograph the four Aspect variants (Nightburrow,
## Stormtrail, Riftfrill, Ashtusk) against a small purpose-built stage rather
## than the full `meadows_playground.tscn` -- the same choice
## `tools/_capture_creature_roster.gd` already made and measured at "well
## under a minute" for a comparable rig+creature scene, instead of the
## 12-25 minute full-world cycle. Each variant gets its own lighting MOOD
## approximating its intended habitat (night cave mouth, open storm country,
## a dusk pond, warm volcanic stone) rather than the real terrain geometry --
## acceptable for judging colour/material/VFX/scale, which is what this pass
## is for; a full-world placement check (the real Burrow Warrens at night,
## in particular, for Nightburrow's own "confirm it does not become a
## silhouette" requirement) is named as follow-up work in this lane's
## handover, not attempted here.
##
## No species.json entry exists for any of these four yet (T3-CREATURES'
## lane owns that data and has not landed it) -- so this tool builds each
## body directly off its SOURCE species (Burrowback/Trailpup/Paddlenewt/
## Tuskroot) and calls `set_aspect_variant()` programmatically, exactly the
## call a future species.json-driven path would make through
## `creature_body._build_placeholder()`'s own `aspect_variant`/
## `aspect_source_species` placeholder fields. See this lane's handover for
## the exact data contract.
##
## xvfb invocation (ralph/conventions.md's own, copied verbatim):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_aspect_variants.gd
##
## NEVER --headless alongside a real rendering driver -- hangs forever with
## no error (ralph/conventions.md's own "single most expensive trap").

const BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const NPC_BODY := preload("res://scripts/npc/npc_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUT_DIR := "res://ralph/reports/T1-CREATURE-ART/shots"

const TRAINER_HEIGHT := 1.8

## One stand per variant: source species, gameplay body_scale (the board's
## own "15-25% larger" / "10-15% larger" asks, and 1.0 -- no size change
## claimed -- for the two that are recolor variants rather than Alphas),
## and a lighting mood approximating the board's own named habitat.
const STANDS := [
	{
		"variant": "nightburrow", "source": "burrowback", "scale": 1.20,
		"mood": "night_cave", "trainer_x": -2.3,
	},
	{
		"variant": "stormtrail", "source": "trailpup", "scale": 1.12,
		"mood": "storm_country", "trainer_x": -2.0,
	},
	{
		"variant": "riftfrill", "source": "paddlenewt", "scale": 1.0,
		"mood": "dusk_pond", "trainer_x": -1.8,
	},
	{
		"variant": "ashtusk", "source": "tuskroot", "scale": 1.0,
		"mood": "warm_stone", "trainer_x": -2.6,
	},
]

const CAM_POS := Vector3(-1.15, 1.55, 6.4)
const CAM_LOOK := Vector3(-1.15, 1.3, 0.0)
const FOV := 42.0

## A tight head/shoulders framing for each variant, no trainer -- this is
## where a small emissive crack or an eye reads or does not.
const CLOSE_CAM_POS := Vector3(0.0, 1.5, 2.4)
const CLOSE_CAM_LOOK := Vector3(0.0, 1.2, 0.0)
const CLOSE_FOV := 32.0

const BOOT_FRAMES := 10
const SETTLE_FRAMES := 10
## VFX motes cycle on periods up to a few seconds (Riftfrill's orbit is 9s) --
## long enough settle that the wide shot does not always land on the exact
## same dead frame of every effect's cycle.
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
	print("[aspect-vfx] stage up, boot settled; starting the pass")

	for stand in STANDS:
		await _shoot_stand(stand)

	print("")
	print("Aspect variant frames written to %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("colour and relative scale are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


## One shared stage, RE-LIT per stand rather than rebuilt -- a moved light
## and a swapped floor colour are cheap; tearing down and rebuilding the
## WorldEnvironment/light nodes every stand is not, and buys nothing.
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


## Moods approximate each board's own named habitat/time without loading the
## real terrain -- see this file's header for why that is an accepted
## substitution for THIS pass. Ambient/key numbers start from
## `_capture_creature_roster.gd`'s own CALIBRATED neutral stage (floor
## renders at its own albedo there) and are pushed warmer/cooler/darker per
## mood; they are NOT re-measured against that calibration here, since mood
## lighting is deliberately not neutral -- flagged in the handover as
## judged-by-eye, not photometrically calibrated.
func _apply_mood(mood: String) -> void:
	match mood:
		"night_cave":
			# T1-CREATURE-ART finding: the first pass here (ambient 0.55 at
			# colour ~0.11, key 0.12) rendered UNJUDGEABLE -- the trainer, the
			# ruler this whole survey depends on, was barely a silhouette, and
			# Nightburrow's own charcoal body (the darkest creature in the
			# roster, per this lane's brief) nearly vanished into the
			# background between its glowing cracks. A cave mouth at night
			# still has real fill light in this game (moonlight, or the
			# Warrens' own authored lights per burrow_warrens.json) -- a
			# stage this dark is a lighting-rig defect, not a faithful "night"
			# read, and §15's own rule is explicit: do not make the subject
			# harder to see in the name of atmosphere.
			_env.background_color = Color(0.06, 0.065, 0.09)
			_env.ambient_light_color = Color(0.30, 0.32, 0.42)
			_env.ambient_light_energy = 0.85
			_key.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(-35.0), 0.0)
			_key.light_energy = 0.35
			_key.light_color = Color(0.65, 0.68, 0.85)
			_rim.light_energy = 0.55
			_rim.light_color = Color(0.55, 0.4, 0.85)
			_floor_mat.albedo_color = Color(0.09, 0.09, 0.11)
		"storm_country":
			_env.background_color = Color(0.30, 0.33, 0.38)
			_env.ambient_light_color = Color(0.7, 0.74, 0.8)
			_env.ambient_light_energy = 0.45
			_key.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-40.0), 0.0)
			_key.light_energy = 0.6
			_key.light_color = Color(0.85, 0.88, 0.95)
			_rim.light_energy = 0.5
			_rim.light_color = Color(0.7, 0.8, 1.0)
			_floor_mat.albedo_color = Color(0.28, 0.30, 0.26)
		"dusk_pond":
			_env.background_color = Color(0.12, 0.10, 0.20)
			_env.ambient_light_color = Color(0.35, 0.32, 0.5)
			_env.ambient_light_energy = 0.5
			_key.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(-50.0), 0.0)
			_key.light_energy = 0.3
			_key.light_color = Color(0.6, 0.55, 0.85)
			_rim.light_energy = 0.4
			_rim.light_color = Color(0.5, 0.6, 0.9)
			_floor_mat.albedo_color = Color(0.10, 0.14, 0.16)
		"warm_stone":
			_env.background_color = Color(0.22, 0.14, 0.09)
			_env.ambient_light_color = Color(0.55, 0.4, 0.3)
			_env.ambient_light_energy = 0.5
			_key.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-30.0), 0.0)
			_key.light_energy = 0.55
			_key.light_color = Color(1.0, 0.75, 0.5)
			_rim.light_energy = 0.4
			_rim.light_color = Color(1.0, 0.5, 0.25)
			_floor_mat.albedo_color = Color(0.24, 0.15, 0.1)
		_:
			_env.background_color = Color(0.20, 0.22, 0.24)
			_env.ambient_light_color = Color(0.75, 0.78, 0.82)
			_env.ambient_light_energy = 0.35
			_key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-35.0), 0.0)
			_key.light_energy = 0.55
			_rim.light_energy = 0.5
			_floor_mat.albedo_color = Color(0.30, 0.33, 0.30)


func _shoot_stand(stand: Dictionary) -> void:
	var variant: String = stand["variant"]
	_apply_mood(str(stand["mood"]))

	var body := _spawn(stand)
	_trainer.visible = true
	_trainer.global_position = Vector3(float(stand["trainer_x"]), 0.0, 0.0)
	_camera.fov = FOV
	_camera.global_position = CAM_POS
	_camera.look_at(CAM_LOOK, Vector3.UP)

	for i in VFX_SETTLE_FRAMES:
		await physics_frame

	var wide_path := "%s/%s-wide.png" % [OUT_DIR, variant]
	if await _capture(wide_path):
		_report(variant, body)

	# Close-up, no trainer -- where the emissive cracks and eye-glow actually
	# resolve, and Nightburrow's own "confirm it does not become a
	# silhouette against dark" check. Back to yaw 0 -- empirically (not by
	# any documented mesh-facing convention) that is what puts this camera's
	# framing on the BACK, which is where the crack pattern and dorsal VFX
	# actually live.
	body.rotation.y = 0.0
	_seat_on_ground(body, Vector3.ZERO)
	_trainer.visible = false
	_camera.fov = CLOSE_FOV
	_camera.global_position = CLOSE_CAM_POS
	_camera.look_at(CLOSE_CAM_LOOK, Vector3.UP)
	for i in SETTLE_FRAMES:
		await physics_frame
	await _capture("%s/%s-close.png" % [OUT_DIR, variant])

	body.queue_free()


## A 3/4 turn rather than face-on: the flame/arcs/motes/embers ring is a
## world-space effect around the WHOLE body, and Nightburrow's own reference
## board frames its hero shot the same way for the same reason -- a straight
## front view puts half the ring (everything near the "back" angle) directly
## behind the animal's own opaque mesh from the camera's point of view, which
## a render-and-check pass here caught directly: the isolated VFX probe
## (tools/_probe_aspect_vfx_isolated.gd) proved the billboard technique draws
## fine on its own, and only the face-on framing was hiding it.
const WIDE_YAW_DEG := 35.0


func _spawn(stand: Dictionary) -> Node3D:
	var source: String = stand["source"]
	var variant: String = stand["variant"]
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "Aspect_%s" % variant
	body.set_script(BODY)
	_world.add_child(body)
	# body_scale must be set before setup()/populate() builds the collider --
	# see creature_body.gd's own comment on the field. This is the board's
	# "15-25% / 10-15% larger" ask; Riftfrill/Ashtusk are recolor variants
	# with no claimed size change, hence 1.0 for those two stands.
	body.set("body_scale", float(stand["scale"]))
	body.call("setup", source, false)
	body.call("set_aspect_variant", variant, source)
	body.global_position = Vector3.ZERO
	body.rotation.y = deg_to_rad(WIDE_YAW_DEG)
	body.set_physics_process(false)
	_seat_on_ground(body, Vector3.ZERO)
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


func _report(name: String, body: Node3D) -> void:
	var measured := _measured_height(body)
	var has_model: bool = bool(body.call("has_model"))
	var tag := "" if has_model else "  WARN no model found, capsule fallback shot instead"
	print("  %-12s %5.2fm measured, trainer 1.80m, %.2fx%s" % [
		name, measured, measured / TRAINER_HEIGHT, tag])
