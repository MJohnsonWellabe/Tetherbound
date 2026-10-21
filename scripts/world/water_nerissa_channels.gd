extends Node3D

## BOSSES §4.11: Captain Nerissa's Heart Chamber side-channel sweeps (Channel
## Cycle, then Pressure Rise), driven by water_nerissa_channel_rules.gd.
##
## Authority follows the trainer battle: the process that runs Nerissa's
## battle (the host when the host fights, with guests joined through the
## encounter record) owns the waves. Each struck participant's creature takes
## the hit through the encounter's own host_deliver_enemy_hit (the local ally
## through CombatManager.apply_host_enemy_hit when no record is open). The
## trainer is never struck. Joined participants mirror the lane state from
## WaterVeilfallTransport snapshots; nothing is saved.
##
## Mounted by water_veilfall.gd under the interior only when
## water_nerissa_channels.json is enabled.

const RULES := preload("res://scripts/world/water_nerissa_channel_rules.gd")
const SIDES := [-1, 1]

var world: Node3D
var veilfall: Node3D
var rules: RefCounted
var _sheets: Dictionary = {}
var _centre := Vector2.INF
var _remote_until_msec := 0
var _last_serial := -1
var _last_state := ""


func setup(owner_world: Node3D, owner_veilfall: Node3D) -> void:
	world = owner_world
	veilfall = owner_veilfall
	rules = RULES.new()
	name = "NerissaChannels"
	for side: int in SIDES:
		var sheet := MeshInstance3D.new()
		sheet.name = "Channel_%s" % ("left" if side < 0 else "right")
		sheet.mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		sheet.material_override = material
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sheet.visible = false
		add_child(sheet)
		_sheets[side] = sheet


func _director() -> Node:
	return world.get_node_or_null(^"EncounterDirector") if world != null else null


func _manager() -> Node:
	return world.get_node_or_null(^"CombatManager") if world != null else null


## The battle this process runs is Nerissa's.
func _owns_battle() -> bool:
	var director := _director()
	return director != null and bool(director.call("trainer_battle_active")) \
		and str(director.call("trainer_battle_id")) == str(rules.config.get("trainer_id", ""))


func _process(delta: float) -> void:
	if rules == null:
		return
	if not _owns_battle():
		if rules.get("state") != "off" and Time.get_ticks_msec() > _remote_until_msec:
			rules.set("state", "off")
		_show(rules.call("snapshot"))
		return
	var director := _director()
	var manager := _manager()
	rules.call("set_send_out", int(director.get("_trainer_battle_sent")) - 1)
	# Between send-outs (no live round) the waves hold where they are.
	if manager == null or not bool(manager.call("is_fighting")):
		return
	var arena: Node3D = manager.get("_arena")
	if is_instance_valid(arena):
		_centre = Vector2(arena.global_position.x, arena.global_position.z)
	if not _centre.is_finite():
		return
	var bodies := _participant_bodies(director)
	var locals: Dictionary = {}
	var outer_legal: Dictionary = {}
	for peer: int in bodies:
		var at := _local(bodies[peer])
		locals[peer] = at
		outer_legal[peer] = _outer_legal(at)
	var own: int = _local_peer()
	var ally_local: Vector2 = locals.get(own, Vector2.ZERO)
	var step := str(rules.call("advance", delta, bool(manager.call("enemy_is_winding_up")),
		ally_local, locals, outer_legal))
	if step == "fire":
		_fire(director, manager, bodies, locals)
	if not step.is_empty():
		_publish(director)
	_show(rules.call("snapshot"))


func _local(body: Node3D) -> Vector2:
	return Vector2(body.global_position.x - _centre.x, body.global_position.z - _centre.y)


## The lane's outer edge is a legal exit only while it stays inside the
## Heart Chamber's side walls.
func _outer_legal(at: Vector2) -> bool:
	if veilfall == null or veilfall.get("interior") == null:
		return true
	var interior: Node3D = veilfall.get("interior")
	var lane: Dictionary = rules.config.get("lane", {})
	var side := 1.0 if at.x >= 0.0 else -1.0
	var outer_x := _centre.x + side * float(lane.get("outer_m", 8.6)) - interior.global_position.x
	for room: Dictionary in veilfall.get("rules").get("rooms", []):
		if str(room.get("id", "")) == "heart_chamber":
			return absf(outer_x - float(room.center_xz[0])) < float(room.size_xz[0]) * 0.5 - 0.5
	return true


func _local_peer() -> int:
	var game := get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") if game != null else null
	return int(session.call("local_peer_id")) if session != null else 1


func _encounter_id(director: Node) -> String:
	var encounter: Dictionary = director.get("_encounter")
	return str(encounter.get("encounter_id", ""))


## peer -> the creature body that fights for it. Only creatures; never a
## trainer body.
func _participant_bodies(director: Node) -> Dictionary:
	var out: Dictionary = {}
	var own := _local_peer()
	var ally: Node3D = director.call("ally_body")
	if is_instance_valid(ally):
		out[own] = ally
	var id := _encounter_id(director)
	var host: RefCounted = director.get("_encounter_host")
	if id.is_empty() or host == null:
		return out
	for peer: int in host.call("participants_of", id):
		if peer == own:
			continue
		var body: Node3D = director.call("deployed_body_for", peer)
		if is_instance_valid(body):
			out[peer] = body
	return out


func _fire(director: Node, manager: Node, bodies: Dictionary, locals: Dictionary) -> void:
	var own := _local_peer()
	var id := _encounter_id(director)
	for peer: int in bodies:
		var max_hp := 0.0
		if peer == own:
			var creature: RefCounted = director.call("ally_instance")
			max_hp = float(creature.get("max_hp")) if creature != null else 0.0
		else:
			var card: Dictionary = director.call("_creature_card_for", peer)
			max_hp = float(card.get("hp_max", card.get("max_hp", 0.0)))
		var damage := float(rules.call("damage_for", peer, locals[peer], max_hp))
		if damage <= 0.0:
			continue
		var payload := {"damage": damage, "move_id": "nerissa_channel", "lunge": 0.0}
		if not id.is_empty():
			director.call("host_deliver_enemy_hit", id, peer, payload)
		elif peer == own:
			manager.call("apply_host_enemy_hit", payload)


## Joined participants mirror the lanes; nothing durable is sent.
func _publish(director: Node) -> void:
	var id := _encounter_id(director)
	var host: RefCounted = director.get("_encounter_host")
	var transport: Node = veilfall.get("_transport") if veilfall != null else null
	if id.is_empty() or host == null or transport == null:
		return
	var snap: Dictionary = rules.call("snapshot")
	snap["centre"] = [_centre.x, _centre.y]
	var own := _local_peer()
	for peer: int in host.call("participants_of", id):
		if peer != own:
			transport.call("deliver", peer, "nerissa_channel", snap)


## A participant that does not run the battle mirrors the host's lanes.
func receive_snapshot(snap: Dictionary) -> void:
	if _owns_battle() or rules == null:
		return
	var centre: Array = snap.get("centre", [])
	if centre.size() == 2:
		_centre = Vector2(float(centre[0]), float(centre[1]))
	rules.set("state", str(snap.get("state", "off")))
	rules.set("side", int(snap.get("side", 0)))
	rules.set("serial", int(snap.get("serial", 0)))
	# A missed "idle" never leaves a lane lit: the mirror lapses on its own.
	_remote_until_msec = Time.get_ticks_msec() + int(1000.0 * (float(snap.get("left", 0.0)) + 2.0))


func _show(snap: Dictionary) -> void:
	var state := str(snap.get("state", "off"))
	var side := int(snap.get("side", 0))
	var pres: Dictionary = rules.config.get("presentation", {})
	var lane: Dictionary = rules.config.get("lane", {})
	for lane_side: int in SIDES:
		var sheet: MeshInstance3D = _sheets[lane_side]
		var lit := lane_side == side and state in ["announce", "active", "drain"] and _centre.is_finite()
		sheet.visible = lit
		if not lit:
			continue
		var inner := float(lane.get("inner_m", 2.6))
		var outer := float(lane.get("outer_m", 8.6))
		var height := float(pres.get("active_height_m", 0.6)) if state == "active" else 0.06
		(sheet.mesh as BoxMesh).size = Vector3(outer - inner, height, float(lane.get("half_length_m", 12.0)) * 2.0)
		var x := _centre.x + float(lane_side) * (inner + outer) * 0.5
		var floor_y := _floor_y(x, _centre.y)
		sheet.global_position = Vector3(x, floor_y + height * 0.5 + 0.03, _centre.y)
		var material := sheet.material_override as StandardMaterial3D
		var key: String = state
		material.albedo_color = Color(str(pres.get(key + "_colour", "#7fd6ff")), float(pres.get(key + "_alpha", 0.4)))


func _floor_y(x: float, z: float) -> float:
	if veilfall != null and veilfall.has_method("built_floor_height_at"):
		var y: Variant = veilfall.call("built_floor_height_at", x, z)
		if y is float and is_finite(y):
			return y
	var interior: Node3D = veilfall.get("interior") if veilfall != null else null
	return interior.global_position.y if interior != null else global_position.y
