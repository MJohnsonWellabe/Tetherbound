extends "res://tests/helpers/cloudreach_witness_route.gd"

## F06#1 witness (ACCEPTANCE §6.1 F06: "ordinary foot, Fly and loaner paths
## traverse all six Cloudreach regions ... do not bypass a closed gate").
##
## Runs the unchanged continuous normal-input route (InputEventAction through
## the production controller/collision, no position writes) and adds a
## per-physics-frame region ledger on top of it: the region the trainer (or the
## piloted creature) stands in, by the map's own `region_at`, and how it got
## there -- foot, Fly or deployed-creature pilot. It passes only when all six
## regions are entered, every ground region is walked on foot, the fly-only High
## Roost is reached by Fly (WORLD: it has no ground route by design), and no
## frame is spent inside a sealed Fly restriction box before its unlock flag.
##
## START STATE (disclosed): the earned c1_arrival save does not exist yet
## (F06#0 is a separate criterion). Without `--from-save` this uses the
## continuous harness's committed completed-Meadows fixture: five level-25
## installed creatures, Meadows Heart active, no Cloudreach flags. Pass
## `--from-save=<dir>` to run from an earned save once one exists.
const MAP_STATE := preload("res://scripts/world/cloudreach_map_state.gd")
const WORLD_CONFIG := "res://data/config/cloudreach_world.json"
const PHYSICAL_CONFIG := "res://data/config/cloudreach_physical_runtime.json"
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f06-1-foot-regions"
const MIN_FOOT_FRAMES := 60

var world_config: Dictionary = {}
var sealed_boxes: Array[Dictionary] = []
var region_frames: Dictionary = {}
var region_first_entry: Dictionary = {}
var region_sequence: Array[Dictionary] = []
var last_region := ""
var sealed_violations: Array[Dictionary] = []
var witness_frames := 0
var region_unlock: Dictionary = {}
var locked_entries: Array[Dictionary] = []


func _run() -> void:
	world_config = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG))
	var physical_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PHYSICAL_CONFIG))
	for spec: Dictionary in physical_config.get("restrictions", []):
		sealed_boxes.append({"id": str(spec.id), "flag": str(spec.requires_flag),
			"box": AABB(_vec(spec.position), _vec(spec.size))})
	for entry: Dictionary in world_config.get("regions", []):
		region_unlock[str(entry.id)] = str(entry.get("access", {}).get("requires_unlock", ""))
	await super._run()


## This witness's event log lives beside its verdict, not in the shared
## continuous-route directory another run could overwrite.
func _write_report() -> void:
	output_dir = WITNESS_DIR
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	super._write_report()


func _mode() -> String:
	if runtime != null and runtime.creature_piloted(): return "creature_pilot"
	if fly != null and fly.is_flying(): return "fly"
	return "foot"


func _record_frame() -> void:
	super._record_frame()
	if not is_instance_valid(player) or runtime == null: return
	witness_frames += 1
	var body: Node3D = runtime.controlled_body()
	var at: Vector3 = body.global_position
	var mode := _mode()
	var region := MAP_STATE.region_at(world_config, at)
	if not region.is_empty():
		var counts: Dictionary = region_frames.get(region, {})
		counts[mode] = int(counts.get(mode, 0)) + 1
		region_frames[region] = counts
		if not region_first_entry.has(region):
			region_first_entry[region] = {"mode": mode, "stage": stage, "position": str(at),
				"simulated_seconds": snappedf(simulated_seconds, 0.01)}
			_log("witness_region_entered", {"region": region, "mode": mode})
		# `region_at` picks the nearest centre; a gated region entered before its
		# unlock flag would be a gate bypass (or a boundary artefact to inspect).
		var unlock := str(region_unlock.get(region, ""))
		if not unlock.is_empty() and not _has(unlock) and locked_entries.size() < 50:
			locked_entries.append({"region": region, "flag": unlock, "mode": mode, "stage": stage, "position": str(at)})
	if region != last_region:
		region_sequence.append({"region": region, "mode": mode, "stage": stage,
			"simulated_seconds": snappedf(simulated_seconds, 0.01)})
		last_region = region
	for sealed: Dictionary in sealed_boxes:
		if _has(sealed.flag): continue
		if (sealed.box as AABB).has_point(at) and sealed_violations.size() < 50:
			sealed_violations.append({"restriction": sealed.id, "flag": sealed.flag,
				"position": str(at), "mode": mode, "stage": stage})


func _finish() -> void:
	var expected: Array[String] = []
	var summary: Array[Dictionary] = []
	for entry: Dictionary in world_config.get("regions", []):
		var id := str(entry.id)
		var mode_required := str(entry.get("access", {}).get("mode", "ground"))
		expected.append(id)
		var counts: Dictionary = region_frames.get(id, {})
		var foot := int(counts.get("foot", 0))
		var flown := int(counts.get("fly", 0))
		var ok := false
		if mode_required == "fly_only": ok = flown > 0
		else: ok = foot >= MIN_FOOT_FRAMES
		summary.append({"region": id, "access_mode": mode_required, "frames": counts,
			"first_entry": region_first_entry.get(id, {}), "passed": ok})
		if completed_route and not failed:
			_require(ok, "F06#1 region %s traversed (%s): %s" % [id, mode_required, str(counts)])
	if completed_route and not failed:
		_require(sealed_violations.is_empty(), "F06#1 no frame inside a sealed restriction before its unlock")
		_require(locked_entries.is_empty(), "F06#1 no gated region entered before its unlock flag (%d)" % locked_entries.size())
		_require(game.party.members().size() == expected_party_size, "F06#1 party size unchanged")
	_write_witness(summary)
	super._finish()


func _write_witness(summary: Array[Dictionary]) -> void:
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	var file := FileAccess.open(WITNESS_DIR + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F06#1",
		"passed": completed_route and not failed,
		"start_state": ("earned save " + from_save) if not from_save.is_empty() else "committed completed-Meadows fixture (smoke_cloudreach_continuous default; earned c1_arrival save not yet available)",
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal",
		"accelerated": accelerated, "stage": stage, "distance_m": distance_m,
		"witness_frames": witness_frames, "regions": summary,
		"region_sequence": region_sequence, "sealed_violations": sealed_violations, "locked_region_entries": locked_entries,
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	print("F06#1 WITNESS %s regions=%s" % ["PASS" if completed_route and not failed else "FAIL",
		JSON.stringify(summary.map(func(s: Dictionary) -> String: return "%s:%s" % [s.region, "ok" if s.passed else "MISSING"]))])
