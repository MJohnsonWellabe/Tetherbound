extends RefCounted

## Team Tether's visual language, built out of primitives and the village's own
## kit. MEADOWS_VERTICAL_SLICE.md M13's fifth bullet: "sacred/natural site
## industrialized by Tether".
##
## `GAME_DESIGN.md` §28 lists what that means — old stone and natural forms
## contrasted with machinery, cables, barricades, cages and trainers — and
## `data/config/palette.json` reserves one colour project-wide to say it with.
## This file is the only place in the game that spends that reservation, through
## `tether_data.accent()`; every colour below arrives as an ID and never as a hex.
##
## Nothing here is new art. The banners, the pylon, the cables and the tabard are
## primitives; the barricade is fence panels and a crate out of the settlement's
## own kit, left the colour they were made. That is the story as well as the
## budget: Team Tether did not ship a fort in, they nailed one onto somebody's
## road out of somebody's lumber.
##
## EVERY POSITION HERE IS IN WORLD SPACE, and every builder refuses a parent that
## is not in the scene tree yet — see `_placeable()`.
##
## Static builders, no state. Every function takes a parent and a position and
## hands back what it made, so a trainer, a pylon and a route all dress
## themselves from one place and cannot drift apart.

const DATA := preload("res://scripts/trainers/tether_data.gd")


## --- materials -------------------------------------------------------------

## Refuse to build anything onto a parent that is not in the scene tree yet.
##
## Every builder below places its pieces in WORLD coordinates, and
## `global_position` on a detached node prints `Condition "!is_inside_tree()" is
## true. Returning: Transform3D()` to stderr and then silently leaves the node at
## the origin. `shots/warden/01` from the second pass is what that looks like: a
## banner meant to be six metres to one side standing inside a trainer's chest,
## and a tether cable drawn across the whole frame from the world origin. Nothing
## failed, nothing was logged where anyone was looking, and the frame was simply
## wrong.
static func _placeable(parent: Node3D, what: String) -> bool:
	if parent != null and parent.is_inside_tree():
		return true
	push_error(("cannot build Team Tether's %s on a parent that is not in the scene tree. " % what)
		+ "Everything here is placed in world space; add the parent first.")
	return false


static func _material(colour: Color, emissive: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.55 if emissive else 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		mat.emission_enabled = true
		mat.emission = colour
		# Low. At 1.6 the tether cable rendered as a bright pink garden hose — the
		# accent blown out to white by its own glow, which is the opposite of a
		# reserved danger colour. It has to read as powered, not as neon.
		mat.emission_energy_multiplier = 0.35
	return mat


## --- the uniform -----------------------------------------------------------

## Hang Team Tether's colours on a character, as a tabard front and back.
##
## THIS REPLACED TINTING THE CHARACTER, and the frame that killed that idea is
## `shots/warden/01-the-three-of-them.png` from the first pass. The plan had been
## `pal_body._retint()`'s trick — duplicate the material and multiply its albedo
## by the accent, keeping the 2K texture underneath. It cannot work here, for a
## reason that is a fact about these models rather than a bug:
##
##   * The Styloo characters split their mesh into two surfaces BY TEXTURE ATLAS,
##     not by object. `art.json` already records this about the knight ("surface
##     1 holds the props and both legs"). `knightfirst` carries the tunic AND the
##     skin, so multiplying it by oxblood produced a trainer with a purple tunic
##     and BRIGHT RED HANDS AND FACE. A red-skinned man is not a uniform.
##   * A multiply can only ever darken. The mage's robe already ships near-black
##     plum, so multiplying it by a dark red produced black, and the boss lost his
##     silhouette entirely against the meadow's own shadows.
##
## A tabard fixes both by ADDING cloth rather than repainting a person, and it is
## also the more truthful thing: §3 asks that Team Tether not read as
## interchangeable villains, and three different people wearing the same flag is
## a better picture than three people dyed the same colour.
##
## It rides a BoneAttachment3D on the chest, so it moves with the animation. A
## panel parented to the model root would hang in the air the moment the trainer
## plays their send-out throw.
static func tabard(art: Node3D, colour_id: String = "tether_cloth") -> Node3D:
	if art == null:
		return null
	var skeleton := _skeleton(art)
	if skeleton == null:
		push_warning("a Team Tether trainer has no skeleton to hang a tabard on")
		return null
	# `DEF-spine.003` is where Rigify hangs the shoulders, which `art.json`'s
	# retarget map already picked out as the structural chest. All three Styloo
	# characters carry the whole `DEF-spine` chain, so this is not a per-model
	# name.
	const CHEST := "DEF-spine.003"
	if skeleton.find_bone(CHEST) < 0:
		push_warning("no '%s' bone; this character cannot wear Team Tether's colours" % CHEST)
		return null

	var mount := BoneAttachment3D.new()
	mount.name = "TetherTabard"
	skeleton.add_child(mount)
	mount.bone_name = CHEST

	var cloth := _material(DATA.accent(colour_id))
	# Sized in the SKELETON's units, which are the model's own — the character is
	# scaled to its declared height by `trainer_model._fit()` and this is a child
	# of the skeleton, so it scales with them and one size fits all three bodies.
	var span := _chest_span(skeleton)
	for side in [1.0, -1.0]:
		var panel := MeshInstance3D.new()
		var sheet := QuadMesh.new()
		# Chest to hip. The first pass was 1.15 x 2.6 span, which measured 15cm by
		# 34cm on the 1.80m knight — a bib, invisible at any distance the player
		# actually sees a trainer from. The BANNER is what reads at forty metres;
		# this is what identifies the person once you are close enough to talk to
		# them, and it has to survive being read at ten.
		sheet.size = Vector2(span * 1.5, span * 3.0)
		panel.mesh = sheet
		panel.material_override = cloth
		mount.add_child(panel)
		# Front and back, just clear of the body, hanging from the chest down.
		# Hung from just under the collar, and far enough off the spine to clear the
		# body. Three passes on this one number, all of them from looking at frames:
		# 0.9 span buried the panel inside the knight's tunic and showed two red
		# slivers at his ribs; 1.5 cleared him and left it visibly floating a hand's
		# width off the Warden's chest, because his span is larger AND his robe is
		# deeper, so the offset compounded twice. 1.15 clears the narrowest chest on
		# the road without standing off the widest.
		panel.position = Vector3(0.0, -span * 1.2, span * 1.15 * side)
		panel.rotation.y = 0.0 if side > 0.0 else PI
	return mount


## How wide this character's chest is, from the two upper-arm bones' rest poses.
##
## Measured rather than constanted, because the dwarf is 1.53m and the Warden is
## 1.96m and a tabard sized for one is a bib or a bedsheet on the other.
static func _chest_span(skeleton: Skeleton3D) -> float:
	var left := skeleton.find_bone("DEF-upper_arm.L")
	var right := skeleton.find_bone("DEF-upper_arm.R")
	if left < 0 or right < 0:
		return 0.22
	var apart: float = absf(
		skeleton.get_bone_global_rest(left).origin.x - skeleton.get_bone_global_rest(right).origin.x
	)
	return clampf(apart * 0.5, 0.08, 0.5)


static func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _skeleton(child)
		if found != null:
			return found
	return null


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## --- the banner ------------------------------------------------------------

## A pole with a hanging cloth. The cloth is the thing that reads at distance;
## the pole is there so it is not floating.
##
## `facing` is the direction the cloth's face is turned towards — the road, so a
## player walking up sees the flag rather than its edge. A banner seen edge-on is
## a stick.
static func banner(parent: Node3D, at: Vector3, facing: Vector3) -> Node3D:
	if not _placeable(parent, "banner"):
		return null
	var cfg: Dictionary = DATA.dress().get("banner", {})
	var root := Node3D.new()
	root.name = "TetherBanner"
	parent.add_child(root)
	root.global_position = at
	var flat := Vector3(facing.x, 0.0, facing.z)
	if flat.length() > 0.01:
		# GLOBAL, not local. Every position handed to this file is in world space,
		# and the parent is usually a trainer node that has been turned to face
		# down the road — so setting `rotation.y` here would add the post's yaw to
		# the banner's and hang every flag at a different angle from the one asked
		# for. It is the kind of mistake that looks like a deliberate arrangement.
		root.global_rotation = Vector3(0.0, atan2(flat.x, flat.z), 0.0)

	var height := float(cfg.get("pole_height", 3.4))

	var pole := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = float(cfg.get("pole_radius", 0.055))
	shaft.bottom_radius = shaft.top_radius
	shaft.height = height
	pole.mesh = shaft
	pole.material_override = _material(DATA.accent(str(cfg.get("pole_colour", "tether_iron"))))
	pole.position = Vector3(0.0, height * 0.5, 0.0)
	root.add_child(pole)

	var cloth := MeshInstance3D.new()
	var sheet := QuadMesh.new()
	sheet.size = Vector2(float(cfg.get("cloth_width", 0.95)), float(cfg.get("cloth_height", 1.9)))
	cloth.mesh = sheet
	cloth.material_override = _material(DATA.accent(str(cfg.get("cloth_colour", "tether_cloth"))))
	# Hung off one side of the pole and just under the top, the way a flag is,
	# rather than centred on it — a cloth bisected by its own pole reads as two
	# flags.
	cloth.position = Vector3(sheet.size.x * 0.5, height - sheet.size.y * 0.5 - 0.15, 0.0)
	root.add_child(cloth)
	return root


## --- the barricade ---------------------------------------------------------

## Kit pieces stood across the verge.
##
## `spread` is how wide the line is; the pieces repeat along it. Placed on the
## ground the caller gives, because a barricade that hovers is worse than none.
##
## LEFT THE COLOUR THEY WERE MADE. The first version painted every piece flat
## `tether_iron` and `shots/warden/03-the-dressing.png` shows what that produces:
## a black plastic crate and a black plastic fence, with the kit's timber grain,
## nail heads and edge wear all deleted by one albedo override. It also said the
## wrong thing. Team Tether did not ship a fort in — they nailed one onto
## somebody's road out of the village's own lumber, and the village's own lumber
## is exactly what these pieces are. The oxblood goes on the flag above the
## barricade, which is the part that is theirs.
##
## `Prop_Support` was in this list and is gone. It is a diagonal roof brace, and
## stood on the ground it renders as a large floating X — the same category error
## MA-05 called out when four windmill sails ended up bolted to the stronghold's
## curtain wall.
static func barricade(parent: Node3D, at: Vector3, along: Vector3, ground: Callable) -> Node3D:
	if not _placeable(parent, "barricade"):
		return null
	var cfg: Dictionary = DATA.dress().get("barricade", {})
	var paths: Array = cfg.get("pieces", [])
	if paths.is_empty():
		return null
	var root := Node3D.new()
	root.name = "TetherBarricade"
	parent.add_child(root)
	root.global_position = at

	var side := Vector3(along.x, 0.0, along.z)
	side = Vector3.RIGHT if side.length() < 0.01 else side.normalized()
	var spread := float(cfg.get("spread", 3.2))

	for i in paths.size():
		var path := str(paths[i])
		if not ResourceLoader.exists(path):
			push_warning("barricade piece missing: %s" % path)
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var piece: Node3D = packed.instantiate() as Node3D
		if piece == null:
			continue
		root.add_child(piece)
		var t := (float(i) / maxf(1.0, float(paths.size() - 1))) - 0.5
		var spot := at + side * (t * spread)
		spot.y = float(ground.call(spot.x, spot.z)) if ground.is_valid() else at.y
		if is_nan(spot.y):
			spot.y = at.y
		piece.global_position = spot
		# Global, for the reason `banner()` above gives. The small per-piece kick
		# is so a barricade reads as things dragged into place rather than as a
		# fence somebody surveyed.
		piece.global_rotation = Vector3(0.0, atan2(side.x, side.z) + deg_to_rad(float(i) * 11.0), 0.0)
	return root


## --- the tether ------------------------------------------------------------

## The machine that holds a creature: a drum on a footing.
static func pylon(parent: Node3D, at: Vector3) -> Node3D:
	if not _placeable(parent, "pylon"):
		return null
	var cfg: Dictionary = DATA.dress().get("pylon", {})
	var root := Node3D.new()
	root.name = "TetherPylon"
	parent.add_child(root)
	root.global_position = at

	var height := float(cfg.get("height", 2.6))
	var radius := float(cfg.get("radius", 0.55))
	var iron := _material(DATA.accent(str(cfg.get("colour", "tether_iron"))))

	var column := MeshInstance3D.new()
	var mast := CylinderMesh.new()
	mast.top_radius = radius * 0.45
	mast.bottom_radius = radius * 0.7
	mast.height = height
	column.mesh = mast
	column.material_override = iron
	column.position = Vector3(0.0, height * 0.5, 0.0)
	root.add_child(column)

	var footing := MeshInstance3D.new()
	var plinth := BoxMesh.new()
	plinth.size = Vector3(radius * 3.0, 0.35, radius * 3.0)
	footing.mesh = plinth
	footing.material_override = iron
	footing.position = Vector3(0.0, 0.17, 0.0)
	root.add_child(footing)

	var drum := MeshInstance3D.new()
	var spool := CylinderMesh.new()
	spool.top_radius = radius
	spool.bottom_radius = radius
	spool.height = 0.5
	drum.mesh = spool
	drum.material_override = iron
	drum.position = Vector3(0.0, height * 0.72, 0.0)
	drum.rotation.z = deg_to_rad(90.0)
	root.add_child(drum)
	return root


## One cable, sagging, from `from` to `to`. Returns the node so it can be moved
## or freed; `cut()` below is what the Warden's defeat does to it.
##
## Built as a chain of short cylinders rather than as a line, because a
## `MeshInstance3D` line has no thickness at distance and this has to read as a
## physical thing holding a creature down.
static func cable(parent: Node3D, from: Vector3, to: Vector3) -> Node3D:
	if not _placeable(parent, "cable"):
		return null
	var cfg: Dictionary = DATA.dress().get("pylon", {})
	var root := Node3D.new()
	root.name = "TetherCable"
	parent.add_child(root)

	var segments: int = maxi(2, int(cfg.get("cable_segments", 10)))
	var radius := float(cfg.get("cable_radius", 0.055))
	var sag := float(cfg.get("cable_sag", 0.18)) * from.distance_to(to)
	var live := _material(DATA.accent(str(cfg.get("cable_colour", "tether_live"))), true)

	var previous := from
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var point: Vector3 = from.lerp(to, t)
		# A parabola through the two ends, so the middle hangs.
		point.y -= sag * 4.0 * t * (1.0 - t)
		var axis := point - previous
		var length := axis.length()
		if length < 0.0001:
			previous = point
			continue

		var link := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = radius
		tube.bottom_radius = radius
		tube.height = length
		# A cheap tube, not a pipe. Twelve sides on a 5cm cable at twenty metres is
		# geometry nobody will ever resolve, times fourteen links times two cables.
		tube.radial_segments = 6
		tube.rings = 1
		link.mesh = tube
		link.material_override = live
		root.add_child(link)

		# BUILT AS A BASIS RATHER THAN WITH `look_at`.
		#
		# The first version positioned each link and then called `look_at` followed
		# by a 90-degree object-local roll to turn Godot's +Y cylinder onto the -Z
		# that `look_at` aims. `shots/warden/03-the-dressing.png` shows what came
		# out: three fat rods scattered around the pylon instead of a chain of
		# fourteen. Composing an orthonormal basis whose +Y IS the segment is not
		# a workaround for that — it is simply the thing the code was trying to
		# express, with no convention to get backwards.
		var up := axis / length
		var reference := Vector3.RIGHT if absf(up.dot(Vector3.UP)) > 0.99 else Vector3.UP
		var right := reference.cross(up).normalized()
		link.global_transform = Transform3D(
			Basis(right, up, right.cross(up).normalized()), (previous + point) * 0.5
		)
		previous = point
	return root


## The tether is cut. The cables go, and the machine that was running them goes
## dark — the ONE thing the reserved accent is allowed to stop meaning.
static func go_dark(node: Node3D) -> void:
	if node == null:
		return
	var dead := _material(DATA.accent("tether_iron"))
	for mesh in _mesh_instances(node):
		for surface in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(surface, dead)
		mesh.material_override = dead


## --- the collar ------------------------------------------------------------

## A band around a tethered creature, so the thing making it faster is visible on
## the thing that is faster.
##
## The whole difficulty argument in `warden_meadows.json` rests on the player
## being able to see WHY the Warden's creatures are quicker. A creature whose
## timings are silently multiplied is a creature that is inexplicably hard.
static func collar(body: Node3D, height: float, radius: float) -> Node3D:
	var ring := MeshInstance3D.new()
	ring.name = "TetherCollar"
	var band := TorusMesh.new()
	# A COLLAR, not a hoop. The first version was sized on the creature's whole
	# body radius and `shots/warden/07-a-trainer-battle.png` shows the result: a
	# glowing pink ring as wide as the Palehorn, floating at its shoulder like a
	# hula hoop, and the single loudest object in a frame whose subject was the
	# fight. A tether band sits on a neck and is a fraction of the animal.
	band.inner_radius = radius * 0.26
	band.outer_radius = radius * 0.38
	ring.mesh = band
	ring.material_override = _material(DATA.accent("tether_live"), true)
	body.add_child(ring)
	# High on the body, at the neck, and never at the feet — a ring on the ground
	# reads as a summoning circle.
	ring.position = Vector3(0.0, height * 0.86, 0.0)
	return ring
