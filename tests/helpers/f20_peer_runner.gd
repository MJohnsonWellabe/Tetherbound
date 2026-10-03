extends "res://tools/net/peer_runner.gd"

## F20-only runner. The shared runner and other feature fixtures are untouched.
const F20 := preload("res://tests/helpers/f20_ending_probe.gd")
var f20 := F20.new()
var _f20_arrival_trace_at := 0
var _f20_arrival_projections: Dictionary = {}

func _send_heartbeat() -> void:
	super._send_heartbeat()
	# Observe the pending shipping arrival on both peers at most once/10s.
	# Read stored physical samples; foundation_ground_contact() also admits
	# character state, so this observer must not call it or trigger a save.
	if Time.get_ticks_msec() < _f20_arrival_trace_at: return
	var game := root.get_node_or_null("Game")
	if game == null or game.get("session") == null: return
	var session: Node = game.get("session")
	var arrival := session.get_node_or_null("FoundationComposition/PortalArrival")
	if arrival == null: return
	var pending: Dictionary = arrival.get("_pending")
	var remote: Dictionary = arrival.get("_remote")
	var requests: Dictionary = session.get("_portal_requests")
	if pending.is_empty() and remote.is_empty() and requests.is_empty(): return
	_f20_arrival_trace_at = Time.get_ticks_msec() + 10000
	var key := game.get_node_or_null("HomeKey")
	var player := game.call("find_player") as CharacterBody3D
	print("F20 ARRIVAL peer=", _peer_index, " ticks_ms=", Time.get_ticks_msec(),
		" physics=", Engine.get_physics_frames(), " requests=", requests,
		" key_phase=", key.get("_phase") if key != null else "none",
		" key_pending=", key.get("_pending") if key != null else "none",
		" pending_keys=", pending.keys(), " seated=", pending.get("seated", false),
		" pose_saved=", pending.get("pose_saved", false), " journal_started=", pending.get("journal_started", false),
		" save_wait_notified=", pending.get("save_wait_notified", false),
		" player=", player.global_position if player != null else Vector3.INF,
		" floor=", player.is_on_floor() if player != null else false)
	var retry: Dictionary = session.get("_owner_training_retry")
	print("F20 ARRIVAL owner retry_keys=", retry.keys(), " retry_receipt=", retry.get("receipt", ""),
		" retry_saved=", retry.get("saved", false), " install=", session.get("_owner_training_install"),
		" bootstrap_waiting=", session.get("_training_bootstrap_waiting"),
		" receipts=", game.local.redesign_character.get("transaction_receipts", []))
	for value: Variant in game.world.reward_deliveries.values():
		if value is Dictionary and value.get("action") == "portal_arrival":
			print("F20 ARRIVAL row character=", value.get("character_id", ""),
				" status=", value.get("status", ""), " intent=", value.get("intent", {}),
				" receipt=", value.get("receipt", ""))
			# One detached owner projection per original local pending receipt.
			# The pure plan reports its comparison, not an apply/save BOOL result.
			var receipt: String = str(value.get("receipt", ""))
			if value.get("character_id") == game.local.character_id and value.get("status") == "pending" \
					and not receipt.is_empty() and not _f20_arrival_projections.has(receipt):
				_f20_arrival_projections[receipt] = true
				var record := preload("res://scripts/net/character_record_rules.gd")
				var delivery := preload("res://scripts/net/character_action_delivery.gd")
				var current: Dictionary = record.portable_projection(game.local.call("save_data"))
				var plan: Dictionary = delivery.owner_plan(current, value, record.errors)
				print("F20 ARRIVAL detached owner comparison ", JSON.stringify({
					"receipt": receipt, "current": current, "before": value.get("before", {}),
					"after": value.get("after", {}), "pure_plan_ok": plan.get("ok", false),
					"pure_plan_code": plan.get("code", ""), "pure_plan_duplicate": plan.get("duplicate", false)}))
	var lifecycle := session.get_node_or_null("FoundationComposition/TravelLifecycle")
	for peer: int in remote:
		var original: Dictionary = remote[peer]
		var body: CharacterBody3D = lifecycle.call("remote_body", peer) if lifecycle != null else null
		print("F20 ARRIVAL remote peer=", peer, " permit=", original.get("permit", {}),
			" owner_saved=", original.get("owner_saved", false), " journal_started=", original.get("journal_started", false),
			" body=", body.get_path() if body != null else "none",
			" position=", body.global_position if body != null else Vector3.INF,
			" floor=", body.is_on_floor() if body != null else false,
			" contact_frame=", body.get("_foundation_ground_contact_frame") if body != null else -1,
			" contact_position=", body.get("_foundation_ground_contact_position") if body != null else Vector3.INF,
			" contact_generation=", body.get("_foundation_ground_contact_generation") if body != null else -1)

func _boot_scene(which: String, settle: int) -> void:
	await process_frame
	var game := root.get_node("Game")
	if not f20.fixture(game, "Peer%d" % _peer_index):
		quit(2); return
	# reset_for_new_game in the disclosed setup reclaims solo ownership.
	# Restore the shipping joiner's guard before a throwaway world is built.
	if OS.get_cmdline_user_args().has("--joiner"):
		# A shipping guest resumes its portable character, with no host-world
		# slot competing with that newer acknowledgement on the title route.
		if not f20.check(game.save_system.call("delete_slot", 0) and not game.call("has_save", 0),
			"guest fixture retains only its portable character save"):
			quit(2); return
		game.call("relinquish_world_save_ownership")
	await super._boot_scene(which, settle)

func _execute_step(msg: Dictionary) -> Dictionary:
	var action: String = str(msg.get("action", ""))
	var game := root.get_node("Game")
	var passed := false
	match action:
		"f20_return": passed = await f20.return_home(self, game)
		"f20_talk": passed = await f20.open_credits(self, game)
		"f20_skip": passed = await f20.finish_credits(self, game)
		"f20_revisit": passed = await f20.revisit_completed(self, game)
		"f20_fifth": passed = await f20.fifth(self, game)
		"f20_inspect":
			var retained := f20.retained(game)
			if not f20.check(f20.retained_valid(retained), "peer inspection retains a complete detached character snapshot"):
				return {"verdict": "FAIL", "detail": str(f20.failures)}
			return {"verdict": "PASS", "data": {"retained": retained,
				"context": F20.HOME.journey_context(game), "checks": f20.checks,
				"credits_open": _f20_credits_open()}}
		_:
			return await super._execute_step(msg)
	return {"verdict": "PASS" if passed else "FAIL", "detail": str(f20.failures),
		"data": {"checks": f20.checks, "context": F20.HOME.journey_context(game)}}

func _f20_credits_open() -> bool:
	for node: Node in get_nodes_in_group("story_modal"):
		if node.get_script() == load("res://scripts/ui/regional_credits.gd") and node.call("is_open"): return true
	return false
