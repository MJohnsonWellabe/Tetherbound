extends Control

## The minimap widget — `D33` / the owner's UI spec §6A. A rounded-square,
## player-up-rotated read of `Game.map` (`autoload/map_state.gd`, D33's one
## map database): a baked terrain texture (`scripts/world/map_baker.gd`)
## under a fog-of-war overlay, with landmark/objective/creature markers on top.
## Never a wild-creature radar (§6A.6) — nothing here ever reads a wild creature's
## position, and the only positions this file ever draws are whatever
## `Game.map` itself exposes.
##
## MOVEMENT-UP ROTATION — DERIVED, NOT GUESSED, per the task's own instruction.
## This project's yaw convention (used everywhere a facing direction is built
## from a yaw angle: `player_controller.gd`'s `atan2(direction.x,
## direction.z)`, `world_perimeter.gd`, `wild_creature.gd`, `encounter_director.gd`)
## is `forward(yaw) = Vector3(sin(yaw), 0, cos(yaw))`. `map_baker.gd` bakes a
## north-up texture: image column = world X, image row = world Z, so
## screen-up before any rotation is world -Z (north) and screen-right is
## world +X. Godot's `draw_set_transform(pos, rotation, scale)` rotates
## content using `Transform2D`'s own basis (`x_basis = (cos r, sin r)`,
## `y_basis = (-sin r, cos r)`); solving "what rotation `r` sends
## `forward(yaw)` to screen-up `(0,-1)`" gives **`r = yaw + PI`**. Here yaw
## is the last meaningful ACTUAL horizontal displacement, not camera yaw. Sanity
## check by hand: at `yaw = 0`, `forward = (0,0,1)` = world south = screen-
## down pre-rotation; rotating the layer by `PI` (180°) brings it to
## screen-up, which is what a player facing south must show on a player-up
## map. At `yaw = PI/2`, `forward` = world +X = screen-right pre-rotation;
## rotating by `PI/2 + PI` also brings it to screen-up. The same `r` is used
## to place every marker (`_world_to_local`) so the map layer and its markers
## never disagree about where anything is. The centred triangle rotates from
## look yaw relative to movement yaw: travel stays up while its tip answers
## where the camera is looking. Stationary orbit retains the last travel yaw.
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
## rather than allocating a new one every reveal — the grid is small (today
## 128×128, `autoload/map_state.gd`'s `grid_x()`/`grid_z()`), but there is no
## reason to churn GPU texture objects every time the player takes one more
## step into fogged ground.

const WORLD_EXTENT := preload("res://scripts/world/world_extent.gd")
const MOVE_EPSILON := 0.05
const YAW_EPSILON := 0.01
const CREATURE_SHOW_DISTANCE := 15.0

const CORNER_RADIUS := 28.0
const RING_WIDTH := 8.0
const CORNER_STEPS := 10
const OBJECTIVE_LABEL_PUSH := 10.0 ## px the distance label sits past the clamped diamond, toward the rim.
const PLAYER_MARKER_CLEAR_RADIUS := 34.0 # bumped alongside the player marker's own enlargement below
const MARKER_SEPARATION := 22.0

## OW3: was 0.95 — 5% show-through, which stacked with this widget's already
## tight ~90m span meant unexplored ground at the rim read as dim terrain
## rather than hidden fog. Bumped to fully opaque (1.0) to match `tab_map.gd`'s
## own OW3 fix and actually satisfy spec §16 ("does not reveal everything
## automatically") rather than merely approximate it. See that file's header
## comment for why the colour stays near-black rather than becoming a
## parchment-style fill.
const FOG_UNDISCOVERED := Color(0.02, 0.02, 0.03, 1.0)
const FOG_DISCOVERED := Color(0.0, 0.0, 0.0, 0.0)

var _map_state: RefCounted = null
var _terrain_texture: Texture2D = null
var _span_m: float = 90.0

## Cached once at construction, not re-read per draw call — `_draw()` runs
## every frame the minimap redraws and the world's bounds do not change
## mid-session.
var _world_min := Vector2.ZERO
var _world_max := Vector2.ZERO

var _player_pos: Vector3 = Vector3.ZERO
var _movement_yaw: float = 0.0
var _look_yaw: float = 0.0
var _has_player_sample: bool = false
var _creature_pos: Variant = null

var _fog_image: Image = null
var _fog_texture: ImageTexture = null
var _last_fog_revision: int = -1

var _font: Font = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 240)
	clip_contents = true
	_font = load(UITokens.FONT_PATH)
	var bounds: Dictionary = WORLD_EXTENT.bounds()
	_world_min = Vector2(float(bounds.get("min_x", 0.0)), float(bounds.get("min_z", 0.0)))
	_world_max = Vector2(float(bounds.get("max_x", 0.0)), float(bounds.get("max_z", 0.0)))


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
## epsilon, the followed creature moved, or `map_state.revision` advanced — a
## stationary player standing still must not repaint every frame.
func update_view(player_pos: Vector3, look_yaw_rad: float, creature_pos: Variant = null) -> void:
	var displacement := Vector2(player_pos.x - _player_pos.x, player_pos.z - _player_pos.z)
	var moved := _has_player_sample and displacement.length() > MOVE_EPSILON
	var movement_turned := false
	if moved:
		var next_movement_yaw := atan2(displacement.x, displacement.y)
		movement_turned = absf(angle_difference(_movement_yaw, next_movement_yaw)) > YAW_EPSILON
		_movement_yaw = next_movement_yaw
	elif not _has_player_sample:
		# There is no travel direction before the first step. Start from look so
		# the map does not arbitrarily snap north, then let real motion own it.
		_movement_yaw = look_yaw_rad
	var look_turned := absf(angle_difference(_look_yaw, look_yaw_rad)) > YAW_EPSILON
	var creature_changed := not _creature_equal(creature_pos)
	var revision_changed := _map_state != null and int(_map_state.revision) != _last_fog_revision

	_player_pos = player_pos
	_look_yaw = look_yaw_rad
	_has_player_sample = true
	_creature_pos = creature_pos

	if moved or movement_turned or look_turned or creature_changed or revision_changed:
		queue_redraw()


## 0..1 exterior dim multiplier — combat pulls this to ~0.55, dialogue to
## ~0.4, so the minimap recedes without vanishing while something else has
## the player's attention. Applied via `modulate` so it costs nothing beyond
## the alpha blend the CanvasLayer is already doing.
func set_dim(dim: float) -> void:
	modulate = Color(1.0, 1.0, 1.0, clampf(dim, 0.0, 1.0))


func _creature_equal(new_creature: Variant) -> bool:
	if new_creature == null and _creature_pos == null:
		return true
	if new_creature == null or _creature_pos == null:
		return false
	return (new_creature as Vector3).distance_to(_creature_pos as Vector3) <= MOVE_EPSILON


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if _map_state != null and int(_map_state.revision) != _last_fog_revision:
		_rebuild_fog()

	var box := size
	var centre := box * 0.5
	var scale_px_per_m := box.x / maxf(_span_m, 0.001)
	var rotation := _movement_yaw + PI # see the header comment for the derivation

	draw_rect(Rect2(Vector2.ZERO, box), UITokens.BG_DEEP, true)

	if _terrain_texture != null:
		_draw_map_layer(centre, scale_px_per_m, rotation)

	# Left with real headroom (not just enough for the diamond) so the
	# objective's distance label — anchored past the diamond, toward the rim
	# — has somewhere to sit without needing `_draw_upright_text`'s own
	# last-resort clamp to do all the work.
	#
	# Also capped by `corner_safe_radius`: the corner masks (`_draw_corner_
	# masks`) are painted AFTER markers/text, specifically so anything that
	# strays into a rounded corner gets covered — but they are only ~90%
	# opaque (`UITokens.BG_DEEP`'s own alpha), so a label caught under one
	# **BUG WAS HERE** (real root cause, not a rotated/mirrored draw): the
	# label sits `OBJECTIVE_LABEL_PUSH` px further out than the diamond's own
	# clamp radius, and the old `box.x*0.5 - RING_WIDTH - 14.0` (98px on a
	# 240px widget) plus that push (108px) exceeded the wedge's own closest-
	# approach distance (~102px) whenever the objective sat near a diagonal —
	# the label landed *inside* the wedge and was mostly erased, leaving a
	# faint fragment-soup of remaining glyph edges. That is what a reviewer
	# eyeballing a shrunk contact-sheet thumbnail read as "garbled sideways
	# text" ("esn m r2e"): every glyph WAS drawn upright at identity
	# transform (confirmed — `_draw_upright_text` is only ever called after
	# `_draw_map_layer` resets the transform to identity), it was just ~90%
	# painted over by the corner mask right after. Capping the radius here
	# keeps the diamond *and* its label's full push clear of every corner's
	# wedge, for any objective angle, not just the diagonal this capture
	# happened to hit.
	var corner_safe_radius := sqrt(2.0) * (box.x * 0.5 - CORNER_RADIUS) - CORNER_RADIUS
	var visible_radius := minf(
		box.x * 0.5 - RING_WIDTH - 14.0,
		corner_safe_radius - OBJECTIVE_LABEL_PUSH - 20.0 # 20px: label's own half-extent
	)
	var objective_position: Variant = _objective_display_position(centre, scale_px_per_m, visible_radius)
	_draw_landmarks(centre, scale_px_per_m, objective_position)
	_draw_creature_marker(centre, scale_px_per_m, objective_position)
	_draw_objective(centre, scale_px_per_m, visible_radius)

	_draw_corner_masks(box)
	_draw_frame(box)
	_draw_ticks_and_compass(centre, box)
	_draw_player_marker(centre)


func _draw_map_layer(centre: Vector2, scale_px_per_m: float, rotation: float) -> void:
	# A rotated square only covers the widget at 0/90-degree headings; at every
	# diagonal the old 90m layer exposed large black triangles in its corners.
	# Draw the square's diagonal instead. Scale remains px/metre, so the visible
	# inscribed 90m window and all marker math stay unchanged.
	var draw_span := map_layer_draw_span(_span_m)
	var half_draw_span := draw_span * 0.5
	var dest := Rect2(Vector2(-half_draw_span, -half_draw_span), Vector2(draw_span, draw_span))

	draw_set_transform(centre, rotation, Vector2.ONE * scale_px_per_m)

	# Source coordinates are texture pixels, not metres. The corridor is four
	# times longer than it is wide and the shared bake is rectangular, so each
	# axis must use its own world-to-texture scale. The old px==metres shortcut
	# sampled outside the 512px texture around the village and reduced a 90m
	# north/south view to roughly six useful pixels.
	var terrain_src := terrain_source_region(
		Vector2(_player_pos.x, _player_pos.z), draw_span,
		Vector2(_terrain_texture.get_width(), _terrain_texture.get_height()),
		{"min_x": _world_min.x, "min_z": _world_min.y, "max_x": _world_max.x, "max_z": _world_max.y})
	draw_texture_rect_region(_terrain_texture, dest, terrain_src)

	if _fog_texture != null and _map_state != null:
		# `cell_m` is the fog grid's actual cell size, read from `MapState`
		# directly rather than re-derived from a world span and cell count —
		# that derivation only happened to work while the grid was square and
		# `CELL` was never anything but "world span / grid count".
		var cell_m := maxf(float(_map_state.cell_size()), 0.001)
		var cx := _player_pos.x - _world_min.x
		var cz := _player_pos.z - _world_min.y
		var fog_src := Rect2((cx - half_draw_span) / cell_m, (cz - half_draw_span) / cell_m, draw_span / cell_m, draw_span / cell_m)
		draw_texture_rect_region(_fog_texture, dest, fog_src)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Converts a square local world window to the rectangular shared bake. Kept
## pure so the corridor aspect contract is regression-testable without a
## rendered screenshot.
static func terrain_source_region(world_centre: Vector2, span_m: float, texture_size: Vector2, bounds: Dictionary) -> Rect2:
	var world_min := Vector2(float(bounds.get("min_x", 0.0)), float(bounds.get("min_z", 0.0)))
	var world_size := Vector2(
		maxf(float(bounds.get("max_x", 0.0)) - world_min.x, 0.001),
		maxf(float(bounds.get("max_z", 0.0)) - world_min.y, 0.001))
	var pixels_per_metre := texture_size / world_size
	var half := Vector2.ONE * span_m * 0.5
	return Rect2((world_centre - half - world_min) * pixels_per_metre, Vector2.ONE * span_m * pixels_per_metre)


func _rebuild_fog() -> void:
	if _map_state == null:
		return
	var grid_x: int = int(_map_state.cell_grid_x())
	var grid_z: int = int(_map_state.cell_grid_z())
	if _fog_image == null or _fog_image.get_width() != grid_x or _fog_image.get_height() != grid_z:
		_fog_image = Image.create(grid_x, grid_z, false, Image.FORMAT_RGBA8)

	for iz in grid_z:
		for ix in grid_x:
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
	var r := _movement_yaw + PI
	var cr := cos(r)
	var sr := sin(r)
	var local_x := dx * cr - dz * sr
	var local_y := dx * sr + dz * cr
	return centre + Vector2(local_x, local_y) * scale_px_per_m


# --- markers -------------------------------------------------------------

func _draw_landmarks(centre: Vector2, scale_px_per_m: float, objective_position: Variant) -> void:
	if _map_state == null:
		return
	var occupied: Array[Vector2] = []
	for entry: Dictionary in _map_state.landmarks():
		var discovered: bool = bool(entry.get("discovered", false))
		var silhouette: bool = bool(entry.get("silhouette", false))
		if not discovered and not silhouette:
			continue # nothing to show at all yet — the common case, most landmarks

		var pos2: Vector2 = entry.get("position", Vector2.ZERO)
		var local := _world_to_local(Vector3(pos2.x, 0.0, pos2.y), centre, scale_px_per_m)
		# Player > objective > landmark. A location still exists in shared map
		# data, but its lower-priority icon yields when the local view stacks it
		# under the centred player or tracked objective.
		if local.distance_to(centre) < PLAYER_MARKER_CLEAR_RADIUS:
			continue
		if objective_position is Vector2 and local.distance_to(objective_position as Vector2) < MARKER_SEPARATION:
			continue
		var overlaps_landmark := false
		for used in occupied:
			if local.distance_to(used) < MARKER_SEPARATION:
				overlaps_landmark = true
				break
		if overlaps_landmark:
			continue
		occupied.append(local)
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


func _draw_creature_marker(centre: Vector2, scale_px_per_m: float, objective_position: Variant) -> void:
	if not (_creature_pos is Vector3):
		return
	var creature: Vector3 = _creature_pos
	if Vector2(creature.x, creature.z).distance_to(Vector2(_player_pos.x, _player_pos.z)) <= CREATURE_SHOW_DISTANCE:
		return # too close to the player to need its own marker
	var local := _world_to_local(creature, centre, scale_px_per_m)
	if objective_position is Vector2 and local.distance_to(objective_position as Vector2) < MARKER_SEPARATION:
		return
	_draw_dot(local, 3.0, UITokens.TEAL_SOFT)


func _draw_objective(centre: Vector2, scale_px_per_m: float, visible_radius: float) -> void:
	if _map_state == null:
		return
	var objective: Dictionary = _map_state.objective_marker()
	if objective.is_empty():
		return

	var pos2: Vector2 = objective.get("position", Vector2.ZERO)
	var world_pos := Vector3(pos2.x, 0.0, pos2.y)
	var true_local := _world_to_local(world_pos, centre, scale_px_per_m)
	var local := true_local
	var offset := local - centre
	var clamped := false
	if offset.length() > visible_radius:
		offset = offset.normalized() * visible_radius
		local = centre + offset
		clamped = true
	elif offset.length() < PLAYER_MARKER_CLEAR_RADIUS:
		local = player_clear_position(local, centre)
		draw_line(true_local, local, Color(UITokens.WARNING, 0.45), 1.5)

	_draw_diamond(local, 9.0, UITokens.WARNING)

	if clamped:
		var world_dist := Vector2(_player_pos.x, _player_pos.z).distance_to(pos2)
		var label := "◇ %d m" % int(round(world_dist))
		_draw_upright_text(local + offset.normalized() * OBJECTIVE_LABEL_PUSH, label, UITokens.FONT_TINY, UITokens.TEXT_PRIMARY)


func _objective_display_position(centre: Vector2, scale_px_per_m: float, visible_radius: float) -> Variant:
	if _map_state == null:
		return null
	var objective: Dictionary = _map_state.objective_marker()
	if objective.is_empty():
		return null
	var pos2: Vector2 = objective.get("position", Vector2.ZERO)
	var local := _world_to_local(Vector3(pos2.x, 0.0, pos2.y), centre, scale_px_per_m)
	var offset := local - centre
	if offset.length() > visible_radius:
		return centre + offset.normalized() * visible_radius
	if offset.length() < PLAYER_MARKER_CLEAR_RADIUS:
		return player_clear_position(local, centre)
	return local


static func player_clear_position(local: Vector2, centre: Vector2) -> Vector2:
	var offset := local - centre
	var direction := offset.normalized() if offset.length_squared() > 0.001 else Vector2.UP
	return centre + direction * PLAYER_MARKER_CLEAR_RADIUS


static func map_layer_draw_span(visible_span: float) -> float:
	return visible_span * sqrt(2.0)


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
	# OP21-15 blind pass: "minimap corner tick decorations are clipped by the
	# frame edge." These four notches sit at the diagonals -- exactly the
	# directions `_draw_corner_masks`' rounded-corner wedges eat into, and the
	# old radius (`RING_WIDTH * 0.5` in from the square's raw edge) put a
	# notch's own 2.5px radius close enough to the widget's true corner that
	# corner-rounding on the real device (a different box size than whatever
	## this was authored against) could plausibly clip it. Pulled in by
	# `CORNER_RADIUS` as well so every notch sits inside the ring's rounded
	# interior with real clearance, not just past the ring's straight edges.
	var notch_radius := box.x * 0.5 - RING_WIDTH * 0.5 - CORNER_RADIUS * 0.35
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
	var north_dir := Vector2(-sin(_movement_yaw), cos(_movement_yaw))
	# Keep the full glyph inside the frame, not centred on its inner edge. The
	# latter made N look clipped/crowded whenever north approached a corner.
	var north_pos := centre + north_dir * (tick_radius - 16.0)
	draw_circle(north_pos, 9.0, Color(UITokens.BG_DEEP, 0.82))
	_draw_upright_text(north_pos, "N", UITokens.FONT_TINY, UITokens.TEXT_PRIMARY)


## The player's arrow is independent from the movement-up world layer. With
## look == travel it points up. Orbiting while stationary turns only this
## marker; strafing/backpedalling keep actual travel at the top of the map.
## OP21-15 blind pass: "the minimap player arrow is 10x10px (~1.2mm) --
## smaller than the waypoint diamond it points toward... the thing you are
## should never be smaller than the thing you're going to." The objective
## diamond draws at `r = 9.0` (an 18px point-to-point span); the old
## `size = 12.0` triangle here was actually narrower than that once its
## `0.62` side factor and `0.75` base pullback are accounted for, and its
## "cream heading tip" -- the one visual cue that distinguishes a direction
## arrow from a plain dot -- was a sliver at `0.15`/`0.28` of an already
## small shape, reading as 1-2px of white at map scale. Both numbers are
## bumped here: the whole marker is now unambiguously the largest fixed
## marker on the minimap (bigger than the 18px objective diamond it needs to
## out-rank), and the cream tip is close to half the shape's own length so
## it survives being shrunk again by the project's canvas_items handheld
## stretch scale.
func _draw_player_marker(centre: Vector2) -> void:
	var size := 17.0 # ~30px tip-to-base triangle, wider stance too (see below)
	var relative := angle_difference(_movement_yaw, _look_yaw)
	var forward := Vector2(sin(relative), -cos(relative))
	var side := Vector2(-forward.y, forward.x)
	var points := PackedVector2Array([
		centre + forward * size,
		centre - forward * size * 0.75 + side * size * 0.72,
		centre - forward * size * 0.75 - side * size * 0.72,
	])
	draw_colored_polygon(points, UITokens.TEAL)
	# a cream tip, now close to half the arrow's own length, so the heading
	# reads at a glance instead of needing the viewer to find a 1-2px sliver.
	var tip := PackedVector2Array([
		centre + forward * size,
		centre + forward * size * -0.05 + side * size * 0.40,
		centre + forward * size * -0.05 - side * size * 0.40,
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
## OP21-15 blind pass: the objective distance label ("257 m") is white text
## laid straight onto whatever terrain colour is under it, most often the
## light meadow-green the baked terrain uses for most open ground -- with no
## outline or shadow it vanishes into pale ground the same way `tab_map.gd`'s
## `_draw_string_legible` was written to fix for the full map (that file's
## own header: "every string this file draws is a raw `_draw()` call over a
## busy, multi-coloured baked terrain texture, so it needs the SAME outline
## treatment applied by hand rather than going unplated" -- true here too,
## just never done). Same `UITokens.OUTLINE`/`OUTLINE_SIZE` treatment, copied
## rather than shared for the same "concurrent agent's file" reason this
## file's fog constants are already copied from `tab_map.gd`.
func _draw_upright_text(centre: Vector2, text: String, font_size: int, colour: Color) -> void:
	if _font == null:
		return
	# DEFECT 3 (blind visual review, `shots/ui/07-minimap.png`): "the
	# waypoint distance '256 m' is clipped by the minimap's own right
	# border, cutting the 'm' in half." Not `clip_contents` -- the old
	# MARGIN (3.0) already kept the clamp inside the Control's own `size`,
	# so `clip_contents` never touched it. The real cause is draw order:
	# `_draw()` calls `_draw_objective()` (this text) BEFORE `_draw_frame()`
	# paints the ring, and `_draw_frame()`'s ring border is `RING_WIDTH` (8px)
	# thick, painted inward from the widget's edge -- so a label clamped to
	# within 3px of that edge sits UNDER where the ring gets painted on TOP
	# of it one call later, and the ring's own opaque colour bites into
	# whatever glyph was sitting in that outer band. Clamping to at least
	# `RING_WIDTH` clear of the edge keeps every label's clamped box entirely
	# outside the ring's painted footprint, so nothing drawn afterward can
	# cut into it.
	const MARGIN := RING_WIDTH + 3.0
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var top_left := centre - text_size * 0.5
	top_left.x = clampf(top_left.x, MARGIN, maxf(MARGIN, size.x - text_size.x - MARGIN))
	top_left.y = clampf(top_left.y, MARGIN, maxf(MARGIN, size.y - text_size.y - MARGIN))
	var baseline := top_left + Vector2(0.0, text_size.y - _font.get_descent(font_size))
	draw_string_outline(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, UITokens.OUTLINE_SIZE, UITokens.OUTLINE)
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, colour)
