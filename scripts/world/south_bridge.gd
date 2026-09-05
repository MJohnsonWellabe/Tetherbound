extends "res://scripts/world/gated_crossing.gd"

## SC14 — the South Bridge, spec §3's Gate 1.
##
## The whole mechanism lives in `gated_crossing.gd`, which this file was
## before `SE22` needed the same crossing built a second time over the river.
## What is left here is what is actually specific to this bridge: which
## `crossings[]` entry it is, which key opens it, and which flag remembers.
##
## Beating Oskar yields the South Bridge Key (`SC13`).

const TETHER_SIGIL := preload("res://scripts/world/tether_sigil.gd")

## GATE-1-HELD (G3-BAND1-FINISH-0904). The played-route blind judge
## (`ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` §3, §8.1 item 2), standing on
## the crossing itself rather than a posed survey stand: "a bare plank frame,
## half off-corner, no gate, no banner, no guard, for the chapter's first
## physical gate and the thing Team Tether is supposed to be holding."
##
## `gated_crossing.gd`'s own leaf (`south_bridge_gate`, building_prefabs.json)
## is the SAME `Prop_WoodenFence_*` two-course panel every ordinary field
## fence in the game already stands on — correct for a farm boundary, but it
## carries nothing that says a faction holds this crossing. That is the exact
## finding `road_gate.gd::_build_faction_gatehouse`/`_hang_sigil_banner`
## already answered once, at the Meadows Hall approach's own Sigil Gate
## (T1-HALL-3, JUDGE-5 finding D4: "no sigil, no banner, no gatehouse, no Team
## Tether mark of any kind"). Same mechanism reused here rather than
## reinvented — two posts, a lintel and the shared compass sigil
## (`tether_sigil.gd`, the one mark every Team Tether banner in the game
## carries) — but built at THIS crossing's own human scale (the deck rail
## stands 0.95m, the gate leaf ~1.4m) rather than copied at the Hall
## approach's 6.2m causeway-pier scale, which would read as a fortress
## dropped on a footbridge rather than as the same faction's checkpoint.
##
## Posts, lintel and banners are children of the crossing (`self`), never of
## `_mesh` (the swinging leaf) — the same reason `road_gate.gd`'s own piers
## are not children of ITS leaf: a gatehouse must stand still when the gate
## opens, not swing with it.
## GATE-1-HELD round 3: a blind pass on round 2's render measured this
## banner, rendered, at hue 5-12 degrees / saturation 65-79% / value 56-61% --
## 19-24 degrees of saturation and ~20 points of value brighter than the SAME
## judge's own direct sample of the key art's stronghold banners
## (`docs/reference/tetherbound-meadows-keyart.png`, region x520-1070 y600-930):
## hue 9, saturation 60%, value 39%. road_gate.gd's own `#6b2a20` is close to
## that target as a flat colour (H8/S70/V42), but `banner_cloth.gdshader`'s
## fold shading and this sun angle render it visibly brighter and more
## saturated than the reference. Set directly to the board's own measured
## value rather than road_gate.gd's flat-colour figure, since that figure was
## never checked against how it actually renders through this shader.
const FACTION_CLOTH := Color("#633128")
const POST_W := 0.34
## GATE-1-HELD round 2: a blind pass on the first render found the deck's own
## permanent parapet rail (`south_bridge` prefab, running the full 17.2m span
## at z=+-0.95) visibly passing through these posts — they were spaced off the
## gate LEAF's own width, which put them close enough to that separate,
## always-there rail to intersect it. Thinner (0.34 -> 0.22) and offset half a
## metre further toward the village than the leaf (`ARCH_X_OFFSET` below)
## rather than spaced off the leaf's own edge, so the archway clears both the
## leaf's picket rail (a different x) and the parapet rail (a thin enough
## post) instead of straddling either.
const POST_D := 0.22
const POST_H := 2.5
const LINTEL_H := 0.26
## Matches the parapet rail's own z line exactly, so the posts read as that
## rail's own gateposts rather than a second, competing rail line.
const ARCH_HALF_Z := 0.95
const ARCH_X_OFFSET := 0.5
const BANNER_W := 0.9
const BANNER_H := 1.55

## GATE-1-HELD follow-up (2026-09-04). The owner supplied real reference art
## for this checkpoint (`docs/art/reference/21_South_Bridge_Checkpoint_Gate.png`)
## and Meshy generated `south_bridge_gate.glb` from it — see
## `docs/specs/ASSET_LEDGER.md`'s "Riding Saddle and South Bridge Checkpoint
## Gate" entry, which named the trap this const's placement code has to dodge:
## the hero scan bakes ITS OWN closed double leaf into the same fused object
## as its posts, lintel and lanterns, but this crossing already stands a
## separate, independently-animated leaf (`_mesh`, `gated_crossing.gd`) that
## permanently swings open on the real unlock event. Standing both up loses
## either way — doubled leaves while shut, or a "ghost" closed leaf left
## standing once the player actually opens the gate.
##
## Kept safe by using the hero scan as PURE DRESSING in exactly the footprint
## the procedural posts/lintel/banners used to occupy, and retiring it the
## instant the crossing is genuinely unlocked (`_on_unlocked` below) — the
## real `_mesh` leaf is the one that swings; the hero dressing just stops
## being there to contradict it. The procedural gatehouse stays as the
## fallback if the model ever fails to load, per the D49 convention of never
## leaving a checkpoint with nothing standing over it.
const HERO_GATE_MODEL := "res://assets/environment/team_tether/south_bridge_gate.glb"
## The hero scan's own bounds run roughly 1 : 0.41 : 0.16 (width : height :
## depth, per the ledger's measurement) rather than the procedural
## gatehouse's near-square archway, so it is fit by HEIGHT against the
## existing posts rather than width — the dimension a player walking through
## actually reads, and the one the scan's own thin depth cannot distort.
const HERO_GATE_HEIGHT := POST_H + LINTEL_H
var _hero_gate: Node3D = null


func _init() -> void:
	super("south_bridge", "south_bridge_key", "south_bridge_open")


## Only extra this crossing has: the checkpoint standing over the gate
## `gated_crossing.gd::_build_gate` already built. `_mesh` is that gate's
## `GateLeaf`, already positioned and rotated by the time `build()` reaches
## this call.
func _build_extras(world: Node3D, prefabs: RefCounted, _deck_ground: float) -> void:
	if _mesh == null:
		return
	_build_checkpoint_gatehouse(prefabs)
	_build_occupation(world, prefabs)


## Retires the hero checkpoint dressing the instant the crossing is genuinely
## unlocked. See `HERO_GATE_MODEL`'s own header for why it cannot be left
## standing once `_mesh` (the real leaf) has swung open: it bakes in its own
## closed leaf, and leaving it up would read as the gate never having opened.
func _on_unlocked() -> void:
	if _hero_gate != null and is_instance_valid(_hero_gate):
		_hero_gate.queue_free()
	_hero_gate = null


## The archway stands ARCH_X_OFFSET further toward the village than the gate
## leaf itself, at the parapet rail's own z line — see ARCH_HALF_Z/ARCH_X_OFFSET's
## own header for why, after a first render put these posts through that rail.
func _build_checkpoint_gatehouse(prefabs: RefCounted) -> void:
	var arch_x: float = _mesh.position.x - ARCH_X_OFFSET
	var deck_y: float = _mesh.position.y

	if _build_hero_gate(prefabs, arch_x, deck_y):
		return

	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color("#4a3520")
	timber.roughness = 0.9

	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "CheckpointPost%s" % ("A" if side < 0.0 else "B")
		var post_box := BoxMesh.new()
		post_box.size = Vector3(POST_W, POST_H, POST_D)
		post.mesh = post_box
		post.material_override = timber
		post.position = Vector3(arch_x, deck_y + POST_H * 0.5, side * ARCH_HALF_Z)
		add_child(post)

		_hang_checkpoint_banner(Vector3(
			arch_x - (POST_W * 0.5 + 0.03),
			deck_y + POST_H - 0.2,
			side * ARCH_HALF_Z))

	var lintel := MeshInstance3D.new()
	lintel.name = "CheckpointLintel"
	var lintel_box := BoxMesh.new()
	lintel_box.size = Vector3(POST_D * 0.9, LINTEL_H, ARCH_HALF_Z * 2.0 + POST_W)
	lintel.mesh = lintel_box
	lintel.material_override = timber
	lintel.position = Vector3(arch_x, deck_y + POST_H - LINTEL_H * 0.5, 0.0)
	add_child(lintel)


## Tries to stand the generated hero mesh at the archway instead of the
## procedural posts/lintel/banners. Returns whether it actually did — a
## failed load falls back to the procedural gatehouse rather than leaving the
## checkpoint bare.
##
## `combined_aabb` reports the model's bounds in ITS OWN unscaled, unrotated
## local space (see that function's own header) — neither `hero.scale` nor
## `hero.rotation` factor into it, so both the fit and the final placement are
## worked out from that one raw measurement rather than re-measuring after
## each transform is applied.
func _build_hero_gate(prefabs: RefCounted, arch_x: float, deck_y: float) -> bool:
	if not ResourceLoader.exists(HERO_GATE_MODEL):
		return false
	var resource: Resource = load(HERO_GATE_MODEL)
	if not resource is PackedScene:
		return false
	var hero: Node3D = (resource as PackedScene).instantiate()
	if hero == null:
		return false
	hero.name = "CheckpointHero"
	add_child(hero)

	var raw_aabb: AABB = prefabs.call("combined_aabb", hero)
	if raw_aabb.size.y <= 0.0:
		hero.queue_free()
		return false

	var scale_factor: float = HERO_GATE_HEIGHT / raw_aabb.size.y
	hero.scale = Vector3.ONE * scale_factor
	# Yawed the same quarter turn `_mesh` (the real leaf) stands at — this
	# crossing's local +X is the village-to-far axis, and every object meant
	# to face across the deck rather than along it turns the same way.
	hero.rotation.y = deg_to_rad(90.0)

	var centre_scaled := (raw_aabb.position + raw_aabb.size * 0.5) * scale_factor
	var centre_rotated := centre_scaled.rotated(Vector3.UP, hero.rotation.y)
	var bottom_scaled_y: float = raw_aabb.position.y * scale_factor
	hero.position = Vector3(
		arch_x - centre_rotated.x,
		deck_y - bottom_scaled_y,
		-centre_rotated.z)

	_hero_gate = hero
	return true


## GATE-1-HELD round 2. A blind pass on round 1's flat-box banner (the same
## rigid-panel-plus-tails construction `road_gate.gd::_hang_sigil_banner`
## itself still uses) called it "flat vertical slabs... no cloth shape, no
## hanging rod, no hem, no taper, no fold" — which is exactly the "reads as a
## laminated sign" defect JUDGE-6 found on the HALL's own banners before
## `stronghold.gd::_hang_banner` replaced six rigid boxes with one subdivided
## plane wearing `banner_cloth.gdshader` (the field, both swallow tails, the V
## notch, the selvage, the hem and the faction device, all baked into the
## shader rather than assembled from separate meshes, with a real per-vertex
## sway). That shader is generic — not Hall-specific, just parked under
## `assets/environment/team_tether/hall/` — so it is reused directly here
## rather than re-implementing rigid boxes a second time at a second scale.
##
## Local +X here is the crossing's own village-to-far axis
## (`gated_crossing.gd::build`'s own `_across`), so an approaching player —
## who walks from more-negative X toward this gate — sees the banner's `-X`
## face first, and that is the face the device rides. Mirrors
## `stronghold.gd::_hang_banner`'s own local frame exactly, but rotated the
## other way: that file's holder faces +X outward, this one faces -X, so the
## quad's local +Z (its natural forward) is turned -90 degrees here instead
## of +90.
const BANNER_CLOTH_SHADER := preload("res://assets/environment/team_tether/hall/banner_cloth.gdshader")
const BANNER_CLOTH_T := 0.05
var _banners_hung := 0


func _hang_checkpoint_banner(at: Vector3) -> void:
	var holder := Node3D.new()
	# Numbered: a second child named "CheckpointBanner" is silently renamed
	# by the tree to "@CheckpointBanner@N", which is how `smoke_traversal`'s
	# banner count first came back as one of two.
	_banners_hung += 1
	holder.name = "CheckpointBanner%d" % _banners_hung
	holder.position = at
	add_child(holder)

	var bar := MeshInstance3D.new()
	bar.name = "BannerBar"
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3(0.09, 0.09, BANNER_W * 1.16)
	bar.mesh = bar_box
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color("#4a3520")
	bar_mat.roughness = 0.9
	bar.material_override = bar_mat
	bar.position = Vector3(-BANNER_CLOTH_T * 2.0, 0.0, 0.0)
	holder.add_child(bar)

	var quad := QuadMesh.new()
	quad.size = Vector2(BANNER_W, BANNER_H)
	quad.subdivide_width = 6
	quad.subdivide_depth = 14
	var panel := MeshInstance3D.new()
	panel.name = "BannerCloth"
	panel.mesh = quad
	panel.material_override = _banner_cloth_material(FACTION_CLOTH, Vector2(BANNER_W, BANNER_H), at)
	panel.position = Vector3(-BANNER_CLOTH_T, -BANNER_H * 0.5 - 0.09, 0.0)
	panel.rotation.y = -PI * 0.5
	holder.add_child(panel)


## One shader material per banner, same recipe `stronghold.gd::
## _banner_cloth_material` uses: the sway phase seeded off the banner's own
## position so the two banners on this gate never move in step.
func _banner_cloth_material(colour: Color, size: Vector2, at: Vector3) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = BANNER_CLOTH_SHADER
	m.set_shader_parameter("colour", colour)
	m.set_shader_parameter("selvage_colour", colour.darkened(0.34))
	m.set_shader_parameter("device_colour", colour.lerp(Color("#e8ddc4"), 0.86))
	m.set_shader_parameter("device_tex", TETHER_SIGIL.texture())
	m.set_shader_parameter("use_device", 1.0)
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("tails", 2.0)
	m.set_shader_parameter("phase", fposmod(at.x * 1.7 + at.z * 0.9 + at.y * 0.4, TAU))
	m.set_shader_parameter("sway", clampf(0.05 * size.y, 0.08, 0.32))
	m.set_shader_parameter("speed", clampf(2.4 / maxf(size.y, 1.0), 0.6, 1.6))
	return m


## W22-BRIDGE-SIGNPOST-0904, closure plan CL-B3's in-rules half: the South
## Bridge as a HELD crossing from the approach. The generated checkpoint gate
## (`HERO_GATE_MODEL`, PR #39) stands over the leaf, but on its own it is a
## gate -- the played-route judge's list was "no gate, no banner, no guard",
## and a gate with nobody at it and nothing beside it still reads as shut,
## not held. Everything here is dressing in front of the archway on the
## VILLAGE side, where the player actually stands when the objective says
## "Team Tether holds the crossing":
##
##   * two staked oxblood banners flanking the road (the only oxblood at this
##     crossing -- palette.json's reservation; the same cloth shader and
##     sigil the checkpoint's own procedural fallback hangs);
##   * a barricade -- crossed-timber frames on each shoulder, with the
##     faction's crates and a barrel stacked against the archway -- built
##     from primitives and the already-vendored fantasy props, and set on
##     the SHOULDERS, never across the deck, so the real leaf stays the one
##     thing that shuts the road and an opened gate is an open road;
##   * a lantern on a post with the faint teal of Team Tether's own energy
##     (`palette.json` `tether_teal`, reserved for live faction machinery);
##   * a posted grunt from the installed rig, placed through
##     `village_npcs.gd` with the same set-dressing spec shape
##     `relay_site.json`'s "Relay Sentry" uses -- no greeting, so no prompt
##     (INTERACT-SWEEP-0903's rule) -- who stands down once the crossing is
##     genuinely opened (`place_when: unless_flag south_bridge_open`), the
##     same way the relay's sentries leave a dead station.
##
## The barricade, banners and lantern stay after the gate opens: the
## crossing WAS held, and the evidence of it is the story the player walked
## through. Only the body that would contradict an open gate leaves.
## `docs/decisions/D86-the-south-bridge-is-held-from-the-approach.md`.
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const OCCUPATION_CONFIG := "res://data/config/south_bridge_dressing.json"
const FANTASY_PROPS := "res://assets/props/quaternius_fantasy"
const PALETTE_PATH := "res://data/config/palette.json"
## How far in front of the archway (toward the village) each piece stands,
## and how far off the road's centreline. The road is 3m wide with a 1.5m
## shoulder; `tests/smoke_traversal.gd` walks a body straight down z=0, so
## nothing here sits inside |z| < 1.5. TUNABLE.
const BANNER_BACK := 2.2
const BANNER_SIDE := 2.7
const BANNER_POLE_H := 3.3
const BARRICADE_BACK := 3.4
const BARRICADE_SIDE := 2.4
const BARRICADE_LENGTH := 1.8
const LANTERN_BACK := 1.5
const LANTERN_SIDE := 2.0
const LANTERN_POST_H := 2.15
const OCCUPATION_TIMBER := Color("#4a3520")
const OCCUPATION_IRON := Color("#2b2a2e")
var _occupation: Node3D = null


func _build_occupation(world: Node3D, prefabs: RefCounted) -> void:
	var arch_x: float = _mesh.position.x - ARCH_X_OFFSET
	_occupation = Node3D.new()
	_occupation.name = "Occupation"
	add_child(_occupation)

	for side: float in [-1.0, 1.0]:
		_stake_banner(world, Vector2(arch_x - BANNER_BACK, side * BANNER_SIDE))
		_build_barricade(world, Vector2(arch_x - BARRICADE_BACK, side * BARRICADE_SIDE), side)
	_build_lantern(world, Vector2(arch_x - LANTERN_BACK, LANTERN_SIDE))
	_stack_stores(world, prefabs, arch_x)
	_post_sentry(world)


## Ground under a point given in this crossing's own local metres, as a
## local y (the node's origin already sits at the levelled deck ground).
## Never a raycast (D09): the same `ground_height_at` climb `build()` uses.
func _local_ground(world: Node3D, local_xz: Vector2) -> float:
	var at := global_transform * Vector3(local_xz.x, 0.0, local_xz.y)
	var ground: float = float(world.call("ground_height_at", at.x, at.z))
	if is_nan(ground):
		return 0.0
	return ground - global_position.y


func _stake_banner(world: Node3D, local_xz: Vector2) -> void:
	var y := _local_ground(world, local_xz)
	var pole := MeshInstance3D.new()
	pole.name = "BannerPole"
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.045
	shaft.bottom_radius = 0.06
	shaft.height = BANNER_POLE_H
	shaft.radial_segments = 8
	pole.mesh = shaft
	var timber := StandardMaterial3D.new()
	timber.albedo_color = OCCUPATION_TIMBER
	timber.roughness = 0.9
	pole.material_override = timber
	pole.position = Vector3(local_xz.x, y + BANNER_POLE_H * 0.5, local_xz.y)
	_occupation.add_child(pole)
	# The cloth hangs from a bar just below the pole's crown, on the face an
	# approaching player sees first (-X, see `_hang_checkpoint_banner`).
	_hang_checkpoint_banner(Vector3(local_xz.x - 0.06, y + BANNER_POLE_H - 0.12, local_xz.y))


## A cheval-de-frise: one beam on two crossed-leg trestles, the X facing the
## road so it reads as a barrier from the approach. Solid -- a barricade a
## player walks through is the hologram village.gd's header warns about.
func _build_barricade(world: Node3D, local_xz: Vector2, side: float) -> void:
	var y := _local_ground(world, local_xz)
	var frame := Node3D.new()
	frame.name = "Barricade_%s" % ("A" if side < 0.0 else "B")
	frame.position = Vector3(local_xz.x, y, local_xz.y)
	# A few degrees off square, each its own way: dragged into place, not
	# tiled.
	frame.rotation.y = deg_to_rad(6.0 * side)
	_occupation.add_child(frame)

	var timber := StandardMaterial3D.new()
	timber.albedo_color = OCCUPATION_TIMBER.lightened(0.08)
	timber.roughness = 0.92

	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var beam_box := BoxMesh.new()
	beam_box.size = Vector3(0.14, 0.14, BARRICADE_LENGTH)
	beam.mesh = beam_box
	beam.material_override = timber
	beam.position = Vector3(0.0, 0.66, 0.0)
	frame.add_child(beam)

	for end: float in [-1.0, 1.0]:
		for lean: float in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			leg.name = "Leg"
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.09, 1.5, 0.09)
			leg.mesh = leg_box
			leg.material_override = timber
			leg.position = Vector3(0.0, 0.6, end * (BARRICADE_LENGTH * 0.5 - 0.12))
			leg.rotation.z = deg_to_rad(34.0 * lean)
			frame.add_child(leg)

	var body := StaticBody3D.new()
	body.name = "BarricadeCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.3, BARRICADE_LENGTH)
	shape.shape = box
	shape.position = Vector3(0.0, 0.65, 0.0)
	body.add_child(shape)
	frame.add_child(body)


## A post lantern with Team Tether's own faint teal in it: the one light on
## the crossing, and the one colour that says whose it is at night.
func _build_lantern(world: Node3D, local_xz: Vector2) -> void:
	var y := _local_ground(world, local_xz)
	var lantern := Node3D.new()
	lantern.name = "Lantern"
	lantern.position = Vector3(local_xz.x, y, local_xz.y)
	_occupation.add_child(lantern)

	var iron := StandardMaterial3D.new()
	iron.albedo_color = OCCUPATION_IRON
	iron.roughness = 0.7
	iron.metallic = 0.15

	var post := MeshInstance3D.new()
	post.name = "Post"
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.035
	shaft.bottom_radius = 0.05
	shaft.height = LANTERN_POST_H
	shaft.radial_segments = 8
	post.mesh = shaft
	post.material_override = iron
	post.position = Vector3(0.0, LANTERN_POST_H * 0.5, 0.0)
	lantern.add_child(post)

	# The arm reaches toward the road (-z here is toward the centreline for
	# the +z shoulder this stands on), so the light hangs over the way in.
	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var arm_box := BoxMesh.new()
	arm_box.size = Vector3(0.05, 0.05, 0.5)
	arm.mesh = arm_box
	arm.material_override = iron
	arm.position = Vector3(0.0, LANTERN_POST_H - 0.05, -0.22)
	lantern.add_child(arm)

	var hang := Node3D.new()
	hang.name = "Lamp"
	hang.position = Vector3(0.0, LANTERN_POST_H - 0.32, -0.42)
	lantern.add_child(hang)

	var cage := MeshInstance3D.new()
	cage.name = "Cage"
	var cage_box := BoxMesh.new()
	cage_box.size = Vector3(0.2, 0.3, 0.2)
	cage.mesh = cage_box
	var cage_mat := StandardMaterial3D.new()
	cage_mat.albedo_color = OCCUPATION_IRON
	cage_mat.roughness = 0.75
	cage_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cage_mat.albedo_color.a = 0.55
	cage.material_override = cage_mat
	hang.add_child(cage)

	var teal := _palette_colour("tether_teal", Color("#3fe8c4"))
	var core := MeshInstance3D.new()
	core.name = "Core"
	var core_box := BoxMesh.new()
	core_box.size = Vector3(0.13, 0.2, 0.13)
	core.mesh = core_box
	var glow := StandardMaterial3D.new()
	glow.albedo_color = teal.darkened(0.45)
	glow.emission_enabled = true
	glow.emission = teal
	glow.emission_energy_multiplier = 1.4
	core.material_override = glow
	hang.add_child(core)

	var roof := MeshInstance3D.new()
	roof.name = "Roof"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.17
	cone.height = 0.12
	cone.radial_segments = 4
	roof.mesh = cone
	roof.material_override = iron
	roof.position = Vector3(0.0, 0.2, 0.0)
	hang.add_child(roof)

	var light := OmniLight3D.new()
	light.name = "Glow"
	light.light_color = teal
	# Faint: enough to tint the archway post beside it after dark, never a
	# floodlight -- the pylons' own glow is the loud one.
	light.light_energy = 0.7
	light.omni_range = 5.5
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	hang.add_child(light)


## Crates and a barrel stacked against the archway's village-side face, off
## the deck: what a post that expects to stay looks like.
func _stack_stores(world: Node3D, prefabs: RefCounted, arch_x: float) -> void:
	var stores := [
		{"model": "Crate_Wooden", "at": Vector2(arch_x - 0.7, 3.9), "yaw": 14.0},
		{"model": "Crate_Wooden", "at": Vector2(arch_x - 0.75, 3.85), "yaw": -9.0, "lift": 1.2},
		{"model": "Barrel", "at": Vector2(arch_x - 1.9, 3.75), "yaw": 40.0},
		{"model": "Rope_1", "at": Vector2(arch_x - 0.6, -3.7), "yaw": 70.0},
		{"model": "Crate_Wooden", "at": Vector2(arch_x - 1.7, -3.9), "yaw": -22.0},
	]
	for entry: Variant in stores:
		var spec: Dictionary = entry
		var path := "%s/%s.gltf" % [FANTASY_PROPS, str(spec["model"])]
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		var prop: Node3D = scene.instantiate() as Node3D
		if prop == null:
			continue
		prop.name = "Store_%s" % str(spec["model"])
		var at: Vector2 = spec["at"]
		var y := _local_ground(world, at) + float(spec.get("lift", 0.0)) - 0.02
		prop.position = Vector3(at.x, y, at.y)
		prop.rotation.y = deg_to_rad(float(spec.get("yaw", 0.0)))
		_occupation.add_child(prop)
		var aabb: AABB = prefabs.call("combined_aabb", prop)
		if aabb.size.y > 0.3:
			var body := StaticBody3D.new()
			body.name = "StoreCollision"
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = aabb.size
			shape.shape = box
			shape.position = aabb.position + aabb.size * 0.5
			body.add_child(shape)
			prop.add_child(body)


## The posted grunt. `village_npcs.gd` places from a config file in WORLD
## metres and finds its ground by climbing to the nearest `ground_height_at`
## -- which, as a `top_level` child here, is the world's, not this
## crossing's yawed local frame. The config carries the placement and the
## `place_when` gate; nothing about him is decided in code.
func _post_sentry(world: Node3D) -> void:
	if not ResourceLoader.exists(OCCUPATION_CONFIG) and not FileAccess.file_exists(OCCUPATION_CONFIG):
		push_warning("%s missing; the South Bridge has no sentry" % OCCUPATION_CONFIG)
		return
	var sentries: Node3D = VILLAGE_NPCS.new()
	sentries.name = "Sentries"
	sentries.top_level = true
	_occupation.add_child(sentries)
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	sentries.call("build", player, OCCUPATION_CONFIG)


func _palette_colour(key: String, fallback: Color) -> Color:
	var file := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return fallback
	for section: Variant in (parsed as Dictionary).values():
		if section is Dictionary and (section as Dictionary).has(key):
			return Color(str((section as Dictionary)[key]))
	return fallback

