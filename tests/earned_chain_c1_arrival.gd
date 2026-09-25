extends SceneTree

## Validates the committed earned C1 fixture
## (`tests/fixtures/earned_saves/c1_arrival/`), produced by
## `tools/earned_saves/run_chain.sh` from a fresh save by ordinary play.
##
##   godot --headless --path . --script tests/earned_chain_c1_arrival.gd
##
## The fixture is copied to a scratch directory first, so neither the load's
## D100 split nor any autosave can modify the committed files. It is then
## loaded through the production title's Load list (the same path a player
## takes) and must boot the Cloudreach scene with the trainer at the arrival,
## carrying the earned Meadows state:
##   * every earned-chain beat flag PROVENANCE.json lists as gained;
##   * one to five owned creatures, the freed Veridian among them, and
##     `legendary_joined` (the F05 offer accepted), never `legendary_refused`;
##   * `TB_WORLD_SEED`-free: the saved world seed equals the recorded seed;
##   * no fixture/debug marker: Free Build off, no `debug`/`fixture`/`test_`
##     flag, no pending catch, and PROVENANCE declares zero injections.
## A failure prints `FAIL:` lines and exits 1.
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const FIXTURE := "res://tests/fixtures/earned_saves/c1_arrival/"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SLOT := 1
## The trainer stands where the production Rift arrival put them; the saved
## pose must reboot within this distance of the authored arrival road start.
const ARRIVAL_RADIUS_M := 60.0
const REQUIRED_FLAGS := [
	"road_gate_open", "tournament_won", "defeated_south_bridge_grunt", "south_bridge_open",
	"warrens_cleared", "hall_approach_open", "defeated_stronghold_elite", "defeated_warden",
	"legendary_freed", "legendary_settled", "legendary_joined", "realm_key_cloudreach",
	"realm_heart_meadows_earned", "meadows_acknowledged", "realm_gate_cloudreach_unlocked",
]
const FORBIDDEN_FLAGS := ["legendary_refused"]

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _run() -> void:
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE + "PROVENANCE.json"))
	_expect(provenance is Dictionary, "PROVENANCE.json is missing or unreadable")
	if not provenance is Dictionary:
		_done()
		return
	var prov: Dictionary = provenance
	_expect(int(prov.get("injections", -1)) == 0, "PROVENANCE must declare zero injections")
	_expect(int(prov.get("world_seed", -1)) > 0, "PROVENANCE must record the pinned world seed")
	var segments: Array = prov.get("segments", [])
	_expect(segments.size() == 7, "PROVENANCE must carry all seven segment receipts")
	for row: Variant in segments:
		_expect(bool((row as Dictionary).get("passed", false)),
			"segment %s did not pass" % str((row as Dictionary).get("segment", "?")))
	var scratch := "user://earned_chain_c1_check_%d_%d/" % [OS.get_process_id(), Time.get_ticks_msec()]
	_copy_tree(ProjectSettings.globalize_path(FIXTURE) + "save/", ProjectSettings.globalize_path(scratch))
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new(scratch))
	var info: Dictionary = game.call("save_slot_info", SLOT)
	_expect(str(info.get("realm", "")) == "cloudreach", "slot %d is not a Cloudreach save: %s" % [SLOT, info])
	_expect(not bool(info.get("legacy", true)), "the fixture slot is not at the current save version")

	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10:
		await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % SLOT) and not (node as Button).disabled:
			chosen = node
	_expect(chosen != null, "the title's Load list does not offer the fixture slot")
	if chosen == null:
		_done(scratch)
		return
	chosen.pressed.emit()
	var world: Node = null
	for _frame in 3600:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, "cloudreach")):
			world = scene
			break
	_expect(world != null, "the fixture never booted a ready Cloudreach scene")
	if world == null:
		_done(scratch)
		return
	for _i in 180:
		await physics_frame
	_expect(str(game.get("current_realm")) == "cloudreach", "loaded realm is not Cloudreach")
	var player := world.get_node("Player") as Node3D
	var arrival := _arrival_start(world)
	_expect(arrival != Vector3.INF, "the Cloudreach arrival road is missing from the world config")
	if arrival != Vector3.INF:
		var flat := Vector2(player.global_position.x - arrival.x, player.global_position.z - arrival.z)
		_expect(flat.length() <= ARRIVAL_RADIUS_M, "trainer is %.1f m from the Cloudreach arrival (limit %.0f)" % [
			flat.length(), ARRIVAL_RADIUS_M])
	var progression: RefCounted = game.get("progression")
	for flag: String in REQUIRED_FLAGS:
		_expect(bool(progression.call("has", flag)), "earned flag missing: " + flag)
	for flag: String in FORBIDDEN_FLAGS:
		_expect(not bool(progression.call("has", flag)), "forbidden flag present: " + flag)
	for flag: Variant in progression.call("all_set"):
		var id := str(flag).to_lower()
		_expect(not (id.contains("debug") or id.contains("fixture") or id.begins_with("test_")),
			"injected-looking flag present: " + str(flag))
	var last: Dictionary = segments[-1] if not segments.is_empty() else {}
	for flag: Variant in last.get("flags_total_list", []):
		_expect(bool(progression.call("has", str(flag))), "provenance flag not in the save: " + str(flag))
	_expect(not bool(game.get("free_build")), "Free Build is on in the fixture")
	_expect(game.get("pending_catch") == null, "a pending catch is parked in the fixture")
	_expect(int(game.get("world_seed")) == int(prov.get("world_seed", -2)),
		"saved world seed %d differs from the recorded seed" % int(game.get("world_seed")))
	var members: Array = (game.get("party") as RefCounted).call("members")
	_expect(members.size() >= 1 and members.size() <= 5, "owned party size %d is outside 1..5" % members.size())
	var species: Array[String] = []
	for member: RefCounted in members:
		species.append(str(member.get("species_id")))
	_expect(species.has(str(prov.get("legendary_species", "veridian"))),
		"the accepted Veridian is not on the belt: %s" % [species])
	var expected_party: Array = prov.get("final_party", [])
	var expected_species: Array[String] = []
	for row: Variant in expected_party:
		expected_species.append(str((row as Dictionary).get("species", "")))
	_expect(expected_species == species, "belt %s differs from provenance %s" % [species, expected_species])
	print("EARNED C1 FIXTURE realm=%s player=%s party=%s flags=%d" % [
		game.get("current_realm"), player.global_position, species, (progression.call("all_set") as Array).size()])
	_done(scratch)


func _arrival_start(world: Node) -> Vector3:
	if not world.has_method("config_data"):
		return Vector3.INF
	for route: Variant in (world.call("config_data") as Dictionary).get("routes", []):
		if str((route as Dictionary).get("id", "")) == "arrival_gate_road":
			var p: Array = (route as Dictionary).polyline[0]
			return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return Vector3.INF


func _copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	var dir := DirAccess.open(from)
	if dir == null:
		failures.append("fixture save dir is missing: " + from)
		return
	for file: String in dir.get_files():
		DirAccess.copy_absolute(from + file, to + file)
	for sub: String in dir.get_directories():
		_copy_tree(from + sub + "/", to + sub + "/")


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file: String in dir.get_files():
		DirAccess.remove_absolute(path + file)
	for sub: String in dir.get_directories():
		_remove_tree(path + sub + "/")
	DirAccess.remove_absolute(path)


func _done(scratch: String = "") -> void:
	if not scratch.is_empty():
		_remove_tree(ProjectSettings.globalize_path(scratch))
	if failures.is_empty():
		print("EARNED C1 FIXTURE OK")
		quit(0)
		return
	for failure: String in failures:
		print("  FAIL: %s" % failure)
	quit(1)
