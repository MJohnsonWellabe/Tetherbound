extends "res://tests/test_case.gd"

## Real typed CAS + character/world BOOL files and native delayed ENet
## Foundation envelopes. Physical Den presence/movement and publication of the
## already-saved world row are explicit fixtures, not full co-op acceptance.
const SYNC := preload("res://scripts/net/groom_passive_sync.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

class GuestSession extends GROOM.GroomSession:
	var hosting := false
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func is_host() -> bool: return hosting
	func is_active() -> bool: return true
	func snapshot_ready() -> bool: return true
	func local_peer_id() -> int:
		return multiplayer.get_unique_id() if is_inside_tree() and multiplayer.has_multiplayer_peer() else (1 if hosting else 2)
	func _foundation_groom_context(peer: int, key: String) -> Dictionary:
		if _authority_character(peer) != DATA.CHARACTER or key != "den:meadows:b3": return {}
		return GROOM.new()._context(1, int(get("_character_authority").call("revision", DATA.CHARACTER)))

class JournalRpc extends SAVE.FixtureRpc:
	func _ready() -> void: pass
	func publish_creature_training(_peer: int, _character: String, _receipt: String) -> bool:
		return false # This test explicitly delivers the real saved row below.

class ReleaseSample extends Node:
	func publish_now() -> bool: return true # Physical context is a disclosed fixture.
	func remote_body(_peer: int) -> CharacterBody3D: return null

class ObservedFixture extends SYNC:
	func _sample_host() -> void: pass # Test supplies the disclosed physical observations.

func _prepared(before: Dictionary, elapsed: float = 3.0, distance: float = 0.0) -> Dictionary:
	var result := {"character_id": DATA.CHARACTER, "world_namespace": "resource-namespace", "session_epoch": "resource-epoch",
		"intent": GROOM.new()._intent(before), "source_key": "den:meadows:b3", "revision": 0,
		"before": before.duplicate(true), "after": SYNC.derive(before, elapsed, distance, 0),
		"elapsed": elapsed, "distance": distance, "landmarks": 0, "discoveries": {}, "preparation_id": GROOM.SECOND}
	result.hash = SYNC.preparation_hash(result)
	return result

func _passive_difference(left: Dictionary, right: Dictionary) -> Dictionary:
	var differences := {}
	for index: int in mini(left.get("party", []).size(), right.get("party", []).size()):
		for field: String in SYNC.FIELDS:
			if not E._equivalent(left.party[index].get(field), right.party[index].get(field)):
				differences[str(index) + ":" + field] = {"disk": left.party[index].get(field), "prepared": right.party[index].get(field),
					"delta": float(left.party[index].get(field, 0)) - float(right.party[index].get(field, 0))}
	return differences

func _game(directory: String) -> Node:
	var game := SAVE.FixtureGame.new()
	game.local = GROOM.new()._player()
	game.world = DATA.new()._world()
	var session := GuestSession.new()
	session.fixture = game
	session.set("_altar_epoch", "resource-epoch")
	game.session = session
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	session.set("_character_authority", AUTHORITY.new())
	return game

func test_reservation_protects_core_and_admission_discoveries_survive_replacement() -> void:
	var before := GROOM.new()._before()
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, {"meadows": ["already_visited"]}))
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, {"meadows": []}))
	assert_eq(authority.discovered_landmarks(DATA.CHARACTER).meadows, ["already_visited"])
	var prepared := _prepared(before)
	assert_true(SYNC.valid(prepared))
	assert_true(authority.reserve_groom_preparation(DATA.CHARACTER, prepared))
	assert_eq(authority.stage_character_action(DATA.CHARACTER, 0, "groom", prepared.intent, GROOM.new()._context()).code, "transaction_busy")
	var forged := prepared.duplicate(true)
	forged.intent.action_id = "2223456789abcdef0123456789abcdef"
	assert_false(SYNC.valid(forged), "hash binds the original, not only equal after state")
	forged = prepared.duplicate(true)
	forged.after.party[0].hp = maxf(0.0, float(forged.after.party[0].hp) - 1.0)
	forged.hash = SYNC.preparation_hash(forged)
	assert_false(SYNC.valid(forged), "host derivation cannot change HP")
	assert_false(authority.cancel_groom_preparation(DATA.CHARACTER, "foreign"))
	assert_true(authority.commit_groom_preparation(DATA.CHARACTER, prepared))
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	assert_eq(authority.discovered_landmarks(DATA.CHARACTER).meadows, ["already_visited"])
	assert_false(authority.commit_groom_preparation(DATA.CHARACTER, prepared), "no unreserved replay")
	var historical := before.duplicate(true)
	historical.party[0].distance_m_together = 12.345678901234567
	historical.party[0].hp = float(historical.party[0].max_hp) - 0.1234567890123456
	var stationary := SYNC.derive(historical, 0.0, 0.0, 0)
	assert_eq(stationary.party[0].distance_m_together, historical.party[0].distance_m_together, "zero new travel preserves exact admitted history")
	var fractional := SYNC.derive(historical, 0.7, 0.1234567890123456, 0)
	assert_eq(fractional.party[0].hp, historical.party[0].hp, "JSON normalization never touches HP")
	var disk_form: Dictionary = JSON.parse_string(JSON.stringify(fractional))
	for field: String in ["nourishment", "happiness", "distance_m_together"]:
		assert_true(E._equivalent(fractional.party[0][field], disk_form.party[0][field]), "new passive output must roundtrip exactly: " + field)
	assert_true(E._equivalent(SYNC.unchanged_core(fractional), SYNC.unchanged_core(historical)))

func test_observation_preserves_pending_visits_but_refuses_time_across_feed_or_new_uid() -> void:
	var sync := SYNC.new()
	var before := GROOM.new()._before()
	var definitions := {"first": {"position": Vector3.ZERO, "discover_radius": 2.0}}
	sync.admitted(DATA.CHARACTER, {})
	sync.observe(DATA.CHARACTER, 0, 1000, 7, "meadows", Vector3.ZERO, definitions, false, before)
	sync.observe(DATA.CHARACTER, 0, 1500, 7, "meadows", Vector3(1, 0, 0), definitions, false, before)
	sync.observe(DATA.CHARACTER, 1, 2000, 7, "meadows", Vector3(2, 0, 0), definitions, false, before)
	assert_eq(sync.observations[DATA.CHARACTER].landmarks, 1)
	assert_true(sync.observations[DATA.CHARACTER].visits.has("meadows:first"))
	assert_almost_eq(sync.observations[DATA.CHARACTER].distance, 2.0)
	var fed := before.duplicate(true)
	fed.party[0].nourishment += 5.0
	sync.observe(DATA.CHARACTER, 2, 2500, 7, "meadows", Vector3(2, 0, 0), definitions, false, fed)
	assert_true(sync.observations[DATA.CHARACTER].chronology_conflict)
	sync.departed(DATA.CHARACTER)
	var elapsed: float = sync.observations[DATA.CHARACTER].elapsed
	sync.observe(DATA.CHARACTER, 2, 40000, 8, "meadows", Vector3(100, 0, 0), definitions, false, fed)
	assert_almost_eq(sync.observations[DATA.CHARACTER].elapsed, elapsed, 0.00001, "offline time is not elapsed care")
	assert_almost_eq(sync.observations[DATA.CHARACTER].distance, 2.0, 0.00001, "new body/teleport gets no deferred distance")
	assert_true(SYNC.derive(before, INF, 0, 0).is_empty())
	assert_true(SYNC.derive(before, 0, -1, 0).is_empty())
	var player := GROOM.new()._player()
	var admitted := RECORD.portable_projection(player.save_data())
	var roster_clock := SYNC.new()
	roster_clock.observe(DATA.CHARACTER, 0, 1000, 7, "meadows", Vector3.ZERO, {}, false, admitted)
	roster_clock.observe(DATA.CHARACTER, 0, 1500, 7, "meadows", Vector3.ONE, {}, false, admitted)
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	var caught := RECORD.portable_projection(player.save_data())
	assert_ne(caught.party[1].uid, caught.party[0].uid)
	roster_clock.observe(DATA.CHARACTER, 1, 2000, 7, "meadows", Vector3.ONE, {}, false, caught)
	assert_true(roster_clock.observations[DATA.CHARACTER].chronology_conflict, "pre-capture time cannot be replayed onto a new actual UID")

func test_actual_locked_landmark_refuses_before_counter_or_disk_ack() -> void:
	var directory := "user://test_groom_map_refusal_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := _game(directory)
	var sync: RefCounted = game.session._groom_service()
	var map: RefCounted = game.local.map_for("cloudreach")
	assert_false(map.discover_landmark("waterward_overlook"), "the actual canonical map requires its personal/world unlocks")
	var before := RECORD.portable_projection(game.local.save_data())
	var maps: Dictionary = game.local.save_data().realm_maps.duplicate(true)
	var prepared := _prepared(before, 0.0)
	prepared.discoveries = {"cloudreach": ["waterward_overlook"]}
	prepared.landmarks = 1
	prepared.after = SYNC.derive(before, 0.0, 0.0, 1)
	prepared.hash = SYNC.preparation_hash(prepared)
	assert_true(SYNC.valid(prepared))
	assert_true(game.save_system.save_character_prepared(game, DATA.CHARACTER))
	var path: String = game.save_system.character_store.path_for(DATA.CHARACTER)
	var bytes := FileAccess.get_file_as_bytes(path)
	sync.pending = {"scope": sync._scope(), "intent": prepared.intent, "source_key": prepared.source_key, "phase": "save", "prepared": prepared}
	assert_eq(sync.save_owner_baseline().code, "groom_landmark_view_pending")
	assert_true(E._equivalent(RECORD.portable_projection(game.local.save_data()), before))
	assert_true(E._equivalent(game.local.save_data().realm_maps, maps))
	assert_eq(FileAccess.get_file_as_bytes(path), bytes)
	assert_true(game.world.reward_deliveries.is_empty())
	assert_true(game.session.get("_foundation_requests").is_empty(), "no baseline ACK escaped the refused map install")
	sync.reset()
	game.session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func test_same_host_reoffers_original_until_seat_expiry_without_touching_saved_world_row() -> void:
	var directory := "user://test_groom_expiry_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := _game(directory)
	game.session.hosting = true
	var registry: RefCounted = game.session.registry()
	registry.add(2, DATA.CHARACTER, "Guest", "meadows")
	var authority: RefCounted = game.session.get("_character_authority")
	var before := RECORD.portable_projection(game.local.save_data())
	authority.bind_world("resource-namespace")
	authority.seed_admitted_character(before, DATA.CHARACTER)
	authority.seed_discovered_landmarks(DATA.CHARACTER, {})
	var sync: RefCounted = game.session._groom_service()
	sync.admitted(DATA.CHARACTER, {})
	var prepared := _prepared(before)
	assert_true(authority.reserve_groom_preparation(DATA.CHARACTER, prepared))
	sync.preparations[DATA.CHARACTER] = prepared.duplicate(true)
	var row: Dictionary = GROOM.new()._row(before, GROOM.new()._intent(before), GROOM.new()._context())
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true) # Explicit existing-journal fixture.
	assert_true(game.save_system.save_world_prepared(game, "resource-slot"))
	var path: String = game.save_system.world_store.path_for("resource-slot")
	var bytes := FileAccess.get_file_as_bytes(path)
	registry.remove(2)
	registry.reserve(DATA.CHARACTER, Time.get_ticks_msec() + 120000)
	sync.departed(DATA.CHARACTER)
	sync._prune_departed()
	assert_eq(sync.preparations[DATA.CHARACTER], prepared)
	registry.add(3, DATA.CHARACTER, "Guest", "meadows")
	var resumed: Dictionary = sync.host_resume(3, {"intent": {}, "revision": -1})
	assert_eq(resumed.prepared, prepared, "peer ID changes without recomputing the saved original")
	registry.remove(3)
	registry.reserve(DATA.CHARACTER, Time.get_ticks_msec() - 1)
	sync._prune_departed()
	assert_true(sync.preparations.is_empty())
	assert_true(sync.observations.is_empty())
	assert_false(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_eq(game.world.reward_deliveries[row.delivery_id], row)
	assert_eq(FileAccess.get_file_as_bytes(path), bytes, "expiry cannot cancel or rewrite a real saved world row")
	game.session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func test_owner_bool_save_precedes_ack_retries_keep_uid_and_restart_uses_disk_baseline() -> void:
	var directory := "user://test_guest_groom_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := _game(directory)
	var session: Node = game.session
	var sync: RefCounted = session.call("_groom_service")
	var before := RECORD.portable_projection(game.local.save_data())
	var prepared := _prepared(before)
	var member: RefCounted = game.local.party.at(0)
	assert_true(game.save_system.save_character_prepared(game, DATA.CHARACTER))
	var path: String = game.save_system.character_store.path_for(DATA.CHARACTER)
	var old_bytes := FileAccess.get_file_as_bytes(path)
	CONDITION.tick(member, CONDITION.config(), 1.0) # Genuine local drift before preparation arrives.
	sync.pending = {"scope": sync._scope(), "intent": prepared.intent.duplicate(true), "source_key": prepared.source_key, "phase": "save", "prepared": prepared}
	assert_true(session.owns_input(), "the prepared original owns input before the false BOOL writer")
	game.save_system.refuse_owner = true
	assert_eq(sync.save_owner_baseline().code, "groom_baseline_save_failed")
	assert_eq(FileAccess.get_file_as_bytes(path), old_bytes)
	assert_true(game.world.reward_deliveries.is_empty(), "a failed owner baseline never stages Groom")
	assert_true(game.local.party.at(0) == member)
	game.save_system.refuse_owner = false
	assert_true(sync.save_owner_baseline().saved)
	var disk: Dictionary = game.save_system.character_store.read(DATA.CHARACTER)
	assert_true(E._equivalent(RECORD.portable_projection(disk), prepared.after), "owner disk must equal prepared baseline: " + str(_passive_difference(RECORD.portable_projection(disk), prepared.after)))
	assert_true(session.owns_input(), "BOOL success still waits for the host's exact ACK path")
	var host := AUTHORITY.new()
	host.bind_world("resource-namespace")
	host.seed_admitted_character(before, DATA.CHARACTER)
	host.seed_discovered_landmarks(DATA.CHARACTER, {})
	assert_true(host.reserve_groom_preparation(DATA.CHARACTER, prepared))
	assert_true(host.seed_admitted_character(prepared.after, DATA.CHARACTER).already_seeded)
	assert_true(E._equivalent(host.state(DATA.CHARACTER), before), "same-host rejoin cannot replace a reserved record")
	assert_true(host.commit_groom_preparation(DATA.CHARACTER, prepared))
	var restarted := AUTHORITY.new()
	restarted.bind_world("resource-namespace")
	assert_true(restarted.seed_admitted_character(RECORD.portable_projection(disk), DATA.CHARACTER).ok)
	assert_false(restarted.commit_groom_preparation(DATA.CHARACTER, prepared), "a new host has no old preparation capability")
	assert_true(E._equivalent(restarted.state(DATA.CHARACTER), prepared.after), "restarted registry must equal prepared baseline: " + str(_passive_difference(restarted.state(DATA.CHARACTER), prepared.after)))
	sync.reset()
	assert_false(session.owns_input())
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

var _root: Node
var _apis: Array[SceneMultiplayer] = []
var _peers: Array[ENetMultiplayerPeer] = []
var _native_directory := ""
var _native_completed := false

func _until(check: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not check.call() and Time.get_ticks_msec() < deadline:
		for api: SceneMultiplayer in _apis: api.poll()
		OS.delay_msec(1)
	return check.call()

func _case_native_delayed_preparation() -> void:
	var directory := "user://test_guest_groom_enet_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	_native_directory = directory
	var tree := Engine.get_main_loop() as SceneTree
	_root = Node.new()
	_root.name = "GuestGroomNative"
	tree.root.add_child(_root)
	var host := _game(directory.path_join("host"))
	var guest := _game(directory.path_join("guest"))
	host.name = "Host"
	guest.name = "Guest"
	guest.local.load_data(host.local.save_data())
	for game: Node in [host, guest]:
		_root.add_child(game)
		var api := SceneMultiplayer.new()
		_apis.append(api)
		tree.set_multiplayer(api, game.get_path())
		game.session.name = "Session"
		game.add_child(game.session)
		var composition := Node.new()
		composition.name = "FoundationComposition"
		game.session.add_child(composition)
		var lifecycle := ReleaseSample.new()
		lifecycle.name = "TravelLifecycle"
		composition.add_child(lifecycle)
	host.session.hosting = true
	var server := ENetMultiplayerPeer.new()
	server.set_bind_ip("127.0.0.1")
	assert_eq(server.create_server(0, 1, 4), OK)
	var client := ENetMultiplayerPeer.new()
	assert_eq(client.create_client("127.0.0.1", server.host.get_local_port(), 4), OK)
	_peers = [server, client]
	_apis[0].multiplayer_peer = server
	_apis[1].multiplayer_peer = client
	assert_true(_until(func() -> bool: return _apis[0].get_peers().size() == 1 and _apis[1].get_peers().has(1)))
	var peer := _apis[1].get_unique_id()
	host.session.registry().add(peer, DATA.CHARACTER, "Guest", "meadows")
	var authority: RefCounted = host.session.get("_character_authority")
	var before := RECORD.portable_projection(guest.local.save_data())
	authority.bind_world("resource-namespace")
	authority.seed_admitted_character(before, DATA.CHARACTER)
	authority.seed_discovered_landmarks(DATA.CHARACTER, {})
	var host_sync := ObservedFixture.new(host.session)
	host.session.set("_groom_passive", host_sync)
	host_sync.admitted(DATA.CHARACTER, {})
	host_sync.observe(DATA.CHARACTER, 0, 1000, 7, "meadows", Vector3.ZERO, {}, false, before)
	host_sync.observe(DATA.CHARACTER, 0, 1500, 7, "meadows", Vector3.ZERO, {}, false, before)
	var journal := JournalRpc.new()
	journal.name = "LedgerRpc"
	journal.fixture = host
	journal.ledger = preload("res://scripts/net/world_ledger.gd").new(host.world)
	host.session.add_child(journal)
	assert_true(host.save_system.save_world_prepared(host, "resource-slot"))
	assert_true(guest.save_system.save_character_prepared(guest, DATA.CHARACTER))
	guest.save_system.refuse_owner = true
	var guest_sync: RefCounted = guest.session._groom_service()
	var original := GROOM.new()._intent(before)
	guest_sync.begin(original, "den:meadows:b3")
	# Deliberately withhold the real receive pump. The production owner fence
	# already blocks Game's condition tick before any host response exists.
	OS.delay_msec(40)
	assert_true(guest.session._owner_training_mutation_blocked(guest.local), "the real in-flight original must block owner mutations before RPC delivery")
	assert_true(host.world.reward_deliveries.is_empty())
	assert_true(_until(func() -> bool: return guest_sync.pending.has("prepared")))
	assert_true(host.world.reward_deliveries.is_empty(), "real false owner BOOL withheld the prepare ACK")
	var prepared: Dictionary = guest_sync.pending.prepared.duplicate(true)
	assert_true(authority.creature_training_is_pending(DATA.CHARACTER))
	guest.save_system.refuse_owner = false
	guest_sync._retry_owner()
	assert_true(_until(func() -> bool: return not host.world.reward_deliveries.is_empty()))
	var row: Dictionary = host.world.reward_deliveries.values()[0]
	assert_eq(row.action, "groom")
	assert_eq(row.intent, original)
	assert_true(E._equivalent(row.before, prepared.after), "the journal starts from the actual BOOL-saved preparation")
	var disk := RECORD.portable_projection(guest.save_system.character_store.read(DATA.CHARACTER))
	assert_true(E._equivalent(disk, row.before), "native owner disk must equal journal baseline: " + str(_passive_difference(disk, row.before)))
	assert_eq(guest.local.inventory.count("fiber"), 0, "preparation save contains no reward")
	# The existing owner installer alone applies the real journal reward.
	guest.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	var applied := preload("res://scripts/net/character_action_owner.gd").apply_owner(guest, row)
	assert_true(applied.get("saved") == true, str(applied))
	assert_eq(guest.local.inventory.count("fiber"), 1)
	assert_eq(host.world.reward_deliveries.size(), 1)
	_native_completed = true

func _native_cleanup() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var paths: Array[NodePath] = []
	if is_instance_valid(_root):
		for child: Node in _root.get_children(): paths.append(child.get_path())
		_root.free()
	_root = null
	for path: NodePath in paths: tree.set_multiplayer(null, path)
	for transport: ENetMultiplayerPeer in _peers: transport.close()
	_apis.clear()
	_peers.clear()
	if not _native_directory.is_empty(): preload("res://tests/helpers/split_save_fixture.gd").wipe(_native_directory)
	_native_directory = ""

func test_native_delayed_preparation_and_bool_retry_enter_existing_groom_journal() -> void:
	var path := "user://guest_groom_native_runner.gd"
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_guest_groom_passive_sync.gd").new()\n\ttest._case_native_delayed_preparation()\n\ttest._native_cleanup()\n\tprint("GROOM_NATIVE_RESULT=" + JSON.stringify({"assertions": test.assertion_count, "failures": test.failures, "completed": test._native_completed}))\n\tquit(0 if test.failures.is_empty() and test._native_completed else 1)\n')
	runner.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", ProjectSettings.globalize_path(path), "--log-file", ProjectSettings.globalize_path("user://guest-groom-native-child.log")], output, true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("GROOM_NATIVE_RESULT="): result = JSON.parse_string(line.trim_prefix("GROOM_NATIVE_RESULT="))
	assert_true(result.get("completed") == true, combined)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_true(int(result.get("assertions", 0)) >= 18, combined)
	assert_false(combined.contains("ERROR:") or combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)

