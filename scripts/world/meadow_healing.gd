extends Node3D

## SG46 — the Meadows answers, and D41's third clause: the whole meadow is
## freed and the drained ground heals.
##
## Spec §9. One flag — `legendary_freed`, set exactly once by
## `stronghold_climax.gd` — and everything the region does about it in one
## place, because the failure §9 warns about is a world that changes in three
## systems and forgets the fourth. What it does, all of it keyed on that flag:
##
##   * THE LAND HEALS. `vegetation.restore_drained()` puts back the exact
##     instances the drain took out of the scatter, the relay's and the
##     approach's runtime drain skins fade, and a runtime REGREEN fades in over
##     the baked scars (see below).
##   * THE NETWORK DIES. Every lit pylon, glowing conduit and Team Tether
##     fitting in the region and inside the stronghold goes to its own dead
##     material. §9's "stronghold effects change", D41's "the drain network
##     dies with the stronghold machinery", one pass. Then the dead pylons of
##     the quarry, relay and approach runs FALL, and their hanging cables go.
##   * THE HERD COMES BACK. A returning Meadowhart herd stands on the Highfield
##     around the freed Veridian's site, whatever the Veridian answer was.
##   * BARRIERS DEACTIVATE. The keyed gates stand open, through their own
##     flags, so a reload opens them for the ordinary reason.
##   * PATROLS THIN. Team Tether trainers the player has ALREADY BEATEN are
##     withdrawn. Nobody unbeaten is removed and no defeat flag is cleared:
##     beaten trainers stay beaten, which is the half of "density drops" that
##     is easy to break by being clever.
##
## THE BAKED HALF, AND THE OWNER'S ANSWER TO IT. `D45` decided the drained-
## ground grammar as one authored radius with three consumers: the scatter and
## the runtime skins are live scene state, the third is the terrain BAKE, whose
## colour and control maps nothing at run time can repaint. This node used to
## leave that discolouration standing as "the honest remainder". The owner has
## since decided "the land heals" at the finale WITHOUT a re-bake and with
## installed assets only: the baked tint stays as the BEFORE state, and a
## runtime regreen overlay -- the installed meadow grass texture, world
## triplanar, alpha shaped by each station's own authored falloff -- fades in
## over it and persists. Same shape as the dead-ground skins it crossfades
## with, the opposite colour. All of it is re-derived from `legendary_freed`
## on every peer and every load; nothing new is saved.
##
## Nothing here is built from scratch on the flag: this node re-uses the live/
## dead material pair `severed_spokes.gd` already ships, the placements
## `vegetation.gd` already holds, the pose `road_gate.gd` already has and the
## bodies `trainer_npc.gd` already stood up.

const CONFIG_PATH := "res://data/config/meadow_healing.json"
## CL-E12: where the authored drain radii live. The same block
## `playground_heightfield.drain_factor()` reads, so a local heal and the drain
## it undoes are answering the same numbers.
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
## Set on a pylon the moment it is committed to falling, so a second `apply`
## (or any second pass) can never rotate an already-fallen pylon again.
const TOPPLED_META := &"meadow_toppled"

var _config: Dictionary = {}
var _world: Node3D = null
var _progression: RefCounted = null
var _applied: bool = false
var _flag := "legendary_freed"
## Last `progression.revision` this node compared the flag against.
var _revision: int = -1
var _journal_check_in: float = 1.0
var _report: Dictionary = {}
## F05 / WORLD §3.2: the unengageable Stag among the healed Highfield herd,
## standing only while every eligible participant has refused. Null otherwise.
var _herd_display: Node3D = null
## The `legendary_resolution:` receipts the display was last decided from, so
## the (snapshot-reading) full-refusal rule only runs when an answer lands.
var _herd_signature: String = "-"
## The land heals: the regreen overlay, the returning herd, the fallen pylons.
var _field: RefCounted = null
var _regreen: MeshInstance3D = null
var _regreen_material: StandardMaterial3D = null
var _regreen_quads: int = 0
var _herd_return: Node3D = null
var _toppled: Array[Node3D] = []
var _cables_hidden: int = 0


func build(world: Node3D) -> void:
	_world = world
	_config = _load_json(CONFIG_PATH)
	if _config.is_empty():
		push_warning("meadow_healing.json missing; the Meadows never answers")
		return
	var game := get_node_or_null(^"/root/Game")
	_progression = game.get("progression") as RefCounted if game != null else null
	if _progression == null:
		return
	var flag := str(_config.get("flag", "legendary_freed"))
	if bool(_progression.call("has", flag)):
		# A save loaded after the ending: no fade, no ceremony. The world has
		# been this way since before the player pressed Continue.
		apply(true)
		# F05: the herd display is not a one-shot, so it keeps watching.
		_flag = flag
		set_process(true)
		return
	# Otherwise: POLL. progression_state.gd has no signal, by design and by its
	# own header, and every other consumer of the flag store watches `revision`
	# instead (party.gd, inventory.gd, map_state.gd, village_npcs.gd). A world
	# change wired to a signal nobody emits is a world change that silently
	# never happens, which is exactly the §9 failure this node exists to
	# prevent.
	_flag = flag
	set_process(true)


func _process(_delta: float) -> void:
	if _progression == null:
		set_process(false)
		return
	var revision := int(_progression.get("revision"))
	if revision == _revision:
		# The Warden journal is not a flag, so a journal row landing alone does
		# not move the revision: re-check the display about once a second.
		_journal_check_in -= _delta
		if _journal_check_in <= 0.0 and _applied:
			_journal_check_in = 1.0
			sync_herd_display()
		return
	_revision = revision
	if not _applied and bool(_progression.call("has", _flag)):
		apply(false)
	# F05: re-read on every flag change rather than once. In co-op the answers
	# arrive one character at a time and in any order, so the display can only
	# be decided when the last eligible participant's receipt lands -- and a
	# later acceptance must take it down again.
	sync_herd_display()


## --- F05 / WORLD §3.2: the herd display ---------------------------------------
##
## "If every eligible participant refuses the Veridian offer, an unengageable
## Stag appears among the healed Highfield herd after the climax. If any
## participant accepts, that world display is absent." The rule itself is
## `stronghold_climax.gd::all_refused()`, read off the per-character WORLD
## receipts, so it is the same answer on every peer and after every reload.
##
## Unengageable by construction: a creature body with its physics and AI off,
## in no encounter group, with no interactable -- nothing here can reopen the
## offer, start a fight, be caught or pay anything. It exists in the world and
## nowhere else: no flag of its own, nothing saved; it is re-derived.
func sync_herd_display() -> bool:
	var spec: Dictionary = _config.get("herd_display", {})
	var signature := _resolution_signature()
	if signature == _herd_signature:
		return _herd_display != null
	_herd_signature = signature
	var want := bool(spec.get("enabled", true)) and _applied and _full_refusal()
	if want and _herd_display == null:
		_herd_display = _build_herd_display(spec)
	elif not want and _herd_display != null:
		_herd_display.queue_free()
		_herd_display = null
	return _herd_display != null


func _resolution_signature() -> String:
	if _progression == null or not _applied:
		return ""
	var receipts: Array = []
	for raw: Variant in (_progression.call("all_set") as Array):
		if str(raw).begins_with("legendary_resolution:"):
			receipts.append(str(raw))
	receipts.sort()
	# The Warden journal decides who is eligible, so a journal row arriving
	# (a late snapshot, a pending delivery acknowledged) re-decides the
	# display as surely as a new receipt does.
	var participants: Array = []
	var climax := _find(str((_config.get("herd_display", {}) as Dictionary).get("climax_node", "StrongholdClimax")))
	if climax != null and climax.has_method("warden_participants"):
		participants = (climax.call("warden_participants") as Array).duplicate()
	participants.sort()
	return ",".join(receipts) + "|" + ",".join(participants)


func herd_display() -> Node3D:
	return _herd_display


func _full_refusal() -> bool:
	var climax := _find(str((_config.get("herd_display", {}) as Dictionary).get("climax_node", "StrongholdClimax")))
	return climax != null and climax.has_method("full_refusal") and bool(climax.call("full_refusal"))


func _build_herd_display(spec: Dictionary) -> Node3D:
	var at_raw: Variant = spec.get("at", [])
	if not at_raw is Array or (at_raw as Array).size() < 2:
		return null
	var at := Vector3(float((at_raw as Array)[0]), 0.0, float((at_raw as Array)[1]))
	if _world != null and _world.has_method("ground_height_at"):
		at.y = float(_world.call("ground_height_at", at.x, at.z))
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "HighfieldHerdStag"
	body.set_script(CREATURE_BODY)
	add_child(body)
	body.global_position = at
	body.call("setup", str(spec.get("species", "veridian")), false)
	body.rotation.y = deg_to_rad(float(spec.get("facing_deg", 0.0)))
	# Stands, and is not simulated: no gravity walk, no AI, and on no
	# collision LAYER, so nothing can bump, target or engage it. Its MASK is
	# kept: `creature_body` turns physics back on whenever it becomes visible
	# again, and with a mask it then stands on the ground instead of falling
	# through it.
	body.set_physics_process(false)
	body.set_process(false)
	if body is CollisionObject3D:
		(body as CollisionObject3D).collision_layer = 0
	if body.has_method("place_on_ground"):
		body.call("place_on_ground", at)
	print("[meadow] every participant refused: the freed stag stands with the Highfield herd at %s" % str(body.global_position))
	return body


## Everything, in one call, so a test can drive it without a boss fight.
## `immediate` skips the fades — the loaded-save case.
func apply(immediate: bool = false) -> Dictionary:
	if _applied:
		return _report
	_applied = true
	_report = {
		"regrown": _heal_the_scatter(),
		"dead_ground_faded": _fade_the_drain_skins(immediate),
		"regreened": _regreen_the_scars(immediate),
		"lights_killed": _kill_the_tether_lights(),
		# After the lights: what falls is already dead.
		"pylons_toppled": _topple_the_pylons(immediate),
		"herd_returned": _return_the_herd(),
		"barriers_opened": _open_the_barriers(),
		"patrols_withdrawn": _withdraw_beaten_patrols(),
	}
	_report["cables_hidden"] = _cables_hidden
	print("[meadow] the tether let go: %d plants back, %d regreen quads, %d tether lights out, %d pylons down (%d cable pieces gone), %d of the herd back, %d barriers open, %d beaten patrols withdrawn"
		% [_report["regrown"], _report["regreened"], _report["lights_killed"],
			_report["pylons_toppled"], _report["cables_hidden"], _report["herd_returned"],
			_report["barriers_opened"], _report["patrols_withdrawn"]])
	return _report


func applied() -> bool:
	return _applied


## --- CL-E12 / contract V-5: healing ONE SITE, before the chapter's own ------
##
## D41 says drained ground "heals when the machinery fails". The chapter's
## machinery fails once, at the Warden, and `apply()` above is that moment.
## But the relay's OWN machinery fails the moment the player presses its
## console, hours earlier, and the owner answered V-5 with a plain **yes**
## (`docs/owner/OWNER_DIRECTIVES_2026-09-04.md`, question 1): heal the relay's
## own three drain stations then, and leave the rest of the map to the Warden.
##
## This is a FILTER ON THE EXISTING MECHANISM, not a second healing system.
## It calls the same `vegetation.restore_drained()` the chapter-wide sweep
## calls and the same `heal()` every drain skin already carries; the only new
## thing is a list of discs to restrict them to.
##
## `station_ids` names entries in `terrain_playground.json`'s `drains.stations`
## -- the SAME authored radii `playground_heightfield.drain_factor()` reads and
## `scatter_rules._thin_by_drain` filtered the scatter on, so what grows back
## is exactly what those three stations took and nothing a fourth station took.
## Reading the ids from the caller rather than from this file's own config is
## deliberate: the relay knows which stations are its, and a second list here
## would be a second place to keep that true.
##
## Idempotent and order-independent with `apply()`, both ways round. Run first,
## it hands `apply()` a smaller `_drained` and a skin already faded, and
## `apply()` heals the remainder normally. Run after — a save loaded past the
## ending, then a console pressed — every disc's placements are already gone
## from `_drained` and `restore_drained()` returns 0 rather than double-placing.
##
## It does not regreen: the relay's ground was never baked (its skin stands in
## for the bake), so fading that skin IS its repair. The chapter-wide regreen
## of the BAKED scars belongs to `apply()` alone, at the finale -- see
## `_regreen_the_scars()` and this file's header for the owner decision.
func heal_stations(station_ids: Array, immediate: bool = false) -> Dictionary:
	var discs := _station_discs(station_ids)
	if discs.is_empty():
		return {"regrown": 0, "dead_ground_faded": 0, "stations": 0}
	var report := {
		"stations": discs.size(),
		"regrown": _heal_the_scatter_within(discs),
		"dead_ground_faded": _fade_the_drain_skins_within(discs, immediate),
	}
	print("[meadow] local healing at %d station(s): %d plants back, %d drain skin(s) fading"
		% [report["stations"], report["regrown"], report["dead_ground_faded"]])
	return report


## The authored discs for the named stations, straight out of the terrain
## config. Unknown ids are warned about rather than skipped silently: a typo
## here is a site that quietly never heals, which is precisely the V-5 *fails
## if* ("a before/after frame shows no ground change inside the site radius").
func _station_discs(station_ids: Array) -> Array:
	var wanted: Dictionary = {}
	for raw: Variant in station_ids:
		var id := str(raw)
		if not id.is_empty():
			wanted[id] = true
	if wanted.is_empty():
		return []
	var terrain := _load_json(TERRAIN_PATH)
	var discs: Array = []
	for raw: Variant in ((terrain.get("drains", {}) as Dictionary).get("stations", []) as Array):
		var station: Dictionary = raw
		var id := str(station.get("id", ""))
		if not wanted.has(id):
			continue
		wanted.erase(id)
		var centre: Array = station.get("centre", [])
		if centre.size() < 2:
			continue
		discs.append({
			"id": id,
			"centre": Vector2(float(centre[0]), float(centre[1])),
			"radius": float(station.get("radius", 0.0)),
			"inner": float(station.get("inner", 0.0)),
			"strength": float(station.get("strength", 1.0)),
		})
	for missing: String in wanted.keys():
		push_warning("meadow_healing: no drain station '%s' in terrain_playground.json" % missing)
	return discs


## The scatter half, restricted to the discs, WITHOUT a filter argument on
## `vegetation.gd::restore_drained()`.
##
## READ THIS BEFORE CHANGING IT, because the shape is deliberate and it is not
## the shape anybody would choose freely.
##
## The clean version of this is one optional parameter on `restore_drained()`
## -- `restore_drained(within: Array = [])`, partitioning inside the function
## that owns the list. It was written that way first and it worked. It was
## backed out on a routing decision: `scripts/world/vegetation.gd` is outside
## this lane's ownership and the round's standing rule is to document a needed
## change in another lane's file rather than make it. The exact fix is written
## up as a routed finding in `ralph/reports/W20-SMALL-FIXES-0904/REPORT.md`.
##
## So the partition happens HERE instead, by lending `vegetation.gd` a smaller
## `_drained` for the length of one call and handing back the remainder:
##
##   1. read the held list, split it on the discs;
##   2. give the node only the entries inside them;
##   3. call the SAME `restore_drained()` the chapter-wide sweep calls, which
##      rebuilds those placements and clears the list;
##   4. give the node back everything that was outside.
##
## Step 4 is what keeps the rest of the map owed to the Warden. Every step
## uses the same `_build_batch` path any other heal uses; there is no second
## vegetation system and no "healed" variant asset, which is the property the
## contract actually asks for.
##
## THE TWO WARTS, named rather than discovered later:
##
##   * it touches `_drained`, an underscore-private of another node. That is
##     the whole reason the parameter belongs in `vegetation.gd` and it is the
##     substance of the routed finding.
##   * `restore_drained()` ASSIGNS `_regrown` rather than accumulating it, so
##     after a local heal and then the chapter-wide one, `regrown_count()` and
##     `vegetation.stats()`'s `regrown` field report the LAST call's share
##     rather than the running total. Nothing reads either for a decision --
##     they are diagnostics -- and this function's own return value is always
##     the number this call put back, which is what `heal_stations()` reports.
##     Fixing it is one character (`=` to `+=`) in the same file the routed
##     finding names.
func _heal_the_scatter_within(discs: Array) -> int:
	if not bool((_config.get("vegetation", {}) as Dictionary).get("enabled", true)):
		return 0
	var vegetation := _find("Vegetation")
	if vegetation == null or not vegetation.has_method("restore_drained"):
		return 0
	var held: Variant = vegetation.get("_drained")
	if not (held is Dictionary) or (held as Dictionary).is_empty():
		return 0
	var inside: Dictionary = {}
	var outside: Dictionary = {}
	for layer_name: String in (held as Dictionary).keys():
		for entry: Variant in ((held as Dictionary)[layer_name] as Array):
			var placement: Dictionary = entry
			var bucket := inside if _inside_any_disc(
				placement.get("position", Vector3.ZERO), discs) else outside
			if not bucket.has(layer_name):
				bucket[layer_name] = []
			(bucket[layer_name] as Array).append(placement)
	if inside.is_empty():
		return 0
	vegetation.set("_drained", inside)
	var regrown := int(vegetation.call("restore_drained"))
	# `restore_drained()` clears the list it was given. Everything the drain
	# still holds outside these stations goes back, and stays owed until
	# `legendary_freed`.
	vegetation.set("_drained", outside)
	return regrown


## The same sweep `_fade_the_drain_skins` makes, restricted to skins that
## actually STAND inside one of the discs. Found by geometry rather than by
## name for the same reason the chapter-wide pass is found by method: a drain
## skin belongs to whichever site built it, and this file must not learn the
## list of files that build them.
##
## WHERE a skin is has to be asked carefully, and the first cut of this got it
## wrong in the silent direction. `tether_relay.gd::_build_dead_ground()` writes
## its mesh vertices in WORLD coordinates and leaves the MeshInstance3D at the
## node origin, so `global_position` reads (0,0,0) for a skin painted 3.7 km
## down the corridor — a filter that trusted it matched nothing, reported
## "0 drain skins fading" and looked like it had simply found none to fade.
## `_skin_position()` below asks the rendered geometry instead.
func _fade_the_drain_skins_within(discs: Array, immediate: bool) -> int:
	var block: Dictionary = _config.get("dead_ground", {})
	if not bool(block.get("enabled", true)):
		return 0
	var seconds := 0.0 if immediate else float(block.get("fade_seconds", 12.0))
	var faded := 0
	for node: Node in _all_nodes(_world):
		if not node.has_method("heal") or not node.has_method("dead_ground_visible"):
			continue
		if not bool(node.call("dead_ground_visible")):
			continue
		# Already fading, because the site that fired this sweep started its own
		# skin first. `heal()` no-ops on it anyway; skipping keeps the count a
		# statement about what THIS pass did.
		if node.has_method("healing") and bool(node.call("healing")):
			continue
		var at := _skin_position(node)
		if is_inf(at.x) or not _inside_any_disc(at, discs):
			continue
		node.call("heal", seconds)
		faded += 1
	return faded


## Where a healable node's drained ground actually is, in world metres.
##
## The centre of the first visual instance's global AABB at or under the node,
## because that is the paint; the node's own origin only as a last resort, for
## a healable that carries no geometry of its own. `Vector3.INF` when neither
## can be had, which the caller reads as "cannot place this one" rather than as
## "it is at the origin".
func _skin_position(node: Node) -> Vector3:
	for child: Node in _all_nodes(node):
		var visual := child as VisualInstance3D
		if visual == null or not visual.is_inside_tree():
			continue
		var box := visual.get_aabb()
		if box.size == Vector3.ZERO:
			continue
		return visual.global_transform * box.get_center()
	var spatial := node as Node3D
	return spatial.global_position if spatial != null else Vector3.INF


func _inside_any_disc(position: Vector3, discs: Array) -> bool:
	var spot := Vector2(position.x, position.z)
	for raw: Variant in discs:
		var disc: Dictionary = raw
		if spot.distance_to(disc["centre"] as Vector2) <= float(disc["radius"]):
			return true
	return false


func report() -> Dictionary:
	return _report.duplicate()


## --- the land ---------------------------------------------------------------

func _heal_the_scatter() -> int:
	if not bool((_config.get("vegetation", {}) as Dictionary).get("enabled", true)):
		return 0
	var vegetation := _find("Vegetation")
	if vegetation == null or not vegetation.has_method("restore_drained"):
		return 0
	return int(vegetation.call("restore_drained"))


func _fade_the_drain_skins(immediate: bool) -> int:
	var block: Dictionary = _config.get("dead_ground", {})
	if not bool(block.get("enabled", true)):
		return 0
	var seconds := 0.0 if immediate else float(block.get("fade_seconds", 12.0))
	var faded := 0
	for node: Node in _all_nodes(_world):
		if node.has_method("heal") and node.has_method("dead_ground_visible"):
			if bool(node.call("dead_ground_visible")):
				node.call("heal", seconds)
				faded += 1
	return faded


## --- the network -------------------------------------------------------------

## Every lit Team Tether fitting standing in the world, swapped to its own dead
## material state. Found by what the material IS rather than by node name: the
## pylons are built by three different files (`severed_spokes.gd` for the
## spokes, `old_quarry.gd` and `tether_relay.gd` through the same builder) and
## each holds its own cached material instance, so a name walk would have to
## know all three and the next one nobody has written yet.
##
## Two signatures, matching the two things `severed_spokes.gd` lights:
## a pylon albedo (texture swap, live sheet -> the graded dead sheet) and an
## emissive teal conduit or fitting (emission off, albedo dulled). Warm
## emission is deliberately untouched — the freed legendary's own light is
## #e8d79a and this pass must not take it out on the way past.
func _kill_the_tether_lights() -> int:
	var block: Dictionary = _config.get("tether_lights", {})
	if not bool(block.get("enabled", true)):
		return 0
	var lit_path := str(block.get("lit_albedo", ""))
	var dead_path := str(block.get("dead_albedo", ""))
	var dead_texture: Texture2D = null
	if ResourceLoader.exists(dead_path):
		dead_texture = load(dead_path)
	var killed := 0
	var seen: Array[Material] = []
	for node: Node in _all_nodes(_world):
		if not node is GeometryInstance3D:
			continue
		var geometry := node as GeometryInstance3D
		for material: Material in _materials_of(geometry):
			var standard := material as StandardMaterial3D
			if standard == null or seen.has(standard):
				continue
			seen.append(standard)
			if _kill_one(standard, lit_path, dead_texture):
				killed += 1
	return killed


func _kill_one(material: StandardMaterial3D, lit_path: String, dead: Texture2D) -> bool:
	var changed := false
	if material.albedo_texture != null and dead != null \
			and material.albedo_texture.resource_path == lit_path:
		material.albedo_texture = dead
		changed = true
	if material.emission_enabled and _is_tether_teal(material.emission):
		material.emission_enabled = false
		material.albedo_color = material.albedo_color.darkened(0.25)
		material.roughness = 0.92
		changed = true
	return changed


## The reserved faction teal, tested by hue rather than by exact equality: the
## same colour is read from palette.json by several files and each darkens or
## brightens its own copy. Cold, saturated, green-blue — a warm light cannot
## satisfy this and that is the point.
func _is_tether_teal(colour: Color) -> bool:
	if colour.s < 0.25:
		return false
	var hue := colour.h * 360.0
	return hue > 140.0 and hue < 210.0


## --- barriers and patrols -----------------------------------------------------

func _open_the_barriers() -> int:
	var block: Dictionary = _config.get("barriers", {})
	if not bool(block.get("enabled", true)) or _progression == null:
		return 0
	var opened := 0
	for raw: Variant in (block.get("flags", []) as Array):
		var flag := str(raw)
		if flag == "":
			continue
		if not bool(_progression.call("has", flag)):
			_progression.call("set_flag", flag)
			opened += 1
	# The bodies already standing take their open pose now rather than on the
	# next load. `open_permanently()` is road_gate.gd's own, and both gates in
	# the region are that script.
	for node: Node in _all_nodes(_world):
		if node.has_method("open_permanently"):
			node.call("open_permanently")
	return opened


## §9's patrol thinning, and the narrow version of it on purpose: a Team Tether
## trainer whose defeat flag is set is withdrawn, and one who is still standing
## unbeaten is left alone. No defeat flag is ever cleared here — "already
## beaten stay beaten" is a rule about the flags, and this pass only reads them.
func _withdraw_beaten_patrols() -> int:
	var block: Dictionary = _config.get("patrols", {})
	if not bool(block.get("enabled", true)) or _progression == null:
		return 0
	var withdrawn := 0
	for raw: Variant in (block.get("withdraw", []) as Array):
		var spec := TRAINERS.trainer(str(raw))
		if spec.is_empty():
			continue
		var flag := str(spec.get("defeat_flag", ""))
		if flag == "" or not bool(_progression.call("has", flag)):
			continue
		var body := _world.find_child(str(spec.get("name", "")), true, false)
		if body == null or not is_instance_valid(body):
			continue
		body.queue_free()
		withdrawn += 1
	return withdrawn


## --- the land heals: regreen, fallen pylons, the herd back -------------------
##
## Owner decision (F05, "the land heals"): at the Meadows finale the baked scar
## stations regreen over the finale beat and stay green, the Highfield herd is
## back around the freed Veridian's site, and the dark tether pylons are down.
## Installed assets only; NO terrain re-bake -- D45's baked discolouration is
## the BEFORE state and stays in the texture. Every part is re-derived from
## `legendary_freed` (world scope), deterministically, so every peer and every
## load builds the same world; nothing below writes a flag or a save field.


## (A) THE REGREEN. One runtime overlay mesh over the configured baked
## stations, in WORLD coordinates (top_level, the same convention the drain
## skins use). A global grid aligned to world multiples of `cell`, so where two
## station discs overlap their cells coincide and each cell is drawn ONCE --
## overlapping per-disc grids would stack two alpha layers into a darker seam.
## Each corner's alpha is the listed stations' own authored falloff (the same
## `strength * (1 - smoothstep(inner, radius, d))` `drain_factor()` uses, so it
## greens exactly the contour the bake browned) times `max_alpha`, times
## `1 - path_factor` so a road through a station stays a road. The material is
## the installed meadow grass texture, world-triplanar at the terrain's own UV
## scale and tint; its `albedo_color.a` fades 0 -> 1 over `fade_seconds`, the
## same seconds the dark skins fade out over, so the two crossfade.
func _regreen_the_scars(immediate: bool) -> int:
	var block: Dictionary = _config.get("regreen", {})
	if not bool(block.get("enabled", true)):
		return 0
	if _regreen != null:
		return _regreen_quads
	if _world == null or not _world.has_method("ground_height_at"):
		return 0
	var discs := _station_discs(block.get("stations", []) as Array)
	if discs.is_empty():
		return 0
	var drains: Dictionary = _load_json(TERRAIN_PATH).get("drains", {})
	var global_strength := clampf(float(drains.get("strength", 1.0)), 0.0, 1.0)
	var cell := maxf(float(block.get("cell", 3.0)), 1.0)
	var lift := float(block.get("lift", 0.11))
	var max_alpha := clampf(float(block.get("max_alpha", 0.7)), 0.0, 1.0)
	var keep_roads := bool(block.get("spare_roads", true))
	var field := _heightfield()

	var cells := regreen_cells(discs, cell)
	var corners: Dictionary = {}  # Vector2i -> [Vector3 point, alpha] or null
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads := 0
	for key: Vector2i in cells:
		var quad: Array = []
		var peak := 0.0
		for offset: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var at := key + offset
			if not corners.has(at):
				var x := float(at.x) * cell
				var z := float(at.y) * cell
				var ground := float(_world.call("ground_height_at", x, z))
				if is_nan(ground):
					corners[at] = null
				else:
					var path := 0.0
					if keep_roads and field != null:
						path = float(field.call("path_factor", x, z))
					corners[at] = [Vector3(x, ground + lift, z),
						regreen_alpha(Vector2(x, z), discs, global_strength, max_alpha, path)]
			if corners[at] == null:
				quad.clear()
				break
			quad.append(corners[at])
			peak = maxf(peak, float((corners[at] as Array)[1]))
		if quad.size() < 4 or peak <= 0.01:
			continue
		for triangle: Array in [[0, 1, 2], [0, 2, 3]]:
			for index: int in triangle:
				var point: Array = quad[index]
				surface.set_color(Color(1.0, 1.0, 1.0, float(point[1])))
				surface.add_vertex(point[0] as Vector3)
		quads += 1
	if quads == 0:
		return 0
	surface.generate_normals()
	var material := _regreen_material_for(block)
	surface.set_material(material)
	var skin := MeshInstance3D.new()
	skin.name = "Regreen"
	skin.top_level = true
	skin.mesh = surface.commit()
	skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skin)
	skin.global_transform = Transform3D.IDENTITY
	_regreen = skin
	_regreen_material = material
	_regreen_quads = quads
	var seconds := 0.0 if immediate else float(block.get("fade_seconds", 12.0))
	if seconds <= 0.0:
		material.albedo_color.a = 1.0
	else:
		material.albedo_color.a = 0.0
		create_tween().tween_property(material, "albedo_color:a", 1.0, seconds)
	return quads


func _regreen_material_for(block: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tint := Color(str(block.get("tint", "#e9dfc0")))
	material.albedo_color = Color(tint.r, tint.g, tint.b, 0.0)
	var albedo_path := str(block.get("albedo", ""))
	if albedo_path != "" and ResourceLoader.exists(albedo_path):
		material.albedo_texture = load(albedo_path)
	var normal_path := str(block.get("normal", ""))
	if normal_path != "" and ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path)
		material.normal_scale = float(block.get("normal_depth", 0.34))
	var uv := float(block.get("uv_scale", 0.27))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(uv, uv, uv)
	return material


## One station's authored falloff at `distance` -- the per-station term of
## `playground_heightfield.drain_factor()`, restated so a disc list can be
## evaluated without the rest of the network.
static func station_falloff(distance: float, inner: float, radius: float, strength: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	var core := clampf(inner, 0.0, radius - 0.001)
	return clampf(strength, 0.0, 1.0) * (1.0 - smoothstep(core, radius, distance))


## The regreen alpha at a world XZ: the worst listed station there, scaled by
## the global drain strength and `max_alpha`, and spared on roads.
static func regreen_alpha(spot: Vector2, discs: Array, global_strength: float,
		max_alpha: float, path: float) -> float:
	var worst := 0.0
	for raw: Variant in discs:
		var disc: Dictionary = raw
		worst = maxf(worst, station_falloff(spot.distance_to(disc["centre"] as Vector2),
			float(disc.get("inner", 0.0)), float(disc["radius"]), float(disc.get("strength", 1.0))))
	return clampf(worst * global_strength * max_alpha * (1.0 - clampf(path, 0.0, 1.0)), 0.0, 1.0)


## Every world-aligned grid cell (index = floor(world / cell)) any disc
## touches, each once, in a stable order.
static func regreen_cells(discs: Array, cell: float) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var out: Array[Vector2i] = []
	for raw: Variant in discs:
		var disc: Dictionary = raw
		var centre: Vector2 = disc["centre"]
		var radius := float(disc["radius"])
		for i in range(int(floor((centre.x - radius) / cell)), int(ceil((centre.x + radius) / cell))):
			for j in range(int(floor((centre.y - radius) / cell)), int(ceil((centre.y + radius) / cell))):
				var key := Vector2i(i, j)
				if not seen.has(key):
					seen[key] = true
					out.append(key)
	return out


func regreen_node() -> MeshInstance3D:
	return _regreen


func regreen_alpha_now() -> float:
	return _regreen_material.albedo_color.a if _regreen_material != null else 0.0


func _heightfield() -> RefCounted:
	if _field == null:
		_field = HEIGHTFIELD.new()
	return _field


## (C) THE PYLONS FALL. Every `Pylon_<i>` under a holder whose name matches
## `pylons.holders` tips over about its own base edge, in a deterministic
## direction, until its tip rests on the terrain. Which holders is a config
## decision: the quarry spur, the relay's runs and the stronghold approach
## trunk were the LIVE network the finale kills; the severed spokes at the map
## edges were dead before the game began and their standing, leaning pylons
## are the severance story, so they stay up.
##
## Each pylon's box collider (a SIBLING `StaticBody3D` at the pylon's XZ, see
## `severed_spokes.gd::_add_box_collider`) is disabled for the fall and then
## laid down with the same pivot transform (or removed, per config) -- never
## left standing as an invisible wall. The cables strung between pylons would
## float once they fall, so the holder's `Conduit_*`/`DangleStub_*` pieces are
## hidden, as are the spans in `pylons.cable_holders` that end on one.
func _topple_the_pylons(immediate: bool) -> int:
	var block: Dictionary = _config.get("pylons", {})
	if not bool(block.get("enabled", true)) or _world == null:
		return 0
	var patterns: Array = block.get("holders", [])
	var prefixes: Array = block.get("hide_prefixes", ["Conduit_", "DangleStub_"])
	var fall := maxf(float(block.get("fall_seconds", 2.0)), 0.1)
	var stagger := float(block.get("stagger_seconds", 0.35))
	var toppled := 0
	for node: Node in _all_nodes(_world):
		var holder := node as Node3D
		if holder == null or not _name_matches(str(holder.name), patterns):
			continue
		var pylons: Array[Node3D] = []
		for child: Node in holder.get_children():
			if child is MeshInstance3D and str(child.name).begins_with("Pylon_"):
				pylons.append(child as Node3D)
		if pylons.is_empty():
			continue
		_cables_hidden += _hide_named(holder, prefixes)
		for i in pylons.size():
			var delay := float(i) * stagger
			if _topple_one(pylons[i], holder, block, 0.0 if immediate else fall, delay):
				toppled += 1
	for raw: Variant in (block.get("cable_holders", []) as Array):
		for node: Node in _all_nodes(_world):
			if str(node.name) == str(raw):
				_cables_hidden += _hide_named(node, prefixes)
	return toppled


func _name_matches(node_name: String, patterns: Array) -> bool:
	for raw: Variant in patterns:
		if node_name.match(str(raw)):
			return true
	return false


func _hide_named(root: Node, prefixes: Array) -> int:
	var hidden := 0
	for node: Node in _all_nodes(root):
		var visual := node as Node3D
		if visual == null or not visual.visible:
			continue
		for raw: Variant in prefixes:
			if str(node.name).begins_with(str(raw)):
				visual.visible = false
				hidden += 1
				break
	return hidden


## One pylon. False (and nothing moved) when it has already fallen.
func _topple_one(pylon: Node3D, holder: Node3D, block: Dictionary, seconds: float,
		delay: float) -> bool:
	if pylon == null or pylon.has_meta(TOPPLED_META):
		return false
	pylon.set_meta(TOPPLED_META, true)
	var start := _global_of(pylon)
	var box := AABB(start.origin, Vector3.ZERO)
	var mesh_instance := pylon as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		box = start * mesh_instance.mesh.get_aabb()
	var height := maxf(box.size.y, 0.5)
	var base := Vector3(start.origin.x, box.position.y, start.origin.z)
	var key := "%s/%s" % [str(holder.name), str(pylon.name)]
	var dir := _fall_direction(key, base, height, block)
	var pivot := base + Vector3(dir.x, 0.0, dir.y) * float(block.get("pivot_offset", 0.85))
	var ground_pivot := _ground(pivot.x, pivot.z)
	var tip := Vector2(pivot.x, pivot.z) + dir * height
	var angle := deg_to_rad(fall_angle_deg(height, ground_pivot, _ground(tip.x, tip.y),
		float(block.get("sink_deg", 3.0)), float(block.get("min_angle_deg", 70.0)),
		float(block.get("max_angle_deg", 108.0))))
	var final := topple_transform(start, pivot, dir, angle)

	var colliders: Array[Node3D] = []
	var reach := float(block.get("collider_match_radius", 0.35))
	for sibling: Node in holder.get_children():
		var body := sibling as StaticBody3D
		if body == null:
			continue
		var at := _global_of(body).origin
		if Vector2(at.x, at.z).distance_to(Vector2(start.origin.x, start.origin.z)) <= reach:
			colliders.append(body)
	var remove := str(block.get("collider", "lay_down")) == "remove"
	for body: Node3D in colliders:
		_set_shapes_disabled(body, true)

	_toppled.append(pylon)
	if seconds <= 0.0 or not is_inside_tree():
		_set_global(pylon, final)
		_settle_colliders(colliders, pivot, dir, angle, remove)
		return true
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(_pose_pylon.bind(pylon, start, pivot, dir, angle), 0.0, 1.0, seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_fall.bind(pylon, final, colliders, pivot, dir, angle, remove))
	return true


func _pose_pylon(t: float, pylon: Node3D, start: Transform3D, pivot: Vector3, dir: Vector2,
		angle: float) -> void:
	if is_instance_valid(pylon):
		_set_global(pylon, topple_transform(start, pivot, dir, angle * t))


func _finish_fall(pylon: Node3D, final: Transform3D, colliders: Array[Node3D], pivot: Vector3,
		dir: Vector2, angle: float, remove: bool) -> void:
	if is_instance_valid(pylon):
		_set_global(pylon, final)
	_settle_colliders(colliders, pivot, dir, angle, remove)


func _settle_colliders(colliders: Array[Node3D], pivot: Vector3, dir: Vector2,
		angle: float, remove: bool) -> void:
	for body: Node3D in colliders:
		if not is_instance_valid(body):
			continue
		if remove:
			body.queue_free()
			continue
		_set_global(body, topple_transform(_global_of(body), pivot, dir, angle))
		_set_shapes_disabled(body, false)


func _set_shapes_disabled(body: Node, disabled: bool) -> void:
	for child: Node in body.get_children():
		if not child is CollisionShape3D:
			continue
		if child.is_inside_tree():
			(child as CollisionShape3D).set_deferred("disabled", disabled)
		else:
			(child as CollisionShape3D).disabled = disabled


## World transform of a node, or its local one outside the tree (the unit
## tests drive the topple on bare nodes, where local IS world).
func _global_of(node: Node3D) -> Transform3D:
	return node.global_transform if node.is_inside_tree() else node.transform


func _set_global(node: Node3D, value: Transform3D) -> void:
	if node.is_inside_tree():
		node.global_transform = value
	else:
		node.transform = value


## The fall direction: an azimuth hashed from the pylon's holder and name, so
## every peer and every load picks the same one; then stepped round by
## `TAU / candidates` until the fallen body would not lie across a road or a
## building apron (sampled along its length) and its tip can meet the ground
## within the allowed angles. Falls back to the hashed azimuth if every
## candidate is blocked.
func _fall_direction(key: String, base: Vector3, height: float, block: Dictionary) -> Vector2:
	var candidates := maxi(int(block.get("direction_candidates", 8)), 1)
	var limit := float(block.get("avoid_road_above", 0.05))
	var field := _heightfield()
	for attempt in candidates:
		var dir := fall_direction(key, attempt, candidates)
		if field == null:
			return dir
		var clear := true
		for s in range(1, 6):
			var spot := Vector2(base.x, base.z) + dir * (height * float(s) / 5.0)
			var road := float(field.call("path_factor", spot.x, spot.y))
			var apron := float(field.call("building_apron_factor", spot.x, spot.y)) \
				if field.has_method("building_apron_factor") else 0.0
			if maxf(road, apron) > limit:
				clear = false
				break
		if clear and not _lands_flat(base, dir, height, block):
			clear = false
		if clear:
			return dir
	return fall_direction(key, 0, candidates)


## Whether falling toward `dir` lets the tip meet the ground within the
## allowed angles. A pylon falling across a gully or off a bank would need more
## than `max_angle_deg` and end with its tip in the air; another direction is
## tried instead.
func _lands_flat(base: Vector3, dir: Vector2, height: float, block: Dictionary) -> bool:
	var tip := Vector2(base.x, base.z) + dir * height
	var from := _ground(base.x, base.z)
	var to := _ground(tip.x, tip.y)
	if is_nan(from) or is_nan(to):
		return true
	var raw := 90.0 - rad_to_deg(atan2(to - from, maxf(height, 0.01))) + float(block.get("sink_deg", 3.0))
	return raw >= float(block.get("min_angle_deg", 70.0)) and raw <= float(block.get("max_angle_deg", 108.0))


## Deterministic unit XZ direction for `key`, candidate `attempt` of `count`.
static func fall_direction(key: String, attempt: int = 0, count: int = 8) -> Vector2:
	var turn := float(key.hash() & 0xffff) / 65536.0 * TAU
	turn += float(attempt) * TAU / float(maxi(count, 1))
	return Vector2(sin(turn), cos(turn))


## How far (degrees from upright) a pylon of `height` falls before its tip
## meets the ground: 90 on the level, less when the ground rises ahead of it,
## more when it falls away; plus a few degrees of sink so the tip rests IN the
## grass rather than hovering. NaN ground reads as level.
static func fall_angle_deg(height: float, ground_pivot: float, ground_tip: float,
		sink_deg: float, min_deg: float, max_deg: float) -> float:
	var rise := 0.0
	if not is_nan(ground_pivot) and not is_nan(ground_tip):
		rise = ground_tip - ground_pivot
	var slope := rad_to_deg(atan2(rise, maxf(height, 0.01)))
	return clampf(90.0 - slope + sink_deg, min_deg, max_deg)


## `transform` rotated by `angle` about the horizontal axis through `pivot`
## perpendicular to `dir`, tipping its up axis toward `dir`. The same axis
## convention `severed_spokes.gd` leans its pylons with.
static func topple_transform(transform: Transform3D, pivot: Vector3, dir: Vector2,
		angle: float) -> Transform3D:
	var along := Vector3(dir.x, 0.0, dir.y)
	if along.length() < 0.0001:
		return transform
	var axis := along.normalized().cross(Vector3.UP).normalized()
	var turn := Basis(axis, -angle)
	return Transform3D(turn * transform.basis, pivot + turn * (transform.origin - pivot))


func toppled_pylons() -> Array[Node3D]:
	return _toppled.duplicate()


func _ground(x: float, z: float) -> float:
	if _world == null or not _world.has_method("ground_height_at"):
		return NAN
	return float(_world.call("ground_height_at", x, z))


## (B) THE HERD COMES BACK. Inert Meadowharts -- built exactly the way the
## Veridian herd display is (no AI, no physics, on no collision layer, so
## nothing can engage, catch or bump them) -- at authored spots around the
## Highfield herd point, in their own holder. Built whenever the healing is
## applied, whatever the Veridian answer; `herd_display()` still returns only
## the Veridian. Idle clip started once and phase-shifted per index so they do
## not breathe in unison.
func _return_the_herd() -> int:
	var block: Dictionary = _config.get("herd_return", {})
	if not bool(block.get("enabled", true)) or _world == null:
		return 0
	if _herd_return != null:
		return _herd_return.get_child_count()
	var holder := Node3D.new()
	holder.name = "HighfieldHerdReturn"
	add_child(holder)
	_herd_return = holder
	var species := str(block.get("species", "meadowhart"))
	var phase := float(block.get("idle_phase_step", 0.37))
	var places := herd_placements(block)
	for i in places.size():
		var place: Dictionary = places[i]
		var spot: Vector2 = place["at"]
		var at := Vector3(spot.x, 0.0, spot.y)
		var ground := _ground(at.x, at.z)
		if not is_nan(ground):
			at.y = ground
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.name = "HerdReturn_%d" % i
		body.set_script(CREATURE_BODY)
		holder.add_child(body)
		body.global_position = at
		body.call("setup", species, false)
		body.rotation.y = deg_to_rad(float(place["facing_deg"]))
		body.set_physics_process(false)
		body.set_process(false)
		if body is CollisionObject3D:
			(body as CollisionObject3D).collision_layer = 0
		# creature_body turns physics back on whenever it becomes visible; this
		# runs after its own handler and keeps a display body standing.
		body.visibility_changed.connect(_hold_still.bind(body))
		if body.has_method("place_on_ground"):
			body.call("place_on_ground", at)
		_start_idle(body, fposmod(float(i) * phase, 1.0))
	return holder.get_child_count()


func _hold_still(body: Node) -> void:
	if is_instance_valid(body):
		body.set_physics_process(false)


func _start_idle(body: Node, phase: float) -> void:
	var animator: Variant = body.get("_animator")
	if not animator is Object or animator == null:
		return
	(animator as Object).call("tick", 0.0, 0.0, 1.0)
	var player := (animator as Object).get("_player") as AnimationPlayer
	if player == null or player.current_animation == "":
		return
	player.seek(player.current_animation_length * phase, true)


## The authored herd spots, `[x, z, facing_deg]` each, as
## `{"at": Vector2, "facing_deg": float}`. Pure, for tests.
static func herd_placements(block: Dictionary) -> Array:
	var out: Array = []
	for raw: Variant in (block.get("members", []) as Array):
		if not raw is Array or (raw as Array).size() < 2:
			continue
		var entry: Array = raw
		out.append({
			"at": Vector2(float(entry[0]), float(entry[1])),
			"facing_deg": float(entry[2]) if entry.size() > 2 else 0.0,
		})
	return out


func herd_return() -> Node3D:
	return _herd_return


## --- plumbing ----------------------------------------------------------------

func _find(node_name: String) -> Node:
	if _world == null:
		return null
	var direct := _world.get_node_or_null(NodePath(node_name))
	return direct if direct != null else _world.find_child(node_name, true, false)


func _all_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root == null:
		return out
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		for child in node.get_children():
			stack.append(child)
	return out


func _materials_of(geometry: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if geometry.material_override != null:
		out.append(geometry.material_override)
	var mesh_instance := geometry as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for i in mesh_instance.mesh.get_surface_count():
			var override := mesh_instance.get_surface_override_material(i)
			if override != null:
				out.append(override)
			var surface := mesh_instance.mesh.surface_get_material(i)
			if surface != null:
				out.append(surface)
	return out


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
