extends "res://tests/test_case.gd"

## The envelope, not the contents.
##
## What these pin is the promise SaveManager makes to every system that will
## ever register with it: your data comes back as you gave it, your neighbour
## cannot tread on it, and a file this build cannot read is refused whole rather
## than dribbled into a running game. The domains themselves — structures,
## party, inventory — test their own record shapes.
##
## The manager is instantiated directly rather than reached through
## `/root/SaveManager`. `run_tests.gd` does all its work inside `_init()`, and
## Godot attaches autoloads to the tree only after that returns, so the
## singleton does not exist yet at this point. Testing the script instead of the
## singleton is also simply the right scope: this is logic, not wiring.

const MANAGER := preload("res://autoload/save_manager.gd")

## A slot number no real save uses, so a failing test cannot eat the owner's
## game.
const TEST_SLOT := 9001


## The minimum a contributor has to be. Anything with these two methods can
## register, which is the whole design — a new system is two methods, not a new
## file.
class FakeDomain extends RefCounted:
	var payload: Dictionary = {}
	var received: Dictionary = {}
	var load_calls: int = 0

	func _init(initial: Dictionary = {}) -> void:
		payload = initial

	func save_data() -> Dictionary:
		return payload.duplicate(true)

	func load_data(data: Dictionary) -> void:
		received = data.duplicate(true)
		load_calls += 1


var manager: Node = null


func before_each() -> void:
	manager = MANAGER.new()
	_delete_slot_file()


func after_each() -> void:
	_delete_slot_file()
	if is_instance_valid(manager):
		# A Node, not a RefCounted, and never in the tree — nothing else will
		# ever free it.
		manager.free()
	manager = null


func _delete_slot_file() -> void:
	var path: String = manager.call("slot_path", TEST_SLOT)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Hand-write a slot file, to forge the states a correct build cannot produce.
func _write_raw(envelope: Dictionary) -> void:
	var file := FileAccess.open(manager.call("slot_path", TEST_SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()


# --- the round trip -------------------------------------------------------

func test_a_registered_domain_gets_back_exactly_what_it_saved() -> void:
	var writer := FakeDomain.new({"pieces": 4, "name": "hut"})
	manager.call("register", "structures", writer)
	assert_true(bool(manager.call("save", TEST_SLOT)), "save reported failure")
	assert_true(bool(manager.call("has_slot", TEST_SLOT)), "save left no file")

	# A FRESH manager and a fresh contributor, because reading back through the
	# same objects that wrote would pass even if nothing reached the disk.
	var reader := FakeDomain.new()
	var second: Node = MANAGER.new()
	second.call("register", "structures", reader)
	assert_true(bool(second.call("load_slot", TEST_SLOT)), "load reported failure")
	second.free()

	assert_eq(reader.load_calls, 1, "domain was loaded a strange number of times")
	assert_eq(int(reader.received.get("pieces", 0)), 4)
	assert_eq(str(reader.received.get("name", "")), "hut")


func test_a_saved_slot_can_be_deleted_and_then_reads_as_absent() -> void:
	manager.call("register", "structures", FakeDomain.new({"pieces": 1}))
	manager.call("save", TEST_SLOT)
	assert_true(bool(manager.call("has_slot", TEST_SLOT)))
	assert_true(bool(manager.call("delete_slot", TEST_SLOT)), "delete reported failure")
	assert_false(bool(manager.call("has_slot", TEST_SLOT)), "slot survived deletion")
	# Deleting nothing is false, not an error: "there was no save" is an answer.
	assert_false(bool(manager.call("delete_slot", TEST_SLOT)), "deleting an absent slot claimed success")


# --- the empty slot -------------------------------------------------------

func test_an_unknown_slot_loads_nothing_and_leaves_the_game_alone() -> void:
	# The "new game" path, and the "slot 3 is empty" path. Neither is a fault
	# and neither may disturb a contributor that is already holding live state.
	var domain := FakeDomain.new({"pieces": 7})
	manager.call("register", "structures", domain)
	assert_false(bool(manager.call("has_slot", TEST_SLOT)))
	assert_false(bool(manager.call("load_slot", TEST_SLOT)), "an absent slot claimed to load")
	assert_eq(domain.load_calls, 0, "an absent slot still called load_data")
	assert_eq(int(domain.payload.get("pieces", 0)), 7, "an absent slot disturbed live state")


# --- the version gate -----------------------------------------------------

func test_a_file_from_another_version_is_refused_whole_rather_than_partly_applied() -> void:
	# The failure this guards against is not a crash. It is a game that looks
	# like it loaded, with one system holding state from a build that no longer
	# exists. Refuse the file; do not hand out the half of it that still parses.
	_write_raw({
		"version": int(MANAGER.SAVE_VERSION) + 1,
		"structures": {"pieces": 12},
		"party": {"pals": 3},
	})
	var structures := FakeDomain.new()
	var party := FakeDomain.new()
	manager.call("register", "structures", structures)
	manager.call("register", "party", party)

	assert_false(bool(manager.call("load_slot", TEST_SLOT)), "a version mismatch claimed to load")
	assert_eq(structures.load_calls, 0, "a version mismatch reached structures anyway")
	assert_eq(party.load_calls, 0, "a version mismatch reached party anyway")


func test_an_unversioned_or_unreadable_file_is_refused_the_same_way() -> void:
	# A file with no version at all reads as version 0, which is nobody's build.
	_write_raw({"structures": {"pieces": 12}})
	var domain := FakeDomain.new()
	manager.call("register", "structures", domain)
	assert_false(bool(manager.call("load_slot", TEST_SLOT)), "an unversioned file claimed to load")
	assert_eq(domain.load_calls, 0, "an unversioned file was applied")


# --- domain isolation -----------------------------------------------------

func test_two_domains_in_one_envelope_do_not_clobber_each_other() -> void:
	# The reason there is one file rather than one file per system: the systems
	# have to be able to share it without knowing about each other.
	manager.call("register", "structures", FakeDomain.new({"pieces": 4}))
	manager.call("register", "party", FakeDomain.new({"pals": ["ember", "brook"]}))
	assert_true(bool(manager.call("save", TEST_SLOT)))

	var structures := FakeDomain.new()
	var party := FakeDomain.new()
	var second: Node = MANAGER.new()
	second.call("register", "structures", structures)
	second.call("register", "party", party)
	assert_true(bool(second.call("load_slot", TEST_SLOT)))
	second.free()

	assert_eq(int(structures.received.get("pieces", 0)), 4, "structures lost its own data")
	assert_false(structures.received.has("pals"), "structures was handed the party's data")
	assert_eq((party.received.get("pals", []) as Array).size(), 2, "party lost its own data")
	assert_false(party.received.has("pieces"), "party was handed the structures data")


func test_a_domain_missing_from_the_file_is_left_alone_not_wiped() -> void:
	# A save written before a system existed must not blank that system out. The
	# version gate above already proves the file is this build's shape, so an
	# absent key means "nothing to say", not "set it to empty".
	_write_raw({"version": int(MANAGER.SAVE_VERSION), "structures": {"pieces": 4}})
	var structures := FakeDomain.new()
	var party := FakeDomain.new({"pals": ["ember"]})
	manager.call("register", "structures", structures)
	manager.call("register", "party", party)

	assert_true(bool(manager.call("load_slot", TEST_SLOT)))
	assert_eq(structures.load_calls, 1, "the domain that WAS in the file did not load")
	assert_eq(party.load_calls, 0, "an absent domain was handed an empty dictionary")


# --- registration ---------------------------------------------------------

func test_registering_the_same_domain_twice_replaces_it_rather_than_duplicating() -> void:
	# Contributors re-register defensively, because under `--script` the
	# autoloads land after the scene does. That has to be free.
	var first := FakeDomain.new({"pieces": 1})
	var second := FakeDomain.new({"pieces": 2})
	manager.call("register", "structures", first)
	manager.call("register", "structures", second)
	assert_eq((manager.call("domains") as Array).size(), 1, "a re-registration added a second domain")

	manager.call("save", TEST_SLOT)
	var reader := FakeDomain.new()
	var other: Node = MANAGER.new()
	other.call("register", "structures", reader)
	other.call("load_slot", TEST_SLOT)
	other.free()
	assert_eq(int(reader.received.get("pieces", 0)), 2, "the stale contributor was written")


func test_an_object_that_cannot_save_is_refused_registration() -> void:
	# Better to fail at the register call, where the stack says which system is
	# wrong, than at save time when the file is already half written.
	manager.call("register", "broken", RefCounted.new())
	assert_false(bool(manager.call("is_registered", "broken")), "a contributor with no save_data registered")
	# `version` is the envelope's own key; a domain by that name would overwrite
	# it and the file would read as version 0 forever after.
	manager.call("register", "version", FakeDomain.new())
	assert_false(bool(manager.call("is_registered", "version")), "'version' was accepted as a domain")


func test_an_unregistered_domain_stops_being_written() -> void:
	var domain := FakeDomain.new({"pieces": 4})
	manager.call("register", "structures", domain)
	manager.call("unregister", "structures")
	assert_false(bool(manager.call("is_registered", "structures")))
	assert_true(bool(manager.call("save", TEST_SLOT)))

	var reader := FakeDomain.new()
	var other: Node = MANAGER.new()
	other.call("register", "structures", reader)
	other.call("load_slot", TEST_SLOT)
	other.free()
	assert_eq(reader.load_calls, 0, "an unregistered domain was still in the file")
