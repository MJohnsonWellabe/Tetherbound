extends SceneTree

## CAMP-SHELTER-0903, owner playtest 2026-09-03 item 7: one real frame of the
## enlarged tent with a real bedroll placed inside it and the trainer
## standing in the tent, for the mandatory blind visual pass. Same
## lightweight-stage pattern `capture_interior.gd` established (real
## `world_look.gd` lighting, a real player scene, no Terrain3D/village/
## vegetation boot) rather than `capture_creature_bed.gd`'s flat studio
## stage, because "does this read as a shelter a person sleeps in" needs the
## real trainer body in frame, not a bare prop. A hand-placed `Camera3D`
## stands in for the game's own third-person rig -- this is a still frame
## from a fixed vantage, not gameplay, so the rig's own follow/collision
## behaviour is not the thing under test.
##
## Places the tent and bedroll through their own production scripts
## (camp_tent.gd/player_bed.gd `build_real()`) at the tent's own local
## origin, bedroll dead centre in it -- not a hand-tuned "looks right"
## offset.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_camp_shelter_0903.gd

const WORLD_LOOK_SCRIPT := preload("res://scripts/world/world_look.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMP_TENT := preload("res://scripts/build/camp_tent.gd")
const PLAYER_BED := preload("res://scripts/build/player_bed.gd")

const OUT_DIR := "res://ralph/reports/CAMP-SHELTER-0903"
const SETTLE_FRAMES := 40
const SHOT_FRAMES := 20


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)
	await process_frame  # see capture_interior.gd's own comment on this line

	_build_ground(world)
	_build_lighting(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	world.add_child(player)

	var tent := CAMP_TENT.new()
	tent.name = "Tent"
	world.add_child(tent)
	tent.position = Vector3.ZERO
	tent.call("build_real")

	# Dead centre in the tent's own footprint -- `evaluate_placement`'s new
	# `_bedroll_has_tent` check accepts exactly this spot, and it is the
	# tightest-margin point the containment box allows on the tent's long
	# (Z) axis, so a render at this position is also evidence the fit is
	# real and not just true in the math.
	var bedroll := PLAYER_BED.new()
	bedroll.name = "Bedroll"
	world.add_child(bedroll)
	bedroll.position = Vector3.ZERO
	bedroll.call("build_real")

	for i in SETTLE_FRAMES:
		await process_frame

	# The tent's own front face is its only open one (measured: a diag 4-angle
	# turntable of the real placed mesh showed a modelled open doorway facing
	# local/world +Z at yaw 0, every other face closed canvas) -- so the shot
	# has to look in from the +Z side or there is nothing to see. Standing
	# just inside the doorway, on the bedroll's own near edge (the bedroll's
	# solid collider settles the trainer's feet on ITS top surface, exactly
	# where a real person stepping onto a groundsheet would stand) rather
	# than squeezed down the tent's narrow side -- three wider offsets were
	# tried first and every one put the trainer visibly outside the canvas,
	# because the mesh's real fabric footprint (an A-frame silhouette,
	# narrowest at the ground on the sides) is well inside the raw AABB
	# `INTERIOR_HALF_X`/`_Z` are measured from; only the doorway itself is
	# that wide at ground level.
	var camera := Camera3D.new()
	camera.name = "ShotCamera"
	camera.fov = 62.0
	camera.current = true
	world.add_child(camera)
	camera.global_position = Vector3(1.5, 1.65, 3.3)
	camera.look_at(Vector3(0.1, 1.0, -0.15), Vector3.UP)

	var stand_at := Vector3(0.0, 0.0, 0.6)
	player.global_position = stand_at
	player.velocity = Vector3.ZERO
	var forward := (Vector3(0.1, 0.0, -0.15) - stand_at)
	forward.y = 0.0
	player.rotation.y = atan2(-forward.x, -forward.z)

	for i in SHOT_FRAMES:
		await process_frame

	var image := root.get_texture().get_image()
	image.save_png("%s/_sheet_tent.png" % OUT_DIR)
	print("shot -> %s/_sheet_tent.png" % OUT_DIR)
	quit(0)


func _build_ground(world: Node3D) -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.32, 0.16)
	mesh.mesh = plane
	mesh.material_override = mat
	world.add_child(mesh)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	shape.shape = box
	shape.position.y = -0.1
	body.add_child(shape)
	world.add_child(body)


## Sun + sky + fog through `world_look.gd`, matching `capture_interior.gd`'s
## own pattern so this frame's lighting is the same code path the real
## playground uses, not a hand-tuned stand-in.
func _build_lighting(world: Node3D) -> void:
	var env_holder := WorldEnvironment.new()
	env_holder.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.fog_enabled = true
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	world.add_child(sun)

	var look := Node.new()
	look.name = "WorldLook"
	look.set_script(WORLD_LOOK_SCRIPT)
	look.set("sun_path", NodePath("../Sun"))
	look.set("environment_path", NodePath("../WorldEnvironment"))
	world.add_child(look)
