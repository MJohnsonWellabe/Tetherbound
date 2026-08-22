extends Node3D

## BAND5-CONTENT, prompt 66's environmental storytelling clause: "the player
## should increasingly understand that the land is being affected by the tether
## system before entering the Hall", using "existing machinery, drained-ground/
## healing systems and faction language rather than inventing unrelated lore."
##
## WHAT WAS ACTUALLY MISSING. `terrain_playground.json`'s `drains.stations` --
## the authority for drained ground in the whole chapter -- holds seven entries:
## four at the quarry (z~1790) and three at the relay (z~3749). There is not one
## anywhere in Band 5. So the worst ground in the Meadows was 3.7km BEHIND the
## machine causing it, and the last 680m, the approach to the source itself, was
## clean meadow with a castle on the skyline. The drain got weaker as the player
## walked toward the thing doing the draining.
##
## WHY THIS IS A SEPARATE NODE and not a method on `stronghold.gd`. The fade is
## driven from `_process`, and `stronghold.gd::_process` already runs the door
## sync -- a healing routine calling `set_process(false)` there would silently
## stop the stronghold's own shutter from tracking its flag. `tether_relay.gd`
## can hold both because it has only the one process loop. This does not, so the
## skin owns its own node, which is also what lets it hang off the WORLD's
## unrotated frame rather than the stronghold's yawed one.
##
## HOW MUCH OF THE EFFECT THIS IS. Two halves, and this is honest about owning
## only one. `scatter_rules.gd` reads `drains` at RUN TIME, so vegetation thins
## out the moment a station exists; the ground's COLOUR is baked into the
## terrain's colour and control maps and needs a re-bake. This skin stands in
## for the baked half exactly as `tether_relay.gd::_build_dead_ground` does, and
## for the same stated reason -- its alpha IS `drain_factor()`, so it dies out
## on precisely the contour the bake will, and it is paint: no collider, no
## layer, shadows off.
##
## IT RENDERS NOTHING UNTIL THE STATIONS EXIST, deliberately. `drain_factor()`
## returns 0.0 everywhere with no station in range, every quad is skipped, and
## this builds an empty node and says so. `terrain_playground.json` is a file no
## Gate D lane may edit (`ralph/GATE_D_LANE_CONTRACT.md` §5 -- editing it forces
## a ~60s single-threaded re-bake that cannot be run concurrently by five
## lanes), so the stations are REQUESTED in this lane's report, the same way a
## `density_scale` is. This is built now rather than after, so that the request
## is one edit to one file and not an edit plus a code change.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var _skin: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _healing := false
var _healed := false
var _heal_seconds := 0.0
var _heal_elapsed := 0.0
var _quads := 0


## `world` is only ever asked for `ground_height_at` -- the same duck-typed
## climb `old_quarry.gd` and `severed_spokes.gd` use (D09: never a raycast for
## ground).
func build(world: Node3D, config: Dictionary) -> void:
	if not bool(config.get("enabled", true)):
		return
	var field: RefCounted = HEIGHTFIELD.new()
	if not field.has_method("drain_factor"):
		return
	var bounds: Array = config.get("bounds", [])
	if bounds.size() < 4:
		push_warning("approach_drain has no `bounds`; the approach paints no drained ground")
		return
	var min_x := float(bounds[0])
	var min_z := float(bounds[1])
	var max_x := float(bounds[2])
	var max_z := float(bounds[3])
	var cell := maxf(float(config.get("cell", 4.0)), 1.0)
	var lift := float(config.get("lift", 0.09))
	var tint := Color(str(config.get("tint", "#a89d84")))
	var max_alpha := clampf(float(config.get("max_alpha", 0.72)), 0.0, 1.0)

	var cols := int(ceil((max_x - min_x) / cell))
	var rows := int(ceil((max_z - min_z) / cell))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in cols:
		for j in rows:
			var quad: Array = []
			var any := false
			for corner: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0),
					Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
				var x := min_x + (float(i) + corner.x) * cell
				var z := min_z + (float(j) + corner.y) * cell
				var ground := float(world.call("ground_height_at", x, z))
				if is_nan(ground):
					quad.clear()
					break
				var alpha := float(field.call("drain_factor", x, z)) * max_alpha
				if alpha > 0.01:
					any = true
				quad.append([Vector3(x, ground + lift, z), alpha])
			if quad.size() < 4 or not any:
				continue
			for triangle: Array in [[0, 1, 2], [0, 2, 3]]:
				for index: int in triangle:
					var point: Array = quad[index]
					surface.set_color(Color(tint.r, tint.g, tint.b, float(point[1])))
					surface.add_vertex(point[0] as Vector3)
			_quads += 1
	if _quads == 0:
		# The expected state until `drains.stations` carries a Band 5 entry --
		# see this file's header. Said out loud rather than passed over, because
		# "nothing rendered" and "nothing was asked for" look identical in a
		# capture and this project has lost hours to that difference before.
		print("[approach-drain] no drained ground on the approach: drain_factor() is 0 across the corridor (terrain_playground.json `drains.stations` has no Band 5 entry)")
		return
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	var skin := MeshInstance3D.new()
	skin.name = "ApproachDeadGround"
	skin.mesh = surface.commit()
	skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skin)
	_skin = skin
	_material = material
	print("[approach-drain] %d drained quads over the approach corridor" % _quads)


## The same contract `tether_relay.gd` answers, and found the same way:
## `meadow_healing.gd::_fade_the_drain_skins` walks the world for any node with
## BOTH of these methods, so the drain network dying at the Warden fades this
## with the relay's without either file naming the other. `seconds <= 0` snaps,
## for a save loaded with the flag already set.
func heal(seconds: float = 0.0) -> void:
	if _skin == null or not is_instance_valid(_skin):
		return
	if _healing:
		return
	if seconds <= 0.0:
		_finish_healing()
		return
	_healing = true
	_heal_seconds = seconds
	_heal_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	if not _healing:
		set_process(false)
		return
	_heal_elapsed += delta
	var fraction := clampf(_heal_elapsed / maxf(_heal_seconds, 0.01), 0.0, 1.0)
	if _material != null:
		# The material's own albedo alpha MULTIPLIES the per-vertex alpha the
		# drain contour is stored in, so the skin pales preserving its shape
		# rather than shrinking to a rectangle.
		_material.albedo_color.a = 1.0 - fraction
	if fraction >= 1.0:
		_finish_healing()


func _finish_healing() -> void:
	_healing = false
	set_process(false)
	if _material != null:
		_material.albedo_color.a = 0.0
	if _skin != null and is_instance_valid(_skin):
		_skin.visible = false
	_healed = true


func dead_ground_visible() -> bool:
	return _skin != null and is_instance_valid(_skin) and _skin.visible \
		and (_material == null or _material.albedo_color.a > 0.01)


func healed() -> bool:
	return _healed


## For tests and capture tools, so neither counts vertices to find out whether
## the corridor painted anything.
func quads() -> int:
	return _quads
