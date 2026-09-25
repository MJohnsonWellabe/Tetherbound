extends SceneTree

## F13 walk-and-claim receipt for the six filled Tidewake reward pockets, in
## the production Water scene (baked Terrain3D ground, production pickup
## streamer, interaction arbiter and host ledger).
##
## For each Skill Candy row bound to a reward pocket: the trainer is placed on
## that island's authored arrival landing (DISCLOSED FIXTURE: one position
## write per island; no swim between islands), then walks to the candy with
## real left-stick input only, and claims it by pressing the ordinary Interact
## action on the production prompt. The walk follows a harness-planned route
## over the BAKED ground (AStarGrid2D, 2 m cells, dry and at most 35 degrees,
## preferring the island's authored graded land route), steered by the shared `stick_navigator.gd`; the planner is harness-only and
## writes nothing into the world.
##
## Asserts per pocket: the prompt is offered, one Interact press is accepted by
## the host (item in inventory, personal receipt, pickup no longer resident).
## Records baked vs analytic ground at the candy and the 3D distances at the
## moment of the press. A refusal fails loudly with the ledger's code.
##
## The Cradle care leg (on unless `--no-cradle`) additionally walks from the
## Tidal Cradle arrival to `cradle_shell_nest`, mines the nest's Reef Stone
## seam with a hotbar pickaxe (DISCLOSED FIXTURE: carried tool granted before
## the world loads) and takes its berries, by the same real Interact press.
##   godot --headless --path . --script tests/smoke_water_pocket_walk_claim.gd
##     [-- --only=<pocket_id>] [--no-cradle]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const PICKUPS := "res://data/config/water_pickups.json"
const CELL_M := 2.0
const MAX_SLOPE_DEG := 35.0
const DRY_M := 0.8
const MARGIN_M := 80.0
const WAYPOINT_EVERY := 3
const CRADLE_POCKET := "cradle_shell_nest"

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var arbiter: Node
var navigator: RefCounted
var field := FIELD.new()
var config: Dictionary
var failures: Array[String] = []
var checks := 0
var finished := false
var _refusal := ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(1500.0).timeout.connect(func() -> void:
		if not finished:
			_fail("1500 second watchdog expired")
			_finish())
	game = root.get_node("Game")
	game.save_system = SAVE.new("user://smoke_water_pocket_walk_claim_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
	# Disclosed carried tool for the Cradle leg: Reef Stone needs a held pickaxe.
	if game.inventory.add("pickaxe", 1) != 0 or not game.assign_hotbar(0, "pickaxe"):
		_fail("could not create the disclosed carried pickaxe fixture")
		_finish()
		return
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _check(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		_finish()
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	arbiter = get_first_node_in_group("interaction_arbiter")
	config = world.get("config")
	navigator = NAV.new(self, player, camera, _stick)
	if not _check(arbiter != null, "production interaction arbiter missing"):
		_finish()
		return
	await _frames(30)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS))
	var results: Array[String] = []
	var only := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	for row: Dictionary in data.pickups:
		if row.has("reward_pocket_id") and str(row.category) == "skill_candy" \
				and (only.is_empty() or only == str(row.reward_pocket_id)):
			results.append(await _walk_and_claim(row))
	var with_cradle := not OS.get_cmdline_user_args().has("--no-cradle") \
			and (only.is_empty() or only == CRADLE_POCKET)
	if with_cradle:
		results.append(await _cradle_leg(data))
	for line: String in results:
		print(line)
	_finish()


func _walk_and_claim(row: Dictionary) -> String:
	var id := str(row.id)
	var pocket := str(row.reward_pocket_id)
	# Disclosed fixture: a gated pocket (Deep Watch Candy III, gated on its
	# chain's Tidecoil resolution) is unlocked before its walk. The lock itself
	# is proven by smoke_water_deep_watch_chart and the unit tests; this smoke
	# proves reach and claim from the real approach.
	for flag: Variant in row.get("requires_world_flags", []):
		game.world.flags.call("set_flag", str(flag), true)
	var landing := _landing(str(row.island_id))
	var target := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	if not _check(landing.is_finite(), "no arrival landing for " + id):
		return "POCKET %s FAIL no landing" % pocket
	var walked: Variant = await _walk_from(landing, target, 1.6, pocket)
	if walked == null:
		return "POCKET %s FAIL walk (see FAIL above)" % pocket
	var service: Node = world.get_node("WaterPickups")
	var candy: Node3D = service.call("node_for", id)
	if not _check(candy != null, "%s candy not resident on arrival" % id):
		return "POCKET %s FAIL not resident" % pocket
	var baked: float = world.call("ground_height_at", target.x, target.z)
	var analytic: float = field.height_at(target.x, target.z)
	# Close the last metre with real input until the production prompt offers
	# THIS candy; the arbiter's own winner is the only evidence accepted.
	var prompt := candy.get_node_or_null("Interactable")
	var offered := await _approach_prompt(prompt, candy.global_position)
	if not _check(offered, "%s prompt never offered; player=%s candy=%s winner=%s" % [
			id, player.global_position, candy.global_position, arbiter.call("prompt")]):
		return "POCKET %s FAIL prompt not offered" % pocket
	var stand := player.global_position
	var to_node := stand.distance_to(candy.global_position)
	var to_analytic := stand.distance_to(Vector3(target.x, analytic, target.z))
	var item := str(row.item_id)
	var before: int = game.inventory.count(item)
	_refusal = ""
	candy.connect("claim_refused", _on_refused)
	await _press_interact()
	await _frames(20)
	var after: int = game.inventory.count(item)
	var receipt: bool = game.local.flags.has(RULE.personal_flag(id))
	service.call("refresh")
	await _frames(2)
	var gone: bool = service.call("node_for", id) == null
	var accepted := after == before + int(row.quantity) and receipt and gone
	_check(accepted, "%s claim NOT accepted: refusal='%s' inventory %d->%d receipt=%s gone=%s dist_node=%.2f dist_analytic=%.2f" % [
		id, _refusal, before, after, receipt, gone, to_node, to_analytic])
	return "POCKET %s row=%s landing=%s walked=%.0fm legs=%d off_trail=%.0fm steepest_off_trail=%.1fdeg baked_y=%.3f analytic_y=%.3f gap=%+.3f claim_dist_node_3d=%.2f claim_dist_analytic_3d=%.2f result=%s" % [
		pocket, id, _landing_id(str(row.island_id)), float(walked.metres), int(walked.legs), float(walked.spur_m), float(walked.spur_max_slope), baked, analytic,
		baked - analytic, to_node, to_analytic, "ACCEPTED" if accepted else "REFUSED(%s)" % _refusal]


## Tidal Cradle (`side_water_cradle_care` payout): walk to the nest, mine its
## Reef Stone seam with the hotbar pickaxe and take its berries, each by an
## ordinary Interact press on the resident production body.
func _cradle_leg(data: Dictionary) -> String:
	var rows: Array = []
	for row: Dictionary in data.pickups + data.harvest:
		if str(row.get("reward_pocket_id", "")) == CRADLE_POCKET:
			rows.append(row)
	if not _check(rows.size() == 2, "cradle nest expects one Reef Stone seam + one berries find, found %d" % rows.size()):
		return "CRADLE FAIL rows=%d" % rows.size()
	var pocket: Dictionary = {}
	for spec: Dictionary in config.reward_pockets:
		if str(spec.id) == CRADLE_POCKET:
			pocket = spec
	var centre := Vector3(float(pocket.position[0]), 0.0, float(pocket.position[2]))
	var walked: Variant = await _walk_from(_landing("tidal_cradle"), centre, 2.0, CRADLE_POCKET)
	if walked == null:
		return "CRADLE FAIL walk"
	var service: Node = world.get_node("WaterPickups")
	var gains := {"reef_stone": 0, "berries": 0}
	var notes: Array[String] = []
	for row: Dictionary in rows:
		var id := str(row.id)
		var body: Node3D = service.call("node_for", id)
		if not _check(body != null, "cradle row not resident: " + id):
			continue
		var item := str(row.item_id)
		var tool := str(row.get("gather_action", ""))
		if not tool.is_empty() and str(game.equipped_tool) != tool:
			await _tap(StringName("hotbar_%d" % (game.hotbar.find(tool) + 1)))
			await _frames(20)
			_check(str(game.equipped_tool) == tool, "hotbar did not equip the disclosed %s" % tool)
		var prompt := body.get_node_or_null("Interactable")
		var offered := await _approach_prompt(prompt, body.global_position)
		if not _check(offered, "cradle prompt never offered for %s; player=%s body=%s winner=%s" % [
				id, player.global_position, body.global_position, arbiter.call("prompt")]):
			continue
		var before: int = game.inventory.count(item)
		await _press_interact()
		for _frame in 240:
			await physics_frame
			if game.inventory.count(item) > before:
				break
		await _frames(10)
		var gained: int = game.inventory.count(item) - before
		gains[item] = int(gains.get(item, 0)) + gained
		notes.append("%s +%d %s" % [id, gained, item])
	_check(int(gains.reef_stone) == 4, "cradle nest paid %d Reef Stone with the pickaxe, expected 4" % int(gains.reef_stone))
	_check(int(gains.berries) == 3, "cradle nest paid %d berries, expected 3" % int(gains.berries))
	service.call("refresh")
	await _frames(2)
	for row: Dictionary in rows:
		_check(service.call("node_for", str(row.id)) == null, "cradle row still resident after its one claim: " + str(row.id))
	return "CRADLE %s walked=%.0fm legs=%d off_trail=%.0fm steepest_off_trail=%.1fdeg reef_stone=+%d berries=+%d [%s]" % [
		CRADLE_POCKET, float(walked.metres), int(walked.legs), float(walked.spur_m), float(walked.spur_max_slope),
		int(gains.reef_stone), int(gains.berries), ", ".join(notes)]


## Places the trainer on `landing` (the one disclosed position write) and walks
## the planned route to within `tolerance` of `target`. Returns
## {metres, legs} or null after recording a failure.
func _walk_from(landing: Vector3, target: Vector3, tolerance: float, label: String) -> Variant:
	var deck: float = world.call("ground_height_at", landing.x, landing.z)
	player.global_position = Vector3(landing.x, maxf(deck, landing.y) + 0.3, landing.z)
	player.velocity = Vector3.ZERO
	await _frames(60)
	var plan := plan_route(world, Vector2(landing.x, landing.z), Vector2(target.x, target.z))
	var route: Array[Vector2] = plan.points
	if not _check(route.size() >= 1, "%s: no dry route over the baked ground from %s to %s" % [label, landing, target]):
		return null
	var metres := 0.0
	var last := player.global_position
	for index in route.size():
		var point: Vector2 = route[index]
		var final := index == route.size() - 1
		var goal := Vector3(point.x, 0.0, point.y)
		var budget := maxi(900, int(Vector2(player.global_position.x, player.global_position.z).distance_to(point) * 90.0))
		var arrived: bool = await navigator.walk_to(goal, budget, tolerance if final else 1.8)
		metres += Vector2(last.x, last.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		last = player.global_position
		if not arrived:
			_check(false, "%s: walk stalled at leg %d/%d player=%s goal=%s swimming=%s" % [
				label, index + 1, route.size(), player.global_position, goal, _swimming()])
			_stick(0.0, 0.0)
			return null
	_stick(0.0, 0.0)
	await _frames(20)
	return {"metres": metres, "legs": route.size(), "spur_m": float(plan.spur_m), "spur_max_slope": float(plan.spur_max_slope)}


## Steps toward the body until the arbiter's winning provider is `prompt`.
func _approach_prompt(prompt: Node, at: Vector3) -> bool:
	if prompt == null:
		return false
	for _frame in 600:
		await physics_frame
		if arbiter.call("winning_provider") == prompt:
			_stick(0.0, 0.0)
			await _frames(4)
			if arbiter.call("winning_provider") == prompt:
				return true
		var flat := Vector3(at.x - player.global_position.x, 0.0, at.z - player.global_position.z)
		if flat.length() < 0.5:
			_stick(0.0, 0.0)
			continue
		navigator.call("push_once", flat.normalized() * 0.45)
	_stick(0.0, 0.0)
	return false


## AStarGrid2D over baked heights, 2 m cells. A cell is walkable when it is
## dry and its baked slope (central difference at 1 m, the metric the unit
## test applies to the analytic field) is at most MAX_SLOPE_DEG. The island's
## authored graded land routes (`land_routes`, a 4 m trail) are always
## walkable and preferred: the route leaves the trail only for the spur to the
## pocket. Cells within 8 m of the landing are walkable (the deck stands over
## water), and so is the target's own neighbourhood. Static so the pocket
## capture tool frames the same approach. Returns {points, spur_m,
## spur_max_slope}: waypoints ending at `to`, the metres walked off the graded
## trail and the steepest off-trail cell.
static func plan_route(world: Node3D, from: Vector2, to: Vector2) -> Dictionary:
	var cfg: Dictionary = world.get("config")
	var heightfield: RefCounted = FIELD.new()
	var lo := Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2(MARGIN_M, MARGIN_M)
	var hi := Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2(MARGIN_M, MARGIN_M)
	# The whole island is searchable: a pocket may be reached around its far side.
	var island_id: String = heightfield.island_id_at(to.x, to.y)
	for island: Dictionary in cfg.islands:
		if str(island.id) == island_id:
			var centre := Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
			var reach := float(island.shore_radius_m) + 20.0
			lo = Vector2(minf(lo.x, centre.x - reach), minf(lo.y, centre.y - reach))
			hi = Vector2(maxf(hi.x, centre.x + reach), maxf(hi.y, centre.y + reach))
	var size := Vector2i(ceili((hi.x - lo.x) / CELL_M) + 1, ceili((hi.y - lo.y) / CELL_M) + 1)
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	# One-metre lattice: cell (i, j) is lattice point (2i, 2j).
	var fine := Vector2i(size.x * 2 + 1, size.y * 2 + 1)
	var heights := PackedFloat32Array()
	heights.resize(fine.x * fine.y)
	for j in fine.y:
		for i in fine.x:
			var w := lo + Vector2(i, j) * (CELL_M * 0.5)
			heights[j * fine.x + i] = float(world.call("ground_height_at", w.x, w.y))
	var off_trail := {}
	var segments: Array = []
	for route: Dictionary in cfg.land_routes:
		var line: Array = route.polyline
		for k in line.size() - 1:
			segments.append([Vector2(float(line[k][0]), float(line[k][2])), Vector2(float(line[k + 1][0]), float(line[k + 1][2])),
				float(route.get("width_m", 4.0)) * 0.5 + 1.0])
	for j in size.y:
		for i in size.x:
			var w := lo + Vector2(i, j) * CELL_M
			if w.distance_to(from) <= 8.0 or w.distance_to(to) <= 2.5:
				continue
			var fi := i * 2
			var fj := j * 2
			var h := heights[fj * fine.x + fi]
			var solid := not is_finite(h) or h < DRY_M
			var slope := 0.0
			if not solid and fi > 0 and fj > 0 and fi < fine.x - 1 and fj < fine.y - 1:
				var gx := (heights[fj * fine.x + fi + 1] - heights[fj * fine.x + fi - 1]) * 0.5
				var gz := (heights[(fj + 1) * fine.x + fi] - heights[(fj - 1) * fine.x + fi]) * 0.5
				slope = rad_to_deg(atan(sqrt(gx * gx + gz * gz)))
				solid = slope > MAX_SLOPE_DEG
			var trail := false
			if is_finite(h) and h >= DRY_M:
				for segment: Array in segments:
					if w.distance_to(Geometry2D.get_closest_point_to_segment(w, segment[0], segment[1])) <= float(segment[2]):
						trail = true
						break
			if trail:
				solid = false
				slope = 0.0
			grid.set_point_solid(Vector2i(i, j), solid)
			if not solid and not trail:
				off_trail[Vector2i(i, j)] = slope
			if not solid:
				grid.set_point_weight_scale(Vector2i(i, j), 1.0 if trail else 1.5 + pow(slope / 20.0, 2.0))
	var a := Vector2i(roundi((from.x - lo.x) / CELL_M), roundi((from.y - lo.y) / CELL_M))
	var b := Vector2i(roundi((to.x - lo.x) / CELL_M), roundi((to.y - lo.y) / CELL_M))
	var cells := grid.get_id_path(a, b)
	var out: Array[Vector2] = []
	var spur_m := 0.0
	var spur_max_slope := 0.0
	if cells.is_empty():
		return {"points": out, "spur_m": 0.0, "spur_max_slope": 0.0}
	for index in range(1, cells.size()):
		var cell: Vector2i = cells[index]
		if not off_trail.has(cell):
			continue
		spur_m += Vector2(cells[index] - cells[index - 1]).length() * CELL_M
		spur_max_slope = maxf(spur_max_slope, float(off_trail[cell]))
	for index in range(WAYPOINT_EVERY, cells.size() - 1, WAYPOINT_EVERY):
		out.append(lo + Vector2(cells[index]) * CELL_M)
	out.append(to)
	return {"points": out, "spur_m": spur_m, "spur_max_slope": spur_max_slope}


func _landing(island_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF


func _landing_id(island_id: String) -> String:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			return str(anchor.id)
	return "?"


func _swimming() -> bool:
	var swim: Node = player.get("swim_controller")
	return swim != null and bool(swim.call("is_swimming"))


func _on_refused(code: String, reason: String) -> void:
	_refusal = "%s: %s" % [code, reason]


func _tap(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(8)


func _press_interact() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(3)


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	return condition


func _fail(message: String) -> void:
	failures.append(message)
	print("FAIL: ", message)


func _finish() -> void:
	if finished:
		return
	finished = true
	_stick(0.0, 0.0)
	print("Water pocket walk-claim smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
