extends RefCounted

## Read-only diagnostic. Never steering, traversal, gameplay or cause acceptance.
const LIMIT := 64
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SCRIPTS := {
	"player": "res://scripts/player/player_controller.gd",
	"rig": "res://scripts/player/camera_rig.gd",
	"warrens": "res://scripts/world/burrow_warrens.gd",
	"world": "res://scripts/world/playground_world.gd",
	"game": "res://autoload/game_state.gd",
	"manager": "res://scripts/combat/combat_manager.gd",
}

## Pure buffer controls do not authenticate native callbacks or source mounts.
class PairBuffer extends RefCounted:
	var pairs: Array = []
	var pending: Dictionary = {}
	var completed := 0
	var dropped := 0
	var rejected := 0
	var last_frame := -1

	static func valid_frame(value: Variant) -> bool:
		return value is int and value >= 0

	func accept(phase: String, note: Dictionary) -> bool:
		if phase not in ["pre", "post"] or note.get("phase") != phase \
			or not valid_frame(note.get("physics_frame")) or not valid_frame(note.get("process_frame")) \
			or not valid_frame(note.get("ground_generation")) \
			or not (note.get("delta") is int or note.get("delta") is float) \
			or not is_finite(float(note.delta)) or note.delta <= 0.0:
			rejected += 1
			return false
		var frame: int = note.physics_frame
		if phase == "pre":
			if frame <= last_frame or (not pending.is_empty() and frame <= pending.physics_frame):
				rejected += 1
				return false
			if not pending.is_empty(): dropped += 1
			pending = note.duplicate(true)
			return true
		if pending.is_empty() or frame != pending.physics_frame or frame <= last_frame \
			or note.get("delta") != pending.get("delta"):
			rejected += 1
			return false
		var before: Variant = pending.get("ground_generation")
		var after: Variant = note.get("ground_generation")
		pairs.append({"frame": frame, "pre": pending.duplicate(true), "post": note.duplicate(true),
			"ordinary_ground_step": before is int and after is int and after == before + 1})
		pending.clear()
		last_frame = frame
		completed += 1
		if pairs.size() > LIMIT: pairs.pop_front()
		return true

	func seal() -> void:
		if not pending.is_empty():
			dropped += 1
			pending.clear()

class NativeTick extends Node:
	var observer: WeakRef
	var phase := ""
	var active_call: RefCounted = null

	func _physics_process(delta: float) -> void:
		if active_call != null or observer == null: return
		var owner: RefCounted = observer.get_ref()
		if owner == null: return
		active_call = RefCounted.new()
		owner.call("_native_sample", self, phase, delta, active_call)
		active_call = null

var _refs: Dictionary = {}
var _scripts: Dictionary = {}
var _scope: Dictionary = {}
var _target := Vector3.ZERO
var _priority := 0
var _pre: NativeTick
var _post: NativeTick
var _buffer := PairBuffer.new()
var _start: Dictionary = {}
var _end: Dictionary = {}
var _begun := false
var _closed := false
var _refusal := ""


static func _identity(value: Variant) -> Dictionary:
	if not value is Object or not is_instance_valid(value): return {}
	var script: Variant = value.get_script()
	return {"instance_id": str(value.get_instance_id()),
		"path": str(value.get_path()) if value is Node and value.is_inside_tree() else "",
		"script": script.resource_path if script is Script else "",
		"script_instance_id": str(script.get_instance_id()) if script is Script else ""}


static func _v(value: Vector3) -> Variant:
	return [value.x, value.y, value.z] if value.is_finite() else {"nonfinite_vector": str(value)}


static func _mounted(player: CharacterBody3D, warrens: Node3D, rig: Node3D) -> Dictionary:
	for value: Node in [player, warrens, rig]:
		if not is_instance_valid(value) or not value.is_inside_tree() or value.is_queued_for_deletion(): return {}
	var world: Node = player.get_parent()
	if world == null or warrens.get_parent() != world or rig.get_parent() != world: return {}
	var tree := player.get_tree()
	var game := tree.root.get_node_or_null(^"Game")
	var manager := world.get_node_or_null(^"CombatManager")
	var view := {"player": player, "warrens": warrens, "rig": rig,
		"world": world, "game": game, "manager": manager}
	for key: String in SCRIPTS:
		var value: Variant = view[key]
		if not value is Node or not is_instance_valid(value) or not value.is_inside_tree() \
			or value.is_queued_for_deletion() or value.get_tree() != tree \
			or value.get_script() != load(SCRIPTS[key]): return {}
	if world.get_node_or_null(^"Player") != player or world.get_node_or_null(^"CameraRig") != rig \
		or world.get_node_or_null(^"BurrowWarrens") != warrens or player.get("_camera_rig") != rig \
		or player.process_thread_group != Node.PROCESS_THREAD_GROUP_INHERIT: return {}
	return view


## Freeze once; a closed/failed observer can never rebind another leg or body.
func begin(player: CharacterBody3D, warrens: Node3D, target: Vector3, rig: Node3D) -> bool:
	if _begun or _closed or not _refusal.is_empty(): return false
	if not target.is_finite(): return _refuse("nonfinite requested target")
	var view := _mounted(player, warrens, rig)
	if view.is_empty(): return _refuse("actual mounted production source required")
	_priority = player.process_physics_priority
	if _priority <= -2147483648 or _priority >= 2147483647: return _refuse("unbracketable actual player priority")
	_target = target
	for key: String in view:
		_refs[key] = weakref(view[key])
		_scripts[key] = view[key].get_script()
		_scope[key] = _identity(view[key])
		_scope[key]["script_file_sha256"] = FileAccess.get_sha256(SCRIPTS[key])
	_scope["target_world"] = _v(target)
	_scope["target_local"] = _v(warrens.to_local(target))
	_scope["player_physics_priority"] = _priority
	_scope["same_priority_nodes_may_run_between_observers"] = true
	_begun = true
	_pre = NativeTick.new()
	_post = NativeTick.new()
	for tick: NativeTick in [_pre, _post]:
		tick.observer = weakref(self)
		tick.process_thread_group = Node.PROCESS_THREAD_GROUP_INHERIT
	_pre.name = "WarrensReadOnlyBeforePlayer"
	_post.name = "WarrensReadOnlyAfterPlayer"
	_pre.phase = "pre"
	_post.phase = "post"
	_pre.process_physics_priority = _priority - 1
	_post.process_physics_priority = _priority + 1
	view.world.add_child(_pre)
	view.world.add_child(_post)
	if not _live():
		close()
		return false
	_start = _snapshot("leg_start", 0.0)
	return not _start.is_empty()


## Separate pure identity control; never grants mounted source acceptance.
static func same_original(refs: Dictionary, scripts: Dictionary, view: Dictionary) -> bool:
	if refs.size() != SCRIPTS.size() or scripts.size() != SCRIPTS.size() or view.size() != SCRIPTS.size(): return false
	for key: String in SCRIPTS:
		var ref: Variant = refs.get(key)
		var current: Variant = view.get(key)
		if not ref is WeakRef or not current is Object or not is_instance_valid(current) \
			or ref.get_ref() != current or current.get_script() != scripts.get(key): return false
	return true


func _live() -> bool:
	if not _begun or _closed or not _refusal.is_empty(): return false
	var player: CharacterBody3D = _refs.player.get_ref() as CharacterBody3D
	var warrens: Node3D = _refs.warrens.get_ref() as Node3D
	var rig: Node3D = _refs.rig.get_ref() as Node3D
	if player == null or warrens == null or rig == null: return _refuse("original player/rig/warrens expired")
	var view := _mounted(player, warrens, rig)
	if view.is_empty() or not same_original(_refs, _scripts, view): return _refuse("original mounted source or script replaced")
	if player.process_physics_priority != _priority: return _refuse("actual player physics priority changed")
	for tick: NativeTick in [_pre, _post]:
		if not is_instance_valid(tick) or not tick.is_inside_tree() or tick.is_queued_for_deletion() \
			or tick.get_parent() != view.world or tick.observer.get_ref() != self \
			or tick.process_thread_group != Node.PROCESS_THREAD_GROUP_INHERIT: return _refuse("original observer mount expired")
	if _pre.phase != "pre" or _post.phase != "post" \
		or _pre.process_physics_priority != _priority - 1 or _post.process_physics_priority != _priority + 1:
		return _refuse("original observer bracketing changed")
	return true


func _refuse(reason: String) -> bool:
	if _refusal.is_empty(): _refusal = reason
	return false


func _native_sample(sender: Node, phase: String, delta: float, call_id: RefCounted) -> void:
	var expected: NativeTick = _pre if phase == "pre" else _post if phase == "post" else null
	var native := sender as NativeTick
	if not is_instance_valid(native) or native != expected \
		or call_id == null or native.active_call != call_id or not Engine.is_in_physics_frame() \
		or not is_finite(delta) or delta <= 0.0:
		_refuse("missing or foreign actual native observer callback")
		return
	if not _live(): return
	var note := _snapshot(phase, delta)
	if note.is_empty() or not _buffer.accept(phase, note):
		_refuse("missing, duplicate or different-frame pre/post sample")


func _environment(player: CharacterBody3D) -> Dictionary:
	var service: Variant = player.get("_environment_velocity")
	if not service is RefCounted or service.get_script() != load("res://scripts/world/environment_velocity_modifiers.gd"):
		return {"available": false}
	var entries: Variant = service.get("_entries")
	if not entries is Dictionary: return {"available": false}
	if entries.size() > LIMIT: return {"available": false, "entry_count": entries.size(), "bounded_read_refusal": true}
	var projected: Array = []
	for id: Variant in entries:
		var row: Variant = entries[id]
		if not row is Dictionary: return {"available": false, "malformed_entry": str(id)}
		var owner: Variant = row.get("owner")
		var callback: Variant = row.get("modifier")
		projected.append({"id": str(id), "owner": _identity(owner.get_ref()) if owner is WeakRef else {},
			"order": row.get("order"), "sequence": row.get("sequence"),
			"additive_axes": _v(row.get("additive_axes", Vector3.ZERO)),
			"callback_valid": callback is Callable and callback.is_valid()})
	return {"available": true, "entries": projected, "added": _v(service.get("_added")),
		"surviving": _v(service.get("_surviving")), "last_velocity": _v(service.get("_last_velocity"))}


func _snapshot(phase: String, delta: float) -> Dictionary:
	if not _live(): return {}
	var player: CharacterBody3D = _refs.player.get_ref()
	var warrens: Node3D = _refs.warrens.get_ref()
	var rig: Node3D = _refs.rig.get_ref()
	var game: Node = _refs.game.get_ref()
	var manager: Node = _refs.manager.get_ref()
	var tree := player.get_tree()
	var remaining := _target - player.global_position
	remaining.y = 0.0
	var basis: Basis = rig.call("planar_basis")
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var strengths := {}
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		strengths[action] = Input.get_action_strength(action)
	var contacts: Array = []
	if player.get_slide_collision_count() > LIMIT:
		_refuse("actual contact count exceeds read-only record bound")
		return {}
	for index: int in player.get_slide_collision_count():
		var hit := player.get_slide_collision(index)
		contacts.append({"collider": _identity(hit.get_collider()), "position_world": _v(hit.get_position()),
			"position_local": _v(warrens.to_local(hit.get_position())), "normal_world": _v(hit.get_normal())})
	return {"phase": phase, "physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(),
		"delta": delta, "physics_ticks_per_second": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale,
		"target_world": _v(_target), "target_local": _v(warrens.to_local(_target)),
		"remaining_world": _v(remaining), "distance_planar": remaining.length(),
		"requested_yaw_observed": atan2(-remaining.x, -remaining.z),
		"position_world": _v(player.global_position), "position_local": _v(warrens.to_local(player.global_position)),
		"velocity_world": _v(player.velocity), "floor": player.is_on_floor(), "wall": player.is_on_wall(),
		"floor_normal_world": _v(player.get_floor_normal()), "contacts": contacts,
		"ground_generation": player.get("_foundation_ground_contact_generation"),
		"ground_contact_world": _v(player.get("_foundation_ground_contact_position")),
		"player_physics_processing": player.is_physics_processing(), "tree_paused": tree.paused,
		"input": {"vector": [input.x, input.y], "strengths": strengths, "sprint": Input.is_action_pressed("sprint"),
			"auto_run": game.get("auto_run"), "owner": _identity(INPUT_OWNER.current(tree)),
			"locomotion_enabled": player.get("_locomotion_enabled"), "carried": player.get("_carried")},
		"camera": {"identity": _identity(rig), "yaw": rig.get("yaw"), "basis": [_v(basis.x), _v(basis.y), _v(basis.z)],
			"forward_world": _v(-basis.z), "target": _identity(rig.get("_target")),
			"tracking_target": _identity(rig.get("_tracking_target")), "tracking_config": rig.get("_tracking_config").duplicate(true),
			"tracking_manual_left": rig.get("_tracking_manual_left"), "fight_yaw_target": rig.get("_fight_yaw_target"),
			"talk_active": rig.get("_talk_active"), "talk_leaving": rig.get("_talk_leaving"),
			"fight_composer_valid": rig.get("_fight_frame_composer").is_valid(), "processing": rig.is_processing()},
		"movement": {"wanted_dir_world": _v(player.get("_wanted_dir")), "deflect_world": _v(player.get("_deflect")),
			"deflect_left": player.get("_deflect_left"), "deflect_wanted_world": _v(player.get("_deflect_wanted")),
			"wedged_for": player.get("_wedged_for"), "walk_speed": player.get("_walk_speed"),
			"ground_acceleration": player.get("_ground_accel"), "ground_friction": player.get("_ground_friction")},
		"manager_fighting": manager.call("is_fighting"), "environment": _environment(player)}


func report() -> Dictionary:
	if _begun and not _closed and _refusal.is_empty(): _live()
	return {"read_only": true, "acceptance_credit": false, "cause_proven": false,
		"begun": _begun, "closed": _closed, "lifetime_refusal": _refusal,
		"scope": _scope.duplicate(true), "leg_start": _start.duplicate(true), "leg_end": _end.duplicate(true),
		"pairs": _buffer.pairs.duplicate(true), "complete_pairs_total": _buffer.completed,
		"missing_posts": _buffer.dropped, "pair_rejections": _buffer.rejected,
		"pending_pre": not _buffer.pending.is_empty(), "retained_pair_limit": LIMIT}


func close() -> void:
	if _closed: return
	if _begun and _refusal.is_empty() and _live(): _end = _snapshot("leg_end", 0.0)
	_buffer.seal()
	_closed = true
	for tick: NativeTick in [_pre, _post]:
		if is_instance_valid(tick):
			if tick.active_call != null: tick.queue_free()
			else: tick.free()
	_pre = null
	_post = null
