extends SceneTree

## Route blocker B3 (#340): every Cloudreach wild site must resolve near its
## authored spot. Boots the production scene with the runtime mounted, asks
## the runtime for its resolved encounter data (the same call the encounter
## director is set up with) and requires every authored site to be present --
## none left out by the fail-closed rule -- and within the limit (XZ) of where
## it was authored.
##
##   godot --headless --path . --script tests/smoke_cloudreach_wild_site_resolution.gd
##
## Prints `CLOUDREACH WILD SITE RESOLUTION {...}`; exit 0 on pass.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")
## Sites whose authored point is a composition choice with NO supported ground
## within the limit (searched: tests/probe_cloudreach_wild_site_support.gd
## --near, 45 m, 4 m grid, road allowed). They fail closed in play instead of
## being bound to the nearest route (which put each exactly where its
## composition note forbids). A design decision is open for each (e.g. an Air
## patrol); remove the row when it resolves.
const KNOWN_UNRESOLVED := {
	"road_visibility_broken_causeway_main_03": "three-bells composition keeps the west hero approach open; the fallback put it 17 m from that approach",
	"road_visibility_windscar_floor_loop_15": "flight-aerie composition keeps wildlife 90 m off the lesson dais; the fallback put it 7 m from the dais centre",
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 20:
		await physics_frame
	var runtime: Node = world.get_node("CloudreachRuntime")
	var authored: Dictionary = {}
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
	for site: Dictionary in raw.get("wild_sites", []):
		authored[str(site.id)] = Vector3(float(site.position[0]), float(site.position[1]), float(site.position[2]))
	var limit := float(raw.get("wild_site_max_resolution_m", RUNTIME.WILD_SITE_MAX_RESOLUTION_M))
	var resolved: Dictionary = runtime.call("resolved_encounter_data", {})
	var seen: Dictionary = {}
	var worst := {"id": "", "m": 0.0}
	var failures: Array[String] = []
	for site: Dictionary in resolved.get("wild_sites", []):
		var id := str(site.id)
		seen[id] = true
		var at := Vector3(float(site.position[0]), float(site.position[1]), float(site.position[2]))
		var a: Vector3 = authored[id]
		var moved := Vector2(at.x - a.x, at.z - a.z).length()
		if moved > float(worst.m):
			worst = {"id": id, "m": snappedf(moved, 0.01)}
		if moved > limit:
			failures.append("%s resolved %.1f m from its authored spot" % [id, moved])
	var known_left_out: Array[String] = []
	for id: String in authored:
		if seen.has(id) and KNOWN_UNRESOLVED.has(id):
			print("CLOUDREACH WILD SITE RESOLUTION: %s now resolves; delete its KNOWN_UNRESOLVED row" % id)
		elif not seen.has(id):
			if KNOWN_UNRESOLVED.has(id):
				known_left_out.append(id)
			else:
				failures.append("%s was left out (resolves more than %.0f m away)" % [id, limit])
	print("CLOUDREACH WILD SITE RESOLUTION " + JSON.stringify({"verdict": "PASS" if failures.is_empty() else "FAIL",
		"authored": authored.size(), "resolved": seen.size(), "known_unresolved_left_out": known_left_out, "limit_m": limit, "worst": worst, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
