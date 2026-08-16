extends SceneTree

## SE23 scratch probe: the ground the Tether Relay Station has to stand on.
##
##   godot --headless --path . --script tools/_probe_relay_site.gd
##
## The site centre and bearing are NOT chosen here — they are adopted from
## `data/config/relay_site.json` (SE25/SE27's file, which asked SE23 to adopt
## rather than pick a second coordinate). What this answers is the question a
## compound cannot be authored without: how far the ground moves across the
## footprint, so walls, walkways and the apparatus pad are sited on measured
## numbers rather than on guesses. Same reason `_probe_ground.gd` exists and
## the terrain flats carry explicit heights.
##
## Printed in the site's OWN frame: `s` runs along the approach bearing
## (positive = deeper into the site, the direction the conduits and the road
## already walk toward the stronghold), `t` runs across it.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const CENTRE := Vector2(108.0, 34.0)
const BEARING_DEG := -34.4


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	# The same (s, t) basis tether_relay.gd builds in: `u` along the approach,
	# `p` across it.
	var u := Vector2(0.565, -0.826).normalized()
	var p := Vector2(-u.y, u.x)
	print("site centre %s, approach bearing %.1f deg, u=%s p=%s" % [CENTRE, BEARING_DEG, u, p])

	var header := "  s\\t "
	var ts := [-18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0]
	for t: float in ts:
		header += "%8.0f" % t
	print(header)
	var s := -24.0
	while s <= 22.0:
		var row := "%5.0f" % s
		for t: float in ts:
			var at := CENTRE + u * s + p * t
			row += "%8.2f" % float(field.call("height_at", at.x, at.y))
		print(row)
		s += 4.0

	# The five occupied points SE25/SE27 already authored, in world metres, so
	# nothing this file builds is sited on top of a person.
	print("")
	for entry: Array in [
		["picket Hess", 96.5, 49.0],
		["picket Orrin", 102.0, 42.0],
		["officer Dell", 105.5, 37.5],
		["captain", 110.0, 31.0],
		["captive Sela", 114.0, 27.0],
	]:
		var x := float(entry[1])
		var z := float(entry[2])
		var d := Vector2(x, z) - CENTRE
		print("%-14s world [%.1f, %.1f]  s=%6.2f t=%6.2f  ground %.2f" % [
			entry[0], x, z, d.dot(u), d.dot(p), float(field.call("height_at", x, z))])
	quit(0)
