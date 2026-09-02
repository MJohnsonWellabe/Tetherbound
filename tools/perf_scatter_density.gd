extends SceneTree

## T1-PERF (2026-08-30). docs/specs/PERFORMANCE_BUDGET.md needs a real scatter
## density number ("per hectare") and nothing in the repo derives one --
## `ralph/PERF_ROG_REPORT.md` and `HALL_DESIGN_2026-08-30.md` both report raw
## placement counts, never an area-normalised density.
##
## Correct headless: --headless (no RenderingServer numbers are read here,
## unlike perf_render_stats.gd / perf_site_survey.gd, so the Dummy driver's
## zeroed RENDER_* monitors do not matter and the render-driver trap in
## docs/AGENT_WORKFLOW.md does not apply).
##
##   godot --headless --path . --script tools/perf_scatter_density.gd
##
## METHOD. `vegetation.gd::_instance_positions` (mesh_id -> PackedVector3Array,
## documented at its own declaration as "every position that mesh was
## instanced at") is the one place every scattered placement's real position
## lives -- `stats()` reports counts only. Read via `Object.get()`, the same
## reflection `tools/perf_profile.gd` already uses for `_wild_creatures`,
## because this tool has no more business adding a positions-dump accessor to
## gameplay code than that one did.
##
## Placements are binned into the five authored bands by
## `world_perimeter.gd`'s own BAND*_Z1 boundaries (village is everything
## north of band 1's start), and each band's AREA is the bounding box that
## actually CONTAINS its placements (band length along z, measured x-spread
## of the placements themselves) -- not an assumed corridor width, which is
## nowhere authored as a single number (MEADOWS_MACRO_LAYOUT.md says width
## "can be significantly less" than any quoted figure and varies with how the
## trail branches). This measures the footprint scatter actually occupies,
## which is what a density-per-hectare budget line needs; it is NOT the same
## as "hectares of Meadows terrain", which would need the authored trail
## polygons this tool does not have loaded. Stated as measured-footprint
## density, not corridor density, throughout the printed report.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const HECTARE_M2 := 10000.0

## world_perimeter.gd's own boundaries, copied rather than autoloaded (the
## constants are file-private consts on a Node script, not a singleton this
## tool can cheaply instance headless without the rest of the perimeter
## machinery).
const BAND1_Z1 := 1360.0
const BAND2_Z1 := 3180.0
const BAND3_Z1 := 4760.0
const BAND4_Z1 := 7000.0
## Stronghold/Hall site sits at z ~7548-7677 (HALL_DESIGN_2026-08-30.md §2);
## anything between band 4's end and there is "band 5", the approach corridor.
const STRONGHOLD_Z1 := 7548.0

const BANDS := ["village", "band1", "band2", "band3", "band4", "band5", "stronghold"]

## Same x/z as `tools/perf_profile.gd::SITES` (band5/stronghold match this
## tool's own band boundaries and `perf_site_survey.gd`'s band5/stronghold
## views) -- the whole-band bounding-box density above is diluted by empty
## terrain at the authored width's edges (measured x-spread came back ~2047m
## for every band, i.e. the full world width, not a walked corridor), so this
## adds a LOCAL density at the exact points the other two tools already
## sample: placements within LOCAL_RADIUS_M of that point, over a circle of
## that radius. This is what the player actually sees/walks through; the
## whole-band number above is an honest but much coarser upper-terrain
## average and is kept for its own reproducibility.
const LOCAL_RADIUS_M := 60.0
const LOCAL_SITES := {
	"village": Vector2(10.0, -10.0),
	"band1": Vector2(0.0, 700.0),
	"band2": Vector2(0.0, 2200.0),
	"band3": Vector2(0.0, 4000.0),
	"band4": Vector2(0.0, 6000.0),
	"band5": Vector2(0.0, 7160.0),
	"stronghold": Vector2(0.0, 7420.0),
}

func _init() -> void:
	_run()


func _band_for_z(z: float) -> String:
	if z < 0.0:
		return "village"
	if z < BAND1_Z1:
		return "band1"
	if z < BAND2_Z1:
		return "band2"
	if z < BAND3_Z1:
		return "band3"
	if z < BAND4_Z1:
		return "band4"
	if z < STRONGHOLD_Z1:
		return "band5"
	return "stronghold"


func _run() -> void:
	print("=== T1-PERF scatter density by band (measured footprint) ===")
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		print("FAIL: no Vegetation node")
		quit(1)
		return

	var raw: Variant = vegetation.get("_instance_positions")
	if not (raw is Dictionary):
		print("FAIL: vegetation._instance_positions not readable as Dictionary (got %s)" % typeof(raw))
		quit(1)
		return
	var positions: Dictionary = raw

	var count: Dictionary = {}
	var minx: Dictionary = {}
	var maxx: Dictionary = {}
	var minz: Dictionary = {}
	var maxz: Dictionary = {}
	for b in BANDS:
		count[b] = 0
		minx[b] = INF
		maxx[b] = -INF
		minz[b] = INF
		maxz[b] = -INF

	var local_count: Dictionary = {}
	for b in LOCAL_SITES.keys():
		local_count[b] = 0

	var total := 0
	for mesh_id: Variant in positions.keys():
		var arr: PackedVector3Array = positions[mesh_id]
		for p: Vector3 in arr:
			total += 1
			var b := _band_for_z(p.z)
			count[b] = int(count[b]) + 1
			minx[b] = minf(minx[b], p.x)
			maxx[b] = maxf(maxx[b], p.x)
			minz[b] = minf(minz[b], p.z)
			maxz[b] = maxf(maxz[b], p.z)
			for site_name: String in LOCAL_SITES.keys():
				var at: Vector2 = LOCAL_SITES[site_name]
				if Vector2(p.x, p.z).distance_to(at) <= LOCAL_RADIUS_M:
					local_count[site_name] = int(local_count[site_name]) + 1

	print("total scattered placements with a recorded position: %d" % total)
	print("")
	print("%-12s %10s %12s %10s %14s %16s" % [
		"band", "count", "x-spread m", "z-run m", "footprint ha", "density /ha"])
	var summary: Array = []
	for b in BANDS:
		var c: int = count[b]
		if c == 0:
			print("%-12s %10d   (no placements in this band)" % [b, c])
			continue
		var xs: float = maxf(1.0, float(maxx[b]) - float(minx[b]))
		var zs: float = maxf(1.0, float(maxz[b]) - float(minz[b]))
		var ha: float = (xs * zs) / HECTARE_M2
		var density: float = float(c) / ha
		print("%-12s %10d %12.1f %10.1f %14.3f %16.1f" % [b, c, xs, zs, ha, density])
		summary.append({"band": b, "count": c, "x_spread_m": xs, "z_run_m": zs, "footprint_ha": ha, "density_per_ha": density})

	print("")
	print("NOTE: 'footprint ha' is the bounding box of this band's OWN placements,")
	print("not an authored corridor width (none exists as a single number -- see")
	print("this file's header). A band whose scatter clusters in a few dense")
	print("clumps with wide empty gaps between will UNDER-state density here,")
	print("since the empty gaps still count toward the bounding box.")

	var local_ha: float = (PI * LOCAL_RADIUS_M * LOCAL_RADIUS_M) / HECTARE_M2
	print("")
	print("--- local density at the exact points perf_profile.gd/perf_site_survey.gd sample ---")
	print("(circle of radius %.0fm around each point, %.3f ha)" % [LOCAL_RADIUS_M, local_ha])
	print("%-12s %10s %16s" % ["site", "count", "density /ha"])
	for site_name: String in LOCAL_SITES.keys():
		var c: int = local_count[site_name]
		print("%-12s %10d %16.1f" % [site_name, c, float(c) / local_ha])

	quit(0)
