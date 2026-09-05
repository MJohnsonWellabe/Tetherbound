extends SceneTree

## Bounded summit checkpoint, not a continuous chapter. Actual production arena,
## captain AI/damage/rounds, environmental velocity and controller relay input.
## No lethal seam, mid-fight HP/position writes, extra creature or hidden recovery.
## Party snapshot is the pre-captain brawler_switch result in merged-main-final
## ladder evidence: fresh bond counters, earned L26/27 and full named-camp rest.
## Run: godot --headless --path . --fixed-fps 60 --script
## tools/probe_cloudreach_live_finale.gd -- --pilot=brawler_switch
const WORLD := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BALANCE := preload("res://tools/_probe_cloudreach_combat_balance.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const TEAM := [["terrapup",26,793],["ripplet",27,620],["galewisp",26,961],["mosshell",26,1590],["duskhush",26,1423]]
const REQUIREMENTS := ["realm_key_cloudreach","cloudreach_chapter_started","cloudreach_crisis_learned",
	"cloudreach_lower_anchors_investigated","causeway_survivors_reconnected","windscar_aerie_prepared",
	"cloudreach_act_i_complete","fly_traversal_unlocked","sky_shrine_reached","storm_anchor_engine_truth_learned",
	"cloudreach_upper_route_unlocked","cloudreach_act_ii_complete","cloudreach_upper_anchors_disabled",
	"summit_extraction_engine_reached"]
const OUTPUT := "res://ralph/reports/CLOUDREACH-LIVE-FINALE-0905"
var game: Node
var world: Node3D
var runtime: Node
var director: Node
var manager: Node
var finale: Node3D
var pilot: BALANCE.InputPilot
var mode := "brawler_switch"
var output := OUTPUT
var report := {"phases":[],"hits":[],"rounds":[],"relays":[],"recoveries":[],"errors":[]}
var telemetry := {"frames":0,"wind_frames":0,"arc_frames":0,"lee_frames":0,"actual_drift_frames":0,"maximum_drift_mps":0.0}
var switches := 0
var recording := false
var initial_frame := 0
var captures: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func fail(message: String) -> void:
	report.errors.append(message)
	push_error(message)


func snapshot() -> Array:
	var result: Array = []
	for owned: RefCounted in game.get("party").call("members"):
		result.append({"species":owned.get("species_id"),"level":owned.get("level"),"xp":owned.get("xp"),
			"hp":owned.get("hp"),"max_hp":owned.get("max_hp"),"fainted":owned.get("fainted")})
	return result


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args():
		return
	if captures.has(label):
		return
	captures[label] = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+mode+"-"+label+".png")


func _physics_process(_delta: float) -> bool:
	if not recording or not is_instance_valid(runtime):
		return false
	var body: CharacterBody3D = runtime.call("controlled_body")
	if not is_instance_valid(body):
		return false
	var sample: Dictionary = finale.call("hazard_at",body.global_position)
	telemetry.frames += 1
	telemetry.wind_frames += int(not (sample.wind as Vector3).is_zero_approx())
	telemetry.arc_frames += int(not (sample.arc as Vector3).is_zero_approx())
	telemetry.lee_frames += int(sample.sheltered)
	# Observe the real movement hook's persisted drift, not a hypothetical force.
	var drift: Vector3 = (finale.get("_hazard_drift") as Dictionary).get(body.get_instance_id(),Vector3.ZERO)
	telemetry.actual_drift_frames += int(not drift.is_zero_approx())
	telemetry.maximum_drift_mps = maxf(telemetry.maximum_drift_mps,drift.length())
	if not drift.is_zero_approx():
		capture(str(finale.get("phase")))
	return false


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pilot="):
			mode = arg.trim_prefix("--pilot=")
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if mode not in ["spacer","brawler","brawler_switch"]:
		fail("Unknown pilot")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1920,1200)
	game = root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("save_system",SAVE.new("user://cloudreach_live_finale_probe"))
	game.set("current_realm","cloudreach")
	for entry: Array in TEAM:
		var owned: RefCounted = SPECIES.spawn(entry[0])
		owned.call("set_level",entry[1],PROGRESSION.config())
		owned.set("xp",entry[2])
		game.get("party").call("add",owned)
	for flag: String in REQUIREMENTS:
		game.get("progression").call("set_flag",flag)
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	await frames(15)
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.get("director")
	manager = runtime.get("manager")
	finale = runtime.get("finale")
	var player: CharacterBody3D = world.get_node("Player")
	# The sole position assignment declares the isolated summit start fixture.
	player.global_position = finale.global_position+Vector3(0,0.2,-10)
	player.velocity = Vector3.ZERO
	world.get_node("CameraRig").global_position = player.global_position+Vector3.UP*1.75
	await frames(10)
	pilot = BALANCE.InputPilot.new(self,manager,director,world.get_node("CameraRig"))
	pilot.use_switching = false
	pilot.switch_input = mode == "brawler_switch"
	pilot.pilot = BALANCE.PILOT.Pilot.SPACER if mode == "spacer" else BALANCE.PILOT.Pilot.BRAWLER
	pilot.listen()
	manager.connect("creature_switched",func(_index: int): switches += 1)
	manager.connect("hit_landed",func(on_enemy: bool,amount: float):
		if not on_enemy:
			var owned: RefCounted = manager.call("active_creature")
			report.hits.append({"damage":amount,"hp_fraction":amount/float(owned.get("max_hp")),"species":owned.get("species_id")}))
	finale.connect("phase_changed",func(phase: String): report.phases.append({"phase":phase,"physics_frame":Engine.get_physics_frames()}))
	finale.connect("recovery_requested",func(body: CharacterBody3D,camp: String,_at: Vector3):
		report.recoveries.append({"body":str(body.get_path()),"camp":camp}))
	await director.call("summon_active_creature")
	await frames(10)
	var before := snapshot()
	var coin_before: int = game.get("inventory").call("count","coin")
	seed(90525+hash("captain_veyra_storm_anchor"))
	initial_frame = Engine.get_physics_frames()
	recording = true
	var spec: Dictionary = director.get("trainer_specs")["captain_veyra_storm_anchor"]
	var captain: Node3D = director.get("trainer_nodes")[spec.id]
	if not director.call("begin_trainer_battle",spec,captain):
		fail("Real captain challenge refused")
	while director.call("trainer_battle_active") and Engine.get_physics_frames()-initial_frame < 36000:
		if manager.call("is_fighting"):
			var start := Engine.get_physics_frames()
			var result: Dictionary = await pilot.fight_to_the_end()
			result.seconds = float(Engine.get_physics_frames()-start)/Engine.physics_ticks_per_second
			report.rounds.append(result)
			print("LIVE FINALE ROUND "+JSON.stringify(result))
			if result.timed_out:
				fail("Captain round timed out")
				break
		else:
			await physics_frame
	await frames(160)
	var won: bool = game.get("progression").call("has","captain_veyra_defeated")
	var fight_seconds := float(Engine.get_physics_frames()-initial_frame)/Engine.physics_ticks_per_second
	var after_fight := snapshot()
	if won:
		for relay: Dictionary in finale.get("config").relays:
			var body: CharacterBody3D = runtime.call("controlled_body")
			if body == player:
				fail("Captain victory did not release creature field input")
				break
			var offset := Vector3(relay.offset[0],0,relay.offset[2])
			var target := finale.global_position+offset-offset.normalized()*2.0
			var gap := await pilot.walk_trainer_to(body,target,0.9,3600)
			await pilot.press("interact")
			await frames(8)
			var reached: bool = game.get("progression").call("has",relay.flag_id)
			report.relays.append({"id":relay.id,"walk_gap":gap,"activated":reached,"position":str(body.global_position)})
			if not reached:
				fail("Actual piloted relay approach failed: "+str(relay.id))
				break
		await capture("network-result")
	recording = false
	report.merge({"pilot":mode,"team_before":before,"team_after_fight":after_fight,"team_final":snapshot(),
		"won":won,"fight_seconds_including_final_settle":fight_seconds,"hazards":telemetry,
		"network_disabled":game.get("progression").call("has","storm_anchor_network_disabled"),
		"coins_paid":game.get("inventory").call("count","coin")-coin_before,
		"switches":switches,"voluntary_switches":pilot.voluntary_switches,
		"damage_dealt":pilot.damage_dealt,"damage_taken":pilot.damage_taken,
		"limitations":["Explicit summit and pre-captain rested team fixture, not route attrition",
			"No consumable use; pilot reads combat telegraphs but does not plan around wind or lee pockets",
			"Seeded combat RNG; a single run is not a statistical difficulty distribution",
			"Headless/fixed-fps timing is simulated gameplay time, never performance acceptance"],
		"source_hashes":{"probe":FileAccess.get_sha256("res://tools/probe_cloudreach_live_finale.gd"),
			"finale":FileAccess.get_sha256("res://scripts/world/cloudreach_finale_controller.gd"),
			"combat":FileAccess.get_sha256("res://data/config/combat.json"),
			"encounters":FileAccess.get_sha256("res://data/config/cloudreach_encounters.json")}})
	var file := FileAccess.open(output+"/"+mode+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("LIVE FINALE COMPLETE "+JSON.stringify({"won":won,"hazards":telemetry,"relays":report.relays,"errors":report.errors}))
	world.queue_free()
	await frames(5)
	quit(0 if report.errors.is_empty() else 1)
