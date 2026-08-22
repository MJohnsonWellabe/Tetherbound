extends SceneTree

## D4/prompt-65 scratch probe: real ground heights and local slope for the
## new Band 4 content (Ironwood grove, the special Tuskroot/night-Duskhush
## site, the patrol-camp dressing near the watchtower spur, and a field-camp
## clearing between the two captains), so every new position in
## data/config/bands/band4_upper_meadows_ironwood/*.json is measured rather
## than guessed. Same pattern as tools/_probe_upper_meadows.gd; no terrain
## bake is touched. Run with:
##   godot --headless --path . --script tools/_probe_band4_sites.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var _field: RefCounted = null


func _slope_deg(x: float, z: float, r: float = 1.0) -> float:
	var h := float(_field.call("height_at", x, z))
	var worst := 0.0
	for off: Vector2 in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		var d: float = absf(float(_field.call("height_at", x + off.x, z + off.y)) - h)
		worst = maxf(worst, rad_to_deg(atan2(d, r)))
	return worst


func _pad(x: float, z: float, r: float) -> Array:
	var lo := 1e9
	var hi := -1e9
	var worst := 0.0
	for i in 16:
		var a := TAU * float(i) / 16.0
		for rr: float in [r * 0.5, r]:
			var px := x + cos(a) * rr
			var pz := z + sin(a) * rr
			var h := float(_field.call("height_at", px, pz))
			lo = minf(lo, h)
			hi = maxf(hi, h)
			worst = maxf(worst, _slope_deg(px, pz))
	var c := float(_field.call("height_at", x, z))
	lo = minf(lo, c)
	hi = maxf(hi, c)
	worst = maxf(worst, _slope_deg(x, z))
	return [c, hi - lo, worst]


func _report(label: String, x: float, z: float, r: float) -> void:
	var out := _pad(x, z, r)
	print("%-28s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- ironwood grove candidates, old-growth western swing (pad r=3m) ---")
	for c: Array in [
		["iron 1", -340.0, 5030.0], ["iron 2", -355.0, 5045.0], ["iron 3", -365.0, 5065.0],
		["iron 4", -350.0, 5075.0], ["iron 5", -335.0, 5060.0], ["iron 6", -375.0, 5090.0],
		["iron 7", -320.0, 5010.0], ["iron 8", -380.0, 5110.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 3.0)
	print("--- special encounter (tuskroot) + night duskhush, same grove (pad r=6m) ---")
	for c: Array in [
		["special A", -300.0, 5100.0], ["special B", -285.0, 5080.0],
		["special C", -310.0, 5120.0], ["special D", -270.0, 5060.0],
		["night A", -260.0, 5220.0], ["night B", -245.0, 5250.0], ["night C", -280.0, 5270.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 6.0)
	print("--- patrol camp / watchtower ruin dressing (pad r=5m) ---")
	for c: Array in [
		["patrol A", -250.0, 6480.0], ["patrol B", -260.0, 6500.0],
		["patrol C", -235.0, 6470.0], ["patrol D", -245.0, 6520.0],
		["patrol E", -300.0, 6440.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 5.0)
	print("--- field camp clearing between captains (pad r=6m) ---")
	for c: Array in [
		["camp A", 400.0, 6040.0], ["camp B", 380.0, 6060.0], ["camp C", 420.0, 6010.0],
		["camp D", 390.0, 6000.0], ["camp E", 230.0, 6140.0], ["camp F", 250.0, 6120.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 6.0)
	print("--- optional trainer, wind ridge traverse (pad r=6m) ---")
	for c: Array in [
		["scout A", 370.0, 5960.0], ["scout B", 350.0, 5920.0], ["scout C", 390.0, 5940.0],
		["scout D", 330.0, 5880.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 6.0)
	quit(0)
