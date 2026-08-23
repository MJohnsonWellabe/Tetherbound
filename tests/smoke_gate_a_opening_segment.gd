extends SceneTree

## Gate A's production-faithful opening preflight, as one uninterrupted run.
##
## This intentionally does not use the shortcuts in smoke_catching.gd: no
## direct starter adoption, inventory seeding, teleport, HP assignment, or
## camera-yaw assignment. Every player action starts as a physical joypad event
## and travels through the live InputMap. State is read only to know when the
## next visible action is ready and to print useful checkpoint timings.

const OPENING_DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")
const NPC_GATHER_SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const BUILD_SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
const CONTINUOUS_CORE_FLAG := "--gate-a-continuous-core"

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null


func _init() -> void:
	_run()


## The opening itself now lives in `tests/helpers/gate_a_opening_drive.gd`.
##
## It moved on 2026-08-23 so Gate B could PLAY the opening rather than grant it
## -- see that file's header for the measurements that forced it. This file is
## unchanged in what it asserts: the same drive, the same checkpoints, the same
## pass condition. What it no longer is, is the ONLY place that knows how to
## walk the opening.
func _run() -> void:
	var opening: Dictionary = await OPENING_DRIVE.new().run(self)
	for line: Variant in (opening.get("transcript", []) as Array):
		print("GATE A OPENING — %s" % str(line))
	for line: Variant in (opening.get("failures", []) as Array):
		_failures.append(str(line))
	_world = opening.get("world") as Node
	_game = opening.get("game") as Node
	_player = opening.get("player") as CharacterBody3D
	_rig = opening.get("rig") as Node3D

	if _failures.is_empty() and OS.get_cmdline_user_args().has(CONTINUOUS_CORE_FLAG):
		await _run_continuous_core()
	_finish()


## Optional canonical-session continuation. It deliberately shares the
## already-running production world and does not seed state, load another scene,
## or use fixture positioning.
func _run_continuous_core() -> void:
	print("GATE A OPENING — continuous core: village, material, and paid-build segments")
	var npc_failures: Array[String] = await NPC_GATHER_SEGMENT.new().run(
		self, _world, _game, _player, _rig)
	if not npc_failures.is_empty():
		for failure: String in npc_failures:
			_failures.append("NPC/gather continuation: %s" % failure)
		return
	var route: Dictionary = await MATERIAL_ROUTE.new().run(self, _world, _game, _player, _rig)
	if not bool(route.get("passed", false)):
		for failure: Variant in (route.get("failures", []) as Array):
			_failures.append("material route: %s" % str(failure))
		return
	var built: Dictionary = await BUILD_SEGMENT.new().run(self, _world, _player, _rig)
	if not bool(built.get("passed", false)):
		for failure: Variant in (built.get("failures", []) as Array):
			_failures.append("paid build: %s" % str(failure))


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("gate A opening segment: OK — title through natural catch passed continuously with parsed controller input")
		quit(0)
		return
	for line: String in _failures:
		print("gate A opening segment FAIL: %s" % line)
	quit(1)
