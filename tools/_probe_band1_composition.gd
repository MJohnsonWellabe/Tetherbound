extends SceneTree

## BAND1-COMPOSITION-0903. Reads the analytic heightfield along the Band 1
## route so the composition plan can name real crests, dips and open
## sightlines instead of guessing them from the config. Headless only: this
## is arithmetic on `playground_heightfield.gd`, never a render.
##
##   godot --headless --path . --script tools/_probe_band1_composition.gd
##
## Prints, per 25m of arc along `trail.bands[0]`: ground height on the
## centreline, the lateral heights at +-15 / +-30 / +-60m (left/right of the
## direction of travel), and the water level, so a reader can see where the
## road climbs onto a shoulder, where it drops into the pond valley, and
## which side has the high ground for a framing element.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const TRAIL: Array = [
	Vector2(27.5, -16), Vector2(14, 20), Vector2(8, 90), Vector2(-40, 180),
	Vector2(-120, 270), Vector2(-230, 330), Vector2(-360, 400), Vector2(-430, 510),
	Vector2(-330, 590), Vector2(-190, 650), Vector2(-50, 700), Vector2(90, 760),
	Vector2(230, 830), Vector2(360, 910), Vector2(430, 1020), Vector2(330, 1130),
	Vector2(180, 1200), Vector2(30, 1250), Vector2(-40, 1310), Vector2(8.0, 1330),
	Vector2(0, 1360),
]

const STEP := 25.0
const OFFSETS: Array = [15.0, 30.0, 60.0]


func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	print("water level %.2f" % float(f.water_level()))
	print("arc      x       z     h    L15   L30   L60   R15   R30   R60   slope")
	var arc := 0.0
	var next_print := 0.0
	for i in range(TRAIL.size() - 1):
		var a: Vector2 = TRAIL[i]
		var b: Vector2 = TRAIL[i + 1]
		var seg := b - a
		var length := seg.length()
		var dir := seg / length
		var left := Vector2(-dir.y, dir.x)
		var t := 0.0
		while t < length:
			var here := arc + t
			if here >= next_print:
				var p := a + dir * t
				var h: float = f.height_at(p.x, p.y)
				var cols := []
				for side in [1.0, -1.0]:
					for off: float in OFFSETS:
						var q := p + left * (off * side)
						cols.append(float(f.height_at(q.x, q.y)))
				var ahead := p + dir * 10.0
				var slope: float = float(f.height_at(ahead.x, ahead.y)) - h
				print("%5.0f %7.1f %7.1f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f" % [
					here, p.x, p.y, h, cols[0], cols[1], cols[2], cols[3], cols[4], cols[5], slope])
				next_print += STEP
			t += 5.0
		arc += length
	# Named points the plan refers to.
	print("")
	print("named points:")
	var named := {
		"village square (0,0)": Vector2(0, 0),
		"road_gate (14,20)": Vector2(14, 20),
		"gate flank E anchor (20,50)": Vector2(20, 50),
		"gate flank W anchor (-5,95)": Vector2(-5, 95),
		"VP4 copse (45,58)": Vector2(45, 58),
		"first bend copse (-136,289)": Vector2(-136, 289),
		"first bend copse b (-95,292)": Vector2(-95, 292),
		"Rise hero TwistedTree (-224,336)": Vector2(-224, 336),
		"Rise dead-tree marker WORLD-TREES (-276,320)": Vector2(-276, 320),
		"cache + DeadTree_2 marker WORLD-CONTENT (-382.8,355.5)": Vector2(-382.8, 355.5),
		"shepherd Dara (-377,456.8)": Vector2(-377, 456.8),
		"pond centre (-395,545)": Vector2(-395, 545),
		"mill (-383.5,517)": Vector2(-383.5, 517),
		"ranger station (-350,507)": Vector2(-350, 507),
		"fisher camp (-395.5,583.5)": Vector2(-395.5, 583.5),
		"mosshell hollow (-490,555)": Vector2(-490, 555),
		"long field grove 1 (-120,650)": Vector2(-120, 650),
		"trail camp (344,935)": Vector2(344, 935),
		"Old Bram (195,905)": Vector2(195, 905),
		"long field grove 2 (5,1235)": Vector2(5, 1235),
		"tether waypost (156,1227)": Vector2(156, 1227),
		"fence start (81.9,1223)": Vector2(81.9, 1223.2),
		"fence end (22.4,1244.7)": Vector2(22.4, 1244.7),
		"grunt (14,1314)": Vector2(14, 1314),
		"south bridge (8,1330)": Vector2(8, 1330),
		"tutorial mound peak (140,-90)": Vector2(140, -90),
		"survey 03 eye (172,-88)": Vector2(172, -88),
	}
	for label: String in named:
		var p: Vector2 = named[label]
		print("  %-58s h=%6.2f" % [label, float(f.height_at(p.x, p.y))])
	quit(0)
