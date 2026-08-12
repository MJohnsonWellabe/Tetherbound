extends SceneTree

## `EV9-double-prompt`: `combat_hud.gd`'s prompt row used to mirror whatever
## `PlaygroundHUD` was showing, not just an engage offer -- reproduced on
## `main` by standing next to the bed in the opening and seeing "Get up" on
## both HUDs stacked on screen at once.
##
##   godot --headless --path . --script tests/smoke_no_double_prompt.gd
##
## Two things checked directly on the nodes rather than from a screenshot,
## because the defect is exactly "two labels agree" and a render proves that
## happened without proving the fix generalises:
##
##   1. Standing at an interactable that has nothing to do with combat (the
##      bed) — the arbiter's line is genuine, `CombatHUD`'s prompt row must
##      stay blank.
##   2. Standing at the wild pal `encounter_director.gd` itself offers to
##      fight — the row is meant to keep showing "Engage X" before the fight
##      starts (`combat_hud.gd`'s own `_show_fight` comment), so the fix must
##      not have gone too far and blanked that too.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const COMBAT_HUD_SCRIPT := "res://scripts/ui/combat_hud.gd"
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"

const SETTLE_FRAMES := 300
const WALK_FRAMES := 1200

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _arbiter: Node = null
var _encounter: Node = null
var _combat_hud: CanvasLayer = null
var _combat_prompt: RichTextLabel = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	await _standing_at_an_unrelated_interactable_does_not_double_up()
	await _standing_at_a_wild_pal_still_shows_engage()
	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	_encounter = _find_by_script(root, "res://scripts/combat/encounter_director.gd")
	_combat_hud = _find_by_script(root, COMBAT_HUD_SCRIPT) as CanvasLayer
	if _player == null or _rig == null:
		_fail("no Player or CameraRig; this is not the meadows playground")
		return false
	if _arbiter == null:
		_fail("no interaction arbiter in the scene")
		return false
	if _encounter == null:
		_fail("no encounter director in the scene")
		return false
	if _combat_hud == null:
		_fail("no CombatHUD in the scene")
		return false
	_combat_prompt = _combat_hud.get_node_or_null(^"Root/Prompt") as RichTextLabel
	if _combat_prompt == null:
		_fail("CombatHUD has no Root/Prompt node; the scene structure moved")
		return false
	return true


## Reproduces the reported case directly: the bed is not `encounter_director`,
## so its "Get up" line winning the shared arbiter must not also appear on
## the combat layer.
func _standing_at_an_unrelated_interactable_does_not_double_up() -> void:
	var bed := _find_interactable_matching(["get up"])
	if bed == null:
		_fail("nothing offers a 'Get up' prompt; cannot reproduce the reported case")
		return

	if not await _walk_until_winning(bed):
		return

	var arbiter_line := str(_arbiter.call("prompt"))
	if arbiter_line.is_empty():
		_fail("standing at the bed and the interact prompt is blank")
		return

	for i in 5:
		await physics_frame
	if not _combat_prompt.text.is_empty():
		_fail(
			"CombatHUD's prompt row shows '%s' while standing at an unrelated interactable (the bed); it should be blank"
			% _combat_prompt.text
		)
		return
	print("bed: arbiter shows '%s', CombatHUD's row stays blank" % arbiter_line)


## The row still has a job: `combat_hud.gd`'s own comment says it exists to
## keep showing "Engage X" before a fight starts. A fix that blanks
## everything outside a fight, not just other providers' offers, would pass
## the case above and still be wrong.
func _standing_at_a_wild_pal_still_shows_engage() -> void:
	# No ally means `encounter_director._engageable()` never offers anything
	# to begin with, same bypass `smoke_catching.gd`'s `_ensure_ally()` uses:
	# this test is not the opening and never drives it.
	if _encounter.call("ally_instance") == null:
		await _encounter.call("adopt_starter", "terrapup")
		for i in 20:
			await physics_frame

	var wild: Node3D = _encounter.call("wild_pal")
	if wild == null:
		_fail("no wild pal in the sandbox; cannot check the engage case")
		return

	# Teleported near the wild pal's own actual position rather than a guessed
	# cluster coordinate — same reason `smoke_catching.gd`'s
	# `_leave_the_farmhouse` teleports at all: the bed the first check left
	# the player standing at is nowhere near the wild pals, and walking the
	# whole distance is not the point of this check. 8m out, not closer:
	# within a few metres trips the "spawned on top of the creature" tripwire.
	var start := wild.global_position + Vector3(8.0, 0.0, 0.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame

	# The registered provider is `encounter_director` itself, answering for
	# whichever wild pal is nearest — not the pal body — same as
	# `interaction_arbiter.gd`'s own header explains.
	if not await _walk_until_winning(wild, _encounter):
		return

	for i in 5:
		await physics_frame
	if _combat_prompt.text.is_empty():
		_fail("standing at a wild pal encounter_director itself offers to fight, and CombatHUD's row is blank")
		return
	print("wild pal: CombatHUD's row shows '%s' before the fight starts" % _combat_prompt.text)


## Shared by both cases above: walk until the target is the arbiter's actual
## winner, not just until close, the same reason `smoke_opening.gd`'s
## `_walk_to_and_activate` does — two providers can overlap in range.
## `provider` defaults to `target`: true for an interactable, which registers
## itself; not true for a wild pal, whose provider is `encounter_director`.
func _walk_until_winning(target: Node3D, provider: Object = null) -> bool:
	if provider == null:
		provider = target
	for i in WALK_FRAMES:
		var to := target.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= 2.0 and _arbiter.call("winning_provider") == provider:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame

	if _arbiter.call("winning_provider") != provider:
		_fail("could not get '%s' to win the arbiter by walking to it" % target.name)
		return false
	return true


## Same pattern `smoke_opening.gd` already uses: filter by script rather than
## by node path or group, so a rename does not read as "the prompt is gone".
func _find_interactable_matching(words: Array) -> Node3D:
	for candidate in _all_interactables(_world):
		if not bool(candidate.get("enabled")):
			continue
		var label := str(candidate.get("label")).to_lower()
		for word in words:
			if label.contains(str(word)):
				return candidate
	return null


func _all_interactables(node: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == INTERACTABLE_SCRIPT and node is Node3D:
		out.append(node as Node3D)
	for child in node.get_children():
		out.append_array(_all_interactables(child))
	return out


func _find_by_script(node: Node, path: String) -> Node:
	if node.get_script() != null and (node.get_script() as Script).resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("no double prompt: OK — CombatHUD only shows its own offers.")
		quit(0)
		return
	for line in _failures:
		print("no double prompt FAIL: %s" % line)
	quit(1)
