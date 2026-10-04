extends "res://tests/test_case.gd"

# The host resolves shared-fight geometry against its OWN copy of a remote
# body, never against the position the client claimed:
# `encounter_director.gd::_host_strike()` takes `striker.call("centre")` for
# the protocol's step-2 origin, and `remote_trainer.gd::_anchor_params()` reads
# `global_position` with a comment saying why.
#
# Both proxies are driven toward `_render_position` with `move_and_slide()`, so
# the host's own collision can pin the BODY while `_render_position` goes on
# tracking `net_position` perfectly. The original snap test compared only
# `_render_position` to `net_position`, so in exactly that case it never fired
# again and the body stayed where it snagged for the rest of the session.
#
# Measured consequence, before the fix: a guest seated 1.4 m from a shared
# opponent was held 8.86 m away by the host after 28 placements; the host
# ACCEPTED its strike -- valid receipt, right encounter, right peer id -- and
# scored `hit = false`, for 0 of 6 landed swings against a host that landed
# first try every time. See `ralph/reports/MEADOWS-PAYOFFS/tournament` and
# `ralph/reports/MEADOWS-PAYOFFS/river-sela-mill`.

const REMOTE_CREATURE := preload("res://scripts/creatures/remote_creature.gd")
const REMOTE_TRAINER := preload("res://scripts/net/remote_trainer.gd")
const REMOTE_SCENE := preload("res://scenes/player/remote_trainer.tscn")

const SNAP_M := 6.0

class FloorTrainer extends "res://scripts/net/remote_trainer.gd":
	# Disclosed network dispatch/presentation doubles. The actual _follow,
	# CharacterBody3D motion, authored capsule and contact capture run unchanged.
	var fixture_mount: Node3D
	func _ready() -> void: pass
	func _physics_process(delta: float) -> void: _follow(delta)
	func _apply_ride_and_flight(_delta: float) -> void: pass
	func _mount_body() -> Node3D: return fixture_mount


func _floor_fixture(tree: SceneTree, support: bool = true) -> Dictionary:
	var world := Node3D.new()
	tree.root.add_child(world)
	var floor_body: StaticBody3D
	if support:
		floor_body = StaticBody3D.new()
		floor_body.position = Vector3(0, 104.5, -260)
		var box := BoxShape3D.new()
		box.size = Vector3(12, 1, 12) # Actual top plane at Cloud's 105m elevation.
		var surface := CollisionShape3D.new()
		surface.shape = box
		floor_body.add_child(surface)
		world.add_child(floor_body)
	var actor := FloorTrainer.new()
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	# Reuse the scene's actual authored footprint/snap instead of a test-only
	# capsule, margin, collision bypass, floor flag or invented landing height.
	var authored: SceneState = REMOTE_SCENE.get_state()
	for node: int in authored.get_node_count():
		for property: int in authored.get_node_property_count(node):
			var key: StringName = authored.get_node_property_name(node, property)
			var value: Variant = authored.get_node_property_value(node, property)
			if authored.get_node_name(node) == &"RemoteTrainer" and key in [&"floor_max_angle", &"floor_snap_length"]:
				actor.set(key, value)
			elif authored.get_node_name(node) == &"Collision":
				if key == &"shape": collision.shape = (value as CapsuleShape3D).duplicate() as CapsuleShape3D
				elif key == &"transform": collision.transform = value
	actor.add_child(collision)
	actor.position = Vector3(0, 105.03099822998, -260) # Disclosed R7 starting pose.
	actor.net_position = actor.position
	actor._render_position = actor.position
	actor._has_render = true
	world.add_child(actor)
	return {"world": world, "floor": floor_body, "actor": actor, "target": actor.net_position}


func _free_floor_fixture(tree: SceneTree, fixture: Dictionary) -> void:
	fixture.world.queue_free()
	await tree.process_frame
	await tree.process_frame


func run_initialized_remote_floor_case(tree: SceneTree) -> Dictionary:
	var f := _floor_fixture(tree)
	var actor: FloorTrainer = f.actor
	assert_almost_eq(actor.floor_snap_length, 0.4, 0.0000001, "authored float32 property representation only")
	assert_false(actor.is_on_floor())
	for _frame in 8: await tree.physics_frame
	assert_true(actor.is_on_floor(), "stationary remote landing must acquire ACTUAL floor contact")
	assert_true(actor.get_floor_normal().angle_to(Vector3.UP) <= actor.floor_max_angle)
	assert_eq(actor._foundation_ground_contact_position, actor.global_position, "capture follows the real snap")
	assert_true(actor._foundation_ground_contact_generation > 0)
	assert_true(actor.global_position.distance_to(f.target) <= actor.floor_snap_length, "only authored physical snap range")
	assert_eq(actor.net_position, f.target, "host floor seating never replaces owner-published pose")
	var stayed_grounded := true
	for _frame in 12:
		await tree.physics_frame
		stayed_grounded = stayed_grounded and actor.is_on_floor()
	assert_true(stayed_grounded, "owner-height correction must not alternate grounded and airborne frames")
	var generation: int = actor._foundation_ground_contact_generation
	f.floor.queue_free()
	for _frame in 4: await tree.physics_frame
	assert_false(actor.is_on_floor(), "removed actual support cannot retain a floor flag")
	assert_true(actor._foundation_ground_contact_generation > generation)
	await _free_floor_fixture(tree, f)
	f = _floor_fixture(tree, false)
	actor = f.actor
	for _frame in 8: await tree.physics_frame
	assert_false(actor.is_on_floor(), "unsupported stationary pose cannot manufacture contact")
	assert_eq(actor.global_position, f.target)
	assert_true(actor._foundation_ground_contact_generation > 0)
	await _free_floor_fixture(tree, f)
	f = _floor_fixture(tree)
	actor = f.actor
	actor.net_position += Vector3.UP * 0.2
	for _frame in 4: await tree.physics_frame
	assert_false(actor.is_on_floor(), "a rising target remains free even with idle animation")
	assert_true(actor.global_position.y > (f.target as Vector3).y)
	await _free_floor_fixture(tree, f)
	f = _floor_fixture(tree)
	actor = f.actor
	actor.net_anim_state = "jump"
	for _frame in 4: await tree.physics_frame
	assert_false(actor.is_on_floor(), "an ascending jump remains free between pose updates")
	assert_eq(actor.global_position, f.target)
	await _free_floor_fixture(tree, f)
	for mode: String in ["fly", "carried", "swim", "ride"]:
		f = _floor_fixture(tree)
		actor = f.actor
		match mode:
			"fly": actor.net_flying = true
			"carried": actor.net_carried = true
			"swim": actor.aquatic.mode = REMOTE_TRAINER.SWIM_STATE.Mode.HUMAN
			"ride":
				actor.net_riding = true
				actor.fixture_mount = Node3D.new()
				f.world.add_child(actor.fixture_mount)
				actor.fixture_mount.global_position = f.target
		for _frame in 4: await tree.physics_frame
		assert_false(actor.is_on_floor(), mode + " cannot acquire a LAND snap")
		assert_eq(actor._foundation_ground_contact_generation, 0, mode + " preserves its existing motion bypass")
		await _free_floor_fixture(tree, f)
	return {"assertions": assertion_count, "failures": failures, "completed": true}


func test_native_stationary_remote_floor_contact_preserves_unsupported_and_transport_modes() -> void:
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://remote-floor-" + suffix + ".gd"
	var log_path := ProjectSettings.globalize_path("user://remote-floor-" + suffix + ".log")
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var test: RefCounted = load("res://tests/test_remote_proxy_snap.gd").new()
	var result: Dictionary = await test.call("run_initialized_remote_floor_case", self)
	test = null
	await process_frame
	print("REMOTE_TRAINER_FLOOR_RESULT=" + JSON.stringify(result))
	quit(0 if result.completed == true and result.assertions == 26 and result.failures.is_empty() else 1)
''')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_true(FileAccess.file_exists(log_path), "retain the actual initialized controller log")
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	var result: Dictionary = {}
	var results := 0
	for line: String in "\n".join(output).split("\n"):
		if not line.begins_with("REMOTE_TRAINER_FLOOR_RESULT="): continue
		print(line)
		results += 1
		var parsed: Variant = JSON.parse_string(line.trim_prefix("REMOTE_TRAINER_FLOOR_RESULT="))
		if parsed is Dictionary: result = parsed
	assert_eq(results, 1, combined)
	assert_eq(result.get("assertions", 0), 26, "all eight actual physics scenarios must finish")
	assert_true(result.get("completed") == true)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use") \
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)


func test_a_pinned_body_is_snapped_even_though_its_render_target_is_current() -> void:
	# The regression. The render target is on top of the owner -- interpolation
	# is working perfectly -- but the body is pinned metres away, which is the
	# position the host actually resolves a strike against.
	var owner_at := Vector3(-23.45, 2.23, -22.70)
	var render_at := owner_at
	var pinned_body := owner_at + Vector3(8.86, 0.0, 0.0)
	assert_true(REMOTE_CREATURE.needs_snap(render_at, pinned_body, owner_at, SNAP_M),
		"a body the host's collision has pinned 8.86 m from its owner must be placed, "
		+ "not left behind while its render target reports no error at all")


func test_an_ordinary_interpolating_proxy_is_not_snapped() -> void:
	# The case the snap must stay out of: both the render target and the body
	# are close behind the owner, which is just late packets.
	var owner_at := Vector3(10.0, 1.0, 10.0)
	assert_false(REMOTE_CREATURE.needs_snap(owner_at + Vector3(0.4, 0.0, 0.0),
		owner_at + Vector3(0.9, 0.0, 0.0), owner_at, SNAP_M),
		"ordinary interpolation lag must keep being smoothed rather than teleported")


func test_a_ground_offset_under_the_owner_is_not_a_snap() -> void:
	# A proxy standing on real ground sits a little below the replicated point.
	# That must never read as divergence.
	var owner_at := Vector3(0.0, 3.0, 0.0)
	assert_false(REMOTE_CREATURE.needs_snap(owner_at, owner_at - Vector3(0.0, 1.03, 0.0),
		owner_at, SNAP_M),
		"a metre of ground contact offset is not a pinned body")


func test_a_teleport_still_snaps_on_the_render_target_alone() -> void:
	# The original condition still has to hold: the owner jumped, and the body
	# happens to still be sitting on the render target.
	var owner_at := Vector3(500.0, 4.0, 500.0)
	var stale := Vector3(10.0, 4.0, 10.0)
	assert_true(REMOTE_CREATURE.needs_snap(stale, stale, owner_at, SNAP_M),
		"a teleport must keep snapping, which is what this test guarded before")


func test_the_trainer_proxy_uses_the_same_rule() -> void:
	# `remote_trainer.gd` reads the shared helper rather than restating it, so
	# the trainer and the creature cannot drift apart on this decision.
	var owner_at := Vector3(-330.97, 30.02, 429.29)
	var pinned := owner_at + Vector3(0.0, 0.0, 9.5)
	assert_true(REMOTE_TRAINER.REMOTE_CREATURE.needs_snap(owner_at, pinned, owner_at, SNAP_M),
		"a pinned trainer proxy refuses its peer's legitimate claims from a stale place")
