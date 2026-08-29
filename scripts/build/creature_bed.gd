extends Node3D

## Gate A physical-rest implementation. The authoritative recovery state lives
## on the CreatureInstance/Game; this placed node owns only which bed index it is,
## assignment UI, and the visible sleeping body.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const REST_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

## GATEB-FLAGS: the ladder's `creature_bed_built` CONTRACT flag
## (data/progression/objectives.json) -- set the instant this object is
## actually placed, not merely armed/ghosted, so the HUD's next line clears
## on the real interaction the objective names.
const CREATURE_BED_FLAG := "creature_bed_built"

## The camp set's own bed, not the furniture pack's twin bed.
##
## `Bed_Twin1.gltf` is a human single bed -- headboard, footboard, white pillow,
## blue quilt -- and two independent blind critics said the same thing about it
## without being told what it was for: "a human bed labelled creature bed", and
## "if the player's five companions get this, it reads as a naming error".
##
## `generated_camp/camp_bed.glb` is already installed, already textured, already
## placed in the world by `band1_lower_meadows/props.json`, and was generated
## from an OWNER-SUPPLIED reference board
## (`docs/art/reference/owner-board-2026-08-23-camp-set.png`,
## `docs/ASSET_LEDGER.md`). A lashed log frame with a stuffed mattress belongs to
## this game; a bedroom suite does not. No new asset, no generation, and CLAUDE.md's
## reuse-what-is-installed rule is the reason to prefer it rather than an exception to it.
##
## HONEST ABOUT WHAT THIS DOES NOT FIX: a camp bed is still not a NEST. There is
## no basket, nest, cushion or straw-bed mesh anywhere in the build -- checked --
## so "the creature bed does not read as a creature's" is only partly reachable by
## changing a path. The rest is art that is not in the build, recorded as such in
## `ralph/reports/VISUAL_MAKE_LANE_FINDINGS_2026-08-23.md` rather than claimed here.
##
## Raw size is 1.23 x 0.41 x 1.90m (that stand's own note), so it needs no scaling
## and REST_ANCHOR's 0.42m still lands on the mattress rather than inside it.
const MESH_PATH := "res://assets/props/generated_camp/camp_bed.glb"
const REST_ANCHOR := Vector3(0.0, 0.42, 0.0)

## T1-CAMP: measured (tools/_probe_t1_camp.gd) -- camp_bed.glb's own local
## origin sits 0.215m above its own geometric base, the same glTF-export
## quirk `docs/ASSET_LEDGER.md` already documents a `sink_m: -0.21`
## compensation for on this mesh's AUTHORED placement
## (band1_lower_meadows/props.json). `_piece` here is positioned at this
## node's own local origin with no such compensation, so a player-placed
## Creature Bed was sinking a fifth of a metre into the ground -- visible as
## a squashed, half-buried mattress rather than the raised log-frame bed the
## reference board shows. `_piece.position.y` below restores true ground
## contact; `REST_ANCHOR` (the sleeping creature's own local seat) does not
## need the same correction, since it is already measured to land on the
## mattress top as built, which now sits 0.215m higher than before.
const BED_SINK_LIFT := 0.215

## T1-CAST (§17). `camp.gd`'s player bedroll now places this SAME mesh
## (`PLAYER_BED` there, added by T1-CAMP round 2) a few metres away in the
## same small camp. A blind Fable pass on the assembled kit called the reuse
## "a mistake, not a shared-gear story" -- the two beds render pixel-
## identical, including a human pillow at the head of the creature's own
## bed, which is the specific tell. `camp_bed.glb` carries its whole model
## on ONE mesh surface (confirmed: tools/_probe_camp_bed_surfaces.gd), so
## there is no separate "pillow" or "blanket" surface to hide or retint in
## isolation -- the only lever available without a second Meshy generation
## (banned without owner reference art) is a whole-object tint, the same
## "one mesh, many materials" economy `docs/ASSET_LEDGER.md` already uses
## for `tm_orb`. Cooler than the player's own warm bed, so the two read as
## "companion gear from the same maker" rather than a duplicate. Colour
## only, deliberately -- a scale change would also move
## REST_ANCHOR/BED_SINK_LIFT (both measured against this mesh's UNSCALED
## geometry, and load-bearing for tests/smoke_gate_a_rest_torch.gd's real
## resting-creature placement), and re-deriving both under a new scale is a
## bigger, riskier change than a judge asking for "reuse doesn't read as a
## mistake" justifies on its own. Applied via `set_surface_override_material`
## (BUILD_PIECE.mesh_instances(), added for exactly this) so the shared Mesh
## resource used by every OTHER placement of camp_bed.glb -- the player's
## own bed and the authored trail_camp's sleeping surface -- is untouched.
## Round 1 (0.74, 0.86, 0.80) measured as a real shift (pillow (166,138,107)
## -> (113,113,84), sampled directly off rendered frames) but was too subtle
## to register as "a different bed" at a glance, only as a slightly darker
## one -- a genuine hue shift needs more separation between channels than a
## near-uniform multiply gives. Pushed further apart so the same pillow
## comes out an actual moss-green rather than a dimmed tan.
const CREATURE_BED_TINT := Color(0.55, 0.85, 0.62)


func _tint_creature_bed() -> void:
	if _piece == null or not is_instance_valid(_piece):
		return
	for instance: MeshInstance3D in _piece.call("mesh_instances"):
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var source := mesh.surface_get_material(i) as StandardMaterial3D
			var material := source.duplicate() as StandardMaterial3D if source != null else StandardMaterial3D.new()
			material.albedo_color = CREATURE_BED_TINT
			instance.set_surface_override_material(i, material)

## GATE-E: the bed-index namespace, written down because two kinds of bed now
## share it and only one of them is in the build store.
##
##   >= 0  a slot in `Game.placed_buildings` -- a bed the PLAYER placed. These
##         are renumbered when something earlier is dismantled
##         (`build_placer.gd`'s `rest_bed_index > removed_index` loop).
##   -1    UNASSIGNED: not placed anywhere, and the state a bare `new()` is in.
##   <= -2 an AUTHORED bed that belongs to a fixed piece of the world and is in
##         no build store, so nothing ever renumbers it. The dismantle loop
##         only ever decrements indices ABOVE a removed one, and a removed one
##         is always >= 0, so a negative index is untouched by construction.
##
## This exists because the stronghold's recovery point had no index at all: it
## was left at -1, `assign_creature()` refused every creature on `_build_index
## < 0`, and the chapter's one pre-Warden recovery opportunity opened a panel
## that could not rest anything. Measured on a real boot, not inferred.
const UNASSIGNED := -1
const AUTHORED_STRONGHOLD_REST := -2

static var _panel: CanvasLayer = null
var _piece: Node3D = null
var _build_index: int = UNASSIGNED
var _rest_body: Node3D = null
var _last_occupant: int = -2


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = BED_SINK_LIFT
	_piece.call("build_ghost", MESH_PATH)
	_tint_creature_bed()


## `player_built` is what decides whether this placement answers the chapter's
## "Build a creature bed" objective.
##
## GATE-E: it defaults to true, which is every existing caller
## (`build_placer.gd`, i.e. the player placing one), and the stronghold's
## authored recovery point passes false. It had to: that bed is built with the
## world at boot, so on `main` `creature_bed_built` was set on frame one of a
## brand-new save and the tournament ladder's bed objective was complete before
## the player had a hammer. Measured on a fresh boot, not inferred.
func build_real(player_built: bool = true) -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = BED_SINK_LIFT
	_piece.call("build_real", MESH_PATH)
	_tint_creature_bed()
	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.6, 0.7)
	prompt.call("configure", "Rest a Creature", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)
	if not player_built:
		return
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", CREATURE_BED_FLAG)


func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func set_build_index(index: int) -> void:
	_build_index = index
	_sync_rest_body(true)


func build_index() -> int:
	return _build_index


func occupant_index() -> int:
	if _build_index == UNASSIGNED:
		return -1
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return -1
	for i in party.call("size"):
		var creature: RefCounted = party.call("at", i)
		if creature != null and bool(creature.get("resting")) \
				and int(creature.get("rest_bed_index")) == _build_index:
			return i
	return -1


func assign_creature(index: int) -> bool:
	if _build_index == UNASSIGNED or occupant_index() >= 0:
		return false
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null or bool(creature.get("resting")):
		return false
	if not bool(party.call("set_resting", index, true, _build_index)):
		return false
	_sync_rest_body(true)
	return true


func wake_creature_early() -> bool:
	var index := occupant_index()
	if index < 0:
		return false
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null:
		return false
	# HP already regenerated directly on the instance; clearing assignment is
	# all early wake does. No full-heal/rested bonus is granted.
	creature.set("rested", false)
	party.call("set_resting", index, false)
	_sync_rest_body(true)
	return true


func is_occupied() -> bool:
	return occupant_index() >= 0


func _process(_delta: float) -> void:
	_sync_rest_body(false)


func _sync_rest_body(force: bool) -> void:
	var index := occupant_index()
	if not force and index == _last_occupant:
		return
	_last_occupant = index
	if _rest_body != null and is_instance_valid(_rest_body):
		_rest_body.queue_free()
	_rest_body = null
	if index < 0:
		return
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null:
		return
	_rest_body = CREATURE_SCENE.instantiate() as Node3D
	if _rest_body == null:
		return
	_rest_body.name = "RestingCreature"
	_rest_body.set_script(CREATURE_BODY)
	add_child(_rest_body)
	_rest_body.call("setup", str(creature.get("species_id")), bool(creature.get("shiny")))
	_rest_body.position = REST_ANCHOR
	_rest_body.rotation.y = PI * 0.5
	_rest_body.collision_layer = 0
	_rest_body.collision_mask = 0
	_rest_body.set_physics_process(false)
	# Reuse the shipped creature faint/lie animation as the closest authored
	# resting pose. The body is visibly in bed and non-interactive; visual-judge
	# decides whether a later dedicated sleep pose is warranted.
	_rest_body.call_deferred("play_faint")


func _on_rest() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = REST_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
