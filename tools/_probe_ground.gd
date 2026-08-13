extends SceneTree

## EV6-remainder scratch probe: raw ground heights around the stream's middle
## reach, to site the mill, its crossing and the ranger station on real
## numbers instead of guesses (the same reason terrain flats carry EXPLICIT
## heights — see terrain_playground.json's own comment on the 7.3m surprise).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	# The stream's own points, so the crossing spans a real reach.
	for z in [98.0, 104.0, 108.0, 110.0, 112.0, 116.0, 120.0]:
		var row := "z=%6.1f  " % z
		for x in [-146.0, -142.0, -138.0, -136.0, -134.0, -130.0, -126.0, -122.0, -118.0, -114.0, -110.0, -106.0]:
			row += "%7.2f" % float(field.call("height_at", x, z))
		print(row)
	print("      x:  -146   -142   -138   -136   -134   -130   -126   -122   -118   -114   -110   -106")
	# Candidate sites, centre + corners.
	for site: Array in [
		["mill @ [-130,107]", -130.0, 107.0, 4.0],
		["bridge @ [-136.5,111]", -136.5, 111.0, 4.0],
		["ranger @ [-100,100]", -100.0, 100.0, 3.5],
		["ranger @ [-96,106]", -96.0, 106.0, 3.5],
		["ranger @ [-108,104]", -108.0, 104.0, 3.5],
		["ranger @ [-92,96]", -92.0, 96.0, 3.5],
	]:
		var cx := float(site[1])
		var cz := float(site[2])
		var r := float(site[3])
		var hs := []
		for off: Vector2 in [Vector2.ZERO, Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
			hs.append(float(field.call("height_at", cx + off.x, cz + off.y)))
		print("%s  centre %.2f  corners %.2f %.2f %.2f %.2f" % [site[0], hs[0], hs[1], hs[2], hs[3], hs[4]])
	quit(0)
