extends "res://tests/test_case.gd"

## F06: Cloudreach never offers or starts a ride on a companion that is falling
## over open air.
##
## Found by `tests/smoke_net_cloudreach_riding.gd` (2026-09-26). After a
## dismount on a live crossing's 7 m road ribbon, the companion walked back to
## its follower station, which was past the ribbon's edge, and stepped off.
## The guest pressed Ride a few frames later: `mount()` took the falling body
## (on_floor false, velocity -7.6 m/s, 2 m past the edge), the rider went down
## with it, and the mounted-fall recovery found no supported ground to return
## to (the ride's only reference was the take-off point in the air), so the
## ride ended about 100 m down. The trainer was carried off a cliff by pressing
## Ride.
##
## The rule lives in `cloudreach_riding_controller.gd::_mountable_body()`, so
## the Ride prompt and `mount()` agree: a companion that is off the floor AND
## has no walkable floor within the controller's probe under it is not
## mountable. A hop or an edge flicker (off the floor but over ground) is
## still mountable. The two physics reads (`_body_on_floor`, `_floor_under`)
## are seams, stubbed here, because `run_tests.gd` has no scene tree.

const CLOUDREACH_RIDING := preload("res://scripts/world/cloudreach_riding_controller.gd")
const MOUNT_SPECIES := "meadowhart"


class FakeEncounter extends Node:
	var body: Node3D = null

	func ally_body() -> Node3D:
		return body

	func ally_instance() -> RefCounted:
		return null


class FakeMount extends CharacterBody3D:
	var species_id := MOUNT_SPECIES


## The real Cloudreach controller with only its two physics reads stubbed.
class Probed extends "res://scripts/world/cloudreach_riding_controller.gd":
	var on_floor := true
	var floor_y := NAN

	func _body_on_floor(_body: Node3D) -> bool:
		return on_floor

	func _floor_under(_body: Node3D) -> float:
		return floor_y


var _riding: Node = null
var _encounter: FakeEncounter = null
var _mount: FakeMount = null


func before_each() -> void:
	_riding = Probed.new()
	_encounter = FakeEncounter.new()
	_mount = FakeMount.new()
	_mount.position = Vector3(-22.6, 108.6, -194.3)
	_encounter.body = _mount
	_riding.set("_encounter", _encounter)


func after_each() -> void:
	_riding.free()
	_encounter.free()
	_mount.free()


func test_a_standing_companion_is_mountable() -> void:
	_riding.set("on_floor", true)
	_riding.set("floor_y", 108.5)
	assert_true(_riding.call("_mountable_body") == _mount,
		"a saddled Meadowhart standing on the floor must be offered and mountable")


func test_a_companion_falling_over_open_air_is_not_mountable() -> void:
	_riding.set("on_floor", false)
	_riding.set("floor_y", NAN)
	assert_true(_riding.call("_mountable_body") == null,
		"a companion off the floor with no floor under it (stepped off an edge) must not be offered or mounted")


func test_a_hop_over_ground_is_still_mountable() -> void:
	# Off the floor for a frame (a hop, a step down, an edge flicker) but with
	# walkable floor inside the probe: a press there is an ordinary press.
	_riding.set("on_floor", false)
	_riding.set("floor_y", 107.9)
	assert_true(_riding.call("_mountable_body") == _mount,
		"a companion mid-hop over ground must stay mountable, or a press during a flicker is lost")
