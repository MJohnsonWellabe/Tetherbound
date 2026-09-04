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
const FACTION_CLOTH := Color("#6b2a20")
const POST_W := 0.34
const POST_D := 0.34
const POST_H := 2.5
const LINTEL_H := 0.26
const BANNER_W := 0.72
const BANNER_H := 1.7
const BANNER_T := 0.05


func _init() -> void:
	super("south_bridge", "south_bridge_key", "south_bridge_open")


## Only extra this crossing has: the checkpoint standing over the gate
## `gated_crossing.gd::_build_gate` already built. `_mesh` is that gate's
## `GateLeaf`, already positioned and rotated by the time `build()` reaches
## this call.
func _build_extras(_world: Node3D, prefabs: RefCounted, _deck_ground: float) -> void:
	if _mesh == null:
		return
	_build_checkpoint_gatehouse(prefabs)


## The gate leaf's own local frame (`combined_aabb`, pre-rotation) has its
## width along local X — `_build_gate` then yaws the leaf 90° so that width
## stands ACROSS the deck, i.e. along the CROSSING's own local Z. `aabb.size.x`
## is therefore the right number to space these posts along Z, even though it
## is not the axis it looks like on the leaf's own aabb.
func _build_checkpoint_gatehouse(prefabs: RefCounted) -> void:
	var aabb: AABB = prefabs.call("combined_aabb", _mesh)
	var gate_x: float = _mesh.position.x
	var half: float = aabb.size.x * 0.5 + POST_W * 0.5
	var deck_y: float = _mesh.position.y

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
		post.position = Vector3(gate_x, deck_y + POST_H * 0.5, side * half)
		add_child(post)

		_hang_checkpoint_banner(Vector3(
			gate_x - (POST_W * 0.5 + BANNER_T * 0.5 + 0.02),
			deck_y + POST_H - 0.35,
			side * half))

	var lintel := MeshInstance3D.new()
	lintel.name = "CheckpointLintel"
	var lintel_box := BoxMesh.new()
	lintel_box.size = Vector3(POST_D * 0.9, LINTEL_H, half * 2.0 + POST_W)
	lintel.mesh = lintel_box
	lintel.material_override = timber
	lintel.position = Vector3(gate_x, deck_y + POST_H - LINTEL_H * 0.5, 0.0)
	add_child(lintel)


## The same three-piece cloth `road_gate.gd::_hang_sigil_banner` hangs at the
## Sigil Gate (a field, two tails, the shared compass device), at this
## bridge's own smaller scale. Local +X here is the crossing's own
## village-to-far axis (`gated_crossing.gd::build`'s own `_across`), so an
## approaching player — who walks from more-negative X toward this gate — sees
## the banner's `-X` face first, and that is the face the device rides.
func _hang_checkpoint_banner(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "CheckpointBanner"
	holder.position = at
	add_child(holder)

	var cloth := TETHER_SIGIL.cloth_material(FACTION_CLOTH)
	var body_h := BANNER_H * 0.76
	var panel := MeshInstance3D.new()
	panel.name = "BannerCloth"
	var panel_box := BoxMesh.new()
	# Thin along X (the crossing's line of travel, and this banner's outward
	# normal), wide along Z (across the deck, beside the post it hangs from).
	panel_box.size = Vector3(BANNER_T, body_h, BANNER_W)
	panel.mesh = panel_box
	panel.material_override = cloth
	panel.position = Vector3(0.0, -body_h * 0.5, 0.0)
	holder.add_child(panel)

	# Bleached linen tinting the MARK, not a lightened panel behind it —
	# `tether_sigil.gd`'s field is transparent, exactly as `road_gate.gd`'s own
	# sigil banner and `stronghold.gd::_hang_banner`'s Hall banners read it.
	var device := TETHER_SIGIL.device(
		Vector2(BANNER_W * 0.66, body_h * 0.6),
		FACTION_CLOTH.lerp(Color("#e8ddc4"), 0.86),
		Vector3.LEFT, BANNER_T * 0.62)
	device.position += Vector3(0.0, -body_h * 0.46, 0.0)
	holder.add_child(device)

	var tail_h := BANNER_H - body_h
	for side: float in [-1.0, 1.0]:
		var tail := MeshInstance3D.new()
		tail.name = "BannerTail"
		var tail_box := BoxMesh.new()
		tail_box.size = Vector3(BANNER_T, tail_h, BANNER_W * 0.42)
		tail.mesh = tail_box
		tail.material_override = cloth
		tail.position = Vector3(0.0, -body_h - tail_h * 0.5, side * BANNER_W * 0.29)
		holder.add_child(tail)
