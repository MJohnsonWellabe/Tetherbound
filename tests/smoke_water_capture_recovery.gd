extends SceneTree

## Explicit seeded caught-result fixture, NOT a catch-roll/fight proof. Real
## Water scene, world journal reload, claim-service reconstruction and existing
## five-holder UI buttons exercise interrupted durable handover end to end.
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const REWARDS := preload("res://scripts/world/water_alpha_rewards.gd")
const CLAIMS := preload("res://scripts/net/water_capture_claims.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "capture-recovery-smoke"
	game.world.world_id = "capture-recovery-world"
	game.save_system = SAVE.new("user://water_capture_recovery_%d/" % Time.get_ticks_usec())
	var original: Array = []
	for i in 5:
		var keeper := SPECIES.spawn("water_mosshell")
		keeper.nickname = "Keeper %d" % i
		game.local.party.add(keeper)
		original.append(keeper)
	var captured := SPECIES.spawn("water_aquaryn")
	captured.iv_hp = 0.79
	captured.iv_attack = 0.23
	captured.boost_defence = 2
	captured.set_level(49, preload("res://scripts/creatures/progression.gd").config())
	captured.hp *= 0.41
	captured.nickname = "Journal Tide"
	captured.trait_primary = "hardy"
	captured.trait_secondary = "swift"
	captured.swim_stamina_fraction = 0.317
	captured.battles_fought = 19
	captured.distance_m_together = 719.25
	captured.feeds_together = 8
	captured.caught_on_day = maxi(1, game.day)
	var expected := CODEC.encode(captured)
	var claim := REWARDS.capture_claim(game.world.world_id, game.local.character_id, expected)
	var old_service: Node = game.ledger.get_node("WaterCaptureClaims")
	old_service.set_process(false)
	var result: Dictionary = REWARDS.resolve(game, game.ledger.get("ledger"), "caught", [game.local.character_id], claim)
	if not check(result.get("ok", false), "Explicit seeded caught result journals exact claim before any handover"):
		print(result)
		_finish()
		return
	var stored: Dictionary = game.save_system.get("_worlds").read(game.world.world_id)
	check(stored.get("water_capture_claims", {}).has(claim.id), "Actual world file retains interrupted capture claim")
	check(game.pending_catch == null and game.local.party.size() == 5, "No newcomer ownership before service reconstruction")
	game.ledger.remove_child(old_service)
	old_service.free()
	game.world.water_capture_claims.clear()
	game.world.load_data(stored)
	check(game.world.water_capture_claims.has(claim.id), "Production world load restores claim from actual disk journal")
	var service := CLAIMS.new()
	service.name = "WaterCaptureClaims"
	game.ledger.add_child(service)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water world builds after interrupted capture journal"):
		_finish()
		return
	deadline = Time.get_ticks_msec() + 10000
	while game.pending_catch == null and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(game.pending_catch != null and service.owns_pending(game.pending_catch), "Recreated production claim service recovers pending captured creature"):
		_finish()
		return
	var pending: RefCounted = game.pending_catch
	var recovered := CODEC.encode(pending)
	for key: String in expected:
		check(is_equal_approx(float(recovered[key]), float(expected[key])) if expected[key] is float else recovered[key] == expected[key], "Interrupted capture retains " + key)
	var menu: Node = game.menu()
	var tab: Node
	for i in menu.get("_tabs").size():
		if str(menu.get("_tabs")[i].id) == "creatures": tab = menu.get("_bodies")[i]
	deadline = Time.get_ticks_msec() + 5000
	while (not menu.is_open() or tab.get("_release_stage") != "choose") and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(menu.is_open() and tab.get("_release_stage") == "choose", "Existing five-holder ceremony opens automatically for recovered claim"):
		_finish()
		return
	check(game.world.water_capture_claims.has(claim.id), "Host claim remains while release decision is still pending")
	check(not game.local.flags.has("water_capture_receipt:" + claim.id), "Opening ceremony does not prematurely receipt capture")
	var rows: Array = tab.get("_rows")
	rows[2].pressed.emit()
	check(tab.get("_release_stage") == "confirm", "Actual third holder button opens farewell confirmation")
	tab.get("_farewell_release").pressed.emit()
	check(tab.get("_release_stage") == "done", "Actual farewell button completes durable claim transaction")
	check(game.pending_catch == null and game.local.party.size() == 5, "Completion clears pending capture and retains exactly five owned creatures")
	check(game.local.party.at(2) == pending, "Captured instance occupies chosen holder")
	for i in [0, 1, 3, 4]: check(game.local.party.at(i) == original[i], "Other holder identity remains at slot %d" % i)
	var character: Dictionary = game.save_system.get("_characters").read(game.local.character_id)
	check(character.get("flags", {}).get("flags", []).has("water_capture_receipt:" + claim.id), "Actual character file contains durable capture receipt")
	check(character.get("party", []).size() == 5 and character.party[2].nickname == "Journal Tide", "Same character file contains resulting five-holder party")
	check(not game.world.water_capture_claims.has(claim.id), "Acknowledged personal save removes host claim")
	check(not game.save_system.get("_worlds").read(game.world.world_id).get("water_capture_claims", {}).has(claim.id), "Claim removal is durable in actual world file")
	var party_revision: int = game.local.party.revision
	service.receive_claim(claim)
	service.call("_offer_pending")
	check(game.pending_catch == null and game.local.party.revision == party_revision and game.local.party.size() == 5, "Repeated claim delivery cannot duplicate creature or offer another holder")
	_finish()

func _finish() -> void:
	print("Water capture recovery smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
