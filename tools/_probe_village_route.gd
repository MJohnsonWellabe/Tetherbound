extends SceneTree

## GATEB-PATH probe. The village-visit segment ONLY, so the pathing fix can be
## iterated in minutes instead of re-running the whole Gate B continuous smoke.
##
##   godot --headless --path . --script tools/_probe_village_route.gd
##
## Plays the real opening drive (which is what leaves the player standing where
## the game actually leaves them) and then the real NPC/gather segment. Nothing
## is granted and nothing is stubbed: this is exactly the pair
## `smoke_gate_b_continuous.gd` runs before the material route.

const OPENING_DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")
const NPC_GATHER := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")

var _started_ms := 0


func _init() -> void:
	_run()


func _run() -> void:
	_started_ms = Time.get_ticks_msec()
	var opening: Dictionary = await OPENING_DRIVE.new().run(self)
	for line: Variant in (opening.get("transcript", []) as Array):
		print("PROBE opening | %s" % str(line))
	if not bool(opening.get("passed", false)):
		for line: Variant in (opening.get("failures", []) as Array):
			print("PROBE FAIL opening: %s" % str(line))
		_finish(false)
		return
	var world := opening.get("world") as Node
	var game := opening.get("game") as Node
	var player := opening.get("player") as CharacterBody3D
	var rig := opening.get("rig") as Node3D
	print("PROBE +%.1fs opening done; player at %s" % [
		(Time.get_ticks_msec() - _started_ms) / 1000.0, str(player.global_position.round())])

	var village: Array = await NPC_GATHER.new().run(self, world, game, player, rig)
	for line: Variant in village:
		print("PROBE FAIL village: %s" % str(line))
	if not village.is_empty():
		_finish(false)
		return
	print("PROBE +%.1fs village done" % [(Time.get_ticks_msec() - _started_ms) / 1000.0])
	if not "--with-gather" in OS.get_cmdline_user_args():
		_finish(true)
		return

	var gathered: Dictionary = await MATERIAL_ROUTE.new().run(self, world, game, player, rig)
	for line: Variant in (gathered.get("transcript", []) as Array):
		print("PROBE gather | %s" % str(line))
	for line: Variant in (gathered.get("failures", []) as Array):
		print("PROBE FAIL gather: %s" % str(line))
	_finish(bool(gathered.get("passed", false)))


func _finish(passed: bool) -> void:
	print("PROBE %s in %.1fs" % ["PASS" if passed else "FAIL",
		(Time.get_ticks_msec() - _started_ms) / 1000.0])
	quit(0 if passed else 1)
