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
##     instances the drain took out of the scatter, and the relay's runtime
##     drain skin fades. What CANNOT heal is the baked half — see below.
##   * THE NETWORK DIES. Every lit pylon, glowing conduit and Team Tether
##     fitting in the region and inside the stronghold goes to its own dead
##     material. §9's "stronghold effects change", D41's "the drain network
##     dies with the stronghold machinery", one pass.
##   * BARRIERS DEACTIVATE. The keyed gates stand open, through their own
##     flags, so a reload opens them for the ordinary reason.
##   * PATROLS THIN. Team Tether trainers the player has ALREADY BEATEN are
##     withdrawn. Nobody unbeaten is removed and no defeat flag is cleared:
##     beaten trainers stay beaten, which is the half of "density drops" that
##     is easy to break by being clever.
##
## WHAT DOES NOT HEAL, STATED OUT LOUD. `D45` decided the drained-ground
## grammar as one authored radius with three consumers, and priced this exact
## moment while doing it: two of those consumers are live scene state and the
## third is the terrain BAKE. The quarry's stations are painted into the baked
## colour and control maps; nothing at run time can repaint a texel, SG46 is
## explicitly not allowed to re-run a ~15-minute bake, and inventing a green
## overlay to cancel a baked tint would be a second, undecided vocabulary for
## the repair. So the quarry floor keeps its sun-killed cast, its vegetation
## comes back over it, and `docs/decisions/D45-the-drained-ground-grammar.md`
## carries the note. That is the honest state, not an oversight.
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

var _config: Dictionary = {}
var _world: Node3D = null
var _progression: RefCounted = null
var _applied: bool = false
var _flag := "legendary_freed"
## Last `progression.revision` this node compared the flag against.
var _revision: int = -1
var _report: Dictionary = {}


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
	if _applied or _progression == null:
		set_process(false)
		return
	var revision := int(_progression.get("revision"))
	if revision == _revision:
		return
	_revision = revision
	if bool(_progression.call("has", _flag)):
		apply(false)
		set_process(false)


## Everything, in one call, so a test can drive it without a boss fight.
## `immediate` skips the fades — the loaded-save case.
func apply(immediate: bool = false) -> Dictionary:
	if _applied:
		return _report
	_applied = true
	_report = {
		"regrown": _heal_the_scatter(),
		"dead_ground_faded": _fade_the_drain_skins(immediate),
		"lights_killed": _kill_the_tether_lights(),
		"barriers_opened": _open_the_barriers(),
		"patrols_withdrawn": _withdraw_beaten_patrols(),
	}
	print("[meadow] the tether let go: %d plants back, %d tether lights out, %d barriers open, %d beaten patrols withdrawn"
		% [_report["regrown"], _report["lights_killed"], _report["barriers_opened"],
			_report["patrols_withdrawn"]])
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
## What it CANNOT do is repaint the ground: the baked colour and control maps
## are D45's stated remainder and no run-time pass can touch a texel. The
## relay's own skin is a runtime overlay and does fade; the terrain under it
## keeps its cast. See D45 and this file's header.
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
		})
	for missing: String in wanted.keys():
		push_warning("meadow_healing: no drain station '%s' in terrain_playground.json" % missing)
	return discs


func _heal_the_scatter_within(discs: Array) -> int:
	if not bool((_config.get("vegetation", {}) as Dictionary).get("enabled", true)):
		return 0
	var vegetation := _find("Vegetation")
	if vegetation == null or not vegetation.has_method("restore_drained"):
		return 0
	return int(vegetation.call("restore_drained", discs))


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
