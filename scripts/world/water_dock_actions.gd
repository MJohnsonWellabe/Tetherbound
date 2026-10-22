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
const FIRST_SHORE_NOTICE := preload("res://scripts/world/water_first_shore_current_notice.gd")
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
var _reconcile_due := false

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
		if str(dock.id) == FIRST_SHORE_DOCK:
			# A beach-wide route is closed by the existing adverse current and
			# Reedhaven tide race. The old freestanding fence could be walked
			# around; retire its misleading visual AND redundant collision.
			var notice := FIRST_SHORE_NOTICE.new()
			notice.name = "FirstShoreCurrentNotice"
			add_child(notice)
			notice.build(world, _game)
			continue
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
		# X04 / F13#5: every closed departure dock wears the installed
		# cross-braced fence First Shore already uses. The former plain
		# plain brown `_box` (#70583e) read as an untextured tan slab by day
		# and a black one at night at the Tidal Cradle and Sluice Isle stands.
		# Collision (the box shape below) and unlock behaviour are unchanged.
		var look := preload("res://scripts/world/tidewake_look_profile.gd").settings()
		var boom: Dictionary = look.get("dock_barrier", {})
		if not (bool(look.get("enabled", false)) and not boom.is_empty() \
				and _build_rope_boom_visual(barrier, width, boom)):
			_build_first_shore_barrier_visual(barrier, width, height)
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

## A host refusal of a paid copy. NO refusal code ever refunds here, not even
## journal_failed: this wiring cannot guarantee P1/P2 (refusals carry no
## action, another copy of the same txn may be on the wire, and the host keeps
## no sticky refusal), and the debit module's header forbids refunding on
## journal_failed without them. The row stays pending; the next press (or a
## reconnect) resubmits the SAME txn, which commits once or is answered from
## its durable receipt. Items return only through reconcile's paid_by_other
## proof (the action flag set with no receipt naming this txn).
func _settle_verdict(_verdict: Dictionary, _txn: String) -> void:
	_reconcile()

func _on_delta(_delta: Dictionary) -> void:
	for id: Variant in _pending.keys():
		if not _pending[id] is Dictionary:
			_pending.erase(id)
	_reconcile()
	_refresh()

## A `water_dock_action` refusal releases ONLY the in-flight copy it can be
## attributed to: the entry whose txn it names, else (ledger refusals carry no
## action or txn) the single copy of this kind in flight on this peer, when
## exactly one is. F13 local-chain steps (sibling WaterLocalChains) share the
## intent kind, so their in-flight steps count too. With several copies in
## flight an unattributable refusal releases nothing; those entries wait for
## their own verdict/delta or a reconnect (new link). A wrong release could at
## worst send a second copy of the same txn, which the host dedupes by receipt
## and which can no longer cause a refund (see _settle_verdict).
func _on_refused(kind: String, _code: String, reason: String, details: Dictionary) -> void:
	if kind != "water_dock_action":
		return
	var txn := str(details.get("txn_id", ""))
	var released := ""
	for id: Variant in _pending.keys():
		var entry: Variant = _pending[id]
		if not txn.is_empty() and entry is Dictionary and str((entry as Dictionary).txn) == txn:
			released = str(id)
	if released.is_empty() and txn.is_empty() and _pending.size() == 1 and _foreign_in_flight() == 0:
		released = str(_pending.keys()[0])
	if not released.is_empty():
		var entry: Variant = _pending[released]
		_pending.erase(released)
		if entry is Dictionary:
			_settle_verdict(details, str((entry as Dictionary).txn))
	_reconcile()
	_game.push_world_message(reason)

## `water_dock_action` copies this peer has in flight outside this node (F13
## local-chain steps). Docks connect to intent_refused before local chains
## build, so this is read before a refusal clears them.
func _foreign_in_flight() -> int:
	var chains: Node = get_parent().get_node_or_null(^"WaterLocalChains") if get_parent() != null else null
	if chains == null or not chains.has_method("pending_steps"):
		return 0
	return (chains.call("pending_steps") as Array).size()

## Settle/refund escrow rows from the durable receipts this peer's world holds
## (host world, or the host's replicated facts on a guest). Never refunds on a
## missing receipt.
## Returns false only when it could not run yet (a guest mid-handshake).
func _reconcile() -> bool:
	if _game == null or _game.get("local") == null or _game.get("world") == null:
		return true
	var instance := _world_instance()
	if instance.is_empty():
		return true
	var session: Variant = _game.get("session")
	if session is Object and not bool(_game.is_host()) and (session as Object).has_method("snapshot_ready") \
			and bool((session as Object).call("is_active")) and not bool((session as Object).call("snapshot_ready")):
		return false
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
	return true

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
		_reconcile_due = true
	if _reconcile_due:
		# Retried every frame until it runs: a rejoin changes the facts before
		# the session raises snapshot_ready(), which gates _reconcile().
		_reconcile_due = not _reconcile()
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
	# This station's persistent installed awning and chart live beside WaterDocks,
	# so loading progression can rebuild its prompt without duplicating scenery.
	if kind == "chart" and parent.name == "deep_watch_chart":
		return
	var look := preload("res://scripts/world/tidewake_look_profile.gd").settings()
	var winch: Dictionary = look.get("sluice_winch", {})
	if bool(look.get("enabled", false)) and str(parent.name) == str(winch.get("action_id", "")):
		if _build_sluice_winch(parent, winch):
			return
	var station: Array = look.get("dock_equipment", {}).get(kind, [])
	if bool(look.get("enabled", false)) and not station.is_empty() and _build_station_props(parent, station):
		return
	_box(parent, Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 1.5), Color("736044"))
	if kind in ["pump", "sluice"]:
		_box(parent, Vector3(0, 0.9, 0), Vector3(1.0, 1.0, 0.8), Color("67736d"))
		_box(parent, Vector3(0.55, 1.7, 0), Vector3(0.15, 0.7, 0.15), Color("986440"))
	elif kind == "chart":
		_box(parent, Vector3(0, 1.0, 0), Vector3(1.8, 0.1, 1.1), Color("c8b887"))
	else:
		_box(parent, Vector3(0, 0.6, 0), Vector3(1.4, 0.35, 1.0), Color("9a8056"))


## F13#5/F39: OFF-gated installed props replace a station's primitive boxes.
## Each prop is fitted to `height_m`, feet on the ground; the interaction node,
## prompt, costs, flags and transactions are unchanged.
func _build_station_props(parent: Node3D, props: Array) -> bool:
	var built: Array[Node3D] = []
	for raw: Variant in props:
		var spec := raw as Dictionary
		var packed := load(str(spec.get("model", ""))) as PackedScene
		if packed == null:
			push_error("Dock station model missing: " + str(spec.get("model", "")))
			for node: Node3D in built:
				node.free()
			return false
		var model := packed.instantiate() as Node3D
		var bounds := preload("res://scripts/characters/render_bounds.gd").measure(model)
		if bounds.size.y <= 0.001:
			model.free()
			continue
		var factor := float(spec.get("height_m", 1.0)) / bounds.size.y
		model.scale = Vector3.ONE * factor
		var at: Array = spec.get("at", [0.0, 0.0])
		model.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		model.position = Vector3(float(at[0]), -bounds.position.y * factor, float(at[1]))
		if bool(spec.get("timber_family", true)):
			preload("res://scripts/world/tidewake_material_family.gd").prop(model, "timber")
		built.append(model)
	for node: Node3D in built:
		parent.add_child(node)
	return not built.is_empty()


## F13#5: one local, OFF-gated eastern control silhouette. Its interaction
## origin, costs, flags, collision and multiplayer transactions are unchanged.
func _build_sluice_winch(parent: Node3D, cfg: Dictionary) -> bool:
	var assembly := Node3D.new()
	assembly.name = "EasternSluiceWinch"
	assembly.rotation.y = deg_to_rad(float(cfg.yaw_deg))
	for piece: Dictionary in cfg.pieces:
		var packed := load(str(piece.model)) as PackedScene
		if packed == null:
			push_error("Sluice winch model missing: " + str(piece.model))
			assembly.free()
			return false
		var model := packed.instantiate() as Node3D
		var bounds := preload("res://scripts/characters/render_bounds.gd").measure(model)
		if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
			model.free()
			assembly.free()
			return false
		var size: Array = piece["size"]
		model.scale = Vector3(float(size[0]), float(size[1]), float(size[2])) / bounds.size
		model.position = -bounds.get_center() * model.scale
		var holder := Node3D.new()
		holder.name = str(piece.id)
		var at: Array = piece.at
		holder.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		var turn: Array = piece.get("rotation_deg", [0.0, 0.0, 0.0])
		holder.rotation_degrees = Vector3(float(turn[0]), float(turn[1]), float(turn[2]))
		holder.add_child(model)
		assembly.add_child(holder)
		preload("res://scripts/world/tidewake_material_family.gd").prop(model, "timber")
	# Exposed iron handwheel and spindle, leaving open space around the trainer.
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(str(cfg.metal_colour))
	metal.metallic = float(cfg.metallic)
	metal.roughness = float(cfg.roughness)
	var wheel := Node3D.new()
	wheel.name = "Handwheel"
	var centre: Array = cfg.wheel_center
	wheel.position = Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
	assembly.add_child(wheel)
	var ring := TorusMesh.new()
	ring.inner_radius = float(cfg.wheel_radius) - float(cfg.rim_thickness)
	ring.outer_radius = float(cfg.wheel_radius)
	ring.rings = 24
	ring.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.mesh = ring
	rim.material_override = metal
	rim.rotation.x = PI * 0.5
	wheel.add_child(rim)
	for i in 3:
		var spoke := MeshInstance3D.new()
		var bar := CylinderMesh.new()
		bar.top_radius = float(cfg.spoke_radius)
		bar.bottom_radius = float(cfg.spoke_radius)
		bar.height = float(cfg.wheel_radius) * 2.0 - float(cfg.rim_thickness)
		bar.radial_segments = 8
		spoke.mesh = bar
		spoke.material_override = metal
		spoke.rotation.z = float(i) * PI / 3.0
		wheel.add_child(spoke)
	var axle := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = float(cfg.axle_radius)
	shaft.bottom_radius = float(cfg.axle_radius)
	shaft.height = float(cfg.axle_length)
	shaft.radial_segments = 12
	axle.mesh = shaft
	axle.material_override = metal
	axle.rotation.x = PI * 0.5
	axle.position.z = float(cfg.axle_length) * 0.5
	wheel.add_child(axle)
	parent.add_child(assembly)
	return true


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

## F39/F13#5 candidate under the OFF Tidewake look gate (`dock_barrier`): the
## GPU judges read the closed-dock fence as a farm corral standing in the
## sea. A harbour boom instead: a lantern post at each end and sagging rope
## lines strung with cork floats across the same span. The collision box and
## unlock behaviour are built by the caller and unchanged.
func _build_rope_boom_visual(parent: Node3D, width: float, cfg: Dictionary) -> bool:
	var packed := load(str(cfg.get("post_model", ""))) as PackedScene
	if packed == null:
		push_error("Dock barrier post model missing: " + str(cfg.get("post_model", "")))
		return false
	var post_height := float(cfg.get("post_height_m", 2.6))
	for side: float in [-1.0, 1.0]:
		var post := packed.instantiate() as Node3D
		var bounds := preload("res://scripts/characters/render_bounds.gd").measure(post)
		if bounds.size.y <= 0.001:
			post.free()
			return false
		var factor := post_height / bounds.size.y
		var holder := Node3D.new()
		holder.name = "BoomPost_%d" % int(side)
		post.scale = Vector3.ONE * factor
		post.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
		holder.add_child(post)
		holder.position = Vector3(side * width * 0.5, 0.0, 0.0)
		parent.add_child(holder)
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(str(cfg.get("rope_colour", "#b49a6a")))
	rope.roughness = 0.95
	var cork := StandardMaterial3D.new()
	cork.albedo_color = Color(str(cfg.get("float_colour", "#e8dcc0")))
	cork.roughness = 0.8
	var segments := int(cfg.get("rope_segments", 12))
	var radius := float(cfg.get("rope_radius_m", 0.04))
	var sag := float(cfg.get("sag_m", 0.4))
	var span := width - float(cfg.get("post_inset_m", 0.3)) * 2.0
	var lines: Array = cfg.get("rope_heights_m", [2.0, 1.2])
	for line_index in lines.size():
		var y0 := float(lines[line_index])
		var points: Array[Vector3] = []
		for i in segments + 1:
			var t := float(i) / float(segments)
			points.append(Vector3(-span * 0.5 + span * t, y0 - sag * 4.0 * t * (1.0 - t), 0.0))
		for i in segments:
			var a := points[i]
			var b := points[i + 1]
			var piece := MeshInstance3D.new()
			var tube := CylinderMesh.new()
			tube.top_radius = radius
			tube.bottom_radius = radius
			tube.height = a.distance_to(b)
			tube.radial_segments = 6
			tube.rings = 1
			piece.mesh = tube
			piece.material_override = rope
			piece.position = (a + b) * 0.5
			piece.rotation.z = atan2(b.y - a.y, b.x - a.x) - PI * 0.5
			parent.add_child(piece)
		if line_index != lines.size() - 1:
			continue
		var spacing := float(cfg.get("float_spacing_m", 1.2))
		var count := int(floor(span / spacing))
		for i in range(1, count):
			var t := float(i) / float(count)
			var bead := MeshInstance3D.new()
			var shape := CapsuleMesh.new()
			shape.radius = float(cfg.get("float_radius_m", 0.13))
			shape.height = shape.radius * 3.2
			shape.radial_segments = 8
			shape.rings = 2
			bead.mesh = shape
			bead.material_override = cork
			bead.position = Vector3(-span * 0.5 + span * t, y0 - sag * 4.0 * t * (1.0 - t), 0.0)
			bead.rotation.z = PI * 0.5
			parent.add_child(bead)
	return true


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
