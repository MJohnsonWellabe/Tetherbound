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
## `Dictionary` of cells because the grid is fixed-size (today 128x128 =
## 16384 cells, derived from `terrain_playground.json` — see `grid_x()`/
## `grid_z()` below, `docs/specs/MEADOWS_MACRO_LAYOUT.md` §8.6) and dense enough
## that a byte array is both the cheaper storage and the format the eventual
## fog texture wants anyway.
##
## `revision` is the same polling idiom as autoload/party.gd and
## autoload/inventory.gd: the minimap and full map UI read this once a
## frame and rebuild only when it moves, instead of listening to a signal
## for every single cell reveal.
##
## Pure logic, no `Node`, no transform — testable headlessly the same way
## party.gd and inventory.gd are (tests/test_map_state.gd).

## Tunable. `docs/specs/MEADOWS_MACRO_LAYOUT.md` §8.6a recommends 16.0 for the
## corridor world (§8.6a's own math: 1 MB/save at CELL 4.0 over 8192x2048m vs
## 65 KB at 16.0, for a reveal radius that is already 3 cells wide either
## way) — that is a recommendation for whoever lands the corridor config, not
## a measurement, so this stays 4.0 until then.
const CELL := 4.0
const WORLD_EXTENT := preload("res://scripts/world/world_extent.gd")

## `GRID`/`ORIGIN` used to be hard-coded consts assuming a ±256m square world
## (`docs/decisions/D33` said so explicitly). `docs/specs/MEADOWS_MACRO_LAYOUT.md`
## §8.6 names this file as the one place that hard-coded assumption gets
## WRITTEN TO THE SAVE FILE — `save_data()`'s `visited_b64` below — so it is
## the one map-system file where a silent constant edit is a save-format
## change, not just a code change (§8.6a). `grid_x()`/`grid_z()`/`origin()`
## derive the grid from `terrain_playground.json` instead, lazily and cached
## (same pattern as `scripts/combat/catch_math.gd`'s `_config`), so today's
## still-512m world produces the exact same 128x128 grid over ±256m these
## consts used to hard-code, byte for byte — and the day the corridor config
## lands, this is a data change, not another hunt through this file.
static var _grid_x := -1
static var _grid_z := -1
static var _origin := Vector2.ZERO


static func _ensure_extent() -> void:
	if _grid_x > 0:
		return
	var bounds: Dictionary = WORLD_EXTENT.bounds()
	var min_x: float = float(bounds.get("min_x", 0.0))
	var min_z: float = float(bounds.get("min_z", 0.0))
	_origin = Vector2(min_x, min_z)
	# ceil, not round/floor: a world extent that is not an exact multiple of
	# CELL must still be fully covered, never clipped short at the far edge.
	_grid_x = maxi(1, int(ceil((float(bounds.get("max_x", 0.0)) - min_x) / CELL)))
	_grid_z = maxi(1, int(ceil((float(bounds.get("max_z", 0.0)) - min_z) / CELL)))


static func grid_x() -> int:
	_ensure_extent()
	return _grid_x


static func grid_z() -> int:
	_ensure_extent()
	return _grid_z


static func origin() -> Vector2:
	_ensure_extent()
	return _origin


## Polled by the minimap and full map. Bumped on any visible change: a newly
## revealed cell, a landmark discovery, or a dynamic marker add/remove.
var revision: int = 0

## Tunable, from map_landmarks.json.
var reveal_radius: float = 45.0
var minimap_span_m: float = 90.0

var _visited: PackedByteArray = PackedByteArray()
var _visited_count: int = 0

## Fog dirty tracking, for the minimap/full-map texture builders.
##
## OP23-01 root cause: those builders rebuilt the WHOLE grid on every
## `revision` bump. That was fine at the 128x128 this file's header still
## describes, but the corridor world derives 512x2048 = 1,048,576 cells, and
## `mark_visited()` bumps `revision` on essentially every 0.5s discovery tick
## while walking (an 80m reveal radius over a 4m cell always sweeps new cells).
## Measured: 837ms per full rebuild, 735ms of which was the per-cell
## `cell_at()` cross-object call. That is the freeze-every-few-feet the owner
## reported everywhere including indoors, and why a per-frame arbiter fix did
## nothing for it — this is a burst on a spatial grid, not steady frame cost.
##
## So: accumulate the cell rect actually touched since the last texture build,
## and let the builders patch only that. `_fog_dirty_all` covers the wholesale
## replacements (configure/load/reveal_all) where a rect is meaningless.
var _fog_dirty_all: bool = true
var _fog_dirty_min := Vector2i.ZERO
var _fog_dirty_max := Vector2i.ZERO
var _fog_has_dirty_rect: bool = false

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
	_visited.resize(grid_x() * grid_z())
	_visited.fill(0)
	_visited_count = 0
	_mark_fog_dirty_all()

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

	_seed_starting_reveal(config.get("starting_reveal", []) as Array)

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
	var total := grid_x() * grid_z()
	if total <= 0:
		return 0.0
	return float(_visited_count) / float(total)


## Rectangular, not square, per §8.6a — a caller building a fog texture
## (`minimap.gd`, `tab_map.gd`) needs both dimensions, not one shared side.
func cell_grid_x() -> int:
	return grid_x()


func cell_grid_z() -> int:
	return grid_z()


func cell_size() -> float:
	return CELL


## Bulk read of the fog bitfield (1 byte per cell, 1 = discovered), for
## texture builders. `cell_at()` stays the right call for single lookups, but
## in a million-cell loop the cross-object call IS the cost — see the
## `_fog_dirty_all` comment above.
func visited_bytes() -> PackedByteArray:
	return _visited


## Consumes the pending fog dirty region. Returns:
##   {"all": true}                     -> rebuild everything (grid replaced)
##   {"all": false, "rect": Rect2i}    -> patch only this cell rect
##   {"all": false, "rect": null}      -> nothing changed since last call
## Clearing on read is deliberate: two consumers (minimap + full map) each
## need their own view, so each keeps its own last-built revision and asks for
## a full rebuild when it has fallen behind rather than sharing this flag.
func take_fog_dirty() -> Dictionary:
	if _fog_dirty_all:
		_fog_dirty_all = false
		_fog_has_dirty_rect = false
		return {"all": true, "rect": null}
	if not _fog_has_dirty_rect:
		return {"all": false, "rect": null}
	var rect := Rect2i(
		_fog_dirty_min,
		Vector2i(_fog_dirty_max.x - _fog_dirty_min.x + 1, _fog_dirty_max.y - _fog_dirty_min.y + 1))
	_fog_has_dirty_rect = false
	return {"all": false, "rect": rect}


## Marks the whole fog grid as needing a rebuild. Called wherever `_visited`
## is replaced or filled wholesale rather than revealed cell by cell.
func _mark_fog_dirty_all() -> void:
	_fog_dirty_all = true
	_fog_has_dirty_rect = false


func cell_at(ix: int, iz: int) -> bool:
	if ix < 0 or iz < 0 or ix >= grid_x() or iz >= grid_z():
		return false
	return _visited[iz * grid_x() + ix] == 1


func world_to_cell(world_pos: Vector3) -> Vector2i:
	var o := origin()
	var ix := int(floor((world_pos.x - o.x) / CELL))
	var iz := int(floor((world_pos.z - o.y) / CELL))
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


## OWNER-0901-BOND-MILESTONES: `game_state.gd::_process()` diffs this before
## and after `mark_visited()` to know whether a landmark was newly discovered
## THIS tick, without `mark_visited()`'s own bool return (which also fires for
## an ordinary fog reveal) conflating the two.
func discovered_landmark_count() -> int:
	return _discovered.size()


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
##
## `grid_x`/`grid_z`/`cell`/`origin_x`/`origin_z` are new — §8.6a's EXPLICIT
## GRID DESCRIPTOR, added because the byte-length check alone cannot catch
## the dangerous case: `CELL` or the world's bounds changing while
## `GRID_X * GRID_Z` happens to stay the same length, which would otherwise
## load, pass the length check, and silently reveal an arbitrary pattern of
## the WRONG ground as already-explored. A save written by a build old
## enough to predate this field carries none of it; `load_data()` below
## falls back to the pre-existing length-only check for exactly that case.
func save_data() -> Dictionary:
	var markers: Array = []
	for id: String in _dynamic.keys():
		var marker: Dictionary = _dynamic[id]
		var pos: Vector2 = marker.get("position", Vector2.ZERO)
		markers.append({"id": id, "icon": marker.get("icon", ""), "position": [pos.x, pos.y]})
	var o := origin()
	return {
		"visited_b64": Marshalls.raw_to_base64(_visited),
		"grid_x": grid_x(),
		"grid_z": grid_z(),
		"cell": CELL,
		"origin_x": o.x,
		"origin_z": o.y,
		"landmarks": _discovered.keys(),
		"dynamic_markers": markers,
		"regions": _discovered_regions.keys(),
	}


## Tolerant of missing keys — `load_data({})` is a working fresh state, the
## same contract save_game.gd already relies on for parties and satchels
## that predate a field. A `visited_b64` that fails validation (corrupted
## save, or — see below — grid geometry changed under it) is not trusted: it
## is discarded with a warning and the fresh, fully-hidden grid is kept
## rather than reading garbage cells, crashing on an out-of-range index, or
## silently revealing the wrong part of the world.
##
## TWO VALIDATION PATHS, per §8.6a. A save carrying the grid descriptor
## (`grid_x`/`grid_z`/`cell`/`origin_x`/`origin_z`, added alongside this
## check) is trusted only if EVERY one of those matches this build's current
## grid — not just the byte length, which is the check that cannot tell "the
## world resized to a length that happens to match" from "nothing changed".
## A save with no descriptor at all predates this change; for that one case
## only, the old length-only check is still the right answer, because on an
## unresized world (today) the current grid IS 128x128 over ±256m, the exact
## shape every such save already assumes — the benign case §8.6a describes,
## not the dangerous one.
func load_data(data: Dictionary) -> void:
	_visited.fill(0)
	_visited_count = 0
	_mark_fog_dirty_all()
	_discovered.clear()
	_dynamic.clear()
	_discovered_regions.clear()
	_current_region_id = ""
	_pending_region_announcement = ""

	var b64 := str(data.get("visited_b64", ""))
	if not b64.is_empty():
		var raw := Marshalls.base64_to_raw(b64)
		var has_descriptor := data.has("grid_x") and data.has("grid_z") and data.has("cell") \
			and data.has("origin_x") and data.has("origin_z")
		if has_descriptor:
			var o := origin()
			var geometry_matches := int(data.get("grid_x", -1)) == grid_x() \
				and int(data.get("grid_z", -1)) == grid_z() \
				and is_equal_approx(float(data.get("cell", -1.0)), CELL) \
				and is_equal_approx(float(data.get("origin_x", INF)), o.x) \
				and is_equal_approx(float(data.get("origin_z", INF)), o.y)
			if geometry_matches and raw.size() == _visited.size():
				_visited = raw
				_visited_count = _count_set(_visited)
			else:
				push_warning("MapState.load_data: saved grid geometry does not match this world; keeping a fresh grid")
		elif raw.size() == _visited.size():
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
	var total := grid_x() * grid_z()
	if _visited_count == total:
		return
	_visited.fill(1)
	_visited_count = total
	_mark_fog_dirty_all()
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
## The ground the player is presumed to already know, revealed before they
## have walked a step.
##
## `docs/owner/OWNER_DIRECTIVES_2026-08-22.md` section 3: "The village and the roads
## out of it start revealed... The player does not start blind in their own
## home town." The fog itself was never broken -- it was working exactly as
## OW3 built it, from zero reveal -- so a fresh save opened a black rectangle
## with a dot on it, which is what the owner reported as "the map is currently
## unusable" (OP21-15). The ruling was recorded in `ralph/BLOCKED.md` and then
## never implemented: both commits that closed that entry touched only
## `BLOCKED.md`.
##
## Authored in `data/config/map_landmarks.json`, not here, for the same reason
## the landmark table is: where the village is and where its roads run is
## content, and it will be argued with. Each entry is `{"at": [x, z],
## "radius": m}`; a run of overlapping circles down a road reveals the road.
## Walking still uncovers everything else exactly as before -- this only moves
## the starting point off zero.
func _seed_starting_reveal(entries: Array) -> void:
	for entry: Variant in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d := entry as Dictionary
		var at: Array = d.get("at", []) as Array
		if at.size() < 2:
			continue
		_reveal_cells(
			Vector3(float(at[0]), 0.0, float(at[1])),
			float(d.get("radius", reveal_radius)))


func _reveal_cells(world_pos: Vector3, radius: float) -> bool:
	if radius <= 0.0:
		return false
	var cx := world_pos.x
	var cz := world_pos.z
	var o := origin()
	var gx := grid_x()
	var gz := grid_z()

	var min_ix := int(floor((cx - radius - o.x) / CELL))
	var max_ix := int(floor((cx + radius - o.x) / CELL))
	var min_iz := int(floor((cz - radius - o.y) / CELL))
	var max_iz := int(floor((cz + radius - o.y) / CELL))

	min_ix = clampi(min_ix, 0, gx - 1)
	max_ix = clampi(max_ix, 0, gx - 1)
	min_iz = clampi(min_iz, 0, gz - 1)
	max_iz = clampi(max_iz, 0, gz - 1)

	var changed := false
	var radius_sq := radius * radius
	for iz in range(min_iz, max_iz + 1):
		var center_z := o.y + (float(iz) + 0.5) * CELL
		var dz := center_z - cz
		var dz_sq := dz * dz
		for ix in range(min_ix, max_ix + 1):
			var center_x := o.x + (float(ix) + 0.5) * CELL
			var dx := center_x - cx
			if dx * dx + dz_sq > radius_sq:
				continue
			var idx := iz * gx + ix
			if _visited[idx] == 0:
				_visited[idx] = 1
				_visited_count += 1
				_mark_fog_dirty(ix, iz)
				changed = true
	return changed


## Grows the pending fog dirty rect to include one newly-revealed cell.
func _mark_fog_dirty(ix: int, iz: int) -> void:
	if not _fog_has_dirty_rect:
		_fog_dirty_min = Vector2i(ix, iz)
		_fog_dirty_max = Vector2i(ix, iz)
		_fog_has_dirty_rect = true
		return
	_fog_dirty_min.x = mini(_fog_dirty_min.x, ix)
	_fog_dirty_min.y = mini(_fog_dirty_min.y, iz)
	_fog_dirty_max.x = maxi(_fog_dirty_max.x, ix)
	_fog_dirty_max.y = maxi(_fog_dirty_max.y, iz)


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
