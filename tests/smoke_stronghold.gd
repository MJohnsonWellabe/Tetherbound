extends SceneTree

## R8.2/SG38: is the stronghold route a real place you can walk, in order?
##
##   godot --headless --path . --script tests/smoke_stronghold.gd
##
## Same argument `smoke_warrens.gd` makes for the dungeon, and the same shape.
## A route built from primitive boxes either has floors a CharacterBody3D can
## stand on, walls it cannot walk through and doorways it can, or it is a
## diorama the player falls out of — and the only way to tell those apart is to
## boot the world, stand in it and push.
##
## What it asserts, in the order the player meets it:
##
##   * the complex built, with spec §8's five spaces in §8's order
##   * every one of the five has a floor the player actually stands on
##   * they are traversable IN ORDER: pushed from each space toward the next,
##     the player arrives — including the corner into the Legendary Chamber
##   * OP-0905-14: EVERY chamber's exit is shut before its own trainer falls
##     and open after, so each fight in the gauntlet is genuinely mandatory,
##     not just the Warden's
##   * each gauntlet trainer is placed in its own space and is challengeable
##   * the recovery point is a real creature bed and really revives and heals
##   * the Legendary Chamber holds the machine massing, at the board's scale,
##     and reports itself as the PLACEHOLDER it is
##
## Nobody is FOUGHT here. `smoke_trainer_battle.gd` is the test that pilots a
## trainer fight end to end and re-running it three times would be three copies
## of that coverage plus ten minutes of CI. What this proves is that the route
## exists, that its fights are reachable and challengeable in order, and that
## the door between them is real.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")

const SETTLE_FRAMES := 240
## 600 physics frames at 4 m/s is 40m of walking — the longest hop ON THE
## ROUTE ITSELF (the outer works to the courtyard) is 32m centre to centre. A
## budget that merely ALMOST covers the distance reads as a wall in the
## report, which is exactly how the first run of this test mis-reported two
## perfectly good doorways.
const PUSH_FRAMES := 600
## T1-HALL (2026-08-30): the entrance-to-outer-works hop is NOT a route hop —
## it is the approach ramp, and `HALL_DESIGN_2026-08-30.md` §2 deliberately
## lengthened `stronghold.json`'s `site.ramp_run` 26 -> 40 (a real ~14.5° climb
## to a real fortress, re-derived against the re-sited ground, replacing a
## shorter ramp authored before the re-site). That took the entrance-to-
## outer-works distance from ~38m to ~53.5m, past what `PUSH_FRAMES` above
## budgets — this smoke test's own walk-in check started reporting the ramp
## as a wall 14.6m short of the works, when the ramp itself was never the
## defect: `PUSH_FRAMES` was tuned against the OLD ramp length, not this one.
## `ENTRANCE_PUSH_FRAMES` gives the entrance walk-in its own, larger budget
## (comfortable margin over the measured 53.5m at ~3.9 m/s effective speed on
## the incline) without changing `PUSH_FRAMES` for every chamber-to-chamber
## hop this file also drives with it.
const ENTRANCE_PUSH_FRAMES := 950

## §8's five spaces, in §8's order. Hard-coded HERE on purpose: this is the one
## thing in the item that is not tunable, and a test that read the order out of
## the same config the builder reads could not catch it being reordered.
const ROUTE := ["outer_works", "courtyard", "tether_approach", "warden_arena", "legendary_chamber"]
const STRONGHOLD_CONFIG := "res://data/config/stronghold.json"

## OP-0905-14 (owner playtest 2026-09-05): "in the stronghold, you should have
## to fight every npc to advance to the next." Hard-coded HERE on purpose,
## same reasoning as `ROUTE` above: this is not a tunable, it is the whole
## point of the directive, so a test that only read "whichever hops the live
## config happens to gate" could pass just as happily on a config that quietly
## lost a shutter as on one that has all four -- which is exactly the gap that
## let three of these four gates go unbuilt in the first place. Keyed by
## "from>to" against `_gate_flag()`'s own two-argument shape.
const EXPECTED_GATES := {
	"outer_works>courtyard": "defeated_stronghold_patrol",
	"courtyard>tether_approach": "defeated_stronghold_courtyard",
	"tether_approach>warden_arena": "defeated_stronghold_elite",
	"warden_arena>legendary_chamber": "defeated_warden",
}

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

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if player == null or hold == null:
		print("stronghold FAIL: the scene has no Player or no Stronghold node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		print("stronghold FAIL: no Game autoload with a progression store")
		quit(1)
		return
	# A fresh stronghold, whatever a save left behind — every shutter down,
	# not just the elite's (OP-0905-14: every chamber's exit is gated now).
	for flag in _all_gate_flags():
		progression.call("set_flag", flag, false)

	print("stronghold stands at %.0f, %.1f, %.0f" % [
		hold.global_position.x, hold.global_position.y, hold.global_position.z])

	_the_five_spaces_exist_in_order(hold)
	await _the_player_stands_on_every_floor(player, hold)
	await _the_way_in_is_walkable(player, hold)
	_the_gauntlet_is_placed_and_challengeable(world, hold)
	_the_recovery_point_revives_and_heals(hold)
	_the_machine_stands_in_the_legendary_chamber(hold)
	_the_legendary_is_bound_inside_the_machine(world, hold)
	_the_machine_faces_the_doorway(world, hold)
	_the_hall_is_lit_by_torches(hold)
	await _the_route_is_traversable_in_order(player, hold, progression)

	print("")
	if _failures.is_empty():
		print("stronghold smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## §8 names five spaces and names them in one order. Nothing else in the item
## is allowed to reorder them.
func _the_five_spaces_exist_in_order(hold: Node3D) -> void:
	var route: Array = hold.call("route")
	print("route: %s" % " -> ".join(route))
	if route.size() != ROUTE.size():
		_fail("the stronghold has %d spaces; spec §8 names %d" % [route.size(), ROUTE.size()])
	for i in mini(route.size(), ROUTE.size()):
		if str(route[i]) != ROUTE[i]:
			_fail("space %d is '%s'; spec §8 puts '%s' there" % [i + 1, str(route[i]), ROUTE[i]])
	for id: String in ROUTE:
		var size: Vector3 = hold.call("chamber_size", id)
		if size.x < 6.0 or size.y < 6.0 or size.z < 3.0:
			_fail("'%s' is %.0fx%.0fx%.0fm; that is not a space the player can fight in" % [
				id, size.x, size.y, size.z])
		else:
			print("  %-18s %.0f x %.0f m, %.0fm to the ceiling" % [id, size.x, size.y, size.z])


## A built floor above its own ground, five times over. The player is put down
## a little over each space's marker and has to settle ON it — not fall through
## the slab, and not land on the meadow several metres below.
func _the_player_stands_on_every_floor(player: CharacterBody3D, hold: Node3D) -> void:
	for id: String in ROUTE:
		# The middle of the Legendary Chamber is 15m of machine, so the floor
		# there is checked where a player actually gets to stand: the mark the
		# reveal is staged from.
		var at: Vector3 = hold.call("marker", "reveal_stand" if id == "legendary_chamber" else id)
		await _put_down(player, at + Vector3(0.0, 1.4, 0.0))
		var resting := player.global_position.y
		if not player.is_on_floor():
			_fail("the player does not stand on '%s''s floor" % id)
		if absf(resting - at.y) > 1.6:
			_fail("the player settled at y=%.2f in '%s', whose floor is y=%.2f" % [resting, id, at.y])
		print("  %-18s floor y=%.2f, player rests at y=%.2f" % [id, at.y, resting])


## The complex's floor stands above its own highest ground, which on this site
## is metres over the meadow at the west end. So the way in is a long sampled
## ramp, and the only question worth asking about a ramp is whether a capsule
## can actually climb it — `burrow_warrens.gd`'s apron exists because a 0.35m
## sill silently stopped a smoke test 1.4m short of an open cave mouth.
func _the_way_in_is_walkable(player: CharacterBody3D, hold: Node3D) -> void:
	var entrance: Vector3 = hold.call("marker", "entrance")
	var first: Vector3 = hold.call("marker", "outer_works")
	await _put_down(player, entrance + Vector3(0.0, 1.5, 0.0))
	var start := player.global_position
	await _push(player, (first - entrance).normalized(), ENTRANCE_PUSH_FRAMES)
	var reached := player.global_position.distance_to(first)
	print("walked %.1fm in from the entrance; %.1fm from the Outer Works' centre" % [
		start.distance_to(player.global_position), reached])
	if reached > 14.0:
		_fail("walking in from the entrance never reached the Outer Works (%.1fm short)" % reached)
	if absf(player.global_position.y - first.y) > 1.6:
		_fail("the player came in at y=%.2f but the works' floor is y=%.2f" % [
			player.global_position.y, first.y])


## SG38: three fights across the five spaces (the Warden himself is R8.3's
## fourth). Each has to be a body standing in its OWN space, offering a prompt,
## with a team and a defeat flag of its own.
func _the_gauntlet_is_placed_and_challengeable(world: Node, hold: Node3D) -> void:
	var trainers: Node3D = hold.call("trainers_node")
	if trainers == null:
		_fail("the stronghold placed no trainers at all; SG38's gauntlet is missing")
		return
	var director := world.get_node_or_null(^"EncounterDirector")
	var expected := {
		"stronghold_patrol": "outer_works",
		"stronghold_courtyard": "courtyard",
		"stronghold_elite": "tether_approach",
	}
	# The gauntlet's placer must hang where `trainer_npc.gd::_director()` can
	# see the fight: it looks the director up as `get_parent().get_node_or_null
	# ("EncounterDirector")`, so a placer parented under the Stronghold itself
	# finds nothing, quietly decides every trainer is unchallengeable, and
	# opens their DEFEATED conversation instead — three fights that greet you
	# politely and never happen. That shipped once and this assertion is why it
	# cannot ship twice. The check below it only PRINTS (a bare boot has no
	# living ally, so `can_challenge` is not meaningful here), which is exactly
	# how the bug got past this file the first time.
	var placer_host := trainers.get_parent()
	if placer_host == null or placer_host.get_node_or_null(^"EncounterDirector") == null:
		_fail("the gauntlet's placer hangs under '%s', which has no EncounterDirector sibling; "
			% (placer_host.name if placer_host != null else "<nothing>")
			+ "every trainer under it is silently unchallengeable")

	var placed := int(trainers.call("placed"))
	print("gauntlet: %d trainer(s) placed" % placed)
	if placed < 2 or placed > 4:
		_fail("the gauntlet fields %d trainers; §8/§12 ask for 2-4 across the five spaces" % placed)

	var flags := {}
	for id: String in expected:
		var body: Node3D = trainers.call("body_for", id) as Node3D
		if body == null:
			_fail("gauntlet trainer '%s' was never stood up" % id)
			continue
		var room: Vector3 = hold.call("marker", expected[id])
		var away := body.global_position.distance_to(room)
		var spec: Dictionary = TRAINERS.trainer(id)
		var team: Array = TRAINERS.team_of(spec)
		var flag := str(spec.get("defeat_flag", ""))
		print("  %-22s in %-16s (%.1fm from its centre), %d creature(s), flag '%s'" % [
			id, str(expected[id]), away, team.size(), flag])
		if away > 16.0:
			_fail("'%s' is %.1fm from the middle of '%s'; it is not in its own space" % [
				id, away, str(expected[id])])
		if team.is_empty():
			_fail("'%s' fields nobody; there is no fight there" % id)
		if flag == "":
			_fail("'%s' has no defeat_flag; beating them would change nothing" % id)
		elif flags.has(flag):
			_fail("'%s' shares a defeat flag with '%s'" % [id, str(flags[flag])])
		else:
			flags[flag] = id
		if body.get_node_or_null(^"Interactable") == null:
			_fail("'%s' offers no prompt; they cannot be challenged" % id)
		if director != null and not bool(director.call("can_challenge", spec)):
			# Only meaningful with a living ally, which this test does not set
			# up — reported, not failed, so the check stays honest about what
			# it actually proves. smoke_trainer_battle.gd owns the live path.
			print("    (not challengeable right now: no living ally in this bare boot)")


## SG38's recovery opportunity, and the one assertion that matters about it: a
## fainted, hurt creature comes back. `home_recovery.gd` is the shared logic and
## it is what the panel calls, so this drives the same function the player does.
func _the_recovery_point_revives_and_heals(hold: Node3D) -> void:
	var bed: Node3D = hold.call("recovery_point")
	if bed == null:
		_fail("there is no recovery point before the Warden")
		return
	var at: Vector3 = hold.call("marker", "recovery")
	var approach: Vector3 = hold.call("marker", "tether_approach")
	print("recovery point at %.0f, %.1f, %.0f (%.1fm into the Tether Chamber Approach)" % [
		at.x, at.y, at.z, at.distance_to(approach)])
	if at.distance_to(approach) > 14.0:
		_fail("the recovery point is not in the Tether Chamber Approach, where §8 puts it")
	if bed.get_node_or_null(^"Interactable") == null:
		_fail("the recovery point offers no interaction; it cannot be used")

	# GATE-E, two things this file used to take on trust about the authored bed
	# and both of which were wrong on `main`.
	#
	# It is a `creature_bed.gd`, and that class does two things a bed the PLAYER
	# places should do and this one must not: it announces itself as the
	# chapter's "Build a creature bed" objective, and it refuses every creature
	# until something hands it a build index. The stronghold's bed is built with
	# the world at boot, so the first cost `creature_bed_built` on frame one of
	# a brand-new save, and the second left SG38's one recovery opportunity
	# opening a panel that could not rest anything.
	#
	# `smoke_gateb_flags.gd` asserts the opposite of the first — that
	# `build_real` DOES set the flag — and stayed green throughout, because it
	# builds its bed on a bare FlatWorld with no stronghold in it. The real
	# world is the only place either defect is visible.
	var progression := _progression_store()
	if progression != null and bool(progression.call("has", "creature_bed_built")):
		_fail("the stronghold's own bed set 'creature_bed_built' at boot; a fresh save starts with "
			+ "the tournament ladder's bed objective already complete")
	if int(bed.call("build_index")) == -1:
		_fail("the recovery point has no bed index, so assign_creature() refuses every creature; "
			+ "the one rest before the Warden does nothing")

	var cfg := _progression_config()
	var creature: RefCounted = TRAINERS.creature_for({"species": "mudsnout", "level": 12})
	if creature == null:
		_fail("no mudsnout in species.json; the rest check cannot run")
		return
	creature.set("hp", 0.0)
	creature.set("fainted", true)
	var before_xp := int(creature.get("xp"))
	HOME_RECOVERY.rest(creature, cfg)
	print("rested a fainted level-12 mudsnout: fainted=%s hp=%d/%d, xp %d -> %d" % [
		str(creature.get("fainted")), int(creature.get("hp")), int(creature.get("max_hp")),
		before_xp, int(creature.get("xp"))])
	if bool(creature.get("fainted")):
		_fail("resting at the stronghold's recovery point did not revive a fainted creature")
	if int(creature.get("hp")) < int(creature.get("max_hp")):
		_fail("resting did not heal to full")


## OP-0904-8 (owner 2026-09-04): "The legendary should be in the machine not
## in a ring outside the machine." The bound creature stands INSIDE the
## machine's cage void, which `stronghold_climax.gd::_measure_cage` reads off
## the installed mesh: on the axis, above the dais, under the crown, and with
## the whole body under that crown. Asserted here, where the machine's own
## scale is asserted, because the two are one staging.
func _the_legendary_is_bound_inside_the_machine(world: Node, hold: Node3D) -> void:
	var climax: Node = world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("the world built no StrongholdClimax; nothing stands in the machine")
		return
	var legendary: Node3D = climax.call("legendary_body") as Node3D
	if legendary == null:
		_fail("the chamber has no bound legendary in it")
		return
	var measure: Dictionary = climax.call("cage_measure")
	if measure.is_empty():
		_fail("the climax measured no cage in the machine; the legendary is standing on its floor mark, outside")
		return
	var machine: Node3D = hold.call("machine")
	var axis: Vector3 = measure["axis"]
	var off := Vector2(legendary.global_position.x - axis.x, legendary.global_position.z - axis.z).length()
	var up := legendary.global_position.y - axis.y
	var dais := float(measure["dais_top"])
	var crown := float(measure["crown_under"])
	var body_top := up + float(legendary.call("body_height")) * 1.22
	print("bound legendary: %.2f m off the machine's axis, feet %.2f m up (dais %.2f, crown %.2f, void %.2f m), body top %.2f m" % [
		off, up, dais, crown, float(measure["void_height"]), body_top])
	if off > 1.0:
		_fail("the bound legendary stands %.2f m off the machine's axis; it is not inside the machine" % off)
	if up < dais - 0.05 or up > dais + 0.5:
		_fail("the bound legendary's feet are %.2f m up the machine; the dais is at %.2f m" % [up, dais])
	if body_top > crown + 0.05:
		_fail("the bound legendary's %.2f m body top pokes through the machine's crown at %.2f m" % [body_top, crown])
	if machine != null:
		# `_aabb_of` measures in the machine's OWN frame, so the point goes
		# into that frame too.
		var box := _aabb_of(machine)
		var local := machine.global_transform.affine_inverse() * (legendary.global_position + Vector3.UP * 0.5)
		if not box.has_point(local):
			_fail("the bound legendary is outside the machine's own bounds (local %s vs %s)" % [str(local), str(box)])
	if legendary.get_node_or_null(^"ContainmentVFX") == null:
		_fail("the bound legendary carries no containment VFX")


## OP-0905-16 (owner playtest 2026-09-05): "You can't see the legendary when
## you enter the chamber. The machine needs to be turned." Two things, both
## measured rather than trusted: the machine actually carries the authored
## `facing_deg` as a real `rotation.y` (not just a number sitting in JSON),
## and a straight line from just inside the doorway to the bound legendary's
## own chest is not blocked by the machine's VISIBLE geometry -- checked
## against the actual mesh triangles, not just the base collider, because
## `_build_machine`'s own header says the ring and the core are decoration
## with NO collider at all, so a physics raycast alone would pass even if the
## cage's solid pillars visually wall off the view.
func _the_machine_faces_the_doorway(world: Node, hold: Node3D) -> void:
	var machine: Node3D = hold.call("machine")
	if machine == null:
		_fail("no machine to check the facing of")
		return
	var config := _stronghold_config()
	var facing_deg := float((config.get("machine", {}) as Dictionary).get("facing_deg", 0.0))
	var got_deg := rad_to_deg(machine.rotation.y)
	print("machine facing: authored %.1f deg, built rotation.y %.1f deg" % [facing_deg, got_deg])
	if absf(wrapf(got_deg - facing_deg, -180.0, 180.0)) > 0.5:
		_fail("the machine's rotation.y is %.1f deg; stronghold.json's machine.facing_deg asks for %.1f" % [
			got_deg, facing_deg])

	var climax: Node = world.get_node_or_null(^"StrongholdClimax")
	var legendary: Node3D = climax.call("legendary_body") as Node3D if climax != null else null
	if legendary == null:
		_fail("no bound legendary to sight toward; the doorway sightline cannot be checked")
		return

	# Just inside the Legendary Chamber's own doorway (the +x wall -- see
	# `marks.machine_foot`'s own note), at eye height, looking across the room
	# the way the player actually walks in.
	var chamber: Dictionary = _chamber_by_id(config, "legendary_chamber")
	var centre := _local_of(chamber.get("at", []))
	var size := _size_of(chamber.get("size", []))
	var floor_pos: Vector3 = hold.call("marker", "legendary_chamber")
	var local_floor: Vector3 = hold.to_local(floor_pos)
	var doorway_local := Vector3(centre.x + size.x * 0.5 - 1.0, local_floor.y + 1.6, centre.z)
	var doorway: Vector3 = hold.to_global(doorway_local)

	var scale: float = float((config.get("legendary", {}) as Dictionary).get("scale", 1.0)) \
		if config.has("legendary") else 1.0
	# `stronghold_climax.json` (not this file's config) actually carries
	# `legendary.scale` -- read it there so this check does not silently drift
	# from the real figure if the two are ever tuned apart.
	var climax_config := _climax_config()
	scale = float((climax_config.get("legendary", {}) as Dictionary).get("scale", 1.22))
	var chest: Vector3 = legendary.global_position + Vector3.UP \
		* (float(legendary.call("body_height")) * scale * 0.55)

	var model: Node3D = machine.get_node_or_null(^"Model")
	if model == null:
		print("  (no installed Model mesh -- this run is on the primitive fallback, which has no solid cage wall to block the sightline)")
		return
	var hit := _ray_blocked_by_mesh(model, doorway, chest)
	print("doorway-to-legendary sightline: %.1fm, %s" % [
		doorway.distance_to(chest),
		("BLOCKED at %.1fm by the machine's own mesh" % float(hit["distance"])) if bool(hit["blocked"]) else "clear"])
	if bool(hit["blocked"]):
		_fail("the machine's mesh blocks the doorway-to-legendary sightline at %.1fm (of %.1fm); the cage's open side is not facing the doorway" % [
			float(hit["distance"]), doorway.distance_to(chest)])


## The bin a machine's config-declared chamber lives at, read straight off the
## JSON rather than through the built node (this file's own `chambers`
## dictionary is private to `stronghold.gd`).
func _chamber_by_id(config: Dictionary, id: String) -> Dictionary:
	for entry: Variant in config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		if str(chamber.get("id", "")) == id:
			return chamber
	return {}


func _climax_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/stronghold_climax.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Whether a straight segment from `from` to `to` crosses any triangle of any
## MeshInstance3D under `model` before it reaches `to` (with a small epsilon so
## grazing the target itself never counts as a block). `Mesh.get_faces()` at
## the mesh's own scale/transform is not reliable across import pipelines, so
## triangles are read from `surface_get_arrays()` directly and put through the
## mesh instance's own `global_transform`, the same technique
## `tools/_probe_tether_machine_facing.gd` and `stronghold_climax.gd::_to_machine`
## already use for this exact mesh.
func _ray_blocked_by_mesh(model: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var delta := to - from
	var dist := delta.length()
	if dist < 0.01:
		return {"blocked": false, "distance": 0.0}
	var dir := delta / dist
	var closest := INF
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var xform := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var use_index := idx.size() > 0
			var tri_count := (idx.size() / 3) if use_index else (verts.size() / 3)
			for t in tri_count:
				var i0 := idx[t * 3] if use_index else t * 3
				var i1 := idx[t * 3 + 1] if use_index else t * 3 + 1
				var i2 := idx[t * 3 + 2] if use_index else t * 3 + 2
				var a := xform * verts[i0]
				var b := xform * verts[i1]
				var c := xform * verts[i2]
				var hit = Geometry3D.ray_intersects_triangle(from, dir, a, b, c)
				if hit == null:
					continue
				var d: float = (hit as Vector3).distance_to(from)
				if d < dist - 0.15:
					closest = minf(closest, d)
	return {"blocked": closest < INF, "distance": closest if closest < INF else 0.0}


## OP-0905-19 ("The hall needs to be lit by torches"). The three roofed
## interior rooms on the route had no self-lit source of their own at all
## before this item -- just the cool ambient omnis `lights` already gives
## each. Checked two ways: every room actually has real flame lights inside
## its own box (not somewhere else in the building), and no room's total
## OMNI count (torches + its pre-existing ambient pair + the machine's own
## core light where it applies) breaches Godot's per-object cap of 8 -- the
## same cap `stronghold.json`'s own warm-spot comment in the Legendary
## Chamber measured a real light silently dropped against.
func _the_hall_is_lit_by_torches(hold: Node3D) -> void:
	var holder: Node3D = hold.get_node_or_null(^"HallBraziers")
	if holder == null:
		_fail("the Hall built no HallBraziers holder; there are no fires anywhere, torches included")
		return
	var fires: Array[OmniLight3D] = []
	for child in _all_children(holder):
		if child is OmniLight3D:
			fires.append(child as OmniLight3D)
	print("hall braziers: %d flickering light(s) total (interior + exterior)" % fires.size())

	var config := _stronghold_config()
	const OMNI_CAP := 8
	for id in ["tether_approach", "warden_arena", "legendary_chamber"]:
		var chamber := _chamber_by_id(config, id)
		var centre := _local_of(chamber.get("at", []))
		var half := _size_of(chamber.get("size", [])) * 0.5

		var torches := 0
		for fire in fires:
			var local: Vector3 = hold.to_local(fire.global_position)
			if absf(local.x - centre.x) <= half.x + 0.6 and absf(local.z - centre.z) <= half.y + 0.6:
				torches += 1

		var ambient := 0
		for entry: Variant in config.get("lights", []):
			var spec: Dictionary = entry as Dictionary
			if str(spec.get("type", "")) == "spot":
				continue # spots are on a separate Godot budget; never this cap
			var at := _local_of(spec.get("at", []))
			if absf(at.x - centre.x) <= half.x + 0.6 and absf(at.z - centre.z) <= half.y + 0.6:
				ambient += 1
		# The machine's own core OmniLight is on-axis inside the Legendary
		# Chamber and well within every other omni's range there; it counts
		# against the same room's cap even though it is not a `braziers` entry.
		var machine_core := 1 if id == "legendary_chamber" else 0
		var total := torches + ambient + machine_core
		print("  %-16s %d torch(es) + %d ambient omni(s)%s = %d omni(s) (cap %d)" % [
			id, torches, ambient, (" + the machine core" if machine_core > 0 else ""), total, OMNI_CAP])
		if torches < 4:
			_fail("'%s' has only %d torch light(s) inside its own box; OP-0905-19 wants the room actually lit" % [
				id, torches])
		if total > OMNI_CAP:
			_fail("'%s' totals %d omni lights; Godot's Compatibility renderer caps omnis affecting one mesh at %d" % [
				id, total, OMNI_CAP])


## The centrepiece, and the seam. This asserts the SCALE (which is real work and
## survives the asset swap) and asserts that the build still calls itself a
## placeholder (which is the honest part).
func _the_machine_stands_in_the_legendary_chamber(hold: Node3D) -> void:
	var machine: Node3D = hold.call("machine")
	if machine == null:
		_fail("the Legendary Chamber has no tether mechanism in it")
		return
	var chamber: Vector3 = hold.call("marker", "legendary_chamber")
	var away := machine.global_position.distance_to(chamber)
	var placeholder: bool = bool(hold.call("machine_is_placeholder"))
	var aabb := _aabb_of(machine)
	print("machine '%s': %.1fm from the chamber centre, bounding %0.1f x %0.1f x %0.1f m, placeholder=%s" % [
		machine.name, away, aabb.size.x, aabb.size.y, aabb.size.z, str(placeholder)])
	if away > 2.0:
		_fail("the machine is %.1fm off the middle of its own chamber" % away)
	if aabb.size.y < 12.0:
		_fail("the machine stands %.1fm tall; its board draws it at ~15m" % aabb.size.y)
	var room: Vector3 = hold.call("chamber_size", "legendary_chamber")
	if room.z < aabb.size.y + 3.0:
		_fail("the chamber's %.0fm ceiling does not clear its own %.1fm machine" % [room.z, aabb.size.y])
	if placeholder and machine.name != "TetherMachinePlaceholder":
		_fail("the machine is a placeholder but is not named as one; the seam is hidden")
	if not placeholder:
		print("  (the licensed hero asset is installed; this run is not testing the placeholder)")


## The route, walked. From each space's centre, push toward the next and check
## the player gets there — the doorway between them is either cut or it is
## not. OP-0905-14: EVERY hop is checked against `EXPECTED_GATES`, its own
## hard-coded flag (empty for none) — same reasoning `ROUTE` above already
## gives: the four-chamber gauntlet is the directive itself, not a tunable, so
## a check that only read "whichever hops the live config happens to gate"
## could pass just as happily on a config that quietly lost a shutter as on
## the real one. `_gate_flag()` still does the live reading (so a hop's
## ACTUAL behaviour, not just its config entry, is what gets pushed against),
## but every mismatch against `EXPECTED_GATES` fails loudly before that push
## ever happens.
func _the_route_is_traversable_in_order(player: CharacterBody3D, hold: Node3D,
		progression: RefCounted) -> void:
	for flag in _all_gate_flags():
		if bool(hold.call("door_is_open", flag)):
			_fail("the shutter gated by '%s' was already open before it was earned" % flag)

	for i in ROUTE.size() - 1:
		var from_id: String = ROUTE[i]
		var to_id: String = ROUTE[i + 1]
		var from: Vector3 = hold.call("marker", from_id)
		var to: Vector3 = hold.call("marker", to_id)
		var flag := _gate_flag(from_id, to_id)
		var expected := str(EXPECTED_GATES.get("%s>%s" % [from_id, to_id], ""))
		if flag != expected:
			_fail("expected '%s -> %s' to carry gated_by_flag '%s', found '%s'" % [
				from_id, to_id, expected, flag])
		var gated := flag != ""

		if gated:
			# Shut: pushing at it must NOT reach the next chamber.
			await _put_down(player, from + Vector3(0.0, 1.2, 0.0))
			await _push(player, (to - from).normalized())
			var blocked := player.global_position.distance_to(to)
			print("  %s -> %s with the shutter down: ended %.1fm short" % [from_id, to_id, blocked])
			if blocked < 6.0:
				_fail("the player reached '%s' with the shutter still down" % to_id)
			# Beaten, the way beating that chamber's own trainer beats it.
			progression.call("set_flag", flag)
			for f in 8:
				await process_frame
			if not bool(hold.call("door_is_open", flag)):
				_fail("the shutter did not lift once '%s' was set" % flag)

		await _put_down(player, from + Vector3(0.0, 1.2, 0.0))
		await _push(player, (to - from).normalized())
		var reached := player.global_position.distance_to(to)
		var half: Vector3 = hold.call("chamber_size", to_id)
		var allowed := maxf(half.x, half.y) * 0.5 + 2.0
		print("  %s -> %s: ended %.1fm from its centre (allowed %.1f)" % [
			from_id, to_id, reached, allowed])
		if reached > allowed:
			_fail("walking from '%s' toward '%s' never got there (%.1fm short)" % [
				from_id, to_id, reached])
		if not player.is_on_floor():
			_fail("the player left the floor walking from '%s' to '%s'" % [from_id, to_id])


## --- harness ---------------------------------------------------------------

## Measure by the FULL transform, not by position alone.
##
## This used to read `mesh.mesh.get_aabb()` and merely translate it, which is
## correct only while every mesh in the subject sits at scale 1 — true of the
## machine's primitive massing, and false the moment a generated GLB is dropped
## in and fitted to the authored height. The scale-blind version measured the
## installed hero mesh at its raw exported 1.7m and failed the build over a
## machine that was in fact standing at its full 15m. A measurement helper that
## silently ignores scale is worse than no helper: it fails honest work and
## would just as happily pass a mesh that really was too small.
func _aabb_of(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in _all_children(node):
		var mesh := child as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var into := node.global_transform.affine_inverse() * mesh.global_transform
		var here: AABB = into * mesh.mesh.get_aabb()
		if first:
			box = here
			first = false
		else:
			box = box.merge(here)
	return box


func _all_children(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_children(child))
	return out


func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


## Hold a direction for a fixed budget of physics frames, driving the body
## directly. Same technique — and the same suspension of the controller's own
## `_physics_process` — that `smoke_warrens.gd` documents: two `move_and_slide()`
## calls a frame with two different velocities is a race, and it showed up there
## as a push that travelled 1.4m through an open doorway.
func _push(player: CharacterBody3D, direction: Vector3, frames := PUSH_FRAMES) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	player.set_physics_process(false)
	for i in frames:
		player.velocity.x = flat.x * 4.0
		player.velocity.z = flat.z * 4.0
		player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 0.5
		player.move_and_slide()
		await physics_frame
	player.set_physics_process(true)


func _progression_store() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") as RefCounted if game != null else null


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## The same two conversions `stronghold.gd::_local_of`/`_size_of` apply to raw
## config arrays -- duplicated here (rather than called through `hold`, which
## does not expose them) because OP-0905-16/19's own checks read chamber `at`/
## `size` straight out of the JSON, the same way the builder does.
func _local_of(raw: Variant) -> Vector3:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector3.ZERO
	return Vector3(float(list[0]), 0.0, float(list[1]))


func _size_of(raw: Variant) -> Vector2:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector2(8.0, 8.0)
	return Vector2(float(list[0]), float(list[1]))


## OP-0905-14: read the gate straight from the same config the builder reads,
## rather than hard-coding which hops are gated — a test that assumed only
## the Warden's door carried a flag is exactly the gap that let the other
## three shutters go unbuilt in the first place.
func _stronghold_config() -> Dictionary:
	var file := FileAccess.open(STRONGHOLD_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## The flag gating the passage FROM `from_id` TO `to_id`, or "" if that hop
## carries no `gated_by_flag` at all.
func _gate_flag(from_id: String, to_id: String) -> String:
	for entry: Variant in _stronghold_config().get("passages", []):
		var passage: Dictionary = entry as Dictionary
		if str(passage.get("from", "")) == from_id and str(passage.get("to", "")) == to_id:
			return str(passage.get("gated_by_flag", ""))
	return ""


## Every flag any passage in the config is gated by, so `_run()` can put the
## stronghold back into its fully-shut starting state regardless of how many
## shutters exist.
func _all_gate_flags() -> Array[String]:
	var flags: Array[String] = []
	for entry: Variant in _stronghold_config().get("passages", []):
		var flag := str((entry as Dictionary).get("gated_by_flag", ""))
		if flag != "" and not flags.has(flag):
			flags.append(flag)
	return flags
