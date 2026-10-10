extends "res://tests/test_case.gd"

## Component controls use real world/creature/body/director/session scripts.
## They never mount a replacement /root/Game or grant public freeze success,
## real capture, ownership, a BOOL/ACK, ENet, gameplay or READY acceptance.
const SOURCE := preload("res://tools/net/f48_shipping_capture_source.gd")
const WORLD := preload("res://autoload/world_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HOOKS := preload("res://scripts/creatures/trait_spawn_hooks.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")


func _pins() -> Array:
	var out: Array = []
	for file: String in SOURCE.FILES:
		var path := "res://data/config/" + file
		out.append({"file": path, "sha256": FileAccess.get_sha256(path)})
	return out


func _fixture() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var realm := Node3D.new()
	realm.name = "F48ShippingSourceControl"
	realm.process_mode = Node.PROCESS_MODE_DISABLED
	tree.root.add_child(realm)
	var game := Node.new()
	game.name = "SourceGameControl"
	realm.add_child(game)
	var session := Node.new()
	session.name = "Session"
	game.add_child(session)
	# Install scripts AFTER mounting inert nodes: no production ready/scene
	# boot is run. Public mount authentication must still refuse this fixture.
	session.set_script(load("res://scripts/net/session.gd"))
	var director := Node.new()
	director.name = "EncounterDirector"
	realm.add_child(director)
	director.set_script(load("res://scripts/combat/encounter_director.gd"))
	director.set("_session", session)
	var world := WORLD.new()
	world.world_id = "source-world"
	world.reward_delivery_namespace = "source-namespace"
	var local: RefCounted = load("res://autoload/player_state.gd").new()
	local.set("character_id", "source-owner")
	var creature := SPECIES.spawn("mosshell")
	var packet := HOOKS.initialize_host_instance(creature, {"world_namespace": world.reward_delivery_namespace,
		"spawn_id": SOURCE.BODY_NAME, "spawn_generation": 1, "alpha": true, "night": false, "weather": false})
	assert_false(packet.is_empty(), "actual ordinary host trait initialization")
	var body := CharacterBody3D.new()
	body.name = SOURCE.BODY_NAME
	realm.add_child(body)
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.set("instance", creature)
	body.set_meta("foundation_alpha_site", SOURCE.SITE)
	body.set_meta("foundation_alpha_world", weakref(world))
	body.set_meta("foundation_alpha_epoch", session.call("_altar_current_epoch"))
	body.set_meta("foundation_alpha_generation", 1)
	body.set_meta("ordinary_trait_packet", packet.duplicate(true))
	body.set_meta("ordinary_trait_world", weakref(world))
	body.set_meta("ordinary_trait_uid", creature.get("uid"))
	body.set_meta("ordinary_trait_generation", 1)
	body.set_meta("ordinary_trait_alpha", true)
	var mounted := {"tree": tree, "game": game, "session": session, "world": world, "realm": realm, "local": local,
		"director": director, "epoch": session.call("_altar_current_epoch"),
		"namespace": world.reward_delivery_namespace, "world_id": world.world_id, "host_character_id": "source-owner", "host_peer": 1}
	var scope := {"site": SOURCE.SITE, "spawn_id": SOURCE.BODY_NAME, "body_name": SOURCE.BODY_NAME,
		"body_uid": creature.get("uid"), "species": "mosshell", "generation": 1,
		"namespace": mounted.namespace, "world_id": mounted.world_id, "epoch": mounted.epoch, "realm": "meadows",
		"body_path": str(body.get_path()), "director_path": str(director.get_path()),
		"body_instance_id": body.get_instance_id(), "creature_instance_id": creature.get_instance_id(),
		"director_instance_id": director.get_instance_id(), "world_instance_id": world.get_instance_id(),
		"session_instance_id": session.get_instance_id(), "game_instance_id": game.get_instance_id(),
		"local_instance_id": local.get_instance_id(), "host_character_id": "source-owner", "host_peer": 1}
	var source := {"scope": scope, "packet": packet.duplicate(true), "card": CODEC.encode(creature),
		"authored": SOURCE._authored(), "pins": _pins(), "refs": {}}
	for key: String in ["tree", "game", "session", "world", "realm", "director", "local"]:
		source.refs[key] = weakref(mounted[key])
	source.refs.body = weakref(body)
	source.refs.creature = weakref(creature)
	return {"tree": tree, "realm": realm, "director": director, "body": body, "world": world,
		"creature": creature, "packet": packet, "mounted": mounted, "source": source}


func test_complete_current_seven_pins_and_actual_off_traits_flags_are_required() -> void:
	var pins := _pins()
	assert_true(SOURCE.pins_valid(pins))
	assert_false(SOURCE.pins_valid(pins.slice(0, 6)), "six native admission pins do not include all seven")
	var changed := pins.duplicate(true)
	changed[6] = changed[0].duplicate(true)
	assert_false(SOURCE.pins_valid(changed), "duplicate cannot substitute combat pin")
	for invalid: Variant in [null, true, "00", "a".repeat(64), "A".repeat(64)]:
		changed = pins.duplicate(true)
		changed[0].sha256 = invalid
		assert_false(SOURCE.pins_valid(changed), "missing, malformed or mismatched actual bytes")
	changed = pins.duplicate(true)
	changed[0].file = "res://data/config/../config/stations.json"
	assert_false(SOURCE.pins_valid(changed), "path alias refused")
	changed = pins.duplicate(true)
	changed[0].override = true
	assert_false(SOURCE.pins_valid(changed))
	var traits: Dictionary = SOURCE._json("res://data/config/traits.json")
	assert_true(SOURCE.flags_valid({"runtime_enabled": false}, traits))
	assert_false(SOURCE.flags_valid({}, traits), "missing actual alpha declaration refuses")
	assert_false(SOURCE.flags_valid({"runtime_enabled": false}, {}), "missing actual traits declaration cannot fall back to cached configuration")
	for invalid: Variant in [true, 0, "false", null]:
		assert_false(SOURCE.flags_valid({"runtime_enabled": invalid}, traits))
	for invalid: Variant in [false, 1, "true", null]:
		var altered := traits.duplicate(true)
		altered.runtime_enabled = invalid
		assert_false(SOURCE.flags_valid({"runtime_enabled": false}, altered))
	assert_false(SOURCE._authored().is_empty(), "actual authored row remains independently bound")


func test_exact_once_selector_refuses_duplicates_missing_and_nonlive_bodies_without_nearest_fallback() -> void:
	var f := _fixture()
	var once := {f.body: SOURCE.SITE}
	assert_eq(SOURCE._select([f.body], once, f.world), f.body)
	var other := Node3D.new()
	f.realm.add_child(other)
	once[other] = "wild_once_1"
	assert_eq(SOURCE._select([other, f.body], once, f.world), f.body, "unrelated nearer body is irrelevant")
	once[other] = SOURCE.SITE
	assert_true(SOURCE._select([f.body, other], once, f.world) == null, "even a malformed duplicate exact-site body refuses")
	assert_true(SOURCE._select([f.body, f.body], once, f.world) == null)
	assert_true(SOURCE._select([other], {other: "wild_once_1"}, f.world) == null)
	f.body.visible = false
	assert_true(SOURCE._select([f.body], once, f.world) == null)
	f.body.visible = true
	f.creature.fainted = true
	assert_true(SOURCE._select([f.body], once, f.world) == null)
	f.creature.fainted = false
	f.realm.remove_child(f.body)
	assert_true(SOURCE._select([f.body], once, f.world) == null)
	f.realm.add_child(f.body)
	assert_eq(SOURCE._select([f.body], once, f.world), f.body)
	f.realm.free()


func test_packet_identity_world_uid_generation_and_actual_trait_instance_cannot_be_substituted() -> void:
	var f := _fixture()
	assert_true(SOURCE._packet_valid(f.body, f.world))
	var original := var_to_bytes(f.body.get_meta("ordinary_trait_packet"))
	for invalid: Variant in [true, "1", 1.5, 0, -1, NAN, INF, 9007199254740992.0, null]:
		f.body.set_meta("ordinary_trait_generation", invalid)
		assert_false(SOURCE._packet_valid(f.body, f.world))
		f.body.set_meta("ordinary_trait_generation", 1)
		f.body.set_meta("foundation_alpha_generation", invalid)
		assert_false(SOURCE._packet_valid(f.body, f.world))
		f.body.set_meta("foundation_alpha_generation", 1)
	f.body.set_meta("ordinary_trait_generation", 1)
	for field: String in ["world_namespace", "spawn_id", "spawn_generation"]:
		var packet: Dictionary = f.packet.duplicate(true)
		packet.captured_from[field] = 2 if field == "spawn_generation" else "foreign"
		f.body.set_meta("ordinary_trait_packet", packet)
		assert_false(SOURCE._packet_valid(f.body, f.world))
	f.body.set_meta("ordinary_trait_packet", f.packet.duplicate(true))
	var foreign := WORLD.new()
	foreign.world_id = f.world.world_id
	foreign.reward_delivery_namespace = f.world.reward_delivery_namespace
	f.body.set_meta("ordinary_trait_world", weakref(foreign))
	assert_false(SOURCE._packet_valid(f.body, f.world), "equal named world is not original object")
	f.body.set_meta("ordinary_trait_world", weakref(f.world))
	f.body.set_meta("ordinary_trait_uid", "foreign")
	assert_false(SOURCE._packet_valid(f.body, f.world))
	f.body.set_meta("ordinary_trait_uid", f.creature.uid)
	f.body.set_meta("foundation_alpha_packet", {})
	assert_false(SOURCE._packet_valid(f.body, f.world), "dual packet modes refused even for empty alpha packet")
	f.body.remove_meta("foundation_alpha_packet")
	f.creature.rolled_traits.append("foreign-trait")
	assert_false(SOURCE._packet_valid(f.body, f.world))
	f.creature.rolled_traits = f.packet.rolled_traits.duplicate()
	f.body.name = "Wild_mosshell_1_1"
	assert_false(SOURCE._packet_valid(f.body, f.world))
	f.body.name = SOURCE.BODY_NAME
	assert_true(SOURCE._packet_valid(f.body, f.world))
	assert_eq(var_to_bytes(f.body.get_meta("ordinary_trait_packet")), original, "source inspection never changes original packet")
	f.realm.free()


func test_public_api_keeps_real_mount_script_and_pin_guards_and_never_promotes_detached_controls() -> void:
	var f := _fixture()
	assert_true(SOURCE.freeze(f.tree, f.director, SOURCE.SITE, _pins()).is_empty(), "detached actual scripts are not actual mounted Game/Session/realm")
	assert_true(SOURCE.freeze(f.tree, f.director).is_empty(), "no implicit pin acquisition")
	assert_true(SOURCE.freeze(f.tree, f.director, "wild_once_1", _pins()).is_empty())
	assert_true(SOURCE.freeze(f.tree, f.body, SOURCE.SITE, _pins()).is_empty(), "foreign production body script is not director")
	assert_false(SOURCE.live(f.tree, f.director, {"ticket": RefCounted.new()}))
	assert_true(SOURCE.report({"ticket": RefCounted.new()}).is_empty())
	assert_true(SOURCE.selected_body({"ticket": RefCounted.new()}) == null)
	f.realm.free()


func test_frozen_reference_scope_cannot_follow_replaced_world_epoch_owner_or_expired_body() -> void:
	var f := _fixture()
	assert_true(SOURCE._same_objects(f.source, f.mounted, f.body))
	for field: String in ["epoch", "namespace", "world_id", "host_character_id", "host_peer"]:
		var changed: Dictionary = f.mounted.duplicate(true)
		changed[field] = 2 if field == "host_peer" else "foreign"
		assert_false(SOURCE._same_objects(f.source, changed, f.body))
	for field: String in ["game", "session", "realm", "director"]:
		var foreign := Node.new()
		var changed: Dictionary = f.mounted.duplicate(true)
		changed[field] = foreign
		assert_false(SOURCE._same_objects(f.source, changed, f.body))
		foreign.free()
	var foreign_world := WORLD.new()
	foreign_world.world_id = f.world.world_id
	foreign_world.reward_delivery_namespace = f.world.reward_delivery_namespace
	var changed: Dictionary = f.mounted.duplicate(true)
	changed.world = foreign_world
	assert_false(SOURCE._same_objects(f.source, changed, f.body))
	var replacement := SPECIES.spawn("mosshell")
	replacement.uid = f.creature.uid
	f.body.instance = replacement
	assert_false(SOURCE._same_objects(f.source, f.mounted, f.body), "same UID cannot alias another original instance")
	f.body.instance = f.creature
	var binding := SOURCE._remember(f.source)
	assert_eq(SOURCE.selected_body(binding), f.body)
	f.body.free()
	assert_true(SOURCE.selected_body(binding) == null)
	assert_false(SOURCE._same_objects(f.source, f.mounted, null))
	f.realm.free()


func test_lossless_original_report_survives_json_transport_and_rejects_tampering_without_capture_credit() -> void:
	var f := _fixture()
	# Internal component receipt only. Public freeze remains refused above.
	# Preserve a precise float and large native-shaped int through the codec.
	f.source.card.hp = 3.141592653589793
	f.source.scope.body_instance_id = 9223372036854775000
	var binding := SOURCE._remember(f.source)
	var report := SOURCE.report(binding)
	assert_false(report.is_empty())
	assert_eq(report.body_instance_id, "9223372036854775000")
	assert_false(report.acceptance_credit)
	var transported: Dictionary = JSON.parse_string(JSON.stringify(report))
	var verified := SOURCE.verified_report(transported)
	assert_false(verified.is_empty(), "complete authentic-shaped lossless documents survive ordinary outer JSON")
	if not verified.is_empty():
		assert_eq(verified.scope.body_instance_id, 9223372036854775000)
		assert_eq(var_to_bytes(verified.card.hp), var_to_bytes(f.source.card.hp))
	for field: String in ["site", "spawn_id", "body_uid", "namespace", "epoch", "body_instance_id", "source_sha256", "packet_document", "card_document", "scope_document", "authored_document"]:
		var changed := transported.duplicate(true)
		changed[field] = "foreign"
		assert_true(SOURCE.verified_report(changed).is_empty(), field)
	for invalid: Variant in [true, "1", 1.5, null]:
		var changed := transported.duplicate(true)
		changed.generation = invalid
		assert_true(SOURCE.verified_report(changed).is_empty())
	var changed := transported.duplicate(true)
	changed.packet.captured_from.spawn_id = SOURCE.SITE
	assert_true(SOURCE.verified_report(changed).is_empty(), "once site cannot replace authentic packet name")
	changed = transported.duplicate(true)
	changed.shipping_configuration_pins.pop_back()
	assert_true(SOURCE.verified_report(changed).is_empty())
	changed = transported.duplicate(true)
	changed.synthetic_success = true
	assert_true(SOURCE.verified_report(changed).is_empty())
	changed = transported.duplicate(true)
	changed.encounter_id = "actual-separately-bound-encounter"
	assert_false(SOURCE.verified_report(changed).is_empty(), "encounter identity still needs parent runtime/announcement check")
	changed.encounter_id = ""
	assert_true(SOURCE.verified_report(changed).is_empty())
	report.packet.rolled_traits.append("forged")
	assert_eq(SOURCE.report(binding).packet, f.packet, "returned metadata cannot mutate private frozen source")
	assert_eq(SOURCE.selected_body(binding), f.body)
	binding.extra = true
	assert_true(SOURCE.report(binding).is_empty(), "unknown binding fields cannot authorize a source")
	f.realm.free()


func _transport_document(original: Dictionary) -> Dictionary:
	var value := original.duplicate(true)
	value.source_document = DOCUMENT.stringify(original)
	value.source_sha256 = value.source_document.sha256_text()
	return JSON.parse_string(JSON.stringify(value))


func test_inner_documents_are_checked_even_when_outer_document_hash_matches() -> void:
	var f := _fixture()
	var binding := SOURCE._remember(f.source)
	var original: Dictionary = DOCUMENT.parse(SOURCE.report(binding).source_document)
	assert_false(SOURCE.verified_report(_transport_document(original)).is_empty())
	for field: String in ["packet_document", "card_document", "scope_document", "authored_document"]:
		var changed := original.duplicate(true)
		changed[field] = JSON.stringify(DOCUMENT.parse(original[field]))
		assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "plain JSON cannot replace lossless " + field)
	var changed := original.duplicate(true)
	var scope: Dictionary = DOCUMENT.parse(original.scope_document)
	scope.body_uid = "foreign-uid"
	changed.body_uid = scope.body_uid
	changed.scope_document = DOCUMENT.stringify(scope)
	assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "consistent scope mutation still conflicts with original card UID")
	changed = original.duplicate(true)
	scope = DOCUMENT.parse(original.scope_document)
	scope.generation = true
	changed.generation = true
	changed.scope_document = DOCUMENT.stringify(scope)
	assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "BOOL one cannot certify a generation")
	changed = original.duplicate(true)
	var authored: Dictionary = DOCUMENT.parse(original.authored_document)
	authored.spawn.order = 1901
	changed.authored_document = DOCUMENT.stringify(authored)
	assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "foreign authored source does not match actual frozen file")
	changed = original.duplicate(true)
	changed.packet.captured_from.spawn_generation = 2
	changed.packet_document = DOCUMENT.stringify(changed.packet)
	assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "a complete substituted generation remains forbidden")
	changed = original.duplicate(true)
	changed.shipping_configuration_pins[0].sha256 = "a".repeat(64)
	assert_true(SOURCE.verified_report(_transport_document(changed)).is_empty(), "outer digest cannot certify different current config bytes")
	f.realm.free()
