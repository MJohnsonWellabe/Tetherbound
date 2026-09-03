extends RefCounted

## Canonical paid-build material route for Gate A's one continuous session.
##
## This section does not create stock, move the trainer by transform, or call a
## gather/private implementation method. It walks with parsed controller input,
## equips the tools Tam gave through the Satchel, swings at visible live nodes,
## and picks up the downed result the production harvest path creates.
##
## The authored Band-1 route supplies 16 wood, 9 stone, and (after the fiber
## supply branch lands) 20 fiber. The paid 2x2 house + camp + creature bed
## requires 57 wood, 42 stone, and 18 fiber, so the route deliberately expands
## to the nearest live, deterministic harvest-all trees/rocks for the exact
## 41 wood / 33 stone authored shortfall. Runtime selection is intentional:
## scatter locations are deterministic for a candidate SHA, but not source
## constants, and selecting the live public resource nodes proves the actual
## loaded Meadow has the claimed economy.

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const HARVEST_NODE_PATH := "res://scripts/world/harvest_node.gd"
const VEGETATION_POINT_PATH := "res://scripts/world/vegetation_harvest_point.gd"
const FELLED_RESOURCE_PATH := "res://scripts/world/felled_resource.gd"
## What the first day has to come home with.
##
## OWNER DIRECTIVE 2026-08-23 §1, "three creature beds before the tournament":
## house 39 wood / 34 stone (the twelve-piece sequence
## `gate_a_build_segment.gd` raises), THREE creature beds at 6 wood / 8 fiber
## each, and the camp at 12 wood / 8 stone / 10 fiber
## (`data/items/buildables.json`). 69 / 42 / 34.
##
## It used to be 57 / 42 / 18, which bought exactly ONE bed -- and
## `tournament.gd::condition_ready()` wants the `min_party_size` strongest
## entrants RESTED while `creature_bed.gd` holds exactly one occupant, so one
## bed meant three consecutive nights to field a team. The extra wood and
## fiber are authored NEAR THE VILLAGE (`data/config/bands/
## band1_lower_meadows/harvest.json`, orders 1020-1027) rather than found
## further out, because the directive is about what the first day's own loop
## can pay for.
const TARGET_STOCK := {"wood": 69, "stone": 42, "fiber": 34}
const TOOL_ID := {"wood": "axe", "stone": "pickaxe", "fiber": "knife"}
const AUTHORED_ROUTE: Array[Dictionary] = [
	{"item": "wood", "amount": 4, "at": Vector2(16.0, -28.0)},
	{"item": "wood", "amount": 4, "at": Vector2(26.0, -44.0)},
	{"item": "wood", "amount": 4, "at": Vector2(44.0, -24.0)},
	{"item": "wood", "amount": 4, "at": Vector2(-8.0, 8.0)},
	# The three-bed raise (owner directive 2026-08-23 §1), authored at
	# `band1_lower_meadows/harvest.json` orders 1020-1027 and walked here.
	{"item": "wood", "amount": 4, "at": Vector2(6.0, -34.0)},
	{"item": "wood", "amount": 4, "at": Vector2(36.0, -16.0)},
	{"item": "wood", "amount": 4, "at": Vector2(-14.0, -8.0)},
	{"item": "stone", "amount": 3, "at": Vector2(22.0, -34.0)},
	{"item": "stone", "amount": 3, "at": Vector2(52.0, -30.0)},
	{"item": "stone", "amount": 3, "at": Vector2(-18.0, 6.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(12.0, -22.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(34.0, -46.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(-2.0, -20.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(24.0, -24.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(46.0, -40.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(2.0, -30.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(-10.0, -14.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(30.0, -8.0)},
	# The two Gate-A fiber stops are deliberately on ordinary open-spine travel.
	{"item": "fiber", "amount": 4, "at": Vector2(-5.0, 141.0)},
	{"item": "fiber", "amount": 4, "at": Vector2(-168.0, 312.0)},
]

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _arbiter: Node
var _move_x_axis: JoyAxis = JOY_AXIS_LEFT_X
var _move_y_axis: JoyAxis = JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0
## Travel. See `stick_navigator.gd`: this route crosses the whole Meadow and a
## straight stick vector walks into the first tree, rock or wall on the bearing.
var _nav = null  # stick_navigator.gd; untyped so its methods read as methods


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		camera_rig: Node3D) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = camera_rig
	if _tree == null or _world == null or _game == null or _player == null or _rig == null:
		_fail("material route dependencies are incomplete")
		return _result()
	_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter")
	if _arbiter == null:
		_fail("material route could not find the production interaction arbiter")
		return _result()
	if not _resolve_move_bindings():
		return _result()
	_nav = NAVIGATOR.new(_tree, _player, _rig, _send_stick)
	if not _verify_tool_hotbar():
		return _result()
	transcript.append("starting natural paid-build route with %s" % _stock_snapshot())

	if not await _unlock_road_gate():
		return _result()
	for stop in AUTHORED_ROUTE:
		if not await _harvest_authored_stop(stop):
			return _result()
	if not await _fill_with_live_scatter("wood"):
		return _result()
	if not await _fill_with_live_scatter("stone"):
		return _result()
	if not _stock_is_sufficient():
		_fail("natural harvest route ended below paid-house/rest target: %s" % _stock_snapshot())
	else:
		transcript.append("natural material invariant met: %s (need wood %d, stone %d, fiber %d)" % [
			_stock_snapshot(), int(TARGET_STOCK["wood"]), int(TARGET_STOCK["stone"]),
			int(TARGET_STOCK["fiber"])])
	return _result()


## SIGIL-SEAL fallout, owner ruling 2026-08-25 ("make the route unlock the
## gate"). The authored stop at (36, -16) sits BEYOND the village road gate,
## which stands at (27.5, -16). That was reachable only for as long as the gate
## did not really seal its road -- a player, or this route, simply walked round
## the 4m leaf across open meadow. Once `road_gate.gd` grew wings wide enough to
## actually stop someone, the route could not reach its own wood: "controller
## could not reach authored wood at (36.0, -16.0) (stopped 9.0m short)".
##
## The gate was always meant to be opened, not bypassed -- `road_gate.gd`'s own
## header calls this "a simple physical gate on the road out of the village,
## with an easy key nearby", the whole point being that the player learns early
## that gated things have keys. So the route now does what the gate was built to
## teach: take the key at (24, -10), open the gate, walk through.
##
## Tolerant by design. A preceding evidence section may already have taken the
## key or opened the gate, and neither is a failure -- the same rule
## `_harvest_authored_stop` uses for an already-spent stop.
func _unlock_road_gate() -> bool:
	# OP-0830-1: the gate is a hole in the village fence now, so it hangs under
	# `VillageBoundary` rather than off the world root.
	var gate: Node3D = _world.find_child("RoadGate", true, false) as Node3D
	if gate == null:
		transcript.append("no road gate in this world; nothing to unlock")
		return true
	if bool(gate.call("is_open")):
		transcript.append("road gate already open; continuing")
		return true

	var key: Node3D = _world.get_node_or_null(^"GateKey") as Node3D
	if key != null and is_instance_valid(key):
		# Captured before the press, not read off `key` afterward: production
		# pickup frees the world key node as part of a real completed pickup
		# (found running this for real, OWNER-0901-PLAYER-SLEEP-V2) -- so the
		# transcript line below used to crash with "previously freed" on
		# exactly the success path it was meant to record.
		var key_at := key.global_position
		if not await _walk_to(key_at, 1.65, _travel_budget(key_at)) \
				and _player.global_position.distance_to(key_at) > WITHIN_REACH:
			_fail("controller could not reach the gate key at %s (stopped %.1fm short)" % [
				key_at, _player.global_position.distance_to(key_at)])
			return false
		var key_prompt: Node3D = key.get_node_or_null(^"Interactable") as Node3D
		if key_prompt == null:
			key_prompt = key
		if not await _press_and_confirm(key_prompt):
			_fail("the gate key would not come up on the interact line")
			return false
		transcript.append("took the old key at (%.1f, %.1f)" % [key_at.x, key_at.z])
	else:
		transcript.append("gate key already taken; continuing to the gate")

	var prompt: Node3D = gate.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("the road gate has no interact prompt; it cannot be opened")
		return false
	var at := gate.global_position
	if not await _walk_to(at, 2.5, _travel_budget(at)) \
			and _player.global_position.distance_to(at) > WITHIN_REACH:
		_fail("controller could not reach the road gate at %s (stopped %.1fm short)" % [
			at, _player.global_position.distance_to(at)])
		return false
	if not await _press_and_confirm(prompt):
		_fail("the road gate would not open with the key in the satchel")
		return false
	if not bool(gate.call("is_open")):
		_fail("the road gate was tried with the key in the satchel and stayed shut")
		return false
	# GATHER-ROUTE-0903. `road_gate.gd::_on_tried()` opens the gate AND calls
	# `_say(unlocked_conversation)`, which starts the SAME "dialogue_panel"
	# group node every villager visit uses -- but unlike every villager visit
	# in this file and in `gate_a_npc_gather_segment.gd`, nothing here ever
	# waited for that conversation or pressed to close it.
	#
	# A player leaves it open and `sequence_director.gd::_refresh_lockout()`
	# keeps `locomotion_enabled` false for as long as it stays that way --
	# there was never a reachability problem past this point. Measured
	# directly (`tools/_probe_gather_route_reach_0903b.gd`): locomotion reads
	# false, with no fight running and no aggressive creature within 17m, on
	# EVERY sampled second from the moment the gate opens onward, and the
	# resulting stall silently burns `stick_navigator.gd`'s own ten-minute
	# `HELD_FRAMES` allowance (built for a real wild fight, which this is
	# not) before the leg gives up and reports a bogus "stopped 22.9m short"
	# -- the walk never took a single step.
	if not await _clear_gate_conversation():
		_fail("the road gate's own conversation would not close, so locomotion never came back")
		return false
	transcript.append("unlocked the road gate with the old key")
	return true


## Wait for and dismiss whatever `road_gate.gd::_say()` put up, the same way
## `_visit_villager()` closes a villager's dialogue -- then wait for
## `locomotion_enabled()` to actually flip back true, since
## `_refresh_lockout()` only does that on its own next process frame.
func _clear_gate_conversation() -> bool:
	var panel := _tree.get_first_node_in_group("dialogue_panel")
	if panel == null:
		return true
	# The conversation opens on the same frame `_on_tried()` runs, but give it
	# a few frames of margin rather than assume that ordering.
	for _i in 30:
		if bool(panel.call("is_open")):
			break
		await _tree.physics_frame
	if not bool(panel.call("is_open")):
		return true
	for _i in 40:
		if not bool(panel.call("is_open")):
			break
		await _tap_action(&"interact")
	if bool(panel.call("is_open")):
		return false
	for _i in 60:
		if bool(_player.call("locomotion_enabled")):
			return true
		await _tree.physics_frame
	return false


func _verify_tool_hotbar() -> bool:
	var hotbar: Array = _game.get("hotbar") as Array
	if hotbar.size() < 3:
		_fail("Satchel route did not expose three tool quick slots")
		return false
	for item_id in ["axe", "pickaxe", "knife"]:
		if int((_game.get("inventory") as RefCounted).call("find_slot", item_id)) < 0:
			_fail("natural route requires Tam's %s before it can harvest" % item_id)
			return false
	return true


func _harvest_authored_stop(stop: Dictionary) -> bool:
	var item_id := str(stop["item"])
	if _count(item_id) >= int(TARGET_STOCK[item_id]):
		return true
	var expected := Vector2(stop["at"])
	var node := _authored_node_at(expected, item_id)
	if node == null:
		# A preceding evidence section may already have spent this exact authored
		# stop. That is valid only when the inventory reflects it; the final
		# invariant, not a synthetic replacement, decides sufficiency.
		transcript.append("authored %s at %s was already spent; continuing from real satchel stock" % [item_id, expected])
		return true
	# Same rule as the live-scatter fill: the CENTRE is not the test, the prompt
	# is. An authored stop's model can be wider than the 1.65m this asks for --
	# the fiber stand at (24, -24) stopped the walk 2.1m out and the run called
	# a perfectly harvestable stop unreachable. `_harvest_node()` below decides,
	# and says why when it cannot.
	var stop_at := node.global_position
	if not await _walk_to(stop_at, 1.65, _travel_budget(stop_at)) \
			and _player.global_position.distance_to(stop_at) > WITHIN_REACH:
		_fail("controller could not reach authored %s at %s (stopped %.1fm short)" % [
			item_id, expected, _player.global_position.distance_to(stop_at)])
		return false
	if not await _harvest_node(node, item_id, true):
		return false
	transcript.append("authored %s %+d at (%.1f, %.1f)" % [item_id, int(stop["amount"]), expected.x, expected.y])
	return true


## Close the shortfall by chopping real scatter, and DO NOT let one awkward
## stand end the chapter.
##
## GATEB-COORD. The Meadows scatters 24,325 harvestable stands and they grow in
## thickets a metre or two apart. Two things follow, both measured in
## `tools/_probe_scatter_fill.gd`:
##
##   * the interact line flickers between neighbours, so a press aimed at one
##     stand lands on the one beside it -- `_press_and_confirm()` is the
##     answer to that, and it recovers most of them by stepping round;
##   * some stands simply will not settle. Six approaches from six angles and
##     the arbiter still hands the button to a neighbour or publishes nothing.
##
## A player meets the second one and chops a different tree. So does this. A
## refused stand is remembered, skipped, and the next nearest is walked to;
## only `REFUSALS_ALLOWED` in a row means something is actually wrong with
## harvesting rather than with one awkward trunk. Failures recorded during a
## tolerated skip are rolled back off `failures` -- they are not the run's
## verdict, they are why one tree was abandoned -- and the transcript keeps
## every one of them.
const REFUSALS_ALLOWED := 5
## Metres of height difference from the player that still counts as "a tree I
## can walk to". The Meadows has real hills in it and the trainer climbs
## slopes, not cliffs.
const WALKABLE_RISE := 6.0
## Close enough to a stand to be worth pressing at, even when the walk could
## not reach its centre. `interactable.gd`'s own prompt radii on harvest nodes
## sit between 2.4m and 4m, so a player stopped by the far side of a boulder is
## still well inside the offer.
const WITHIN_REACH := 4.5


func _fill_with_live_scatter(item_id: String) -> bool:
	var required := int(TARGET_STOCK[item_id])
	var trips := 0
	var refused: Array[int] = []
	var in_a_row := 0
	while _count(item_id) < required:
		var node := _nearest_live_scatter(item_id, refused)
		if node == null:
			_fail("no live natural %s scatter remains at %d/%d; authored route cannot fund the required paid build" % [
				item_id, _count(item_id), required])
			return false
		var node_id := node.get_instance_id()
		var failures_before := failures.size()
		var before := _count(item_id)
		# The stand's position, taken while the stand still exists.
		#
		# GATEB-COORD: `vegetation_harvest_point.gd` FREES ITSELF once it is
		# spent, and every line below used to re-read `node.global_position`
		# after the chop that spends it. The first successful scatter trip
		# therefore died on
		#
		#   Invalid access to property 'global_position' on a base object of
		#   type 'previously freed'  (gate_a_material_route.gd:150)
		#
		# in the TRANSCRIPT line -- the harvest had worked and paid its wood.
		# That is the real reason Gate B's continuous run stops in the wood
		# fill. It is not a travel failure; nothing had ever measured it,
		# because `tools/_probe_scatter_fill.gd` drove the fill from the
		# default spawn, which is inside GrandpaHouse, and so never got far
		# enough to chop anything.
		var at := node.global_position
		# Getting to the CENTRE is not the test; getting to the PROMPT is.
		#
		# GATEB-COORD: the stone fill stopped 3.4m short of six boulders in a
		# row. A stand's `global_position` is the middle of its own collider,
		# and a big rock is wider than the 1.65m this asks for -- so the walk
		# can never "arrive" however well it is working. What decides whether a
		# harvest is possible is whether the node's own prompt wins the interact
		# line from where the player is standing, and `_harvest_node()` already
		# establishes that and says so when it cannot. So a short walk goes on
		# to try the harvest, and only a walk that ended a long way off is
		# called a travel failure.
		var reached: bool = await _walk_to(at, 1.65, _travel_budget(at))
		var short_by := _player.global_position.distance_to(at)
		if not reached and short_by > WITHIN_REACH:
			_fail("controller could not reach live natural %s at %s (stopped %.1fm short)" % [
				item_id, at, short_by])
		elif not await _harvest_node(node, item_id, false):
			pass  # `_harvest_node` has already said why, on `failures`.
		elif _count(item_id) - before <= 0:
			_fail("natural %s at %s paid no inventory after production chop/pickup" % [item_id, at])
		else:
			trips += 1
			in_a_row = 0
			transcript.append("scatter %s +%d at (%.2f, %.2f); %d/%d" % [
				item_id, _count(item_id) - before, at.x, at.z, _count(item_id), required])
			continue
		# This stand refused. Abandon it and walk to another one.
		in_a_row += 1
		refused.append(node_id)
		var why := str(failures[failures.size() - 1]) if failures.size() > failures_before \
			else "no reason recorded"
		if in_a_row > REFUSALS_ALLOWED:
			_fail(("%d live %s stands in a row refused to be harvested, the last at %s. "
				+ "That is not one awkward trunk, it is harvesting. Last reason: %s")
				% [in_a_row, item_id, at, why])
			return false
		failures.resize(failures_before)
		transcript.append("live %s at (%.1f, %.1f) would not be harvested (%s); "
			% [item_id, at.x, at.z, why] + "walking to another stand (%d/%d tolerated)"
			% [in_a_row, REFUSALS_ALLOWED])
	transcript.append("natural %s deficit closed with %d live scatter stops" % [item_id, trips])
	return true


func _harvest_node(node: Node3D, item_id: String, authored: bool) -> bool:
	if str(node.call("resource_item")) != item_id:
		_fail("route target changed from %s to %s" % [item_id, str(node.call("resource_item"))])
		return false
	if int(node.call("resource_amount")) <= 0:
		_fail("live %s target exposed a non-positive public resource amount" % item_id)
		return false
	if not await _equip(item_id):
		return false
	var before := _count(item_id)
	# `interact` (X), not `use_tool`.
	#
	# CONTROLLER-MAP gave X "talk, gather, chop, mine" and left `use_tool` with
	# only its mouse button (project.godot's own comment on the action says so:
	# "L3, not X"). This line therefore had NO physical joypad binding at all,
	# and `_tap_action` refuses one -- the Gate B continuous run failed here with
	# "use_tool has no physical joypad binding" followed by "wood action produced
	# no visible inventory gain", which is one fault reported twice.
	#
	# `gate_a_npc_gather_segment.gd` fixed exactly this in its own three gathers
	# and wrote the reasoning into its header; this is the same swing on the same
	# pad, so it is the same button.
	# Wait for the node's own prompt to be the one the button is offering.
	#
	# The village stands in open meadow, the arbiter ranks by distance, and X is
	# ALSO "engage the wild creature" -- so a press sent from 1.65m without
	# checking who holds the line can go somewhere else entirely and report back
	# as a swing that credited nothing. `gate_a_npc_gather_segment.gd` learned
	# the same thing at Tam and now says the winner in its own failures.
	# Read once, up here, while the node is certainly alive. GATEB-COORD: the
	# swing below SPENDS the stand and `vegetation_harvest_point.gd` frees a
	# spent stand, so every `node.global_position` after the press was a read
	# through a dangling reference -- see the fill loop's own note.
	var at := node.global_position
	var node_prompt := node.get_node_or_null(^"Interactable") as Node3D
	if node_prompt != null:
		await _stand_where_it_wins(node_prompt, at)
		# The press has to land ON this stand, not on whichever neighbour is
		# nearest by the time the button is read -- see `_press_and_confirm()`.
		if not await _press_and_confirm(node_prompt):
			_fail(_why_the_swing_paid_nothing(node, node_prompt, item_id, at))
			return false
	else:
		await _tap_action(&"interact")
	if authored:
		if await _wait_for_inventory_gain(item_id, before, 120):
			return true
		_fail(_why_the_swing_paid_nothing(node, node_prompt, item_id, at))
		return false
	# Scatter stands are a two-stage production verb: physical tool swing chops,
	# then the same player picks up the visible felled pile. Never call either
	# stage directly, and never assume a swing is itself an inventory grant.
	var pile := await _wait_for_felled_pickup(at, item_id, 180)
	if pile == null:
		_fail(_why_no_pile_appeared(node, node_prompt, item_id, at))
		return false
	if not await _walk_to(pile.global_position, 1.5, 300):
		_fail("controller could not reach its felled %s pickup" % item_id)
		return false
	var prompt := pile.get_node_or_null(^"Interactable") as Node3D
	if prompt == null or not await _stand_where_it_wins(prompt, pile.global_position, 1.0):
		_fail("felled %s pickup never offered the production Pick up prompt" % item_id)
		return false
	var pile_at := pile.global_position
	if not await _press_and_confirm(prompt):
		_fail(_why_the_swing_paid_nothing(pile, prompt, item_id, pile_at))
		return false
	if await _wait_for_inventory_gain(item_id, before, 240):
		return true
	_fail(_why_the_swing_paid_nothing(pile, prompt, item_id, pile_at))
	return false


## Why a pressed swing credited nothing. Four different bugs used to arrive as
## one line reading "wood action produced no visible inventory gain".
## Why a chop left no pile to pick up. GATEB-COORD: this used to be the bare
## line "visible wood swing created no public felled pickup near <point>",
## which cannot distinguish the four things it can mean -- the stand was never
## struck (the button went somewhere else), the stand was struck and is still
## standing (it had more stock in it), the pile exists but landed outside the
## 3m the search allows, or nothing spawned at all. All four want different
## fixes, so all four are now named.
func _why_no_pile_appeared(node, node_prompt, item_id: String,
		at: Vector3) -> String:
	var alive := node != null and is_instance_valid(node)
	var nearest: Node3D = null
	var nearest_distance := INF
	for candidate: Node in _tree.get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != FELLED_RESOURCE_PATH:
			continue
		if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
			continue
		var distance := at.distance_to((candidate as Node3D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate as Node3D
	var winner: Variant = _arbiter.call("winning_provider")
	var hold: Node = _player.get("tool_hold")
	return ("%s chop left no felled pickup within 3m of %s (stand=%s, "
		+ "nearest felled %s=%s, player %.2fm from the stand, equipped=%s, "
		+ "swinging=%s, arbiter winner=%s offering %s, wanted=%s)") % [
		item_id, at,
		("still standing with %s left" % str(node.call("resource_amount"))) if alive
			else "spent and freed",
		item_id,
		("%s at %.1fm" % [str(nearest.name), nearest_distance]) if nearest != null
			else "<none anywhere in the world>",
		_player.global_position.distance_to(at),
		str(_game.get("equipped_tool")),
		str(hold.call("is_swinging")) if hold != null else "<no ToolHold>",
		_who(winner),
		str(_arbiter.call("winner")),
		_who(node_prompt)]


## `at` is passed in rather than read off `node`: this is the failure path of a
## press that may have spent -- and so freed -- the very node it is reporting
## about, and a diagnostic that crashes tells you nothing.
func _why_the_swing_paid_nothing(node, node_prompt, item_id: String,
		at: Vector3) -> String:
	var winner: Variant = _arbiter.call("winning_provider")
	var hold: Node = _player.get("tool_hold")
	var alive := node != null and is_instance_valid(node)
	return ("%s swing credited nothing (arbiter winner=%s offering %s, wanted=%s, %.2fm away, "
		+ "equipped=%s, prop=%s, swinging=%s, node stock=%s)") % [
		item_id,
		_who(winner),
		str(_arbiter.call("winner")),
		_who(node_prompt),
		_player.global_position.distance_to(at),
		str(_game.get("equipped_tool")),
		str(hold.call("prop_node")) if hold != null else "<no ToolHold>",
		str(hold.call("is_swinging")) if hold != null else "<no ToolHold>",
		str(node.call("resource_amount")) if alive else "<stand spent and freed>"]


## Half a metre sideways, a different angle each time.
##
## The circle `_stand_where_it_wins()` walks is the same idea; this is the
## smaller version for a prompt that has already been reached and is only
## occluded, so it does not throw away the approach to start again.
func _step_aside_from(around: Vector3, attempt: int) -> void:
	var angle := TAU * (float(attempt) + 0.5) / 6.0
	var spot := around + Vector3(cos(angle), 0.0, sin(angle)) * 1.4
	await _walk_to(spot, 0.7, 240)
	for _i in 12:
		await _tree.physics_frame


## What the prompt's own line-of-sight ray runs into, if anything.
##
## `interactable.gd::_has_line_of_sight()` withdraws an offer entirely when
## solid geometry stands between the prompt and the player's eye, and it is
## silent about it -- an offer that is refused for this reason looks exactly
## like a prompt that is out of range or disabled. In a chopped-over grove the
## occluder is nearly always a neighbouring trunk, and naming it is the
## difference between "the arbiter went quiet" and a fact.
func _what_blocks_sight_to(target: Vector3) -> String:
	var world := _player.get_world_3d()
	var space := world.direct_space_state if world != null else null
	if space == null:
		return "no space state to test sight with"
	var eye := _player.global_position + Vector3.UP * 1.6
	var query := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 0.5, eye)
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return "sight to it is clear"
	var collider: Variant = hit.get("collider")
	var where: Vector3 = hit.get("position", Vector3.ZERO)
	var owner := "<?>"
	if collider is Node:
		var parent := (collider as Node).get_parent()
		owner = "%s/%s" % [str(parent.name) if parent != null else "?",
			str((collider as Node).name)]
	return "sight to it is blocked by %s at (%.1f, %.1f, %.1f)" % [
		owner, where.x, where.y, where.z]


## The state of the interact line, for a wait that timed out.
##
## GATEB-COORD: "it reads ''" is what this used to say, and an EMPTY line is
## not the same fact as a line held by something else -- `interaction_arbiter.gd`
## publishes nothing at all while `_enabled` is false (a conversation, a naming
## prompt or a fade, per `sequence_director.gd::_refresh_lockout`) or while an
## `input_owner.gd` panel is up, and those are not situations more pressing of
## the button will fix.
func _why_the_line_is_quiet() -> String:
	var enabled := bool(_arbiter.call("enabled")) if _arbiter.has_method("enabled") else true
	var owner: Variant = INPUT_OWNER.current(_tree)
	var manager := _world.get_node_or_null(^"CombatManager")
	var fighting := manager != null and manager.has_method("is_fighting") \
		and bool(manager.call("is_fighting"))
	return "arbiter enabled=%s, reads '%s' held by %s, input owner=%s, fighting=%s, paused=%s" % [
		str(enabled), str(_arbiter.call("prompt")),
		_who(_arbiter.call("winning_provider")),
		_who(owner) if owner != null else "<none>",
		str(fighting), str(_tree.paused)]


## A prompt's IDENTITY, not its class name.
##
## GATEB-COORD: every prompt in the world is a node called "Interactable", so
## "arbiter winner=Interactable, wanted=Interactable" -- which is what these
## diagnostics used to print -- cannot say whether the button went to the pile
## being reported on or to the one two metres away. The instance id and the
## world position can.
func _who(node: Variant) -> String:
	# `is_instance_valid` FIRST: `node is Node` on a freed instance is itself
	# an error ("Left operand of 'is' is a previously freed instance"), and
	# every caller here is a path where the node may well have just been spent.
	if not node is Object or not is_instance_valid(node as Object):
		return "<freed or none>"
	if not node is Node:
		return "<none>"
	var as_node := node as Node
	var where := ""
	if as_node is Node3D:
		var p: Vector3 = (as_node as Node3D).global_position
		where = " @(%.1f, %.1f)" % [p.x, p.z]
	return "%s#%d%s" % [as_node.name, as_node.get_instance_id(), where]


## Put the right tool in hand -- and press NOTHING if it is already there.
##
## A quick slot TOGGLES (`playground_hud.gd`: "press slot, tool in hand", and
## pressing it again stows). This pressed unconditionally, so the second wood
## stop in a row would have STOWED the axe and then failed waiting for it, with
## the outcome depending entirely on what the previous beat left in hand.
## `gate_a_npc_gather_segment.gd` fixed the identical thing after two runs of
## the same file failed at two different points with no code change between
## them; the same reasoning applies to the same toggle here.
##
## HARNESS-HYGIENE-0903: the control pressed is read live via
## `game_state.gd::hotbar_slot_of(expected_tool)`, not the fixed `TOOL_ACTION`
## map this used to press unconditionally. That map was a claim about where an
## earlier assign sequence bound each tool, and the exact class of bug
## `tools/gate_f/operator_harness.gd::_step_equip_tool` was fixed for
## (FINDING-S03-105-HOME-MATERIALS-ROOT-CAUSE-2026-09-02.md): a fixed slot
## number goes stale the moment anything upstream binds tools in a different
## order.
func _equip(item_id: String) -> bool:
	var expected_tool := str(TOOL_ID[item_id])
	# A visible swing owns the held prop for its whole animation and the player
	# cannot switch tools mid-swing, so neither does this.
	var holder: Node = _player.get("tool_hold")
	if holder != null:
		for _i in 120:
			if not bool(holder.call("is_swinging")):
				break
			await _tree.physics_frame
	if str(_game.get("equipped_tool")) != expected_tool:
		var slot := int(_game.call("hotbar_slot_of", expected_tool))
		if slot < 0:
			_fail("'%s' is not on the hotbar at all (checked live via hotbar_slot_of, not a fixed slot guess)" % expected_tool)
			return false
		await _tap_action(StringName("hotbar_%d" % (slot + 1)))
	for _i in 45:
		var hold: Node = _player.get("tool_hold")
		if str(_game.get("equipped_tool")) == expected_tool and hold != null and hold.call("prop_node") != null:
			return true
		await _tree.physics_frame
	_fail("controller quick slot did not visibly equip %s for %s" % [expected_tool, item_id])
	return false


func _authored_node_at(at: Vector2, item_id: String) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for candidate: Node in _tree.get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_PATH:
			continue
		if str(candidate.call("resource_item")) != item_id:
			continue
		if not _is_unspent(candidate as Node3D):
			continue
		var gap := Vector2((candidate as Node3D).global_position.x - at.x,
			(candidate as Node3D).global_position.z - at.y).length()
		if gap < distance:
			distance = gap
			nearest = candidate as Node3D
	return nearest if distance <= 2.0 else null


## Has this authored node actually still got anything on it?
##
## `harvest_node.gd::resource_amount()` reports the AUTHORED amount and keeps
## reporting it after the node has been harvested -- what changes on a spent
## node is that its visual hides and its prompt is switched off for
## `RESPAWN_SECONDS`. So "stock is 4" was never the question; "is the prompt
## still enabled" is.
##
## This mattered because `gate_a_npc_gather_segment.gd` runs immediately before
## this route in the Gate B continuous session and spends the NEAREST authored
## wood, stone and fiber node -- which is routinely one of the stops listed in
## `AUTHORED_ROUTE`. The route then walked to a hidden stump, found the only
## remaining bidder for X was the encounter director's own "Put Bud away"
## statement, pressed anyway, and reported "wood action produced no visible
## inventory gain" about a node a previous beat had legitimately harvested.
##
## `_harvest_authored_stop()` already had the right answer for a spent stop --
## note it in the transcript and let the live-scatter fill cover the shortfall
## -- and simply never reached it.
func _is_unspent(node: Node3D) -> bool:
	if float(node.get("_respawn_left")) > 0.0:
		return false
	var prompt := node.get_node_or_null(^"Interactable")
	return prompt == null or bool(prompt.get("enabled"))


## `refused` carries the instance ids of stands already abandoned this fill --
## see `_fill_with_live_scatter()`. Without it the loop would walk straight
## back to the nearest one, which is precisely the stand that just would not
## answer, forever.
func _nearest_live_scatter(item_id: String, refused: Array[int] = []) -> Node3D:
	var candidates: Array[Node3D] = []
	for candidate: Node in _tree.get_nodes_in_group("harvestable"):
		if not candidate is Node3D or not candidate.has_method("resource_item"):
			continue
		if refused.has(candidate.get_instance_id()):
			continue
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != VEGETATION_POINT_PATH:
			continue
		# A spent scatter stand frees itself (`vegetation_harvest_point.gd`), and
		# a node freed this frame is still in the group for the rest of it.
		if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
			continue
		if str(candidate.call("resource_item")) == item_id:
			candidates.append(candidate as Node3D)
	# Prefer a stand on ground the player can actually walk to.
	#
	# GATEB-COORD: "nearest" measured straight-line will happily pick a tree
	# twenty metres UP the eastern hill once the flat ground nearby has been
	# chopped out, and the continuous run died there -- six stands in a row,
	# all in the same unreachable cluster:
	#
	#   controller could not reach live natural wood at
	#   (104.7, 20.56, -52.6) (stopped 21.6m short)
	#
	# A player picks a tree they can get to. Candidates within `WALKABLE_RISE`
	# of the player's own height are considered first, and the steep ones are
	# only fallen back on when there is nothing level left anywhere.
	var level: Array[Node3D] = []
	for candidate: Node3D in candidates:
		if absf(candidate.global_position.y - _player.global_position.y) <= WALKABLE_RISE:
			level.append(candidate)
	if not level.is_empty():
		candidates = level
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var a_distance := _player.global_position.distance_squared_to(a.global_position)
		var b_distance := _player.global_position.distance_squared_to(b.global_position)
		if not is_equal_approx(a_distance, b_distance):
			return a_distance < b_distance
		if not is_equal_approx(a.global_position.x, b.global_position.x):
			return a.global_position.x < b.global_position.x
		return a.global_position.z < b.global_position.z
	)
	return candidates[0] if not candidates.is_empty() else null


## The visible pile a chop leaves behind. Matched by SCRIPT, not by "anything
## nearby that answers `resource_item`".
##
## The stand that was just chopped answers that too, and it is by definition
## within the 3m radius of itself: `vegetation_harvest_point.gd` frees itself
## when spent, but not until the end of the frame, so a loop that started
## looking immediately could hand back the stump. Walking to it then finds a
## prompt that is on its way out of the tree, presses X at it, and reports "wood
## action produced no visible inventory gain" about a chop that worked and a
## pickup that was never visited.
## Searched through the `harvestable` GROUP rather than by walking the world.
## `felled_resource.gd::_ready()` joins it, and `_descendants(_world)` is a
## recursion over the ~143,000 props `vegetation.gd` scatters -- run once per
## frame for 180 frames, which is most of what made this route slow.
func _wait_for_felled_pickup(at: Vector3, item_id: String, frames: int) -> Node3D:
	for _i in frames:
		# Every fourth frame: the pile is spawned by the swing's own resolution
		# and is not going to appear between two consecutive physics ticks.
		if _i % 4 == 0:
			for candidate: Node in _tree.get_nodes_in_group("harvestable"):
				if not candidate is Node3D:
					continue
				var script := candidate.get_script() as Script
				if script == null or script.resource_path != FELLED_RESOURCE_PATH:
					continue
				if not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
					continue
				if str(candidate.call("resource_item")) != item_id:
					continue
				var prompt := candidate.get_node_or_null(^"Interactable")
				if prompt != null and (candidate as Node3D).global_position.distance_to(at) <= 3.0:
					return candidate as Node3D
		await _tree.physics_frame
	return null


## Stand somewhere the button belongs to `prompt` before pressing it.
##
## X is one button and the arbiter gives it to whatever is NEAREST
## (`prompt_arbiter.gd`), so a chop press sent from beside a tree while a wild
## creature is wandering past goes to the creature instead. Measured, not
## theorised: this route failed at its very first authored stop with
##
##   wood swing credited nothing (arbiter winner=EncounterDirector,
##   wanted=Interactable, 1.13m away, equipped=axe, prop=Axe_Bronze2, ...)
##
## -- axe in hand, a metre from the trunk, and X meant "engage the Bramblebun".
##
## A player walks round the tree and asks again, so this circles the node and
## re-checks. Also gives the wanderer time to wander: the pause between spots is
## as much of the answer as the movement is.
func _stand_where_it_wins(prompt: Node3D, around: Vector3, radius := 1.2) -> bool:
	for attempt in 10:
		if await _wait_for_prompt(prompt, 30):
			return true
		if await _clear_a_statement_off_the_button():
			continue
		var angle := TAU * float(attempt) / 10.0
		await _walk_to(around + Vector3(cos(angle), 0.0, sin(angle)) * radius, 0.6, 300)
		for _i in 12:
			await _tree.physics_frame
	return await _wait_for_prompt(prompt, 60)


## A STATEMENT can hold the interact line, and walking round it does not help.
##
## `encounter_director.gd::interaction_offer()` answers a knocked-out ally with
## `PROMPTS.offer("%s is out of the fight.", 0.0, 100, false)` -- priority 100,
## distance 0, `actionable: false`. That outranks every harvest node in the
## world by design (the line exists to explain why the button is doing nothing),
## and it is not cleared by moving: it stands until the creature is dealt with.
## A press against it is refused outright by
## `interaction_arbiter.gd::activate()`, which is a swing that never happened
## and a satchel that never changed -- exactly the shape of this route's own
## "wood swing credited nothing (arbiter winner=EncounterDirector ...
## swinging=false)".
##
## The player's verb for it is the recall button, so that is the button. Returns
## whether it pressed anything, so the caller can re-check rather than walk.
func _clear_a_statement_off_the_button() -> bool:
	var winner: Variant = _arbiter.call("winning_provider")
	if winner == null or (winner is Node and str((winner as Node).name) != "EncounterDirector"):
		return false
	var offer := _arbiter.call("winner") as Dictionary
	if bool(offer.get("actionable", true)):
		return false
	transcript.append("a statement held the interact line ('%s'); recalling" % str(offer.get("label", "")))
	await _tap_action(&"creature_recall")
	for _i in 30:
		await _tree.physics_frame
	return true


## Press `interact` AT `prompt`, and know whether it landed there.
##
## GATEB-COORD. The scatter fill's ninth trip failed with
##
##   wood chop left no felled pickup within 3m of (-116.2, 8.1, 321.8)
##   (stand=still standing with 3 left, nearest felled wood=@Node3D@29943 at
##   3.9m, ...)
##
## and the arbiter's own activation log named the reason: the press fired
## `Interactable#1135129693963 @(-115.5, 319.1)` -- a DIFFERENT stand, 2.8m
## away. The stand we wanted was still standing with its stock untouched, and
## the pile the press really made landed 3.9m off, just outside the search.
##
## `_wait_for_prompt()` had already returned true, and it was not lying: it
## returns the instant our prompt wins, and in a dense grove the stands are a
## metre or two apart, so the winner flips back to a neighbour while the press
## is still in flight. Confirming the winner and pressing are two different
## moments, and only the second one matters.
##
## So: stop walking, wait for our prompt to hold the line for `HOLD_FRAMES`
## CONSECUTIVE frames, then press while watching the arbiter's own `activated`
## signal, and report which provider actually fired. A player does the same
## thing -- they stop, see the prompt settle, and press.
##
## The hold is the whole check; standing still is something this DOES rather
## than something it waits for. A first cut also demanded `velocity` under
## 0.05 m/s and that rejected presses which had been working: a body on the
## meadow's slopes keeps a little drift indefinitely, so the run got six trips
## instead of ten. Eight consecutive frames of the same winner already proves
## the distances have stopped moving, which is the thing that matters.
const HOLD_FRAMES := 8


## INSTANCE IDS, not object references, all the way through. A press that
## works SPENDS the stand, `vegetation_harvest_point.gd` frees a spent stand,
## and the prompt goes with it -- so by the time this checks what fired, the
## thing it wanted is very often already gone. A freed reference cannot be
## compared, passed to a typed parameter, or even asked `is Node` without an
## error, and the first cut of this function did all three: it reported "press
## 1 meant for  went to " about a chop that had worked perfectly.
func _press_and_confirm(prompt: Node3D) -> bool:
	var wanted_id := prompt.get_instance_id()
	var wanted := _who(prompt)
	var fired: Array[int] = []
	var watch := func(provider: Object) -> void: fired.append(provider.get_instance_id())
	_arbiter.connect("activated", watch)
	var landed := false
	var around := prompt.global_position
	for attempt in 6:
		_release_move()
		if not await _prompt_holds_the_line(wanted_id):
			transcript.append("%s never held the interact line for %d frames running (%s, %s); "
				% [wanted, HOLD_FRAMES, _why_the_line_is_quiet(), _what_blocks_sight_to(around)]
				+ "moving round it")
			# MOVE, do not just wait. A line that will not settle is a line
			# something is standing in -- `interactable.gd::_has_line_of_sight()`
			# refuses an offer through geometry, and in a dense grove the thing
			# in the way is a neighbouring trunk that is not going anywhere.
			# Pressing harder from the same spot cannot fix that; walking round
			# is what a player does and what `_stand_where_it_wins()` is for.
			if not is_instance_valid(prompt):
				break
			await _step_aside_from(around, attempt)
			continue
		fired.clear()
		await _tap_action(&"interact")
		for _i in 12:
			if not fired.is_empty():
				break
			await _tree.physics_frame
		if fired.has(wanted_id):
			landed = true
			break
		if fired.is_empty():
			transcript.append("press %d at %s activated nothing; settling and pressing again"
				% [attempt + 1, wanted])
		else:
			transcript.append("press %d meant for %s went to %s; settling and pressing again"
				% [attempt + 1, wanted, _who(instance_from_id(fired[0]))])
		for _i in 20:
			await _tree.physics_frame
	_arbiter.disconnect("activated", watch)
	return landed


## Our prompt has held the interact line for `HOLD_FRAMES` running, with the
## player standing still. Both halves matter: a winner sampled on one frame is
## the thing that was already wrong, and a player still sliding is a player
## whose distances are still changing.
func _prompt_holds_the_line(wanted_id: int) -> bool:
	var held := 0
	for _i in 180:
		var winner: Variant = _arbiter.call("winning_provider")
		var winner_id := (winner as Object).get_instance_id() \
			if winner is Object and is_instance_valid(winner as Object) else 0
		if winner_id == wanted_id:
			held += 1
			if held >= HOLD_FRAMES:
				return true
		else:
			held = 0
		await _tree.physics_frame
	return false


func _wait_for_prompt(prompt: Node3D, frames: int) -> bool:
	for _i in frames:
		if _arbiter.call("winning_provider") == prompt:
			return true
		await _tree.physics_frame
	return false


func _wait_for_inventory_gain(item_id: String, before: int, frames: int) -> bool:
	for _i in frames:
		if _count(item_id) > before:
			return true
		await _tree.physics_frame
	_fail("%s action produced no visible inventory gain" % item_id)
	return false


## Physics frames to allow for a leg, from how long the leg actually is.
##
## The fixed 1800-frame budget these call sites used to share is 30 seconds, and
## `data/config/movement.json` walks the trainer at 5 m/s -- so it covered about
## 150m in a straight line with nothing in the way. `AUTHORED_ROUTE`'s own last
## two fiber stops are at (-5, 141) and (-168, 312), "deliberately on ordinary
## open-spine travel", and the first of those is a 161m leg. It failed by a few
## metres: "controller could not reach authored fiber at (-5.0, 141.0)", on a
## walk that was working and simply ran out of clock.
##
## 60 frames per metre is one metre per second -- five times the margin the
## trainer needs at a walk, which is what pays for the detours around trees and
## the climbs the open spine has in it.
func _travel_budget(target: Vector3) -> int:
	return 240 + int(_player.global_position.distance_to(target) * 60.0)


func _walk_to(target: Vector3, close_enough: float, budget: int) -> bool:
	var arrived: bool = await _nav.walk_to(target, budget, close_enough)
	_release_move()
	return arrived


## The left stick as `stick_navigator.gd` asks for it, through THIS file's own
## resolved bindings: the navigator hands over stick-space numbers and never
## touches `Input` itself, so each harness keeps speaking the pad it parsed.
func _send_stick(x: float, y: float) -> void:
	_parse_axis(_move_x_axis, x * _move_x_sign)
	_parse_axis(_move_y_axis, y * _move_y_sign)


func _tap_action(action: StringName) -> void:
	var binding := _event_for(action, true)
	if binding == null:
		_fail("%s has no physical joypad binding" % action)
		return
	Input.parse_input_event(binding)
	for _i in 3:
		await _tree.physics_frame
	var released := binding.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	else:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await _tree.physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	for configured: InputEvent in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _resolve_move_bindings() -> bool:
	var right := _motion_for(&"move_right")
	var back := _motion_for(&"move_back")
	if right == null or back == null:
		_fail("material route needs physical left-stick movement bindings")
		return false
	_move_x_axis = right.axis
	_move_x_sign = signf(right.axis_value)
	_move_y_axis = back.axis
	_move_y_sign = signf(back.axis_value)
	return true


func _motion_for(action: StringName) -> InputEventJoypadMotion:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


func _parse_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _release_move() -> void:
	_parse_axis(_move_x_axis, 0.0)
	_parse_axis(_move_y_axis, 0.0)


func _count(item_id: String) -> int:
	return int((_game.get("inventory") as RefCounted).call("count", item_id))


func _stock_is_sufficient() -> bool:
	for item_id: String in TARGET_STOCK:
		if _count(item_id) < int(TARGET_STOCK[item_id]):
			return false
	return true


func _stock_snapshot() -> String:
	return "wood %d / stone %d / fiber %d" % [_count("wood"), _count("stone"), _count("fiber")]


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _fail(message: String) -> void:
	if not failures.has(message):
		failures.append(message)


func _result() -> Dictionary:
	_release_move()
	return {"passed": failures.is_empty(), "failures": failures.duplicate(), "transcript": transcript.duplicate()}
