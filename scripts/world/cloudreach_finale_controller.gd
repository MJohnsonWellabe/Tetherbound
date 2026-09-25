extends Node3D

## Summit encounter environment. Canonical ProgressionState is the only durable
## store. Combat owns team/HP/win detection; the chapter adapter owns rewards.
## Call apply_hazards AFTER locomotion chooses velocity and BEFORE move_and_slide.
## No automatic body movement, human attack, roster or second save payload here.
signal phase_changed(phase: String)
signal captain_defeated()
signal relay_disabled(relay_id: String)
signal network_disabled()
signal aftermath_restored()
signal presentation_changed(state: Dictionary)
signal recovery_requested(body: CharacterBody3D, camp_id: String, safe_position: Vector3)

const CONFIG_PATH := "res://data/config/cloudreach_finale.json"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

## D97, Stage B lane 6.E. A summit relay going dark is a fact about CLOUDREACH,
## whichever realm the peer that broke it happens to be standing in. Never
## `Game.current_realm`.
const REALM_ID := "cloudreach"

var config: Dictionary = {}
var phase := "dormant"
var elapsed := 0.0
var _progression: RefCounted
var _chapter_event: Callable
var _controlled_body: Callable
var _creature_piloted: Callable
var _recovery_handoff: Callable
var _revision := -1
var _in_encounter := false
var _overload := false
var _presentation: Dictionary = {}
var _prompts: Dictionary = {}
var _pending_recoveries: Dictionary = {}
var _hazard_drift: Dictionary = {}
## Flags THIS peer has asked the host for and the host has not answered yet,
## flag id -> what landing it completes ("win", "relay:<id>", "network",
## "witness"). A client's submit answers `pending`; while its flag is in here
## the same intent is never submitted again (`witness_restoration` is polled
## every frame), and when the committed delta sets the flag
## `_settle_landed()` finishes the local half the press could not -- the
## signal, and for the win the encounter bookkeeping. Solo and host commit in
## place and never put anything here. Never persisted: no intent survives a
## reload.
var _in_flight: Dictionary = {}
## Injected transport with `Game.ledger`'s `submit()` shape, for a unit fixture
## that has to answer `pending`. Null in production: `LEDGER_CLAIM.transport()`.
var ledger_transport: Node = null
## The fight this encounter mirrors: the encounter director whose
## `trainer_started`/`trainer_victory`/`trainer_lost` reach `encounter_started`/
## `encounter_won`/`encounter_lost` (`cloudreach_world_runtime.gd` mounts it
## beside this node). Injected by a fixture; null in production, where
## `_fight_director()` finds that sibling by its `trainer_battle_active()` /
## `trainer_battle_id()` surface. Read only by `restore_progression_from_game`.
var fight_director: Node = null
var _found_director: Node = null
## `_committed_seq()` once the last committed delta this node heard of had
## settled; -1 until a ledger is found. See `_delta_sweep`.
var _seq_baseline := -1


static func read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}


## body_source returns the currently piloted CharacterBody (it can switch).
## creature_source returns whether it is a creature, so a human cannot strike.
## recover(body, camp_id, world_position) owns combat exit/Fly exit/camp placement.
func setup(progression: RefCounted, event_adapter: Callable, body_source: Callable,
		creature_source: Callable, recover: Callable = Callable(), data: Dictionary = {}) -> void:
	_progression = progression
	_chapter_event = event_adapter
	_controlled_body = body_source
	_creature_piloted = creature_source
	_recovery_handoff = recover
	config = read_config() if data.is_empty() else data.duplicate(true)
	position = vec(config.get("arena_origin", []))
	_in_encounter = false
	_overload = false
	elapsed = 0.0
	_pending_recoveries.clear()
	_hazard_drift.clear()
	_in_flight.clear()
	_revision = -1
	sync_progression()
	if is_inside_tree():
		build_interactions()


func _ready() -> void:
	add_to_group("progression_restore")
	_listen_for_deltas()
	if not config.is_empty():
		build_interactions()


func _process(delta: float) -> void:
	if _progression == null:
		return
	if int(_progression.get("revision")) != _revision:
		sync_progression()
	elapsed += delta
	_sync_prompt_access()
	# A `seq` that moved without a `delta_applied` (a snapshot's own `seq`)
	# must not make a later load read as a delta.
	if _seq_baseline >= 0:
		_settle_seq_baseline()


## Also the CLIENT's delta path: `ledger_rpc.gd::apply_remote_delta` sweeps
## `progression_restore` after every committed delta, so `_in_flight` is kept
## here -- clearing it would drop exactly the win/relay/witness whose delta is
## landing -- and `sync_progression()` below settles whatever it set. Only a
## different store object drops them, since their flags belong to the old one.
##
## The same sweep used to end a live Veyra fight on a client whenever any
## unrelated delta landed (a pickup, another peer's flag): the phase dropped to
## `dormant` and the crosswind/overload hazards and their clock restarted. It
## also restarted the break_the_eye wind on every relay another peer struck.
## The host and solo reach this sweep only from a save load or a snapshot,
## since `_commit_here` does not sweep and Cloudreach mounts no sequence
## director to run `story_ledger.gd::restore_all`.
##
## `Game.load_game()` and `apply_world_snapshot()` reload the SAME store in
## place (`Game.progression` is one merged view for the whole process), so the
## store alone cannot tell a load from a delta. Two authorities decide instead:
## - the encounter survives while the director still runs this trainer battle
##   and the flags still admit it (`_encounter_survives`);
## - otherwise the hazard clock, drift and pending recoveries survive only a
##   sweep for a committed delta (`_delta_sweep`) that leaves the phase as it
##   was.
## A load or snapshot with the fight over, flags that no longer admit it, or a
## different store all reset as before.
func restore_progression_from_game(game: Node) -> void:
	_listen_for_deltas()
	var restored: RefCounted = game.get("progression")
	var same_store := restored == _progression
	if not same_store:
		_in_flight.clear()
	_progression = restored
	var keep_encounter := same_store and _encounter_survives()
	if not keep_encounter:
		_in_encounter = false
		_overload = false
	if keep_encounter or (same_store and _delta_sweep() and _derived_phase() == phase):
		_keep_deep_recoveries()
	else:
		elapsed = 0.0
		_pending_recoveries.clear()
		_hazard_drift.clear()
	_revision = -1
	sync_progression()


## Whether a sweep leaves this encounter running: it was running, the store's
## flags still admit it (`encounter_started`'s own gate), and the fight it
## mirrors has not ended. With no director to ask it resets: nothing then says
## the fight is still on. The director can only END the encounter here; only
## `encounter_started` begins one.
func _encounter_survives() -> bool:
	if not _in_encounter or not _prerequisites() \
			or _has(str(config.get("captain_victory_flag", ""))):
		return false
	var director := _fight_director()
	if director == null:
		return false
	return bool(director.call("trainer_battle_active")) \
		and str(director.call("trainer_battle_id")) == str(config.get("encounter_id", ""))


func _fight_director() -> Node:
	if is_instance_valid(fight_director):
		return fight_director
	if is_instance_valid(_found_director):
		return _found_director
	var parent := get_parent()
	if parent == null:
		return null
	for sibling: Node in parent.get_children():
		if sibling != self and sibling.has_method("trainer_battle_active") \
				and sibling.has_method("trainer_battle_id"):
			_found_director = sibling
			return sibling
	return null


## The ledger's commit count (`world_ledger.gd::seq`), or -1 with no ledger.
func _committed_seq() -> int:
	var transport := _transport()
	if transport == null:
		return -1
	var ledger: Variant = transport.get("ledger")
	return int((ledger as Object).get("seq")) if ledger is Object else -1


## Is this sweep running for a committed delta? A client's
## `apply_remote_delta` advances the ledger's `seq` and sweeps BEFORE it emits
## `delta_applied`; the baseline catches up only after that emit, deferred, so
## a second sweep for the same delta in the same frame still reads as one. A
## load or snapshot leaves `seq` where the last settled delta put it. No
## ledger: not a delta, so the conservative reset.
##
## Known limitation: this reads the ledger's counter rather than being told.
## Where a client's `seq` already stands above the host's (the same process
## committed solo and then joined, or the host restarted), `apply_remote_delta`
## leaves `seq` unmoved (`world_ledger.gd` keeps the max) and every delta reads
## as a load: the conservative reset, i.e. the pre-fix behaviour outside a live
## fight. The proper fix is an explicit "sweeping for a delta" marker set by
## `ledger_rpc.gd::apply_remote_delta` around its sweep (another lane's file).
func _delta_sweep() -> bool:
	var seq := _committed_seq()
	return seq >= 0 and _seq_baseline >= 0 and seq > _seq_baseline


func _listen_for_deltas() -> void:
	var transport := _transport()
	if transport == null or not transport.has_signal("delta_applied"):
		return
	if not transport.is_connected("delta_applied", _on_delta_applied):
		transport.connect("delta_applied", _on_delta_applied)
		if _seq_baseline < 0:
			_seq_baseline = _committed_seq()


func _on_delta_applied(_delta: Dictionary) -> void:
	_settle_seq_baseline.call_deferred()


func _settle_seq_baseline() -> void:
	_seq_baseline = _committed_seq()


## A kept sweep keeps each recovery handoff exactly as long as
## `_apply_recovery_current` would: while its body is still in the world and
## below the current's depth (`current_below_deck_m`). A body that has risen
## above it, or is gone, is erased, as that function would erase it on the
## next frame. So one fall is never handed off twice.
func _keep_deep_recoveries() -> void:
	var current := float(config.get("recovery", {}).get("current_below_deck_m", 0.0))
	for id: int in _pending_recoveries.keys():
		var body: Node3D = instance_from_id(id) as Node3D if is_instance_id_valid(id) else null
		if body == null or not body.is_inside_tree() \
				or body.global_position.y - _origin().y > -current:
			_pending_recoveries.erase(id)


func _has(flag: String) -> bool:
	return _progression != null and bool(_progression.call("has", flag))


## Submit one relay's world flag through `Game.ledger`, and hand back
## `world_ledger.gd`'s verdict shape -- always, never null. A process with no
## transport (a unit fixture, `tests/test_cloudreach_finale.gd`) answers
## `offline`, and the caller keeps its old local write there.
func _write_relay_flag(flag: String) -> Dictionary:
	var transport := _transport()
	if transport == null:
		return {"ok": false, "kind": "set_world_flag", "peer": 0, "code": "offline",
			"reason": "", "pending": false, "delta": {"seq": 0, "realm": "", "ops": []}}
	return transport.call("submit",
		{"kind": "set_world_flag", "realm": REALM_ID, "id": flag, "value": true})


func _transport() -> Node:
	if is_instance_valid(ledger_transport):
		return ledger_transport
	return LEDGER_CLAIM.transport(self)


## Remember an intent the host has not answered, and hear a refusal of it: a
## refused flag never lands, and without this its entry would block a retry
## for the rest of the session (`item_cache_pickup.gd`'s `_claiming` rule).
func _track(flag: String, tag: String) -> void:
	_in_flight[flag] = tag
	var transport := _transport()
	if transport != null and transport.has_signal("intent_refused") \
			and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


## The verdict does not name its flag, so a flag refusal releases every entry.
## Worst case is one repeated intent, which the host commits as a `noop`.
func _on_intent_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if _in_flight.is_empty() or kind not in ["set_world_flag", "grant_player_flag"]:
		return
	_in_flight.clear()
	_sync_prompt_access()


func _prerequisites() -> bool:
	for flag: String in config.get("requires_flags", []):
		if not _has(flag):
			return false
	return not config.is_empty()


## The chapter adapter's whole result. `pending` there means a client submitted
## the event's flag and nothing is set yet (`realm_chapter_progression.gd`).
func _dispatch(event: String) -> Dictionary:
	if not _chapter_event.is_valid():
		return {}
	var result: Variant = _chapter_event.call(event)
	return result if result is Dictionary else {}


## Connect from the production encounter start; rejects wrong encounters/order.
func encounter_started(encounter_id: String) -> bool:
	if encounter_id != str(config.get("encounter_id", "")) or not _prerequisites() \
			or _has(str(config["captain_victory_flag"])):
		return false
	if _in_encounter:
		return false
	_in_encounter = true
	_overload = false
	elapsed = 0.0
	sync_progression()
	return true


## Combat reports the ACTUAL surviving opposition count; no HP multiplier.
func opposition_remaining(encounter_id: String, remaining: int, initial: int) -> void:
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")):
		return
	if initial > 0 and remaining > 0 and remaining <= initial / 2.0 and not _overload:
		_overload = true
		elapsed = 0.0
		sync_progression()


## Wire ONLY to the production captain-victory callback, never a dialogue effect.
## Zero opposition count alone deliberately cannot manufacture the win.
## On a client the win is `pending`: nothing is granted yet, the intent is
## remembered, and `_settle_landed()` ends the encounter and emits
## `captain_defeated` once when the committed delta sets the flag.
func encounter_won(encounter_id: String) -> bool:
	var victory := str(config.get("captain_victory_flag", ""))
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")) \
			or not _prerequisites() or _has(victory) or _in_flight.has(victory):
		return false
	var result := _dispatch(str(config["captain_victory_event"]))
	if not bool(result.get("accepted", false)) or not _has(victory):
		# Only this event's own accepted-but-pending write is tracked; a
		# `pending` merged in from an unrelated reconcile must not set a guard
		# nothing will ever clear.
		if bool(result.get("accepted", false)) and bool(result.get("pending", false)):
			_track(victory, "win")
		return false
	_in_encounter = false
	elapsed = 0.0
	sync_progression()
	captain_defeated.emit()
	return true


func encounter_lost(encounter_id: String, body: CharacterBody3D) -> bool:
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")):
		return false
	_in_encounter = false
	_overload = false
	sync_progression()
	_request_recovery(body)
	return true


func sync_progression() -> void:
	if _progression == null or config.is_empty():
		return
	# Safe repair after a save between the third relay write and aggregate event.
	var network := str(config["network_flag"])
	if _has(str(config["captain_victory_flag"])) and _all_relays_disabled() \
			and not _has(network) and not _in_flight.has(network):
		var repair := _dispatch(str(config["network_event"]))
		if bool(repair.get("accepted", false)) and bool(repair.get("pending", false)):
			_track(network, "network")
	var next := _derived_phase()
	if next != phase:
		phase = next
		phase_changed.emit(phase)
	_revision = int(_progression.get("revision"))
	_sync_prompt_access()
	var state := presentation_state()
	if state != _presentation:
		_presentation = state.duplicate(true)
		presentation_changed.emit(state)
	_settle_landed()


## The phase the current flags and encounter state call for.
func _derived_phase() -> String:
	if config.is_empty():
		return phase
	if _has(str(config["aftermath_flag"])):
		return "restored"
	if _has(str(config["network_flag"])):
		return "awaiting_restoration"
	if _has(str(config["captain_victory_flag"])):
		return "break_the_eye"
	if _in_encounter:
		return "anchor_overload" if _overload else "crosswind_command"
	return "dormant"


## Finish, once, each pending intent whose committed delta has now set its flag.
## Reached from the revision poll in `_process` and from the client's
## `progression_restore` sweep, whichever runs first; the entry is erased
## BEFORE its signal, so a handler that re-enters `sync_progression()` cannot
## emit it twice. Phase is already current when this runs.
func _settle_landed() -> void:
	for flag: String in _in_flight.keys():
		# A handler re-entering `sync_progression()` may already have settled
		# and erased a later entry of this same pass.
		if not _in_flight.has(flag) or not _has(flag):
			continue
		var tag := str(_in_flight[flag])
		_in_flight.erase(flag)
		if tag == "win":
			_in_encounter = false
			elapsed = 0.0
			captain_defeated.emit()
		elif tag == "network":
			network_disabled.emit()
		elif tag == "witness":
			aftermath_restored.emit()
		elif tag.begins_with("relay:"):
			relay_disabled.emit(tag.trim_prefix("relay:"))


func presentation_state() -> Dictionary:
	var relays: Dictionary = {}
	for relay: Dictionary in config.get("relays", []):
		relays[str(relay["id"])] = _has(str(relay["flag_id"])) or _has(str(config["network_flag"]))
	var freed := _has(str(config.get("aftermath_flag", "")))
	return {"phase": phase, "relays_disabled": relays,
		"hazards_active": phase in ["crosswind_command", "anchor_overload", "break_the_eye"],
		"anchor_drone_active": not _has(str(config.get("network_flag", ""))),
		"natural_wind_trails": freed, "travelers_reconnected": freed,
		"restored_route_currents": freed, "waterward_visible": _has("stormward_route_revealed")}


func build_interactions() -> void:
	if not _prompts.is_empty():
		return
	for relay: Dictionary in config.get("relays", []):
		var prompt := INTERACTABLE.new()
		prompt.name = "Relay_" + str(relay["id"])
		prompt.position = vec(relay["offset"]) + Vector3.UP
		prompt.configure("Strike the exposed %s relay" % relay["id"],
			float(config["relay_interaction_radius_m"]), false)
		prompt.activated.connect(_activate_relay.bind(str(relay["id"])))
		add_child(prompt)
		_prompts[str(relay["id"])] = prompt
	_sync_prompt_access()


func _sync_prompt_access() -> void:
	var piloted := _creature_piloted.is_valid() and bool(_creature_piloted.call())
	for relay: Dictionary in config.get("relays", []):
		var id := str(relay["id"])
		if _prompts.has(id):
			var flag := str(relay["flag_id"])
			_prompts[id].set_enabled(phase == "break_the_eye" and piloted and not _has(flag) \
				and not _in_flight.has(flag))


func _activate_relay(id: String) -> void:
	if not _controlled_body.is_valid():
		return
	strike_relay(id, _controlled_body.call() as CharacterBody3D)


## Public for a production creature hit adapter as well as the shared prompt.
## Validate actor, range, vertical access and sight AGAIN at action time.
func strike_relay(id: String, body: CharacterBody3D) -> bool:
	if not is_inside_tree() or phase != "break_the_eye" or not _has(str(config["captain_victory_flag"])) \
			or not _prerequisites() or not is_instance_valid(body) \
			or not _controlled_body.is_valid() or _controlled_body.call() != body \
			or not _creature_piloted.is_valid() or not bool(_creature_piloted.call()):
		return false
	for relay: Dictionary in config.get("relays", []):
		if str(relay["id"]) != id or _has(str(relay["flag_id"])):
			continue
		if _in_flight.has(str(relay["flag_id"])):
			return false
		var target := _origin() + vec(relay["offset"]) + Vector3.UP
		if body.global_position.distance_to(target) > float(config["relay_interaction_radius_m"]):
			return false
		if _prompts.has(id) and _prompts[id].interaction_offer(body.global_position).is_empty():
			return false
		var network_was_disabled := _has(str(config["network_flag"]))
		# D103, lane 6.E. "A relay went dark" is the canonical world fact -- it
		# was a local `set_flag`, so two players at the summit could each hold a
		# different count of how many of the three were still lit. Submitted as
		# an intent; the host commits it once and every peer applies the delta.
		#
		# A client's verdict is `pending`: nothing has gone dark YET, so this
		# answers false and emits nothing. `_process`'s existing revision poll
		# lands on `sync_progression()` when the delta arrives, which is the same
		# path a save load already takes -- and `sync_progression()`, not this
		# press, is what the arena's presentation is actually drawn from. The
		# relay is remembered as in flight (prompt off, no second submit) and
		# `_settle_landed()` emits `relay_disabled` when its flag lands.
		var verdict := _write_relay_flag(str(relay["flag_id"]))
		if bool(verdict.get("pending", false)):
			_track(str(relay["flag_id"]), "relay:" + id)
			_sync_prompt_access()
			return false
		if not bool(verdict.get("ok", false)):
			if str(verdict.get("code", "")) != "offline":
				return false
			# No transport at all (a unit fixture, a capture tool): the old
			# local write, unchanged.
			_progression.call("set_flag", str(relay["flag_id"]))
		sync_progression()
		relay_disabled.emit(id)
		if not network_was_disabled and _has(str(config["network_flag"])):
			network_disabled.emit()
		return true
	return false


func _all_relays_disabled() -> bool:
	var relays: Array = config.get("relays", [])
	if relays.size() != 3:
		return false
	for relay: Dictionary in relays:
		if not _has(str(relay["flag_id"])):
			return false
	return true


## Call on physical arrival at the delegation's overlook. Reward dialogue is a
## separate chapter event: witnessing restoration never grants the Heart/key.
## Polled every frame by the runtime; a client's pending witness is submitted
## once and `aftermath_restored` is emitted by `_settle_landed()`.
func witness_restoration(body: CharacterBody3D) -> bool:
	var aftermath := str(config.get("aftermath_flag", ""))
	if not is_instance_valid(body) or not _controlled_body.is_valid() \
			or _controlled_body.call() != body or not _has(str(config["network_flag"])) \
			or _has(aftermath) or _in_flight.has(aftermath):
		return false
	var witness: Dictionary = config["aftermath_witness"]
	var offset := body.global_position - vec(witness["position"])
	if Vector2(offset.x, offset.z).length() > float(witness["radius_m"]) \
			or absf(offset.y) > float(witness["height_tolerance_m"]):
		return false
	var result := _dispatch(str(config["aftermath_event"]))
	if not bool(result.get("accepted", false)) or not _has(aftermath):
		if bool(result.get("accepted", false)) and bool(result.get("pending", false)):
			_track(aftermath, "witness")
		return false
	sync_progression()
	aftermath_restored.emit()
	return true


func _origin() -> Vector3:
	return global_position if is_inside_tree() else position


static func vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw.size() == 3 else Vector3.ZERO


static func cycle_stage(at: float, spec: Dictionary) -> String:
	var cycle := maxf(0.1, float(spec["cycle_seconds"]))
	var cursor := fposmod(at, cycle)
	if cursor < float(spec["telegraph_seconds"]):
		return "telegraph"
	return "recovery" if cursor >= cycle - float(spec["recovery_window_seconds"]) else "active"


## Renderer and movement consume the SAME field sample/timer. A lee pocket is
## safe at every rotation; arena height checks exclude stacked lower paths.
func hazard_at(world_position: Vector3, at: float = -1.0) -> Dictionary:
	var result := {"wind": Vector3.ZERO, "arc": Vector3.ZERO, "sheltered": false,
		"wind_stage": "idle", "arc_stage": "idle"}
	if phase not in ["crosswind_command", "anchor_overload", "break_the_eye"]:
		return result
	var local := world_position - _origin()
	var point := Vector2(local.x, local.z)
	if point.length() > float(config["arena_radius_m"]) \
			or absf(local.y) > float(config["arena_height_tolerance_m"]):
		return result
	for lee: Dictionary in config["lee_pockets"]:
		var centre := vec(lee["offset"])
		if point.distance_to(Vector2(centre.x, centre.z)) <= float(lee["radius_m"]):
			result["sheltered"] = true
			return result
	var t := elapsed if at < 0.0 else at
	var wind: Dictionary = config["wind"]
	var angle := deg_to_rad(t * float(wind["rotation_degrees_per_second"]))
	var normal := Vector2(cos(angle), sin(angle))
	var along := Vector2(-normal.y, normal.x)
	result["wind_stage"] = cycle_stage(t, wind)
	for offset: float in wind["lane_offsets_m"]:
		if absf(point.dot(normal) - offset) <= float(wind["lane_half_width_m"]) \
				and result["wind_stage"] == "active":
			result["wind"] = Vector3(along.x, 0, along.y) * float(wind["acceleration_mps2"])
	if phase == "crosswind_command":
		return result
	var arc: Dictionary = config["relay_arc"]
	result["arc_stage"] = cycle_stage(t, arc)
	if result["arc_stage"] != "active" or point.length() < float(arc["inner_radius_m"]) \
			or point.length() > float(arc["outer_radius_m"]):
		return result
	var rotation := deg_to_rad(t * float(arc["rotation_degrees_per_second"]))
	for sector in range(3):
		var difference := wrapf(point.angle() - rotation - sector * TAU / 3.0, -PI, PI)
		if absf(difference) <= deg_to_rad(float(arc["sector_half_angle_degrees"])):
			var inward := -point.normalized() * float(arc["repulsion_acceleration_mps2"])
			result["arc"] = Vector3(inward.x, 0, inward.y)
	return result


## CharacterBody remains collision owner. The caller supplies its chosen
## locomotion velocity each frame, BEFORE this function adds external drift.
## Drift is transient, bounded and decays promptly on entering a lee pocket.
## Never calls move_and_slide twice or reuses pre-collision airborne positions.
func apply_hazards(body: CharacterBody3D, delta: float) -> Dictionary:
	if not is_instance_valid(body) or delta <= 0.0 or config.is_empty():
		return {}
	var sample := hazard_at(body.global_position)
	var wind: Vector3 = sample["wind"]
	var arc: Vector3 = sample["arc"]
	var drift: Vector3 = _hazard_drift.get(body.get_instance_id(), Vector3.ZERO)
	var force := wind + arc
	if force.is_zero_approx():
		drift = drift.move_toward(Vector3.ZERO, 30.0 * delta)
	else:
		var limit := float(config["relay_arc"]["max_push_speed_mps"]) if not arc.is_zero_approx() \
			else float(config["wind"]["max_push_speed_mps"])
		drift = (drift + force * delta).limit_length(limit)
	_hazard_drift[body.get_instance_id()] = drift
	body.velocity += drift
	_apply_recovery_current(body)
	return sample


func _apply_recovery_current(body: CharacterBody3D) -> void:
	# Recovery remains usable after the engine is disabled, including restored play.
	if phase == "dormant":
		return
	var local := body.global_position - _origin()
	var recovery: Dictionary = config["recovery"]
	var id := body.get_instance_id()
	if local.y > -float(recovery["current_below_deck_m"]):
		_pending_recoveries.erase(id)
		return
	if Vector2(local.x, local.z).length() > float(recovery["current_radius_m"]):
		return
	if local.y < -float(recovery["handoff_below_deck_m"]):
		_request_recovery(body)
		return
	var inward := -Vector3(local.x, 0, local.z).normalized()
	body.velocity = inward * float(recovery["inward_speed_mps"]) \
		+ Vector3.UP * float(recovery["lift_speed_mps"])


func _request_recovery(body: CharacterBody3D) -> void:
	if not is_instance_valid(body) or _pending_recoveries.has(body.get_instance_id()):
		return
	_pending_recoveries[body.get_instance_id()] = true
	_hazard_drift.erase(body.get_instance_id())
	var recovery: Dictionary = config["recovery"]
	var camp_id := str(recovery["safe_camp_id"])
	var safe := vec(recovery["safe_position"])
	recovery_requested.emit(body, camp_id, safe)
	if _recovery_handoff.is_valid():
		_recovery_handoff.call(body, camp_id, safe)
