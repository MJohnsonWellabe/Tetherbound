extends Control

## The minimap widget — `D33` / the owner's UI spec §6A. A rounded-square,
## player-up-rotated read of `Game.map` (`autoload/map_state.gd`, D33's one
## map database): a baked terrain texture (`scripts/world/map_baker.gd`)
## under a fog-of-war overlay, with landmark/objective/pal markers on top.
## Never a wild-pal radar (§6A.6) — nothing here ever reads a wild creature's
## position, and the only positions this file ever draws are whatever
## `Game.map` itself exposes.
##
## PLAYER-UP ROTATION — DERIVED, NOT GUESSED, per the task's own instruction.
## This project's yaw convention (used everywhere a facing direction is built
## from a yaw angle: `player_controller.gd`'s `atan2(direction.x,
## direction.z)`, `world_perimeter.gd`, `wild_pal.gd`, `encounter_director.gd`)
## is `forward(yaw) = Vector3(sin(yaw), 0, cos(yaw))`. `map_baker.gd` bakes a
## north-up texture: image column = world X, image row = world Z, so
## screen-up before any rotation is world -Z (north) and screen-right is
## world +X. Godot's `draw_set_transform(pos, rotation, scale)` rotates
## content using `Transform2D`'s own basis (`x_basis = (cos r, sin r)`,
## `y_basis = (-sin r, cos r)`); solving "what rotation `r` sends
## `forward(yaw)` to screen-up `(0,-1)`" gives **`r = yaw + PI`**. Sanity
## check by hand: at `yaw = 0`, `forward = (0,0,1)` = world south = screen-
## down pre-rotation; rotating the layer by `PI` (180°) brings it to
## screen-up, which is what a player facing south must show on a player-up
## map. At `yaw = PI/2`, `forward` = world +X = screen-right pre-rotation;
## rotating by `PI/2 + PI` also brings it to screen-up. The same `r` is used
## to place every marker (`_world_to_local`) so the map layer and its
## markers never disagree about where anything is. `tools/capture_minimap.gd`
## is the visual check this reasoning still owes itself — read this comment
## again before trusting a capture that looks wrong.
##
## CLIP APPROACH. Godot's immediate `_draw()` has no native rounded-rect
## clip. `clip_contents = true` gives a free rectangular clip to the
## Control's own bounds; on top of that, four quarter-disc wedges are drawn
## in `UITokens.BG_DEEP` directly over the square's own corners (after the
## terrain/fog/markers, before the frame ring) so the visible shape reads as
## rounded without any pixel actually being alpha-masked. Drawing the masks
## AFTER the markers is deliberate, not an oversight: it means a marker that
## strays into a corner is simply covered, the same way a real clip would
## hide it, with no extra distance math needed to keep markers off the
## corners in the first place.
##
## FOG TEXTURE. Rebuilt only when `Game.map`'s `revision` changes
## (`_last_fog_revision`), and reuses one `ImageTexture` via `update()`
## rather than allocating a new one every reveal — the grid is only 128×128,
## but there is no reason to churn GPU texture objects every time the player
## takes one more step into fogged ground.

const WORLD_HALF := 256.0 ## `terrain_playground.json`'s `world_size` 512, halved.
const MOVE_EPSILON := 0.05
const YAW_EPSILON := 0.01
const PAL_SHOW_DISTANCE := 15.0

const CORNER_RADIUS := 28.0
const RING_WIDTH := 8.0
const CORNER_STEPS := 10

const FOG_UNDISCOVERED := Color(0.02, 0.02, 0.03, 0.95)
const FOG_DISCOVERED := Color(0.0, 0.0, 0.0, 0.0)

var _map_state: RefCounted = null
var _terrain_texture: Texture2D = null
var _span_m: float = 90.0

var _player_pos: Vector3 = Vector3.ZERO
var _player_yaw: float = 0.0
var _pal_pos: Variant = null

var _fog_image: Image = null
var _fog_texture: ImageTexture = null
var _last_fog_revision: int = -1

var _font: Font = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 240)
	clip_contents = true
	_font = load(UITokens.FONT_PATH)


## `map_state` is `Game.map` (a `MapState`, see `autoload/map_state.gd`);
## `terrain` is a texture from `map_baker.gd::bake()`/`bake_cached()`.
func configure(map_state: RefCounted, terrain: Texture2D, span_m: float = 90.0) -> void:
	_map_state = map_state
	_terrain_texture = terrain
	_span_m = span_m
	_last_fog_revision = -1 # force the fog texture to rebuild on the next draw
	queue_redraw()


## Called once a frame by whatever owns the HUD. Cheap by design: redraw is
## only requested when the player actually moved/turned more than a tiny
## epsilon, the followed pal moved, or `map_state.revision` advanced — a
## stationary player standing still must not repaint every frame.
func update_view(player_pos: Vector3, player_yaw_rad: float, pal_pos: Variant = null) -> void:
	var moved := _player_pos.distance_to(player_pos) > MOVE_EPSILON
	var turned := absf(angle_difference(_player_yaw, player_yaw_rad)) > YAW_EPSILON
	var pal_changed := not _pal_equal(pal_pos)
	var revision_changed := _map_state != null and int(_map_state.revision) != _last_fog_revision

	_player_pos = player_pos
	_player_yaw = player_yaw_rad
	_pal_pos = pal_pos

	if moved or turned or pal_changed or revision_changed:
		queue_redraw()


## 0..1 exterior dim multiplier — combat pulls this to ~0.55, dialogue to
## ~0.4, so the minimap recedes without vanishing while something else has
## the player's attention. Applied via `modulate` so it costs nothing beyond
## the alpha blend the CanvasLayer is already doing.
func set_dim(dim: float) -> void:
	modulate = Color(1.0, 1.0, 1.0, clampf(dim, 0.0, 1.0))


func _pal_equal(new_pal: Variant) -> bool:
	if new_pal == null and _pal_pos == null:
		return true
	if new_pal == null or _pal_pos == null:
		return false
	return (new_pal as Vector3).distance_to(_pal_pos as Vector3) <= MOVE_EPSILON


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if _map_state != null and int(_map_state.revision) != _last_fog_revision:
		_rebuild_fog()

	var box := size
	var centre := box * 0.5
	var scale_px_per_m := box.x / maxf(_span_m, 0.001)
	var rotation := _player_yaw + PI # see the header comment for the derivation

	draw_rect(Rect2(Vector2.ZERO, box), UITokens.BG_DEEP, true)

	if _terrain_texture != null:
		_draw_map_layer(centre, scale_px_per_m, rotation)

	# Left with real headroom (not just enough for the diamond) so the
	# objective's distance label — anchored past the diamond, toward the rim
	# — has somewhere to sit without needing `_draw_upright_text`'s own
	# last-resort clamp to do all the work.
	var visible_radius := box.x * 0.5 - RING_WIDTH - 14.0
	_draw_landmarks(centre, scale_px_per_m)
	_draw_pal_marker(centre, scale_px_per_m)
	_draw_objective(centre, scale_px_per_m, visible_radius)

	_draw_corner_masks(box)
	_draw_frame(box)
	_draw_ticks_and_compass(centre, box)
	_draw_player_marker(centre)


func _draw_map_layer(centre: Vector2, scale_px_per_m: float, rotation: float) -> void:
	var half_span := _span_m * 0.5
	var dest := Rect2(Vector2(-half_span, -half_span), Vector2(_span_m, _span_m))

	draw_set_transform(centre, rotation, Vector2.ONE * scale_px_per_m)

	# The terrain texture is baked 1px/metre over the full ±256m world
	# (`map_baker.gd`), so the source region in texture pixels is the same
	# size in world metres as `_span_m`.
	var cx := _player_pos.x + WORLD_HALF
	var cz := _player_pos.z + WORLD_HALF
	var terrain_src := Rect2(cx - half_span, cz - half_span, _span_m, _span_m)
	draw_texture_rect_region(_terrain_texture, dest, terrain_src)

	if _fog_texture != null and _map_state != null:
		var grid := float(_map_state.cell_grid_size())
		var cell_m := (WORLD_HALF * 2.0) / maxf(grid, 1.0)
		var fog_src := Rect2((cx - half_span) / cell_m, (cz - half_span) / cell_m, _span_m / cell_m, _span_m / cell_m)
		draw_texture_rect_region(_fog_texture, dest, fog_src)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _rebuild_fog() -> void:
	if _map_state == null:
		return
	var grid: int = int(_map_state.cell_grid_size())
	if _fog_image == null or _fog_image.get_width() != grid:
		_fog_image = Image.create(grid, grid, false, Image.FORMAT_RGBA8)

	for iz in grid:
		for ix in grid:
			var discovered: bool = bool(_map_state.cell_at(ix, iz))
			_fog_image.set_pixel(ix, iz, FOG_DISCOVERED if discovered else FOG_UNDISCOVERED)

	if _fog_texture == null:
		_fog_texture = ImageTexture.create_from_image(_fog_image)
	else:
		_fog_texture.update(_fog_image)
	_last_fog_revision = int(_map_state.revision)


## World XZ -> local widget pixels, through the SAME rotation the map layer
## itself is drawn with, so a marker's screen position always agrees with
## the terrain underneath it.
func _world_to_local(world_pos: Vector3, centre: Vector2, scale_px_per_m: float) -> Vector2:
	var dx := world_pos.x - _player_pos.x
	var dz := world_pos.z - _player_pos.z
	var r := _player_yaw + PI
	var cr := cos(r)
	var sr := sin(r)
	var local_x := dx * cr - dz * sr
	var local_y := dx * sr + dz * cr
	return centre + Vector2(local_x, local_y) * scale_px_per_m


# --- markers -------------------------------------------------------------

func _draw_landmarks(centre: Vector2, scale_px_per_m: float) -> void:
	if _map_state == null:
		return
	for entry: Dictionary in _map_state.landmarks():
		var discovered: bool = bool(entry.get("discovered", false))
		var silhouette: bool = bool(entry.get("silhouette", false))
		if not discovered and not silhouette:
			continue # nothing to show at all yet — the common case, most landmarks

		var pos2: Vector2 = entry.get("position", Vector2.ZERO)
		var local := _world_to_local(Vector3(pos2.x, 0.0, pos2.y), centre, scale_px_per_m)
		var is_dynamic: bool = bool(entry.get("dynamic", false))

		if is_dynamic:
			# Camps and the like — muted cream, always discovered by
			# definition (map_state.gd's own contract: a dynamic marker would
			# not exist yet if it were not).
			_draw_dot(local, 6.0, Color(UITokens.BUILD_TEXT, 0.75))
		elif discovered:
			_draw_landmark_icon(local, str(entry.get("category", "minor")))
		else:
			# silhouette, not yet discovered: a "?" placeholder, spec §6A.4.
			_draw_upright_text(local, "?", UITokens.FONT_LABEL, UITokens.TEXT_MUTED)


func _draw_landmark_icon(local: Vector2, category: String) -> void:
	var major := category == "major"
	var r := 12.0 if major else 9.0
	if major:
		_draw_diamond(local, r, UITokens.TEXT_PRIMARY)
	else:
		draw_circle(local, r, UITokens.TEXT_PRIMARY)


func _draw_pal_marker(centre: Vector2, scale_px_per_m: float) -> void:
	if not (_pal_pos is Vector3):
		return
	var pal: Vector3 = _pal_pos
	if Vector2(pal.x, pal.z).distance_to(Vector2(_player_pos.x, _player_pos.z)) <= PAL_SHOW_DISTANCE:
		return # too close to the player to need its own marker
	var local := _world_to_local(pal, centre, scale_px_per_m)
	_draw_dot(local, 3.0, UITokens.TEAL_SOFT)


func _draw_objective(centre: Vector2, scale_px_per_m: float, visible_radius: float) -> void:
	if _map_state == null:
		return
	var objective: Dictionary = _map_state.objective_marker()
	if objective.is_empty():
		return

	var pos2: Vector2 = objective.get("position", Vector2.ZERO)
	var world_pos := Vector3(pos2.x, 0.0, pos2.y)
	var local := _world_to_local(world_pos, centre, scale_px_per_m)
	var offset := local - centre
	var clamped := false
	if offset.length() > visible_radius:
		offset = offset.normalized() * visible_radius
		local = centre + offset
		clamped = true

	_draw_diamond(local, 9.0, UITokens.WARNING)

	if clamped:
		var world_dist := Vector2(_player_pos.x, _player_pos.z).distance_to(pos2)
		var label := "◇ %d m" % int(round(world_dist))
		_draw_upright_text(local + offset.normalized() * 10.0, label, UITokens.FONT_TINY, UITokens.TEXT_PRIMARY)


# --- frame -----------------------------------------------------------------

func _draw_corner_masks(box: Vector2) -> void:
	var r := CORNER_RADIUS
	_draw_corner_wedge(Vector2(0.0, 0.0), Vector2(r, r), r, PI, PI * 1.5)
	_draw_corner_wedge(Vector2(box.x, 0.0), Vector2(box.x - r, r), r, PI * 1.5, TAU)
	_draw_corner_wedge(Vector2(box.x, box.y), Vector2(box.x - r, box.y - r), r, 0.0, PI * 0.5)
	_draw_corner_wedge(Vector2(0.0, box.y), Vector2(r, box.y - r), r, PI * 0.5, PI)


## `corner_point` is the square's own sharp corner; `circle_centre`/`r` are
## the rounding circle the frame ring is about to draw; the polygon fills
## exactly the sliver between the two, in the panel's own background colour,
## so the sharp square corner reads as rounded underneath the ring.
func _draw_corner_wedge(corner_point: Vector2, circle_centre: Vector2, r: float, from_angle: float, to_angle: float) -> void:
	var points := PackedVector2Array()
	points.append(corner_point)
	for i in CORNER_STEPS + 1:
		var t := lerpf(from_angle, to_angle, float(i) / float(CORNER_STEPS))
		points.append(circle_centre + Vector2(cos(t), sin(t)) * r)
	draw_colored_polygon(points, UITokens.BG_DEEP)


func _draw_frame(box: Vector2) -> void:
	var rect := Rect2(Vector2.ZERO, box)

	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	ring.border_color = Color(UITokens.BG_DEEP, 0.88)
	ring.set_border_width_all(int(RING_WIDTH))
	ring.set_corner_radius_all(int(CORNER_RADIUS))
	draw_style_box(ring, rect)

	var accent := StyleBoxFlat.new()
	accent.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	accent.border_color = UITokens.TEAL
	accent.set_border_width_all(UITokens.EDGE)
	accent.set_corner_radius_all(int(maxf(CORNER_RADIUS - RING_WIDTH, 0.0)))
	draw_style_box(accent, rect.grow(-RING_WIDTH))

	# Four tether-notch node dots at the diagonal corners of the ring.
	var notch_radius := box.x * 0.5 - RING_WIDTH * 0.5
	var centre := box * 0.5
	for angle in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
		var notch := centre + Vector2(cos(angle), sin(angle)) * notch_radius
		draw_circle(notch, 2.5, UITokens.TEAL) # 5px dot


func _draw_ticks_and_compass(centre: Vector2, box: Vector2) -> void:
	var tick_radius := box.x * 0.5 - RING_WIDTH
	var tick_length := 6.0
	for angle in [PI * 1.5, 0.0, PI * 0.5, PI]: # top, right, bottom, left rim positions
		var dir := Vector2(cos(angle), sin(angle))
		var outer := centre + dir * tick_radius
		var inner := centre + dir * (tick_radius - tick_length)
		draw_line(inner, outer, Color(UITokens.TEXT_SECONDARY, 0.7), 2.0)

	# The "N" glyph tracks world north around the rim as the map rotates
	# beneath it (header comment has the derivation of `north_dir`); the
	# glyph itself is drawn upright — only its POSITION rotates.
	var north_dir := Vector2(-sin(_player_yaw), cos(_player_yaw))
	var north_pos := centre + north_dir * (tick_radius - 2.0)
	_draw_upright_text(north_pos, "N", UITokens.FONT_TINY, UITokens.TEXT_PRIMARY)


## The player's own arrow, always pointing straight up — a player-up map
## keeps the player centred and facing forward by definition, so this never
## needs to rotate; only the world beneath it does.
func _draw_player_marker(centre: Vector2) -> void:
	var size := 12.0 # ~22px tip-to-base triangle
	var points := PackedVector2Array([
		centre + Vector2(0.0, -size),
		centre + Vector2(size * 0.62, size * 0.75),
		centre + Vector2(-size * 0.62, size * 0.75),
	])
	draw_colored_polygon(points, UITokens.TEAL)
	# a small cream tip so the arrow reads at a glance against dark ground
	var tip := PackedVector2Array([
		centre + Vector2(0.0, -size),
		centre + Vector2(size * 0.28, -size * 0.15),
		centre + Vector2(-size * 0.28, -size * 0.15),
	])
	draw_colored_polygon(tip, UITokens.TEXT_PRIMARY)


# --- primitive helpers -------------------------------------------------------

func _draw_diamond(centre: Vector2, r: float, colour: Color) -> void:
	var points := PackedVector2Array([
		centre + Vector2(0.0, -r),
		centre + Vector2(r, 0.0),
		centre + Vector2(0.0, r),
		centre + Vector2(-r, 0.0),
	])
	draw_colored_polygon(points, colour)


func _draw_dot(centre: Vector2, r: float, colour: Color) -> void:
	draw_circle(centre, r, colour)


## Every text draw goes through here, with the transform already back at
## identity by the time it is called (`_draw()` resets it right after the
## rotated map-layer blit) — spec's own rule, "all text upright": positions
## are computed under the map's rotation, glyphs never are.
##
## The requested `centre` is a WISH, not a guarantee: a rim-clamped label
## near a corner can still ask for a spot whose own text half-width would
## carry it past the widget's edge (a capture caught exactly this — the
## objective's distance label reading as a clipped "7 m" with its leading
## digits gone, `clip_contents` silently eating whatever crossed the
## boundary). So the final baseline is clamped inside the widget's own
## `size` after the text's real dimensions are known, rather than trusting
## the caller's radial math to have left enough room in every direction.
func _draw_upright_text(centre: Vector2, text: String, font_size: int, colour: Color) -> void:
	if _font == null:
		return
	const MARGIN := 3.0
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var top_left := centre - text_size * 0.5
	top_left.x = clampf(top_left.x, MARGIN, maxf(MARGIN, size.x - text_size.x - MARGIN))
	top_left.y = clampf(top_left.y, MARGIN, maxf(MARGIN, size.y - text_size.y - MARGIN))
	var baseline := top_left + Vector2(0.0, text_size.y - _font.get_descent(font_size))
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, colour)
