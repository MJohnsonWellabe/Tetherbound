extends RefCounted

## CONTENT-0828B -- the constructed-interior method.
##
## The owner localised "some locations still look lame" to a CLASS rather than
## to a list of sites (`docs/owner/OWNER_PLAYTEST_2026-08-28.md` §4a):
##
##   "burrow warrens and the castle are the lame looking locations. basically
##    everywhere we had to build an under ground or build a building"
##
## Every space this project GROWS -- terrain, scatter, grass, sightlines -- drew
## praise or no comment. Every space it CONSTRUCTS drew the complaint. So the
## defect is the method, and two one-off dressing passes would not have touched
## it. This file is the method; `burrow_warrens.gd` and `stronghold.gd` are its
## first two consumers.
##
## WHY CONSTRUCTED SPACE READS AS UNFINISHED HERE, stated as a mechanism rather
## than as taste, because the fix follows from it:
##
## Both builders compose rooms the same way -- a chamber is a floor box, a
## ceiling box and four wall boxes, each one flat plane from corner to corner
## carrying one triplanar material at one scale. That gives a room exactly TWO
## scales of incident: the room itself (tens of metres) and its props (under a
## metre). The meadow outside has five or six -- canopy, trunk, bush, fern,
## tuft, pebble -- and that ladder is most of why it reads. An interior wall
## has nothing between "wall" and "barrel", so the eye finds no scale reference,
## and a surface with no scale reference reads as a blockout no matter how good
## its texture is.
##
## The second half is that indoor light here cannot rescue it. Every interior
## OmniLight3D in both files sets `shadow_enabled = false` (a deliberate
## Compatibility-renderer/handheld cost decision, not an oversight, and this
## pass does NOT reopen it). Outdoors the sun models form for free; indoors a
## flat plane under a shadowless point light is a flat plane. So the value
## variation that breaks a surface up has to be built into the GEOMETRY and its
## MATERIAL, because no light in these rooms is going to supply it.
##
## THE METHOD: give every constructed room the middle scale it is missing, as
## five passes on the junctions and runs a built space actually has.
##
##   bays     a vertical member at a repeating pitch along every wall, with a
##            capital. Breaks the wall's horizontal run and installs the scale
##            reference the room has none of. The single largest of the five.
##   course   a horizontal band at mid-height, cut into one segment per bay.
##            Breaks the vertical run and gives the room a horizon.
##   ribs     ceiling members spanning the short axis, landed ON the bay
##            divisions of the long walls. Stops the ceiling being a slab, and
##            the alignment is what makes the room read as structure rather
##            than as stripes -- an unaligned rib is just another stripe.
##   reveals  a jamb-and-lintel frame around every cut opening, so a doorway is
##            a made thing instead of a hole in a plane.
##   corners  a post in each internal corner. The prior pass's own finding, in
##            its words: "a cave does not have corners" -- and neither does a
##            hall. A hard 90-degree junction of two flat planes is the single
##            most blockout-looking thing in either building.
##
## ONE GRAMMAR, TWO VOCABULARIES. The passes are identical for a cave and for a
## fortress; what differs is `jitter` and the materials the consumer hands
## over. At `jitter: 0` the members are regular and square and read as masonry.
## Above zero each piece takes a small random lean, inset and scale, and the
## same code reads as rock ribbing. That is the whole reason this is one file
## and not two -- the owner named a class of space, so the fix has to be a
## thing a class of space can consume.
##
## RULES EVERY PASS KEEPS, each one a defect this repo has already paid for:
##
##  * NOTHING IS SOLID. No colliders, ever. `stronghold.gd::_build_trim` states
##    it for its girders ("a girder with a collider is a ledge the player can
##    stand on halfway up a wall") and `burrow_warrens.gd::_build_site_skirt`
##    for its scatter. Structure is dressing; a pilaster that stops a player is
##    a bug.
##  * NOTHING ENTERS A DOORWAY. Tested against the consumer's own recorded
##    doorway list, the same test its scatter already uses.
##  * NOTHING REACHES PAST `max_project_m`. Both builders reserve a metre from
##    every wall for the fight (`ARENA_WALL_MARGIN`), and
##    `combat_arena_bounds_at()` hands that reservation to combat as a promise.
##    Dressing that eats into it silently shrinks an arena the fight was tuned
##    against, so the clamp is enforced here rather than trusted to each
##    config.
##  * OPEN CHAMBERS GET NO RIBS. A courtyard has no ceiling to rib.

## The hard ceiling on how far any member may reach into a room, in metres.
## Half of both consumers' `ARENA_WALL_MARGIN` of 1.0, so even a config that
## asks for something silly cannot reach the fight. See the rules above.
const MAX_PROJECT_M := 0.5

## Below this, a member is not worth the node it costs.
const MIN_MEMBER_M := 0.08


var _holder: Node3D = null
var _rng := RandomNumberGenerator.new()
var _material_for: Callable = Callable()
var _jitter := 0.0
var _placed := 0


## Dress one constructed building.
##
## `spec` keys:
##   chambers      Array of Dictionary {id, centre:Vector3, size:Vector2,
##                 height:float, open:bool} in the HOST's local space, which is
##                 the space both consumers already author everything else in.
##   doorways      Array of [Vector3 centre, float radius] -- the list both
##                 builders already record while cutting their passages.
##   openings      Array of Dictionary {centre:Vector3, along_x:bool,
##                 width:float, height:float} for the `reveals` pass.
##   floor_y       the building's own floor level, host-local.
##   material_for  Callable(role: String) -> StandardMaterial3D. Roles are
##                 "shaft", "capital", "course", "rib", "corbel",
##                 "reveal", "corner".
##                 The consumer maps them onto its own palette, so this file
##                 never picks a colour and the two buildings cannot drift.
##   config        the tuning block out of the consumer's own JSON.
##
## Returns the number of members placed, so a caller can print it and a perf
## pass can see the node cost without reading the code.
func dress(host: Node3D, spec: Dictionary) -> int:
	var config: Dictionary = spec.get("config", {})
	if not bool(config.get("enabled", true)):
		return 0
	var chambers: Array = spec.get("chambers", [])
	if chambers.is_empty():
		return 0
	_material_for = spec.get("material_for", Callable())
	if not _material_for.is_valid():
		push_warning("interior_structure: no material_for callable; nothing placed")
		return 0

	_rng.seed = int(config.get("seed", 0x57A1C))
	_jitter = clampf(float(config.get("jitter", 0.0)), 0.0, 1.0)
	_placed = 0
	_holder = Node3D.new()
	_holder.name = "InteriorStructure"
	host.add_child(_holder)

	var floor_y := float(spec.get("floor_y", 0.0))
	var doorways: Array = spec.get("doorways", [])

	for entry: Variant in chambers:
		if not entry is Dictionary:
			continue
		var chamber: Dictionary = entry
		var centre: Vector3 = chamber.get("centre", Vector3.ZERO)
		var size: Vector2 = chamber.get("size", Vector2.ZERO)
		var height := float(chamber.get("height", 4.0))
		var open := bool(chamber.get("open", false))
		if size.x <= 1.0 or size.y <= 1.0 or height <= 1.0:
			continue
		var divisions := _bay_divisions(size, config)
		_bays(centre, size, height, floor_y, divisions, doorways, config)
		_course(centre, size, height, floor_y, divisions, doorways, config)
		if not open:
			_ribs(centre, size, height, floor_y, divisions, config)
		_corners(centre, size, height, floor_y, doorways, config)

	_reveals(spec.get("openings", []), floor_y, config)
	return _placed


## --- the bay rhythm ---------------------------------------------------------

## Where the members go along each of the four walls, as fractions of that
## wall's own run.
##
## Derived from the room rather than authored, and rounded so the bays come out
## EVEN: `n = round(L / pitch)` then `pitch = L / n`. A remainder bay is the
## thing that makes a repeating rhythm read as an accident -- one short bay in
## a corner and the wall looks like it ran out of wall, which is the exact
## reading this pass exists to remove. Interior divisions only (1..n-1); the
## two ends are the `corners` pass's, and drawing both puts two members in one
## corner.
func _bay_divisions(size: Vector2, config: Dictionary) -> Dictionary:
	var target := maxf(float(config.get("bay_pitch_m", 3.4)), 1.2)
	var out := {}
	for axis: String in ["x", "z"]:
		var run: float = size.x if axis == "x" else size.y
		var bays := maxi(int(round(run / target)), 1)
		var marks: Array[float] = []
		for i in range(1, bays):
			marks.append(-run * 0.5 + run * float(i) / float(bays))
		out[axis] = {"bays": bays, "marks": marks, "pitch": run / float(bays)}
	return out


## Pass 1 -- a vertical member at every bay division on all four walls, each
## capped with a capital.
##
## The capital is not ornament for its own sake. A bare shaft running floor to
## ceiling is a stripe; the break at the top is what tells the eye the member
## is a THING standing in the room rather than a change of colour painted on
## the wall behind it. It is also the only part of this pass that survives when
## the player is close enough that the shaft fills the frame.
func _bays(centre: Vector3, size: Vector2, height: float, floor_y: float,
		divisions: Dictionary, doorways: Array, config: Dictionary) -> void:
	var width := maxf(float(config.get("bay_width_m", 0.8)), MIN_MEMBER_M)
	var project := _project(config, "bay_project_m", 0.34)
	var cap_h := maxf(float(config.get("capital_height_m", 0.4)), 0.0)
	var cap_extra := maxf(float(config.get("capital_project_m", 0.16)), 0.0)
	var half := size * 0.5
	var full_h := maxf(height - cap_h, MIN_MEMBER_M)
	# RAGGED is what actually separates rock from masonry, and `jitter` alone
	# was not enough. A blind critic given the first ribbed build read the
	# Warrens as "built out of the same dressed ashlar as the fortress" and said
	# plainly that nothing in it reads as burrowed -- which is fair, because a
	# few degrees of lean on a member that still runs floor to ceiling at a
	# regular pitch is a colonnade with a wobble. What a cave has is ribbing
	# that DIES OUT: a rib of harder stone stands proud for a couple of metres
	# and the wall closes over it. So above zero jitter each member takes its
	# own height, and the ones that stop short lose their capital, because a
	# capital is a thing masonry has and rock does not.
	var ragged := bool(config.get("ragged", _jitter > 0.0))
	var short_at := clampf(float(config.get("ragged_short_at", 0.62)), 0.1, 1.0)

	for axis: String in ["x", "z"]:
		var along_x := axis == "x"
		var marks: Array = (divisions[axis] as Dictionary)["marks"]
		for mark: float in marks:
			for side in [-1.0, 1.0]:
				# Flush with the wall's inner face, reaching `project` into the
				# room. The wall itself is untouched -- this stands against it.
				var inset: float = (half.y if along_x else half.x) - project * 0.5
				var at := Vector3(centre.x + mark, 0.0, centre.z + side * inset) if along_x \
					else Vector3(centre.x + side * inset, 0.0, centre.z + mark)
				at += _lean()
				if _in_a_doorway(at, doorways):
					continue
				var shaft_h := full_h
				var wide := width
				if ragged:
					shaft_h = full_h * _rng.randf_range(short_at, 1.0)
					# Width varies too, and for the same reason: a rock rib is
					# not extruded, it is what is left after the softer stone
					# around it went.
					wide = width * _rng.randf_range(0.7, 1.35)
				var span := Vector3(wide, shaft_h, project) if along_x \
					else Vector3(project, shaft_h, wide)
				_member(span, Vector3(at.x, floor_y + shaft_h * 0.5, at.z), "shaft")
				# A capital only where the member actually reaches the top. On a
				# rib that stops short it would read as a shelf hanging off a
				# wall, which is worse than no capital at all.
				if cap_h > MIN_MEMBER_M and is_equal_approx(shaft_h, full_h):
					var cap := Vector3(wide + cap_extra, cap_h, project + cap_extra) if along_x \
						else Vector3(project + cap_extra, cap_h, wide + cap_extra)
					_member(cap, Vector3(at.x, floor_y + full_h + cap_h * 0.5, at.z), "capital")


## Pass 2 -- the horizontal course, in one segment per bay.
##
## Segmented rather than run as one ribbon for two reasons, and the first is
## structural: a continuous band at mid-height crosses every doorway on that
## wall, and a doorway with a bar across it is worse than no course at all. Per
## bay, the same `_in_a_doorway` test the rest of this file uses drops exactly
## the segments that would. The second is that a jointed course reads as
## courses of stone; an extruded ribbon reads as a pipe.
func _course(centre: Vector3, size: Vector2, height: float, floor_y: float,
		divisions: Dictionary, doorways: Array, config: Dictionary) -> void:
	if not bool(config.get("course", true)):
		return
	var thickness := maxf(float(config.get("course_height_m", 0.34)), MIN_MEMBER_M)
	var project := _project(config, "course_project_m", 0.22)
	var at_h := clampf(float(config.get("course_at", 0.55)), 0.1, 0.92) * height
	var gap := maxf(float(config.get("course_joint_m", 0.18)), 0.0)
	var half := size * 0.5

	for axis: String in ["x", "z"]:
		var along_x := axis == "x"
		var info: Dictionary = divisions[axis]
		var bays := int(info["bays"])
		var pitch := float(info["pitch"])
		var run: float = size.x if along_x else size.y
		var length := maxf(pitch - gap, MIN_MEMBER_M)
		for i in bays:
			var mid := -run * 0.5 + pitch * (float(i) + 0.5)
			for side in [-1.0, 1.0]:
				var inset: float = (half.y if along_x else half.x) - project * 0.5
				var at := Vector3(centre.x + mid, 0.0, centre.z + side * inset) if along_x \
					else Vector3(centre.x + side * inset, 0.0, centre.z + mid)
				if _in_a_doorway(at, doorways):
					continue
				var span := Vector3(length, thickness, project) if along_x \
					else Vector3(project, thickness, length)
				_member(span, Vector3(at.x, floor_y + at_h, at.z), "course")


## Pass 3 -- ceiling ribs, spanning the SHORT axis, on the LONG walls' bay
## divisions.
##
## The alignment is the whole point. A rib that lands on a bay member continues
## a line the eye has already followed up the wall, and the room reads as a
## structure that was built. A rib on its own pitch is a second unrelated
## rhythm, and two unrelated rhythms read as wallpaper. This is also why the
## bay divisions are computed once per chamber and handed to all three passes
## rather than recomputed per pass -- they have to agree exactly.
func _ribs(centre: Vector3, size: Vector2, height: float, floor_y: float,
		divisions: Dictionary, config: Dictionary) -> void:
	if not bool(config.get("ribs", true)):
		return
	var width := maxf(float(config.get("rib_width_m", 0.62)), MIN_MEMBER_M)
	var drop := _project(config, "rib_drop_m", 0.38)
	# Ribs span the short axis and repeat along the long one, so a rectangular
	# room reads across its narrow dimension the way a real roof frames.
	var long_is_x := size.x >= size.y
	var axis := "x" if long_is_x else "z"
	var marks: Array = (divisions[axis] as Dictionary)["marks"]
	var span_len: float = size.y if long_is_x else size.x
	# A CORBEL AT EACH END, because a rib that meets a wall and simply stops is
	# the thing a blind critic named first: "they simply penetrate the masonry.
	# Nothing sags, nothing is broken, nothing is doubled at a span, nothing
	# carries a load." A bracket under each end is the smallest honest answer --
	# it is what the wall does to catch the beam, it puts a second silhouette
	# where wall meets ceiling, and it costs two boxes per rib.
	var corbel := maxf(float(config.get("corbel_length_m", 0.0)), 0.0)
	var half := size * 0.5
	for mark: float in marks:
		var at := Vector3(centre.x + mark, floor_y + height - drop * 0.5, centre.z) if long_is_x \
			else Vector3(centre.x, floor_y + height - drop * 0.5, centre.z + mark)
		var span := Vector3(width, drop, span_len) if long_is_x \
			else Vector3(span_len, drop, width)
		_member(span, at, "rib")
		if corbel < MIN_MEMBER_M:
			continue
		for side in [-1.0, 1.0]:
			# Deeper than the rib and hanging below it, so it reads as
			# something the beam sits ON rather than as a thicker beam end.
			var reach: float = (half.y if long_is_x else half.x) - corbel * 0.5
			var seat := Vector3(width * 1.5, drop * 1.6, corbel) if long_is_x \
				else Vector3(corbel, drop * 1.6, width * 1.5)
			var seat_at := Vector3(at.x, floor_y + height - drop * 0.8, centre.z + side * reach) if long_is_x \
				else Vector3(centre.x + side * reach, floor_y + height - drop * 0.8, at.z)
			_member(seat, seat_at, "corbel")


## Pass 4 -- a jamb-and-lintel frame around every cut opening.
##
## `_build_passages()` in both consumers cuts a hole and puts a floor through
## it, and that is genuinely all it does: what the player walks through is an
## absence in a plane. The playtest's own reading of the Warrens' branch door
## -- "a flat brown panel filling a hole in a wall" -- is half about the panel
## and half about the hole. A frame is what makes an opening read as a way on.
##
## Built proud on BOTH faces (`reveal_depth_m` is the total, centred on the
## wall) because an opening is seen from both rooms and a frame on one side
## only reads as a mistake from the other.
func _reveals(openings: Array, floor_y: float, config: Dictionary) -> void:
	if not bool(config.get("reveals", true)) or openings.is_empty():
		return
	var jamb := maxf(float(config.get("reveal_width_m", 0.46)), MIN_MEMBER_M)
	var lintel := maxf(float(config.get("reveal_lintel_m", 0.42)), MIN_MEMBER_M)
	var depth := maxf(float(config.get("reveal_depth_m", 1.9)), MIN_MEMBER_M)

	for entry: Variant in openings:
		if not entry is Dictionary:
			continue
		var opening: Dictionary = entry
		var at: Vector3 = opening.get("centre", Vector3.ZERO)
		var along_x := bool(opening.get("along_x", true))
		var width := float(opening.get("width", 3.0))
		var height := float(opening.get("height", 4.0))
		if width <= 0.1 or height <= 0.1:
			continue
		# Jambs stand beside the gap, not in it: the inner face of each is
		# flush with the edge of the opening the passage actually cut, so the
		# frame never narrows the way through. A doorway a player catches on is
		# the failure `_build_conduits` names for its own cable runs.
		for side in [-1.0, 1.0]:
			var offset: float = side * (width * 0.5 + jamb * 0.5)
			var post := Vector3(jamb, height + lintel, depth) if along_x \
				else Vector3(depth, height + lintel, jamb)
			var post_at := Vector3(at.x + offset, floor_y + (height + lintel) * 0.5, at.z) if along_x \
				else Vector3(at.x, floor_y + (height + lintel) * 0.5, at.z + offset)
			_member(post, post_at, "reveal")
		var head := Vector3(width + jamb * 2.0, lintel, depth) if along_x \
			else Vector3(depth, lintel, width + jamb * 2.0)
		_member(head, Vector3(at.x, floor_y + height + lintel * 0.5, at.z), "reveal")


## Pass 5 -- a pier in each internal corner.
##
## The prior Warrens pass found this in frames and wrote it down: "it reads as
## unfinished because a cave does not have corners." A fortress hall does not
## have them either -- a 90-degree meeting of two flat planes is a modelling
## artefact, not a building.
##
## TWO members per corner, not one, and the reason is the arena clamp rather
## than taste. A single square post big enough to read in a 28-metre hall
## reaches `width * 0.707` diagonally into the room, which blows through
## MAX_PROJECT_M the moment the post is wider than about 0.7 m. An L of two
## slabs -- one against each wall, each projecting exactly `corner_project_m`
## and running `corner_width_m` ALONG its own wall -- reads as a corner pier at
## any size the room wants while never leaving the margin combat is promised.
## It is also simply the right shape: a pier is what a corner of a built room
## has, and a square column standing in a corner is furniture.
func _corners(centre: Vector3, size: Vector2, height: float, floor_y: float,
		doorways: Array, config: Dictionary) -> void:
	if not bool(config.get("corners", true)):
		return
	var run := maxf(float(config.get("corner_width_m", 0.9)), MIN_MEMBER_M)
	var reach := _project(config, "corner_project_m", 0.44)
	var half := size * 0.5
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			# The corner itself, for the doorway test -- a passage cut close to
			# a corner would otherwise get a pier standing in its mouth.
			var corner := Vector3(centre.x + cx * half.x, 0.0, centre.z + cz * half.y)
			if _in_a_doorway(corner, doorways):
				continue
			# The leaf against the +/-z wall, running along x, and the leaf
			# against the +/-x wall, running along z. Each sits flush with its
			# own wall's inner face and reaches `reach` into the room.
			_member(Vector3(run, height, reach),
				Vector3(centre.x + cx * (half.x - run * 0.5), floor_y + height * 0.5,
					centre.z + cz * (half.y - reach * 0.5)), "corner")
			_member(Vector3(reach, height, run),
				Vector3(centre.x + cx * (half.x - reach * 0.5), floor_y + height * 0.5,
					centre.z + cz * (half.y - run * 0.5)), "corner")


## --- shared -----------------------------------------------------------------

## One member. Never solid, always under the holder, and jittered when the
## consumer asked for rock rather than masonry.
func _member(size: Vector3, at: Vector3, role: String) -> void:
	if size.x < MIN_MEMBER_M or size.y < MIN_MEMBER_M or size.z < MIN_MEMBER_M:
		return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material: Variant = _material_for.call(role)
	# VP8: a consumer may hand back a ShaderMaterial (the Hall's weathered
	# stone) as readily as a StandardMaterial3D; the member wears whichever.
	if material is Material:
		mesh.material_override = material
	mesh.position = at
	if _jitter > 0.0:
		# Rock, not masonry. A lean of a few degrees and a percent or two of
		# scale is enough -- past that the members stop lining up with each
		# other and the rhythm this whole file is about stops reading.
		var lean := 0.09 * _jitter
		mesh.rotation = Vector3(
			_rng.randf_range(-lean, lean),
			_rng.randf_range(-lean, lean) * 0.4,
			_rng.randf_range(-lean, lean))
		mesh.scale = Vector3.ONE * (1.0 + _rng.randf_range(-0.09, 0.09) * _jitter)
	mesh.name = "%s_%d" % [role, _placed]
	_holder.add_child(mesh)
	_placed += 1


## A small random offset along the wall, for the rock vocabulary only. Zero at
## `jitter: 0`, so masonry stays on its rhythm exactly.
func _lean() -> Vector3:
	if _jitter <= 0.0:
		return Vector3.ZERO
	var reach := 0.28 * _jitter
	return Vector3(_rng.randf_range(-reach, reach), 0.0, _rng.randf_range(-reach, reach))


## Every "how far into the room" number goes through here, so no config can
## reach past the metre both buildings promise combat. See MAX_PROJECT_M.
func _project(config: Dictionary, key: String, fallback: float) -> float:
	return clampf(float(config.get(key, fallback)), MIN_MEMBER_M, MAX_PROJECT_M)


## The consumer's own doorway list, tested in the flat -- both builders record
## `[centre, radius]` while cutting passages and both already test against it.
func _in_a_doorway(at: Vector3, doorways: Array) -> bool:
	for entry: Variant in doorways:
		if not entry is Array or (entry as Array).size() < 2:
			continue
		var centre: Vector3 = (entry as Array)[0]
		if Vector2(at.x - centre.x, at.z - centre.z).length() < float((entry as Array)[1]):
			return true
	return false
