extends "res://tests/test_case.gd"

## F19#5: the committed new-order chapter-arrival saves are current-schema
## production saves (not refused as an older version), stand in their own
## realm, keep five distinct companions at the chapter_curve team.enter level
## their profile declares, and carry their generated-setup disclosure.
const SAVE := preload("res://scripts/save/save_game.gd")
const PROFILES := "res://tests/fixtures/earned_saves/generated_boundary_profiles.json"
const FIXTURES := {
	"tidewake": {"dir": "res://tests/fixtures/earned_saves/tidewake_arrival_generated", "realm": "water"},
	"cloudreach": {"dir": "res://tests/fixtures/earned_saves/cloudreach_arrival_generated", "realm": "cloudreach"},
	"stormwood": {"dir": "res://tests/fixtures/earned_saves/stormwood_arrival_generated", "realm": "stormwood"},
}


func test_each_arrival_save_loads_in_its_realm_with_the_declared_five() -> void:
	var profiles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILES)).profiles
	for profile: String in FIXTURES:
		var row: Dictionary = FIXTURES[profile]
		var scratch := "user://test_generated_arrival_%s_%d" % [profile, OS.get_process_id()]
		_copy_tree(ProjectSettings.globalize_path(str(row.dir) + "/save"), ProjectSettings.globalize_path(scratch))
		var save := SAVE.new(scratch)
		var info: Dictionary = save.slot_info(0)
		assert_eq(str(info.get("realm", "")), str(row.realm), profile + " slot 0 realm")
		assert_eq(info.get("load_result", {}).get("code"), "ok", profile + " is a current-schema save")
		assert_eq(int(info.get("party_size", 0)), 5, profile + " keeps five companions")
		var data: Dictionary = save._read(0)
		var uids := {}
		for member: Dictionary in data.get("party", []):
			uids[str(member.get("uid", ""))] = true
			assert_eq(int(member.get("level", 0)), int(profiles[profile].party_levels[0]), profile + " companion level")
		assert_eq(uids.size(), 5, profile + " companions are distinct")
		assert_false(uids.has(""), profile + " companions have identities")
		var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(row.dir) + "/PROVENANCE.json"))
		assert_eq(provenance.get("kind"), "generated_boundary_save", profile + " provenance kind")
		assert_eq(provenance.get("profile"), profile, profile + " provenance profile")
		assert_eq(provenance.get("prior_earned_play"), false, profile + " never claims earned play")
		assert_eq(str(provenance.get("disclosure", "")), str(profiles[profile].disclosure), profile + " carries its disclosure")


func _copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	for file: String in DirAccess.get_files_at(from):
		DirAccess.copy_absolute(from.path_join(file), to.path_join(file))
	for child: String in DirAccess.get_directories_at(from):
		_copy_tree(from.path_join(child), to.path_join(child))
