extends Node3D

## A physical Realm Heart shrine.
##
## State belongs to `Game.realm_hearts` and `Game.progression`, never to this
## scene node.  The shrine is only their world-facing interaction and visual,
## which means rebuilding the scene or loading a save cannot duplicate a Heart
## or forget which power is active.
##
## Integration contract (`autoload/game_state.gd` owns both objects):
##
##   Game.realm_hearts.is_earned(heart_id, Game.progression) -> bool
##   Game.realm_hearts.is_placed(heart_id, Game.progression) -> bool
##   Game.realm_hearts.place(heart_id, Game.progression) -> bool
##   Game.realm_hearts.activate(heart_id, Game.progression) -> bool
##   Game.realm_hearts.clear_active()
##   Game.realm_hearts.active_id() -> String
##
## All geometry is made from engine primitives.  It deliberately introduces no
## second prop family and can be replaced later without changing its state API.
##
## ## Stage B lane 5.B: earned and placed are the WORLD's, active is YOURS
##
## D103. Setting a Heart into its socket is a consequential world mutation, so
## it is no longer a write this node makes: it is a `set_world_flag` INTENT
## submitted to `Game.ledger`, exactly as `alpha_pins.gd::clear_alpha()` submits
## a beaten alpha. Solo and the host commit it in-process and the delta lands
## before `submit()` returns; a client is told `pending` and the flag arrives
## when the host has committed it, at which point `ledger_rpc.gd` sweeps the
## `progression_restore` group -- which this node joins in `_ready()` -- and the
## shrine every peer is standing at repaints itself. That is the deliverable:
## one player places a Heart and BOTH see it placed.
##
## ACTIVATING is the opposite and deliberately so. `realm_hearts._active_id`
## lives on the PLAYER half of the state split (`MP_STATE_SEAM.md` §2:
## `PlayerState.save_data()` carries `realm_hearts`), it is never submitted to
## the ledger, and nothing here replicates it. Two peers standing at the same
## socket can be running two different relic powers, and that is the point --
## the Heart is placed in the world once, and each trainer chooses for
## themselves whether to wear its power.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const STATE_UNEARNED := "unearned"
const STATE_EARNED_UNPLACED := "earned_unplaced"
const STATE_PLACED_INACTIVE := "placed_inactive"
const STATE_ACTIVE := "active"

const STONE := Color("657166")
const STONE_DARK := Color("303a35")
const HEART_DORMANT := Color("75a36d")
const HEART_READY := Color("a9d477")
const HEART_ACTIVE := Color("d7f59a")

@export var heart_id: String = "meadows"
@export var heart_name: String = "Heart of the Meadows"
@export var interaction_radius: float = 3.6
## The realm this shrine's RECORD belongs to, stamped onto every intent it
## submits. D97: never `Game.current_realm` -- from Wave 6 two peers stand in
## two realms at once and an intent stamped with "whichever realm the local
## player happens to be in" would file a Cloudreach placement in the Meadows.
## Empty means "the same id as the Heart", which is what every shrine in the
## chapter is (`data/config/realm_hearts.json` names one Heart per realm).
@export var realm_id: String = ""

var _prompt: Node3D = null
var _heart_visual: Node3D = null
var _heart_material: StandardMaterial3D = null
var _socket_material: StandardMaterial3D = null
var _heart_light: OmniLight3D = null
var _built := false
var _observed_progression: RefCounted = null
var _observed_hearts: RefCounted = null
var _progression_revision := -1
var _heart_revision := -1
var _companion_slot := false


## Configure before adding the shrine to the scene tree.  Calling it later is
## also safe: the already-built visual and prompt immediately adopt the state of
## the new Heart id.
func setup(p_heart_id: String = "meadows", p_heart_name: String = "Heart of the Meadows",
		p_realm_id: String = "") -> void:
	heart_id = p_heart_id
	heart_name = p_heart_name
	realm_id = p_realm_id
	if is_inside_tree():
		refresh_from_game()


## The realm every intent from this shrine is stamped with.
func realm() -> String:
	var explicit := realm_id.strip_edges()
	return explicit if not explicit.is_empty() else heart_id


func _ready() -> void:
	add_to_group("progression_restore")
	_build_visual()
	_build_prompt()
	refresh_from_game()
	if not _companion_slot:
		_build_relic_slots()


func _build_relic_slots() -> void:
	var definitions := {"meadows":"Heart of the Meadows", "cloudreach":"Wings of Cloudreach", "stormwood":"Spark of the Stormwood"}
	var side := -1.0
	for id: String in definitions:
		if id == heart_id:
			continue
		var slot := (get_script() as Script).new() as Node3D
		slot.name = "RelicSlot_" + id
		slot.set("_companion_slot", true)
		slot.call("setup", id, definitions[id], realm())
		slot.position = Vector3(side * 3.0, 0, 0)
		slot.set("interaction_radius", 2.0)
		add_child(slot)
		side = 1.0


## The four player-facing states required by the Realm Heart contract.  Kept
## public and side-effect-free so the state machine can be pinned in headless
## tests without constructing the visual shrine.
func state_for(game: Node) -> String:
	var progression := _progression(game)
	var hearts := _realm_hearts(game)
	if progression == null or hearts == null:
		return STATE_UNEARNED
	if not bool(hearts.call("is_earned", heart_id, progression)):
		return STATE_UNEARNED
	if not bool(hearts.call("is_placed", heart_id, progression)):
		return STATE_EARNED_UNPLACED
	if str(hearts.call("active_id")) == heart_id:
		return STATE_ACTIVE
	return STATE_PLACED_INACTIVE


func current_state() -> String:
	return state_for(_game())


func _process(_delta: float) -> void:
	var game := _game()
	var progression := _progression(game)
	var hearts := _realm_hearts(game)
	if progression != _observed_progression or hearts != _observed_hearts \
			or (progression != null and int(progression.get("revision")) != _progression_revision) \
			or (hearts != null and int(hearts.get("revision")) != _heart_revision):
		_refresh(game)


## `Game.load_game()` calls this on every member of `progression_restore` after
## replacing the durable flag/state objects.  Nothing is cached across it.
func restore_progression_from_game(game: Node) -> void:
	_refresh(game)


func refresh_from_game() -> void:
	_refresh(_game())


func _on_activated() -> void:
	var game := _game()
	var progression := _progression(game)
	var hearts := _realm_hearts(game)
	if game == null or progression == null or hearts == null:
		return

	match state_for(game):
		STATE_EARNED_UNPLACED:
			submit_place(game)
		STATE_PLACED_INACTIVE:
			if bool(hearts.call("activate", heart_id, progression)):
				_announce(game, "%s active. %s Only one relic power can be active." % [heart_name, _power_description(hearts)])
		STATE_ACTIVE:
			hearts.call("clear_active")
			_announce(game, "%s power released. No relic power is active." % heart_name)
		_:
			return
	_refresh(game)


## Set this Heart into its socket -- the WORLD half, and the only thing about a
## Realm Heart that is shared.
##
## Returns `world_ledger.gd`'s verdict shape, so a caller never has to branch on
## the type of the answer: `ok` when it committed here and now (solo, or the
## host), `pending` while a client waits for the host, and otherwise a refusal
## whose `reason` is one sentence to show. `pending` is NOT failure and nothing
## local may move on it -- the delta repaints this shrine on every peer when it
## lands, which is how the friend standing beside you sees the Heart go in.
##
## A process with no ledger mounted at all (a unit fixture, a scene test that
## never built `Game.ledger`) falls back to the direct write `place()` has
## always done. That is the pre-Wave-3 path and it is deliberately kept: the
## alternative is a shrine that silently does nothing in every headless test.
func submit_place(game: Node) -> Dictionary:
	var progression := _progression(game)
	var hearts := _realm_hearts(game)
	if game == null or progression == null or hearts == null:
		return _refusal("The world is not ready yet.")
	if _companion_slot:
		return _refusal("Place %s at its own realm's shrine first." % heart_name)
	var flag := str(hearts.call("placed_flag", heart_id))
	if flag.is_empty():
		return _refusal("That Heart has no socket to record.")

	var transport: Node = game.get("ledger") as Node
	if transport == null or not transport.has_method("submit"):
		if bool(hearts.call("place", heart_id, progression)):
			_announce_placed(game, hearts)
			_refresh(game)
			return {"ok": true, "kind": "set_world_flag", "peer": 0, "code": "",
				"reason": "", "pending": false, "delta": {"seq": 0, "realm": realm(), "ops": []}}
		return _refusal("")

	var verdict: Dictionary = transport.call("submit", {
		"kind": "set_world_flag",
		"realm": realm(),
		"id": flag,
	})
	if bool(verdict.get("ok", false)):
		# Host or solo: `submit()` already applied the delta, so `state_for()`
		# reads PLACED on the very next line.
		_announce_placed(game, hearts)
		_refresh(game)
		return verdict
	if bool(verdict.get("pending", false)):
		# A client. Change NOTHING here: `ledger_rpc.gd` sweeps
		# `progression_restore` and then emits `delta_applied`, and this shrine
		# repaints off the sweep.
		return verdict
	var reason := str(verdict.get("reason", ""))
	if not reason.is_empty():
		_announce(game, reason)
	return verdict


func _announce_placed(game: Node, hearts: RefCounted) -> void:
	_announce(game, "%s placed. %s Only one relic power can be active."
		% [heart_name, _power_description(hearts)])


func _refusal(reason: String) -> Dictionary:
	return {
		"ok": false, "kind": "set_world_flag", "peer": 0, "code": "offline",
		"reason": reason, "pending": false,
		"delta": {"seq": 0, "realm": realm(), "ops": []},
	}


func _refresh(game: Node) -> void:
	if not _built or _prompt == null:
		return
	_observed_progression = _progression(game)
	_observed_hearts = _realm_hearts(game)
	_progression_revision = int(_observed_progression.get("revision")) if _observed_progression != null else -1
	_heart_revision = int(_observed_hearts.get("revision")) if _observed_hearts != null else -1
	var state := state_for(game)
	# Keep the power and replacement rule readable for as long as the player
	# stands at the shrine, including when a save already has it placed.
	var details := ""
	if _observed_hearts != null:
		details = "\n%s\nOnly one relic power can be active." % _power_description(_observed_hearts)
	match state:
		STATE_UNEARNED:
			_prompt.call("configure", "%s — empty relic slot" % heart_name, interaction_radius, true)
			_prompt.set("actionable", false)
			_set_visual(false, false, false)
		STATE_EARNED_UNPLACED:
			var label := "Place %s%s" % [heart_name, details]
			if _companion_slot:
				label = "%s — place at its own realm's shrine" % heart_name
			_prompt.call("configure", label, interaction_radius, true)
			_prompt.set("actionable", not _companion_slot)
			_set_visual(true, false, false)
		STATE_PLACED_INACTIVE:
			_prompt.call("configure", "Activate %s%s" % [heart_name, details], interaction_radius, true)
			_prompt.set("actionable", true)
			_set_visual(true, true, false)
		STATE_ACTIVE:
			_prompt.call("configure", "Release %s power%s" % [heart_name, details], interaction_radius, true)
			_prompt.set("actionable", true)
			_set_visual(true, true, true)


func _power_description(hearts: RefCounted) -> String:
	var spec: Dictionary = hearts.call("heart", heart_id)
	var power: Dictionary = spec.get("power", {})
	return str(power.get("description", ""))


func _announce(game: Node, message: String) -> void:
	if game.has_method("push_world_message"):
		game.call("push_world_message", message)


func _set_visual(heart_visible: bool, placed: bool, active: bool) -> void:
	_heart_visual.visible = heart_visible
	_heart_visual.position.y = 0.88 if placed else 1.48
	_heart_visual.scale = Vector3.ONE * (1.16 if active else 1.0)
	var colour := HEART_ACTIVE if active else (HEART_READY if placed else HEART_DORMANT)
	_heart_material.albedo_color = colour
	_heart_material.emission_enabled = heart_visible
	_heart_material.emission = colour
	_heart_material.emission_energy_multiplier = 2.4 if active else (1.15 if placed else 0.45)
	_socket_material.albedo_color = HEART_READY.darkened(0.42) if placed else STONE_DARK
	_socket_material.emission_enabled = placed
	_socket_material.emission = HEART_READY.darkened(0.2)
	_socket_material.emission_energy_multiplier = 1.5 if active else 0.45
	_heart_light.visible = placed
	_heart_light.light_color = colour
	_heart_light.light_energy = 2.1 if active else 0.75


func _build_prompt() -> void:
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(0.0, 1.15, 0.72)
	_prompt.call("configure", "The Meadows shrine is waiting", interaction_radius, true)
	_prompt.set("actionable", false)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)


func _build_visual() -> void:
	if _built:
		return
	_built = true

	var stone_material := _material(STONE)
	_socket_material = _material(STONE_DARK)
	_heart_material = _material(HEART_DORMANT)

	var base := MeshInstance3D.new()
	base.name = "StoneBase"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.25
	base_mesh.bottom_radius = 1.4
	base_mesh.height = 0.34
	base_mesh.radial_segments = 10
	base.mesh = base_mesh
	base.position.y = 0.17
	base.material_override = stone_material
	add_child(base)

	var socket := MeshInstance3D.new()
	socket.name = "HeartSocket"
	var socket_mesh := CylinderMesh.new()
	socket_mesh.top_radius = 0.64
	socket_mesh.bottom_radius = 0.78
	socket_mesh.height = 0.2
	socket_mesh.radial_segments = 8
	socket.mesh = socket_mesh
	socket.position.y = 0.44
	socket.material_override = _socket_material
	add_child(socket)

	# Four short standing stones frame the socket without creating an asset
	# vocabulary beyond the shrine's own primitive masonry.
	for i in 4:
		var fin := MeshInstance3D.new()
		fin.name = "StandingStone%d" % (i + 1)
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(0.24, 0.82, 0.38)
		fin.mesh = fin_mesh
		var angle := float(i) * TAU / 4.0
		fin.position = Vector3(cos(angle) * 0.93, 0.68, sin(angle) * 0.93)
		fin.rotation.y = -angle
		fin.material_override = stone_material
		add_child(fin)

	_heart_visual = Node3D.new()
	_heart_visual.name = "RealmHeart"
	add_child(_heart_visual)
	if heart_id == "cloudreach":
		for side: float in [-1.0, 1.0]:
			for feather in 3:
				_build_heart_piece(Vector3(side*(0.12+feather*0.12),0.15-feather*0.07,0),Vector3(0.13,0.45-feather*0.05,0.12),side*0.65)
	elif heart_id == "stormwood":
		_build_heart_piece(Vector3(-0.06,0.19,0),Vector3(0.16,0.48,0.16),-0.4)
		_build_heart_piece(Vector3(0.06,-0.18,0),Vector3(0.16,0.48,0.16),-0.4)
		_build_heart_piece(Vector3.ZERO,Vector3(0.35,0.13,0.16),0)
	else:
		_build_heart_piece(Vector3(-0.16, 0.10, 0.0), Vector3(0.25, 0.24, 0.16), 0.0)
		_build_heart_piece(Vector3(0.16, 0.10, 0.0), Vector3(0.25, 0.24, 0.16), 0.0)
		_build_heart_piece(Vector3(0.0, -0.13, 0.0), Vector3(0.31, 0.31, 0.17), deg_to_rad(45.0))

	_heart_light = OmniLight3D.new()
	_heart_light.name = "HeartLight"
	_heart_light.position = Vector3(0.0, 1.05, 0.0)
	_heart_light.omni_range = 4.2
	_heart_light.shadow_enabled = false
	add_child(_heart_light)

	var body := StaticBody3D.new()
	body.name = "ShrineCollision"
	var shape_node := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.15
	shape.height = 0.62
	shape_node.shape = shape
	shape_node.position.y = 0.31
	body.add_child(shape_node)
	add_child(body)


func _build_heart_piece(at: Vector3, size: Vector3, roll: float) -> void:
	var piece := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	piece.mesh = mesh
	piece.position = at
	piece.scale = size
	piece.rotation.z = roll
	piece.material_override = _heart_material
	_heart_visual.add_child(piece)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.82
	return material


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _progression(game: Node) -> RefCounted:
	if game == null:
		return null
	var value: Variant = game.get("progression")
	return value as RefCounted if value is RefCounted else null


func _realm_hearts(game: Node) -> RefCounted:
	if game == null:
		return null
	var value: Variant = game.get("realm_hearts")
	return value as RefCounted if value is RefCounted else null
