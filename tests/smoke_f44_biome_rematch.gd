extends SceneTree

## F44#0: after a biome's boss, its named trainers, captains and Master can be
## rematched at the next biome's level for better rewards. One headless witness
## per biome (rematches.json `witnesses`: relay_captain, water_trainer_yara,
## officer_voss_summit_approach, officer_maren_verge_rod).
##
##   godot --headless --path . --script tests/smoke_f44_biome_rematch.gd -- \
##     --biome=<meadows|tidewake|cloudreach|stormwood> --from-save=<dir holding save/> [--json=<path>]
##     [--tier=<r1|endgame>] [--witness=<rematches.json profile id>]
##
## Modelled on tests/helpers/f20_ending_probe.gd::admit_endgame_rematch. The
## save loads through the production title's Load list (Autosave). The fight is
## won by the existing CampaignPilot (tests/helpers/cloudreach_live_segment.gd,
## the earned relay segment's pilot) through the real input path; the rematch
## is admitted by the ordinary Interact press on the mounted rematch prompt.
## Stormwood's witness is post-credits, so its tier is `endgame` (L58), as in
## tools/f44_rematch_witness.gd; the other three are `r1` at the next band.
## F44#1 witnesses pass --tier=endgame with a post-credits save (f44_<biome>_endgame).
##
## Asserted: ordinary input admits the canonical rematch; every member is at the
## configured level; the pilot wins; the settled verdict is saved and resolved;
## the rematch receipt is paid exactly once with the configured unique payout,
## which the first win's story reward never contained, at a higher level than
## the first win; and after a title reload the receipt, payout and cooldown are
## unchanged (no second payout).
## DISCLOSED FIXTURES: the generated post-boss save (generate_boundary_save.gd,
## profiles f44_<biome>, see their disclosures) and one teleport of the player
## beside the witness trainer's rematch prompt (non-traversal setup).

const SAVE := preload("res://scripts/save/save_game.gd")
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const LIVE := preload("res://tests/helpers/cloudreach_live_segment.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const TRAINER_SPEC_GROUP := &"foundation_trainer_specs"
const REALMS := {"meadows": "meadows", "tidewake": "water", "cloudreach": "cloudreach", "stormwood": "stormwood"}
const FIGHT_FRAMES := 36000

var biome := ""
var from_save := ""
var json_out := ""
var tier_arg := ""
var witness_arg := ""
var game: Node
var world: Node3D
var failures: Array[String] = []
var checks: Array[String] = []
var settled: Dictionary = {}
var receipt := {}


func _init() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> bool:
	checks.append(("PASS: " if ok else "FAIL: ") + what)
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: failures.append(what)
	return ok


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="): biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--from-save="): from_save = arg.trim_prefix("--from-save=").trim_suffix("/")
		elif arg.begins_with("--json="): json_out = arg.trim_prefix("--json=")
		elif arg.begins_with("--tier="): tier_arg = arg.trim_prefix("--tier=")
		elif arg.begins_with("--witness="): witness_arg = arg.trim_prefix("--witness=")
	if not REALMS.has(biome) or from_save.is_empty() or tier_arg not in ["", "r1", "endgame"]:
		push_error("usage: --biome=<meadows|tidewake|cloudreach|stormwood> --from-save=<dir>")
		quit(2)
		return
	game = root.get_node("Game")
	if RULES.config().get("runtime_enabled") != true:
		check(false, "F44 rematch runtime is enabled in shipped config")
		await _finish()
		return
	var scratch := "user://f44_rematch_%s_%d/" % [biome, OS.get_process_id()]
	_copy_tree(ProjectSettings.globalize_path(from_save + "/save/"), ProjectSettings.globalize_path(scratch))
	game.save_system = SAVE.new(scratch)
	if not await _title_load():
		await _finish()
		return
	var witness := witness_arg if not witness_arg.is_empty() else str(RULES.config().witnesses[biome])
	var tier := tier_arg if not tier_arg.is_empty() else ("endgame" if biome == "stormwood" else "r1")
	var profile: Dictionary = RULES.profile(witness)
	var expected_level := int(RULES.config().endgame_levels[profile.kind]) if tier == "endgame" \
		else int(RULES.config().biomes[biome].r1_levels[profile.kind])
	receipt = {"biome": biome, "witness": witness, "tier": tier, "expected_level": expected_level}
	var source := _source(witness)
	if not check(source != null, "%s stands in the loaded %s world" % [witness, REALMS[biome]]):
		await _finish()
		return
	var prompt := _prompt(source, "R1 rematch" if tier == "r1" else "Endgame rematch")
	if not check(prompt != null and prompt.get("enabled") == true,
			"the %s rematch prompt is mounted and enabled after the biome's boss" % tier):
		await _finish()
		return
	var canonical: Dictionary = source.get_meta("foundation_trainer_spec", {}).duplicate(true)
	var expected_spec := RULES.encounter_spec(canonical, tier)
	var first_levels: Array = []
	for member: Dictionary in canonical.get("team", []): first_levels.append(int(member.get("level", 0)))
	var first_reward: Dictionary = canonical.get("reward", {})
	var character := str(game.local.character_id)
	var base_receipt := "rematch:%s:%s:%s" % [witness, tier, character]
	var before := RECORD.portable_projection(game.local.call("save_data")).duplicate(true)
	check(not (before.redesign_character.transaction_receipts as Array).has(base_receipt), "no rematch receipt before the fight")
	var bag_before := _bag()
	for service: Node in get_nodes_in_group("f44_rematch_services"):
		if not service.is_connected("settled", _on_settled): service.connect("settled", _on_settled)
	var director := _director()
	var manager: Node = director.get("_manager") if director != null else null
	var rig := _find(world, "CameraRig") as Node3D
	if not check(director != null and manager != null and rig != null, "the realm has its director, combat manager and camera"):
		await _finish()
		return
	# DISCLOSED FIXTURE: stand beside the prompt (non-traversal setup).
	var player := game.call("find_player") as CharacterBody3D
	player.global_position = prompt.global_position + Vector3(0.0, 0.3, 0.0)
	player.velocity = Vector3.ZERO
	for _i in 90: await physics_frame
	if str(director.call("usable_ally_blocker")) == "undeployed":
		await _tap("creature_recall")
		for _i in 600:
			await physics_frame
			if str(director.call("usable_ally_blocker")) != "undeployed": break
	check(str(director.call("usable_ally_blocker")) == "", "an owned companion is called out (%s)" % str(director.call("usable_ally_blocker")))
	var arbiter := world.get_node_or_null("InteractionArbiter")
	for _i in 120:
		if arbiter != null and arbiter.call("winning_provider") == prompt: break
		await physics_frame
	if not check(arbiter != null and arbiter.call("winning_provider") == prompt, "the ordinary Interact offer is the rematch prompt"):
		await _finish()
		return
	await _tap("interact")
	for _i in 1800:
		if manager.call("is_fighting") == true and director.call("trainer_battle_active") == true: break
		await physics_frame
	var spec: Variant = director.get("_trainer_spec")
	var admitted: bool = director.call("trainer_battle_active") == true and str(director.call("trainer_battle_id")) == witness \
		and spec is Dictionary and spec == expected_spec
	if not check(admitted, "ordinary input admits the canonical %s %s rematch" % [witness, tier]):
		await _finish()
		return
	var levels: Array = []
	for member: Dictionary in spec.team: levels.append(int(member.level))
	receipt.levels = levels
	receipt.first_levels = first_levels
	check(levels.all(func(l: Variant) -> bool: return int(l) == expected_level),
		"every rematch member is at the configured %s level L%d (%s)" % [tier, expected_level, str(levels)])
	check(expected_level > int(first_levels.max()), "the rematch is fought above the first win's levels (%s)" % str(first_levels))
	# The existing win step: the earned relay segment's CampaignPilot.
	var pilot := LIVE.CampaignPilot.new(self, manager, director, rig)
	pilot.use_switching = false
	pilot.switch_input = true
	var frames := 0
	while director.call("trainer_battle_active") == true and frames < FIGHT_FRAMES:
		frames += 1
		if manager.call("is_fighting") == true:
			var ally := director.call("ally_body") as Node3D
			var foe := manager.call("enemy_body") as Node3D
			if is_instance_valid(ally) and is_instance_valid(foe):
				await pilot._act(ally, foe)
				pilot._move_toward(Vector3.ZERO)
				continue
		await physics_frame
	receipt.fight_frames = frames
	receipt.outcome = str(manager.call("outcome"))
	if not check(receipt.outcome == "won", "the pilot wins the rematch (%s after %d frames)" % [receipt.outcome, frames]):
		await _finish()
		return
	for _i in 3600:
		if not settled.is_empty(): break
		await physics_frame
	check(settled.get("tier") == tier and settled.get("character_id") == character
		and settled.get("verdict", {}).get("saved") == true and settled.get("verdict", {}).get("resolved") == true,
		"the rematch win settles saved and resolved for this character (%s)" % str(settled))
	var after := RECORD.portable_projection(game.local.call("save_data")).duplicate(true)
	var receipts: Array = after.redesign_character.transaction_receipts
	check(receipts.count(base_receipt) == 1, "the unique rematch receipt is paid exactly once")
	var payout: Dictionary = RULES.config().biomes[profile.biome].unique_materials
	var bag_after := _bag()
	var gained := {}
	for item: String in payout: gained[item] = int(bag_after.get(item, 0)) - int(bag_before.get(item, 0))
	receipt.payout = gained
	receipt.first_reward = first_reward
	check(gained == payout, "the first rematch win pays the configured unique reward %s (gained %s)" % [str(payout), str(gained)])
	var first_items: Array = []
	for row: Variant in first_reward.get("items", []): first_items.append(str(row.get("id", row)) if row is Dictionary else str(row))
	check(payout.keys().all(func(item: Variant) -> bool: return not first_items.has(str(item))),
		"better than the first win: its reward %s never paid %s" % [str(first_reward), str(payout.keys())])
	var cooldowns: Dictionary = after.redesign_character.get("rematch_cooldowns", {})
	# Reload through the title: no second payout.
	if not await _title_load():
		await _finish()
		return
	var reloaded := RECORD.portable_projection(game.local.call("save_data")).duplicate(true)
	check((reloaded.redesign_character.transaction_receipts as Array).count(base_receipt) == 1
		and reloaded.redesign_character.transaction_receipts == receipts,
		"after a title reload the receipts are unchanged (rematch paid once)")
	var bag_reloaded := _bag()
	var same := true
	for item: String in payout: same = same and int(bag_reloaded.get(item, 0)) == int(bag_after.get(item, 0))
	check(same, "after the reload there is no second payout")
	check(reloaded.redesign_character.get("rematch_cooldowns", {}) == cooldowns and not cooldowns.is_empty(),
		"after the reload the repeat cooldown is retained")
	await _finish()


func _on_settled(trainer: String, tier: String, character: String, verdict: Dictionary) -> void:
	if trainer == str(receipt.get("witness", "")):
		settled = {"tier": tier, "character_id": character, "verdict": verdict.duplicate(true)}


func _bag() -> Dictionary:
	var out := {}
	for stack: Variant in RECORD.portable_projection(game.local.call("save_data")).get("inventory", []):
		if stack is Dictionary: out[str(stack.id)] = int(out.get(str(stack.id), 0)) + int(stack.n)
	return out


func _source(witness: String) -> Node3D:
	for body: Node in get_nodes_in_group(TRAINER_SPEC_GROUP):
		if body is Node3D and world.is_ancestor_of(body) \
			and str((body.get_meta("foundation_trainer_spec", {}) as Dictionary).get("id", "")) == witness:
			return body as Node3D
	return null


func _prompt(source: Node3D, label: String) -> Node3D:
	for child: Node in source.get_children():
		if child is Node3D and child.get("label") == label: return child as Node3D
	return null


func _director() -> Node:
	for node: Node in world.find_children("*", "Node", true, false):
		if node.has_method("trainer_battle_active") and node.get("_manager") != null: return node
	return null


func _find(from: Node, node_name: String) -> Node:
	return from.find_child(node_name, true, false)


func _tap(action: String) -> void:
	Input.action_press(action)
	for _i in 3: await physics_frame
	Input.action_release(action)
	for _i in 3: await physics_frame


func _title_load() -> bool:
	var realm: String = REALMS[biome]
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	if current_scene != null and current_scene != title: current_scene.queue_free()
	current_scene = title
	world = null
	for _i in 10: await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Autosave") and not (node as Button).disabled: chosen = node
	if not check(chosen != null, "the title's Load list offers the Autosave"): return false
	chosen.pressed.emit()
	for _frame in 7200:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) and scene.get_node_or_null("Player") != null \
				and str(game.pending_realm_entry).is_empty() and bool(game.call("_realm_scene_ready", scene, realm)):
			world = scene as Node3D
			break
	if not check(world != null and str(game.current_realm) == realm, "the save loads %s through the title" % realm): return false
	for _i in 240: await physics_frame
	return true


func _copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	var dir := DirAccess.open(from)
	if dir == null: return
	for file: String in dir.get_files(): DirAccess.copy_absolute(from.path_join(file), to.path_join(file))
	for sub: String in dir.get_directories(): _copy_tree(from.path_join(sub), to.path_join(sub))


func _finish() -> void:
	receipt.checks = checks
	receipt.passed = failures.is_empty()
	print("F44 REMATCH RESULT " + JSON.stringify(receipt))
	if not json_out.is_empty():
		var f := FileAccess.open(json_out, FileAccess.WRITE)
		if f != null: f.store_string(JSON.stringify(receipt, "  "))
	quit(0 if failures.is_empty() else 1)
