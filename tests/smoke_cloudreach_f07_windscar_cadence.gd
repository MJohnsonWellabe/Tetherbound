extends "res://tests/smoke_cloudreach_continuous.gd"

## F07#2 engine witness: the Windscar return, where the 2026-09-05 continuous
## run measured an 885.87 s stretch with no action. The walker leaves the
## aerie dais after the return glide and follows the continuous harness's own
## `_navigate` to `counterweight_entered` (-720, 700, 3680), exactly the call
## `smoke_cloudreach_continuous.gd` makes after `_return_to_aerie()`.
##
## "Action" is the harness's own definition (`_log` kinds that feed
## `activity_intervals`: first actionable offer of each source -- each wild
## body's Engage offer separately -- interactions, battles, flight). The owned
## companion is deployed by real `creature_recall` input, as
## `smoke_cloudreach_deployed_cadence.gd` does, because the director offers no
## wild Engage without an ally body.
##
## Fixture (declared): post-shrine chapter flags, the player placed once on
## the aerie dais. Every metre after that is stick input over collision.
##
##   godot --headless --path . --script tests/smoke_cloudreach_f07_windscar_cadence.gd -- [--out=<dir>]
##
## Prints `F07 WINDSCAR CADENCE {...}` with every interval and the longest;
## exit 0 when the leg completes and no interval exceeds the A7 limit.

const A7_LIMIT_SECONDS := 120.0
const AERIE_DAIS := Vector3(400.0, 610.0, 3250.0)
const COUNTERWEIGHT_ENTERED := Vector3(-720.0, 700.0, 3680.0)
const FLAGS: Array[String] = ["cloudreach_chapter_started", "cloudreach_crisis_learned",
	"storm_anchor_lower_west_mapped", "cloudreach_lower_anchors_investigated",
	"tether_lieutenant_senn_defeated", "causeway_survivors_reconnected", "windscar_aerie_prepared",
	"keeper_maela_trial_defeated", "cloudreach_act_i_complete", "fly_traversal_unlocked",
	"sky_shrine_reached", "storm_anchor_engine_truth_learned", "cloudreach_upper_route_unlocked"]

var _out := ""
var _wild_offers := 0
## Negative control: `--ignore-cadence-pairs` does not count Engage offers from
## the F07 cadence pairs (sites carrying `_why_cadence_f07`), i.e. measures the
## route as it stood before them.
var _ignore_prefixes: Array[String] = []
## Negative control: `--ignore-wilds` counts no wild Engage offer at all (the
## base harness's companion-less view).
var _ignore_wilds := false


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--ignore-wilds":
			_ignore_wilds = true
		elif arg == "--ignore-cadence-pairs":
			var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
			for site: Dictionary in encounters.get("wild_sites", []):
				if not str(site.get("_why_cadence_f07", "")).is_empty():
					_ignore_prefixes.append(str(site.id) + "_")
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://cloudreach_f07_windscar_cadence"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	await _frames(20)
	stage = "aerie_dais"
	var ground := float(world.call("ground_height_near", AERIE_DAIS))
	player.global_position = Vector3(AERIE_DAIS.x, (ground if is_finite(ground) else AERIE_DAIS.y) + 1.2, AERIE_DAIS.z)
	player.velocity = Vector3.ZERO
	await _frames(60)
	await _tap("creature_recall")
	await _frames(20)
	var ally_deployed: bool = director.ally_body() != null
	previous_activity = {}
	activity_intervals.clear()
	_log("flight_waypoint", {"target": "fixture: aerie dais after the return glide"})
	stage = "windscar_return_to_counterweight"
	var before := distance_m
	var reached := await _navigate(COUNTERWEIGHT_ENTERED)
	_log("physical_interaction", {"id": "counterweight_entered (arrival)"})
	_release()
	var longest: Dictionary = {}
	var over: Array = []
	for interval: Dictionary in activity_intervals:
		if longest.is_empty() or float(interval.gap_seconds) > float(longest.gap_seconds):
			longest = interval
		if float(interval.gap_seconds) > A7_LIMIT_SECONDS:
			over.append(interval)
	var ok := reached and not failed and ally_deployed and over.is_empty() and not longest.is_empty()
	var result := {"verdict": "PASS" if ok else "FAIL", "reached": reached, "ally_deployed": ally_deployed,
		"walked_m": snappedf(distance_m - before, 0.1), "simulated_seconds": snappedf(simulated_seconds, 0.1),
		"wild_engage_offers": _wild_offers, "ignored_cadence_sites": _ignore_prefixes.size(), "ignore_wilds": _ignore_wilds,
		"a7_limit_seconds": A7_LIMIT_SECONDS,
		"longest_interval": longest, "over_limit": over, "intervals": activity_intervals}
	print("F07 WINDSCAR CADENCE " + JSON.stringify(result))
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
		var file := FileAccess.open(_out.path_join("windscar_return_cadence.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(result, "  "))
	quit(0 if ok else 1)


## The base harness already logs each wild body's first Engage offer
## (`EncounterDirector:<body path>`). The negative controls drop those rows
## before they reach `activity_intervals`.
func _log(kind: String, details: Dictionary = {}) -> void:
	if kind == "meaningful_offer":
		var path := str(details.get("path", ""))
		if path.contains("EncounterDirector:"):
			if _ignore_wilds:
				return
			var body := path.get_slice("/", path.get_slice_count("/") - 1)
			for prefix in _ignore_prefixes:
				if body.begins_with(prefix):
					return
			_wild_offers += 1
	super._log(kind, details)
