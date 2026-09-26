extends "res://tests/helpers/net_harness.gd"

# peers: 3

## Owner ruling 2026-09-26, "rejoin returns to exact spot" (MULTIPLAYER
## Return-home placement). Three real processes on the shipping title, Session
## and JoinDriver:
##
##   peer 0 hosts world A; peer 1 hosts world B (a different world instance);
##   peer 2, the guest, joins A through the production title as a new
##   character, walks away from the regional spawn, saves and leaves;
##   it rejoins A through the title's returning route and must stand where it
##   saved (the same host world: matching instance);
##   it then saves, leaves and joins B, where it must get B's regional spawn
##   (a different world: the saved pose belongs to A).

const GUEST_NAME := "Wren"
const GUEST_APPEARANCE := "sera"
## How far from the new-game landing the guest walks before saving (x, z
## metres): well clear of it and of the returning regional spawn near the origin.
const AWAY := Vector2(-40.0, -35.0)
## A seated pose is the saved position; the physics settle may move it a little.
const EXACT_TOLERANCE_M := 1.5
## A regional spawn must be clearly NOT the saved spot.
const REGIONAL_MIN_M := 10.0
const DECIDE_FRAMES := 600


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(3, "world"):
		quit(await finish())
		return
	var port_a := int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	var port_b := int(((_peers[1] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(port_a > 0 and port_b > 0 and port_a != port_b, "two hosts on two ports (%d, %d)" % [port_a, port_b])
	check(_passed(await step(0, "host", {"port": port_a})), "host A opened its world")
	check(_passed(await step(1, "host", {"port": port_b})), "host B opened its world")

	# --- first visit to A: a new character, then a walk away from spawn --------
	var first: Dictionary = await step(2, "production_join", {"host": "127.0.0.1", "port": port_a,
		"returning_route": false, "budget_frames": 6000,
		"character": {"appearance_id": GUEST_APPEARANCE, "display_name": GUEST_NAME}}, 12000)
	check(_passed(first), "the guest joined host A through the production title (%s)" % str(first.get("detail", "")))
	var in_a := await _rejoin(2)
	var instance_a := str(in_a.get("world_instance", ""))
	check(not instance_a.is_empty(), "host A's world has an instance id (%s)" % instance_a)
	var spawn := await _position(2)
	check(spawn.size() == 3, "the guest stands at A's regional spawn %s" % str(spawn))
	if spawn.size() != 3:
		quit(await finish())
		return
	var away := [float(spawn[0]) + AWAY.x, float(spawn[1]) + 6.0, float(spawn[2]) + AWAY.y]
	check(_passed(await step(2, "teleport", {"at": away, "settle": 120})), "the guest moved away from spawn")
	var saved_at := await _position(2)
	check(_flat(saved_at, spawn) > REGIONAL_MIN_M,
		"it now stands %.1f m from the landing" % _flat(saved_at, spawn))
	var identity := _as_dict(await probe(2, "player_identity"))
	var character_id := str(identity.get("character_id", ""))
	check(_passed(await step(2, "save_character_here", {})), "the guest saved its character in world A")
	var on_disk := await _rejoin(2)
	check(str(on_disk.get("file_instance", "")) == instance_a,
		"its character file names world A's instance (%s)" % str(on_disk.get("file_instance", "")))
	var file_at: Array = _as_dict(on_disk.get("file_pose", {})).get("position", []) as Array
	check(file_at.size() == 3 and _flat(file_at, saved_at) < 0.01,
		"and the pose it saved there %s" % str(file_at))
	check(_passed(await step(2, "leave", {"reason": "rejoin_pose_smoke"})), "the guest left world A")
	check(_passed(await step(0, "expect_peers", {"count": 1}, 900)), "host A is alone again")

	# --- rejoin A: the same host world -> the exact saved spot -----------------
	var back: Dictionary = await step(2, "production_join", {"host": "127.0.0.1", "port": port_a,
		"returning_route": true, "budget_frames": 6000,
		"character": {"character_id": character_id, "display_name": GUEST_NAME}}, 12000)
	check(_passed(back), "the guest rejoined A through the title's returning route (%s)" % str(back.get("detail", "")))
	var rejoined := await _decided(2)
	check(str(rejoined.get("outcome", "")) == "exact",
		"host A's snapshot instance matches, so the saved pose is seated (%s)" % str(rejoined))
	var placed_a: Array = rejoined.get("placed_at", []) as Array
	check(_flat(placed_a, saved_at) > REGIONAL_MIN_M,
		"before seating, A's world had placed it at its regional spawn %s, %.1f m away"
		% [str(placed_a), _flat(placed_a, saved_at)])
	var at_a := await _position(2)
	check(_flat(at_a, saved_at) <= EXACT_TOLERANCE_M,
		"SAME HOST: the guest stands %.2f m from where it saved (tolerance %.1f m)"
		% [_flat(at_a, saved_at), EXACT_TOLERANCE_M])
	check(_passed(await step(0, "expect_peers", {"count": 2}, 900)), "host A sees the guest again")

	# --- join B: a different world -> B's regional spawn ------------------------
	check(_passed(await step(2, "save_character_here", {})), "the guest saved again in world A")
	check(_passed(await step(2, "leave", {"reason": "rejoin_pose_smoke"})), "the guest left world A again")
	var to_b: Dictionary = await step(2, "production_join", {"host": "127.0.0.1", "port": port_b,
		"returning_route": true, "budget_frames": 6000,
		"character": {"character_id": character_id, "display_name": GUEST_NAME}}, 12000)
	check(_passed(to_b), "the guest joined host B as the same character (%s)" % str(to_b.get("detail", "")))
	var in_b := await _decided(2)
	check(str(in_b.get("world_instance", "")) != instance_a and not str(in_b.get("world_instance", "")).is_empty(),
		"host B's world is a different instance (%s vs %s)" % [str(in_b.get("world_instance", "")), instance_a])
	check(str(in_b.get("outcome", "")) == "regional",
		"a different world keeps the regional spawn (%s)" % str(in_b))
	var at_b := await _position(2)
	check(_flat(at_b, saved_at) > REGIONAL_MIN_M,
		"DIFFERENT HOST: the guest is %.1f m from A's saved spot, not seated there" % _flat(at_b, saved_at))
	var placed_b: Array = in_b.get("placed_at", []) as Array
	check(_flat(placed_b, saved_at) > REGIONAL_MIN_M and _flat(at_b, placed_b) <= EXACT_TOLERANCE_M,
		"it stands at B's regional spawn %s (%.2f m from it)" % [str(placed_b), _flat(at_b, placed_b)])

	quit(await finish())


## Poll the rejoin decision until the helper has made one.
func _decided(peer: int) -> Dictionary:
	var last: Dictionary = {}
	for _i in DECIDE_FRAMES / 30:
		last = await _rejoin(peer)
		if not str(last.get("outcome", "")).is_empty():
			return last
		for _f in 30:
			await process_frame
			_pump_once()
	return last


func _rejoin(peer: int) -> Dictionary:
	return _as_dict(await probe(peer, "rejoin_pose"))


func _position(peer: int) -> Array:
	var value: Variant = await probe(peer, "position")
	return value as Array if value is Array else []


func _flat(a: Array, b: Array) -> float:
	if a.size() < 3 or b.size() < 3:
		return INF
	return Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length()


func _passed(result: Variant) -> bool:
	return result is Dictionary and str((result as Dictionary).get("verdict", "")) == "PASS"


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
