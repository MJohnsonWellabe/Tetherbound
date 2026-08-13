extends SceneTree

## EV7-remainder scratch probe: ground heights for candidate trainer-camp
## and bridge-repair-site cluster anchors, so placement uses real numbers
## instead of guesses (same reasoning as EV6-remainder's _probe_ground.gd).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	print("-- trainer camp candidates (off the practice-meadow path, segment [18,-24]->[30,-40]) --")
	for site: Array in [
		["camp A", 26.0, -28.0],
		["camp B", 22.0, -33.0],
		["camp C", 24.0, -30.5],
	]:
		var cx := float(site[1])
		var cz := float(site[2])
		var hs := []
		for off: Vector2 in [Vector2.ZERO, Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5)]:
			hs.append(float(field.call("height_at", cx + off.x, cz + off.y)))
		print("%s [%.1f,%.1f]  centre %.2f  corners %.2f %.2f %.2f %.2f" % [site[0], cx, cz, hs[0], hs[1], hs[2], hs[3], hs[4]])

	print("-- bridge repair site candidates (off the footbridge, [-136.3,113] yaw -5) --")
	for site: Array in [
		["repair A (west bank, south of deck)", -142.5, 115.5],
		["repair B (west bank, north of deck)", -142.0, 110.5],
		["repair C (west bank, tighter)", -140.5, 116.0],
	]:
		var cx := float(site[1])
		var cz := float(site[2])
		var hs := []
		for off: Vector2 in [Vector2.ZERO, Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
			hs.append(float(field.call("height_at", cx + off.x, cz + off.y)))
		print("%s [%.1f,%.1f]  centre %.2f  corners %.2f %.2f %.2f %.2f" % [site[0], cx, cz, hs[0], hs[1], hs[2], hs[3], hs[4]])
	quit(0)
