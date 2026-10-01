extends SceneTree

## Passive native witness. ROOT/pilot uses normal title, travel, challenge and
## combat controls. No teleport, flag/party/item/vitals writes, direct challenge,
## lethal resolution or synthetic credits. Save-dir MUST be a disposable copy
## of an earned post-biome (Stormwood: post-credits) checkpoint.
const SAVE := preload("res://scripts/save/save_game.gd")
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
var biome := ""
var output := ""
var save_dir := ""
var game: Node
var expected_id := ""
var observed: Dictionary = {}
var before: Dictionary = {}
var flags_before: Array = []
var levels: Array = []
var captures := 0
var started := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="): biome = arg.trim_prefix("--biome=")
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if biome not in ["meadows", "tidewake", "cloudreach", "stormwood"] or save_dir.is_empty() or output.is_empty():
		push_error("F44 witness requires --biome= --save-dir=<disposable earned copy> --output=<directory>")
		quit(2)
		return
	if RULES.config().get("runtime_enabled") != true:
		push_error("F44 witness pending: integrated runtime gate remains OFF")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		push_error("F44 real witness requires a native rendered window")
		quit(2)
		return
	expected_id = str(RULES.config().witnesses[biome])
	game = root.get_node("Game")
	game.set("save_system", SAVE.new(save_dir))
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	print("F44 WITNESS: Load earned checkpoint through normal title controls; travel and challenge %s (%s)." % [expected_id, biome])
	var bound: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 1200000
	while Time.get_ticks_msec() < deadline and observed.is_empty():
		await physics_frame
		for service: Node in get_nodes_in_group("f44_rematch_services"):
			if not bound.has(service.get_instance_id()):
				service.connect("settled", _settled)
				bound[service.get_instance_id()] = true
		if current_scene == null: continue
		for director: Node in current_scene.find_children("*", "Node", true, false):
			if not director.has_method("trainer_battle_active") or director.call("trainer_battle_active") != true \
				or director.call("trainer_battle_id") != expected_id: continue
			var spec: Variant = director.get("_trainer_spec")
			if not spec is Dictionary or not spec.get("rematch") is Dictionary: continue
			if not started:
				before = RECORD.portable_projection(game.get("local").call("save_data")).duplicate(true)
				flags_before = game.get("world").get("flags").call("all_set").duplicate()
				for member: Dictionary in spec.team: levels.append(int(member.level))
				started = true
				await _capture("start")
	if observed.is_empty():
		_write({"passed": false, "status": "pending_or_timeout", "biome": biome, "trainer_id": expected_id, "started": started})
		quit(2)
		return
	var after := RECORD.portable_projection(game.get("local").call("save_data"))
	var tier: String = observed.tier
	var first := "rematch:%s:%s:%s" % [expected_id, tier, after.character_id]
	var receipts: Array = after.redesign_character.transaction_receipts
	var world_flags: Array = game.get("world").get("flags").call("all_set")
	flags_before.sort()
	world_flags.sort()
	var expected_level: int = 58 if biome == "stormwood" else int(RULES.config().biomes[biome].r1_levels[RULES.profile(expected_id).kind])
	var passed: bool = started and receipts.has(first) and before.character_id == after.character_id \
		and not before.redesign_character.transaction_receipts.has(first) \
		and ESSENCE._equivalent(before.realm_hearts, after.realm_hearts) \
		and _uids(before.party) == _uids(after.party) and flags_before == world_flags \
		and _keys(before.inventory) == _keys(after.inventory) \
		and tier == ("endgame" if biome == "stormwood" else "r1")
	for level: int in levels: passed = passed and level == expected_level
	await _capture("settled")
	_write({"passed": passed, "biome": biome, "trainer_id": expected_id, "tier": tier,
		"levels": levels, "character_id": after.character_id, "settlement": observed.verdict,
		"captures": captures, "disclosure": "Passive observer; normal title/travel/challenge/combat controls required. No state writes. Reconnect and loss/retry require the separate queued transaction witness."})
	quit(0 if passed else 1)

func _settled(id: String, tier: String, character: String, verdict: Dictionary) -> void:
	if id != expected_id or not started or character != before.character_id \
		or verdict.get("saved") != true or verdict.get("resolved") != true: return
	observed = {"tier": tier, "character_id": character, "verdict": verdict.duplicate(true)}

func _capture(label: String) -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot != null and shot.save_png(output.path_join(label + ".png")) == OK: captures += 1

func _write(result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output.path_join("witness.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "  "))
	print("F44 WITNESS ", JSON.stringify(result))

func _uids(party: Array) -> Array:
	var result: Array = []
	for card: Dictionary in party: result.append(card.uid)
	return result

func _keys(inventory: Array) -> Dictionary:
	var result: Dictionary = {}
	for stack: Variant in inventory:
		if stack is Dictionary and preload("res://scripts/world/death_satchel_rules.gd").protected_key(stack.id):
			result[stack.id] = int(result.get(stack.id, 0)) + int(stack.n)
	return result
