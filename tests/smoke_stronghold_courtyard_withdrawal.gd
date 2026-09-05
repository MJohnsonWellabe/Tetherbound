extends SceneTree

## N05-WORLD-DRESSING-0905 (W06-FINALE-0904's routed finding). Three blind
## judges read the Hall's courtyard "stood down" frames and one of them named
## it: "the same NPC stands in exactly the same spot, in the same pose, in both
## frames". That NPC is the courtyard gauntlet trainer, Warder Solene.
##
##   godot --headless --path . --script tests/smoke_stronghold_courtyard_withdrawal.gd
##
## What is actually supposed to happen is spec sec9 / `meadow_healing.gd`: when
## `legendary_freed` is set, every Team Tether trainer the player has ALREADY
## BEATEN is withdrawn, and `data/config/meadow_healing.json`'s `patrols.withdraw`
## list already names `stronghold_courtyard`. W06's capture never set her
## defeat flag (it only set the elite's and the Warden's, then pulled the
## lever), so she was unbeaten and, by sec9's own rule, stayed. This test is
## the check W06's frame could not be: it boots the real world, finds Solene
## standing on her courtyard mark, beats her by flag, kills the machinery by
## flag, and asserts that the Meadows' answer takes her off the courtyard --
## while the two gauntlet trainers who were NOT beaten stay exactly where they
## are, because "already beaten stay beaten" is a rule about the flags and
## sec9 never deletes a fight the player has not taken.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const SETTLE_FRAMES := 240
const HEAL_FRAMES := 600
const FREED_FLAG := "legendary_freed"
const GAUNTLET := ["stronghold_patrol", "stronghold_courtyard", "stronghold_elite"]

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	var healing: Node = world.get_node_or_null(^"MeadowHealing")
	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if hold == null or healing == null or progression == null:
		print("courtyard withdrawal FAIL: no Stronghold (%s), MeadowHealing (%s) or progression (%s)" % [
			str(hold != null), str(healing != null), str(progression != null)])
		quit(1)
		return
	if bool(healing.call("applied")):
		print("courtyard withdrawal FAIL: the Meadows had already answered before the test began ('%s' was set on boot)" % FREED_FLAG)
		quit(1)
		return

	# 1. All three gauntlet trainers stand, each on their own mark.
	var bodies := {}
	for id: String in GAUNTLET:
		var spec: Dictionary = TRAINERS.trainer(id)
		var body: Node = world.find_child(str(spec.get("name", "")), true, false)
		var mark: Vector3 = hold.call("marker", "trainer_%s" % id)
		if body == null or not body is Node3D:
			_fail("gauntlet trainer '%s' (%s) is not standing in the world" % [id, str(spec.get("name", ""))])
			continue
		var off := Vector2((body as Node3D).global_position.x - mark.x, (body as Node3D).global_position.z - mark.z).length()
		if off > 1.5:
			_fail("'%s' stands %.1f m off the mark the stronghold placed for them" % [id, off])
		bodies[id] = body
		print("%s stands at %s (%.2f m off mark)" % [str(spec.get("name", "")), str((body as Node3D).global_position), off])
	if not _failures.is_empty():
		_finish()
		return

	# 2. Only the courtyard fight has been won. Then the machinery dies.
	var courtyard_flag := str((TRAINERS.trainer("stronghold_courtyard") as Dictionary).get("defeat_flag", ""))
	for id: String in GAUNTLET:
		var flag := str((TRAINERS.trainer(id) as Dictionary).get("defeat_flag", ""))
		progression.call("set_flag", flag, id == "stronghold_courtyard")
	progression.call("set_flag", FREED_FLAG)
	var waited := 0
	while not bool(healing.call("applied")) and waited < HEAL_FRAMES:
		await physics_frame
		waited += 1
	if not bool(healing.call("applied")):
		_fail("'%s' was set and the Meadows never answered within %d frames" % [FREED_FLAG, HEAL_FRAMES])
		_finish()
		return
	for i in 10:
		await physics_frame
	var report: Dictionary = healing.call("report")
	print("the Meadows answered after %d frames: %s" % [waited, str(report)])

	# 3. Solene is gone from the courtyard; nobody unbeaten moved.
	for id: String in GAUNTLET:
		# Untyped on purpose: a withdrawn body has been freed, and assigning a
		# freed instance to a `Node`-typed variable is itself a script error.
		var body: Variant = bodies[id]
		var gone := not is_instance_valid(body) or (body as Node).is_queued_for_deletion() \
			or not (body as Node).is_inside_tree()
		if id == "stronghold_courtyard":
			if not gone:
				_fail("the courtyard trainer was beaten (%s) and the machinery died (%s), and Warder Solene is still standing on her mark at %s" % [
					courtyard_flag, FREED_FLAG, str((body as Node3D).global_position)])
			else:
				print("Warder Solene has withdrawn from the courtyard")
		elif gone:
			_fail("'%s' was never beaten and was withdrawn anyway; sec9 deletes no fight the player has not taken" % id)
	if int(report.get("patrols_withdrawn", 0)) < 1:
		_fail("meadow_healing reports %d patrols withdrawn; the courtyard should be one" % int(report.get("patrols_withdrawn", 0)))
	# The flags themselves are untouched by the withdrawal.
	if not bool(progression.call("has", courtyard_flag)):
		_fail("the withdrawal cleared '%s'; beaten trainers stay beaten" % courtyard_flag)
	_finish()


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("stronghold courtyard withdrawal smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
