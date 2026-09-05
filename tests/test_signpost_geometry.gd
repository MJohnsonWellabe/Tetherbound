extends "res://tests/test_case.gd"

## W22-BRIDGE-SIGNPOST-0904. `scripts/world/signpost.gd` is built geometry,
## and prompt 74 §7's two "fails if" clauses for it are geometric: the arms
## must still not visually collide (R7.1-visual's golden-angle mounting) and
## every label must still fit its plank (`_label_scale()`, GF-B-013 and
## BAND1-DISCOVERY-0903's fit). Both are asked of a REAL built signpost --
## the nodes `build()` actually adds, their meshes and their Label3D
## settings -- never of the script's text.

const SIGNPOST := preload("res://scripts/world/signpost.gd")


## The one thing `build()` asks of its world.
class FlatGround extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


const ROUTES := [
	{"label": "Grandpa's House", "points": [[0.0, 0.0], [0.0, 10.0]]},
	{"label": "The Pond", "points": [[0.0, 0.0], [10.0, 3.0]]},
	{"label": "Relay Station", "points": [[0.0, 0.0], [-8.0, 4.0]]},
	{"label": "Watchtower Spur", "points": [[0.0, 0.0], [2.0, -9.0]]},
]

var world: Node3D = null
var sign: Node3D = null


func before_each() -> void:
	world = FlatGround.new()
	sign = SIGNPOST.new()
	world.add_child(sign)
	sign.call("build", world, Vector2.ZERO, ROUTES)


func after_each() -> void:
	world.free()
	world = null
	sign = null


func _arms() -> Array[Node3D]:
	var arms: Array[Node3D] = []
	for child in sign.get_children():
		if child.name.begins_with("Arm_"):
			arms.append(child as Node3D)
	return arms


func _plank(arm: Node3D) -> MeshInstance3D:
	return arm.get_node("Plank") as MeshInstance3D


func _labels(arm: Node3D) -> Array[Label3D]:
	var out: Array[Label3D] = []
	for child in arm.get_children():
		if child is Label3D:
			out.append(child)
	return out


func test_one_arm_is_built_per_route() -> void:
	assert_eq(_arms().size(), ROUTES.size())
	assert_eq(int(sign.call("placed")), ROUTES.size())


## `_label_scale()`'s job: the text's world-space footprint (font pixels x
## metres-per-pixel, using the same 0.55 em mean advance it fits with) must
## sit inside the plank's own body -- its length short of the tip, and its
## height at the body's SHALLOW end, since the plank now tapers.
func test_every_label_fits_inside_its_own_plank_body() -> void:
	var font_size: int = SIGNPOST.LABEL_FONT_SIZE
	var body_length: float = SIGNPOST.ARM_LENGTH
	var body_min_height: float = SIGNPOST.ARM_HEIGHT * SIGNPOST.ARM_TAPER
	for arm in _arms():
		var labels := _labels(arm)
		assert_eq(labels.size(), 2, "%s should be lettered on both faces" % arm.name)
		for label in labels:
			var letter_height := float(font_size) * label.pixel_size
			var text_width := float(label.text.length()) * 0.55 * float(font_size) * label.pixel_size
			assert_true(letter_height < body_min_height,
				"%s: %.3fm letters on a %.3fm board" % [arm.name, letter_height, body_min_height])
			assert_true(text_width < body_length,
				"%s: %.3fm of text on a %.3fm board" % [arm.name, text_width, body_length])
			# And the label is centred on the body, not out on the tip.
			assert_between(label.position.z, 0.0, body_length)


## The plank is one pointed piece: its far end comes to a point on the
## centreline, past the body, and the post end is the full board height.
func test_each_plank_is_a_single_pointed_board() -> void:
	for arm in _arms():
		var mesh := _plank(arm).mesh
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var far_z := -INF
		var tip_half_height := 0.0
		var post_end_half_height := 0.0
		for v in verts:
			far_z = maxf(far_z, v.z)
		for v in verts:
			if is_equal_approx(v.z, far_z):
				tip_half_height = maxf(tip_half_height, absf(v.y))
			if v.z <= 0.0:
				post_end_half_height = maxf(post_end_half_height, absf(v.y))
		assert_true(far_z > SIGNPOST.ARM_LENGTH, "%s: no tip past the body" % arm.name)
		assert_almost_eq(tip_half_height, 0.0, 0.001, "%s: the tip is not a point" % arm.name)
		assert_almost_eq(post_end_half_height, SIGNPOST.ARM_HEIGHT * 0.5, 0.001)
		# One mesh: no separate arrowhead node left bolted to the arm.
		for child in arm.get_children():
			assert_false(child is MeshInstance3D and child.name != "Plank" and child.name != "Bracket",
				"%s carries an extra mesh: %s" % [arm.name, child.name])


## R7.1-visual round 3: arms mount at distinct points around the post, so no
## two planks radiate from the same point. And the stack still clears
## itself: with the tip's height at zero and the body tapered, consecutive
## arms keep clear air between their planks.
func test_arms_mount_apart_and_stack_without_touching() -> void:
	var arms := _arms()
	for i in arms.size():
		for j in range(i + 1, arms.size()):
			var a := Vector2(arms[i].position.x, arms[i].position.z)
			var b := Vector2(arms[j].position.x, arms[j].position.z)
			assert_true(a.distance_to(b) > 0.05,
				"%s and %s share a mount point" % [arms[i].name, arms[j].name])
	var tops: Array[float] = []
	var bottoms: Array[float] = []
	for arm in arms:
		var aabb: AABB = _plank(arm).mesh.get_aabb()
		tops.append(arm.position.y + aabb.end.y)
		bottoms.append(arm.position.y + aabb.position.y)
	for i in arms.size():
		for j in arms.size():
			if i == j:
				continue
			var overlap := minf(tops[i], tops[j]) - maxf(bottoms[i], bottoms[j])
			assert_true(overlap < 0.0, "%s and %s overlap by %.3fm" % [arms[i].name, arms[j].name, overlap])


## Board 18's rope band: wound round the post in the air above the topmost
## arm and below the cap, never across a plank.
func test_rope_band_sits_above_the_topmost_arm_under_the_cap() -> void:
	var band := sign.get_node_or_null("RopeBand") as Node3D
	assert_true(band != null, "no RopeBand on the post")
	if band == null:
		return
	var coils := 0
	var lowest := INF
	var highest := -INF
	for child in band.get_children():
		if child is MeshInstance3D:
			coils += 1
			var aabb: AABB = (child as MeshInstance3D).mesh.get_aabb()
			lowest = minf(lowest, band.position.y + (child as Node3D).position.y + aabb.position.y)
			highest = maxf(highest, band.position.y + (child as Node3D).position.y + aabb.end.y)
	assert_true(coils >= 2, "a band of %d coil(s) is not a wrap" % coils)
	var topmost_plank := -INF
	for arm in _arms():
		topmost_plank = maxf(topmost_plank, arm.position.y + _plank(arm).mesh.get_aabb().end.y)
	assert_true(lowest > topmost_plank, "band starts at %.3f, under the top arm's %.3f" % [lowest, topmost_plank])
	assert_true(highest < SIGNPOST.POST_HEIGHT + SIGNPOST.CAP_HEIGHT, "band rises past the cap")
	var cap := sign.get_node_or_null("Cap")
	assert_true(cap != null, "no cap on the post")


## The plank body reads as the board's own wood: darker than the cream ink,
## which is the legibility contract the ink swap depends on.
func test_lettering_is_lighter_than_the_board_it_sits_on() -> void:
	for arm in _arms():
		var plank := _plank(arm)
		var mat := plank.mesh.surface_get_material(0) as StandardMaterial3D
		assert_true(mat != null, "%s: plank has no material" % arm.name)
		if mat == null:
			continue
		for label in _labels(arm):
			assert_true(label.modulate.get_luminance() > mat.albedo_color.get_luminance() + 0.3,
				"%s: ink %.2f vs board %.2f" % [arm.name, label.modulate.get_luminance(), mat.albedo_color.get_luminance()])
			assert_true(label.outline_modulate.get_luminance() < label.modulate.get_luminance(),
				"%s: outline is not darker than the ink" % arm.name)


## N09-BRIDGE-CHECKPOINT-0905. W22's landing judge: "Both columns also clip
## the last character ('Relay Statio') because the label runs under the post."
##
## Each arm mounts at its own golden-angle point on the post's circumference,
## so the post's centreline falls at a DIFFERENT z in every arm's own frame --
## anywhere in +-ARM_MOUNT_RADIUS -- and on an arm whose mount sits on the far
## side of the post from its own bearing the trunk reaches out past where a
## label fitted to a fixed 0..ARM_LENGTH board starts. This asks the built
## signpost the reader's question directly: on every arm, on both faces, is
## the whole word on visible board?
##
## The plank mesh itself supplies the post end (its own minimum z IS the post
## centreline, `_pointed_plank_mesh(z_axis)`), so this cannot drift with a
## constant.
func test_no_label_runs_under_the_post() -> void:
	var font_size: int = SIGNPOST.LABEL_FONT_SIZE
	for arm in _arms():
		var verts: PackedVector3Array = _plank(arm).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var post_axis_z := INF
		for v in verts:
			post_axis_z = minf(post_axis_z, v.z)
		var trunk_face := post_axis_z + SIGNPOST.POST_RADIUS
		for label in _labels(arm):
			var text_width := float(label.text.length()) * 0.55 * float(font_size) * label.pixel_size
			var near_edge := label.position.z - text_width * 0.5
			var far_edge := label.position.z + text_width * 0.5
			assert_true(near_edge >= trunk_face,
				"%s: '%s' starts at z %.3f, inside the post's face at %.3f" % [
					arm.name, label.text, near_edge, trunk_face])
			assert_true(far_edge <= SIGNPOST.ARM_LENGTH,
				"%s: '%s' ends at z %.3f, past the board's %.3f" % [
					arm.name, label.text, far_edge, SIGNPOST.ARM_LENGTH])


## The outline is the contrast carrier at gameplay distance (see
## `signpost.gd`'s own `outline_size` comment: cream core and dark edge pull
## in opposite directions, and at 7-10 px of glyph band the edge is what
## survives). It only does that job while it is a real fraction of the em --
## and only stays letters while it is under the ~21 % flood point GF-B-013
## measured, where the edge closes an `o`'s counter.
func test_the_ink_outline_is_weighted_between_its_two_known_limits() -> void:
	var font_size: float = float(SIGNPOST.LABEL_FONT_SIZE)
	for arm in _arms():
		for label in _labels(arm):
			var em_fraction := float(label.outline_size) / font_size
			assert_true(em_fraction >= 0.10,
				"%s: outline is %.1f%% of the em, too thin to carry the word at distance" % [
					arm.name, em_fraction * 100.0])
			assert_true(em_fraction < 0.21,
				"%s: outline is %.1f%% of the em, past the counter-flood point" % [
					arm.name, em_fraction * 100.0])
