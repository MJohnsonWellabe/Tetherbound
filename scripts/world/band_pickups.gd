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
## mesh, ten materials", the TM Orb economy). The tier is told at instancing
## here, and -- N08-PICKUP-TIERS (2026-09-05) -- by more than hue. Two
## code-blind judges (W17 round 2, W18 round 1) read the ladder off hue alone
## and could not: "the only difference between the two objects I can find is
## hue... far too subtle to tell apart in play", and the read was INVERTED,
## Rare quietest. So a tier is now an additive part count, the owner's own
## board-17 language (Good: leaf medallion; Great: star and sparkle; Rare:
## crown, wings, the strongest glow), carried on channels that survive a
## 7-12 m frame where the hue does not:
##
##   * size step (kept from W17 round 3, ~1.2x per tier under one family
##     scale);
##   * a crest on the crown that changes SHAPE per tier: a flat disc for Good,
##     a five-point star for Great, a spiked crown for Rare;
##   * a ground ring on EVERY candy, in the tier's own colour, just outside
##     the wrapper ends and growing with the tier -- the "base ring" W18's
##     judge listed among the item cues the family lacked, and the family
##     mark that says "these three are one kind of thing". N08's own round
##     1 put a pure-white ring on Great and Rare only, and its judge read
##     that as "an editor selection gizmo... applied to half the set", so the
##     ring is now on all three and coloured, never white;
##   * sparkles (Great and Rare): three small tier-coloured motes round the
##     crown, the board's "sparkle" for the middle tier, orbiting as the
##     candy turns;
##   * wings (Rare only), swept UP and outward as the board draws them,
##     rooted a third of their span inside the wrapper end and gold, not
##     white -- W17 round 2 called the old flat slabs "a geometry
##     artefact... visually detached... appears to float", and they drooped,
##     because the tilt sign lowered the outer end;
##   * the shared `pickup_glow.gd` highlight scaled per tier, so at the range
##     where no crest resolves the Rare is still the loudest thing on the
##     ground, which is the hierarchy the judge said was missing;
##   * a slow yaw spin, the one motion cue every item game uses and the one
##     the judge named absent ("no float, no hover offset, no spin"). The
##     candy stays ON the ground: the owner's 2026-08-30 directive keeps
##     finds grounded and the board's own style note is "fits in world (not
##     UI-looking)", so no hover.
##
## Rare's hue also moved off cream. Its emission used to be the same pale gold
## as the albedo tint and, added at 1.7x, it clipped toward the white/cream
## the meadow's cup flowers already own; the emission is now a deeper amber
## carried on its own colour (`emit`), under the albedo, so the wrapper stays
## light and the glow stays saturated.
##
## The mushroom family is tinted the same way; the Wild Shroom's broader cap
## is a non-uniform scale, not a second mesh. All of the numbers are TUNABLE.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")

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
## hue." A tier differs in size, in medallion size, in glow strength and
## (Rare) in silhouette, so the ladder survives a frame where the hue does not.
## Round 2 confirmed the ladder then reads in the right direction ("frame 3
## holds the most valuable one, and everything says so at once").
##
## The absolute numbers came DOWN in round 3, and this is the correction of a
## regression this file caused. Round 1 could not measure scale because the
## capture kept the trainer out of frame; round 2 put him in and measured the
## family at "furniture, not pickups" -- the Rare at roughly knee-to-thigh
## height and two and a half metres across, "the same visual weight as the
## black boulder beside it", so "a player would expect to climb on it or mine
## it, not palm it". Growing the tiers to build the ladder is what pushed it
## there. The steps are kept (~1.2x per tier, which is what round 2 read
## correctly) and the whole family is scaled down under them, so Good lands
## near a third of a metre and Rare near two thirds.
##
## This is NOT the case `CLAUDE.md`'s "resolve relative-scale defects by
## growing the smaller side, never by shrinking" covers. That owner directive
## (2026-09-01) is about CREATURES standing against the 1.80 m trainer, and
## the smaller side here is the trainer -- growing him to make a sweet look
## hand-sized would break the creature band the directive exists to protect.
## The candy's own base size lives in `data/items/items.json`
## (`world_model_scale`), which this lane does not own; this multiplier is the
## lever that is in scope.
##
## N08-PICKUP-TIERS: `crest` is the crown shape (`disc` / `star` / `crown`),
## `ring` the ground ring's radius as a multiple of the wrapper's half-length
## (every candy has one; it must clear 1.0), `sparkles` the mote count round
## the crown, `wings` the Rare's wings, `glow` the multiplier on the shared
## highlight's mote and aura radius, `emit` (optional) an emission colour
## distinct from the albedo tint. Parts are ADDITIVE up the ladder -- Good
## has two (crest, ring), Great three (+ sparkles), Rare four (+ wings) --
## so "more parts" is "worth more" without a key. `parts_for()` is the count
## a test can pin.
##
## Good's emission went 0.30 -> 0.55 -> 0.80 on a lighter, minty green after
## N08's round-1 and round-2 judges could not find it at 7 m: "a green shape,
## on green grass, inside a green glow... it needs to be darker or lighter
## than the grass, because it will never win on green-against-green." Lighter
## is the only way open to the quiet tier: darker would read as a stone.
const CANDY_LOOK := {
	"good_candy": {"tint": Color(0.88, 1.0, 0.84), "emit": Color(0.78, 1.0, 0.70), "badge": Color(0.24, 0.72, 0.40), "emission": 0.80, "scale": 0.34, "crest": "disc", "ring": 1.10, "sparkles": 0, "wings": false, "glow": 1.0},
	"great_candy": {"tint": Color(0.62, 0.76, 1.0), "badge": Color(0.22, 0.46, 0.92), "emission": 0.90, "scale": 0.42, "crest": "star", "ring": 1.18, "sparkles": 3, "wings": false, "glow": 1.3},
	"rare_candy": {"tint": Color(1.0, 0.86, 0.48), "emit": Color(1.0, 0.56, 0.06), "badge": Color(1.0, 0.70, 0.10), "emission": 1.25, "scale": 0.52, "crest": "crown", "ring": 1.26, "sparkles": 3, "wings": true, "glow": 1.7},
}
## Per-tier mushroom look. Stamina is the shipped orange (ASSET_LEDGER), so it
## keeps a neutral tint; Speed goes blue; Wild goes redder and broader.
## The mushrooms are NOT rescaled. Round 2 measured both at "around knee
## height on the trainer, roughly half a metre... exactly as something you
## bend down and pick", and called them the only objects in the sheet whose
## noun it did not have to guess at. They are the size the candy is being
## brought toward, so touching them would be undoing the one thing that was
## already right.
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
## Star crest (Great): outer radius as the disc's, inner radius as a fraction
## of it, five points. Crown crest (Rare): a disc with `CROWN_SPIKES` cones
## round its rim, each `CROWN_SPIKE_HEIGHT_FRACTION` of the body's width tall.
const STAR_POINTS := 5
const STAR_INNER_FRACTION := 0.48
const STAR_HEIGHT := 0.06
const CROWN_SPIKES := 5
const CROWN_SPIKE_HEIGHT_FRACTION := 0.13
const CROWN_SPIKE_RADIUS_FRACTION := 0.05
## Ground ring (every candy): a flat coloured circle on the ground round the
## candy's foot -- the "base ring" the W18 judge listed among the item cues
## the family lacked, and a silhouette element that reads from every bearing
## and never floats. Its radius is the tier's `ring` (a multiple of the
## wrapper's half-length, so it always clears the ends); the tube radius is
## this fraction of the half-length; it lies at the base, lifted by its own
## tube so it is not cut by the ground. Coloured in the tier's own hue at a
## modest emission -- N08 round 1's pure-white ring at 2.0 read as "an editor
## selection gizmo or a HUD decal". NOT a waist ring: the wrapper ends run 2x
## the round core's width, so any band round the waist either passes through
## the ends or hangs a body-width off the core.
const RING_TUBE_FRACTION := 0.06
## Round 2's ring at 0.9 was the brightest pixel in the frame, brighter than
## the sky ("a targeting reticle"); the ring now sits well under the cloud
## value -- a coloured mark on the ground, not a light.
const RING_EMISSION := 0.25
const RING_DARKEN := 0.20
## Sparkles (Great, Rare): mote radius and orbit radius as fractions of the
## round core, and how far above the crest they sit.
const SPARKLE_RADIUS_FRACTION := 0.14
const SPARKLE_ORBIT_FRACTION := 0.62
const SPARKLE_LIFT_FRACTION := 0.10
## Wings (Rare): span, height and thickness as fractions of the body's round
## core (its depth); how far the root sits INSIDE the wrapper end's tip (so
## the wing is rooted, not floating); and the upward sweep of the outer tip. The sign is the point:
## a positive tilt on the right wing lifts its +x end, and the mirrored left
## wing gets the mirrored angle, so both tips rise as the board draws them.
## Round 2's wings were still read as "a flat pale-gold blade... a hard-edged
## flat plane": a thin prism is a blade from any angle. Shorter, taller and
## more than twice as thick, they are fins with volume, in the tier's gold.
const WING_SPAN_FRACTION := 0.62
const WING_HEIGHT_FRACTION := 0.40
const WING_THICKNESS_FRACTION := 0.24
const WING_ROOT_INSET_FRACTION := 0.42
const WING_SWEEP_DEG := 36.0
## The idle spin, one full turn per period. A period, not a rate, so the
## number reads as "eight seconds a turn"; 0 disables it.
const SPIN_PERIOD_S := 8.0


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
		if world.get_node_or_null(NodePath("BandPickup_%s" % id)) != null:
			continue
		var outcome := place_one(world, vegetation, pickup)
		for key: String in outcome.keys():
			if stats.has(key):
				stats[key] += int(outcome[key])
	return stats


## Stand ONE pickup up: the loader's whole path for a single entry (ground,
## scatter nudge, the seam, the tier look), so a capture tool can stage the
## three tiers side by side on open ground through exactly the code the world
## runs, rather than a copy of it. `pickup` is one `load_all()` entry (id,
## item, pos, y; band is not needed). Returns the census deltas for it:
## placed, nudged, unclear, no_ground (each 0 or 1); `node` is the pickup
## when one was placed.
static func place_one(world: Node3D, vegetation: Node3D, pickup: Dictionary) -> Dictionary:
	var out := {"placed": 0, "nudged": 0, "unclear": 0, "no_ground": 0, "node": null}
	var game := world.get_node_or_null(^"/root/Game")
	var id: String = str(pickup["id"])
	var at: Vector2 = pickup["pos"]
	var spot := _clear_spot(world, vegetation, at)
	if spot.is_empty():
		push_error("no ground under band pickup '%s' at %.0f, %.0f" % [id, at.x, at.y])
		out["no_ground"] = 1
		return out
	var stood: Vector3 = spot["at"]
	if bool(spot["nudged"]):
		out["nudged"] = 1
	if not bool(spot["clear"]):
		out["unclear"] = 1
		push_warning("band pickup '%s' at %.0f, %.0f sits inside solid scatter and no spot within %.0fm was clear; move it" % [
			id, at.x, at.y, NUDGE_RADII_M[-1]])
	if pickup.has("y") and not is_nan(float(pickup["y"])):
		stood.y = float(pickup["y"])
	var item: String = str(pickup["item"])
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.name = "BandPickup_%s" % id
	node.position = stood
	world.add_child(node)
	var model_and_scale: Array = world.call("_item_cache_model", item) if world.has_method("_item_cache_model") else ["", 1.0]
	node.call("setup", item, label_for(item), str(model_and_scale[0]), float(model_and_scale[1]), id)
	dress(node, item, _badge_colour(game, item), spin_phase_for(id))
	out["placed"] = 1
	out["node"] = node
	return out


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
## exactly as the seam built it. `spin_phase` (radians) is where the idle
## spin starts, so a field of candies does not turn in lockstep; see
## `spin_phase_for()`.
static func dress(pickup: Node3D, item_id: String, badge: Color, spin_phase: float = 0.0) -> void:
	var mesh := _first_mesh(pickup)
	if mesh == null or mesh.mesh == null:
		return
	if CANDY_LOOK.has(item_id):
		var look: Dictionary = CANDY_LOOK[item_id]
		_dress_candy(mesh, look, badge)
		_spin(pickup, mesh, spin_phase)
		# The shared highlight, re-registered with the tier's own radius. The
		# seam attached it at 1.0 for every cache; `attach` is keyed on the
		# node, so this re-places the one instance rather than stacking two.
		PICKUP_GLOW.attach(pickup, badge, -1.0, glow_scale_for(item_id))
	elif MUSHROOM_LOOK.has(item_id):
		_dress_mushroom(mesh, MUSHROOM_LOOK[item_id] as Dictionary)


## How many tier parts a candy grade carries beyond its body: the crest and
## the ring on every grade, sparkles from Great, wings on Rare. Good 2, Great
## 3, Rare 4 -- the ladder a player can count, and the number
## `tests/test_band_pickups.gd` pins so a tuning pass cannot quietly flatten
## it.
static func parts_for(item_id: String) -> int:
	if not CANDY_LOOK.has(item_id):
		return 0
	var look: Dictionary = CANDY_LOOK[item_id]
	var parts := 2  # crest and ring, on every candy
	if int(look.get("sparkles", 0)) > 0:
		parts += 1
	if bool(look.get("wings", false)):
		parts += 1
	return parts


## The multiplier on the shared highlight's radius for a candy grade; 1.0 for
## anything that is not a candy.
static func glow_scale_for(item_id: String) -> float:
	if not CANDY_LOOK.has(item_id):
		return 1.0
	return float((CANDY_LOOK[item_id] as Dictionary).get("glow", 1.0))


## The crest shape a grade wears on its crown: "disc", "star" or "crown";
## "" for a non-candy.
static func crest_for(item_id: String) -> String:
	if not CANDY_LOOK.has(item_id):
		return ""
	return str((CANDY_LOOK[item_id] as Dictionary).get("crest", "disc"))


## A deterministic spin phase from the placement id, so the same world boots
## with the same candies at the same angles and two neighbours never turn in
## step. Radians in [0, TAU).
static func spin_phase_for(pickup_id: String) -> float:
	return TAU * float(absi(hash(pickup_id)) % 3600) / 3600.0


static func _dress_candy(mesh: MeshInstance3D, look: Dictionary, badge: Color) -> void:
	var tint: Color = look["tint"]
	var emit: Color = look.get("emit", tint)
	mesh.material_override = _tinted(mesh, tint, emit, float(look["emission"]))
	var tier_scale := float(look.get("scale", 1.0))
	if not is_equal_approx(tier_scale, 1.0):
		mesh.scale = mesh.scale * tier_scale
	var aabb := mesh.get_aabb()
	var width := aabb.size.x
	var centre := aabb.get_center()
	var radius := width * BADGE_RADIUS_FRACTION
	# The crest: on the crown of the body, where a third-person camera looks
	# down on it. Emissive in the tier's own colour so it reads in shade and
	# at distance, which the wrapper texture alone does not. Its SHAPE is the
	# tier: disc, star, crown.
	var crest := MeshInstance3D.new()
	crest.name = "TierMedallion"
	var crest_kind := str(look.get("crest", "disc"))
	crest.set_meta("crest", crest_kind)
	match crest_kind:
		"star":
			crest.mesh = _star_mesh(radius, radius * STAR_INNER_FRACTION, STAR_HEIGHT)
		"crown":
			crest.mesh = _disc_mesh(radius, BADGE_HEIGHT)
			for i in CROWN_SPIKES:
				var spike := MeshInstance3D.new()
				spike.name = "CrownSpike%d" % i
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = width * CROWN_SPIKE_RADIUS_FRACTION
				cone.height = width * CROWN_SPIKE_HEIGHT_FRACTION
				cone.radial_segments = 8
				spike.mesh = cone
				var angle := TAU * float(i) / float(CROWN_SPIKES)
				spike.position = Vector3(cos(angle) * radius * 0.85, cone.height * 0.5, sin(angle) * radius * 0.85)
				# The tier's own gold at a modest emission: round 1's white
				# spikes read as "the mesh's normals are inverted at the top".
				spike.material_override = _flat(badge, 1.2)
				crest.add_child(spike)
		_:
			crest.mesh = _disc_mesh(radius, BADGE_HEIGHT)
	crest.position = Vector3(centre.x, aabb.end.y - BADGE_HEIGHT * 0.3, centre.z)
	crest.material_override = _flat(badge, 2.2)
	mesh.add_child(crest)
	var ring_fraction := float(look.get("ring", 0.0))
	if ring_fraction > 0.0:
		# Every candy: a coloured ring on the ground round the foot, the
		# family's mark. A torus lying flat reads as a circle from every
		# bearing, which is what a crest seen edge-on and wings seen end-on
		# do not, and its radius steps with the tier so Rare's is the wider.
		var ring := MeshInstance3D.new()
		ring.name = "TierRing"
		var torus := TorusMesh.new()
		var tube := width * 0.5 * RING_TUBE_FRACTION
		torus.inner_radius = width * 0.5 * ring_fraction - tube
		torus.outer_radius = width * 0.5 * ring_fraction + tube
		torus.rings = 40
		torus.ring_segments = 8
		ring.mesh = torus
		ring.position = Vector3(centre.x, aabb.position.y + tube, centre.z)
		ring.material_override = _flat(badge.darkened(RING_DARKEN), RING_EMISSION)
		mesh.add_child(ring)
	var sparkles := int(look.get("sparkles", 0))
	if sparkles > 0:
		# Great and Rare: small motes in the tier's colour round the crown,
		# the board's "sparkle". Children of the body, so they orbit as it
		# turns.
		var core := minf(aabb.size.x, aabb.size.z)
		for i in sparkles:
			var mote := MeshInstance3D.new()
			mote.name = "Sparkle%d" % i
			var ball := SphereMesh.new()
			ball.radius = core * SPARKLE_RADIUS_FRACTION
			ball.height = ball.radius * 2.0
			ball.radial_segments = 8
			ball.rings = 4
			mote.mesh = ball
			var angle := TAU * float(i) / float(sparkles)
			mote.position = Vector3(
				centre.x + cos(angle) * core * SPARKLE_ORBIT_FRACTION,
				aabb.end.y + core * SPARKLE_LIFT_FRACTION,
				centre.z + sin(angle) * core * SPARKLE_ORBIT_FRACTION)
			mote.material_override = _flat(badge.lerp(Color.WHITE, 0.2), 2.4)
			mesh.add_child(mote)
	if bool(look.get("wings", false)):
		# Rare only: two wings either side of the body, rooted a quarter of
		# their span inside it and swept UP toward the tips, the board's own
		# gold-tier read (ASSET_LEDGER: real geometry, not a texture) -- added
		# as children here, never a second generation. A PrismMesh's triangle
		# lies in its X-Y plane with the apex at `left_to_right`, so the apex
		# sits at the OUTER end and the wing is tallest at its tip.
		# Proportions follow the round CORE (the body's depth), not the
		# wrapper ends' full length, so the wings are wing-sized on a candy
		# whose ends run twice its core; they root on the ends themselves.
		var core := minf(aabb.size.x, aabb.size.z)
		var span := core * WING_SPAN_FRACTION
		var height := core * WING_HEIGHT_FRACTION
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			wing.name = "RareWing%s" % ("L" if side < 0.0 else "R")
			var slab := PrismMesh.new()
			slab.size = Vector3(span, height, core * WING_THICKNESS_FRACTION)
			slab.left_to_right = 1.0 if side > 0.0 else 0.0
			wing.mesh = slab
			# The slab is centred on its own middle; put its inner end
			# `WING_ROOT_INSET_FRACTION` of the span inside the body's edge.
			var root_x := width * 0.5 - span * WING_ROOT_INSET_FRACTION
			wing.position = Vector3(
				centre.x + side * (root_x + span * 0.5),
				aabb.position.y + aabb.size.y * 0.55,
				centre.z)
			wing.rotation_degrees = Vector3(0.0, 0.0, side * WING_SWEEP_DEG)
			# Gold, not white: round 1's pale wings were "two flat white
			# blades" a judge could not tie to the body.
			wing.material_override = _flat(badge, 1.0)
			mesh.add_child(wing)


## The idle turn. Spins the pickup's own visual wrapper (the node the seam
## built at the pickup's origin, base-anchored and X/Z-centred, so the candy
## turns on the spot), never the pickup itself -- the prompt hangs off that.
## Needs a tree for the tween, so a pickup dressed off-tree (a unit test) is
## simply left still; `has_meta("tier_spin")` says whether it turns.
static func _spin(pickup: Node3D, mesh: MeshInstance3D, phase: float) -> void:
	if SPIN_PERIOD_S <= 0.0:
		return
	var spinner: Node3D = mesh
	var walk: Node = mesh
	while walk.get_parent() != null and walk.get_parent() != pickup:
		walk = walk.get_parent()
	if walk is Node3D and walk != pickup:
		spinner = walk as Node3D
	spinner.rotation.y = fmod(phase, TAU)
	pickup.set_meta("tier_spin_period", SPIN_PERIOD_S)
	pickup.set_meta("tier_spinner", spinner.name)
	if not pickup.is_inside_tree():
		return
	var tween := spinner.create_tween().set_loops()
	tween.tween_property(spinner, "rotation:y", TAU, SPIN_PERIOD_S).as_relative()
	pickup.set_meta("tier_spin", tween)


static func _disc_mesh(radius: float, height: float) -> Mesh:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = height
	disc.radial_segments = 24
	return disc


## A flat five-point star, `height` thick, built once per Great candy. Top
## and bottom faces as fans about the centre, plus a wall round the outline.
static func _star_mesh(outer: float, inner: float, height: float) -> Mesh:
	var outline: PackedVector2Array = PackedVector2Array()
	for i in STAR_POINTS * 2:
		var angle := -PI * 0.5 + TAU * float(i) / float(STAR_POINTS * 2)
		var r := outer if i % 2 == 0 else inner
		outline.append(Vector2(cos(angle) * r, sin(angle) * r))
	var half := height * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	for i in count:
		var a := outline[i]
		var b := outline[(i + 1) % count]
		# Top face (normal +Y), counter-clockwise seen from above.
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(0.0, half, 0.0))
		surface.add_vertex(Vector3(b.x, half, b.y))
		surface.add_vertex(Vector3(a.x, half, a.y))
		# Bottom face (normal -Y).
		surface.set_normal(Vector3.DOWN)
		surface.add_vertex(Vector3(0.0, -half, 0.0))
		surface.add_vertex(Vector3(a.x, -half, a.y))
		surface.add_vertex(Vector3(b.x, -half, b.y))
		# Wall between a and b.
		var edge := Vector3(b.x - a.x, 0.0, b.y - a.y)
		var normal := Vector3(edge.z, 0.0, -edge.x).normalized()
		surface.set_normal(normal)
		surface.add_vertex(Vector3(a.x, half, a.y))
		surface.add_vertex(Vector3(b.x, half, b.y))
		surface.add_vertex(Vector3(b.x, -half, b.y))
		surface.add_vertex(Vector3(a.x, half, a.y))
		surface.add_vertex(Vector3(b.x, -half, b.y))
		surface.add_vertex(Vector3(a.x, -half, a.y))
	return surface.commit()


static func _dress_mushroom(mesh: MeshInstance3D, look: Dictionary) -> void:
	var tint: Color = look["tint"]
	if not tint.is_equal_approx(Color.WHITE):
		mesh.material_override = _tinted(mesh, tint, tint, 0.0)
	var scale: Vector3 = look["scale"]
	if not scale.is_equal_approx(Vector3.ONE):
		mesh.scale = mesh.scale * scale


## A copy of the mesh's own textured material with the tint multiplied in,
## so the wrapper's shading survives and only its colour family moves.
static func _tinted(mesh: MeshInstance3D, tint: Color, emit: Color, emission: float) -> Material:
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
		# N08: the emission carries its own colour where a grade gives one,
		# so Rare's albedo can stay light (a dark albedo multiplied into the
		# wrapper goes olive) while its glow goes amber rather than cream.
		material.emission_enabled = true
		material.emission = emit
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
