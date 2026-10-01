extends SceneTree

## Named F18 component rules. Synthetic host context is UNIT evidence only.
## ROOT runs after integration under its engine token, supplying --policy-path
## when the accepted shared policy differs from the ignored proposal path.
const ARCH := preload("res://scripts/world/portal_arch.gd")
const HOME := preload("res://scripts/world/home_key.gd")
const STONES := preload("res://scripts/world/waystone.gd")
var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	var path := "res://.tmp/f18-authority/portal_action_policy.gd"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--policy-path="):
			path = arg.trim_prefix("--policy-path=")
	var policy_script := load(path) as Script
	if policy_script == null:
		push_error("F18 policy unavailable: " + path)
		quit(1)
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	var stones := STONES.load_config()
	var policy: RefCounted = policy_script.new()
	policy.call("bind_world", "unit-world-instance")
	var context := _context()
	for field: String in ["combat", "dialogue", "cutscene", "swimming", "flying", "downed"]:
		var refused := context.duplicate(true)
		refused[field] = true
		_check(not str(policy_script.call("refusal", refused)).is_empty(), "HomeKey refusal " + field)
	var malformed := context.duplicate(true)
	malformed.erase("combat")
	_check(not str(policy_script.call("refusal", malformed)).is_empty(), "missing host state refuses")
	_check(not bool(policy_script.call("valid_payload", {"kind": "portal_enter", "arch_id": "tidewake", "realm": "water"})), "client destination injection refuses")
	var begin: Dictionary = policy.call("evaluate", {"kind": "home_key_begin"}, context, config, stones, 1000)
	_check(bool(begin.get("ok", false)), "safe owned HomeKey starts")
	var use_id := str((begin.get("prepared", {}) as Dictionary).get("use_id", ""))
	var impostor := context.duplicate(true)
	impostor.peer_id = 2
	_check(not bool(_evaluate(policy, {"kind": "home_key_finish", "use_id": use_id}, impostor, config, stones, 3500).get("ok", false)), "channel binds peer")
	_check(not bool(_evaluate(policy, {"kind": "home_key_finish", "use_id": use_id}, context, config, stones, 1500).get("ok", false)), "early finish refuses")
	var finish := _evaluate(policy, {"kind": "home_key_finish", "use_id": use_id}, context, config, stones, 3500)
	_check(bool(finish.get("ok", false)), "full raise yields host permit")
	_check(not bool(_evaluate(policy, {"kind": "home_key_finish", "use_id": use_id}, context, config, stones, 4000).get("ok", false)), "finish replay refuses")
	var permit_id := str((finish.get("prepared", {}) as Dictionary).get("travel_permit", ""))
	_check((policy.call("consume_permit", permit_id, 2, "unit-character", "unit-world-instance", "stormwood") as Dictionary).is_empty(), "permit binds peer")
	var permit: Dictionary = policy.call("consume_permit", permit_id, 1, "unit-character", "unit-world-instance", "stormwood")
	_check(permit.get("realm") == "meadows" and permit.get("entry_id") == "hall_home", "HomeKey selects home arch")
	_check((policy.call("consume_permit", permit_id, 1, "unit-character", "unit-world-instance", "stormwood") as Dictionary).is_empty(), "permit consumes once")
	context.realm = "meadows"
	context.position = Vector3.ZERO
	context.arch_positions = {"tidewake": Vector3.ZERO, "biome5": Vector3.ZERO}
	_check(not bool(_evaluate(policy, {"kind": "portal_enter", "arch_id": "tidewake"}, context, config, stones, 5000).get("ok", false)), "locked arch refuses")
	context.world_unlocks = ["tidewake"]
	_check(bool(_evaluate(policy, {"kind": "portal_enter", "arch_id": "tidewake"}, context, config, stones, 5000).get("ok", false)), "behind peer follows world unlock")
	_check(context.character_unlocks.is_empty(), "world travel grants no personal unlock")
	context.world_unlocks = []
	context.character_unlocks = ["tidewake"]
	_check(bool(_evaluate(policy, {"kind": "portal_enter", "arch_id": "tidewake"}, context, config, stones, 5000).get("ok", false)), "portable personal unlock admits traveler")
	context.last_waystones = {"tidewake": "stormwood_ashfoot_waycamp"}
	context.waystones_activated = {"tidewake": ["stormwood_ashfoot_waycamp"]}
	_check(not bool(_evaluate(policy, {"kind": "portal_enter", "arch_id": "tidewake"}, context, config, stones, 5000).get("ok", false)), "cross-biome saved return refuses")
	_check(not bool(_evaluate(policy, {"kind": "portal_enter", "arch_id": "biome5"}, context, config, stones, 5000).get("ok", false)), "fifth never yields travel")
	context.owned_portal_keys = {"fifth_portal_key": 1}
	_check(bool(_evaluate(policy, {"kind": "portal_unlock", "arch_id": "biome5"}, context, config, stones, 5000).get("ok", false)), "fifth prepares spend only")
	var fifth: Dictionary = config.arches[4]
	_check(ARCH.prompt_text(fifth, {"ready": true, "has_key": true}) == "Use the fifth key", "sealed fifth offers real key")
	_check(ARCH.prompt_text(fifth, {"ready": true, "character_stirred": true, "fifth_arch_stirred": true}) == "The arch is quiet.", "stir reload quiet")
	var home := HOME.new()
	home.set("_phase", "confirming")
	_check(home.owns_input(), "confirming owns input")
	home.set("_phase", "idle")
	_check(not home.owns_input(), "idle releases input")
	home.free()
	for failure: String in _failures:
		push_error(failure)
	print(JSON.stringify({"check": "F18 component rules", "checks": _checks, "failures": _failures,
		"limitation": "Synthetic policy/component unit context; no gameplay, persistence, network or visual proof."}))
	quit(0 if _failures.is_empty() else 1)


func _evaluate(policy: RefCounted, intent: Dictionary, context: Dictionary,
		config: Dictionary, stones: Dictionary, now: int) -> Dictionary:
	return policy.call("evaluate", intent, context, config, stones, now)


func _context() -> Dictionary:
	return {"world_instance_id": "unit-world-instance", "character_id": "unit-character",
		"peer_id": 1, "realm": "stormwood", "position": Vector3.ZERO, "damage_revision": 0,
		"home_key_owned": true, "combat": false, "dialogue": false, "cutscene": false,
		"swimming": false, "flying": false, "downed": false, "character_unlocks": [],
		"world_unlocks": [], "last_waystones": {}, "waystones_activated": {}}


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
