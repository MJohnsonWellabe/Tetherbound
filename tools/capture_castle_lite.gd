extends SceneTree

## Lightweight OF4-rebuild verification capture: terrain + landmark ONLY,
## skipping the full playground's vegetation scatter (25946 instances),
## water, village, NPCs and props -- none of which affect the castle's own
## rendering. The full `tools/capture_wayfinding.gd` loads the entire
## `meadows_playground.tscn` scene and its ~30-100+ minute build cost under
## this container's software (xvfb + opengl3/llvmpipe) renderer, documented
## in `archive/ralph/DONE.md` precedent, exceeds any single foreground command's
## timeout here. This reuses the SAME terrain bake, the SAME ground
## materials, the SAME lighting/environment/fog settings as the real scene
## (copied from meadows_playground.tscn's own WorldEnvironment/Sun nodes),
## and the SAME landmark.gd/building_prefabs.gd code path -- it just never
## instantiates the vegetation/settlement/NPC layers, since `playground_world.
## gd`'s own `_ready()` cannot be run partially: it is invoked automatically
## the instant its node enters the SceneTree. `playground_world.gd`'s
## terrain-building methods are called directly on a detached instance of
## that script (never added to the tree, so its own `_ready()` never fires)
## and only the resulting Terrain3D node is reparented into a real,
## in-tree stage -- the same public/duck-typed methods
## (`_build_terrain`, `_apply_ground_materials`, `ground_height_at`) the
## real scene already relies on, just driven by hand instead of by `_ready`.
##
## `OF4-rebuild`'s blind-critique pass stopped after round 4 with an open
## remainder (the gate opening's jagged seam, see `archive/ralph/DONE.md`) rather
## than a clean convergence -- keep this around for whoever resumes that
## pass; delete it once the remainder is actually closed and nobody needs
## this verification path again. Not a permanent addition to tools/.
##
## STRONGHOLD-R2: READ THIS BEFORE PUTTING THESE FRAMES IN FRONT OF A CRITIC.
## Skipping the vegetation layer is the right call for judging the castle's own
## geometry and materials, and it makes the frames LIE about the ground: every
## frame this tool writes shows the stronghold standing in an unbroken mown
## lawn, because the ~130k scatter instances that would put grass, stones, verge
## fringe and path stones on that ground are exactly what it does not build. A
## blind critic reading these will rank "the field is empty" first and will be
## describing this tool rather than the world. `tools/capture_stronghold_
## approach.gd` is the same three viewpoints in the real scene, for that.

const WORLD_SCRIPT := preload("res://scripts/world/playground_world.gd")
const LANDMARK := preload("res://scripts/world/landmark.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const OUT_DIR := "res://shots/wayfinding"
const DATA_DIR := "res://data/terrain/playground"

const SETTLE_FRAMES := 150
const POSE_FRAMES := 4
const FOV := 70.0

## Same coordinates capture_wayfinding.gd uses -- the two viewpoints the
## castle is actually seen from now that OF13 moved it out of sight of the
## village square and Rise path.
const TOWER_AT := Vector2(229.8, -144.4)

const VIEWPOINTS := [
	{
		"name": "silhouette-close",
		"eye": Vector2(229.8, -214.4), "eye_h": 7.0,
		"target": TOWER_AT, "target_h": 14.0,
	},
	{
		"name": "silhouette-approach",
		"eye": Vector2(229.8, -170.4), "eye_h": 1.7,
		"target": TOWER_AT, "target_h": 11.0,
	},
	# OF4-gate-arch: a third, gate-height vantage. The two viewpoints above are
	# the wayfinding silhouette shots -- 70m and 26m out, both aimed high at
	# the skyline -- and at that range the gate itself is a few dozen pixels,
	# too small to judge as architecture. This one stands ~10m off the south
	# wall with the eye level with the arch's own centre (terrain -3.74 + 2.5 =
	# -1.24; the plinth top is -1.95 and the arch centre sits ~0.85m above it),
	# aimed straight down the gate's axis. Same scratch-tool caveat as the rest
	# of this file: delete with it.
	{
		"name": "gate-close",
		"eye": Vector2(229.8, -162.8), "eye_h": 2.5,
		"target": TOWER_AT, "target_h": 2.65,
	},
]


## STRONGHOLD-R2. Nothing human-sized stood anywhere in these three frames, so
## none of them could answer the question a landmark frame exists to answer:
## how big is it? The round-1 pass already named this as the reason a 36x40m
## fortress with a 29m keep reads as a toy, and answered it with a garrison
## camp — 1.8m tents against a 10m curtain. That is a good cue and it is not
## the same cue as a PERSON, and it is the person the critic can measure
## against without being told a number.
##
## So: the real trainer rig (`art.json`'s `trainer` block, fitted to its
## declared 1.80m by `character_model.gd` — the same build path the player's
## own body uses, not a stand-in capsule) and one real creature from the
## roster, built through `creature.tscn` + `creature_body.gd::setup` exactly
## the way `tools/preview_creatures.gd` and `encounter_director.gd` build one.
##
## They stand ON THE RAMP rather than on the grass. The grass in front of the
## ramp is behind two of the three cameras (`gate-close`'s eye is at local
## z -18.4, which is on the ramp itself), so an actor placed there is either
## out of frame or 2m from the lens. On the ramp all three viewpoints see them
## at a usable distance: ~5m for `gate-close`, ~13m for `silhouette-approach`,
## ~57m for `silhouette-close`.
##
## Local coordinates, landmark frame. The ramp runs x -1..+5 and z -10..-21,
## `_ramp_y` below is `stronghold_occupation.gd`'s own formula. The trainer
## sits at x -0.3 and the creature at x +3.2, either side of the walked width,
## so neither of them stands in front of the gate arch (local x +2) and hides
## the thing the frame is of.
const ACTORS_LOCAL_Z := -13.6
const TRAINER_LOCAL_X := -0.3
## 4.1 put the bramblebun's flank over the ramp's own left edge (the deck runs
## x -1..+5), and from `gate-close`'s low eye the edge cut it in half. 3.2
## stands it fully on the deck and still clears the gate axis at x +2.
const CREATURE_LOCAL_X := 3.2
## `spawns.json`'s Meadows starter. Any roster species answers the scale
## question; this one is the first creature the chapter actually gives you.
const CREATURE_SPECIES := "bramblebun"

## landmark.gd's own RAMP_RUN / PLINTH_TOP. Duplicated here rather than read
## off the instance because they are `const` on that script and this is a
## capture tool, not gameplay — but if the ramp is ever retuned and the actors
## start floating, this pair is why.
const RAMP_RUN := 11.0
const PLINTH_TOP := 4.2
const RAMP_TOP_Z := -10.0


func _init() -> void:
	_run()


## The lowest y any visible mesh under `node` reaches, in `node`'s own space.
## Negative for a body whose origin sits above its feet. Zero when nothing has
## a mesh yet, which is the safe answer: the actor stays where it was put.
func _lowest_point(node: Node, xform: Transform3D = Transform3D.IDENTITY) -> float:
	var lowest := 0.0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var box: AABB = xform * (node as MeshInstance3D).mesh.get_aabb()
		lowest = minf(lowest, box.position.y)
	for child in node.get_children():
		var next := xform
		if child is Node3D:
			next = xform * (child as Node3D).transform
		lowest = minf(lowest, _lowest_point(child, next))
	return lowest


func _ramp_y(z: float) -> float:
	var foot := RAMP_TOP_Z - RAMP_RUN
	return PLINTH_TOP * clampf((z - foot) / RAMP_RUN, 0.0, 1.0)


func _stage_actors(stage: Node3D, landmark: Node3D) -> void:
	var base: Vector3 = landmark.position
	var ramp_y := _ramp_y(ACTORS_LOCAL_Z)
	# The ramp deck's own top face: the box is 0.8m thick and its centre is
	# 0.2m below the slope line (landmark.gd::_build_ramp), so the surface a
	# body stands on is 0.2m above `_ramp_y`.
	var deck := ramp_y + 0.2

	var trainer: Node3D = CHARACTER_MODEL.new()
	trainer.name = "ScaleTrainer"
	stage.add_child(trainer)
	if not trainer.call("build", "trainer"):
		push_warning("no trainer model; the scale frames have no ruler in them")
	trainer.position = base + Vector3(TRAINER_LOCAL_X, deck, ACTORS_LOCAL_Z)
	# Facing the gate, which is what somebody walking up a ramp is doing.
	trainer.rotation.y = 0.0

	var creature: Node3D = CREATURE_SCENE.instantiate()
	creature.name = "ScaleCreature"
	creature.set_script(CREATURE_BODY)
	stage.add_child(creature)
	creature.call("setup", CREATURE_SPECIES)
	# A creature's origin is its BODY centre, not its feet -- `creature.tscn` is
	# a CharacterBody3D whose capsule is built around the origin from
	# species.json. Round 1 of this staging put the origin on the deck and the
	# bramblebun rendered half-sunk into the ramp. Lift by however far its own
	# art actually hangs below the origin, measured rather than guessed, so
	# this keeps working for any species.
	var drop := _lowest_point(creature)
	creature.position = base + Vector3(
		CREATURE_LOCAL_X, deck - drop, ACTORS_LOCAL_Z + 0.9)
	creature.rotation.y = deg_to_rad(-20.0)
	# A CharacterBody3D with no floor under it (the ramp's collider is real, but
	# nothing here waits for it) falls out of frame during the settle. Same
	# freeze `preview_creatures.gd` needed for the same reason.
	creature.set_physics_process(false)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var stage := Node3D.new()
	root.add_child(stage)

	# Lighting/environment/fog: a bare WorldEnvironment + Sun (placeholder
	# starting values, overwritten below), plus a REAL `world_look.gd`
	# instance driving them exactly like the scene does. A first attempt
	# hand-copied the .tscn's raw Environment/Sun values and got a near-black
	# unlit-looking near field in every frame -- `world_look.gd`'s own header
	# explains why a hand-copy misses the point: the .tscn's authored values
	# are only ever a starting pose, and `apply_time("day")` is what actually
	# sets the ambient fill colour the Compatibility renderer depends on
	# (`env.ambient_light_color`/`ambient_light_sky_contribution`, "sky
	# radiance does not reach the terrain under the Compatibility renderer").
	# Skipping that call is what produced the black foreground, not a real
	# rendering defect in the castle.
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	world_env.environment = environment
	world_env.name = "WorldEnvironment"
	stage.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	stage.add_child(sun)

	var look: Node = WORLD_LOOK.new()
	look.name = "WorldLook"
	look.set("sun_path", NodePath("../Sun"))
	look.set("environment_path", NodePath("../WorldEnvironment"))
	stage.add_child(look)
	look.call("apply_time", "day")

	# The camera FIRST, current from the start -- Terrain3D's own
	# `_grab_camera()` runs the instant it enters the tree and permanently
	# disables its `_physics_process` if it cannot find one right then
	# (confirmed by a first attempt at this script: terrain entered the tree
	# with no camera yet built, Terrain3D logged exactly that and gave up,
	# and the capture loop then hung waiting on a frame that never properly
	# rendered). `playground_world.gd::_ready()` avoids this the same way --
	# camera and `_terrain.set_camera()` both happen before anything else
	# waits on a real frame.
	# Positioned near the site FROM THE START, not at the origin -- Terrain3D
	# streams regions around wherever `set_camera`'s camera actually is, and
	# the site (~230,-144) is a full region away from the origin. A first
	# attempt left the camera at (0,0,0) through the whole settle phase, then
	# jumped it to the site only for the two brief per-viewpoint waits before
	# capture: the near-camera terrain came back solid black in both frames,
	# undercooked/unstreamed geometry, not a real rendering defect.
	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	camera.global_position = Vector3(TOWER_AT.x, 50.0, TOWER_AT.y)
	stage.add_child(camera)
	camera.make_current()

	# playground_world.gd's script, instantiated but NEVER added to the tree --
	# its own `_ready()` (the full vegetation/water/settlement build) only
	# fires on tree entry, so a detached instance never runs it. Only its
	# terrain-building methods are called directly.
	var world = WORLD_SCRIPT.new()
	print("[lite] calling _build_terrain")
	var terrain: Node3D = world.call("_build_terrain")
	if terrain == null:
		push_error("terrain build failed -- is the bake present at %s?" % DATA_DIR)
		quit(1)
		return
	print("[lite] terrain built, moving from the detached world instance to the real stage")
	# `_build_terrain()` already did `add_child(terrain)` on `world` (which is
	# itself never added to any tree). Plain remove/add rather than
	# `reparent()`: `reparent()` tries to preserve global transform via
	# `get_global_transform()`, which errors (harmlessly, but noisily) on a
	# node whose old parent was never in a tree in the first place.
	world.remove_child(terrain)
	stage.add_child(terrain)
	if terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	for i in 5:
		await physics_frame
	print("[lite] setting data_directory")
	terrain.set("data_directory", DATA_DIR)
	for i in 5:
		await physics_frame
	terrain.set("collision_mode", 3)
	world.set("_terrain", terrain)
	print("[lite] applying ground materials")
	world.call("_apply_ground_materials")

	print("[lite] building landmark")
	var landmark: Node3D = LANDMARK.new()
	landmark.name = "StrongholdSilhouette"
	stage.add_child(landmark)
	landmark.call("build", world)
	print("[lite] landmark built, staging actors")
	_stage_actors(stage, landmark)
	print("[lite] actors staged, settling")

	for i in SETTLE_FRAMES:
		await physics_frame
	print("[lite] settled, capturing viewpoints")

	var field: RefCounted = HEIGHTFIELD.new()
	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		print("[lite] %s: posed, waiting physics" % name)

		for i in 30:
			await physics_frame
		print("[lite] %s: physics settled, waiting process frames" % name)
		for i in POSE_FRAMES:
			await process_frame
		print("[lite] %s: process settled, waiting frame_post_draw" % name)
		await RenderingServer.frame_post_draw
		print("[lite] %s: frame drawn, reading texture" % name)

		var image := root.get_texture().get_image()
		print("[lite] %s: image read (null=%s)" % [name, image == null])
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue
		written.append(path)
		print("  %-26s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
