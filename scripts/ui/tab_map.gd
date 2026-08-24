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
## CONTROLLER NAVIGATION. The whole world fits at zoom 1. RT/LT zoom through a
## bounded range and the right stick pans only once zoomed, leaving the left
## stick/d-pad exclusively to the menu's existing focus navigation. Pan is
## stored in world metres and clamped from the visible span, so no aspect ratio
## or zoom level can scroll the whole Meadows off-screen into empty space.
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
## `tab_creatures.gd` uses for HP bars that update without ever rebuilding rows.

const MAP_STATE := preload("res://autoload/map_state.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

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
## OP21-15: bumped from 26 across the board (icon/marker/font sizes below) —
## this screen's `canvas.draw_*` calls sit under the SAME `canvas_items`
## viewport stretch every other Control on the tab does (`project.godot`'s
## `window/stretch/mode`), so a literal pixel size authored to read cleanly on
## the project's 1920x1080 authoring canvas becomes visibly smaller once that
## canvas is squeezed into the Ally's 1280x800 handheld output (stretch scale
## ~0.667). The owner's "currently unusable" covered exactly this: markers and
## labels that were legible at desktop size were not at handheld size. This
## file's own constants are the only legibility knob available here —
## `UITokens.FONT_TINY`/`FONT_LABEL` are shared by every other tab and are not
## this task's to retune globally.
const ICON_SIZE := 30.0
const PLAYER_MARKER_RADIUS := 8.0
## The facing arrow, in pixels: where its base sits (just clear of the dot's
## cream ring, which is drawn at `PLAYER_MARKER_RADIUS + 3`), how far past that
## the tip reaches, and how wide the base is. Long enough to read as a heading
## at a glance on a handheld, short enough not to be mistaken for a route line
## to something. TUNABLE.
const PLAYER_FACING_BASE := 12.0
const PLAYER_FACING_LENGTH := 12.0
const PLAYER_FACING_HALF_WIDTH := 7.0
const OBJECTIVE_RADIUS := 11.0
const MIN_ZOOM := 1.0
const MAX_ZOOM := 16.0
## Deliberate strategic scales: the 4:1 north/south Meadows corridor needs a
## substantial step before a 16:9 panel reads as a local rather than overview
## map. Every trigger press should make an unmistakable, useful change.
const ZOOM_LEVELS := [1.0, 4.0, 8.0, 16.0]
const PAN_SPEED_MPS := 1200.0

## How far the player has to move before a redraw is worth spending — the fog
## trail is drawn from whole grid cells (4m each), so anything smaller than a
## cell is invisible on screen anyway.
const REDRAW_MOVE_EPSILON := 2.0

## Canvas text sizes — bumped from `UITokens.FONT_TINY`/`FONT_LABEL` (19/23)
## for the same handheld-legibility reason `ICON_SIZE` above is bumped. These
## are read raw by `draw_string`/`draw_string_outline`, never by a `Label`
## node, so `UITokens.make_text_legible()`'s automatic outline pass (which
## only walks `Label`/`RichTextLabel` children) never reaches them — every
## canvas text draw below goes through `_draw_string_legible()` instead,
## which applies the SAME `UITokens.OUTLINE`/`OUTLINE_SIZE` treatment by
## hand, so a region name or destination label reads against any terrain
## colour underneath it rather than only the darkest ones.
## OP21-15's own bump (26/20, from the shared 19/23 UITokens defaults) still
## measured well under a legible handheld comfort bar at 1280x800: a blind
## capture-frame pass measured cap heights of only ~11px (region labels,
## destination callouts) and ~8px (the "DISCOVERED REGIONS"/"DESTINATIONS"
## section headers, which read through `CANVAS_HEADING_FONT_SIZE` here) against
## the ~16px comfort-bar every other bumped chrome element (title, footer) was
## already clearing. `assets/ui/fonts/kenney_future.ttf` is a thin geometric
## face whose strokes are only 1-2px at these sizes, which is exactly what
## made 11px and 8px read as much smaller than the raw number suggests.
## Raised again here, proportionally larger for the header role since it
## measured furthest under the bar (8px vs 11px starting point, same target).
const CANVAS_HEADING_FONT_SIZE := 30
const CANVAS_LABEL_FONT_SIZE := 38

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
var _controls_label: RichTextLabel = null

var _zoom: float = MIN_ZOOM
var _pan_world: Vector2 = Vector2.ZERO

## OP21-15: true once the player has moved the right stick while zoomed in.
## While false, the view keeps `_pan_world` locked to the player's own world
## position every `poll()` (`_follow_player_if_not_panned()`), so zooming in
## always centres and scales around wherever the player currently stands
## instead of the map's static geometric centre. Cleared back to false the
## moment zoom returns to `MIN_ZOOM` (`_clamp_pan()`), so re-opening zoom
## after backing all the way out starts following the player again rather
## than re-using a stale manual pan from earlier in the session.
var _manual_pan: bool = false

var _last_map_revision: int = -1
var _last_player_pos: Vector3 = Vector3.ZERO
var _has_last_player_pos: bool = false

var _terrain_attempted: bool = false
var _terrain_tex: Texture2D = null
var _icon_cache: Dictionary = {}
var _region_font: Font = null

## Cache for `_fog_texture()`, keyed on `map_state.revision` — see that
## function's own header for why this exists: the bug it fixed, not a
## pre-emptive optimisation.
var _fog_tex: ImageTexture = null
var _fog_tex_revision: int = -1

## Frames left to force a redraw regardless of `revision`/movement, counted
## down from `SETTLE_FRAMES` by every `poll()` right after `build()`. A freshly
## baked `ImageTexture` is created synchronously inside `_draw_map()` (the
## first draw this tab ever does); the rendering server is not guaranteed to
## have finished uploading it to the GPU before that SAME frame's draw
## commands sample it, which measured as a real one-frame "terrain renders
## solid white" glitch under software (llvmpipe) rendering — confirmed by
## reading the texture's own pixels straight out of `_terrain_texture()`
## (correct meadow-green) while the on-screen frame showed white. Because
## `poll()` otherwise only redraws on a state change, a player who opens the
## map and holds perfectly still would keep seeing that first bad frame
## forever. A few forced redraws right after open ride out the upload
## regardless of the true cause, cost nothing on a menu screen, and self-
## expire — no permanent per-frame redraw is added.
var _settle_frames_left: int = 0
const SETTLE_FRAMES := 6


func build() -> void:
	for child in get_children():
		child.queue_free()
	_zoom = MIN_ZOOM
	_pan_world = Vector2.ZERO
	_manual_pan = false
	_terrain_attempted = false
	_terrain_tex = null
	_fog_tex = null
	_fog_tex_revision = -1
	_icon_cache.clear()
	_last_map_revision = -1
	_has_last_player_pos = false
	_settle_frames_left = SETTLE_FRAMES

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
	# OP21-15: bumped past UITokens.FONT_TINY (19) — see CANVAS_LABEL_FONT_SIZE's
	# header for why this screen keeps its own legibility sizing.
	_surveyed_label.add_theme_font_size_override("font_size", CANVAS_HEADING_FONT_SIZE + 2)
	_surveyed_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	header.add_child(_surveyed_label)

	_canvas = MapCanvas.new()
	_canvas.tab = self
	_canvas.custom_minimum_size = Vector2(640, 440)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.focus_mode = Control.FOCUS_ALL
	_canvas.clip_contents = true
	var canvas_panel := _panel(_canvas)
	canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(canvas_panel)

	_controls_label = RichTextLabel.new()
	_controls_label.bbcode_enabled = true
	_controls_label.fit_content = true
	_controls_label.scroll_active = false
	_controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_label.add_theme_font_size_override("normal_font_size", CANVAS_HEADING_FONT_SIZE + 2)
	_controls_label.text = "%s Zoom Out    %s Zoom In    Right Stick  Pan" % [
		INPUT_GLYPH.icon("map_zoom_out", 24),
		INPUT_GLYPH.icon("map_zoom_in", 24),
	]
	add_child(_controls_label)

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
	_read_navigation_input()
	_follow_player_if_not_panned()

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

	var settling := _settle_frames_left > 0
	if settling:
		_settle_frames_left -= 1

	if revision_changed or moved or settling:
		_canvas.queue_redraw()
	if revision_changed:
		_last_map_revision = current_revision
		_update_legend(map_state)

	_update_header(map_state)


func _read_navigation_input() -> void:
	var changed := false
	if Input.is_action_just_pressed("map_zoom_in"):
		_zoom = _next_zoom_level(1)
		changed = true
	if Input.is_action_just_pressed("map_zoom_out"):
		_zoom = _next_zoom_level(-1)
		changed = true

	var pan_input := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if _zoom > MIN_ZOOM and pan_input.length_squared() > 0.01:
		_pan_world += pan_input * PAN_SPEED_MPS * get_process_delta_time() / _zoom
		_manual_pan = true # a deliberate pan owns the view until zoom resets to MIN_ZOOM
		changed = true

	if changed:
		_clamp_pan()
		_canvas.queue_redraw()


## OP21-15 fix: "zoom does not centre or scale around the player's location as
## expected." Every `poll()` this tab is shown, while zoomed in and the player
## has not deliberately panned elsewhere, snaps `_pan_world` to the player's
## own world offset from the map's centre — so a zoom press re-centres AND
## re-scales around wherever the player currently is (the whole point of a
## "you are here, zoom in" map), and simply walking around while zoomed keeps
## the player under the view without them ever touching the right stick.
## `_manual_pan` (set the instant the right stick actually moves the view,
## cleared the instant zoom returns to `MIN_ZOOM`) is what lets a player who
## deliberately panned elsewhere look at that other place without this
## dragging their view back to themselves every frame.
func _follow_player_if_not_panned() -> void:
	if _manual_pan or _zoom <= MIN_ZOOM:
		return
	var player := _player_node()
	if player == null:
		return
	var target := _pan_world_for_player(player.global_position)
	if target.distance_to(_pan_world) <= 0.01:
		return
	_pan_world = target
	_clamp_pan()
	_canvas.queue_redraw()


## The world-space offset (metres, same unit `_pan_world` is stored in) that
## puts `world_pos` at the centre of the map rectangle — i.e. the pan value
## `_world_to_canvas`/`_map_rect_for_canvas` need so that position renders at
## the panel's own centre. Independent of `_zoom`: `_pan_world` is a world-
## space quantity, not a screen-space one, so the same offset centres the
## player at any zoom level once `_map_rect_for_canvas` scales the rectangle
## around it.
func _pan_world_for_player(world_pos: Vector3) -> Vector2:
	var origin: Vector2 = MAP_STATE.origin()
	var span_x := float(MAP_STATE.CELL) * float(MAP_STATE.grid_x())
	var span_z := float(MAP_STATE.CELL) * float(MAP_STATE.grid_z())
	return Vector2(
		world_pos.x - (origin.x + span_x * 0.5),
		world_pos.z - (origin.y + span_z * 0.5),
	)


func _next_zoom_level(direction: int) -> float:
	var nearest := 0
	for index in ZOOM_LEVELS.size():
		if absf(ZOOM_LEVELS[index] - _zoom) < absf(ZOOM_LEVELS[nearest] - _zoom):
			nearest = index
	return ZOOM_LEVELS[clampi(nearest + direction, 0, ZOOM_LEVELS.size() - 1)]


func _clamp_pan() -> void:
	if _zoom <= MIN_ZOOM:
		_pan_world = Vector2.ZERO
		_manual_pan = false # whole-world fit has no "player" or "manual" focal point to remember
		return
	var span_x := float(MAP_STATE.CELL) * float(MAP_STATE.grid_x())
	var span_z := float(MAP_STATE.CELL) * float(MAP_STATE.grid_z())
	var canvas_size := _canvas.size if _canvas != null else Vector2(640.0, 440.0)
	var fit_scale := minf(canvas_size.x / span_x, canvas_size.y / span_z)
	var scale := fit_scale * _zoom
	var visible_span := canvas_size / maxf(scale, 0.001)
	# At low zoom the narrow X axis is wholly visible; allow the complete strip
	# to move between the panel edges, but never beyond them. Once an axis is
	# larger than the panel the same absolute difference is the normal cropped
	# world clamp.
	var max_pan_x := absf(span_x - visible_span.x) * 0.5
	if visible_span.x >= span_x:
		# Reposition the wholly visible strip enough to communicate panning,
		# without making a 300-frame controller hold crawl through thousands of
		# metres of empty side gutter before it reaches a stable clamp.
		max_pan_x = minf(max_pan_x, span_x * 0.45)
	var max_pan := Vector2(max_pan_x, absf(span_z - visible_span.y) * 0.5)
	_pan_world.x = clampf(_pan_world.x, -max_pan.x, max_pan.x)
	_pan_world.y = clampf(_pan_world.y, -max_pan.y, max_pan.y)


func _update_header(map_state: RefCounted) -> void:
	if _surveyed_label == null:
		return
	if map_state == null:
		_surveyed_label.text = "Surveyed: --"
		return
	var fraction: float = float(map_state.call("discovered_fraction"))
	var view_name := "Whole Meadows" if _zoom <= MIN_ZOOM else "%dx local view" % int(_zoom)
	_surveyed_label.text = "Surveyed: %d%%   •   %s" % [int(round(fraction * 100.0)), view_name]


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
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.text = label_text
	# OP21-15: see CANVAS_LABEL_FONT_SIZE's header — bumped past FONT_TINY.
	label.add_theme_font_size_override("font_size", CANVAS_HEADING_FONT_SIZE + 2)
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

	# Fit is an honest aspect-preserving overview. Zoom scales that same
	# north-up world rectangle and lets the canvas clip it into a local view.
	# Previously only the sampled source changed while the destination stayed
	# at its ~108px fit width, so even the "zoomed" frame was still a strip.
	var map_rect := _map_rect_for_canvas(rect_size)

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

	# Region name labels — only for regions the player has actually entered
	# (map_state.gd's own regions() doc: "a renderer needs the geometry for
	# both to decide that for itself"). Drawn after the fog/icon passes so the
	# text sits on top of both, same "text is the topmost layer" ordering the
	# legend row already uses.
	#
	# `placed_label_rects` is shared across every region drawn THIS frame.
	# The regions in map_landmarks.json today are spaced far enough apart
	# that this rarely has anything to do (owner playtest: a first cut named
	# the village square, Grandpa's house and the practice meadow as three
	# SEPARATE regions only 15-35m apart, which read as clutter; they are
	# now one "Grandpa's Village" region — see that file's own
	# `_comment_regions`). This stays as a backstop for whatever gets
	# authored later, not a fix for a design problem that still exists:
	# `_draw_region_label` nudges a label down past anything it collides
	# with rather than trusting that no two centres will ever land close.
	if _zoom <= MIN_ZOOM:
		_draw_overview_callouts(canvas, map_rect, map_state)
	else:
		# Labels share one occupied-rect list with visible markers. Previously
		# this list contained only older labels, so a region centred on its own
		# destination (notably The Tether Relay) printed directly through the
		# icon. Seeding the same deterministic nudge-down layout with the real
		# marker geometry resolves that overlap without special-casing a place.
		var placed_label_rects := _map_marker_exclusion_rects(canvas, map_rect, map_state)
		for region: Dictionary in (map_state.call("regions") as Array):
			if bool(region.get("discovered", false)):
				_draw_region_label(canvas, map_rect, region, placed_label_rects)

	var objective: Dictionary = map_state.call("objective_marker")
	if not objective.is_empty():
		# The player's OWN canvas point, computed here (world position, not yet
		# drawn) so `_draw_objective` can nudge the diamond clear of it before
		# `_draw_player` draws the marker itself on top a few lines below --
		# see `_draw_objective`'s own header for why the two would otherwise
		# collide at whole-Meadows fit.
		var player_point: Variant = null
		var player_for_clear := _player_node()
		if player_for_clear != null:
			player_point = _world_to_canvas(
				Vector2(player_for_clear.global_position.x, player_for_clear.global_position.z), map_rect)
		_draw_objective(canvas, map_rect, objective, player_point)

	if world != null:
		var player := _player_node()
		if player != null:
			_draw_player(canvas, map_rect, player.global_position, _facing_yaw(world, player))


## A 4:1 world cannot honestly fill a 16:9 panel at whole-world fit. The
## corridor therefore remains an undistorted strip, while its otherwise-empty
## side gutters carry spatial callouts connected to their true Z positions.
## This is overview-only: local zoom returns labels and icons to the terrain.
func _draw_overview_callouts(canvas: Control, map_rect: Rect2, map_state: RefCounted) -> void:
	if _region_font == null:
		_region_font = load(UITokens.FONT_PATH)
	if _region_font == null:
		return

	var regions: Array[Dictionary] = []
	for region: Dictionary in (map_state.call("regions") as Array):
		if not bool(region.get("discovered", false)):
			continue
		var point := _world_to_canvas(region.get("centre", Vector2.ZERO), map_rect)
		regions.append({"text": str(region.get("display_name", "")), "point": point, "desired_y": point.y})

	var destinations: Array[Dictionary] = []
	for entry: Dictionary in (map_state.call("landmarks") as Array):
		if bool(entry.get("dynamic", false)) or str(entry.get("category", "")) != "major":
			continue
		if not bool(entry.get("discovered", false)):
			continue
		var point := _world_to_canvas(entry.get("position", Vector2.ZERO), map_rect)
		destinations.append({
			"text": str(entry.get("display_name", "")),
			"icon": str(entry.get("icon", "")),
			"point": point,
			"desired_y": point.y,
		})

	_spread_callouts(regions, 42.0, canvas.size.y - 24.0)
	_spread_callouts(destinations, 42.0, canvas.size.y - 24.0)
	_draw_callout_heading(canvas, "DISCOVERED REGIONS", Rect2(18.0, 10.0, map_rect.position.x - 42.0, 24.0), HORIZONTAL_ALIGNMENT_RIGHT)
	_draw_callout_heading(canvas, "DESTINATIONS", Rect2(map_rect.end.x + 24.0, 10.0, canvas.size.x - map_rect.end.x - 42.0, 24.0), HORIZONTAL_ALIGNMENT_LEFT)
	for callout in regions:
		_draw_region_callout(canvas, map_rect, callout)
	for callout in destinations:
		_draw_destination_callout(canvas, map_rect, callout)


func _spread_callouts(entries: Array[Dictionary], top: float, bottom: float) -> void:
	if entries.is_empty():
		return
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.desired_y) < float(b.desired_y))
	const GAP := 38.0 # >= CANVAS_LABEL_FONT_SIZE's own line height, so bumped labels never touch
	var cursor := top
	for index in entries.size():
		var entry := entries[index]
		entry["label_y"] = maxf(float(entry.desired_y), cursor)
		entries[index] = entry
		cursor = float(entry.label_y) + GAP
	cursor = bottom
	for offset in entries.size():
		var index := entries.size() - 1 - offset
		var entry := entries[index]
		entry["label_y"] = minf(float(entry.label_y), cursor)
		entries[index] = entry
		cursor = float(entry.label_y) - GAP


## Every canvas-drawn label on this tab goes through here rather than a bare
## `draw_string` — see `CANVAS_HEADING_FONT_SIZE`'s header for why:
## `UITokens.make_text_legible()` only reaches `Label`/`RichTextLabel` nodes,
## and every string this file draws is a raw `_draw()` call over a busy,
## multi-coloured baked terrain texture, so it needs the SAME outline
## treatment applied by hand rather than going unplated.
func _draw_string_legible(canvas: Control, font: Font, baseline: Vector2, text: String, alignment: HorizontalAlignment, width: float, font_size: int, colour: Color) -> void:
	canvas.draw_string_outline(font, baseline, text, alignment, width, font_size, UITokens.OUTLINE_SIZE, UITokens.OUTLINE)
	canvas.draw_string(font, baseline, text, alignment, width, font_size, colour)


func _draw_callout_heading(canvas: Control, text: String, rect: Rect2, alignment: HorizontalAlignment) -> void:
	if rect.size.x <= 20.0:
		return
	var baseline := rect.position + Vector2(0.0, rect.size.y - _region_font.get_descent(CANVAS_HEADING_FONT_SIZE))
	_draw_string_legible(canvas, _region_font, baseline, text, alignment, rect.size.x, CANVAS_HEADING_FONT_SIZE, UITokens.TEXT_SECONDARY)


func _draw_region_callout(canvas: Control, map_rect: Rect2, callout: Dictionary) -> void:
	var point: Vector2 = callout.point
	var y := float(callout.label_y)
	var line_end := Vector2(map_rect.position.x - 18.0, y)
	var line_colour := UITokens.TEAL
	line_colour.a = 0.45
	canvas.draw_polyline(PackedVector2Array([point, Vector2(map_rect.position.x - 8.0, point.y), line_end]), line_colour, 1.5, true)
	canvas.draw_circle(point, 3.0, UITokens.TEAL)
	var label_rect := Rect2(18.0, y - 12.0, maxf(map_rect.position.x - 48.0, 20.0), 24.0)
	var baseline := label_rect.position + Vector2(0.0, label_rect.size.y - _region_font.get_descent(CANVAS_LABEL_FONT_SIZE))
	_draw_string_legible(canvas, _region_font, baseline, str(callout.text), HORIZONTAL_ALIGNMENT_RIGHT, label_rect.size.x, CANVAS_LABEL_FONT_SIZE, UITokens.TEXT_SECONDARY)


func _draw_destination_callout(canvas: Control, map_rect: Rect2, callout: Dictionary) -> void:
	var point: Vector2 = callout.point
	var y := float(callout.label_y)
	var line_end := Vector2(map_rect.end.x + 18.0, y)
	var line_colour := UITokens.WARNING
	line_colour.a = 0.45
	canvas.draw_polyline(PackedVector2Array([point, Vector2(map_rect.end.x + 8.0, point.y), line_end]), line_colour, 1.5, true)
	var icon := _icon_texture(str(callout.icon))
	var text_x := line_end.x + 8.0
	if icon != null:
		canvas.draw_texture_rect(icon, Rect2(text_x, y - 11.0, 22.0, 22.0), false)
		text_x += 30.0
	var label_width := maxf(canvas.size.x - text_x - 18.0, 20.0)
	var baseline := Vector2(text_x, y + 7.0)
	_draw_string_legible(canvas, _region_font, baseline, str(callout.text), HORIZONTAL_ALIGNMENT_LEFT, label_width, CANVAS_LABEL_FONT_SIZE, UITokens.TEXT_PRIMARY)


func _map_marker_exclusion_rects(canvas: Control, map_rect: Rect2, map_state: RefCounted) -> Array[Rect2]:
	var occupied: Array[Rect2] = []
	var viewport := Rect2(Vector2.ZERO, canvas.size)
	for entry: Dictionary in (map_state.call("landmarks") as Array):
		var visible := false
		if bool(entry.get("dynamic", false)):
			visible = str(entry.get("id", "")) != "objective"
		else:
			visible = bool(entry.get("discovered", false)) or bool(entry.get("silhouette", false))
		if not visible:
			continue
		var point := _world_to_canvas(entry.get("position", Vector2.ZERO), map_rect)
		var radius := _marker_size(entry) * 0.5 + 8.0
		var exclusion := Rect2(point - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		if viewport.intersects(exclusion):
			occupied.append(exclusion)

	var objective: Dictionary = map_state.call("objective_marker")
	if not objective.is_empty():
		var point := _world_to_canvas(objective.get("position", Vector2.ZERO), map_rect)
		var exclusion := Rect2(point - Vector2(17.0, 17.0), Vector2(34.0, 34.0))
		if viewport.intersects(exclusion):
			occupied.append(exclusion)

	var player := _player_node()
	if player != null:
		var point := _world_to_canvas(Vector2(player.global_position.x, player.global_position.z), map_rect)
		# Matches `_draw_player`'s own halo radius (`PLAYER_MARKER_RADIUS +
		# PLAYER_FACING_BASE + PLAYER_FACING_LENGTH + 4.0`) so a label never
		# lands on top of the bigger OP21-15 legibility halo.
		var player_radius := PLAYER_MARKER_RADIUS + PLAYER_FACING_BASE + PLAYER_FACING_LENGTH + 4.0
		var exclusion := Rect2(point - Vector2(player_radius, player_radius), Vector2(player_radius, player_radius) * 2.0)
		if viewport.intersects(exclusion):
			occupied.append(exclusion)
	return occupied


func _marker_size(entry: Dictionary) -> float:
	var category := str(entry.get("category", ""))
	if category == "major":
		return 38.0
	if category == "minor":
		return 26.0
	return ICON_SIZE


func _draw_icon(canvas: Control, map_rect: Rect2, entry: Dictionary, alpha: float) -> void:
	var icon_name := str(entry.get("icon", ""))
	if icon_name.is_empty():
		return
	var tex := _icon_texture(icon_name)
	if tex == null:
		return
	var pos: Vector2 = entry.get("position", Vector2.ZERO)
	var point := _world_to_canvas(pos, map_rect)
	var category := str(entry.get("category", ""))
	var marker_size := _marker_size(entry)
	var size := Vector2(marker_size, marker_size)
	var viewport := Rect2(Vector2.ZERO, canvas.size).grow(-marker_size * 0.5)
	if not viewport.has_point(point):
		return
	# OP21-15 blind pass: "two unlabeled dark-olive dots... nearly invisible
	# against the background." Only "major" landmarks got a dark backing
	# plate below their icon; minor landmarks (this is most of them —
	# discover_radius is small and there are more of them than there are
	# majors) drew the bare icon texture straight onto whatever terrain
	# colour happened to be underneath, and several of the vendored icons
	# (`assets/ui/icons/map/`) are themselves dark, low-saturation art that
	# a light meadow-green terrain swallows without a plate. Every discovered
	# landmark now gets one, sized down for minor/generic categories so a
	# major destination still reads as visually heavier on the map.
	var plate_scale := 0.58 if category == "major" else 0.48
	canvas.draw_circle(point, marker_size * plate_scale, Color(0.02, 0.03, 0.04, 0.72))
	canvas.draw_texture_rect(tex, Rect2(point - size * 0.5, size), false, Color(1, 1, 1, alpha))


## `player_point` is the player marker's own canvas position, or `null` when
## there is no player in this draw (a headless/menu-only context). OP21-15
## blind pass: "player marker and waypoint diamond overlap at default zoom —
## they collide corner-to-corner, producing a ~3mm cyan-and-gold smudge."
## `_draw_player`'s own legibility halo (drawn AFTER this, so it always wins
## the overlap) reaches `PLAYER_MARKER_RADIUS + PLAYER_FACING_BASE +
## PLAYER_FACING_LENGTH + 4` px out from the player -- at whole-Meadows fit
## that halo alone is wider than the entire visible map strip's short axis,
## so an objective anywhere near the player is guaranteed to land inside it.
## Nudging the diamond out to just past that halo (mirroring `minimap.gd`'s
## own `player_clear_position`/warning-line treatment for the same problem)
## keeps both markers individually readable instead of one erasing the other.
const PLAYER_CLEAR_RADIUS := PLAYER_MARKER_RADIUS + PLAYER_FACING_BASE + PLAYER_FACING_LENGTH + 4.0 + OBJECTIVE_RADIUS
func _draw_objective(canvas: Control, map_rect: Rect2, marker: Dictionary, player_point: Variant = null) -> void:
	var pos: Vector2 = marker.get("position", Vector2.ZERO)
	var true_point := _world_to_canvas(pos, map_rect)
	var point := true_point
	var nudged := false
	if player_point is Vector2:
		var offset := point - (player_point as Vector2)
		if offset.length() < PLAYER_CLEAR_RADIUS:
			var direction := offset.normalized() if offset.length_squared() > 0.001 else Vector2.UP
			point = (player_point as Vector2) + direction * PLAYER_CLEAR_RADIUS
			nudged = true
	var r := OBJECTIVE_RADIUS
	if not Rect2(Vector2.ZERO, canvas.size).grow(-r).has_point(point):
		return
	if nudged:
		var line_colour := UITokens.WARNING
		line_colour.a = 0.45
		canvas.draw_line(true_point, point, line_colour, 1.5)
	var points := PackedVector2Array([
		point + Vector2(0, -r), point + Vector2(r, 0), point + Vector2(0, r), point + Vector2(-r, 0),
	])
	canvas.draw_colored_polygon(points, UITokens.WARNING)
	canvas.draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
		UITokens.TEXT_PRIMARY, 1.5, true
	)


## Centred on the region's own centre point, same font UITokens hands every
## other HUD/menu text (`_font` caching mirrors `minimap.gd`'s own pattern —
## loaded once, reused every draw rather than re-loading a Resource per frame).
##
## `placed` is every label rect already drawn this frame — a backstop against
## whatever gets authored into map_landmarks.json later (see the call site's
## own comment), not a fix for today's regions, which are spaced apart on
## purpose. If this label's own rect would overlap a previously placed one,
## it drops to just below that other rect's own bottom edge and re-checks —
## bounded to a handful of tries so a pathological cluster degrades to
## "stacked but readable" rather than an infinite loop.
func _draw_region_label(canvas: Control, map_rect: Rect2, region: Dictionary, placed: Array[Rect2]) -> void:
	var rect := _resolved_region_label_rect(canvas, map_rect, region, placed)
	if rect.size == Vector2.ZERO:
		return
	placed.append(rect)
	var text := str(region.get("display_name", ""))
	var font_size := CANVAS_LABEL_FONT_SIZE
	var text_size := _region_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := rect.position + Vector2(0.0, text_size.y - _region_font.get_descent(font_size))
	_draw_string_legible(canvas, _region_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, UITokens.TEXT_PRIMARY)


## Returns the exact final text rect after collision avoidance. Kept separate
## from drawing so the controller smoke can prove that an icon-centred region
## cannot regress to printing through that icon again.
func _resolved_region_label_rect(canvas: Control, map_rect: Rect2, region: Dictionary, occupied: Array[Rect2]) -> Rect2:
	if _region_font == null:
		_region_font = load(UITokens.FONT_PATH)
	if _region_font == null:
		return Rect2()
	var text := str(region.get("display_name", ""))
	if text.is_empty():
		return Rect2()
	var point := _world_to_canvas(region.get("centre", Vector2.ZERO), map_rect)
	var font_size := CANVAS_LABEL_FONT_SIZE
	var text_size := _region_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)

	# PADDING is real breathing room, not the bare minimum that stops
	# `intersects()` from returning true. A confirmed render at PADDING=2
	# separated two labels by exactly enough that Rect2.intersects() called
	# it "clear" while the rendered text still read as visually cramped —
	# capital letters and glyph overshoot fill more of a font's own line
	# height than the tight box get_string_size() reports, so a hairline
	# geometric gap is not the same thing as a comfortable visual one.
	const PADDING := 8.0

	var top_left := point + Vector2(-text_size.x * 0.5, -text_size.y * 0.5)
	var rect := Rect2(top_left, text_size)
	var attempts := 0
	while attempts < 6:
		var collided := false
		for other in occupied:
			if rect.intersects(other):
				# Drop straight to just under THIS collider's own bottom edge,
				# not down by this label's own height -- two centres that are
				# only a few pixels apart in Y mean a same-size blind shift
				# can still leave the new top a few pixels inside the old
				# bottom. Anchoring to the actual collider geometry is what
				# guarantees real clearance regardless of how close the two
				# centres started.
				rect.position.y = other.position.y + other.size.y + PADDING
				collided = true
		if not collided:
			break
		attempts += 1
	if not Rect2(Vector2.ZERO, canvas.size).encloses(rect):
		return Rect2()
	return rect


## The player's dot, and which way they are facing.
##
## The owner's brief asks that a player be able to answer "which way am I
## facing?" from the map. The minimap conveys it by rotating the whole world
## under a fixed screen-up triangle; this screen is deliberately north-up
## (see this file's own header), so the world cannot rotate here and the
## marker has to carry the heading itself. It used to be a plain circle: a
## position with no heading at all.
##
## `yaw` is the CAMERA's planar yaw, the same value `playground_hud.gd` feeds
## `minimap.update_view` — so both screens answer the question the same way
## rather than one showing where the body points and the other where the view
## does.
##
## Direction math, from the project convention `forward(yaw) =
## Vector3(sin(yaw), 0, cos(yaw))` (`minimap.gd`'s header derives it): this
## map draws -Z up, so world +Z is canvas-down and world +X is canvas-right,
## giving `Vector2(sin(yaw), cos(yaw))` with no extra sign flips. Sanity check
## by hand: at `yaw = 0` forward is world south, and `(sin 0, cos 0) = (0, 1)`
## is canvas-down, which on a north-up map is south.
func _draw_player(canvas: Control, map_rect: Rect2, world_pos: Vector3, yaw: float) -> void:
	var point := _world_to_canvas(Vector2(world_pos.x, world_pos.z), map_rect)
	if not Rect2(Vector2.ZERO, canvas.size).grow(-(PLAYER_FACING_BASE + PLAYER_FACING_LENGTH)).has_point(point):
		return
	var forward := Vector2(sin(yaw), cos(yaw))
	var side := Vector2(-forward.y, forward.x)

	# The arrow sits wholly OUTSIDE the dot's ring rather than starting at the
	# centre. A first pass ran it from the middle and the ring cut straight
	# across it, so at map scale the two merged into one teal blob that showed
	# a position and no heading -- which was the entire point of adding it.
	var base := point + forward * PLAYER_FACING_BASE
	var tip := base + forward * PLAYER_FACING_LENGTH

	# OP21-15: a dark halo behind the whole marker (dot + ring + arrow) so it
	# reads against EVERY terrain colour it can land on, not just the darker
	# half of the height ramp — the pale-high ground `map_baker.gd` bakes at
	# the ramp's top end came closest to matching the cream ring outright.
	canvas.draw_circle(point, PLAYER_MARKER_RADIUS + PLAYER_FACING_BASE + PLAYER_FACING_LENGTH + 4.0, Color(UITokens.OUTLINE, 0.55))

	canvas.draw_colored_polygon(
		PackedVector2Array([
			tip,
			base + side * PLAYER_FACING_HALF_WIDTH,
			base - side * PLAYER_FACING_HALF_WIDTH,
		]),
		UITokens.TEAL
	)
	canvas.draw_circle(point, PLAYER_MARKER_RADIUS, UITokens.TEAL)
	canvas.draw_arc(point, PLAYER_MARKER_RADIUS + 3.0, 0.0, TAU, 20, UITokens.TEXT_PRIMARY, 2.5, true)


## The camera's planar yaw, derived exactly as `playground_hud.gd` derives it
## for the minimap. Falls back to the body's own yaw when no rig is reachable
## (a bare capture scene), and to 0.0 when there is no player either.
func _facing_yaw(world: Node, player: Node3D) -> float:
	if world != null:
		var rig := world.get_node_or_null(^"CameraRig")
		if rig != null and rig.has_method("planar_basis"):
			var basis: Basis = rig.call("planar_basis")
			return atan2(basis.z.x, basis.z.z)
	return player.global_rotation.y if player != null else 0.0


## World (x, z) -> a point inside `map_rect`, using the same grid `MapState`
## fogs (`MAP_STATE.CELL`/`grid_x()`/`grid_z()`/`origin()` — the const/static-
## func-on-a-preloaded-script read `tab_creatures.gd` already uses for
## `PARTY.MAX_CREATURES`), so a landmark and the fog cell under it can never
## drift apart. Separate spans per axis, not one shared square span — §8.6
## rejects the square assumption for the world itself, and `map_rect` is now
## letterboxed to the same non-square aspect (`_draw_map` above), so both
## sides of this mapping already agree the world need not be square. Zoom and
## pan are applied after that north-up fit, identically to the texture rect.
func _world_to_canvas(pos: Vector2, map_rect: Rect2) -> Vector2:
	var span_x: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_x())
	var span_z: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_z())
	var origin: Vector2 = MAP_STATE.origin()
	var nx: float = clampf((pos.x - origin.x) / span_x, 0.0, 1.0)
	var nz: float = clampf((pos.y - origin.y) / span_z, 0.0, 1.0)
	return map_rect.position + Vector2(nx * map_rect.size.x, nz * map_rect.size.y)


## The actual aspect-preserving world rectangle drawn by the canvas. At 1x
## it is the complete corridor. At larger scales it grows around the panel
## centre and `_pan_world` moves it under the fixed clipping viewport.
func _map_rect_for_canvas(canvas_size: Vector2) -> Rect2:
	var span := Vector2(
		float(MAP_STATE.CELL) * float(MAP_STATE.grid_x()),
		float(MAP_STATE.CELL) * float(MAP_STATE.grid_z()),
	)
	var fit_scale := minf(canvas_size.x / span.x, canvas_size.y / span.y)
	var scale := fit_scale * _zoom
	var size := span * scale
	var centre := canvas_size * 0.5 - _pan_world * scale
	return Rect2(centre - size * 0.5, size)


## Same two colours `scripts/ui/minimap.gd` fogs with (its own `FOG_UNDISCOVERED`/
## `FOG_DISCOVERED`) — copied rather than imported, since that file is a
## concurrent agent's and not this agent's to reach into, but D33 wants the
## two screens to read as one fog treatment and matching the colour costs
## nothing.
##
## OW3 / owner playtest: "the full map is rendered before I explore
## anything." A previous pass (see git blame) tuned this to 55% opacity so
## the terrain's colour/shape would show through dimly everywhere on the
## full map — but that IS "reveals everything automatically," just at
## reduced contrast instead of full brightness: spec §16 says the map "does
## not reveal everything automatically," not "reveals everything faintly."
## A player who has taken zero steps could already read the whole Meadows'
## shoreline, hills and road network off the menu. FULLY OPAQUE (alpha 1.0)
## now: unexplored cells hide the terrain underneath completely, so what
## shows on open is exactly what `MapState`'s fog grid says has been
## visited — nothing more. Kept the same near-black hue rather than
## switching to a parchment-style unexplored fill: this project's whole menu
## chrome is the dark blue-gray/teal panel language (`UITokens`, D28,
## `menu_tab.gd`'s own header), and introducing a second, warmer "unknown
## territory" material would be a new visual language for one screen, not a
## fog fix. Edges read soft, not blocky, for free: `ImageTexture` samples
## with linear filtering by default, and the grid is drawn scaled up from
## 128px to the panel's ~400+px side, so cell boundaries blend across a few
## screen pixels exactly the way `reveal_radius`'s circular reveal already
## implies they should.
const FOG_UNDISCOVERED := Color(0.02, 0.02, 0.03, 1.0)
const FOG_DISCOVERED := Color(0.0, 0.0, 0.0, 0.0)


## One `ImageTexture` baked from the fog grid rather than ~16k individual
## `draw_rect` calls — only REBUILT when `map_state.revision` actually moved,
## never unconditionally on every `_draw()`.
##
## THIS CACHE IS THE FIX FOR "the larger map in the menus shows nothing but
## black/white" (owner playtest report). Before it existed, this function ran
## fresh on every single redraw — every `poll()` while `_settle_frames_left`
## was still counting down, every player step, every revision bump — so it
## created a BRAND NEW `ImageTexture` far more often than `_terrain_texture()`
## below ever does (that one is memoized after its first call). A texture
## `ImageTexture.create_from_image()` just produced is not guaranteed visible
## to the SAME frame's draw commands on software (llvmpipe) rendering —
## exactly the race `_terrain_texture()`'s own header already documents — and
## it samples as opaque WHITE until the upload lands, not the transparent/
## near-black fog it is supposed to be. Redraws stop the instant
## `_settle_frames_left` reaches 0 and nothing else changed (a player standing
## still with a stable revision), so whichever frame's fresh fog texture last
## happened to land mid-race is what stays on screen forever after — proven
## by raising the settle-frame wait to 90 frames in `tools/capture_map_tab.gd`
## and seeing the exact same solid white square: more WAITING never helped
## because nothing was still triggering new REDRAWS by then, and every past
## redraw had rebuilt this same texture from scratch. Caching it the same way
## `_terrain_tex` already is (build once per real state change, not once per
## draw call) means there are only ever a handful of "brand new texture" frames
## over the tab's whole lifetime instead of one per redraw, and — just as
## importantly — a LATER redraw (there will always be at least a few more
## while `_settle_frames_left` counts down) has every chance to draw the
## SAME already-uploaded RID correctly instead of manufacturing a fresh race
## of its own on every attempt.
func _fog_texture(map_state: RefCounted) -> ImageTexture:
	var revision: int = int(map_state.get("revision"))
	if _fog_tex != null and revision == _fog_tex_revision:
		return _fog_tex

	var grid_x: int = int(map_state.call("cell_grid_x"))
	var grid_z: int = int(map_state.call("cell_grid_z"))
	if grid_x <= 0 or grid_z <= 0:
		return null
	var image := Image.create(grid_x, grid_z, false, Image.FORMAT_RGBA8)
	# Bulk-read the fog bitfield instead of calling `cell_at` per cell. Same
	# OP23-01 measurement as `minimap.gd`: over the corridor world's 1,048,576
	# cells the cross-object call was 735ms of an 837ms rebuild. The minimap
	# patches a dirty rect because it rebuilds while walking; this one only
	# rebuilds when the map tab is opened, so a full repaint is still the right
	# shape — it just must not cost most of a second to open the map.
	var visited: PackedByteArray = map_state.call("visited_bytes")
	for iz in grid_z:
		var row := iz * grid_x
		for ix in grid_x:
			image.set_pixel(ix, iz, FOG_DISCOVERED if visited[row + ix] == 1 else FOG_UNDISCOVERED)
	_fog_tex = ImageTexture.create_from_image(image)
	_fog_tex_revision = revision
	return _fog_tex


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
