extends SceneTree

## GATE-F corridor evidence run: the whole post-village chapter walked as ONE
## continuous route, in one boot, with the cadence recorded end to end.
##
##   godot --headless --path . --script tools/_probe_gate_f_corridor.gd
##
## ## Why this is not five copies of tools/_probe_band1_evidence.gd
##
## That probe answers "is Band 1 populated". Gate F asks a question no
## per-band probe can: does the chapter hold together ACROSS the seams. The
## longest dead walk in the Meadows is not inside a band -- every band lane
## tuned its own interior and each one passes on its own numbers -- it is at
## the handoffs, where one lane's content stops and the next lane's has not
## started yet, and nobody owns the join. Walking band 1..5 as one route with
## one running "metres since I last met anything" counter is the only way that
## interval becomes visible.
##
## So this carries `seen` and the dead-walk counter ACROSS band boundaries and
## reports both the per-band figures (comparable with each lane's own evidence)
## and the chapter-wide worst interval (which is the Gate F finding).
##
## ## Method, and its honest limit
##
## Inherited wholesale from `tools/_probe_band1_evidence.gd`, including its
## caveat: the route is stepped as points, not driven through physics at walk
## speed, because driving 7.5km of corridor through physics is tens of
## thousands of ticks and hours of wall clock. So this measures CONTENT cadence
## honestly and says nothing about traversal feel or footing.
##
## Two things make the snapshot trustworthy for wilds, both verified in the
## source rather than assumed:
##
##   * `encounter_director.gd::_set_wild_active()` only ever flips
##     `set_physics_process` -- distance streaming never hides, moves or frees a
##     body. So every authored creature in the chapter is standing in the tree
##     at boot regardless of where the player is, and a snapshot counts them
##     all.
##   * `visible` is still checked, because R5.3's time/weather gates express
##     themselves as visibility, and a gated-out creature is not an encounter
##     however present it is in the table.
##
## The route itself is read from `data/config/terrain_playground.json`
## (`trail.bands[].points`) rather than transcribed, so it cannot drift from
## the spine the world is actually built around. The five bands chain
## end to end -- band N's last point is band N+1's first -- which is what makes
## one continuous walk legitimate rather than five stitched ones.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_CFG := "res://data/config/terrain_playground.json"

const STEP_M := 4.0
## How far off the path something still counts as met. Same 30m as the band 1
## probe, and for the same reason: this is "would a player walking here notice
## it and could they choose to go to it", not "does it block the road".
const NOTICE_M := 30.0
## Walking pace used only to turn metres into a readable minutes figure.
const WALK_MPS := 4.0
## A dead walk worth reporting as a Gate F finding. Prompt 61/70 call the
## symptom "dead travel"; this is the threshold the report flags at, not an
## assertion -- the judgement of whether a given gap is intentional breathing
## room belongs to the coordinator reading it.
const DEAD_WALK_FLAG_M := 250.0

var _band_ids: Array[String] = []
var _band_routes: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_load_routes()
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var nodes: Array = _all(world)
	var points: Array = _points_of_interest(nodes)
	print("GATEF corridor probe -- world contains %d points of interest in total" % points.size())
	print("")

	var seen := {}
	var travelled := 0.0
	var last_meeting := 0.0
	var worst_gap := 0.0
	var worst_at := 0.0
	var worst_band := ""
	var chapter_log: Array = []
	var totals := {}

	for b in range(_band_routes.size()):
		var band_id: String = _band_ids[b]
		var route: Array = _band_routes[b]
		var band_start_m := travelled
		var band_log: Array = []
		var band_worst := 0.0
		var band_counts := {}

		for leg in range(route.size() - 1):
			var a: Vector2 = route[leg]
			var b2: Vector2 = route[leg + 1]
			var length := a.distance_to(b2)
			var steps := maxi(1, int(length / STEP_M))
			for s in range(steps):
				var here: Vector2 = a.lerp(b2, float(s) / float(steps))
				travelled += length / float(steps)
				for entry: Variant in points:
					var point: Dictionary = entry
					if seen.has(point["key"]):
						continue
					var flat: Vector2 = point["at"]
					if here.distance_to(flat) > NOTICE_M:
						continue
					seen[point["key"]] = true
					var gap := travelled - last_meeting
					if gap > worst_gap:
						worst_gap = gap
						worst_at = travelled
						worst_band = band_id
					if gap > band_worst:
						band_worst = gap
					var kind: String = point["kind"]
					band_counts[kind] = int(band_counts.get(kind, 0)) + 1
					totals[kind] = int(totals.get(kind, 0)) + 1
					var row := {"m": travelled, "gap": gap, "what": point["what"], "kind": kind}
					band_log.append(row)
					chapter_log.append(row)
					last_meeting = travelled

		var band_m := travelled - band_start_m
		print("== %s ==" % band_id)
		print("  walked %.0f m (%.0f -> %.0f along the chapter), ~%.1f min at %.1f m/s"
			% [band_m, band_start_m, travelled, band_m / WALK_MPS / 60.0, WALK_MPS])
		print("  met %d new things: %s" % [band_log.size(), _counts_line(band_counts)])
		print("  longest stretch meeting nothing new, inside this band: %.0f m" % band_worst)
		print("GATEF-METRIC band=%s metres=%.0f minutes=%.1f met=%d worst_gap_m=%.0f %s"
			% [band_id, band_m, band_m / WALK_MPS / 60.0, band_log.size(), band_worst,
				_metric_counts(band_counts)])
		print("")

	# The walk ends at the Hall door; nothing after it is a "gap" the player
	# walks through, so the tail is reported but never allowed to become the
	# headline worst interval the way an interior stretch is.
	var tail := travelled - last_meeting

	print("== chapter ==")
	print("corridor walked: %.0f m  (~%.1f min at %.1f m/s)"
		% [travelled, travelled / WALK_MPS / 60.0, WALK_MPS])
	print("things met within %.0f m of the route: %d" % [NOTICE_M, chapter_log.size()])
	print("by kind: %s" % _counts_line(totals))
	print("longest stretch meeting nothing new: %.0f m (~%.1f min), ending at %.0f m along, in %s"
		% [worst_gap, worst_gap / WALK_MPS / 60.0, worst_at, worst_band])
	print("tail after the last thing met: %.0f m" % tail)
	print("GATEF-METRIC band=CHAPTER metres=%.0f minutes=%.1f met=%d worst_gap_m=%.0f worst_gap_at_m=%.0f worst_gap_band=%s tail_m=%.0f %s"
		% [travelled, travelled / WALK_MPS / 60.0, chapter_log.size(), worst_gap, worst_at,
			worst_band, tail, _metric_counts(totals)])
	print("")

	var flagged: Array = []
	for entry: Variant in chapter_log:
		var e: Dictionary = entry
		if float(e["gap"]) >= DEAD_WALK_FLAG_M:
			flagged.append(e)
	print("dead-walk intervals >= %.0f m (%d):" % [DEAD_WALK_FLAG_M, flagged.size()])
	for entry: Variant in flagged:
		var e: Dictionary = entry
		print("  +%5.0f m of nothing, broken at %6.0f m along by %s"
			% [e["gap"], e["m"], e["what"]])
	print("")

	print("cadence -- every new thing, in the order a player walking the chapter meets it:")
	for entry: Variant in chapter_log:
		var e: Dictionary = entry
		print("  %6.0f m  (+%4.0f m)  %s" % [e["m"], e["gap"], e["what"]])

	_report_grounding(world, nodes)
	quit(0)


## The corridor spine, straight out of the file the world is built from.
func _load_routes() -> void:
	var f := FileAccess.open(TERRAIN_CFG, FileAccess.READ)
	if f == null:
		push_error("cannot open %s" % TERRAIN_CFG)
		quit(1)
		return
	var cfg: Dictionary = JSON.parse_string(f.get_as_text())
	for entry: Variant in (cfg["trail"]["bands"] as Array):
		var band: Dictionary = entry
		var pts: Array = []
		for p: Variant in (band["points"] as Array):
			var pair: Array = p
			pts.append(Vector2(float(pair[0]), float(pair[1])))
		_band_ids.append(str(band["id"]))
		_band_routes.append(pts)


## GATE-D's regression, asked as a question rather than assumed fixed: a wild
## creature under the terrain is authored content the player never meets, and
## it is invisible to every count above because the body IS in the tree.
func _report_grounding(world: Node, nodes: Array) -> void:
	var under := 0
	var total := 0
	var worst := 0.0
	for node: Variant in nodes:
		var n3 := node as Node3D
		if n3 == null or not n3.is_inside_tree():
			continue
		if n3.get_script() == null:
			continue
		if not str(n3.get_script().resource_path).ends_with("wild_creature.gd"):
			continue
		total += 1
		var ground := float(world.call("ground_height_at", n3.global_position.x, n3.global_position.z))
		var below := ground - n3.global_position.y
		if below > 2.0:
			under += 1
			worst = maxf(worst, below)
	var pct := 0.0
	if total > 0:
		pct = 100.0 * float(under) / float(total)
	print("")
	print("grounding: %d of %d wild bodies are >2m under their terrain (%.1f%%), worst %.0fm"
		% [under, total, pct, worst])
	print("GATEF-METRIC band=GROUNDING wilds=%d underground=%d pct=%.1f worst_m=%.0f"
		% [total, under, pct, worst])


func _counts_line(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for k: Variant in keys:
		parts.append("%s %d" % [str(k), int(counts[k])])
	if parts.is_empty():
		return "nothing"
	return ", ".join(parts)


func _metric_counts(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for k: Variant in keys:
		parts.append("%s=%d" % [str(k), int(counts[k])])
	return " ".join(parts)


## Everything standing in the world that is a reason to stop, found by asking
## the running scene rather than by re-reading the configs that built it.
##
## Kinds and how they are recognised, all of them the hard-won way rather than
## the obvious way (see `_probe_band1_evidence.gd`'s notes): trainers by the
## `trainer_id` metadata `trainer_npc.gd` stamps on the BODY (the script sits
## on the placer, not the body), harvest nodes by `_item_id` with the
## underscore (private, no getter, and `get("item_id")` returns null rather
## than erroring), wilds by script path plus a visibility check.
func _points_of_interest(nodes: Array) -> Array:
	var out: Array = []
	for node: Variant in nodes:
		var n3 := node as Node3D
		if n3 == null or not n3.is_inside_tree():
			continue
		var at := Vector2(n3.global_position.x, n3.global_position.z)
		var script_path := ""
		if n3.get_script() != null:
			script_path = str(n3.get_script().resource_path)

		if n3.has_meta("trainer_id"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "trainer",
				"what": "TRAINER %s" % str(n3.get_meta("trainer_id"))})
			continue

		if script_path.ends_with("wild_creature.gd"):
			if not n3.visible:
				continue
			var instance: Variant = n3.get("instance")
			var label := str(n3.get("species_id"))
			if instance != null:
				label = "%s  (L%d)" % [str(instance.get("display_name")), int(instance.get("level"))]
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "wild",
				"what": "wild     %s" % label})
		elif script_path.ends_with("harvest_node.gd"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "gather",
				"what": "gather   %s" % str(n3.get("_item_id"))})
		elif script_path.ends_with("camp.gd"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "rest",
				"what": "rest     camp"})
		elif script_path.ends_with("landmark.gd"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "landmark",
				"what": "landmark %s" % n3.name})
		elif script_path.ends_with("tm_pickup.gd"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "tm",
				"what": "TM       %s" % n3.name})
		elif script_path.ends_with("key_pickup.gd"):
			out.append({"key": n3.get_instance_id(), "at": at, "kind": "key",
				"what": "key      %s" % n3.name})
	return out


func _all(node: Node) -> Array:
	var out: Array = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
