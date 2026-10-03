extends RefCounted

## Explicit tools-only initial fixtures and physical selectors. This script
## never produces a canonical receipt, permit, accepted row or gameplay ACK.
const DISCLOSURE := "DIAGNOSTIC_PRETEND_PREREQUISITES_NO_F48_EARNED_OR_RECORDED_INPUT_CREDIT"
const SOURCE := preload("res://tools/net/f48_actor_topup.gd")
const PROOF := preload("res://tools/net/proof_steps_f48.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const RECORDS := preload("res://scripts/net/character_record_rules.gd")
const DETACHED := preload("res://tools/net/f48_detached_file.gd")

static func run(tree: SceneTree, args: Dictionary) -> Dictionary:
	var runtime_script: Script = tree.get_script() as Script
	if args.get("disclosure") != DISCLOSURE or OS.get_environment("TB_F48_DIAGNOSTIC_ONLY") != DISCLOSURE \
		or SOURCE.runner_script_valid(runtime_script) != true:
		return _result(false,"Actual disclosed diagnostic proof process required")
	match str(args.get("phase","")):
		"initial_save": return _initial_save(tree,args)
		"choose_caught": return await _choose_caught(tree)
		"confirm_release": return await _confirm_release(tree)
		"ordinary_round": return await _ordinary_round(tree,args)
	return _result(false,"Unknown diagnostic phase")

static func _result(ok: bool, reason: String, data: Dictionary = {}) -> Dictionary:
	data["diagnostic_disclosure"] = DISCLOSURE
	data["acceptance_credit"] = false
	data["earned_checkpoint"] = false
	data["ready_ci_bundle"] = false
	return {"verdict":"PASS" if ok else "FAIL","detail":reason,"data":data}

static func _protected(personal: Dictionary, world: Dictionary) -> Dictionary:
	var identities: Array = []
	for row: Dictionary in personal.get("party",[]):
		var mirror: Dictionary = personal.get("redesign_character",{}).get("creatures",{}).get(row.get("uid"),{})
		identities.append({"uid":row.get("uid"),"species":row.get("species_id"),
			"card_capture":row.get("captured_from"),"mirror_capture":mirror.get("captured_from")})
	var receipts := {}
	for field: String in ["transaction_receipts","release_receipts","research_receipts","bounty_receipts"]:
		receipts[field]=personal.get("redesign_character",{}).get(field)
	return {"character_id":personal.get("character_id"),"identities":identities,"receipts":receipts,
		"escrow":personal.get("satchel_escrow"),"world_id":world.get("world_id"),
		"namespace":world.get("reward_delivery_namespace"),"journal":world.get("reward_deliveries")}

static func _seed(personal: Dictionary, seed: String) -> Dictionary:
	var next: Dictionary = personal.duplicate(true)
	if seed == "none": return next
	if seed not in ["feast_ready","key_ready","relic_ready","round_ready"]: return {}
	if seed in ["feast_ready","round_ready"]:
		if next.get("party",[]).is_empty(): return {}
		var card: Dictionary = next.party[0]
		var cap: int = 20 if seed == "round_ready" else 10
		var uid: String = str(card.uid)
		var mirror: Dictionary = next.redesign_character.creatures.get(uid,{})
		if mirror.is_empty(): return {}
		if seed == "round_ready":
			mirror["breakthroughs"]=[1]
			mirror["cap_level"]=20
		var staged: Dictionary = PROGRESSION.staged_xp(card,cap,1000000,PROGRESSION.config())
		if staged.is_empty(): return {}
		next.party[0]=staged
		var refreshed: Dictionary = ESSENCE.refresh_training_moves(RECORDS.portable_projection(next),
			TEACHING.available_moves,TEACHING.character_loadout_mirror)
		if refreshed.is_empty(): return {}
		next.party=refreshed.party
		next.redesign_character=refreshed.redesign_character
	if seed == "feast_ready":
		if not next.redesign_character.master_wins.has("master_t1"): next.redesign_character.master_wins.append("master_t1")
		if not next.redesign_character.feast_recipes.has("feast_t1"): next.redesign_character.feast_recipes.append("feast_t1")
		_add_stock(next,"feast_t1_ground",1)
	if seed == "key_ready": _add_stock(next,"tidewake_portal_key",1)
	if seed == "relic_ready" and not next.redesign_character.relics_held.has("meadows"):
		next.redesign_character.relics_held.append("meadows")
	return next

static func _add_stock(personal: Dictionary, item: String, amount: int) -> void:
	for stack: Dictionary in personal.inventory:
		if stack.get("id") == item:
			stack["n"]=int(stack.n)+amount
			return
	personal.inventory.append({"id":item,"n":amount})

static func _initial_save(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game: Node = tree.root.get_node_or_null(^"Game")
	var session: Node = game.get("session") as Node if game != null else null
	var saver: RefCounted = game.get("save_system") as RefCounted if game != null else null
	var local: RefCounted = game.get("local") as RefCounted if game != null else null
	var world: RefCounted = game.get("world") as RefCounted if game != null else null
	if session == null or saver == null or local == null or world == null or session.call("is_active") == true \
		or session.get("_preparing_client") == true or tree.has_meta("f48_diagnostic_initial_saved"):
		return _result(false,"Initial diagnostic fixture requires an isolated pre-admission owner")
	var before: Dictionary = local.call("save_data")
	var world_before: Dictionary = world.call("save_data")
	var candidate: Dictionary = _seed(before,str(args.get("seed","none")))
	if candidate.is_empty() or not PROOF._json_equal(_protected(before,world_before),_protected(candidate,world_before)):
		return _result(false,"Diagnostic prerequisite changed protected original identity/journal/receipt")
	local.call("load_data",candidate)
	var installed: Dictionary = local.call("save_data")
	if not PROOF._json_equal(installed,candidate):
		return _result(false,"Actual owner codec refused complete diagnostic initial fixture",
			{"before":before,"candidate":candidate,"installed":installed,"first_difference":PROOF._json_difference(candidate,installed)})
	var character_only: String = str(local.get("character_id")) if int(tree.get("_peer_index")) > 0 else ""
	var request: Dictionary = saver.call("_prepare_snapshot",game,0,character_only.is_empty(),character_only)
	if request.is_empty(): return _result(false,"Actual SaveGame refused diagnostic initial snapshot")
	var world_prepared: Dictionary = world.call("save_data")
	if not PROOF._json_equal(_protected(before,world_before),_protected(installed,world_prepared)):
		return _result(false,"Actual snapshot preparation changed protected source identity/journal/receipt")
	var success: Variant = saver.call("write_snapshot_observed",request)
	var receipt: Dictionary = saver.call("fallback_write_receipt")
	if not success is bool or success != true: return _result(false,"Actual initial writer BOOL failed",{"request":request})
	var characters: RefCounted = saver.get("_characters")
	var worlds: RefCounted = saver.get("_worlds")
	var paths := {"character":characters.call("path_for",str(request.character_id))}
	if not request.character_only:
		paths.slot=saver.call("slot_path",0)
		if request.host: paths.world=worlds.call("path_for",str(request.world_id))
	var files: Dictionary = PROOF._fallback_receipt_files(request,receipt,paths,saver.get_instance_id())
	if files.is_empty(): return _result(false,"Actual initial full byte receipt did not match frozen request")
	for kind: String in paths:
		if FileAccess.get_sha256(str(paths[kind])) != receipt.files[kind].sha256:
			return _result(false,"Actual initial primary changed during readback")
	var evidence := {"case":args.get("case"),"seed":args.get("seed"),"before":before,"after":installed,
		"first_difference":PROOF._json_difference(before,installed),"protected":_protected(before,world_before),
		"request":request,"strict_writer_BOOL":true,"receipt":receipt,"acceptance_credit":false,"disclosure":DISCLOSURE}
	var path: String = OS.get_environment("TB_PROOF_OUT").path_join("diagnostic-initial-peer-%d.json" % int(tree.get("_peer_index")))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not DETACHED.publish(path,evidence): return _result(false,"Could not preserve initial diagnostic source manifest")
	tree.set_meta("f48_diagnostic_initial_saved",true)
	return _result(true,"Disclosed pretend prerequisite persisted by actual canonical writer; no ACK or earned credit",
		{"path":path,"sha256":FileAccess.get_sha256(path),"request":request,"receipt":receipt})

static func _choose_caught(tree: SceneTree) -> Dictionary:
	var game: Node = tree.root.get_node_or_null(^"Game")
	if game == null: return _result(false,"Actual owner missing")
	var personal: Dictionary = game.get("local").call("save_data")
	var choices: Array[String] = []
	for uid: String in personal.redesign_character.creatures:
		var mirror: Dictionary = personal.redesign_character.creatures[uid]
		if mirror.get("captured_from",{}).get("kind") == "wild": choices.append(uid)
	if choices.size() != 1: return _result(false,"Exactly one actual previously caught owned companion required")
	var selected: Dictionary = await PROOF._choice(tree,{"uid":choices[0]})
	if selected.get("verdict") == "PASS": tree.set_meta("f48_diagnostic_release_uid",choices[0])
	return selected

static func _release_buttons(node: Node, out: Array[Button]) -> void:
	if node is Button and node.is_visible_in_tree() and not node.disabled \
		and node.text.begins_with("Release ") and node.text.contains("This can't be undone."):
		out.append(node)
	for child: Node in node.get_children(): _release_buttons(child,out)

static func _confirm_release(tree: SceneTree) -> Dictionary:
	if not tree.has_meta("f48_diagnostic_release_uid"): return _result(false,"Actual physical caught UID selection required")
	var buttons: Array[Button] = []
	_release_buttons(tree.root,buttons)
	if buttons.size() != 1 or buttons[0].get_meta("confirmed_uid","") != tree.get_meta("f48_diagnostic_release_uid"):
		return _result(false,"Exact actual shipping release confirmation is unavailable")
	return await PROOF._button(tree,{"text":buttons[0].text})

static func _ordinary_round(tree: SceneTree, args: Dictionary) -> Dictionary:
	var director: Node = tree.current_scene.get_node_or_null(^"EncounterDirector") if tree.current_scene != null else null
	if director == null or director.call("trainer_battle_id") != "warden_aldis":
		return _result(false,"Actual already challenged Warden encounter required")
	var disclosure := {"scope":"named_mechanics_only","self_hp_topups":true,"ally_placement":true,
		"enemy_hp_ceiling":0,"earned_campaign_credit":false}
	var provider: Node = SOURCE.install(tree,disclosure)
	if provider == null: return _result(false,"Actual existing typed Warden aid source required")
	var budget: int = int(args.get("budget_frames",9000))
	if budget < 240 or budget > 9000: return _result(false,"Original bounded driver budget required")
	var result: Dictionary = await tree.call("_step_win_trainer_battle",{"budget_frames":budget,
		"stop_when_creatures_left":3,"retain_fixture_actions":true,"enemy_hp_ceiling":0,"fixture_topup_provider":provider})
	return result
