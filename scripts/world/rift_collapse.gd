extends Node3D

## SG44 — the first Tether Rift collapses, and the world gets bigger.
##
## Spec §27, §28, §30. The Warden falls, `stronghold_climax.gd` sets
## `legendary_freed` exactly once, the machinery holding the Rifts apart fails,
## and ONE severed spoke visibly reconnects. Which spoke and why is in
## `data/config/rift_collapse.json`'s own `_comment_spoke` — short version:
## `storm_road`, because its blocker is a baked 11m carve nothing at run time
## can open, because §30's own list of reconnection images includes "a storm
## wall dissipating" and this is the road the map already calls Storm Country,
## and because SF33 already dressed that seam with a live pylon and a resuming
## roadbed on the FAR rim, which is the close-range half of the same sentence.
##
## THE CARVE-OUT IS THE POINT AND IT IS NOT NEGOTIABLE. This is a DISTANT,
## NON-ENTERABLE VIEW. CLAUDE.md forbids Biome 2 work until the Meadows passes
## its exit gate, D23 holds that rule over this step, and §19's non-goals agree.
## So this file builds SKY and nothing else:
##
##   * every mesh sits 260–460m out along the spoke's own bearing — outside the
##     512m terrain, past the 235m boundary ring, past the spoke's carve
##   * not one collider, area, spawn, species, prompt or nav mesh is created
##   * the road still stops at the collapsed bridge. `tests/smoke_boss.gd`
##     walks a body at the LEGENDARY's own 55-degree climb limit (R8.5, the
##     best mobility that exists in this game) into that seam before and after
##     the flag and fails the build if it ever gets across
##
## What it does own: two groups of unshaded, alpha-blended slabs. `StormWall`
## is up from the first boot and is what the player has looked at across the
## broken bridge for the entire chapter. `FarCountry` is at zero alpha until
## the flag, and is ridge silhouettes plus one warm horizon glow in the same
## colour the freed legendary is lit by indoors. On the flag the first
## dissipates while the second comes up, overlapping, so it reads as one event.
##
## Nothing here explains itself with UI text, the same hard rule
## `severed_spokes.gd` carries for the same seven roads.

const CONFIG_PATH := "res://data/config/rift_collapse.json"
const TERRAIN_CONFIG_PATH := "res://data/config/terrain_playground.json"

var _config: Dictionary = {}
var _spoke: Dictionary = {}
var _world: Node3D = null

## The frame the effect is placed in: the far rim of the seam, and the road's
## own outward direction. Derived from the spoke's authored data every build,
## never copied into this file's config — move the storm road and the sky
## follows it.
var _origin := Vector2.ZERO
var _forward := Vector2(1.0, 0.0)
var _base_height: float = 0.0

var _storm_slabs: Array[MeshInstance3D] = []
var _far_slabs: Array[MeshInstance3D] = []
## Authored alpha per slab, so a fade is always a fraction of what the artist
## asked for rather than a march to 1.0.
var _storm_alpha: Array[float] = []
var _far_alpha: Array[float] = []

var _collapsed: bool = false
var _elapsed: float = 0.0
var _time: float = 0.0
var _progression: RefCounted = null
var _flag := "legendary_freed"
## Last `progression.revision` this node compared the flag against.
var _revision: int = -1


func build(world: Node3D) -> void:
	_world = world
	_config = _load_json(CONFIG_PATH)
	if _config.is_empty():
		push_warning("rift_collapse.json missing; the Rift never collapses")
		return
	if not _resolve_frame():
		return
	_build_group("StormWall", _config.get("storm_wall", {}).get("slabs", []),
		_storm_slabs, _storm_alpha, 1.0)
	var far: Dictionary = _config.get("far_country", {})
	var far_list: Array = (far.get("ridges", []) as Array).duplicate()
	if far.get("glow", null) is Dictionary:
		far_list.append(far["glow"])
	_build_group("FarCountry", far_list, _far_slabs, _far_alpha, 0.0)
	_watch_the_flag()
	set_process(true)


## The seam's frame, off the spoke's OWN entry in terrain_playground.json.
## `far_road.to` is the last authored point of the roadbed resuming on the far
## rim, which is exactly the place the player's eye is already going.
func _resolve_frame() -> bool:
	var wanted := str(_config.get("spoke", ""))
	var terrain := _load_json(TERRAIN_CONFIG_PATH)
	for entry: Variant in (terrain.get("spokes", {}).get("routes", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == wanted:
			_spoke = entry
			break
	if _spoke.is_empty():
		push_warning("rift_collapse: no spoke '%s' in terrain_playground.json" % wanted)
		return false
	var road: Array = _spoke.get("road", [])
	if road.size() < 2:
		return false
	var road_end := _vec2(road[road.size() - 1])
	var far_road: Dictionary = _spoke.get("far_road", {})
	var beyond := _vec2(far_road.get("to", road[road.size() - 1]))
	_forward = (beyond - road_end)
	if _forward.length() < 0.01:
		_forward = _vec2(road[road.size() - 1]) - _vec2(road[road.size() - 2])
	_forward = _forward.normalized()
	_origin = beyond
	_base_height = 0.0
	if _world != null and _world.has_method("ground_height_at"):
		var ground := float(_world.call("ground_height_at", road_end.x, road_end.y))
		if not is_nan(ground):
			_base_height = ground
	return true


## One slab: a quad standing in the sky at `distance` along the spoke's bearing,
## yawed off it by `yaw_deg`, facing back down the road at the player. No
## collider, no shadow, no lighting — this is a painted horizon and it has to
## look like the sky it stands in rather than like a lit object in a field.
##
## GATE-E-STRONGHOLD-ART (2026-08-23) — WHY EVERY SLAB NOW CARRIES A VIEWING
## RANGE. This file's own header above still claims every mesh sits "260–460m
## out ... outside the 512m terrain". The first half is true and the second
## half quietly stopped being true: the world moved to the 8192m corridor, the
## storm road's seam went with it to z≈7513, and the Meadows now has thousands
## of metres of open sightline pointing straight at these quads from places
## that are not the seam. Band 4 is one of them. `shots/band4/far-panels-
## north.png` shows three pale translucent rectangles standing on the horizon,
## and `tools/_probe_sky_slabs.gd` (this task) named them: StormWall_0/1/2, at
## 1943–2005m from that viewpoint, inside the capture camera's own 2000m far
## plane and dead ahead of it. The same probe finds them 1414–1557m off the
## `ridge-patrol-camp` and `watchtower-spur` viewpoints.
##
## At the seam the effect works — 365–461m out, each slab subtending ~26° of
## sky, an overlapping wall of weather with no land past it, exactly what it
## was authored to be. At 2km the identical quad subtends 5–8°, and the fog it
## is (correctly) drawn through blends roughly two thirds of the way to
## `fog_colour` at that range, so a slate storm wall becomes a small, pale,
## hard-edged translucent box floating over a hillside. Nothing is broken in
## the material or the transform; the geometry is simply being seen from
## outside the vantage it is a painting for.
##
## So the fix is a placement contract rather than a colour: a slab is drawn
## only within the band it was authored for, and fades rather than pops at the
## edge of it. `visible_within_metres`/`fade_metres` in rift_collapse.json are
## the tunables. This is deliberately applied to BOTH groups — `FarCountry` is
## at zero alpha until the flag, so it has never been seen misbehaving, but it
## is the same quads at the same place and would inherit the same defect the
## moment the Warden falls.
func _build_group(group_name: String, slabs: Array, into: Array[MeshInstance3D],
		alphas: Array[float], scale: float) -> void:
	var visible_within := float(_config.get("visible_within_metres", 0.0))
	var fade := maxf(float(_config.get("fade_metres", 0.0)), 0.0)
	var holder := Node3D.new()
	holder.name = group_name
	add_child(holder)
	var index := 0
	for entry: Variant in slabs:
		if not entry is Dictionary:
			continue
		var slab: Dictionary = entry
		var distance := float(slab.get("distance", 300.0))
		var yaw := deg_to_rad(float(slab.get("yaw_deg", 0.0)))
		var width := float(slab.get("width", 400.0))
		var height := float(slab.get("height", 140.0))
		var direction := _forward.rotated(yaw)
		var at := _origin + direction * distance

		var mesh := QuadMesh.new()
		mesh.size = Vector2(width, height)
		var instance := MeshInstance3D.new()
		instance.name = "%s_%d" % [group_name, index]
		instance.mesh = mesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Far enough that the engine's own culling would otherwise argue with
		# a 400m quad whose origin sits behind the camera's far plane check.
		instance.extra_cull_margin = maxf(width, height)
		# The viewing band, measured from the slab's own centre. Godot fades
		# across [end - margin, end], so `visible_within_metres` is where the
		# slab has fully gone and `fade_metres` is how long it takes to get
		# there. Zero (or unset) keeps the old always-drawn behaviour.
		if visible_within > 0.0:
			instance.visibility_range_end = visible_within
			instance.visibility_range_end_margin = minf(fade, visible_within)
			instance.visibility_range_fade_mode = \
				GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		var authored := clampf(float(slab.get("alpha", 0.9)), 0.0, 1.0)
		var colour := Color(str(slab.get("colour", "#39404f")))
		colour.a = authored * scale
		instance.material_override = _slab_material(colour, hash("%s_%d" % [group_name, index]))
		instance.position = Vector3(at.x, _base_height + float(slab.get("base", 0.0)) + height * 0.5, at.y)
		# Face back along its own bearing, at the road the player stands on.
		instance.rotation.y = atan2(-direction.x, -direction.y)
		instance.visible = colour.a > 0.001
		holder.add_child(instance)
		into.append(instance)
		alphas.append(authored)
		index += 1


## T1-STORMWALL (2026-08-30) -- WHY THIS SLAB NOW CARRIES A TEXTURE.
## `T1-HALL`'s re-site (`data/config/stronghold.json::_comment_ow5d_relocation`)
## put the Hall's `site.at` at (8,7560), 62.7m from this spoke's own road end
## (-33.99,7513.46) and 74.2m from `_origin` -- so close that JUDGE-4, the Hall
## lane and the lane before it all independently traced "four huge untextured
## grey slabs behind the Hall" back to this file (`ralph/reports/
## JUDGE-4-2026-08-30.md`, evidence-validity section). Measured, not assumed
## (`tools/_probe_stormwall_hall.gd`, this task): the three `storm_wall` slabs
## sit 332-409m from the Hall, inside the very range this file's own GATE-E-
## STRONGHOLD-ART comment above already names as the effect's designed sweet
## spot -- "at the seam the effect works -- 365-461m out" -- and close to
## on-axis (the Hall sits ~7 degrees off the forward bearing at that range,
## comfortably inside a single slab's own 26-degree spread). So this is NOT
## the visibility/lifecycle bug GATE-E-STRONGHOLD-ART fixed: `visible_within_
## metres` cannot discriminate "seen from the seam, as designed" from "seen
## from the Hall" because, geometrically, the Hall now sits almost exactly
## where the seam already put a viewer. Shrinking the visibility band would
## also blank the wall at the storm road's own dead end, deleting the read
## this file's header says is "what the player has looked at across the
## broken bridge for the entire chapter."
##
## What actually changed is CONTEXT, not distance: at the seam this is the
## only thing in the shot, across 200m of open meadow, with nothing to compare
## it to. Next to the Hall's coursed, lit, textured stone, the same flat
## single-colour unshaded quad this file has always drawn reads as exactly
## what it is under that comparison -- a hard-edged rectangle -- rather than
## as weather. So the fix is materials: a procedurally generated mask (no new
## asset, no Meshy generation, same rule the rest of this file already follows
## for its own geometry) that (1) feathers the rectangle's edges into a cloud
## silhouette instead of a hard-edged card, (2) thins the base so the wall
## settles toward the ground fog instead of ending in a visible sill, and (3)
## adds internal noise-driven variation so the surface reads as volume rather
## than flat paint. `_scale_group`'s animation is untouched -- it still only
## writes `albedo_color.a`, which multiplies with this mask's own alpha, so
## the breathing pulse and the collapse/reveal fade work exactly as before and
## `_cover()`/`horizon()` (mesh area times `albedo_color.a`) are unaffected by
## a texture that never appears in that arithmetic.
const _MASK_SIZE := Vector2i(160, 72)

## One seeded, deterministic soft-edged noise mask per slab, so the storm wall
## reads as several irregular banks of weather rather than one texture tiled
## across identical rectangles -- the same "asymmetric, not mirrored" note
## JUDGE-3/JUDGE-4 already made about the creature variants' own crack
## networks applies here.
static func _slab_mask(seed_value: int) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.05
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.55
	var image := Image.create(_MASK_SIZE.x, _MASK_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in _MASK_SIZE.y:
		var v := float(y) / float(_MASK_SIZE.y - 1)
		# Denser toward the top, thinning toward the base -- a wall of weather
		# settles into ground fog, it does not end on a visible straight sill.
		var vertical := smoothstep(0.0, 0.3, v) * (1.0 - 0.45 * smoothstep(0.72, 1.0, v))
		for x in _MASK_SIZE.x:
			var u := float(x) / float(_MASK_SIZE.x - 1)
			# The mesh boundary itself must never read as an edge -- feather
			# both sides into a cloud bank rather than a card.
			var edge := smoothstep(0.0, 0.18, u) * smoothstep(1.0, 0.82, u)
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var shade := 0.8 + 0.4 * n
			var alpha := clampf(edge * vertical * (0.5 + 0.5 * n), 0.0, 1.0)
			image.set_pixel(x, y, Color(shade, shade, shade, alpha))
	return ImageTexture.create_from_image(image)


func _slab_material(colour: Color, seed_value: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.albedo_texture = _slab_mask(seed_value)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.disable_receive_shadows = true
	return material


## --- the trigger -------------------------------------------------------------

## `legendary_freed`, set exactly once by `stronghold_climax.gd`. Read, never
## written: a world event that can set its own trigger fires on a fresh boot.
## A save loaded with the flag already set snaps straight to the after state,
## which is why `_apply_now` exists separately from the timed collapse.
func _watch_the_flag() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	_progression = game.get("progression") as RefCounted
	if _progression == null:
		return
	var flag := str(_config.get("flag", "legendary_freed"))
	if bool(_progression.call("has", flag)):
		_apply_now()
		return
	# And otherwise it is watched by POLLING `revision`, in `_process` below.
	# progression_state.gd has no signal, by design and by its own header;
	# every other consumer of the flag store (party.gd, inventory.gd,
	# map_state.gd, village_npcs.gd) polls the revision counter, and a world
	# event connected to a signal nobody emits is a world event that silently
	# never happens.
	_flag = flag


func _process(delta: float) -> void:
	_time += delta
	if not _collapsed:
		_poll_the_flag()
	if not _collapsed:
		_breathe()
		return
	_elapsed += delta
	var collapse: Dictionary = _config.get("collapse", {})
	var hold := float(collapse.get("hold_seconds", 1.2))
	var dissipate := maxf(float(collapse.get("dissipate_seconds", 9.0)), 0.01)
	var reveal := maxf(float(collapse.get("reveal_seconds", 7.0)), 0.01)
	var reveal_delay := float(collapse.get("reveal_delay_seconds", 2.5))
	var since := maxf(_elapsed - hold, 0.0)
	_scale_group(_storm_slabs, _storm_alpha, 1.0 - clampf(since / dissipate, 0.0, 1.0))
	_scale_group(_far_slabs, _far_alpha, clampf((since - reveal_delay) / reveal, 0.0, 1.0))
	if since > maxf(dissipate, reveal_delay + reveal):
		set_process(false)


func _poll_the_flag() -> void:
	if _progression == null:
		return
	var revision := int(_progression.get("revision"))
	if revision == _revision:
		return
	_revision = revision
	if bool(_progression.call("has", _flag)):
		_collapsed = true
		_elapsed = 0.0


## The wall breathes while it is still there, so it reads as live weather
## rather than as a painted backdrop. Tiny on purpose.
func _breathe() -> void:
	var period := maxf(float(_config.get("storm_wall", {}).get("pulse_seconds", 5.5)), 0.1)
	var wave := 0.94 + 0.06 * sin(TAU * _time / period)
	_scale_group(_storm_slabs, _storm_alpha, wave)


func _scale_group(slabs: Array[MeshInstance3D], alphas: Array[float], scale: float) -> void:
	for i in slabs.size():
		var instance := slabs[i]
		if instance == null or not is_instance_valid(instance):
			continue
		var material := instance.material_override as StandardMaterial3D
		if material == null:
			continue
		var alpha := alphas[i] * clampf(scale, 0.0, 1.0)
		material.albedo_color.a = alpha
		instance.visible = alpha > 0.004


func _apply_now() -> void:
	_collapsed = true
	_scale_group(_storm_slabs, _storm_alpha, 0.0)
	_scale_group(_far_slabs, _far_alpha, 1.0)
	set_process(false)


## --- what the test reads ------------------------------------------------------

## The horizon, as a number, from the place SF33 put the seam. Two boots that
## differ only by `legendary_freed` must not produce the same answer here —
## that is SG44's own done-when, and `tests/smoke_boss.gd` asserts it rather
## than trusting a screenshot nobody took.
##
## `cover` is the alpha-weighted area of sky each group is painting, in square
## metres, which is the closest an automated check can honestly get to "what is
## on the horizon". `signature` folds both into one comparable number.
func horizon() -> Dictionary:
	return {
		"spoke": str(_config.get("spoke", "")),
		"origin": _origin,
		"storm_cover": _cover(_storm_slabs),
		"far_cover": _cover(_far_slabs),
		"collapsed": _collapsed,
		"signature": snappedf(_cover(_storm_slabs) - _cover(_far_slabs), 0.01),
	}


func _cover(slabs: Array[MeshInstance3D]) -> float:
	var total := 0.0
	for instance: MeshInstance3D in slabs:
		if instance == null or not is_instance_valid(instance) or not instance.visible:
			continue
		var material := instance.material_override as StandardMaterial3D
		var mesh := instance.mesh as QuadMesh
		if material == null or mesh == null:
			continue
		total += mesh.size.x * mesh.size.y * material.albedo_color.a
	return snappedf(total, 0.01)


## Every mesh this file owns, for the test that proves none of them is anything
## the player could reach: no collider, no area, and all of it well outside the
## boundary ring.
func meshes() -> Array[MeshInstance3D]:
	var all: Array[MeshInstance3D] = []
	all.append_array(_storm_slabs)
	all.append_array(_far_slabs)
	return all


## The seam the player stands at to see it — the spoke's own road end, which is
## where the collapsed bridge stops them.
func seam() -> Vector2:
	var road: Array = _spoke.get("road", [])
	if road.is_empty():
		return Vector2.ZERO
	return _vec2(road[road.size() - 1])


func _vec2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		var list: Array = raw
		return Vector2(float(list[0]), float(list[1]))
	return Vector2.ZERO


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
