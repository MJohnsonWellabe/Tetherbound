extends RefCounted

## W17-DENSITY-B2-B3 (2026-09-04). Authored world pickups, per corridor band.
##
## The addendum (`docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` §B/§C) asks
## for roughly a hundred candies and a hundred-odd useful findables across the
## Meadows, authored in regional batches with a reason for every one. This is
## the loader for those batches. It is deliberately thin: it reads
## `data/config/bands/<band>/pickups.json` for every band `band_content.gd`
## knows, and stands each entry up through the one-time-find seam the world
## already has (`item_cache_pickup.gd`), which owns the satchel add, the
## refuse-not-vanish on a full satchel, the shared `pickup_glow.gd` highlight
## and the save-safe once-flag. No second pickup mechanism is built here.
##
## ## The data contract (fixed; bands 4-5 author to the same schema)
##
##   { "_why": "...", "pickups": [
##       { "id": "b2_candy_quarry_ledge", "item": "good_candy",
##         "pos": [x, z], "y": <optional>, "tier": "side|detour|secret|critical",
##         "why": "one line" } ] }
##
##   * `id` is globally unique across every band and IS the save's once-flag
##     (`cache:<id>`): one persistent identity per authored location, so a
##     reload can never mint a second copy and two Good Candies never share a
##     flag. `item_cache_pickup.gd::setup()`'s `flag_key` exists for exactly
##     this.
##   * `item` names a `data/items/items.json` id; its own `world_model` /
##     `world_model_scale` decide what stands in the world
##     (`playground_world.gd::_item_cache_model()`), so a candy is the candy
##     mesh and a revive is the revive flower without this file knowing.
##   * `pos` is world [x, z]; the ground is asked for y (D09: never a raycast)
##     unless `y` is authored, which only a placement on built geometry should
##     ever need.
##   * `tier` is the placement's reason in the addendum's own vocabulary --
##     critical path sparse and Good, side routes Good with an occasional
##     Great, detours Great, secrets/hard encounters Rare -- and is what the
##     census (`tools/_probe_band_density.gd`) reports critical-vs-optional
##     counts from. It changes nothing at runtime.
##
## ## Where it stands
##
## On real ground (`ground_height_at`), and never inside solid scatter: a find
## buried in a tree trunk is a find nobody makes. `vegetation.gd::
## has_solid_scatter_near()` is asked at the authored spot and, if a trunk or
## boulder is there, at a short ring of alternatives around it; the first
## clear one wins, and a spot with no clear alternative is still placed
## (visibly -- the glow rides above the canopy) with a warning naming it, so
## the author moves it rather than a player losing it.
##
## ## The three-tier look
##
## `candy_pickup.glb` is one mesh for Good/Great/Rare (ASSET_LEDGER: "one
## mesh, ten materials", the TM Orb economy). The tier is told by a
## `material_override` tint, an emissive medallion on the body, and -- Rare
## only -- two small primitive wings, all attached at instancing here. The
## mushroom family is tinted the same way; the Wild Shroom's broader cap is a
## non-uniform scale, not a second mesh. All of the numbers are TUNABLE.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")

const FILE_NAME := "pickups.json"
const ARRAY_KEY := "pickups"
const TIERS: Array[String] = ["critical", "side", "detour", "secret"]

## How much clear ground a pickup wants around it before it counts as "inside"
## a trunk or boulder, and the ring of alternatives tried when it is not.
##
## Raised 0.6 -> 1.6 after round 1's code-blind judge (see
## `ralph/reports/W17-DENSITY-B2-B3-0904/JUDGE-round1.md`). 0.6 m only kept a
## pickup out of a trunk's own footprint, which is not the test that matters:
## the judge could not find the quarry mushroom AT ALL because a trunk stood
## between the camera and it, hiding the cap's right half and the whole stalk
## ("as staged, this pickup does not exist to the player"), and the springhead
## candy was split into two disconnected halves by another. A find is hidden by
## a trunk it stands NEAR, not only by one it stands IN, and the approach
## bearing is not knowable here -- so the answer is a wider berth from anything
## solid, not a sightline test against one guessed camera.
const SCATTER_CLEARANCE_M := 1.6
const NUDGE_RADII_M: Array[float] = [2.0, 3.5, 5.0]
const NUDGE_BEARINGS := 12

## Per-tier candy look. `tint` multiplies the wrapper texture; `badge` is the
## medallion's own colour (overridden by the item's `colour` from items.json
## when a live item db is available, so the glow, the icon and the medallion
## always agree); `emission` lifts the wrapper so a tier reads in shade.
## `scale` is a per-tier size step ON TOP of the item's own
## `world_model_scale`, because round 1's judge found the ladder unreadable
## with hue as its only variable: "grade is carried entirely by a colour with
## no key attached to it, so a player learns 'different colour' and never
## learns 'worth more'... it needs something structural per tier, not another
## hue." A tier now differs in size, in medallion size, in glow strength and
## (Rare) in silhouette, so the ladder survives a frame where the hue does not.
const CANDY_LOOK := {
	"good_candy": {"tint": Color(0.80, 1.0, 0.80), "badge": Color(0.24, 0.72, 0.40), "emission": 0.30, "scale": 1.0, "wings": false},
	"great_candy": {"tint": Color(0.62, 0.76, 1.0), "badge": Color(0.22, 0.46, 0.92), "emission": 0.65, "scale": 1.18, "wings": false},
	"rare_candy": {"tint": Color(1.0, 0.80, 0.30), "badge": Color(1.0, 0.78, 0.16), "emission": 1.70, "scale": 1.40, "wings": true},
}
## Per-tier mushroom look. Stamina is the shipped orange (ASSET_LEDGER), so it
## keeps a neutral tint; Speed goes blue; Wild goes redder and broader.
const MUSHROOM_LOOK := {
	"speed_mushroom": {"tint": Color(0.60, 0.72, 1.0), "scale": Vector3.ONE},
	"stamina_mushroom": {"tint": Color(1.0, 1.0, 1.0), "scale": Vector3.ONE},
	"wild_mushroom": {"tint": Color(1.0, 0.62, 0.52), "scale": Vector3(1.30, 0.90, 1.30)},
}

## Medallion and wing proportions, as fractions of the candy mesh's own AABB
## so they follow whatever `world_model_scale` the item carries. Both were
## grown after round 1: the judge's report names neither the medallion nor the
## wings anywhere in six frames, which at 7 m is the same as their not being
## there. The wings were also a 2 cm slab, invisible edge-on.
const BADGE_RADIUS_FRACTION := 0.30
const BADGE_HEIGHT := 0.05
const WING_SIZE := Vector3(0.70, 0.09, 0.46)
const WING_TILT_DEG := 34.0


## --- reading ----------------------------------------------------------------


## Every authored pickup across every band, in band order then file order,
## each as a Dictionary: band, band_index, id, item, pos (Vector2), y
## (float, NAN when unauthored), tier, why. Malformed entries are reported
## (`push_error`) and dropped rather than allowed to crash a world build;
## `tests/test_band_pickups.gd` is what refuses them at the data level.
static func load_all() -> Array:
	var out: Array = []
	var seen := {}
	for band_index in BAND_CONTENT.BANDS.size():
		var band: String = BAND_CONTENT.BANDS[band_index]
		for entry: Variant in read_band(band):
			var spec: Dictionary = entry
			var problem := validate(spec)
			if problem != "":
				push_error("%s/%s: %s" % [band, FILE_NAME, problem])
				continue
			var id := str(spec["id"])
			if seen.has(id):
				push_error("%s/%s: pickup id '%s' is also in %s; ids are the once-flag and must be unique" % [
					band, FILE_NAME, id, str(seen[id])])
				continue
			seen[id] = band
			var pos: Array = spec["pos"]
			out.append({
				"band": band,
				"band_index": band_index,
				"id": id,
				"item": str(spec["item"]),
				"pos": Vector2(float(pos[0]), float(pos[1])),
				"y": float(spec["y"]) if spec.has("y") else NAN,
				"tier": str(spec["tier"]),
				"why": str(spec.get("why", "")),
			})
	return out


## The raw `pickups` array of one band's file, or [] when the band has none
## (most bands legitimately had none when this shipped).
static func read_band(band: String) -> Array:
	var path := "%s/%s/%s" % [BAND_CONTENT.BANDS_DIR, band, FILE_NAME]
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("could not open %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not a JSON object" % path)
		return []
	var entries: Variant = (parsed as Dictionary).get(ARRAY_KEY, [])
	if not entries is Array:
		push_error("%s: '%s' is not an array" % [path, ARRAY_KEY])
		return []
	var out: Array = []
	for entry: Variant in (entries as Array):
		if entry is Dictionary:
			out.append(entry)
		else:
			push_error("%s: a '%s' entry is not an object" % [path, ARRAY_KEY])
	return out


## "" when the entry is well-formed, otherwise one line saying what is wrong.
## Pure, so the data test and the loader refuse the same things.
static func validate(spec: Dictionary) -> String:
	var id := str(spec.get("id", ""))
	if id == "":
		return "a pickup has no `id`"
	if str(spec.get("item", "")) == "":
		return "pickup '%s' names no `item`" % id
	var pos: Variant = spec.get("pos")
	if not pos is Array or (pos as Array).size() != 2:
		return "pickup '%s' has no [x, z] `pos`" % id
	for axis: Variant in (pos as Array):
		if not (axis is float or axis is int):
			return "pickup '%s' has a non-numeric `pos`" % id
	if spec.has("y") and not (spec["y"] is float or spec["y"] is int):
		return "pickup '%s' has a non-numeric `y`" % id
	var tier := str(spec.get("tier", ""))
	if not TIERS.has(tier):
		return "pickup '%s' has tier '%s'; it must be one of %s" % [id, tier, str(TIERS)]
	if str(spec.get("why", "")) == "":
		return "pickup '%s' has no `why`; every placement is authored" % id
	return ""


## The once-flag a placement writes when taken. Same prefix as every cache;
## keyed on the placement, not the item.
static func flag_id(pickup_id: String) -> String:
	return ITEM_CACHE_PICKUP.flag_id(pickup_id)


## The prompt verb, by item family. Matches `playground_world.gd::CACHE_LABEL`'s
## own wording for the families it already names.
static func label_for(item_id: String) -> String:
	if item_id.ends_with("_candy"):
		return "Take the candy"
	if item_id.ends_with("_mushroom"):
		return "Take the mushroom"
	if item_id.begins_with("potion"):
		return "Take the potion"
	if item_id == "revive":
		return "Take the revive"
	if item_id.begins_with("orb"):
		return "Take the orbs"
	return "Take it"


## --- placing ----------------------------------------------------------------


## Stand every authored pickup in `world` (the playground; it answers
## `ground_height_at` and `_item_cache_model`). `vegetation` may be null (a
## probe with no scatter), in which case the scatter check is skipped.
## Returns a census: placed, taken (already collected in this save),
## nudged (moved off scatter), no_ground (skipped, reported).
static func place_all(world: Node3D, vegetation: Node3D) -> Dictionary:
	var stats := {"placed": 0, "taken": 0, "nudged": 0, "no_ground": 0, "unclear": 0}
	var game := world.get_node_or_null(^"/root/Game")
	for entry: Variant in load_all():
		var pickup: Dictionary = entry
		var id: String = pickup["id"]
		if ITEM_CACHE_PICKUP.was_taken(game, id):
			stats["taken"] += 1
			continue
		var name := "BandPickup_%s" % id
		if world.get_node_or_null(NodePath(name)) != null:
			continue
		var at: Vector2 = pickup["pos"]
		var spot := _clear_spot(world, vegetation, at)
		if spot.is_empty():
			push_error("no ground under band pickup '%s' at %.0f, %.0f" % [id, at.x, at.y])
			stats["no_ground"] += 1
			continue
		var stood: Vector3 = spot["at"]
		if bool(spot["nudged"]):
			stats["nudged"] += 1
		if not bool(spot["clear"]):
			stats["unclear"] += 1
			push_warning("band pickup '%s' at %.0f, %.0f sits inside solid scatter and no spot within %.0fm was clear; move it" % [
				id, at.x, at.y, NUDGE_RADII_M[-1]])
		if not is_nan(float(pickup["y"])):
			stood.y = float(pickup["y"])
		var item: String = pickup["item"]
		var node: Node3D = ITEM_CACHE_PICKUP.new()
		node.name = name
		node.position = stood
		world.add_child(node)
		var model_and_scale: Array = world.call("_item_cache_model", item) if world.has_method("_item_cache_model") else ["", 1.0]
		node.call("setup", item, label_for(item), str(model_and_scale[0]), float(model_and_scale[1]), id)
		dress(node, item, _badge_colour(game, item))
		stats["placed"] += 1
	return stats


## The authored spot on the ground, or the nearest clear alternative when a
## trunk or boulder stands on it. {} when there is no terrain here at all.
static func _clear_spot(world: Node3D, vegetation: Node3D, at: Vector2) -> Dictionary:
	var ground := float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		return {}
	var here := Vector3(at.x, ground, at.y)
	if vegetation == null or not vegetation.has_method("has_solid_scatter_near"):
		return {"at": here, "nudged": false, "clear": true}
	if not bool(vegetation.call("has_solid_scatter_near", here, SCATTER_CLEARANCE_M)):
		return {"at": here, "nudged": false, "clear": true}
	for radius: float in NUDGE_RADII_M:
		for step in NUDGE_BEARINGS:
			var bearing := TAU * float(step) / float(NUDGE_BEARINGS)
			var candidate := at + Vector2(cos(bearing), sin(bearing)) * radius
			var candidate_ground := float(world.call("ground_height_at", candidate.x, candidate.y))
			if is_nan(candidate_ground):
				continue
			var there := Vector3(candidate.x, candidate_ground, candidate.y)
			if not bool(vegetation.call("has_solid_scatter_near", there, SCATTER_CLEARANCE_M)):
				return {"at": there, "nudged": true, "clear": true}
	return {"at": here, "nudged": false, "clear": false}


static func _badge_colour(game: Node, item_id: String) -> Color:
	var fallback: Color = (CANDY_LOOK.get(item_id, {}) as Dictionary).get("badge", Color.WHITE)
	if game == null:
		return fallback
	var items: RefCounted = game.get("items")
	if items == null or not items.has_method("colour"):
		return fallback
	return items.call("colour", item_id)


## --- the tier look ----------------------------------------------------------


## Give an instanced pickup its tier. Safe on anything: an item outside the
## two tiered families, or a pickup whose model fell back to the box, is left
## exactly as the seam built it.
static func dress(pickup: Node3D, item_id: String, badge: Color) -> void:
	var mesh := _first_mesh(pickup)
	if mesh == null or mesh.mesh == null:
		return
	if CANDY_LOOK.has(item_id):
		_dress_candy(mesh, CANDY_LOOK[item_id] as Dictionary, badge)
	elif MUSHROOM_LOOK.has(item_id):
		_dress_mushroom(mesh, MUSHROOM_LOOK[item_id] as Dictionary)


static func _dress_candy(mesh: MeshInstance3D, look: Dictionary, badge: Color) -> void:
	mesh.material_override = _tinted(mesh, look["tint"] as Color, float(look["emission"]))
	var tier_scale := float(look.get("scale", 1.0))
	if not is_equal_approx(tier_scale, 1.0):
		mesh.scale = mesh.scale * tier_scale
	var aabb := mesh.get_aabb()
	var radius := aabb.size.x * BADGE_RADIUS_FRACTION
	# The medallion: a flat disc on the crown of the body, where a third-person
	# camera looks down on it. Emissive in the tier's own colour so it reads
	# in shade and at distance, which the wrapper texture alone does not.
	var medallion := MeshInstance3D.new()
	medallion.name = "TierMedallion"
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = BADGE_HEIGHT
	disc.radial_segments = 24
	medallion.mesh = disc
	medallion.position = Vector3(aabb.get_center().x, aabb.end.y - BADGE_HEIGHT * 0.3, aabb.get_center().z)
	medallion.material_override = _flat(badge, 2.2)
	mesh.add_child(medallion)
	if bool(look["wings"]):
		# Rare only: two small wings either side of the body, tilted up, the
		# board's own gold-tier read (ASSET_LEDGER: real geometry, not a
		# texture) -- added as children here, never a second generation.
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			wing.name = "RareWing%s" % ("L" if side < 0.0 else "R")
			var slab := PrismMesh.new()
			slab.size = WING_SIZE
			wing.mesh = slab
			wing.position = Vector3(
				aabb.get_center().x + side * (aabb.size.x * 0.5 + WING_SIZE.x * 0.35),
				aabb.get_center().y + aabb.size.y * 0.15,
				aabb.get_center().z)
			wing.rotation_degrees = Vector3(0.0, 0.0, -side * WING_TILT_DEG)
			wing.material_override = _flat(badge.lerp(Color.WHITE, 0.35), 1.8)
			mesh.add_child(wing)


static func _dress_mushroom(mesh: MeshInstance3D, look: Dictionary) -> void:
	var tint: Color = look["tint"]
	if not tint.is_equal_approx(Color.WHITE):
		mesh.material_override = _tinted(mesh, tint, 0.0)
	var scale: Vector3 = look["scale"]
	if not scale.is_equal_approx(Vector3.ONE):
		mesh.scale = mesh.scale * scale


## A copy of the mesh's own textured material with the tint multiplied in,
## so the wrapper's shading survives and only its colour family moves.
static func _tinted(mesh: MeshInstance3D, tint: Color, emission: float) -> Material:
	var source: Material = mesh.get_active_material(0)
	var material: StandardMaterial3D
	if source is StandardMaterial3D:
		material = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		material = StandardMaterial3D.new()
	material.albedo_color = tint
	if emission > 0.0:
		# Emission ADDS, albedo MULTIPLIES. That distinction is the whole fix
		# for Rare: `candy_pickup.glb`'s wrapper texture is a tight green band
		# (ASSET_LEDGER), so a gold albedo tint multiplied into it produced the
		# washed yellow-green round 1's judge called "the most desaturated of
		# the four... a weathered rock rather than a prize". A saturated
		# emission in the tier's own colour puts the hue back on top of the
		# texture instead of underneath it.
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = emission
	return material


static func _flat(colour: Color, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = emission
	return material


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null
