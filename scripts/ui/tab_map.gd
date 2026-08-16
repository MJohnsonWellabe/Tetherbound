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
## FIXED VIEW, NO PAN/ZOOM (v1). `MapState`'s grid is today 128 cells at 4m —
## 512x512m, derived from `terrain_playground.json` rather than hard-coded
## (`docs/MEADOWS_MACRO_LAYOUT.md` §8.6) — and every landmark in
## `data/config/map_landmarks.json` sits well inside that box: the whole
## Meadows already fits one screen at a glance, so fitting the world to the
## panel is not a corner cut, it is the actual right answer for a biome this
## size. THIS STOPS BEING TRUE the day the corridor world lands (`D50`:
## 8192x2048m) — an un-panned, un-zoomed view of a world that long reduces
## every landmark to a sliver of pixels, which is exactly why pan/zoom is
## real, not-yet-built future work rather than a permanently deferred one;
## nothing here tries to solve that today. Free pan/zoom was considered and set aside
## for a real reason, not laziness: every existing in-menu directional read
## (`tab_backpack.gd`, `tab_creatures.gd`) rides Godot's `ui_*` focus-navigation
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
## `tab_creatures.gd` uses for HP bars that update without ever rebuilding rows.

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
## The facing arrow, in pixels: where its base sits (just clear of the dot's
## cream ring, which is drawn at `PLAYER_MARKER_RADIUS + 3`), how far past that
## the tip reaches, and how wide the base is. Long enough to read as a heading
## at a glance on a handheld, short enough not to be mistaken for a route line
## to something. TUNABLE.
const PLAYER_FACING_BASE := 10.0
const PLAYER_FACING_LENGTH := 10.0
const PLAYER_FACING_HALF_WIDTH := 6.0
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

	var settling := _settle_frames_left > 0
	if settling:
		_settle_frames_left -= 1

	if revision_changed or moved or settling:
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

	# Letterbox to a centered rect matching the WORLD's own aspect ratio, not
	# a bare square — stretching x/y independently would visibly warp the
	# landmark layout relative to the terrain bake beneath it, and that ratio
	# is only 1:1 (a square) because today's world happens to be square. The
	# aspect is read from `MapState`'s own derived grid (`docs/MEADOWS_MACRO_
	# LAYOUT.md` §8.6), so this stops assuming a square the moment the world
	# does.
	var world_span_x: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_x())
	var world_span_z: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_z())
	var aspect: float = world_span_x / maxf(world_span_z, 0.001)

	var map_size: Vector2
	if rect_size.x / maxf(rect_size.y, 0.001) > aspect:
		map_size = Vector2(rect_size.y * aspect, rect_size.y) # panel wider than the world: height-constrained
	else:
		map_size = Vector2(rect_size.x, rect_size.x / aspect) # panel taller than the world: width-constrained
	var map_origin := Vector2((rect_size.x - map_size.x) * 0.5, (rect_size.y - map_size.y) * 0.5)
	var map_rect := Rect2(map_origin, map_size)

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
	var placed_label_rects: Array[Rect2] = []
	for region: Dictionary in (map_state.call("regions") as Array):
		if bool(region.get("discovered", false)):
			_draw_region_label(canvas, map_rect, region, placed_label_rects)

	var objective: Dictionary = map_state.call("objective_marker")
	if not objective.is_empty():
		_draw_objective(canvas, map_rect, objective)

	if world != null:
		var player := _player_node()
		if player != null:
			_draw_player(canvas, map_rect, player.global_position, _facing_yaw(world, player))


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
	if _region_font == null:
		_region_font = load(UITokens.FONT_PATH)
	if _region_font == null:
		return
	var text := str(region.get("display_name", ""))
	if text.is_empty():
		return
	var point := _world_to_canvas(region.get("centre", Vector2.ZERO), map_rect)
	var font_size := UITokens.FONT_LABEL
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
		for other in placed:
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
	placed.append(rect)

	var baseline := rect.position + Vector2(0.0, text_size.y - _region_font.get_descent(font_size))
	canvas.draw_string(_region_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, UITokens.TEXT_PRIMARY)


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
	var forward := Vector2(sin(yaw), cos(yaw))
	var side := Vector2(-forward.y, forward.x)

	# The arrow sits wholly OUTSIDE the dot's ring rather than starting at the
	# centre. A first pass ran it from the middle and the ring cut straight
	# across it, so at map scale the two merged into one teal blob that showed
	# a position and no heading -- which was the entire point of adding it.
	var base := point + forward * PLAYER_FACING_BASE
	var tip := base + forward * PLAYER_FACING_LENGTH
	canvas.draw_colored_polygon(
		PackedVector2Array([
			tip,
			base + side * PLAYER_FACING_HALF_WIDTH,
			base - side * PLAYER_FACING_HALF_WIDTH,
		]),
		UITokens.TEAL
	)
	canvas.draw_circle(point, PLAYER_MARKER_RADIUS, UITokens.TEAL)
	canvas.draw_arc(point, PLAYER_MARKER_RADIUS + 3.0, 0.0, TAU, 16, UITokens.TEXT_PRIMARY, 1.5, true)


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
## sides of this mapping already agree the world need not be square.
func _world_to_canvas(pos: Vector2, map_rect: Rect2) -> Vector2:
	var span_x: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_x())
	var span_z: float = float(MAP_STATE.CELL) * float(MAP_STATE.grid_z())
	var origin: Vector2 = MAP_STATE.origin()
	var nx: float = clampf((pos.x - origin.x) / span_x, 0.0, 1.0)
	var nz: float = clampf((pos.y - origin.y) / span_z, 0.0, 1.0)
	return map_rect.position + Vector2(nx * map_rect.size.x, nz * map_rect.size.y)


## Same two colours `scripts/ui/minimap.gd` fogs with (its own `FOG_UNDISCOVERED`/
## `FOG_DISCOVERED`) — copied rather than imported, since that file is a
## concurrent agent's and not this agent's to reach into, but D33 wants the
## two screens to read as one fog treatment and matching the colour costs
## nothing.
##
## OWNER PLAYTEST REPORT: "the larger map in the menus shows nothing but
## black." Root cause: this is genuinely correct fog-of-war behaviour, just
## tuned for the wrong SCREEN. The world is 512x512m; a day-1 player has
## typically explored a couple hundred metres around the house/village --
## under 10% of the grid -- and the minimap this alpha was copied from only
## ever shows a ~90m window centred on the player (mostly already-revealed
## ground by definition), so 95% opacity read as reasonable there. Stretched
## over the FULL map's whole-world view, that same 95% opacity black is
## correct at covering >90% of the panel in solid near-black, which is
## exactly what "shows nothing but black" describes -- not a rendering bug,
## a fog treatment that never got re-judged at the full map's own scale.
## Dropped to 55%: still clearly reads as unexplored/fogged (a real
## incentive to go look), but the terrain's own colour and shape now show
## through dimly everywhere, so a player opening the map for the first time
## sees the whole Meadows' silhouette immediately instead of a blob of
## colour in a black void.
const FOG_UNDISCOVERED := Color(0.02, 0.02, 0.03, 0.55)
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
	for iz in grid_z:
		for ix in grid_x:
			var discovered: bool = bool(map_state.call("cell_at", ix, iz))
			image.set_pixel(ix, iz, FOG_DISCOVERED if discovered else FOG_UNDISCOVERED)
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
