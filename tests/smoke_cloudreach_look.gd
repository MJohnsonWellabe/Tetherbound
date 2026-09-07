extends SceneTree

## CLOUDREACH-LOOK-0906 smoke. Builds the real Cloudreach scene (same harness
## as smoke_cloudreach_foundation.gd), mounts scripts/world/cloudreach_look.gd
## directly against the built world -- exactly what
## cloudreach_world_runtime.gd::mount() does in production, without pulling in
## the combat/encounter/Game-singleton machinery a full mount() needs -- and
## checks the owner's 2026-09-06 addendum landed: rope rails on every bridge
## edge, mooring lines on every floating region/fly-only-destination/aerie/
## perches, a second raycast-placed ground-cover layer that actually plants
## tufts on region tops and landing pads, trees on every region top, and
## cliffside settlement materials that no longer match the Meadows village.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const LOOK := preload("res://scripts/world/cloudreach_look.gd")

# The Meadows house kit's own authored roof retint (cottage_a's "MI_RoundTiles"
# -> #8a6448 in data/config/building_prefabs.json) -- the value the cliffside
# settlement's roofs verbatim-reused before this pass. This pass's own roof
# colour must differ from it.
const MEADOWS_ROOF_COLOUR := Color("#8a6448")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 8:
		await physics_frame

	var look := LOOK.new()
	look.name = "CloudreachLook"
	world.add_child(look)
	look.call("dress", world)
	for _frame in 2:
		await physics_frame

	var failures: Array[String] = []
	var config_data: Dictionary = world.call("config_data")

	# 1. Bridge rope rails: every deck edge reaches >=2 rails.
	var rope_sides: Dictionary = look.call("bridge_rope_rail_sides")
	_expect(not rope_sides.is_empty(), "no bridge deck edges were dressed with rope rails", failures)
	for key: String in rope_sides.keys():
		_expect(int(rope_sides[key]) >= 2, "%s has fewer than 2 rope rails" % key, failures)
	_expect(int(look.call("bridge_post_count")) > 0, "no bridge rail posts were placed", failures)

	# 2. Mooring lines: every region plus the fly-only shrine/aerie/perches.
	var mooring: Dictionary = look.call("mooring_line_counts")
	_expect(mooring.size() == 9,
		"expected 9 moored islands (6 regions + shrine + aerie + perches), got %d" % mooring.size(), failures)
	for label: String in mooring.keys():
		_expect(int(mooring[label]) >= 2, "%s has fewer than 2 mooring lines" % label, failures)

	# 3. Ground cover finish: every region top and a settlement landing area
	# actually received raycast-placed tufts (the first, flat-height layer's
	# own bug was near-total loss over most of the crown).
	var cover_total := int(look.call("cover_finish_total_count"))
	_expect(cover_total > 0, "ground cover finish planted nothing at all", failures)
	for raw: Variant in config_data.get("regions", []):
		var spec: Dictionary = raw
		var pos := _vec3(spec.get("position", []))
		var near := int(look.call("cover_finish_count_near", pos, 220.0))
		_expect(near > 0, "region '%s' top has no finished ground cover near it" % str(spec.get("id", "")), failures)
	var transition_points: Dictionary = config_data.get("transition_points", {})
	for landing_id: String in transition_points.keys():
		var spec: Dictionary = transition_points[landing_id]
		var pos := _vec3(spec.get("position", []))
		var near := int(look.call("cover_finish_count_near", pos, 30.0))
		_expect(near > 0, "landing pad '%s' has no finished ground cover near it" % landing_id, failures)

	# 4. Trees: >=3 per region top.
	for raw: Variant in config_data.get("regions", []):
		var spec: Dictionary = raw
		var pos := _vec3(spec.get("position", []))
		var nearby := int(look.call("tree_count_near", pos, 220.0))
		_expect(nearby >= 3, "region '%s' top has fewer than 3 dressed trees (%d)" % [str(spec.get("id", "")), nearby], failures)

	# 5. Settlement materials differ from the Meadows village.
	_expect(int(look.call("settlement_material_override_count")) > 0,
		"no settlement building materials were overridden", failures)
	var roof_colour: Color = look.call("settlement_roof_colour")
	_expect(roof_colour != MEADOWS_ROOF_COLOUR,
		"cliffside settlement roof colour still matches the Meadows village roof colour", failures)
	_expect(int(look.call("settlement_guy_rope_count")) > 0, "no settlement guy ropes were added", failures)

	if failures.is_empty():
		var grid: Dictionary = look.call("cover_fill_grid")
		print("  turf fill: %d turf surfaces, %d triangles, %d m2 of turf; %d plantable, %d tufts at density x%.2f, %d ms" % [
			int(grid.get("surfaces", 0)), int(look.call("cover_fill_cell_count")),
			int(grid.get("turf_area_m2", 0)), int(grid.get("turf_triangles", 0)),
			int(look.call("cover_fill_count")), float(grid.get("density_scale", 1.0)),
			int(look.call("cover_fill_msec"))])
		print(("CLOUDREACH LOOK OK bridges_rails=%d posts=%d moorings=%d cover_main=%d cover_far=%d " +
			"cover_alpine=%d cover_fill=%d trees=%d stones=%d settlement_overrides=%d guy_ropes=%d") % [
			rope_sides.size(), int(look.call("bridge_post_count")), mooring.size(),
			int(look.call("cover_finish_main_count")), int(look.call("cover_finish_far_count")),
			int(look.call("cover_finish_alpine_count")), int(look.call("cover_fill_count")),
			int(look.call("tree_count")), int(look.call("stone_count")),
			int(look.call("settlement_material_override_count")), int(look.call("settlement_guy_rope_count"))])
		quit(0)
		return
	for failure: String in failures:
		push_error("CLOUDREACH LOOK: %s" % failure)
	quit(1)


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
