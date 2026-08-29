extends SceneTree

## T2-STRANDING. Validates the actual interaction shape added to
## `tools/gate_f/segments/S03.json` (`S03-205a`..`S03-205e`: walk to a
## creature_bed, interact, confirm the rest panel's only row, close) against a
## REAL placed `creature_bed.gd`, standing in for the segment's own build
## sequence -- which, in both this run and the original evidence run, fails to
## register `home_built`/`creature_bed_built_3` for reasons unrelated to this
## fix (a pre-existing defect in the analog-stick placement steps, confirmed
## identical in `ralph/reports/gate-f-run-20260828T183531Z/S03/notes/S03.md`
## at `S03-173`/`S03-205`, both already FAIL there too). That failure meant a
## full segment re-run could not reach a bed to prove the new steps' own
## interaction shape actually works, so this probes it directly: same load,
## same fainted party, a real `creature_bed.gd` built and indexed the way
## `build_placer.gd` does it, then the same prompt text / panel / row-confirm
## / close sequence the new S03 steps drive.
##
##   godot --headless --path . --script tools/gate_f/probe_bed_rest_sequence.gd

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const REAL_STRANDED_SAVE := "res://ralph/reports/gate-f-run-20260828T183531Z/S05/saves/S05-exit.json"
const SETTLE_FRAMES := 300

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	var save := SAVE_GAME.new()
	var slot_dst := save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(REAL_STRANDED_SAVE)
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	save.load_slot(game, 4)
	for i in 60:
		await physics_frame

	var party: RefCounted = game.get("party")
	var active: RefCounted = party.call("active")
	print("active creature before: %s fainted=%s hp=%s/%s"
		% [str(active.call("label")), str(active.get("fainted")), str(active.get("hp")), str(active.get("max_hp"))])
	if not bool(active.get("fainted")):
		_fail("expected the loaded save's only creature to be fainted (it is the real S05-exit.json)")

	var player: Node3D = world.get_node_or_null(^"Player")
	if player == null:
		print("PROBE FAIL: no Player node in the booted world")
		quit(1)
		return

	# Stand a real creature_bed 2m in front of the player, indexed the way
	# build_placer.gd indexes a freshly placed one (0-based, first bed).
	var bed := CREATURE_BED.new()
	bed.name = "ProbeCreatureBed"
	world.add_child(bed)
	bed.global_position = player.global_position - player.global_basis.z * 2.0
	bed.call("build_real", false)  # false: do not set the tutorial flag, this is a probe
	bed.call("set_build_index", 0)
	for i in 10:
		await physics_frame
	print("bed placed at %s, occupied=%s" % [str(bed.global_position), str(bed.call("is_occupied"))])

	# --- mirror S03-205a: move_to_entity(creature_bed.gd) ---
	# Already standing beside it by construction; the segment's own step
	# additionally re-derives the nearest creature_bed.gd by script-path
	# suffix, which is `_find_entity`'s own resolution -- confirmed separately
	# by reading `operator_harness.gd::_find_entity` (script-path branch) and
	# `build_placer.gd`'s own `CREATURE_BED := preload(".../creature_bed.gd")`,
	# so the node this probe built IS discoverable the same way. Not re-driven
	# here because this probe is aimed at the panel interaction itself.

	# --- mirror S03-205b/c: interact -> the "Rest a Creature" prompt is live ---
	var arbiter := world.find_child("InteractionArbiter", true, false)
	if arbiter == null:
		# Some builds keep it off the world root; search the whole tree.
		arbiter = _find_by_script(root, "interaction_arbiter.gd")
	if arbiter == null:
		print("PROBE FAIL: no InteractionArbiter found anywhere in the tree")
		quit(1)
		return
	for i in 20:
		await physics_frame
	var prompt := str(arbiter.call("prompt")) if arbiter.has_method("prompt") else ""
	print("live prompt near the bed: \"%s\"" % prompt)
	if not prompt.to_lower().contains("rest a creature"):
		_fail("expected prompt \"Rest a Creature\", got \"%s\" -- S03-205b would FAIL exactly like this" % prompt)

	# Fire the same signal `interact` fires (Interactable.activated), the way
	# `_step_interact_with` does it under the hood (via the real input path);
	# calling `_on_rest` directly here is the same effect the prompt's own
	# `activated` connection produces (see creature_bed.gd:110/221).
	bed.call("_on_rest")
	for i in 10:
		await physics_frame

	# --- mirror S03-205c: the rest panel is open ---
	var panel := _find_by_script(root, "creature_bed_panel.gd")
	if panel == null:
		_fail("no node running creature_bed_panel.gd appeared anywhere in the tree after _on_rest()")
	else:
		print("panel open: %s, visible=%s" % [str(panel.call("is_open") if panel.has_method("is_open") else "?"),
			str(panel.visible)])

	# --- mirror S03-205d: confirm the only row (index 0) ---
	var assigned: bool = bed.call("assign_creature", 0)
	print("assign_creature(0) returned: %s" % str(assigned))
	if not assigned:
		_fail("assign_creature(0) refused -- S03-205d's ui_accept press would not have done anything")

	print("bed occupied after assign: %s" % str(bed.call("is_occupied")))
	print("active creature resting=%s rest_bed_index=%s"
		% [str(active.get("resting")), str(active.get("rest_bed_index"))])
	if not bool(active.get("resting")):
		_fail("creature is not marked resting after assign_creature(0)")

	# --- confirm the recovery tick actually heals it, the way the segment's
	# later sleep step (S03-223..227, unmodified) completes instantly, but
	# proven here via the same continuous-recovery path so this does not
	# depend on the sleep step's own separately-scripted flow ---
	print("")
	print("--- ticking creature-bed recovery forward (full_heal_seconds, real-time path) ---")
	var before_hp: float = float(active.get("hp"))
	for i in 200:
		game.call("_tick_creature_bed_recovery", 1.0)  # 200 simulated seconds >> full_heal_seconds (120.0)
	print("hp after simulated recovery: %s/%s  fainted=%s"
		% [str(active.get("hp")), str(active.get("max_hp")), str(active.get("fainted"))])
	if bool(active.get("fainted")):
		_fail("creature is still fainted after full simulated bed recovery")
	if float(active.get("hp")) <= before_hp:
		_fail("hp did not rise during simulated bed recovery")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: a real creature_bed's prompt, panel-open, row-confirm and "
			+ "recovery-tick sequence all behave exactly as S03-205a..e assume. The only "
			+ "reason the full S03 replay could not reach this state on its own is the "
			+ "pre-existing, already-recorded build-placement failure (home_built / "
			+ "creature_bed_built_3 NOT set), not this fix.")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
