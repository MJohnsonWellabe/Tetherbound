extends SceneTree

## Are the wild creatures the spawn tables author actually STANDING on the
## corridor, or are they underneath it?
##
##   godot --headless --path . --script tools/_probe_wild_grounding.gd
##   godot --headless --path . --script tools/_probe_wild_grounding.gd -- --frames=1200
##
## WHY THIS EXISTS.
##
## GATE-D3's driven run walked the whole of Band 3 and came within 35m of 11
## of the band's 155 wild creatures. The authored placement does not predict
## that -- the cluster centres sit a median 20m off the spine -- so either the
## probe was broken or the creatures were not where the config puts them. They
## were not: nearly every one of them was 190-200 METRES BELOW the terrain.
##
## The mechanism, and it is not Band 3's:
##
##   `creature_body.gd::_physics_process` subtracts gravity (26 m/s^2) on any
##   frame where `is_on_floor()` is false. Terrain3D builds collision
##   DYNAMICALLY around the CAMERA within a granted radius (ralph/BAKE-GUARDS
##   sec8.2) -- `playground_world.gd` hands it the player's camera. A creature
##   spawned four kilometres from the player therefore has no floor under it on
##   the frame it spawns, and never gets one, because collision arrives around
##   the camera and the camera never went there. It falls. Four seconds of
##   settle at 26 m/s^2 is 208m, which is the number this probe measures.
##
##   `encounter_director.gd::_stand_on_ground` reports no error, and cannot:
##   `place_on_ground` puts the body at the analytic height and succeeds. The
##   fall happens afterwards, in physics, silently.
##
## What that costs: the owner's 2026-08-22 density directive raised Band 3 from
## 18 creatures to 155, and a player walking the region meets a handful. Every
## band pays this, not only Band 3 -- band1's creatures survive only because
## they spawn where the player is standing.
##
## This is NOT a band-content defect and must not be fixed in a band's
## spawns.json: no placement change can help a body with no floor under it.
## It belongs with distance activation / creature streaming, which
## `ralph/DONE.md`'s GATE-D3 entry already names as the coordinator's own lane.
## This probe exists so that lane can reproduce it in one boot and prove it
## fixed.
##
## Read the printed summary, not the exit code: Terrain3D aborts on shutdown
## by design (D06).

const SCENE := "res://scenes/world/meadows_playground.tscn"
## Where each band ends, from `ralph/GATE_D_LANE_CONTRACT.md` sec1.
const BANDS := [
	{"name": "band1_lower_meadows", "to": 1360.0},
	{"name": "band2_stone_and_root", "to": 3180.0},
	{"name": "band3_the_river_lock", "to": 4760.0},
	{"name": "band4_upper_ironwood", "to": 7000.0},
	{"name": "band5_stronghold", "to": 999999.0},
]
## A body this far under the ground it was authored on is not standing on it.
## Generous on purpose: terrain the analytic heightfield and the collider
## disagree about by a metre is a different, much smaller problem.
const UNDERGROUND_M := 5.0

## GATE-D, after the fix: a steady ONE creature in band2_stone_and_root reads as
## ~8m under and does not go away. It is not a defect and should not be chased.
## `data/config/burrow_warrens.json` hand-places four residents inside the
## Warrens' chambers, and a cave is by definition below the surface this probe
## compares against (`ground_height_at` is the analytic HEIGHTFIELD, which knows
## nothing about carved interiors). Those creatures are also deliberately exempt
## from distance activation -- `encounter_director.gd`'s streaming keys clusters
## from `spawns.json`, and a hand-placed creature has no cluster, which reads as
## "never deactivated", which is correct for a dungeon.
##
## So the honest reading of this probe's output is: any band showing tens of
## creatures underground, or a depth that grows between the 60/240/600-frame
## samples, is the free-fall defect. One creature at a fixed ~8m in band2 is the
## Warrens, and it was there before the density work and will be there after.

var _samples := [60, 240, 600]


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		if parts[0].lstrip("-") == "frames" and parts.size() > 1:
			_samples = [60, 240, int(parts[1])]


func _run() -> void:
	_parse_args()
	print("=== wild creature grounding ===")
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)

	var director: Node = null
	var elapsed := 0
	for stop in _samples:
		while elapsed < stop:
			await physics_frame
			elapsed += 1
		if director == null:
			director = world.get_node_or_null(^"EncounterDirector")
			if director == null:
				print("PROBE FAIL: no EncounterDirector in the scene")
				quit(1)
				return
		_report(world, director, elapsed)
	quit(0)


func _report(world: Node, director: Node, frames: int) -> void:
	var bodies: Array = director.call("wild_creatures")
	var per_band := {}
	for entry: Variant in BANDS:
		per_band[(entry as Dictionary)["name"]] = {"n": 0, "under": 0, "worst": 0.0}

	for body: Variant in bodies:
		var b := body as Node3D
		if b == null:
			continue
		var p := b.global_position
		var ground := float(world.call("ground_height_at", p.x, p.z))
		var drop := ground - p.y
		var band := ""
		for entry: Variant in BANDS:
			if p.z < float((entry as Dictionary)["to"]):
				band = str((entry as Dictionary)["name"])
				break
		if band == "":
			continue
		var row: Dictionary = per_band[band]
		row["n"] = int(row["n"]) + 1
		if drop > UNDERGROUND_M:
			row["under"] = int(row["under"]) + 1
		row["worst"] = maxf(float(row["worst"]), drop)

	print("\nafter %d physics frames (%.1fs):" % [frames, float(frames) / 60.0])
	print("  %-24s %6s %10s %12s" % ["band", "wilds", "underground", "deepest"])
	for entry: Variant in BANDS:
		var name: String = str((entry as Dictionary)["name"])
		var row: Dictionary = per_band[name]
		if int(row["n"]) == 0:
			continue
		print("  %-24s %6d %10s %10.1f m" % [
			name, int(row["n"]),
			"%d (%.0f%%)" % [int(row["under"]),
				100.0 * float(int(row["under"])) / float(int(row["n"]))],
			float(row["worst"])])
