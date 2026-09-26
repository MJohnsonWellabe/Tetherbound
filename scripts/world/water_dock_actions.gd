extends Node3D
const RULES := preload("res://scripts/world/water_dock_rules.gd")
const INTERACT := preload("res://scripts/world/interactable.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
## F15 paid-debit escrow (water_dock_debit.gd P1-P7): a paid action moves its
## cost out of the bag into a durable escrow row and SAVES the character before
## the intent is sent; the host records a receipt instead of an item_take; the
## row settles on that receipt, refunds only on proof this txn cannot commit,
## and is otherwise resubmitted unchanged (the host dedupes by receipt).
const DEBIT := preload("res://scripts/net/water_dock_debit.gd")
const WORLD_IDENTITY := preload("res://scripts/save/world_identity.gd")
const RECONCILE_EVERY_FRAMES := 60
const FIRST_SHORE_DOCK := "first_shore_to_reedhaven_dock"
const FENCE_SCENES: Array[PackedScene] = [
	preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Single.gltf"),
	preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension1.gltf"),
	preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension2.gltf"),
]
# Raw glTF bounds. Three courses are fitted to the existing 2.5 m solid blocker
# instead of leaving invisible upper collision.
const FENCE_WIDTHS := [2.06409966945648, 2.04504501819611, 2.02677971124649]
const FENCE_CENTRE_X := [0.00059908628464, 0.01012641191483, 0.01913312077522]
const FENCE_HEIGHT := 0.83810905367136
const FENCE_MIN_Y := -0.0282525196671486
const FENCE_BAYS := 5
const FENCE_COURSES := 3
var _world: Node3D
var _game: Node
var _data: Dictionary
var _prompts: Dictionary = {}
var _barriers: Dictionary = {}
## action_id -> in-flight entry. Paid entries are {"txn", "link"}; `link` is
## the transport the copy went out on, so a copy dropped with its connection
## never blocks a resubmit (P1: at most one outstanding copy per connection).
var _pending: Dictionary = {}
var _last_revision := -1
var _reconcile_countdown := 0
var _last_instance := ""

func build(world: Node3D) -> void:
	add_to_group("progression_restore")
	_world = world
	_game = get_node("/root/Game")
	_data = RULES.load_data()
	for action: Dictionary in _data.actions:
		var equipment := Node3D.new()
		equipment.name = str(action.id)
		add_child(equipment)
		equipment.position = RULES.action_position(action, world.config, world.ground_height_at)
		if not equipment.position.is_finite():
			push_error("Water dock has no terrain: " + str(action.id))
			equipment.queue_free()
			continue
		_build_equipment(equipment, str(action.kind))
		var prompt := INTERACT.new()
		equipment.add_child(prompt)
		prompt.position.y = 1.0
		prompt.configure(str(action.label), float(_data.interaction_distance_m), false)
		prompt.activated.connect(_activate.bind(action))
		_prompts[str(action.flag)] = prompt
	for dock: Dictionary in world.config.docks:
		if str(dock.unlock_flag).is_empty():
			continue
		var anchor: Dictionary = {}
		for candidate: Dictionary in world.config.anchors:
			if str(candidate.id) == str(dock.departure_anchor):
				anchor = candidate
		if anchor.is_empty():
			continue
		var at := Vector3(float(anchor.safe_position[0]), float(anchor.safe_position[1]), float(anchor.safe_position[2]))
		var shore := Vector3(float(anchor.shore_position[0]), 0, float(anchor.shore_position[2]))
		var barrier := StaticBody3D.new()
		barrier.name = str(dock.id) + "Barrier"
		add_child(barrier)
		barrier.position = at + (shore - at).normalized() * 5.0
		barrier.position.y = float(world.ground_height_at(barrier.position.x, barrier.position.z))
		barrier.rotation.y = atan2(shore.x - at.x, shore.z - at.z)
		var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
		var height := float(rules.docks.barrier_height_m)
		var width := float(rules.docks.barrier_width_m)
		if str(dock.id) == FIRST_SHORE_DOCK:
			_build_first_shore_barrier_visual(barrier, width, height)
		else:
			_box(barrier, Vector3(0, height * 0.5, 0), Vector3(width, height, 0.35), Color("70583e"))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(width, height, 0.35)
		shape.shape = box
		shape.position.y = height * 0.5
		barrier.add_child(shape)
		_barriers[str(dock.unlock_flag)] = barrier
	CLAIM.listen(self, _on_delta)
	var ledger: Node = _game.ledger
	if ledger != null and not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)
	_refresh()
	_reconcile()

func restore_progression_from_game(_loaded_game: Node) -> void:
	# A load can restore a closed gate after this scene already removed it.
	# Rebuild disposable equipment from the newly loaded world flags.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_prompts.clear()
	_barriers.clear()
	_pending.clear()
	build(_world)

func _activate(action: Dictionary) -> void:
	if _world.simulation_only or _in_flight(str(action.id)):
		return
	if not (action.get("cost", {}) as Dictionary).is_empty():
		_activate_paid(action)
		return
	var counts: Dictionary = {}
	for item: String in action.cost:
		counts[item] = _game.inventory.count(item)
	_pending[str(action.id)] = true
	var result := CLAIM.submit(self, {"kind":"water_dock_action", "realm":"water", "action_id":str(action.id), "inventory":counts})
	if not CLAIM.in_flight(result):
		_pending.erase(str(action.id))
		_game.push_world_message(str(result.get("reason", "The dock action could not complete.")))

## Escrow, persist, then submit (or resubmit the stored pending txn unchanged).
func _activate_paid(action: Dictionary) -> void:
	var id := str(action.id)
	var instance := _world_instance(true)
	if instance.is_empty():
		_game.push_world_message("The world is not ready yet.")
		return
	_reconcile()
	var flags: RefCounted = _game.world.flags
	var pending_txn := _pending_txn(id, instance)
	if pending_txn.is_empty():
		if flags.has(str(action.flag)):
			_game.push_world_message("This dock task is already complete.")
			return
		for flag: String in action.requires_flags:
			if not flags.has(flag):
				_game.push_world_message(str(action.get("refusal", "Resolve the dock's challenge first.")))
				return
	var fresh := false
	if pending_txn.is_empty():
		var begun := DEBIT.begin(_debit_state(), id, action.cost as Dictionary, instance,
			RULES.world_facts(flags, instance, _data.actions))
		if bool(begun.ok):
			pending_txn = str(begun.txn_id)
			fresh = true
			# P5: the reservation must be durable before anything is sent.
			if not _persist():
				DEBIT.rollback_unsent(_debit_state(), pending_txn)
				_persist()
				_game.push_world_message("Your character could not be saved. Nothing was spent.")
				return
		elif str(begun.code) == "already_pending":
			pending_txn = str(begun.txn_id)
		else:
			_game.push_world_message(_begin_refusal(str(begun.code)))
			return
	var row: Dictionary = _game.local.satchel_escrow.get(pending_txn, {})
	var counts: Dictionary = {}
	for item: String in action.cost:
		# P7: the materials proof counts the escrowed cost; the bag no longer does.
		counts[item] = int(_game.inventory.count(item)) + int((row.get("cost", {}) as Dictionary).get(item, 0))
	_pending[id] = {"txn": pending_txn, "link": _link()}
	var result := CLAIM.submit(self, {"kind":"water_dock_action", "realm":"water", "action_id":id,
		"inventory":counts, "txn_id":pending_txn, "world_instance_id":str(row.get("world_instance_id", instance)),
		"attempt":int(row.get("attempt", 1))})
	if bool(result.get("pending", false)):
		return
	_pending.erase(id)
	if bool(result.get("ok", false)):
		_reconcile()
		return
	if str(result.get("code", "")) == "offline" and not bool(_game.is_host()):
		# Never sent. A fresh reservation returns (P5); an older pending txn
		# may have committed on an earlier connection, so it stays escrowed.
		if fresh and not DEBIT.rollback_unsent(_debit_state(), pending_txn).is_empty():
			_persist()
		return
	_settle_verdict(result, pending_txn)

func _begin_refusal(code: String) -> String:
	match code:
		"materials":
			return "Bring 6 reed fiber and 4 driftwood to repair the dock."
		"already_paid":
			return "You have already paid for this dock task."
		"refund_outstanding":
			return "Your returned dock materials need room in your satchel first."
	return "The dock payment could not be started."

## A host refusal of a paid copy. Only journal_failed carries this txn and
## proves it never committed; every other code is answered by the replica's
## durable receipts (already_done) or leaves the row pending for a resubmit.
func _settle_verdict(verdict: Dictionary, txn: String) -> void:
	var changed := false
	if str(verdict.get("code", "")) == "journal_failed" and str(verdict.get("txn_id", "")) == txn:
		changed = bool(DEBIT.refund(_debit_state(), {"txn_id": txn,
			"world_instance_id": str(verdict.get("world_instance_id", "")),
			"code": "journal_failed"}).get("changed", false))
	if changed:
		_persist()
	_reconcile()

func _on_delta(_delta: Dictionary) -> void:
	for id: Variant in _pending.keys():
		if not _pending[id] is Dictionary:
			_pending.erase(id)
	_reconcile()
	_refresh()

func _on_refused(kind: String, code: String, reason: String, details: Dictionary) -> void:
	if kind == "water_dock_action":
		for id: Variant in _pending.keys():
			var entry: Variant = _pending[id]
			if entry is Dictionary and code == "journal_failed" \
					and str(details.get("txn_id", "")) == str((entry as Dictionary).txn):
				_settle_verdict(details, str((entry as Dictionary).txn))
		_pending.clear()
		_reconcile()
		_game.push_world_message(reason)

## Settle/refund escrow rows from the durable receipts this peer's world holds
## (host world, or the host's replicated facts on a guest). Never refunds on a
## missing receipt.
func _reconcile() -> void:
	if _game == null or _game.get("local") == null or _game.get("world") == null:
		return
	var instance := _world_instance()
	if instance.is_empty():
		return
	var session: Variant = _game.get("session")
	if session is Object and not bool(_game.is_host()) and (session as Object).has_method("snapshot_ready") \
			and bool((session as Object).call("is_active")) and not bool((session as Object).call("snapshot_ready")):
		return
	var in_flight: Array = []
	for id: Variant in _pending.keys():
		if _in_flight(str(id)) and _pending[id] is Dictionary:
			in_flight.append(str((_pending[id] as Dictionary).txn))
	var result := DEBIT.reconcile(_debit_state(), RULES.world_facts(_game.world.flags, instance, _data.actions),
		instance, in_flight)
	for id: Variant in _pending.keys():
		var entry: Variant = _pending.get(id)
		if entry is Dictionary and (str(entry.txn) in result.settled or str(entry.txn) in result.refunded):
			_pending.erase(id)
	if bool(result.changed):
		_persist()
	if not (result.refunded as Array).is_empty():
		_game.push_world_message("Your dock materials were returned: that task was already paid for.")

func _in_flight(id: String) -> bool:
	if not _pending.has(id):
		return false
	var entry: Variant = _pending[id]
	if not entry is Dictionary or bool(_game.is_host()) or (entry as Dictionary).link == _link():
		return true
	_pending.erase(id)
	return false

func _pending_txn(action_id: String, instance: String) -> String:
	var state := _debit_state()
	for txn: String in DEBIT.resubmittable_txns(state, instance):
		if str((_game.local.satchel_escrow[txn] as Dictionary).get("action_id", "")) == action_id:
			return txn
	return ""

## P6: built fresh from PlayerState on every call.
func _debit_state() -> Dictionary:
	return {"character_id": str(_game.local.character_id), "escrow": _game.local.satchel_escrow,
		"inventory": _game.local.inventory}

## The world instance escrow rows are bound to. Only a host's paid press may
## mint one (the dock commit's durable world save then records it).
func _world_instance(mint: bool = false) -> String:
	var world: RefCounted = _game.world
	if mint and bool(_game.is_host()):
		return WORLD_IDENTITY.ensure(world)
	var raw: Variant = world.get("reward_delivery_namespace")
	return raw as String if typeof(raw) == TYPE_STRING else ""

## The transport a copy went out on: a new connection (rejoin) is a new link.
func _link() -> int:
	var session: Variant = _game.get("session")
	if session is Object and (session as Object).has_method("is_active") and not bool((session as Object).call("is_active")):
		return 0
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer if is_inside_tree() else null
	return peer.get_instance_id() if peer != null else 0

## Same durability boundary as the satchel escrow (ledger_rpc.gd): the named
## character is saved; session-less legacy fixtures have nothing to write.
func _persist() -> bool:
	if str(_game.local.character_id).is_empty() or str(_game.world.world_id).is_empty():
		return true
	var saver: Variant = _game.get("save_system")
	return saver != null and bool((saver as RefCounted).call("save_character", _game, str(_game.local.character_id)))

func _process(_delta: float) -> void:
	if _game == null:
		return
	_reconcile_countdown -= 1
	if _reconcile_countdown <= 0:
		# Snapshot installs and reconnects need not bump the flag revision.
		_reconcile_countdown = RECONCILE_EVERY_FRAMES
		var instance := _world_instance()
		if not instance.is_empty() and not DEBIT.open_txns(_debit_state(), instance).is_empty():
			_reconcile()
	var instance_now := _world_instance()
	if int(_game.world.flags.revision) != _last_revision or instance_now != _last_instance:
		# A delta, a load or a rejoin snapshot: settle from the new facts now.
		_last_instance = instance_now
		_refresh()
		_reconcile()
	if not _game.is_host():
		return
	for completion: Dictionary in _data.completions:
		if _game.world.flags.has(str(completion.flag)):
			continue
		var ready := true
		for flag: String in completion.requires_flags:
			ready = ready and _game.world.flags.has(flag)
		if ready:
			_game.ledger.submit({"kind":"set_world_flag", "realm":"water", "id":str(completion.flag), "value":true})

func _refresh() -> void:
	_last_revision = int(_game.world.flags.revision)
	for flag: String in _prompts:
		_prompts[flag].enabled = not _world.simulation_only and not _game.world.flags.has(flag)
	for flag: String in _barriers.keys():
		if _game.world.flags.has(flag):
			var barrier: Node = _barriers[flag]
			remove_child(barrier)
			barrier.queue_free()
			_barriers.erase(flag)

func _build_equipment(parent: Node3D, kind: String) -> void:
	_box(parent, Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 1.5), Color("736044"))
	if kind in ["pump", "sluice"]:
		_box(parent, Vector3(0, 0.9, 0), Vector3(1.0, 1.0, 0.8), Color("67736d"))
		_box(parent, Vector3(0.55, 1.7, 0), Vector3(0.15, 0.7, 0.15), Color("986440"))
	elif kind == "chart":
		_box(parent, Vector3(0, 1.0, 0), Vector3(1.8, 0.1, 1.1), Color("c8b887"))
	else:
		_box(parent, Vector3(0, 0.6, 0), Vector3(1.4, 0.35, 1.0), Color("9a8056"))


func _build_first_shore_barrier_visual(parent: Node3D, width: float, height: float) -> void:
	# Five contiguous two-metre bays preserve the authored ten-metre span.
	# Alternating the installed cross-braced variants keeps the blockade from
	# reading as one stretched panel. Course joins remain aligned, so it still
	# reads as one closed working-dock gate rather than loose fence scatter.
	var bay_width := width / float(FENCE_BAYS)
	var course_height := height / float(FENCE_COURSES)
	for course in FENCE_COURSES:
		for bay in FENCE_BAYS:
			var variant := (bay + course * 2) % FENCE_SCENES.size()
			var fence := FENCE_SCENES[variant].instantiate() as Node3D
			var scale_x := bay_width / float(FENCE_WIDTHS[variant])
			fence.name = "FirstShoreBarrierFence_%d_%d" % [course, bay]
			fence.position = Vector3(-width * 0.5 + bay_width * (float(bay) + 0.5)
				- float(FENCE_CENTRE_X[variant]) * scale_x,
				-FENCE_MIN_Y * course_height / FENCE_HEIGHT + float(course) * course_height, 0.0)
			fence.scale = Vector3(scale_x, course_height / FENCE_HEIGHT, 1.0)
			parent.add_child(fence)

func _box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	box.material = material
	mesh.mesh = box
	mesh.position = at
	parent.add_child(mesh)
