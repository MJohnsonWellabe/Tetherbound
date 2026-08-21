extends Node3D

## EV5 — the Meadows water layer (bible §15): the pond, its inflow stream,
## and the reeds standing at their banks.
##
## Composed at runtime from config, like every other layer of the playground.
## Geometry truth lives in data/config/terrain_playground.json's `water`
## block — the heightfield carves the stream channel from it and the bake
## paints the wet bed from it — while this file reads the same block to put
## the visible surface exactly where the ground already expects water to be.
## Presentation (colours, foam, waves, reeds) is data/config/water.json.
##
## The surface is deliberately cheap: a trimmed flat grid for the pond, a
## ribbon for the stream, one shared ShaderMaterial (shaders/water.gdshader)
## whose per-pixel depth comes from a heightfield texture baked right here at
## build time. No simulation, no reflection probe, no depth-texture readback
## — see the shader's own header for why that last one is off the table on
## this project's gl_compatibility renderer.
##
## No collision, on purpose. The pond is a basin in solid terrain: the player
## wades in and walks on the bed, exactly as the traversal smoke test walks
## everywhere else. Blocking the water's edge would invent a movement rule,
## and there is no swimming system to hand deep water to — the deepest point
## is ~3m, which submerges the trainer briefly if they insist. If that reads
## badly in play it is a design question for the owner, not something this
## composer should quietly legislate with an invisible wall.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CONFIG_PATH := "res://data/config/water.json"
const SHADER := preload("res://shaders/water.gdshader")

## Resolution of the baked terrain-height texture the shader reads depth
## from. 512 over a ~150m region is ~0.3m per texel — finer than the mesh
## grid, coarse enough to bake in well under a second.
const HEIGHT_MAP_SIZE := 512

## Reeds sink deeper than vegetation.gd's 0.06: a tuft mesh has a visible
## flat base, and on a bank slope at the waterline that base showed as a
## floating plate (blind round 1). Shin-deep burial hides it at every angle
## this shore's slopes produce.
const REED_SINK := 0.14

var _field: RefCounted = null
var _water_cfg: Dictionary = {}
var _level: float = NAN

## PERF2. `_region()` is a ~2100-sample scan of the heightfield, and it was run
## twice — once for the material and again inside `_build_pond` — for an answer
## that cannot change between them. `terrain_playground.json` was likewise
## re-opened and re-parsed from disk four times in one build. Neither is a
## result cache with a staleness question: the config is read-only for the
## lifetime of a build, and the region is a pure function of it.
var _terrain_cfg: Dictionary = {}
var _region_cache := Rect2()
var _region_ready := false
var _stats := {
	"pond_quads": 0, "stream_points": 0, "reeds": 0,
	# EV5-remainder — the waterside dressing the blind rounds asked for.
	"marginals": 0, "bank_flowers": 0, "rocks": 0,
	"driftwood": 0, "lilypads": 0, "jetty_pieces": 0,
	# SE21 — the river is a second body of water in the same layer.
	"river_quads": 0, "river_reeds": 0, "river_scrub": 0,
}


func build() -> void:
	_field = HEIGHTFIELD.new()
	_water_cfg = _load_config()
	_level = float(_field.call("water_level"))
	if is_nan(_level):
		push_warning("terrain_playground.json has no water block; the meadow stays dry")
		return

	var terrain_cfg: Dictionary = _terrain_config()
	var stream: Dictionary = terrain_cfg.get("water", {}).get("stream", {})
	var pond_centre: Array = terrain_cfg.get("water", {}).get("pond_centre", [0.0, 0.0])

	var material := _build_material(_region())
	_build_pond(material)
	# The stream carries the same shader with more opaque water: at 0.35m
	# deep, a see-through surface is mostly its own carved, wet-darkened,
	# partly self-shadowed bed, which rendered as a dark strip against the
	# pond's bright shallows — blind rounds 1 and 2 both read them as two
	# different waters. Measured after round 3's shared-alpha attempt: same
	# hue family (192 vs 184) but half the value. A stylised stream is
	# nearly opaque, its colour carried by the surface, not the bed.
	var stream_material: ShaderMaterial = material.duplicate()
	var surface_cfg: Dictionary = _water_cfg.get("stream", {})
	stream_material.set_shader_parameter("alpha_shallow", float(surface_cfg.get("alpha_shallow", 0.78)))
	stream_material.set_shader_parameter("alpha_deep", 0.95)
	# EV5-remainder: the stream ribbon carries its own course parameterisation
	# in UV2, and only ITS material turns the shader's flow scroll on — the
	# pond plane never sets UV2 and keeps the default still-water drift.
	stream_material.set_shader_parameter("flow_enabled", true)
	stream_material.set_shader_parameter("flow_speed", float(surface_cfg.get("flow_speed", 1.1)))
	stream_material.set_shader_parameter("flow_stretch", float(surface_cfg.get("flow_stretch", 0.6)))
	_build_stream(stream_material, stream)

	_build_river()

	var centre := Vector2(float(pond_centre[0]), float(pond_centre[1]))
	# The shoreline fan is shared by every shore-anchored layer below —
	# computed once so they all agree about where the waterline is.
	var shore := _shoreline(centre)
	_build_shore_flora(shore, centre)
	_build_dressing(shore, centre)
	_build_jetty(centre)
	print("[water] pond quads %d, stream points %d, reeds %d, marginals %d, bank flowers %d, rocks %d, driftwood %d, lilypads %d, jetty %d, level %.1f" % [
		_stats["pond_quads"], _stats["stream_points"], _stats["reeds"],
		_stats["marginals"], _stats["bank_flowers"], _stats["rocks"], _stats["driftwood"],
		_stats["lilypads"], _stats["jetty_pieces"], _level
	])
	print("[water] river quads %d, bank reeds %d, bank scrub %d" % [
		_stats["river_quads"], _stats["river_reeds"], _stats["river_scrub"]
	])


func stats() -> Dictionary:
	return _stats


## The world-rect the height texture and the pond grid both cover: the pond's
## own below-water extent plus the whole stream course, padded. Derived from
## the data rather than configured, so retuning the level or the course can
## never silently crop the map that the shader reads depth from.
func _region() -> Rect2:
	if _region_ready:
		return _region_cache
	_region_ready = true
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var water: Dictionary = _terrain_config().get("water", {})
	var centre: Array = water.get("pond_centre", [0.0, 0.0])
	var c := Vector2(float(centre[0]), float(centre[1]))
	# Coarse scan around the pond centre for terrain below the waterline.
	for z in range(int(c.y) - 90, int(c.y) + 91, 4):
		for x in range(int(c.x) - 90, int(c.x) + 91, 4):
			if float(_field.call("height_at", float(x), float(z))) < _level:
				lo = Vector2(minf(lo.x, x), minf(lo.y, z))
				hi = Vector2(maxf(hi.x, x), maxf(hi.y, z))
	for entry: Variant in water.get("stream", {}).get("points", []):
		var p := Vector2(float(entry[0]), float(entry[1]))
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	if lo.x > hi.x:
		# No submerged terrain found at all — fall back to a small rect at the
		# configured centre so the composer degrades visibly, not by crashing.
		push_warning("no terrain below water level %.1f near pond centre; is the level above the basin floor?" % _level)
		lo = c - Vector2(20, 20)
		hi = c + Vector2(20, 20)
	var margin := float(_water_cfg.get("pond", {}).get("margin", 6.0))
	lo -= Vector2(margin, margin)
	hi += Vector2(margin, margin)
	_region_cache = Rect2(lo, hi - lo)
	return _region_cache


## `terrain_playground.json`, parsed once per composer.
func _terrain_config() -> Dictionary:
	if _terrain_cfg.is_empty():
		_terrain_cfg = HEIGHTFIELD.load_config()
	return _terrain_cfg


## The shared water material, baked over ONE world rect. Taken as an argument
## rather than read from `_region()` because SE21's river is a second body of
## water somewhere else entirely: the shader decodes depth from a height
## texture covering its own `region`, and a river surface handed the pond's
## rect would read every one of its texels as clamped ceiling and render deep
## navy water over a phantom chasm — the exact failure this function's
## `height_min`/`height_max` comment already records once.
func _build_material(region: Rect2) -> ShaderMaterial:
	var surface: Dictionary = _water_cfg.get("surface", {})

	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))

	# Normalised over the REGION'S OWN height range, never a fixed window
	# around the water level. The first version used level ±8m, and the
	# stream's course climbs ~20m above the pond — every texel above the
	# window clamped to its ceiling, the shader decoded ground 5m under the
	# actual bed, and the upper stream rendered as deep navy water over a
	# phantom chasm. Found by replicating the shader's lookup on the CPU
	# after two blind critics called the stream "a different water" and no
	# amount of colour tuning moved it: the tuning was fine, the depth was
	# lying. Scan first, window second.
	var height_min := INF
	var height_max := -INF
	for z in range(int(region.position.y), int(region.end.y) + 1, 4):
		for x in range(int(region.position.x), int(region.end.x) + 1, 4):
			var h := float(_field.call("height_at", float(x), float(z)))
			height_min = minf(height_min, h)
			height_max = maxf(height_max, h)
	height_min -= 1.0
	height_max += 1.0
	material.set_shader_parameter("terrain_height", _bake_height_texture(region, height_min, height_max))
	material.set_shader_parameter("height_min", height_min)
	material.set_shader_parameter("height_max", height_max)

	material.set_shader_parameter("deep_colour", Color(str(surface.get("deep_colour", "#1d5261"))))
	material.set_shader_parameter("shallow_colour", Color(str(surface.get("shallow_colour", "#7ab08e"))))
	material.set_shader_parameter("depth_falloff", float(surface.get("depth_falloff", 1.6)))
	material.set_shader_parameter("alpha_deep", float(surface.get("alpha_deep", 0.88)))
	material.set_shader_parameter("alpha_shallow", float(surface.get("alpha_shallow", 0.42)))
	material.set_shader_parameter("edge_feather", float(surface.get("edge_feather", 0.1)))
	material.set_shader_parameter("foam_colour", Color(str(surface.get("foam_colour", "#ebf1ec"))))
	material.set_shader_parameter("foam_depth", float(surface.get("foam_depth", 0.3)))
	material.set_shader_parameter("foam_scale", float(surface.get("foam_scale", 0.14)))
	material.set_shader_parameter("foam_speed", float(surface.get("foam_speed", 0.03)))
	material.set_shader_parameter("wave_uv_scale", float(surface.get("wave_uv_scale", 0.09)))
	material.set_shader_parameter("wave_speed", float(surface.get("wave_speed", 0.016)))
	material.set_shader_parameter("wave_strength", float(surface.get("wave_strength", 0.35)))
	material.set_shader_parameter("fresnel_colour", Color(str(surface.get("fresnel_colour", "#b9c8cf"))))
	material.set_shader_parameter("fresnel_power", float(surface.get("fresnel_power", 4.0)))
	material.set_shader_parameter("fresnel_strength", float(surface.get("fresnel_strength", 0.65)))
	material.set_shader_parameter("roughness_value", float(surface.get("roughness", 0.12)))

	material.set_shader_parameter("wave_normal_a", _noise_normal(11, 0.05))
	material.set_shader_parameter("wave_normal_b", _noise_normal(12, 0.09))
	material.set_shader_parameter("foam_noise", _noise_plain(13, 0.11))
	return material


## The shader's depth source: the baked heightfield sampled over `region`,
## normalised. Generated here rather than shipped as an asset because it is
## a pure function of data already in the repo — committing it would just
## be a cache that silently rots when the terrain config changes.
##
## FORMAT_RF, not R8: the first render used R8, whose 16 metres over 256
## steps is 6.3cm height quanta — and on a bank sloping a few degrees one
## quantum spans over a metre of ground, so the foam band's depth threshold
## crossed in metre-wide contour steps and the whole shoreline rendered as
## a hard white staircase. Float costs 1MB once and removes the artefact at
## its source. (This build targets desktop GL, where linear filtering of
## float textures is universal.)
func _bake_height_texture(region: Rect2, height_min: float, height_max: float) -> ImageTexture:
	var image := Image.create_empty(HEIGHT_MAP_SIZE, HEIGHT_MAP_SIZE, false, Image.FORMAT_RF)
	var span := maxf(height_max - height_min, 0.001)
	for py in HEIGHT_MAP_SIZE:
		var wz := region.position.y + (float(py) + 0.5) / HEIGHT_MAP_SIZE * region.size.y
		for px in HEIGHT_MAP_SIZE:
			var wx := region.position.x + (float(px) + 0.5) / HEIGHT_MAP_SIZE * region.size.x
			var h := float(_field.call("height_at", wx, wz))
			image.set_pixel(px, py, Color(clampf((h - height_min) / span, 0.0, 1.0), 0.0, 0.0))
	return ImageTexture.create_from_image(image)


## Procedural scrolling-wave normal map. FastNoiseLite via NoiseTexture2D,
## seamless so the scroll never shows a tile seam — no sourced asset, nothing
## to ledger, and the same texture is reproducible from this code alone.
func _noise_normal(noise_seed: int, frequency: float) -> NoiseTexture2D:
	var texture := _noise_plain(noise_seed, frequency)
	texture.as_normal_map = true
	texture.bump_strength = 6.0
	return texture


func _noise_plain(noise_seed: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.frequency = frequency
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.seamless = true
	texture.width = 256
	texture.height = 256
	return texture


## The pond: a flat grid at the water level, keeping only quads that touch
## water. The mesh edge is never the shoreline — the shader feathers alpha to
## zero exactly where depth reaches zero — so the grid just has to reach past
## the shore everywhere, which "any corner within half a metre of waterline
## height" comfortably guarantees at 2m cells.
func _build_pond(material: ShaderMaterial) -> void:
	var region := _region()
	var step := maxf(float(_water_cfg.get("pond", {}).get("grid_step", 2.0)), 0.5)
	var cols := int(ceil(region.size.x / step))
	var rows := int(ceil(region.size.y / step))

	# Candidate cells: any corner near or below the waterline (0.5m margin
	# keeps the shader's feathered shoreline inside kept geometry). Then a
	# flood fill from the pond centre keeps only the basin's own connected
	# component: without it, every dip under `level + 0.5` anywhere in the
	# region grew a plate — the carved stream channel collected a chain of
	# them, and blind round 4 found their exposed edges as "orphaned quads"
	# and an angular sliver poking over a bank.
	var wet_cells: Dictionary = {}
	for row in rows:
		var z0 := region.position.y + row * step
		for col in cols:
			var x0 := region.position.x + col * step
			for corner: Vector2 in [
				Vector2(x0, z0), Vector2(x0 + step, z0),
				Vector2(x0, z0 + step), Vector2(x0 + step, z0 + step)
			]:
				if float(_field.call("height_at", corner.x, corner.y)) < _level + 0.5:
					wet_cells[Vector2i(col, row)] = true
					break

	var terrain_cfg: Dictionary = _terrain_config()
	var centre: Array = terrain_cfg.get("water", {}).get("pond_centre", [0.0, 0.0])
	var seed_cell := Vector2i(
		int((float(centre[0]) - region.position.x) / step),
		int((float(centre[1]) - region.position.y) / step)
	)
	var kept: Dictionary = {}
	if wet_cells.has(seed_cell):
		var frontier: Array[Vector2i] = [seed_cell]
		kept[seed_cell] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for offset: Vector2i in [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
			]:
				var next := cell + offset
				if wet_cells.has(next) and not kept.has(next):
					kept[next] = true
					frontier.append(next)
	else:
		push_warning("pond centre cell is not below the waterline; keeping every wet cell unfiltered")
		kept = wet_cells

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads := 0
	for cell: Vector2i in kept.keys():
		var x0 := region.position.x + cell.x * step
		var z0 := region.position.y + cell.y * step
		_add_quad(tool,
			Vector3(x0, _level, z0), Vector3(x0 + step, _level, z0),
			Vector3(x0 + step, _level, z0 + step), Vector3(x0, _level, z0 + step))
		quads += 1
	if quads == 0:
		push_warning("pond mesh has no quads; water level %.1f never dips below terrain" % _level)
		return
	tool.generate_tangents()
	var node := MeshInstance3D.new()
	node.name = "PondSurface"
	node.mesh = tool.commit()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_stats["pond_quads"] = quads


## SE21 — the river: one flat sheet of water lying in the channel
## `playground_heightfield._river_carve` cuts, from the ridge in the north to
## the ring in the south.
##
## FLAT, like the pond, and not a descending ribbon like the stream. The
## ribbon's height is clamped monotone non-increasing, which is right for a
## 90m brook probed downhill; this course is 340m across ground that swings
## 27m, and no monotone surface can lie in it without either floating over a
## bank or sinking under the bed. The channel is authored to hold one level
## instead (the config's own `_comment_depths` is the arithmetic), so the
## river gets the pond's mechanism: one height, and the shader's per-pixel
## depth does the rest.
##
## It is still built as a RIBBON rather than the pond's trimmed grid, because
## the grid's flood fill needs a seed cell and a basin, and this water's own
## bbox contains two things that are also below its level and are not it (the
## storm ravine's floor and, at the south end, open low meadow). Walking the
## course and finding the waterline outward from the centreline can only ever
## produce water that is in the river.
func _build_river() -> void:
	var terrain_cfg: Dictionary = _terrain_config()
	var river: Dictionary = terrain_cfg.get("river", {})
	var course: Array = river.get("course", [])
	if course.size() < 2 or not river.has("water_level"):
		return
	var level := float(river.get("water_level"))
	var cfg: Dictionary = _water_cfg.get("river", {})
	var step := maxf(float(cfg.get("sample_step", 4.0)), 1.0)

	# Resample the authored course evenly, and carry the local channel reach
	# with each sample so the waterline search never has to guess how wide
	# this reach of the river is.
	var samples: Array[Vector2] = []
	var reaches: Array[float] = []
	for i in course.size() - 1:
		var a: Dictionary = course[i]
		var b: Dictionary = course[i + 1]
		var pa := _vec2(a.get("at", []))
		var pb := _vec2(b.get("at", []))
		var count := maxi(1, int(pa.distance_to(pb) / step))
		for s in count:
			var t := float(s) / count
			samples.append(pa.lerp(pb, t))
			reaches.append(
				lerpf(float(a.get("half_width", 9.0)), float(b.get("half_width", 9.0)), t)
				+ lerpf(float(a.get("rim", 5.0)), float(b.get("rim", 5.0)), t))
	samples.append(_vec2((course[course.size() - 1] as Dictionary).get("at", [])))
	reaches.append(float((course[course.size() - 1] as Dictionary).get("half_width", 9.0))
		+ float((course[course.size() - 1] as Dictionary).get("rim", 5.0)))

	# Half-widths of actual WATER at each station: outward from the
	# centreline until the ground climbs past the level. Negative means the
	# bed itself is above the level — the dry gorge at the north end — and
	# those stations carry no surface at all.
	var left: Array[float] = []
	var right: Array[float] = []
	var bank_points: Array[Vector2] = []
	for i in samples.size():
		var p := samples[i]
		var across := _river_across(samples, i)
		if float(_field.call("height_at", p.x, p.y)) >= level:
			left.append(-1.0)
			right.append(-1.0)
			continue
		var found: Array[float] = []
		for side: float in [-1.0, 1.0]:
			var d := 0.0
			var limit := reaches[i] + 3.0
			while d < limit:
				var q := p + across * (side * (d + 0.25))
				if float(_field.call("height_at", q.x, q.y)) >= level:
					break
				d += 0.25
			found.append(d)
			bank_points.append(p + across * (side * d))
		left.append(found[0])
		right.append(found[1])

	var region := _river_region(samples, reaches)
	var material: ShaderMaterial = _build_material(region).duplicate()
	# The river runs deep (6-9m through the middle reaches) and its bed is
	# raw cut earth rather than the pond's shallow silt, so it takes the
	# stream's more opaque shallow alpha: without it the whole channel reads
	# as its own dark bed seen through glass, which EV5 already measured once
	# and split the stream's alpha off for.
	material.set_shader_parameter("alpha_shallow", float(cfg.get("alpha_shallow", 0.7)))

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	var quads := 0
	for i in samples.size() - 1:
		var a := samples[i]
		var b := samples[i + 1]
		along += a.distance_to(b)
		if left[i] < 0.0 or left[i + 1] < 0.0:
			continue
		var across_a := _river_across(samples, i)
		var across_b := _river_across(samples, i + 1)
		# Half a metre of overshoot past the measured waterline on each side:
		# the shader feathers alpha to zero exactly where its depth reaches
		# zero, so the mesh edge must sit OUTSIDE the waterline or the water
		# ends in a hard cut short of the bank.
		var la := across_a * -(left[i] + 0.5)
		var ra := across_a * (right[i] + 0.5)
		var lb := across_b * -(left[i + 1] + 0.5)
		var rb := across_b * (right[i + 1] + 0.5)
		_add_quad(tool,
			Vector3(a.x + la.x, level, a.y + la.y),
			Vector3(a.x + ra.x, level, a.y + ra.y),
			Vector3(b.x + rb.x, level, b.y + rb.y),
			Vector3(b.x + lb.x, level, b.y + lb.y),
			# UV2 is the course parameterisation the shader scrolls its waves
			# along — the same flow trick the stream ribbon uses, so the
			# river visibly runs, downstream being the way the course is
			# authored (north, off the ridge, to the southern ring).
			[
				Vector2(along, -left[i]), Vector2(along, right[i]),
				Vector2(along + a.distance_to(b), right[i + 1]),
				Vector2(along + a.distance_to(b), -left[i + 1]),
			])
		quads += 1
	if quads == 0:
		push_warning("the river's bed never dips below its water level %.1f; no surface built" % level)
		return
	tool.generate_tangents()
	var node := MeshInstance3D.new()
	node.name = "RiverSurface"
	node.mesh = tool.commit()
	material.set_shader_parameter("flow_enabled", true)
	material.set_shader_parameter("flow_speed", float(cfg.get("flow_speed", 0.7)))
	material.set_shader_parameter("flow_stretch", float(cfg.get("flow_stretch", 0.7)))
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_stats["river_quads"] = quads

	# The banks. `R7.1-remainder-2`'s open question was whether water would do
	# more for the set's missing middle distance than more vegetation tuning;
	# the honest answer is that a bare cut with water in it still reads as a
	# trench from 150m out. What makes a river legible at that range is the
	# LINE of standing vegetation along it, so the same `_build_plant_band`
	# the pond's reeds use runs here twice against the river's own waterline
	# — a reed band at the water and a taller band up the bank — with the
	# bands themselves configured in water.json like everything else.
	var previous := _level
	_level = level
	_stats["river_reeds"] = _build_plant_band(cfg.get("reeds", {}), bank_points)
	_stats["river_scrub"] = _build_plant_band(cfg.get("bank_scrub", {}), bank_points)
	_level = previous


## The rect the river's height texture covers: its own channel, padded. Kept
## tight to the course rather than to the bbox of everything nearby, because
## the texture is a fixed number of texels however large the rect is and this
## river is 340m long — a rect stretched to the far corner of the map would
## halve the depth resolution of the water itself for nothing.
func _river_region(samples: Array[Vector2], reaches: Array[float]) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in samples.size():
		var pad := reaches[i] + 4.0
		lo = Vector2(minf(lo.x, samples[i].x - pad), minf(lo.y, samples[i].y - pad))
		hi = Vector2(maxf(hi.x, samples[i].x + pad), maxf(hi.y, samples[i].y + pad))
	return Rect2(lo, hi - lo)


## Unit vector across the course at sample `i`, from the tangent either side.
func _river_across(samples: Array[Vector2], i: int) -> Vector2:
	var previous: Vector2 = samples[maxi(i - 1, 0)]
	var next: Vector2 = samples[mini(i + 1, samples.size() - 1)]
	var tangent := (next - previous).normalized()
	if tangent == Vector2.ZERO:
		tangent = Vector2.RIGHT
	return Vector2(-tangent.y, tangent.x)


func _vec2(raw: Variant) -> Vector2:
	if not raw is Array or (raw as Array).size() < 2:
		return Vector2.ZERO
	return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))


## The stream: a ribbon of surface water following the carved bed downhill.
## Vertex heights are clamped monotone non-increasing — the course was probed
## downhill with no reversals, but "water never flows uphill" should be a
## property of the builder, not a hope about the noise — and the ribbon ends
## by meeting the pond's own level at the mouth.
func _build_stream(material: ShaderMaterial, stream: Dictionary) -> void:
	var points: Array = stream.get("points", [])
	if points.size() < 2:
		return
	var width := float(stream.get("width", 2.4))
	var surface_depth := float(_water_cfg.get("stream", {}).get("surface_depth", 0.45))
	var step := maxf(float(_water_cfg.get("stream", {}).get("sample_step", 3.0)), 0.5)

	# Resample the polyline at an even step so ribbon quads stay similar sizes.
	var line: Array[Vector2] = []
	for entry: Variant in points:
		line.append(Vector2(float(entry[0]), float(entry[1])))
	var samples: Array[Vector2] = [line[0]]
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var count := maxi(1, int(a.distance_to(b) / step))
		for s in range(1, count + 1):
			samples.append(a.lerp(b, float(s) / count))

	# Surface heights: carved bed plus water depth, monotone, floored at the
	# pond level. The ribbon does NOT stop at the first sample that reaches
	# pond level — the shore band's own carve dips the bed under the level a
	# few metres early, and ending there left a dry-looking gap between the
	# stream's terminus and the pond plane (blind round 1: "the blue simply
	# begins partway down the channel... no inlet anywhere"). Instead the
	# surface rides AT the pond level (a hair above, so the coplanar overlap
	# cannot z-fight) across the mouth and only ends once the bed is well
	# inside the basin, where the pond plane has unambiguously taken over.
	# The ribbon spans only where its water genuinely sits inside the ground:
	# it begins once the carve is deep enough to hold `surface_depth` of
	# water (the head ramp's shallow start would put water proud of the
	# meadow — round 4's "orphaned quads in the dry channel"), and it ends
	# the moment the bed passes under the pond's level, where the pond plane
	# is the water from then on (running further produced a more-opaque
	# ribbon tongue floating 2cm over the pond — round 4's plate at the
	# mouth).
	var start_index := 0
	while start_index < samples.size():
		var head := samples[start_index]
		if float(_field.call("stream_carve_depth", head.x, head.y)) >= surface_depth + 0.1:
			break
		start_index += 1
	samples = samples.slice(start_index)
	if samples.size() < 2:
		push_warning("stream carve never reaches surface_depth; no ribbon built")
		return

	# ...and it ends BEFORE the bed crosses under the pond's level, without an
	# overlap row: both this ribbon and the pond plane feather their alpha to
	# zero as their own depth reaches zero, so each fades out on the same
	# waterline and the junction closes itself. An overlapping row was tried
	# first and rendered as a darker wedge over the pond — the stream's more
	# opaque alpha sitting 2cm proud of it (blind round 4's mouth plate). The
	# fine sample_step keeps the un-meshed sliver between the two feather
	# lines under a metre.
	var heights: Array[float] = []
	var last := INF
	var end_index := samples.size()
	for i in samples.size():
		var p := samples[i]
		var bed := float(_field.call("height_at", p.x, p.y))
		if bed <= _level:
			end_index = i
			break
		var y := maxf(minf(bed + surface_depth, last), _level + 0.02)
		heights.append(y)
		last = y
	if end_index < 2:
		return

	# EV5-remainder: cumulative distance along the course, written into UV2.x
	# per vertex (UV2.y is signed metres across). The shader scrolls its wave
	# normals along this axis when flow_enabled — the flow direction IS the
	# ribbon's own tangent, so the water visibly runs downstream with no flow
	# map asset: the parameterisation is the flow map.
	var alongs: Array[float] = [0.0]
	for i in range(1, samples.size()):
		alongs.append(alongs[i - 1] + samples[i - 1].distance_to(samples[i]))

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := width * 0.5
	for i in range(0, end_index - 1):
		var a := samples[i]
		var b := samples[i + 1]
		var t_a := _tangent_at(samples, i)
		var t_b := _tangent_at(samples, i + 1)
		# Width breathes along the run (±25% over two incommensurate waves):
		# a constant-width ribbon was blind round 1's "extruded ribbon...
		# nothing about it says a river cut this". Deterministic in the
		# sample index, so the mesh is identical every build.
		var w_a := half * _width_swell(i)
		var w_b := half * _width_swell(i + 1)
		var side_a := Vector2(-t_a.y, t_a.x) * w_a
		var side_b := Vector2(-t_b.y, t_b.x) * w_b
		_add_quad(tool,
			Vector3(a.x - side_a.x, heights[i], a.y - side_a.y),
			Vector3(a.x + side_a.x, heights[i], a.y + side_a.y),
			Vector3(b.x + side_b.x, heights[i + 1], b.y + side_b.y),
			Vector3(b.x - side_b.x, heights[i + 1], b.y - side_b.y),
			[
				Vector2(alongs[i], -w_a), Vector2(alongs[i], w_a),
				Vector2(alongs[i + 1], w_b), Vector2(alongs[i + 1], -w_b)
			])
	tool.generate_tangents()
	var node := MeshInstance3D.new()
	node.name = "StreamSurface"
	node.mesh = tool.commit()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_stats["stream_points"] = end_index


## 0.75..1.25 width multiplier along the stream, two sine waves at
## incommensurate frequencies so the swell never visibly repeats over the
## course's length. The carve stays constant-width — banks a little wider
## than the water in places read as low-water margins, which is free realism.
func _width_swell(i: int) -> float:
	return 1.0 + 0.15 * sin(i * 0.83 + 1.7) + 0.1 * sin(i * 0.31 + 0.4)


func _tangent_at(samples: Array[Vector2], i: int) -> Vector2:
	var before := samples[maxi(i - 1, 0)]
	var after := samples[mini(i + 1, samples.size() - 1)]
	var along := after - before
	return along.normalized() if along.length_squared() > 0.0001 else Vector2(0, 1)


func _add_quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv2s: Array = []) -> void:
	# UVs are world-XZ so generate_tangents has something consistent to chew
	# on; the shader does its own world-space UVs and never reads these.
	# UV2, when given (one Vector2 per corner a..d), carries the stream's
	# course parameterisation for the shader's flow scroll.
	var corner_uv2 := [0, 1, 2, 0, 2, 3]
	var index := 0
	for v: Vector3 in [a, b, c, a, c, d]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(v.x, v.z) * 0.05)
		if uv2s.size() == 4:
			tool.set_uv2(uv2s[corner_uv2[index]])
		tool.add_vertex(v)
		index += 1


## The shoreline as a fan of bearings out of the pond centre, each bisected
## to where the ground crosses the waterline. Every shore-anchored layer
## (reeds, marginals, rocks, driftwood, lily pads) samples this one fan, so
## they all hug the same real isoline however the level is tuned.
func _shoreline(pond_centre: Vector2) -> Array[Vector2]:
	var shore: Array[Vector2] = []
	var bearings := 72
	for i in bearings:
		var angle := float(i) / bearings * TAU
		var point := _shore_point(pond_centre, Vector2(cos(angle), sin(angle)))
		if point != Vector2.INF:
			shore.append(point)
	if shore.is_empty():
		push_warning("no shoreline found around pond centre %s; shore layers skipped" % pond_centre)
	return shore


## Optional authored arcs for a shoreline layer. The pond is large enough that
## drawing every layer from the whole fan makes sparse dots at low counts and a
## continuous planted ring at high counts. Bearing ranges keep the existing
## terrain-derived shoreline while letting data concentrate plants and stones
## into a few irregular pockets with open access between them.
func _shore_for_config(
	shore: Array[Vector2], pond_centre: Vector2, layer_cfg: Dictionary
) -> Array[Vector2]:
	var ranges: Array = layer_cfg.get("bearing_ranges_deg", [])
	if ranges.is_empty():
		return shore
	var filtered: Array[Vector2] = []
	for point: Vector2 in shore:
		var bearing := rad_to_deg((point - pond_centre).angle())
		for entry: Variant in ranges:
			if not entry is Array or (entry as Array).size() < 2:
				continue
			var limits := entry as Array
			var start_deg := float(limits[0])
			var end_deg := float(limits[1])
			var inside := bearing >= start_deg and bearing <= end_deg
			if start_deg > end_deg:
				inside = bearing >= start_deg or bearing <= end_deg
			if inside:
				filtered.append(point)
				break
	if filtered.is_empty():
		push_warning("shoreline bearing ranges selected no points; using the full shore")
		return shore
	return filtered


## Reeds at the banks (bible §15) plus, EV5-remainder, a second marginal
## species — the broadleaf Plant_1_Big at the waterline, in-family per D24,
## a different silhouette from the wispy-grass reed. EV5-remainder-2 added a
## third: Grass_Wheat, the closest available sedge/cattail read in the fuller
## MegaKit (no literal cattail model exists in the pack) — a tall, narrow,
## dense blade-cluster distinct from Plant_1_Big's broad arch.
func _build_shore_flora(shore: Array[Vector2], pond_centre: Vector2) -> void:
	if shore.is_empty():
		return
	var reeds: Dictionary = _water_cfg.get("reeds", {})
	var marginals: Dictionary = _water_cfg.get("marginals", {})
	var bank_flowers: Dictionary = _water_cfg.get("bank_flowers", {})
	_stats["reeds"] = _build_plant_band(reeds, _shore_for_config(shore, pond_centre, reeds))
	_stats["marginals"] = _build_plant_band(
		marginals, _shore_for_config(shore, pond_centre, marginals)
	)
	_stats["bank_flowers"] = _build_plant_band(
		bank_flowers, _shore_for_config(shore, pond_centre, bank_flowers)
	)


## One config-driven band of plants straddling the waterline. The reed keys
## documented in water.json apply to any band; returns how many were placed.
func _build_plant_band(band_cfg: Dictionary, shore: Array[Vector2]) -> int:
	var models: Array = band_cfg.get("models", [])
	if models.is_empty() or shore.is_empty():
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(band_cfg.get("seed", 1))

	var clumps := int(band_cfg.get("clumps", 34))
	var per_clump := int(band_cfg.get("per_clump", 8))
	var radius := float(band_cfg.get("clump_radius", 2.6))
	var band_below := float(band_cfg.get("band_below", 0.35))
	var band_above := float(band_cfg.get("band_above", 0.45))
	var max_slope := float(band_cfg.get("max_bank_slope_deg", 33.0))
	var scale_min := float(band_cfg.get("scale_min", 0.55))
	var scale_max := float(band_cfg.get("scale_max", 1.0))
	var sink := float(band_cfg.get("sink", REED_SINK))

	var placements: Dictionary = {}
	for model: Variant in models:
		placements[str(model)] = []
	var total := 0
	for c in clumps:
		var anchor := shore[rng.randi_range(0, shore.size() - 1)]
		if float(_field.call("slope_degrees_at", anchor.x, anchor.y)) > max_slope:
			continue
		# Clump size and spread both vary (blind round 1: "one scale, one
		# tint, evenly spaced") — some stands are three stalks, some a real
		# brake, and their footprints differ enough to break the interval.
		var clump_radius := radius * rng.randf_range(0.7, 1.4)
		var clump_count := maxi(2, int(per_clump * rng.randf_range(0.5, 1.4)))
		for i in clump_count:
			var angle := rng.randf_range(0.0, TAU)
			var spot := anchor + Vector2(sin(angle), cos(angle)) * sqrt(rng.randf()) * clump_radius
			var ground := float(_field.call("height_at", spot.x, spot.y))
			# Keep the stand in the waterline band: shin-deep in the shallows
			# to just up the bank. Elevation, not distance — the same rule
			# whether the bank is a beach or a slope.
			if ground < _level - band_below or ground > _level + band_above:
				continue
			var model := str(models[rng.randi_range(0, models.size() - 1)])
			(placements[model] as Array).append({
				"position": Vector3(spot.x, ground - sink, spot.y),
				"yaw": rng.randf_range(0.0, TAU),
				"scale": rng.randf_range(scale_min, scale_max),
				# A few degrees of lean, biased nowhere in particular. Bolt-
				# upright rows are what read as planted; real reeds splay.
				"lean": rng.randf_range(0.0, deg_to_rad(8.0)),
				"lean_yaw": rng.randf_range(0.0, TAU),
				# Per-instance value jitter, the same lever the grass layer
				# uses (R7.1-remainder), with a slight independent green push
				# so neighbouring stalks differ in tone, not just brightness.
				"tone": Color(
					1.0 + rng.randf_range(-0.16, 0.16),
					1.0 + rng.randf_range(-0.08, 0.2),
					1.0 + rng.randf_range(-0.16, 0.1)
				),
			})
			total += 1

	var tint := str(band_cfg.get("tint", "#86a05c"))
	for model: String in placements.keys():
		var list: Array = placements[model]
		if list.is_empty():
			continue
		_add_reed_batch(model, list, tint)
	return total


## Where the ground crosses the waterline along one bearing out of the pond:
## first crossing by 1.5m march, refined by bisection. Vector2.INF when the
## bearing never surfaces within 90m (an inlet the fan skips harmlessly).
func _shore_point(centre: Vector2, direction: Vector2) -> Vector2:
	var last_r := 0.0
	var r := 1.5
	while r <= 90.0:
		var p := centre + direction * r
		if float(_field.call("height_at", p.x, p.y)) >= _level:
			var wet_r := last_r
			var dry_r := r
			for i in 8:
				var mid := (wet_r + dry_r) * 0.5
				var m := centre + direction * mid
				if float(_field.call("height_at", m.x, m.y)) >= _level:
					dry_r = mid
				else:
					wet_r = mid
			return centre + direction * ((wet_r + dry_r) * 0.5)
		last_r = r
		r += 1.5
	return Vector2.INF


## One MultiMesh per reed model, mirroring vegetation.gd's batching. The
## retint is local because these two meshes already belong to the drygrass
## layer, and vegetation.gd's batches are grouped by model — the documented
## reason a mesh must not appear in two of ITS layers. A separate composer
## with its own MultiMesh instances sidesteps that entirely.
##
## EV5-remainder reuses this for the dressing layers: rocks and driftwood
## pass cast_shadows=true — a boulder's shadow IS information, unlike a
## tuft's — and every layer keeps the same placement-dict contract.
func _add_reed_batch(model_path: String, placements: Array, tint: String, cast_shadows := false) -> void:
	var mesh := _mesh_for(model_path)
	if mesh == null:
		push_error("reed model %s could not be loaded" % model_path)
		return
	var tinted: ArrayMesh = mesh.duplicate(false)
	for surface in mesh.get_surface_count():
		tinted.surface_set_material(surface, _reed_material(mesh.surface_get_material(surface), tint))

	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = tinted
	# use_colors BEFORE instance_count — the buffer is sized when the count
	# is assigned and never resized after (the exact silent failure
	# vegetation.gd's own R7.2 comment documents).
	multi.use_colors = true
	multi.instance_count = placements.size()
	for i in placements.size():
		var placement: Dictionary = placements[i]
		var basis := Basis(Vector3.UP, float(placement["yaw"]))
		var lean := float(placement.get("lean", 0.0))
		if lean > 0.0:
			var lean_axis := Vector3(cos(float(placement["lean_yaw"])), 0.0, sin(float(placement["lean_yaw"])))
			basis = Basis(lean_axis, lean) * basis
		basis = basis.scaled(Vector3.ONE * float(placement["scale"]))
		multi.set_instance_transform(i, Transform3D(basis, placement["position"]))
		multi.set_instance_color(i, placement.get("tone", Color.WHITE))

	var node := MultiMeshInstance3D.new()
	node.name = "Shore_%s" % model_path.get_file().get_basename()
	node.multimesh = multi
	# Same rule as the grass layers for flora: a tuft's shadow is not
	# information. Solid dressing (rocks, driftwood) opts back in.
	if not cast_shadows:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


## A marsh-green modulate over the pack's own grass texture — the same
## multiply-over-texture treatment vegetation.gd's _tint_for applies, kept
## local for the reason _add_reed_batch's comment gives.
func _reed_material(source: Material, tint: String) -> Material:
	var material := StandardMaterial3D.new()
	var standard := source as StandardMaterial3D
	material.albedo_color = Color(tint)
	# Forced on: MultiMesh per-instance tone multiplies through this channel
	# (vegetation.gd's own colour_jitter mechanism, same reason).
	material.vertex_color_use_as_albedo = true
	if standard != null:
		if standard.albedo_texture != null:
			material.albedo_texture = standard.albedo_texture
		material.transparency = standard.transparency
		material.alpha_scissor_threshold = standard.alpha_scissor_threshold
		material.cull_mode = standard.cull_mode
		if standard.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
	material.roughness = 0.94
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


## Same flatten-to-one-mesh read vegetation.gd uses for the pack's models.
func _mesh_for(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var scene: Node = packed.instantiate()
	var found: Mesh = null
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if found == null and node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			found = (node as MeshInstance3D).mesh
		for child in node.get_children():
			stack.append(child)
	scene.queue_free()
	return found


## ---------------------------------------------------------------------------
## EV5-remainder — waterside dressing. Everything below reads water.json's
## `dressing` and `jetty` blocks; all counts, bands and scales are TUNABLE
## there. Assets are strictly the families already in the build (D24): the
## Stylized Nature MegaKit's rocks/pebbles/plants, the Kenney logs the ledger
## retained "for the log shapes", the Medieval Village MegaKit's deck/fence
## modules and the Fantasy Props kit pieces already curated for EV7.
## ---------------------------------------------------------------------------


func _build_dressing(shore: Array[Vector2], pond_centre: Vector2) -> void:
	var dressing: Dictionary = _water_cfg.get("dressing", {})
	if dressing.is_empty() or shore.is_empty():
		return
	_jetty_keepout(pond_centre)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(dressing.get("seed", 20260813))
	var boulders: Dictionary = dressing.get("boulders", {})
	var stones: Dictionary = dressing.get("stones", {})
	var driftwood: Dictionary = dressing.get("driftwood", {})
	var lilypads: Dictionary = dressing.get("lilypads", {})
	_stats["rocks"] = _scatter_rocks(
		boulders, _shore_for_config(shore, pond_centre, boulders), pond_centre, rng
	)
	_stats["rocks"] += _scatter_rocks(
		stones, _shore_for_config(shore, pond_centre, stones), pond_centre, rng
	)
	_stats["driftwood"] = _scatter_driftwood(
		driftwood, _shore_for_config(shore, pond_centre, driftwood), pond_centre, rng
	)
	_stats["lilypads"] = _scatter_lilypads(
		lilypads, _shore_for_config(shore, pond_centre, lilypads), pond_centre, rng
	)


## Rocks and driftwood must not land on the jetty: the first render put a
## boulder against the deck and drove the railing straight through it. The
## keep-out is the deck's own segment plus a margin, derived from the same
## jetty config the builder reads, so retuning the jetty moves it too.
var _keepout_a := Vector2.INF
var _keepout_b := Vector2.INF
var _keepout_r := 0.0


func _jetty_keepout(pond_centre: Vector2) -> void:
	var cfg: Dictionary = _water_cfg.get("jetty", {})
	if cfg.is_empty():
		return
	var bearing := deg_to_rad(float(cfg.get("bearing_deg", -30.0)))
	var out_dir := Vector2(cos(bearing), sin(bearing))
	var anchor := _shore_point(pond_centre, out_dir)
	if anchor == Vector2.INF:
		return
	var into := -out_dir
	var run := 2.0 * float(cfg.get("modules", 4))
	var land_overlap := float(cfg.get("land_overlap", 1.4))
	_keepout_a = anchor - into * land_overlap
	_keepout_b = anchor + into * (run - land_overlap)
	_keepout_r = float(cfg.get("width_scale", 0.8)) + 2.2


func _in_keepout(p: Vector2) -> bool:
	if _keepout_a == Vector2.INF:
		return false
	var ab := _keepout_b - _keepout_a
	var t := clampf((p - _keepout_a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(_keepout_a + ab * t) < _keepout_r


## Rocks in and at the water: anchored on the shoreline fan, pushed a random
## distance into the water (or a step up the bank), sunk so no pivot-plane
## edge can show, tilted a few degrees so no two sit identically. Two config
## groups route through here — `boulders` (the metre-plus Rock_Medium set)
## and `stones` (Pebble_Round scaled up into smooth half-submerged slabs) —
## because one scale range cannot serve meshes two orders apart in volume.
func _scatter_rocks(cfg: Dictionary, shore: Array[Vector2], pond_centre: Vector2, rng: RandomNumberGenerator) -> int:
	var models: Array = cfg.get("models", [])
	if models.is_empty() or shore.is_empty():
		return 0
	var count := int(cfg.get("count", 12))
	var into_water := float(cfg.get("into_water_max", 5.0))
	var up_bank := float(cfg.get("up_bank_max", 1.0))
	var max_depth := float(cfg.get("max_depth", 1.6))
	var scale_min := float(cfg.get("scale_min", 0.4))
	var scale_max := float(cfg.get("scale_max", 1.0))
	var sink_min := float(cfg.get("sink_min", 0.15))
	var sink_max := float(cfg.get("sink_max", 0.5))

	var placements: Dictionary = {}
	for model: Variant in models:
		placements[str(model)] = []
	var total := 0
	for i in count:
		var anchor := shore[rng.randi_range(0, shore.size() - 1)]
		var out_dir := (anchor - pond_centre).normalized()
		var spot := anchor + out_dir * rng.randf_range(-into_water, up_bank)
		var ground := float(_field.call("height_at", spot.x, spot.y))
		# Depth gate, not distance: the same rock rule whether the bank
		# shelves gently or drops. Too deep and the crown vanishes for
		# nothing; too high and it is just a meadow rock (EV3's job).
		if ground < _level - max_depth or ground > _level + 0.4:
			continue
		if _in_keepout(spot):
			continue
		var scale := rng.randf_range(scale_min, scale_max)
		var model := str(models[rng.randi_range(0, models.size() - 1)])
		(placements[model] as Array).append({
			"position": Vector3(spot.x, ground - rng.randf_range(sink_min, sink_max) * scale, spot.y),
			"yaw": rng.randf_range(0.0, TAU),
			"scale": scale,
			"lean": rng.randf_range(0.0, deg_to_rad(12.0)),
			"lean_yaw": rng.randf_range(0.0, TAU),
			# Near-neutral value jitter only — a tinted rock reads painted.
			"tone": Color.WHITE * (1.0 + rng.randf_range(-0.1, 0.08)),
		})
		total += 1

	for model: String in placements.keys():
		var list: Array = placements[model]
		if list.is_empty():
			continue
		_add_reed_batch(model, list, str(cfg.get("tint", "#ffffff")), true)
	_add_rock_collision(cfg, placements)
	return total


## A boulder the trainer walks through reads as a hologram, and the camera's
## SpringArm3D only stops at colliders (vegetation.gd's own lesson). One
## body, many shapes, same as vegetation.gd::_add_collision; only groups
## whose config opts in collide — the scaled pebbles are shin-height and
## wading over them is fine.
func _add_rock_collision(cfg: Dictionary, placements: Dictionary) -> void:
	if not bool(cfg.get("collides", false)):
		return
	var radius := float(cfg.get("collision_radius", 1.1))
	var body := StaticBody3D.new()
	body.name = "RockCollision"
	add_child(body)
	for model: String in placements.keys():
		for entry: Variant in (placements[model] as Array):
			var placement: Dictionary = entry
			var shape := SphereShape3D.new()
			shape.radius = radius * float(placement["scale"])
			var node := CollisionShape3D.new()
			node.shape = shape
			node.position = placement["position"] as Vector3
			body.add_child(node)


## Driftwood: the Kenney logs beached at the waterline, lying along the
## shore with a few degrees of pitch so one end dips into the water. Laid
## parallel-ish to the shoreline (perpendicular to the outward bearing) the
## way real drift settles, never radially like spokes.
func _scatter_driftwood(cfg: Dictionary, shore: Array[Vector2], pond_centre: Vector2, rng: RandomNumberGenerator) -> int:
	var models: Array = cfg.get("models", [])
	if models.is_empty():
		return 0
	var count := int(cfg.get("count", 5))
	var band_below := float(cfg.get("band_below", 0.3))
	var band_above := float(cfg.get("band_above", 0.45))
	var scale_min := float(cfg.get("scale_min", 1.6))
	var scale_max := float(cfg.get("scale_max", 2.8))
	var max_pitch := deg_to_rad(float(cfg.get("max_pitch_deg", 9.0)))

	var placements: Dictionary = {}
	for model: Variant in models:
		placements[str(model)] = []
	var total := 0
	for i in count:
		var anchor := shore[rng.randi_range(0, shore.size() - 1)]
		var out_dir := (anchor - pond_centre).normalized()
		var spot := anchor + out_dir * rng.randf_range(-0.8, 0.8)
		var ground := float(_field.call("height_at", spot.x, spot.y))
		if ground < _level - band_below or ground > _level + band_above:
			continue
		if _in_keepout(spot):
			continue
		# Yaw: the shore tangent plus jitter. The Kenney logs lie along
		# their own Z, and Basis(UP, yaw) turns +Z toward the tangent when
		# yaw is the tangent's bearing.
		var tangent := Vector2(-out_dir.y, out_dir.x)
		var yaw := atan2(tangent.x, tangent.y) + rng.randf_range(-0.5, 0.5)
		# Pitch around the log's own lie: lean the placement toward the
		# water so the waterward end settles in.
		var model := str(models[rng.randi_range(0, models.size() - 1)])
		(placements[model] as Array).append({
			"position": Vector3(spot.x, ground - 0.06, spot.y),
			"yaw": yaw,
			"scale": rng.randf_range(scale_min, scale_max),
			"lean": rng.randf_range(deg_to_rad(2.0), max_pitch),
			"lean_yaw": atan2(-out_dir.x, -out_dir.y),
			# Weathered wood: value jitter around the tint, no green push.
			"tone": Color.WHITE * (1.0 + rng.randf_range(-0.12, 0.08)),
		})
		total += 1

	for model: String in placements.keys():
		var list: Array = placements[model]
		if list.is_empty():
			continue
		_add_reed_batch(model, list, str(cfg.get("tint", "#9a8974")), true)
	return total


## Lily pads: the nature pack's flat broadleaf rosette (Plant_7) floating at
## the surface in clusters over calm shallow water. Placed by depth, not by
## shore distance — pads want 0.3–1.3m of water under them, which keeps them
## off the banks and out of the deep middle where they would read as flotsam.
func _scatter_lilypads(cfg: Dictionary, shore: Array[Vector2], pond_centre: Vector2, rng: RandomNumberGenerator) -> int:
	var models: Array = cfg.get("models", [])
	if models.is_empty() or shore.is_empty():
		return 0
	var clusters := int(cfg.get("clusters", 6))
	var per_cluster := int(cfg.get("per_cluster", 7))
	var radius := float(cfg.get("cluster_radius", 3.0))
	var depth_min := float(cfg.get("depth_min", 0.3))
	var depth_max := float(cfg.get("depth_max", 1.3))
	var scale_min := float(cfg.get("scale_min", 0.7))
	var scale_max := float(cfg.get("scale_max", 1.4))

	var placements: Dictionary = {}
	for model: Variant in models:
		placements[str(model)] = []
	var total := 0
	for c in clusters:
		# Walk in from a shore anchor until the water is pad-deep; give up
		# on bearings that shelve too slowly to reach it within 12m.
		var anchor := shore[rng.randi_range(0, shore.size() - 1)]
		var in_dir := (pond_centre - anchor).normalized()
		var seed_spot := Vector2.INF
		var walk := 1.0
		while walk <= 12.0:
			var probe := anchor + in_dir * walk
			var depth := _level - float(_field.call("height_at", probe.x, probe.y))
			if depth >= depth_min + 0.1 and depth <= depth_max:
				seed_spot = probe
				break
			walk += 1.0
		if seed_spot == Vector2.INF:
			continue
		for i in per_cluster:
			var angle := rng.randf_range(0.0, TAU)
			var spot := seed_spot + Vector2(sin(angle), cos(angle)) * sqrt(rng.randf()) * radius
			var depth := _level - float(_field.call("height_at", spot.x, spot.y))
			if depth < depth_min or depth > depth_max:
				continue
			var model := str(models[rng.randi_range(0, models.size() - 1)])
			(placements[model] as Array).append({
				# A whisker above the surface so the pad never z-fights the
				# water plane; the pad is opaque and draws before it.
				"position": Vector3(spot.x, _level + 0.02, spot.y),
				"yaw": rng.randf_range(0.0, TAU),
				"scale": rng.randf_range(scale_min, scale_max),
				"tone": Color(
					1.0 + rng.randf_range(-0.12, 0.1),
					1.0 + rng.randf_range(-0.06, 0.16),
					1.0 + rng.randf_range(-0.12, 0.06)
				),
			})
			total += 1

	for model: String in placements.keys():
		var list: Array = placements[model]
		if list.is_empty():
			continue
		_add_reed_batch(model, list, str(cfg.get("tint", "#4f7d44")))
	return total


## The jetty (bible §15's "support Water Creature ecology", the blind rounds'
## "the key art's jetty"): a short plank deck the villagers built, walking
## out from the shore where the pond path delivers the player. Composed from
## the Medieval Village kit's own modules (D24's one village family) —
## Floor_WoodDark planks, WoodenFence railing — on rough log pilings, with
## two of EV7's already-curated props at the end so it reads as a used
## fishing spot rather than an ornament. Walkable: one box collider over the
## deck, same one-body pattern as every other placed structure.
func _build_jetty(pond_centre: Vector2) -> void:
	var cfg: Dictionary = _water_cfg.get("jetty", {})
	if cfg.is_empty():
		return
	var bearing := deg_to_rad(float(cfg.get("bearing_deg", -30.0)))
	var out_dir := Vector2(cos(bearing), sin(bearing))
	var anchor := _shore_point(pond_centre, out_dir)
	if anchor == Vector2.INF:
		push_warning("jetty bearing %.0f° never crosses the waterline; jetty skipped" % rad_to_deg(bearing))
		return

	var module_len := 2.0  # Floor_WoodDark is a 2×2m slab, measured.
	var modules := int(cfg.get("modules", 4))
	var width_scale := float(cfg.get("width_scale", 0.8))
	var width := 2.0 * width_scale
	var deck_h := _level + float(cfg.get("deck_above_water", 0.5))
	var land_overlap := float(cfg.get("land_overlap", 1.4))
	var into := -out_dir
	var perp := Vector2(-into.y, into.x)
	# Basis(UP, yaw) maps +X to (cos yaw, 0, -sin yaw); yaw chosen so the
	# deck's long axis runs along `into`.
	var yaw := atan2(-into.y, into.x)

	var root := Node3D.new()
	root.name = "Jetty"
	add_child(root)
	var pieces := 0

	var deck_scene: PackedScene = load("res://assets/buildings/quaternius_medieval/Floor_WoodDark.gltf")
	var fence_scene: PackedScene = load("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Single.gltf")
	if deck_scene == null:
		push_error("jetty deck module missing; jetty skipped")
		root.queue_free()
		return

	for i in modules:
		var s := module_len * (float(i) + 0.5) - land_overlap
		var centre := anchor + into * s
		var deck := deck_scene.instantiate() as Node3D
		# Rotation FIRST, then a local-axis scale (Basis.scaled() alone is a
		# global-space scale and would squash the rotated deck diagonally).
		deck.transform = Transform3D(
			Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(1.0, 1.0, width_scale)),
			Vector3(centre.x, deck_h, centre.y)
		)
		root.add_child(deck)
		pieces += 1
		# Railing down one side only — a working jetty, not a balcony.
		if bool(cfg.get("railing", true)) and fence_scene != null and i < modules - 1:
			var rail := fence_scene.instantiate() as Node3D
			var rail_pos := centre + perp * (width * 0.5 - 0.06)
			rail.transform = Transform3D(
				Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(module_len / 2.06, 1.0, 1.0)),
				Vector3(rail_pos.x, deck_h, rail_pos.y)
			)
			root.add_child(rail)
			pieces += 1

	# Pilings: the Kenney log stood on end at each module joint, stretched
	# from the bed to the deck underside. Rougher than a kit post and that
	# is the point — the villagers drove logs, they did not turn columns.
	var log_mesh := _mesh_for(str(cfg.get("piling_model", "res://assets/environment/nature/log.glb")))
	if log_mesh != null:
		# Not _reed_material: that one turns vertex_color_use_as_albedo on
		# for MultiMesh instance tones, and the Kenney log's own cream cut-
		# wood vertex colours multiplied through it — the pilings rendered
		# as pale concrete posts (own-render pass). A plain opaque wood
		# material shows the tint as authored.
		var piling_material := StandardMaterial3D.new()
		piling_material.albedo_color = Color(str(cfg.get("piling_tint", "#6b5843")))
		piling_material.roughness = 0.95
		piling_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		for j in modules + 1:
			var s := module_len * float(j) - land_overlap
			for side: float in [-1.0, 1.0]:
				var pos2 := anchor + into * s + perp * side * (width * 0.5 - 0.12)
				var ground := float(_field.call("height_at", pos2.x, pos2.y))
				if ground > deck_h:
					continue
				var span := deck_h - ground + 0.35
				var piling := MeshInstance3D.new()
				piling.mesh = log_mesh
				piling.material_override = piling_material
				# The log lies along its own Z (0.71m); rotate Z up, then
				# scale local Z to span bed→deck and XY into a post's girth.
				piling.transform = Transform3D(
					Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3(1.4, span / 0.71, 1.4)),
					Vector3(pos2.x, ground - 0.2 + span * 0.5, pos2.y)
				)
				root.add_child(piling)
				pieces += 1

	# The end of the deck earns its keep: a crate and a bucket from EV7's
	# curated prop family, the difference between "geometry" and "someone
	# fishes here".
	var end2 := anchor + into * (module_len * modules - land_overlap - 0.75)
	for extra: Array in [
		["res://assets/props/quaternius_fantasy/Crate_Wooden.gltf", perp * (width * 0.22), 0.6],
		["res://assets/props/quaternius_fantasy/Bucket_Wooden_1.gltf", perp * (-width * 0.24), 2.4],
	]:
		var scene: PackedScene = load(str(extra[0]))
		if scene == null:
			continue
		var prop := scene.instantiate() as Node3D
		var offset: Vector2 = extra[1]
		prop.transform = Transform3D(
			Basis(Vector3.UP, yaw + float(extra[2])),
			Vector3(end2.x + offset.x, deck_h + 0.01, end2.y + offset.y)
		)
		root.add_child(prop)
		pieces += 1

	# One box over the whole deck: walkable, and the camera arm stops at it.
	var body := StaticBody3D.new()
	body.name = "DeckCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(module_len * modules, 0.3, width)
	shape.shape = box
	var mid := anchor + into * (module_len * modules * 0.5 - land_overlap)
	shape.transform = Transform3D(
		Basis(Vector3.UP, yaw),
		Vector3(mid.x, deck_h - 0.14, mid.y)
	)
	body.add_child(shape)
	root.add_child(body)
	_stats["jetty_pieces"] = pieces


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("water.json missing; water renders with shader defaults")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
