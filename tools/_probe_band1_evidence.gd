extends SceneTree

## BAND1-D1 evidence run: walk the real Lower Meadows route and record what a
## player would actually meet on the way.
##
##   godot --headless --path . --script tools/_probe_band1_evidence.gd
##
## ## Why this is not tools/_probe_band1_cadence.py
##
## That probe reads the authored JSON and projects config positions onto the
## spine. It is the right tool for authoring -- it is fast, and it tells you
## where you have left a hole before you have built anything. It also cannot
## tell you whether a single one of those entries EXISTS in the running game.
## A spawn whose ground lookup failed, a creature hidden behind an R5.3
## `time`/`weather` gate, a trainer body that never placed, a harvest node
## inside a tree: all of those are invisible to a JSON reader and all of them
## are what the player actually experiences. This walks the built world and
## counts what is standing in it.
##
## ## What this is NOT
##
## It is a traversal probe, not a physics-driven playthrough. The body is
## stepped along the route and stood on the ground rather than driven by input
## at walk speed, because driving 2.4km through physics at this project's own
## measured rate (tests/smoke_traversal.gd: ~1700 ticks for ~120m) is roughly
## 34,000 physics ticks and hours of wall clock. So this measures CONTENT
## cadence honestly and says nothing about traversal feel, footing, or
## whether the walk is boring in the way only walking it can reveal. Prompt
## 62's evidence run wants both; this is the half a machine can do.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

## Band 1's spine, terrain_playground.json `trail.bands[0]`: the village square
## out to the South Bridge crossing at (8, 1330).
const ROUTE := [
	Vector2(27.5, -16), Vector2(14, 20), Vector2(8, 90), Vector2(-40, 180),
	Vector2(-120, 270), Vector2(-230, 330), Vector2(-360, 400), Vector2(-430, 510),
	Vector2(-330, 590), Vector2(-190, 650), Vector2(-50, 700), Vector2(90, 760),
	Vector2(230, 830), Vector2(360, 910), Vector2(430, 1020), Vector2(330, 1130),
	Vector2(180, 1200), Vector2(30, 1250), Vector2(-40, 1310), Vector2(8.0, 1330),
]

const STEP_M := 4.0
## How far off the path something still counts as met. Generous on purpose:
## this is "would a player walking here notice it and could they choose to go
## to it", not "does it block the road".
const NOTICE_M := 30.0
## Walking pace used only to turn metres into a readable minutes figure.
const WALK_MPS := 4.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var field: RefCounted = HEIGHTFIELD.new()
	var nodes: Array = _all(world)
	var points: Array = _points_of_interest(nodes)
	print("world contains %d points of interest in total (all bands)" % points.size())
	_report_trainers(nodes)

	var seen := {}
	var log: Array = []
	var travelled := 0.0
	var last_meeting := 0.0
	var worst_gap := 0.0
	var worst_at := 0.0

	for leg in range(ROUTE.size() - 1):
		var a: Vector2 = ROUTE[leg]
		var b: Vector2 = ROUTE[leg + 1]
		var length := a.distance_to(b)
		var steps := maxi(1, int(length / STEP_M))
		for s in range(steps):
			var here: Vector2 = a.lerp(b, float(s) / float(steps))
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
				log.append({"m": travelled, "gap": gap, "what": point["what"]})
				last_meeting = travelled

	var tail := travelled - last_meeting
	if tail > worst_gap:
		worst_gap = tail
		worst_at = travelled

	print("")
	print("route walked: %.0f m  (~%.1f min at %.1f m/s)" % [travelled, travelled / WALK_MPS / 60.0, WALK_MPS])
	print("things met within %.0f m of the path: %d" % [NOTICE_M, log.size()])
	print("longest stretch meeting nothing new: %.0f m, ending at %.0f m along" % [worst_gap, worst_at])
	print("")
	print("cadence -- every new thing, in the order a player walking this meets it:")
	for entry: Variant in log:
		var e: Dictionary = entry
		print("  %6.0f m  (+%4.0f m)  %s" % [e["m"], e["gap"], e["what"]])

	_report_gate(world)
	quit(0)


## Every trainer body standing in the world, with how far off this route it
## is. Trainers are the sparsest thing in a region and the easiest to
## mis-site, so "near the road but not ON it" is worth seeing as a number
## rather than inferring from an absence in the cadence list above.
func _report_trainers(nodes: Array) -> void:
	print("")
	print("trainer bodies, by distance from this route:")
	var rows: Array = []
	for node: Variant in nodes:
		var n := node as Node3D
		if n == null or not n.has_meta("trainer_id"):
			continue
		var at := Vector2(n.global_position.x, n.global_position.z)
		rows.append({"id": str(n.get_meta("trainer_id")), "at": at, "d": _lateral(at)})
	rows.sort_custom(func(a, b): return a["d"] < b["d"])
	for entry: Variant in rows:
		var row: Dictionary = entry
		var at: Vector2 = row["at"]
		var note := "on the route" if float(row["d"]) <= NOTICE_M else "OFF the route"
		print("  %-26s (%.0f, %.0f)  %6.0f m  %s" % [row["id"], at.x, at.y, row["d"], note])


func _lateral(p: Vector2) -> float:
	var best := 1.0e9
	for i in range(ROUTE.size() - 1):
		var a: Vector2 = ROUTE[i]
		var b: Vector2 = ROUTE[i + 1]
		var ab := b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


## Everything standing in the world that is a reason to stop, found by asking
## the running scene rather than by re-reading the configs that built it.
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

		# Trainer bodies are found by the `trainer_id` metadata
		# `trainer_npc.gd` stamps on each one, NOT by script path. The first
		# cut of this probe matched on the script and caught the PLACERS --
		# "Trainers", "StrongholdTrainers", "WardenTrainer", three container
		# nodes at the world origin -- while every actual trainer body went
		# uncounted. That is worth knowing generally: `trainer_npc.gd` is the
		# placer, and the bodies it places carry no script of their own.
		if n3.has_meta("trainer_id"):
			out.append({"key": n3.get_instance_id(), "at": at,
				"what": "TRAINER %s" % str(n3.get_meta("trainer_id"))})
			continue

		if script_path.ends_with("wild_creature.gd"):
			# `visible` matters: R5.3's time/weather gates hide a creature
			# rather than removing it, and a hidden creature is not an
			# encounter however present it is in the table.
			if not n3.visible:
				continue
			var instance: Variant = n3.get("instance")
			var label := str(n3.get("species_id"))
			if instance != null:
				label = "%s  (L%d)" % [str(instance.get("display_name")), int(instance.get("level"))]
			out.append({"key": n3.get_instance_id(), "at": at, "what": "wild    %s" % label})
		elif script_path.ends_with("harvest_node.gd"):
			# `_item_id`, with the underscore: harvest_node.gd keeps it
			# private and exposes no getter, and `get("item_id")` returns
			# null rather than erroring -- which is how the first cut of this
			# probe printed a column of "gather <null>" and still looked like
			# it was working.
			out.append({"key": n3.get_instance_id(), "at": at,
				"what": "gather  %s" % str(n3.get("_item_id"))})
	return out


## Prompt 62: "Bridge progression must be physical/story/trainer based, never
## arbitrary level-lock UI." Reported rather than asserted -- this is an
## evidence probe, and the assertion belongs in a test.
func _report_gate(world: Node) -> void:
	print("")
	var bridge: Node = null
	for node: Variant in _all(world):
		var n := node as Node
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("south_bridge.gd"):
			bridge = n
			break
	if bridge == null:
		print("south bridge: NOT FOUND in the scene")
		return
	print("south bridge: present as %s" % bridge.name)
	if bridge.has_method("is_open"):
		print("  open without the key: %s  (false is the correct answer)" % str(bridge.call("is_open")))


## No default `into: Array = []` parameter here, deliberately. GDScript
## evaluates a default array argument ONCE and shares that same instance
## across every call, exactly like Python -- so a second `_all(world)` in the
## same run returns the first call's contents with the whole tree appended
## again. This probe called it twice and the second list came back doubled
## and reordered, which is how a trainer that is demonstrably standing in the
## world went missing from one report and not the other.
func _all(node: Node) -> Array:
	var out: Array = []
	_collect_all(node, out)
	return out


func _collect_all(node: Node, into: Array) -> void:
	into.append(node)
	for c in node.get_children():
		_collect_all(c, into)
