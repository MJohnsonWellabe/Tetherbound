extends Node
const BACKGROUND_TRACE := preload("res://scripts/net/background_work_trace.gd")

## Actual production lifetime composition under Game/Session.
var _host: Node
var _interaction: Node
var _board: WeakRef
var _left := 0.0
var _cached_view: Dictionary = {}

func _ready() -> void:
	var breakthrough: Node = preload("res://scripts/masters/breakthrough_service.gd").new()
	breakthrough.name = "BreakthroughService"
	add_child(breakthrough)
	breakthrough.call("bind_actions", Callable(get_parent(), "_foundation_breakthrough_submit"), Callable(get_parent(), "homestead_personal_view"))
	var arrival: Node = preload("res://scripts/net/foundation_portal_arrival.gd").new()
	arrival.name = "PortalArrival"
	add_child(arrival)
	var waystones: Node = preload("res://scripts/net/waystone_mounts.gd").new()
	waystones.name = "WaystoneMounts"
	add_child(waystones)
	var lifecycle: Node = preload("res://scripts/net/foundation_travel_lifecycle.gd").new()
	lifecycle.name = "TravelLifecycle"
	add_child(lifecycle)
	var forge: Node = preload("res://scripts/net/foundation_forge.gd").new()
	forge.name = "ForgeHost"
	add_child(forge)
	_host = preload("res://scripts/world/bounty_host_adapter.gd").new()
	_host.name = "BountyHost"
	add_child(_host)
	_host.call("configure", get_parent(), bounty_context, accepted_bounty_event)
	_interaction = preload("res://scripts/world/bounty_interaction_adapter.gd").new()
	_interaction.name = "BountyInteraction"
	add_child(_interaction)
	_interaction.call("bind_actions", bounty_claim, personal_view, bounty_reconcile)
	get_parent().connect("foundation_reply_received", _reply)
	preload("res://scripts/ui/bounty_board_panel.gd").attach(_interaction)
	var rematches: Node = preload("res://scripts/net/foundation_rematches.gd").new()
	rematches.name = "Rematches"
	add_child(rematches)
	var alphas: Node = preload("res://scripts/net/foundation_alphas.gd").new()
	alphas.name = "Alphas"
	add_child(alphas)
	var captures: Node = preload("res://scripts/net/foundation_capture.gd").new()
	captures.name = "Captures"
	add_child(captures)
	var resources: Node = preload("res://scripts/net/foundation_resources.gd").new()
	resources.name = "Resources"
	add_child(resources)

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 1.0
	var trace := BACKGROUND_TRACE.begin("composition.poll")
	_poll_background_work()
	BACKGROUND_TRACE.end("composition.poll", trace)

func _poll_background_work() -> void:
	var camp_trace := BACKGROUND_TRACE.begin("composition.retry_camp")
	get_parent().call("_retry_foundation_camp")
	BACKGROUND_TRACE.end("composition.retry_camp", camp_trace)
	var events_trace := BACKGROUND_TRACE.begin("composition.retry_events")
	get_parent().call("_retry_foundation_events")
	BACKGROUND_TRACE.end("composition.retry_events", events_trace)
	var sites_trace := BACKGROUND_TRACE.begin("composition.mount_master_sites")
	_mount_occupied_master_sites()
	BACKGROUND_TRACE.end("composition.mount_master_sites", sites_trace)
	if _board != null and _board.get_ref() != null: return
	# Resolve Halda's actual grounded tournament board, never a packet name.
	# Tournaments join their group; walking every node of the tree each second
	# stalled Stormwood (which has no board) for its whole stay.
	for node: Node in get_tree().get_nodes_in_group(preload("res://scripts/world/tournament.gd").FOUNDATION_GROUP):
		var script: Script = node.get_script()
		if script == null or script.resource_path != "res://scripts/world/tournament.gd" or node.call("built") != true: continue
		var board := node.get_node_or_null(^"Board") as Node3D
		if board == null: continue
		_board = weakref(board)
		_interaction.call("mount", board, Vector3(-1.5, 0.9, 0.6))
		break

## Actual ready worlds and their current occupants, never a global realm or
## a saved peer claim. Repeated calls retry late terrain readiness safely.
func _mount_occupied_master_sites() -> void:
	if preload("res://scripts/build/station_rules.gd").config().get("runtime_enabled") != true: return
	var owner: Node = get_parent()
	var game: Node = owner.call("_game")
	if game == null: return
	var service := get_node(^"BreakthroughService")
	var local_realm: String = str(game.get("current_realm"))
	var world_node: Node3D = owner.call("_portal_world_node", local_realm)
	var player: Node3D = game.call("find_player")
	var mounted := {}
	if world_node != null and player != null and world_node.is_ancestor_of(player):
		service.call("mount_biome", world_node, player, local_realm)
		mounted[world_node.get_instance_id()] = true
	if owner.call("is_host") != true: return
	var lifecycle := get_node(^"TravelLifecycle")
	var registry: RefCounted = owner.get("_registry")
	for row: Dictionary in registry.call("rows"):
		var peer: int = int(row.get("peer_id", 0))
		if peer == owner.call("local_peer_id") or owner.call("_authority_character", peer) != row.get("character_id") \
			or owner.call("admitted_character_state", peer).is_empty(): continue
		var realm: String = str(row.get("realm", ""))
		var shell: Node3D = owner.call("_portal_world_node", realm)
		var occupant: Node3D = lifecycle.call("remote_body", peer)
		if shell == null or occupant == null or not shell.is_inside_tree() or not occupant.is_inside_tree() \
			or not shell.is_ancestor_of(occupant) or occupant.get("net_realm") != realm \
			or mounted.has(shell.get_instance_id()): continue
		service.call("mount_biome", shell, occupant, realm)
		mounted[shell.get_instance_id()] = true

func bounty_context(peer: int) -> Dictionary:
	var session := get_parent()
	if session.call("is_host") != true or session.call("admitted_character_state", peer).is_empty(): return {}
	var game: Node = session.call("_game")
	var world: RefCounted = game.get("world")
	var writer := session.get_node_or_null(^"LedgerRpc")
	if writer == null: return {}
	var actor: Dictionary = writer.call("_water_actor_context", peer, {})
	var board := _board.get_ref() as Node3D if _board != null else null
	var nearby: bool = actor.get("position") is Vector3 and actor.get("realm") == "meadows" \
		and board != null and actor.position.distance_to(board.global_position) <= float(preload("res://scripts/world/bounty_board.gd").config().interaction_radius_m)
	var registry: RefCounted = session.get("_character_authority")
	var character: String = session.call("_authority_character", peer)
	return {"character_id": character, "expected_revision": registry.call("revision", character),
		"source_key": preload("res://scripts/world/bounty_board.gd").config().board_key,
		"in_range": nearby, "in_combat": session.call("_altar_peer_in_combat", peer),
		"world_namespace": world.reward_delivery_namespace, "host_day": world.redesign_world.bounty_day,
		"host_unlocks": world.redesign_world.portal_unlocks.duplicate(), "clock_confirmed": world.day >= 1}

func accepted_bounty_event(peer: int, token: String) -> Dictionary:
	var session := get_parent()
	var game: Node = session.call("_game")
	var world: RefCounted = game.get("world")
	var character: String = session.call("_authority_character", peer)
	for row: Variant in world.reward_deliveries.values():
		if not preload("res://scripts/net/foundation_event.gd").valid(row, world.reward_delivery_namespace, world.world_id): continue
		for duty: Dictionary in row.duties:
			if duty.character_id == character and duty.action == "bounty_event" and duty.context.event_id == token:
				var result: Dictionary = duty.context.duplicate(true)
				result.character_id = character
				return result
	return {}

func bounty_view() -> Dictionary:
	return get_parent().call("_foundation_send", "bounty_view", "halda_bounty_board", {}, -1)

func personal_view() -> Dictionary:
	var result := bounty_view()
	return result if get_parent().call("is_host") == true else _cached_view.duplicate(true)

func bounty_claim(intent: Dictionary) -> Dictionary:
	return get_parent().call("_foundation_send", "bounty_claim", "halda_bounty_board", intent, -1)

func bounty_reconcile(pending: Dictionary) -> Dictionary:
	var session := get_parent()
	if pending.get("character_id") != session.call("_local_character_id") \
		or pending.get("world_namespace") != session.call("_game").get("world").reward_delivery_namespace: return {"ok": false, "resolved": false}
	return session.call("_foundation_send", "bounty_reconcile", "halda_bounty_board", {"instance": pending.get("instance")}, -1)

func _reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.op == "bounty_view": _cached_view = result.duplicate(true)
	elif envelope.op in ["bounty_claim", "bounty_reconcile"]: _interaction.call("settled", result)
