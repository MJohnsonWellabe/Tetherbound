extends SceneTree

## F14#1 / F13#5 evidence: the Veilfall interior at the production CameraRig,
## for a code-blind Bars A/B verdict on the four rooms (the fight captures only
## show the Heart Chamber). Evidence only: nothing is asserted or saved.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1920x1080 --script res://tools/capture_veilfall_interior.gd -- --out=res://shots/veilfall_interior
##
## Fixture (disclosed): the player is placed at each stand inside the interior
## staging area (the same place the waterfall prompt transfers a peer to), the
## pump flags are set so both grilles stand open, the party is the original
## five at L43 with Ripplet out, and the HUD is live.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := ["ripplet", "bramblebun", "mudsnout", "pipwing", "trailpup"]
const FLAGS := ["water_veilfall_intake_stopped", "water_veilfall_return_opened"]
## [name, interior-local player position, camera yaw (deg), pitch (deg)].
const STANDS := [
	["intake_gallery", Vector3(0, 0.2, 6), 180.0, -8.0],
	["pump_hall", Vector3(-6, 0.2, 36), 200.0, -10.0],
	["sluice_crossing", Vector3(0, 0.2, 63), 180.0, -12.0],
	["heart_chamber_entry", Vector3(0, 0.2, 86), 180.0, -8.0],
	["heart_chamber_crystal", Vector3(6, 0.2, 100), 165.0, -6.0],
	["heart_chamber_banner", Vector3(-8, 0.2, 98), 110.0, -8.0],
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "res://shots/veilfall_interior"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "veilfall-interior-capture"
	game.world.world_id = "veilfall-interior-capture-world"
	game.save_system = SAVE.new("user://veilfall_interior_capture_%d/" % Time.get_ticks_usec())
	for id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(id)
		creature.set_level(43, PROGRESSION.config())
		game.local.party.add(creature)
	for flag: String in FLAGS:
		game.world.flags.set_flag(flag)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	while not world.shell_build_complete():
		await process_frame
	var veilfall: Node3D = world.get_node("WaterVeilfall")
	var player: Node3D = world.local_rig()
	var rig: Node = world.get_node("CameraRig")
	var director: Node = world.get_node("EncounterDirector")
	var log: Array = []
	var first := true
	for stand: Array in STANDS:
		var at: Vector3 = veilfall.interior.global_position + (stand[1] as Vector3)
		player.global_position = at
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		rig.set("yaw", deg_to_rad(float(stand[2])))
		rig.set("pitch", deg_to_rad(float(stand[3])))
		await _frames(30)
		if first:
			first = false
			await director.summon_active_creature()
			await _frames(90)
		await RenderingServer.frame_post_draw
		var path := out.path_join("%s.png" % stand[0])
		root.get_viewport().get_texture().get_image().save_png(path)
		log.append({"stand": stand[0], "player": [at.x, at.y, at.z], "yaw_deg": stand[2], "pitch_deg": stand[3]})
		print("VEILFALL INTERIOR %s" % path)
	var file := FileAccess.open(out.path_join("frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(log, "  "))
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
