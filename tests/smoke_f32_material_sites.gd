extends SceneTree

## ROOT owns native execution. Run separately with --realm=meadows or water;
## optional --site=<exact-id> keeps a repair check bounded. All saves are new.
## Disclosed fixtures: one owned Terrapup, opening free-play, requested realm,
## one trainer start 6m from each candidate, and in-memory candidate registry
## insertion after actual placement validation. Source evidence/gates stay
## unchanged. Actual terrain/body, controller approach, prompt, host context,
## typed stock transaction, owner disk write and ACK remain production paths.
## This local approach is not an earned inter-region/campaign or ENet proof.
## --essence walks to and gathers every registered essence node of the realm.
## --ordinary instead walks to and gathers one already-registered renewable
## site per tier material of the realm (the per-biome gather census); those
## need no registry fixture. --realm also takes cloudreach and stormwood.
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const VALIDATOR := preload("res://scripts/world/essence_node_mount.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const DRIVER := preload("res://tests/helpers/gate_a_material_route.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const ADAPTER := preload("res://scripts/net/foundation_resources.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const SCENES := {"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn"}
const CONFIGS := {"meadows": "res://data/config/harvest.json", "water": "res://data/config/water_pickups.json",
	"cloudreach": "res://data/config/cloudreach_resources.json", "stormwood": "res://data/config/stormwood_harvests.json"}
var _args: Dictionary = {}
var _report := {"checks": [], "sites": [], "earned_campaign": false, "two_peer_rejoin": false,
	"fixture": "one owned Terrapup; opening free-play; realm selection; 6m trainer/camera starts with collision-streaming wait; in-memory candidate definitions after real validation"}
var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _resources: Node
var _driver: RefCounted
var _saver: RefCounted
var _settled: Dictionary = {}
var _failed := false
var _finished := false
var _realm := "meadows"
var _output := ""
var _soft := false # ordinary census: pre-gather placement refusals try the next site

func _init() -> void:
	_run.call_deferred()

## Placement-stage gate. In the ordinary census a refused placement is
## recorded as skipped (production would not mount it either) instead of failing.
func _pre(value: bool, label: String) -> bool:
	if value or not _soft: return _check(value, label)
	_report.checks.append({"ok": true, "skipped": true, "label": label})
	print("F32 MATERIAL SKIP: ", label)
	return false

func _check(value: bool, label: String) -> bool:
	_report.checks.append({"ok": value, "label": label})
	_failed = _failed or not value
	print("F32 MATERIAL %s: %s" % ["PASS" if value else "FAIL", label])
	return value

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() == 2 else true
	_realm = str(_args.get("realm", "meadows"))
	_output = str(_args.get("output", "user://f32_material_sites_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]))
	DirAccess.make_dir_recursive_absolute(_output)
	_report.realm = _realm
	_report.user_data_dir = OS.get_user_data_dir()
	create_timer(540.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "native watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	if not _check(_game != null and SCENES.has(_realm), "production Game and selected realm exist"):
		_finish(); return
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", _realm)
	_game.get("local").set("character_id", "f32-site-owner")
	_game.get("world").set("world_id", "f32-site-world")
	_game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	if _args.has("ordinary"):
		# Disclosed fixture, granted before admission like the Terrapup: one of
		# each gathering tool, so tier sites can be gathered with the right tool.
		for tool: Variant in _game.get("items").call("tool_ids"):
			_game.get("inventory").call("add", str(tool), 1)
	var source_path: String = CONFIGS[_realm]
	_report.source_path = source_path
	_report.source_sha256 = FileAccess.get_sha256(source_path)
	var config := _read(source_path)
	_report.source_runtime_enabled = config.get("additional_material_node_candidates", {}).get("runtime_enabled")
	if not _check(SITES.validation_errors().is_empty(), "canonical production source registry is valid"):
		_finish(); return
	if not _check(change_scene_to_file(SCENES[_realm]) == OK, "request actual baked realm scene"):
		_finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("world_realm") \
			and current_scene.call("world_realm") == _realm and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "actual realm procedural build completed"):
		_finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	_resources = _game.get("session").get_node_or_null(^"FoundationComposition/Resources")
	if not _check(_player != null and _resources != null, "production player and resource adapter mounted"):
		_finish(); return
	_resources.get_node(^"SourceService").connect("settled", _on_settled)
	_driver = DRIVER.new()
	_driver.set("_tree", self)
	_driver.set("_world", _world)
	_driver.set("_game", _game)
	_driver.set("_player", _player)
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	_driver.set("_rig", rig)
	_driver.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _check(rig != null and _driver.get("_arbiter") != null and _driver.call("_resolve_move_bindings") == true,
		"existing physical controller driver resolves production camera and arbiter"):
		_finish(); return
	_driver.set("_nav", NAV.new(self, _player, rig, Callable(_driver, "_send_stick")))
	await _frames(30)
	var selected := 0
	var rows: Array = config.get("additional_material_node_candidates", {}).get("nodes", [])
	if _args.has("ordinary"): rows = _ordinary_rows()
	if _args.has("essence"):
		# F32#2: every registered essence node of the realm, as production resolves it.
		rows = []
		for node: Dictionary in preload("res://scripts/world/essence_node_catalog.gd").nodes_for(_realm):
			rows.append(SITES.by_id(_realm, str(node.id)))
	_report.mode = "ordinary" if _args.has("ordinary") else ("essence" if _args.has("essence") else "additional_candidates")
	for raw: Dictionary in rows:
		if raw.has("candidates"):
			# Production placement may refuse a site (and then never mounts it);
			# the census needs one mountable, gatherable site of the material.
			selected += 1
			_soft = true
			var gathered := false
			for candidate: Dictionary in raw.candidates:
				gathered = await _site(candidate, source_path)
				if gathered:
					_report.ordinary_census[raw.item] = candidate.id
					break
			_soft = false
			_check(gathered, "census: %s has a mountable, controller-reachable, saved gather" % raw.item)
			continue
		if _args.has("site") and _args.site != raw.id: continue
		selected += 1
		await _site(raw, source_path)
	_check(selected > 0, "selected at least one authored candidate")
	_check(FileAccess.get_sha256(source_path) == _report.source_sha256, "production source bytes and proof gates unchanged")
	_finish()

## One registered ungated renewable site per tier material, lowest ID first.
## A material with no ungated site is reported as a failed census entry.
func _ordinary_rows() -> Array:
	var tiers: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/schema/material_tiers.json"))
	var biome: String = {"water": "tidewake"}.get(_realm, _realm)
	var materials: Array = []
	for tier: Dictionary in tiers:
		if tier.get("biome") == biome: materials = tier.get("raws", [])
	var sites := SITES.sites_for(_realm)
	sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id))
	var result: Array = []
	_report.ordinary_census = {}
	for item: String in materials:
		var chosen: Array = []
		for site: Dictionary in sites:
			if site.get("source_additional_material", false) or str(site.get("source_config", "")).ends_with("essence_nodes.json"): continue
			if site.get("outputs", {}).keys() != [item] or not str(site.get("requires_flag", "")).is_empty() \
				or not site.get("requires_world_flags", []).is_empty(): continue
			if _args.has("site") and _args.site != site.id: continue
			chosen.append(site)
			if chosen.size() >= 4: break
		_report.ordinary_census[item] = ""
		if chosen.is_empty():
			print("F32 MATERIAL CENSUS no ungated registered renewable site for ", item)
			continue
		result.append({"item": item, "candidates": chosen})
	return result

func _site(raw: Dictionary, source_path: String) -> bool:
	var id := str(raw.id)
	var result := {"id": id, "source_evidence": raw.get("terrain_and_player_path_proven"), "authored_at": raw.at,
		"placement": {}, "controller_approach": false, "accepted_disk_gather": false}
	_report.sites.append(result)
	print("F32 MATERIAL BEGIN ", id)
	var tuning: Dictionary = _read("res://data/config/essence_nodes.json").get("placement_validation", {})
	var at := Vector2(float(raw.at[0]), float(raw.at[1]))
	var authored_at := at
	# These are disclosed start fixtures. Only the later walked segment counts.
	# Cliff sites: the first 6m ring point on baked ground near the site height.
	var start := at + Vector2(0, 6)
	var ground := float(_world.call("ground_height_at", start.x, start.y))
	var site_y := float(raw.get("authored_height", ground))
	if raw.has("authored_height") and _world.has_method("_resource_position"):
		# Production placement first binds a Cloudreach site to its real
		# surface (essence_node_mount.placement_verdict); ring around that.
		var resolved: Vector3 = _world.call("_resource_position", Vector3(at.x, site_y, at.y))
		if resolved.is_finite():
			at = Vector2(resolved.x, resolved.z)
			site_y = resolved.y
	for offset: Vector2 in [Vector2(0, 6), Vector2(6, 0), Vector2(-6, 0), Vector2(0, -6),
			Vector2(4.5, 4.5), Vector2(-4.5, 4.5), Vector2(4.5, -4.5), Vector2(-4.5, -4.5)]:
		var y := float(_world.call("ground_height_at", at.x + offset.x, at.y + offset.y))
		if not (is_finite(y) and absf(y - site_y) <= 2.0) and _world.has_method("ground_height_near"):
			# Same layered-surface resolver Cloudreach placement uses.
			y = float(_world.call("ground_height_near", Vector3(at.x + offset.x, site_y, at.y + offset.y)))
		if not (is_finite(y) and absf(y - site_y) <= 2.0):
			# Built platforms (camps, decks) are meshes, not Terrain3D: ray down.
			var from := Vector3(at.x + offset.x, site_y + 4.0, at.y + offset.y)
			var hit := _world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 8.0, 1))
			y = float(hit.position.y) if not hit.is_empty() else NAN
		if is_finite(y) and absf(y - site_y) <= 2.0:
			start = at + offset
			ground = y
			break
	if not _pre(is_finite(ground), id + " fixture start resolves actual baked ground"): return false
	# Terrain3D streams collision around the render camera. Match the real
	# arrival staging: hold gravity at the disclosed start while that camera
	# reaches it, then require actual floor contact before measuring movement.
	_player.set_physics_process(false)
	_player.global_position = Vector3(start.x, ground + 0.2, start.y)
	_player.velocity = Vector3.ZERO
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.global_position = _player.global_position
		rig.reset_physics_interpolation()
	for frame in 8:
		await process_frame
		await physics_frame
	_player.set_physics_process(true)
	_player.reset_physics_interpolation()
	await _frames(6) # Discard floor contact cached before the fixture relocation.
	for frame in 180:
		await physics_frame
		if _player.is_on_floor(): break
	result.fixture_start = _player.global_position
	var verdict := VALIDATOR.placement_verdict(_world, raw, _player, tuning)
	result.placement = verdict
	if not _pre(verdict.get("ok") == true, id + " actual terrain slope and trainer capsule: " + str(verdict)): return false
	if _realm == "water" and not _check(VALIDATOR._additional_water_dry(_world, verdict.position, tuning), id + " actual water plane establishes a dry bed"): return false
	if not _check(_player.is_on_floor() and _player.global_position.distance_to(verdict.position) >= 4.5,
		id + " disclosed start is grounded and outside interaction range"): return false
	var parent := SITES.by_id(_realm, str(raw.get("anchor", {}).get("id", ""))) if raw.has("anchor") else SITES.by_id(_realm, id)
	if not _check(not parent.is_empty(), id + " ordinary source anchor exists"): return false
	if raw.has("anchor"):
		var expected := Vector2(float(parent.at[0]), float(parent.at[1])) + Vector2(float(raw.anchor.offset_xz_m[0]), float(raw.anchor.offset_xz_m[1]))
		if not _check(expected.is_equal_approx(authored_at), id + " authored offset matches canonical anchor"): return false
	if SITES.by_id(_realm, id).is_empty():
		# Test-only admission permits gathering an unshipped candidate; the false
		# source proof field is preserved. Runtime host admission is not mocked.
		var candidate := raw.duplicate(true)
		for key: String in ["requires_flag", "requires_world_flags", "availability"]:
			if parent.has(key): candidate[key] = parent[key].duplicate(true) if parent[key] is Array else parent[key]
		candidate.source_additional_material = true
		candidate.order = "material:" + id
		SITES._add(_realm, candidate, source_path)
		result.registry_fixture = true
	_resources.get("_mount_retry").erase(_realm)
	_resources.call("_mount_realm", _realm, _player)
	var node: Node3D = _resources.call("_source", _realm, id)
	if not _check(node != null, id + " production world mount accepts validated candidate"): return false
	var prompt := node.get_node_or_null(^"Interactable") as Node3D
	if not _check(prompt != null, id + " actual gather prompt exists"): return false
	_driver.set("_active_walk_purpose", "F32 candidate " + id)
	var before: Vector3 = _player.global_position
	var arrived: bool = await _driver.call("_walk_to", node.global_position, 1.6, 600)
	result.walk_start = before
	result.walk_end = _player.global_position
	result.walked_metres = Vector2(before.x, before.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z))
	result.controller_approach = arrived and result.walked_metres >= 3.0 and _player.is_on_floor()
	if not _check(result.controller_approach, id + " actual controller approach moved at least 3m and remained grounded"): return false
	if not _check(await _driver.call("_prompt_holds_the_line", prompt.get_instance_id()), id + " exact candidate prompt wins ordinary interaction"): return false
	if _args.has("essence"): _gate_fixture(raw, result)
	var tool: String = str(_game.get("items").call("gathered_with", str(raw.get("item", ""))))
	if tool.is_empty() and _soft:
		_game.set("equipped_tool", "")
	if not tool.is_empty():
		# Disclosed fixture: equip the item's gathering tool (granted at setup). The host
		# rule that refuses an unequipped tier gather is unchanged.
		_game.set("equipped_tool", tool)
		result.fixture_tool = tool
		await _frames(10)
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		id + " pre-gather owner and world fixtures saved to isolated disk"): return false
	var before_disk := _disk("before_" + id.replace(":", "_"))
	result.lifecycle_before = _resources.get_parent().get_node(^"TravelLifecycle").call("local_sample")
	result.host_context_before = _resources.call("host_context", int(_game.get("session").call("local_peer_id")),
		"resource:%s:%s" % [_realm, id], {"operation": "node", "request": {"site_id": id}})
	result.actor_baseline_before = _actor_baseline_diagnostic()
	await _driver.call("_tap_action", &"interact")
	for frame in 600:
		if _settled.has(id): break
		await physics_frame
	result.settlement = _settled.get(id, {})
	if not ADAPTER.saved_decision(result.settlement.get("verdict", {})):
		result.baseline_diagnostic = _baseline_diagnostic()
	if not _check(ADAPTER.saved_decision(result.settlement.get("verdict", {})), id + " ordinary gather reaches real owner save and ACK"): return false
	var after_disk := _disk("after_" + id.replace(":", "_"))
	var row: Dictionary = {}
	for value: Variant in after_disk.world.get("reward_deliveries", {}).values():
		if value is Dictionary and value.get("action") == "resource" and value.get("intent", {}).get("request", {}).get("site_id") == id: row = value
	var exact: bool = row.get("status") == "accepted" and row.get("intent", {}).get("request", {}).get("action_id") == result.settlement.get("action_id")
	for item: String in raw.outputs:
		exact = exact and _count(after_disk.character, item) - _count(before_disk.character, item) == int(raw.outputs[item])
	var stock: Dictionary = after_disk.world.get("redesign_world", {}).get("node_cycles", {}).get("sites", {}).get(_realm + ":" + id, {})
	exact = exact and int(stock.get("revision", -1)) == 1 and int(stock.get("generation", -1)) == 2
	exact = exact and after_disk.character.get("redesign_character", {}).get("transaction_receipts", []).has(row.get("receipt", ""))
	result.accepted_disk_gather = exact
	result.saved_stock = stock
	result.saved_action = row
	_check(exact, id + " actual disk has exact material gain, accepted journal, receipt and consumed stock")
	var reloaded := preload("res://autoload/world_state.gd").new()
	reloaded.load_data(after_disk.world)
	_check(ESSENCE._equivalent(reloaded.renewable_stock_state(_realm, id), stock), id + " actual saved stock survives JSON world reload")
	return result.accepted_disk_gather

func _on_settled(op: String, id: String, action: String, verdict: Dictionary) -> void:
	if op == "node": _settled[id] = {"action_id": action, "verdict": verdict.duplicate(true)}

## Read the actual owner, admitted registry and director without creating an
## arbiter or encounter. Fresh gathering must initialize through production.
func _actor_baseline_diagnostic() -> Dictionary:
	var session: Node = _game.get("session")
	var authority: RefCounted = session.get("_character_authority")
	var character: String = _game.get("local").character_id
	var admitted: Dictionary = authority.call("state", character) if authority != null else {}
	var result := {"character_id": character, "local_party_uids": [], "admitted_party_uids": [],
		"admitted_character_id": admitted.get("character_id", ""), "directors": [],
		"session_active": session.call("is_active"), "local_peer_id": session.call("local_peer_id"),
		"realm": _game.get("current_realm"), "registered_realm": session.call("realm_of", session.call("local_peer_id")),
		"local_combat_manager": {}}
	var manager := _world.get_node_or_null(^"CombatManager")
	if manager != null and manager.get_script() != null:
		result.local_combat_manager = {"path": str(manager.get_path()), "script": manager.get_script().resource_path,
			"fighting": manager.call("is_fighting") if manager.has_method("is_fighting") else null}
	for member: RefCounted in _game.get("party").call("members"):
		result.local_party_uids.append(str(member.get("uid")))
	for card: Dictionary in admitted.get("party", []):
		result.admitted_party_uids.append(str(card.get("uid", "")))
	for node: Node in _world.find_children("*", "Node", true, false):
		var script: Script = node.get_script()
		if script == null or script.resource_path not in preload("res://scripts/net/session.gd").FOUNDATION_DIRECTORS: continue
		var host: Variant = node.get("_encounter_host")
		var row := {"path": str(node.get_path()), "script": script.resource_path, "host_present": host is RefCounted}
		if host is RefCounted:
			row.host_script = host.get_script().resource_path
			row.encounter_count = host.get("encounters").size()
		result.directors.append(row)
	return result

## Disclosed --essence fixture for authored gates the census cannot earn in a
## fresh world: the anchor's world/route flag is set, and for a Stormwood seam
## the saved storm clock is moved into a phase the seam opens in (>= 60 s left).
## The host still evaluates both rules exactly as in play.
func _gate_fixture(raw: Dictionary, result: Dictionary) -> void:
	var world: RefCounted = _game.get("world")
	var required := str(raw.get("requires_flag", ""))
	if not required.is_empty() and not world.flags.call("has", required):
		world.flags.call("set_flag", required)
		result.fixture_world_flag = required
	if _realm != "stormwood": return
	var rules := preload("res://scripts/world/stormwood_harvest_rules.gd").new()
	var origin := str(raw.get("anchor", {}).get("id", raw.id))
	if not rules.refusal(origin, world).contains("Break"): return
	var site: Dictionary = rules.get("sites")[origin]
	var allowed: Array = site.get("availability", [])
	for second in 4000:
		var info: Dictionary = rules.get("surge").call("phase_at", float(second), str(site.region_id))
		if allowed.has(info.get("phase")) and float(info.get("remaining", 0.0)) >= 60.0:
			var environment: Dictionary = world.get("realm_environment")
			if not environment.get("stormwood") is Dictionary: environment["stormwood"] = {}
			environment.stormwood["elapsed"] = float(second)
			result.fixture_storm_elapsed = float(second)
			break

## Read-only: the session's own actor-baseline verdict for each pending
## creature_training row, so a refusal names its inner reason in the report.
func _baseline_diagnostic() -> Array:
	var out: Array = []
	var session: Node = _game.get("session")
	var character := str(_game.get("local").character_id)
	for node: Node in session.call("_foundation_directors_under", session.call("_foundation_realm_roots")):
		var host: Variant = node.get("_encounter_host")
		var row := {"director": str(node.get_path()), "host": host.get_script().resource_path if host is RefCounted else "none",
			"fence": host.has_method("move_action_publication_pending") if host is RefCounted else false, "mine": []}
		if host is RefCounted:
			var encounters: Dictionary = host.get("encounters")
			for id: String in encounters:
				for key: String in ["participants", "retained_actor_participants"]:
					for participant: Variant in (encounters[id].get(key, {}) as Dictionary).values():
						if participant is Dictionary and participant.get("character_id") == character:
							row.mine.append({"id": id, "set": key, "phase": encounters[id].get("phase")})
		out.append(row)
	return out

func _disk(label: String) -> Dictionary:
	_saver.call("finish_fallback")
	var paths := {"world": _saver.call("worlds").call("path_for", str(_game.get("world").world_id)),
		"character": _saver.call("characters").call("path_for", str(_game.get("local").character_id))}
	var result := {}
	var directory := _output.path_join(label)
	DirAccess.make_dir_recursive_absolute(directory)
	for kind: String in paths:
		var path: String = paths[kind]
		var retained := directory.path_join(kind + ".json")
		_check(FileAccess.file_exists(path) and DirAccess.copy_absolute(path, retained) == OK, label + " retains exact " + kind + " bytes")
		# Saves are codec envelopes; decode exactly as the production loader does.
		var decoded: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(path))
		_check(decoded is Dictionary, label + " decodes " + kind + " save document")
		result[kind] = decoded if decoded is Dictionary else {}
	return result

func _count(character: Dictionary, item: String) -> int:
	var count := 0
	for slot: Variant in character.get("inventory", []):
		if slot is Dictionary and slot.get("id") == item: count += int(slot.get("n", 0))
	return count

func _finish() -> void:
	if _finished: return
	_finished = true
	if _driver != null: _driver.call("_release_move")
	_report.ok = not _failed
	var path := _output.path_join("report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "\t"))
		file.close()
	print("F32 MATERIAL REPORT ", ProjectSettings.globalize_path(path))
	quit(1 if _failed else 0)
