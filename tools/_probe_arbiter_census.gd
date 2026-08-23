extends SceneTree

## PERF-ROG / OP23-01. What is registered with the interaction arbiter, by
## owner, and what polling all of it costs -- which is what `main`'s
## `_recompute()` did every frame, and is the number OP23-01 turned out to be.
##
##   godot --headless --path . --script tools/_probe_arbiter_census.gd
##
## Kept rather than deleted with the fix, because the cost it measures is
## linear in scatter density and this is how the next density directive gets
## priced BEFORE it lands. Measured on the two bakes that exist today:
##
##   143,630 placements -> 24,461 providers -> 15.6-26.0 ms/frame
##   223,271 placements -> 37,438 providers -> 44.65 ms/frame
##
## `interaction_offer() on every one` is the old per-frame cost. The
## `position read + distance reject` row is the cheapest touch that could
## replace it -- 6.3ms at 143k, 16.0ms at 223k -- and is why the fix is a
## spatial index and not a cheaper inner loop.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE := 240


func _collapse(name: String) -> String:
	var out := ""
	var in_digits := false
	for i in name.length():
		var c := name[i]
		if c >= "0" and c <= "9":
			if not in_digits:
				out += "*"
				in_digits = true
		else:
			in_digits = false
			out += c
	return out


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE:
		await physics_frame
	var arbiter := world.get_node_or_null(^"InteractionArbiter")
	var providers: Array = arbiter.get("_providers")
	print("providers registered: %d" % providers.size())

	var by_script: Dictionary = {}
	var by_parent: Dictionary = {}
	for p: Variant in providers:
		var key := "(not a Node)"
		if p is Node:
			var scr: Script = (p as Node).get_script() as Script
			key = (scr.resource_path.get_file() if scr != null else (p as Node).get_class())
			var parent: Node = (p as Node).get_parent()
			var pk: String = "(none)" if parent == null else String(parent.name)
			# Collapse numbered siblings: Harvest_grass_00417 -> Harvest_grass_*
			pk = _collapse(pk)
			by_parent[pk] = int(by_parent.get(pk, 0)) + 1
		else:
			key = (p as Object).get_class()
		by_script[key] = int(by_script.get(key, 0)) + 1

	print("\nby script:")
	for k: String in by_script.keys():
		print("  %-40s %6d" % [k, by_script[k]])
	print("\nby parent name (numbers collapsed), top 20:")
	var names := by_parent.keys()
	names.sort_custom(func(a, b): return int(by_parent[a]) > int(by_parent[b]))
	for i in mini(20, names.size()):
		print("  %-40s %6d" % [names[i], by_parent[names[i]]])

	# What one offer call costs, isolated from the arbiter's own loop.
	var player: Node3D = world.get_node_or_null(^"Player")
	var from: Vector3 = player.global_position
	var t0 := Time.get_ticks_usec()
	for p: Variant in providers:
		if p != null and is_instance_valid(p as Object):
			(p as Object).call("interaction_offer", from)
	var offers_ms := (Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	var copy: Array = providers.duplicate()
	var dup_ms := (Time.get_ticks_usec() - t0) / 1000.0
	# The cheapest possible per-provider touch, for comparison: a position read
	# and a squared-distance reject, no method call at all.
	t0 = Time.get_ticks_usec()
	var near := 0
	for p: Variant in providers:
		if p is Node3D and (p as Node3D).global_position.distance_squared_to(from) < 36.0:
			near += 1
	var cheap_ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("\nper-frame cost breakdown, %d providers:" % providers.size())
	print("  _providers.duplicate()            %7.3f ms" % dup_ms)
	print("  interaction_offer() on every one  %7.3f ms" % offers_ms)
	print("  position read + distance reject   %7.3f ms  (%d within 6m)" % [cheap_ms, near])
	quit(0)
