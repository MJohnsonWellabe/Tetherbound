extends SceneTree

## OWNER-0901-PLAYER-SLEEP-V2. `tests/smoke_gate_b_continuous.gd` is the one
## test meant to prove wake -> catch -> village tools -> gather -> build ->
## sleep as a single continuous fresh-save run, but a separate, pre-existing
## navigation defect in its Oskar/Bram commerce visits (unrelated to sleep --
## see the Bram-exit finding in ralph/reports/OWNER-0901-PLAYER-SLEEP-V2.md)
## currently keeps it from ever reaching the build/sleep segment at all.
##
## This composes the same real, already-proven production helpers that test
## uses -- in the same order `tests/smoke_gate_a_opening_segment.gd`'s own
## `--gate-a-continuous-core` flag already establishes as a tested pipeline
## (opening drive -> NPC/gather -> material route) -- but skips the two
## commerce-only NPCs (`gate_a_npc_gather_segment.gd`'s new `include_vendors`
## parameter) and continues straight into a REAL Build-menu selection and
## placement of the Bedroll specifically (`gate_a_build_segment.gd`'s own
## controller-navigation primitives, not its house sequence), then a real
## walk-up-and-interact on the placed piece's own "Rest until morning" prompt.
##
## No teleport, no seeded inventory, no `pending_build` shortcut, no direct
## call into `night_rest.gd`/`player_bed.gd` -- every state change here is a
## real dialogue effect, a real swing at a real harvest node, a real
## controller press on a real UI cell, or a real Interactable activation,
## exactly the class of evidence this project's own conventions require.
##
##   godot --headless --path . --script tools/_probe_sleep_chain_e2e.gd

const OPENING_DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")
const NPC_GATHER_SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const BUILD_SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _run() -> void:
	var opening: Dictionary = await OPENING_DRIVE.new().run(self)
	for line: Variant in (opening.get("failures", []) as Array):
		_fail("opening: %s" % str(line))
	if not _failures.is_empty():
		_finish()
		return
	var world: Node = opening.get("world") as Node
	var game: Node = opening.get("game") as Node
	var player: CharacterBody3D = opening.get("player") as CharacterBody3D
	var rig: Node3D = opening.get("rig") as Node3D
	print("[e2e] real opening complete (wake -> Grandpa -> starter -> natural catch); player at %s"
		% str(player.global_position.round()))

	var npc_failures: Array[String] = await NPC_GATHER_SEGMENT.new().run(
		self, world, game, player, rig, false)
	for line: String in npc_failures:
		_fail("npc/gather: %s" % line)
	if not _failures.is_empty():
		_finish()
		return
	print("[e2e] real village visits complete: Mira (axe/pickaxe/recipe), Tam (knife/torch), "
		+ "the Foreman (hammer), tools assigned, real swings gathered wood/stone/fiber")

	var route: Dictionary = await MATERIAL_ROUTE.new().run(self, world, game, player, rig)
	if not bool(route.get("passed", false)):
		for line: Variant in (route.get("failures", []) as Array):
			_fail("material route: %s" % str(line))
		_finish()
		return
	var inventory: RefCounted = game.get("inventory")
	var wood := int(inventory.call("count", "wood"))
	var fiber := int(inventory.call("count", "fiber"))
	print("[e2e] real authored material route complete: %d wood, %d fiber in the Satchel "
		% [wood, fiber] + "(the Bedroll costs 4 wood / 6 fiber)")
	if wood < 4 or fiber < 6:
		_fail("real gathering left %d wood / %d fiber, short of the Bedroll's 4/6 cost" % [wood, fiber])
		_finish()
		return

	var builder = BUILD_SEGMENT.new()
	builder._tree = self
	builder._game = game
	builder._world = world
	builder._player = player
	builder._camera_rig = rig
	builder._resolve_move_bindings()
	if not builder.failures.is_empty():
		for line: String in builder.failures:
			_fail("build wiring: %s" % line)
		_finish()
		return

	if not await builder._select_piece("bedroll"):
		for line: String in builder.failures:
			_fail("select Bedroll through the real catalogue: %s" % line)
		_finish()
		return
	print("[e2e] real Build catalogue opened (hammer in hand, controller press) and "
		+ "Bedroll selected by controller navigation, same as a player choosing it from the grid")

	var forward: Vector3 = -(rig.call("planar_basis") as Basis).z
	var spot: Vector3 = player.global_position + forward * 4.0
	if not await builder._move_ghost_to(spot):
		for line: String in builder.failures:
			_fail("aim the Bedroll ghost: %s" % line)
		_finish()
		return
	var placed_at: Variant = await builder._place_current("bedroll")
	if placed_at == null:
		for line: String in builder.failures:
			_fail("place the Bedroll: %s" % line)
		_finish()
		return
	print("[e2e] real Bedroll placed through the catalogue+placer at %s" % str(placed_at))

	var bedroll_node: Node3D = null
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == "bedroll":
			bedroll_node = node as Node3D
	if bedroll_node == null:
		_fail("placed a Bedroll but no placed_building node carries id 'bedroll'")
		_finish()
		return
	var prompt := bedroll_node.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("the placed Bedroll carries no 'Rest until morning' prompt")
		_finish()
		return

	if builder._nav == null:
		_fail("no navigator survived placement to walk the player to the Bedroll")
		_finish()
		return
	var arrived: bool = await builder._nav.walk_to(prompt.global_position, 900, 1.4)
	builder._release_move_stick()
	if not arrived:
		_fail("controller could not walk from the placed Bedroll's ghost stance to its own prompt "
			+ "(stopped %.1fm short)" % player.global_position.distance_to(prompt.global_position))
		_finish()
		return

	var arbiter: Node = get_first_node_in_group(&"interaction_arbiter")
	var offered := ""
	for _i in 30:
		if arbiter != null and arbiter.call("winning_provider") == prompt:
			offered = str(arbiter.call("prompt"))
			break
		await physics_frame
	if not offered.contains("Rest"):
		_fail("standing at the placed Bedroll, the game offers '%s', not the Rest prompt" % offered)
		_finish()
		return
	print("[e2e] standing at the real, controller-placed Bedroll, the game offers '%s'" % offered)

	var progression: RefCounted = game.get("progression")
	progression.call("set_flag", "player_slept_at_home", false)
	var day_before := int(game.get("day"))
	await builder._tap_action(&"interact")
	for _i in 150:
		await physics_frame
	var day_after := int(game.get("day"))
	if day_after <= day_before:
		_fail("pressing interact at the real placed Bedroll did not advance the day (%d -> %d)"
			% [day_before, day_after])
	else:
		print("[e2e] pressed interact at the real placed Bedroll: day %d -> %d" % [day_before, day_after])
	if not bool(progression.call("has", "player_slept_at_home")):
		_fail("sleeping at the real placed Bedroll did not clear the objective ladder's rest rung")
	else:
		print("[e2e] 'Rest at camp and let a creature recover' objective flag is now set")

	_finish()


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("SLEEP CHAIN E2E: PASS — a genuinely fresh save reached and used the real Bedroll "
			+ "sleep prompt with no seeded inventory, no teleport, and no gameplay shortcut anywhere "
			+ "in the chain.")
		quit(0)
		return
	print("SLEEP CHAIN E2E: FAIL")
	for line: String in _failures:
		print("  FAIL: %s" % line)
	quit(1)
