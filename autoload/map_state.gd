extends RefCounted

## D33's one map database: fog-of-war discovery, landmark discovery and
## dynamic markers. The minimap and the full map both read THIS and nothing
## else — spec §6A.12 forbids two map databases, and this is the one.
##
## Deliberately not a radar. Spec §6A.6: wild creatures never get a marker here,
## and there is no method on this class that could produce one — the only
## positions this file ever stores are the player's own fog trail, the
## data-driven landmarks and whatever calls `add_dynamic_marker()` (camps,
## the tracked objective). If a future change wants wild-creature blips, that is a
## design decision for someone to flag, not a natural extension of this file.
##
## Discovery is permanent: fog cells and landmarks only ever move from
## hidden to revealed, never back. A `PackedByteArray` rather than a
## `Dictionary` of cells because the grid is fixed-size and dense enough
## (128x128 = 16384 cells) that a byte array is both the cheaper storage and
## the format the eventual fog texture wants anyway.
##
## `revision` is the same polling idiom as autoload/party.gd and
## autoload/inventory.gd: the minimap and full map UI read this once a
## frame and rebuild only when it moves, instead of listening to a signal
## for every single cell reveal.
##
## Pure logic, no `Node`, no transform — testable headlessly the same way
## party.gd and inventory.gd are (tests/test_map_state.gd).

const GRID := 128
const CELL := 4.0
const ORIGIN := Vector2(-256.0, -256.0)

## Polled by the minimap and full map. Bumped on any visible change: a newly
## revealed cell, a landmark discovery, or a dynamic marker add/remove.
var revision: int = 0

## Tunable, from map_landmarks.json.
var reveal_radius: float = 45.0
var minimap_span_m: float = 90.0

var _visited: PackedByteArray = PackedByteArray()
var _visited_count: int = 0

## id -> {display_name, icon, position: Vector2, discover_radius, category, silhouette}
var _landmark_defs: Dictionary = {}
## id -> true, for every discovered landmark id.
var _discovered: Dictionary = {}
## id -> {icon, position: Vector2}
var _dynamic: Dictionary = {}

## Owner directive: "name some of the areas and uncover them like fortnite
## maps do." A named region is broader than a landmark (spec's landmarks are
## single points of interest -- the house, the well; a region is the AREA
## around one, "Grandpa's Village" rather than just "Grandpa's House"), and
## unlike a landmark it is discovered by ENTERING it, not by a proximity
## check the player may never trigger by walking a road that skirts past.
##
## FORTNITE-SIZED, NOT ONE-PER-BUILDING. A first cut named the village
## square, Grandpa's house and the practice meadow as three separate
## regions -- all real destinations, but only 15-35m apart, so all three
## names landed on the full map within a few pixels of each other and read
## as clutter rather than geography (owner: "we shouldn't have region
## labels that close together... look at a fortnite map. the regions are
## much larger and the names aren't close"). data/config/map_landmarks.json
## now authors a handful of large zones instead — see that file's own
## `_comment_regions`.
## id -> {display_name, centre: Vector2, radius}
var _region_defs: Dictionary = {}
## id -> true, for every region the player has ever entered.
var _discovered_regions: Dictionary = {}
## The region id the player is standing in right now, "" for open pasture
## outside every authored region. Tracked so a region only announces itself
## on the frame it is ENTERED, not on every poll while standing inside it.
var _current_region_id: String = ""
## Set by `update_region()` on the exact frame a NEW region is entered for
## the first time; read-and-cleared by `take_pending_region_announcement()`
## so the HUD shows the toast exactly once, the same one-shot contract
## `playground_hud.gd`'s own `_hotbar_message` uses for its timed banners.
var _pending_region_announcement: String = ""


## Takes the parsed contents of data/config/map_landmarks.json. Resets
## discovery to fresh (nothing visited, nothing discovered, no dynamic
## markers) — this is setup, not a merge.
func configure(config: Dictionary) -> void:
	reveal_radius = float(config.get("reveal_radius", 45.0))
	minimap_span_m = float(config.get("minimap_span_m", 90.0))

	_visited = PackedByteArray()
	_visited.resize(GRID * GRID)
	_visited.fill(0)
	_visited_count = 0

	_landmark_defs.clear()
	_discovered.clear()
	_dynamic.clear()

	var raw_landmarks: Array = config.get("landmarks", [])
	for entry: Variant in raw_landmarks:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d := entry as Dictionary
		var id := str(d.get("id", ""))
		if id.is_empty():
			continue
		var pos: Array = d.get("position", [0.0, 0.0])
		var position := Vector2.ZERO
		if pos.size() >= 2:
			position = Vector2(float(pos[0]), float(pos[1]))
		_landmark_defs[id] = {
			"display_name": str(d.get("display_name", id)),
			"icon": str(d.get("icon", "")),
			"position": position,
			"discover_radius": float(d.get("discover_radius", 0.0)),
			"category": str(d.get("category", "minor")),
			"silhouette": bool(d.get("silhouette", false)),
		}

	_region_defs.clear()
	_discovered_regions.clear()
	_current_region_id = ""
	_pending_region_announcement = ""
	var raw_regions: Array = config.get("regions", [])
	for entry: Variant in raw_regions:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d := entry as Dictionary
		var id := str(d.get("id", ""))
		if id.is_empty():
			continue
		var pos: Array = d.get("centre", d.get("center", [0.0, 0.0]))
		var centre := Vector2.ZERO
		if pos.size() >= 2:
			centre = Vector2(float(pos[0]), float(pos[1]))
		_region_defs[id] = {
			"display_name": str(d.get("display_name", id)),
			"centre": centre,
			"radius": float(d.get("radius", 40.0)),
		}

	revision += 1


# --- fog of war ---------------------------------------------------------

## Reveals every cell whose CENTER lies within `reveal_radius` of the given
## world position, and auto-discovers any landmark whose `discover_radius`
## the position has entered. Returns true (and bumps `revision`) only when
## something was actually newly revealed or discovered — a repeat call from
## a stationary player must be a no-op, not a UI rebuild every frame.
func mark_visited(world_pos: Vector3) -> bool:
	var revealed := _reveal_cells(world_pos, reveal_radius)
	var discovered := _discover_landmarks_near(world_pos)
	var changed := revealed or discovered
	if changed:
		revision += 1
	return changed


func is_discovered(world_pos: Vector3) -> bool:
	var cell := world_to_cell(world_pos)
	return cell_at(cell.x, cell.y)


# --- named regions ---------------------------------------------------------

## Called every discovery tick alongside `mark_visited` (`game_state.gd`'s
## own throttle, not a raw per-physics-frame call). Tracks which authored
## region (if any) the position falls inside and, the moment the player
## crosses into one they have never entered before, queues an announcement
## for the HUD to show once — the Fortnite-style "you have entered X" beat
## the owner asked for. Silent (no queued text, no revision bump) on every
## other call: re-entering an already-discovered region, wandering between
## two regions, or standing in open pasture outside all of them.
func update_region(world_pos: Vector3) -> void:
	var here := Vector2(world_pos.x, world_pos.z)
	var region := _region_at(here)
	var new_id := str(region.get("id", "")) if not region.is_empty() else ""
	if new_id == _current_region_id:
		return
	_current_region_id = new_id
	if new_id.is_empty() or _discovered_regions.has(new_id):
		return
	_discovered_regions[new_id] = true
	_pending_region_announcement = str(region.get("display_name", ""))
	revision += 1


## The region whose centre `here` is nearest to, among every region `here`
## actually falls inside (there is no authored overlap today, but nearest-
## centre-among-candidates is the well-defined answer if that ever changes,
## rather than "whichever the dictionary iterates to last"). {} outside
## every authored region.
func _region_at(here: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := INF
	for id: String in _region_defs.keys():
		var def: Dictionary = _region_defs[id]
		var centre: Vector2 = def.get("centre", Vector2.ZERO)
		var dist := here.distance_to(centre)
		if dist <= float(def.get("radius", 0.0)) and dist < best_dist:
			best_dist = dist
			best = {"id": id, "display_name": def.get("display_name", id)}
	return best


## Read-and-clear: "" if nothing is waiting (the common case, polled every
## frame), the newly-entered region's display name exactly once otherwise.
func take_pending_region_announcement() -> String:
	var text := _pending_region_announcement
	_pending_region_announcement = ""
	return text


## Every authored region, discovered or not — the full map draws a name
## label only for the discovered ones, but a renderer needs the geometry
## for both to decide that for itself (same split `landmarks()` already
## gives silhouettes for undiscovered majors).
func regions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in _region_defs.keys():
		var def: Dictionary = _region_defs[id]
		out.append({
			"id": id,
			"display_name": def.get("display_name", id),
			"centre": def.get("centre", Vector2.ZERO),
			"radius": def.get("radius", 40.0),
			"discovered": _discovered_regions.has(id),
		})
	return out


func discovered_fraction() -> float:
	var total := GRID * GRID
	if total <= 0:
		return 0.0
	return float(_visited_count) / float(total)


func cell_grid_size() -> int:
	return GRID


func cell_at(ix: int, iz: int) -> bool:
	if ix < 0 or iz < 0 or ix >= GRID or iz >= GRID:
		return false
	return _visited[iz * GRID + ix] == 1


func world_to_cell(world_pos: Vector3) -> Vector2i:
	var ix := int(floor((world_pos.x - ORIGIN.x) / CELL))
	var iz := int(floor((world_pos.z - ORIGIN.y) / CELL))
	return Vector2i(ix, iz)


# --- landmarks -----------------------------------------------------------

## Every configured landmark, in file order, plus every dynamic marker
## appended after them. Configured entries carry `discovered`; dynamic
## markers are always `discovered: true` (they would not exist yet if they
## were not) and carry `dynamic: true` so a renderer can tell the two kinds
## of entry apart without matching against the config.
func landmarks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in _landmark_defs.keys():
		var def: Dictionary = _landmark_defs[id]
		out.append({
			"id": id,
			"display_name": def.get("display_name", ""),
			"icon": def.get("icon", ""),
			"position": def.get("position"),
			"category": def.get("category", "minor"),
			"discovered": _discovered.has(id),
			"silhouette": bool(def.get("silhouette", false)),
		})
	for id: String in _dynamic.keys():
		var marker: Dictionary = _dynamic[id]
		out.append({
			"id": id,
			"icon": marker.get("icon", ""),
			"position": marker.get("position"),
			"dynamic": true,
			"discovered": true,
		})
	return out


func is_landmark_discovered(id: String) -> bool:
	return _discovered.has(id)


## Manual discovery for story beats (e.g. a cutscene that reveals the
## stronghold silhouette). Returns true only when the id is a real landmark
## and was not already discovered.
func discover_landmark(id: String) -> bool:
	if not _landmark_defs.has(id):
		return false
	if _discovered.has(id):
		return false
	_discovered[id] = true
	revision += 1
	return true


# --- dynamic markers -------------------------------------------------------

## Adds or replaces the marker at `id` — camps and the tracked objective use
## this, and a repeated call with the same id (e.g. the objective moving)
## replaces rather than stacks.
func add_dynamic_marker(id: String, icon: String, world_pos: Vector3) -> void:
	_dynamic[id] = {"icon": icon, "position": Vector2(world_pos.x, world_pos.z)}
	revision += 1


func remove_dynamic_marker(id: String) -> void:
	if not _dynamic.has(id):
		return
	_dynamic.erase(id)
	revision += 1


## Convenience for the HUD's objective pointer. {} when nothing is tracked.
func objective_marker() -> Dictionary:
	if not _dynamic.has("objective"):
		return {}
	var marker: Dictionary = _dynamic["objective"]
	return {
		"id": "objective",
		"icon": marker.get("icon", ""),
		"position": marker.get("position"),
		"dynamic": true,
		"discovered": true,
	}


# --- save/load ---------------------------------------------------------

## Compact and versionless — the save system wraps this in its own slot
## format and version number, the same way it already owns party/inventory
## serialization; this class only knows how to describe its own state.
func save_data() -> Dictionary:
	var markers: Array = []
	for id: String in _dynamic.keys():
		var marker: Dictionary = _dynamic[id]
		var pos: Vector2 = marker.get("position", Vector2.ZERO)
		markers.append({"id": id, "icon": marker.get("icon", ""), "position": [pos.x, pos.y]})
	return {
		"visited_b64": Marshalls.raw_to_base64(_visited),
		"landmarks": _discovered.keys(),
		"dynamic_markers": markers,
		"regions": _discovered_regions.keys(),
	}


## Tolerant of missing keys — `load_data({})` is a working fresh state, the
## same contract save_game.gd already relies on for parties and satchels
## that predate a field. A `visited_b64` of the wrong length (corrupted save,
## grid dimensions changed under it) is not trusted: it is discarded with a
## warning and the fresh, fully-hidden grid is kept rather than reading
## garbage cells or crashing on an out-of-range index.
func load_data(data: Dictionary) -> void:
	_visited.fill(0)
	_visited_count = 0
	_discovered.clear()
	_dynamic.clear()
	_discovered_regions.clear()
	_current_region_id = ""
	_pending_region_announcement = ""

	var b64 := str(data.get("visited_b64", ""))
	if not b64.is_empty():
		var raw := Marshalls.base64_to_raw(b64)
		if raw.size() == _visited.size():
			_visited = raw
			_visited_count = _count_set(_visited)
		else:
			push_warning("MapState.load_data: visited grid is %d bytes, expected %d; keeping a fresh grid" % [raw.size(), _visited.size()])

	for id: Variant in data.get("landmarks", []):
		var sid := str(id)
		if _landmark_defs.has(sid):
			_discovered[sid] = true

	for id: Variant in data.get("regions", []):
		var sid := str(id)
		if _region_defs.has(sid):
			_discovered_regions[sid] = true

	for entry: Variant in data.get("dynamic_markers", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d := entry as Dictionary
		var id := str(d.get("id", ""))
		if id.is_empty():
			continue
		var pos: Array = d.get("position", [0.0, 0.0])
		var position := Vector2.ZERO
		if pos.size() >= 2:
			position = Vector2(float(pos[0]), float(pos[1]))
		_dynamic[id] = {"icon": str(d.get("icon", "")), "position": position}

	revision += 1


# --- debug / testing helpers ---------------------------------------------

## Reveals the entire grid. Debug/testing only — no gameplay path should
## call this; a "reveal whole map" item or cheat is a design decision, not
## something this file decides on its own.
func reveal_all() -> void:
	if _visited_count == GRID * GRID:
		return
	_visited.fill(1)
	_visited_count = GRID * GRID
	revision += 1


## Reveals a circle of arbitrary radius with no landmark side effects.
## Debug/testing only — `mark_visited()` is the real gameplay entry point and
## is the one that also discovers landmarks.
func reveal_circle(world_pos: Vector3, radius: float) -> void:
	if _reveal_cells(world_pos, radius):
		revision += 1


# --- internals -------------------------------------------------------------

## Sets every cell whose center lies within `radius` of `world_pos` to
## visited. Returns true if anything was newly set. Iterates only the cell
## rectangle bounding the circle, not the full 128x128 grid.
func _reveal_cells(world_pos: Vector3, radius: float) -> bool:
	if radius <= 0.0:
		return false
	var cx := world_pos.x
	var cz := world_pos.z

	var min_ix := int(floor((cx - radius - ORIGIN.x) / CELL))
	var max_ix := int(floor((cx + radius - ORIGIN.x) / CELL))
	var min_iz := int(floor((cz - radius - ORIGIN.y) / CELL))
	var max_iz := int(floor((cz + radius - ORIGIN.y) / CELL))

	min_ix = clampi(min_ix, 0, GRID - 1)
	max_ix = clampi(max_ix, 0, GRID - 1)
	min_iz = clampi(min_iz, 0, GRID - 1)
	max_iz = clampi(max_iz, 0, GRID - 1)

	var changed := false
	var radius_sq := radius * radius
	for iz in range(min_iz, max_iz + 1):
		var center_z := ORIGIN.y + (float(iz) + 0.5) * CELL
		var dz := center_z - cz
		var dz_sq := dz * dz
		for ix in range(min_ix, max_ix + 1):
			var center_x := ORIGIN.x + (float(ix) + 0.5) * CELL
			var dx := center_x - cx
			if dx * dx + dz_sq > radius_sq:
				continue
			var idx := iz * GRID + ix
			if _visited[idx] == 0:
				_visited[idx] = 1
				_visited_count += 1
				changed = true
	return changed


## Discovers any not-yet-discovered landmark within its own discover_radius
## of `world_pos`. Returns true if anything was newly discovered.
func _discover_landmarks_near(world_pos: Vector3) -> bool:
	var here := Vector2(world_pos.x, world_pos.z)
	var changed := false
	for id: String in _landmark_defs.keys():
		if _discovered.has(id):
			continue
		var def: Dictionary = _landmark_defs[id]
		var position: Vector2 = def.get("position", Vector2.ZERO)
		var radius: float = def.get("discover_radius", 0.0)
		if position.distance_to(here) <= radius:
			_discovered[id] = true
			changed = true
	return changed


func _count_set(bytes: PackedByteArray) -> int:
	var count := 0
	for b in bytes:
		if b == 1:
			count += 1
	return count
