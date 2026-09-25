extends SceneTree

## X03 / F05 heal: a story payoff (a member of `presentation_hold.gd`'s GROUP)
## holds the world HUD's teaching lines and the objective beam, and both come
## back the frame the hold ends. Real PlaygroundHUD scene, real interaction
## arbiter prompt, real objective beacon resolving the real objectives.json
## chain over a flat stand-in world; no Meadows terrain build.
##
##   godot --headless --path . --script tests/smoke_presentation_hold.gd

const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")
const OBJECTIVE_BEACON := preload("res://scripts/world/objective_beacon.gd")
const PRESENTATION_HOLD := preload("res://scripts/ui/presentation_hold.gd")

var _failures: Array[String] = []


class _TalkProvider:
	func interaction_offer(_from: Vector3) -> Dictionary:
		return {"label": "Call out Terrapup", "distance": 1.0, "priority": 5, "actionable": true}
	func interaction_activate() -> void:
		pass


## Flat ground for the beacon, which asks its parents for `ground_height_at`.
class _FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_report()
		return
	var world := _FlatWorld.new()
	world.name = "HoldWorld"
	root.add_child(world)
	current_scene = world
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var arbiter: Node = ARBITER_SCRIPT.new()
	arbiter.name = "InteractionArbiter"
	arbiter.set("player_path", NodePath("../Player"))
	world.add_child(arbiter)
	var hud := HUD_SCENE.instantiate() as CanvasLayer
	world.add_child(hud)
	var beacon: Node3D = OBJECTIVE_BEACON.new()
	beacon.set("realm_id", str(game.get("current_realm")))
	world.add_child(beacon)
	arbiter.call("register", _TalkProvider.new())
	for i in 10:
		await process_frame

	var prompt := hud.get("_prompt_label") as Control
	_check(not PRESENTATION_HOLD.active(self), "no hold with an empty group")
	_check(prompt != null and prompt.visible, "the teaching prompt shows with no hold")
	beacon.call("refresh_now")
	await process_frame
	_check(bool(beacon.call("beam_visible")), "the objective beam shows with no hold (target '%s')" % beacon.call("active_objective_id"))

	# A hint revealed just before the payoff: visible now, held during, and
	# still shown after (its countdown pauses for the hold).
	hud.call("_reveal_objective_hint", "Five is the whole team and always was.")
	await process_frame
	var hint := hud.get("_objective_hint_card") as Control
	_check(hint != null and hint.visible, "the objective hint card shows with no hold")
	var map_state: RefCounted = game.get("map") as RefCounted
	var marker_before := _marker(map_state)

	var payoff := Node.new()
	payoff.name = "HealPayoff"
	world.add_child(payoff)
	payoff.add_to_group(PRESENTATION_HOLD.GROUP)
	for i in 3:
		await process_frame
	_check(PRESENTATION_HOLD.active(self), "a group member is a hold")
	_check(not prompt.visible, "the teaching prompt stands down during the payoff")
	_check(not hint.visible, "the objective hint card stands down during the payoff")
	# Longer than the hint's own hold would last unpaused.
	await create_timer(float(hud.get("OBJECTIVE_HINT_SECONDS_BASE")) + 3.0).timeout
	_check(not hint.visible, "and stays down for the whole payoff")
	_check(_marker(map_state) == marker_before and not marker_before.is_empty(),
		"the objective map marker is untouched by the hold")
	_check(not bool(beacon.call("beam_visible")), "the objective beam stands down during the payoff")
	_check(not str(beacon.call("active_objective_id")).is_empty(), "the objective itself is untouched by the hold")

	payoff.queue_free()
	for i in 3:
		await process_frame
	_check(not PRESENTATION_HOLD.active(self), "a freed member releases the hold")
	_check(prompt.visible, "the teaching prompt returns when the payoff ends")
	_check(hint.visible, "the held hint card is shown again after the payoff, its time paused")
	_check(bool(beacon.call("beam_visible")), "the objective beam returns when the payoff ends")
	_report()


func _marker(map_state: RefCounted) -> Dictionary:
	if map_state == null:
		return {}
	var all: Variant = map_state.get("_dynamic")
	return (all as Dictionary).get("objective", {}) if all is Dictionary else {}


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		_failures.append(what)


func _fail(what: String) -> void:
	_failures.append(what)


func _report() -> void:
	if _failures.is_empty():
		print("presentation hold smoke: PASS")
		quit(0)
	else:
		print("presentation hold smoke: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - " + f)
		quit(1)
