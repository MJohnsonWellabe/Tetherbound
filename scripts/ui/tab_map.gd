extends "res://scripts/ui/menu_tab.gd"

## THE MEADOWS — the full map. D33 / spec §6A.12: the minimap and the full map
## share ONE database (`autoload/map_state.gd`) and ONE icon vocabulary
## (`assets/ui/icons/map/`). This tab reads the same `Game.map` the minimap
## reads and draws the same icon per landmark id — nothing here invents a
## second source of truth, it is only a bigger, un-rotated window onto it.
##
## NORTH-UP, DELIBERATELY DIFFERENT FROM THE MINIMAP. Spec's map/minimap
## consistency is about the DATA (one fog grid, one landmark list, one icon
## per landmark), not about orientation. A minimap that rotates with the
## player is answering "which way am I facing"; a full map opened from a menu
## is answering "where is everything" and reads worse if it spins under a
## cursor the player is trying to hold still on a legend row. `-Z` is drawn as
## up ("north") purely because that is Godot's own camera-forward axis — there
## is no documented in-fiction compass, so this is a naming convenience, not a
## rule anyone could get wrong.
##
## FIXED VIEW, NO PAN/ZOOM (v1). `MapState`'s grid is 128 cells at 4m —
## 512x512m — and every landmark in `data/config/map_landmarks.json` sits well
## inside that box: the whole Meadows already fits one screen at a glance, so
## fitting the world to the panel is not a corner cut, it is the actual right
## answer for a biome this size. Free pan/zoom was considered and set aside
## for a real reason, not laziness: every existing in-menu directional read
## (`tab_backpack.gd`, `tab_pals.gd`) rides Godot's `ui_*` focus-navigation
## actions, which this canvas cannot also repurpose as a pan axis without
## fighting the same stick the d-pad uses to move focus off the map entirely.
## Gameplay's `move_*` actions are the wrong tool inside a paused menu (the
## world tree is paused; nothing gameplay-side should be listening), and this
## agent may not add a new input action to `project.godot` to invent a real
## pan verb (CLAUDE.md: "do not silently invent major design decisions" reads
## on adding input actions the same way it reads on adding a mechanic). A
## zoomed, panned map is real future work with a real cost; it is deferred
## here, not skipped.
##
## `revision()` STAYS CONSTANT (0). Per `menu_tab.gd`'s contract, `revision()`
## gates `build()` — and `game_menu.gd::open()`/`select()` already force one
## rebuild every time this tab is opened or switched to (`_last_revision = -1`
## on both paths), so a constant `revision()` does not mean "never rebuilds":
## it means "does not rebuild every frame while sitting open," which is the
## only thing that would actually break something — the strategic canvas and
## legend row would tear down mid-frame and controller focus would fall off
## the map. `poll()` is what redraws the canvas and refreshes the surveyed-%
## and legend text every frame this tab is showing, the same split
## `tab_pals.gd` uses for HP bars that update without ever rebuilding rows.

const MAP_STATE := preload("res://autoload/map_state.gd")

## Not preloaded: `scripts/world/map_baker.gd` is `docs/decisions/D33`'s
## minimap/full-map terrain baker, owned and delivered by a concurrent agent
## working alongside this one — at the moment this file was written that
## agent's work could land before, during or after this tab's own, and a bare
## `preload()` on a script that does not exist yet fails to COMPILE this
## whole file, which is worse than any runtime fallback. `_terrain_texture()`
## below checks `ResourceLoader.exists()` and the resulting script's own
## `has_method()` before ever calling it, so this tab works whether that file
## has landed or not, and it calls `bake_cached(world)` the same way
## `minimap.gd` does — same static function, same default `user://cache/
## map_meadows.png`, so the two screens share not just the fog/landmark data
## but the literal baked terrain bitmap, one bake for both.
const MAP_BAKER_PATH := "res://scripts/world/map_baker.gd"

const ICON_DIR := "res://assets/ui/icons/map/"
const ICON_SIZE := 26.0
const PLAYER_MARKER_RADIUS := 6.0
const OBJECTIVE_RADIUS := 9.0

## How far the player has to move before a redraw is worth spending — the fog
## trail is drawn from whole grid cells (4m each), so anything smaller than a
## cell is invisible on screen anyway.
const REDRAW_MOVE_EPSILON := 2.0

## One draw call's worth of state, refreshed by `MapCanvas._draw()` reaching
## back into the owning tab. A plain `Control` rather than a scene: this
## screen has exactly one of them and it is entirely code-drawn, the same
## reasoning `starter_picker.gd`'s header gives for not promoting a
## SubViewport trick to a `.tscn` for a single user.
class MapCanvas extends Control:
	var tab: Node = null

	func _draw() -> void:
		if tab != null:
			tab.call("_draw_map", self)


var _canvas: MapCanvas = null
var _surveyed_label: Label = null
var _legend_row: HBoxContainer = null

var _last_map_revision: int = -1
var _last_player_pos: Vector3 = Vector3.ZERO
var _has_last_player_pos: bool = false

var _terrain_attempted: bool = false
var _terrain_tex: Texture2D = null
var _icon_cache: Dictionary = {}


func build() -> void:
	for child in get_children():
		child.queue_free()
	_terrain_attempted = false
	_terrain_tex = null
	_icon_cache.clear()
	_last_map_revision = -1
	_has_last_player_pos = false

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	add_child(header)

	var title := Label.new()
	title.text = "THE MEADOWS"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_surveyed_label = Label.new()
	_surveyed_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_surveyed_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	header.add_child(_surveyed_label)

	_canvas = MapCanvas.new()
	_canvas.tab = self
	_canvas.custom_minimum_size = Vector2(640, 440)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.focus_mode = Control.FOCUS_ALL
	var canvas_panel := _panel(_canvas)
	canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(canvas_panel)

	_legend_row = HBoxContainer.new()
	_legend_row.add_theme_constant_override("separation", 22)
	add_child(_legend_row)

	poll()
	UITokens.make_text_legible(self)


func first_focus() -> Control:
	return _canvas


## See the header note: constant on purpose. A canvas redraw is not a rebuild.
func revision() -> int:
	return 0


func poll() -> void:
	if _canvas == null:
		return

	var map_state: RefCounted = _map_state()
	var current_revision: int = int(map_state.get("revision")) if map_state != null else -1
	var revision_changed := current_revision != _last_map_revision

	var moved := false
	var player := _player_node()
	if player != null:
		var pos: Vector3 = player.global_position
		if not _has_last_player_pos or pos.distance_to(_last_player_pos) > REDRAW_MOVE_EPSILON:
			moved = true
		_last_player_pos = pos
		_has_last_player_pos = true

	if revision_changed or moved:
		_canvas.queue_redraw()
	if revision_changed:
		_last_map_revision = current_revision
		_update_legend(map_state)

	_update_header(map_state)


func _update_header(map_state: RefCounted) -> void:
	if _surveyed_label == null:
		return
	if map_state == null:
		_surveyed_label.text = "Surveyed: --"
		return
	var fraction: float = float(map_state.call("discovered_fraction"))
	_surveyed_label.text = "Surveyed: %d%%" % int(round(fraction * 100.0))


func _update_legend(map_state: RefCounted) -> void:
	if _legend_row == null:
		return
	for child in _legend_row.get_children():
		child.queue_free()
	if map_state == null:
		return

	var seen: Dictionary = {}
	for entry: Dictionary in (map_state.call("landmarks") as Array):
		if bool(entry.get("dynamic", false)):
			continue
		if not bool(entry.get("discovered", false)):
			continue
		var icon_name := str(entry.get("icon", ""))
		if icon_name.is_empty() or seen.has(icon_name):
			continue
		seen[icon_name] = true
		_legend_row.add_child(_legend_entry(icon_name, str(entry.get("display_name", icon_name))))

	UITokens.make_text_legible(_legend_row)


func _legend_entry(icon_name: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var icon := TextureRect.new()
	icon.texture = _icon_texture(icon_name)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	row.add_child(label)

	return row


# --- drawing -----------------------------------------------------------------


## Called by `MapCanvas._draw()`. Split out of the inner class so every helper
## below can use this tab's own `state()`/`_map_state()` plumbing instead of
## duplicating it on the Control.
func _draw_map(canvas: Control) -> void:
	var rect_size: Vector2 = canvas.size
	if rect_size.x <= 0.0 or rect_size.y <= 0.0:
		return

	# Letterbox to a centered square: the world is 512x512m (square), the
	# panel usually is not, and stretching x/y independently would visibly
	# warp the landmark layout relative to the terrain bake beneath it.
	var side: float = minf(rect_size.x, rect_size.y)
	var map_origin := Vector2((rect_size.x - side) * 0.5, (rect_size.y - side) * 0.5)
	var map_rect := Rect2(map_origin, Vector2(side, side))

	canvas.draw_rect(Rect2(Vector2.ZERO, rect_size), UITokens.BG_DEEP)

	var world: Node = null
	if canvas.is_inside_tree():
		world = canvas.get_tree().get_current_scene()

	var terrain := _terrain_texture(world)
	if terrain != null:
		canvas.draw_texture_rect(terrain, map_rect, false)
	else:
		# Defensive fallback (spec: NEVER crash) — headless tests and a menu
		# opened before the world finishes standing up both land here.
		canvas.draw_rect(map_rect, UITokens.BG_PANEL_ALT)

	var map_state: RefCounted = _map_state()
	if map_state == null:
		return

	var fog := _fog_texture(map_state)
	if fog != null:
		canvas.draw_texture_rect(fog, map_rect, false)

	for entry: Dictionary in (map_state.call("landmarks") as Array):
		if bool(entry.get("dynamic", false)):
			if str(entry.get("id", "")) == "objective":
				continue  # drawn below, as a diamond, not a plain icon
			_draw_icon(canvas, map_rect, entry, 1.0)
			continue
		if bool(entry.get("discovered", false)):
			_draw_icon(canvas, map_rect, entry, 1.0)
		elif bool(entry.get("silhouette", false)):
			_draw_icon(canvas, map_rect, {"icon": "question", "position": entry.get("position")}, 0.6)

	var objective: Dictionary = map_state.call("objective_marker")
	if not objective.is_empty():
		_draw_objective(canvas, map_rect, objective)

	if world != null:
		var player := _player_node()
		if player != null:
			_draw_player(canvas, map_rect, player.global_position)


func _draw_icon(canvas: Control, map_rect: Rect2, entry: Dictionary, alpha: float) -> void:
	var icon_name := str(entry.get("icon", ""))
	if icon_name.is_empty():
		return
	var tex := _icon_texture(icon_name)
	if tex == null:
		return
	var pos: Vector2 = entry.get("position", Vector2.ZERO)
	var point := _world_to_canvas(pos, map_rect)
	var size := Vector2(ICON_SIZE, ICON_SIZE)
	canvas.draw_texture_rect(tex, Rect2(point - size * 0.5, size), false, Color(1, 1, 1, alpha))


func _draw_objective(canvas: Control, map_rect: Rect2, marker: Dictionary) -> void:
	var pos: Vector2 = marker.get("position", Vector2.ZERO)
	var point := _world_to_canvas(pos, map_rect)
	var r := OBJECTIVE_RADIUS
	var points := PackedVector2Array([
		point + Vector2(0, -r), point + Vector2(r, 0), point + Vector2(0, r), point + Vector2(-r, 0),
	])
	canvas.draw_colored_polygon(points, UITokens.WARNING)
	canvas.draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
		UITokens.TEXT_PRIMARY, 1.5, true
	)


func _draw_player(canvas: Control, map_rect: Rect2, world_pos: Vector3) -> void:
	var point := _world_to_canvas(Vector2(world_pos.x, world_pos.z), map_rect)
	canvas.draw_circle(point, PLAYER_MARKER_RADIUS, UITokens.TEAL)
	canvas.draw_arc(point, PLAYER_MARKER_RADIUS + 3.0, 0.0, TAU, 16, UITokens.TEXT_PRIMARY, 1.5, true)


## World (x, z) -> a point inside `map_rect`, using the same grid `MapState`
## fogs (`MAP_STATE.ORIGIN`/`CELL`/`GRID` — the const-on-a-preloaded-script
## read `tab_pals.gd` already uses for `PARTY.MAX_PALS`), so a landmark and
## the fog cell under it can never drift apart.
func _world_to_canvas(pos: Vector2, map_rect: Rect2) -> Vector2:
	var span: float = float(MAP_STATE.CELL) * float(MAP_STATE.GRID)
	var origin: Vector2 = MAP_STATE.ORIGIN
	var nx: float = clampf((pos.x - origin.x) / span, 0.0, 1.0)
	var nz: float = clampf((pos.y - origin.y) / span, 0.0, 1.0)
	return map_rect.position + Vector2(nx * map_rect.size.x, nz * map_rect.size.y)


## Same two colours `scripts/ui/minimap.gd` fogs with (its own `FOG_UNDISCOVERED`/
## `FOG_DISCOVERED`) — copied rather than imported, since that file is a
## concurrent agent's and not this agent's to reach into, but D33 wants the
## two screens to read as one fog treatment and matching the colour costs
## nothing.
const FOG_UNDISCOVERED := Color(0.02, 0.02, 0.03, 0.95)
const FOG_DISCOVERED := Color(0.0, 0.0, 0.0, 0.0)


## One `ImageTexture` baked from the fog grid rather than ~16k individual
## `draw_rect` calls — only built on an actual redraw (gated by `poll()`),
## never per physics frame, so the cost is the same order as any other panel
## refresh in this menu.
func _fog_texture(map_state: RefCounted) -> ImageTexture:
	var grid: int = int(map_state.call("cell_grid_size"))
	if grid <= 0:
		return null
	var image := Image.create(grid, grid, false, Image.FORMAT_RGBA8)
	for iz in grid:
		for ix in grid:
			var discovered: bool = bool(map_state.call("cell_at", ix, iz))
			image.set_pixel(ix, iz, FOG_DISCOVERED if discovered else FOG_UNDISCOVERED)
	return ImageTexture.create_from_image(image)


## Lazily bakes the terrain texture through `scripts/world/map_baker.gd`, and
## is defensive at every step described in the header note: a missing baker
## script, a `bake_cached` that turns out not to be `static`, a `world` with
## no `ground_height_at` (this tab open in a headless test with no scene), or
## `get_tree().get_current_scene()` returning null all fall through to `null`
## rather than erroring — the caller draws a flat panel instead. Attempted at
## most once per `build()`, since `build()` already reruns on every fresh
## `open()`/`select()` (see the header note on `revision()`), which is exactly
## when it is worth retrying a world that was not ready last time.
func _terrain_texture(world: Node) -> Texture2D:
	if _terrain_attempted:
		return _terrain_tex
	_terrain_attempted = true

	if world == null or not world.has_method("ground_height_at"):
		return null
	if not ResourceLoader.exists(MAP_BAKER_PATH):
		return null

	var baker_script: Script = load(MAP_BAKER_PATH) as Script
	if baker_script == null or not baker_script.has_method("bake_cached"):
		return null

	var result: Variant = baker_script.call("bake_cached", world)
	_terrain_tex = result as Texture2D
	return _terrain_tex


func _icon_texture(icon_name: String) -> Texture2D:
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name]
	var path := "%s%s.png" % [ICON_DIR, icon_name]
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_icon_cache[icon_name] = tex
	return tex


func _map_state() -> RefCounted:
	var game := state()
	return game.get("map") if game != null else null


## Defensive the same way `_terrain_texture()` is: no tree, no current scene,
## or no `Player` node all read as "nothing to draw," never a crash. Matches
## `smoke_menu.gd`'s own lookup (`world.get_node_or_null(^"Player")`).
func _player_node() -> Node3D:
	if not is_inside_tree():
		return null
	var world := get_tree().get_current_scene()
	if world == null:
		return null
	return world.get_node_or_null(^"Player") as Node3D
