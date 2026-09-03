extends SceneTree

## OW5D prep. READ-ONLY: samples the LIVE repo's analytic heightfield
## (scripts/world/playground_heightfield.gd::height_at, via load_config()
## against the UNMODIFIED data/config/terrain_playground.json still on disk
## in /workspace/tetherbound -- this script writes nothing, anywhere) at
## every NEW coordinate the OW5D relocation table proposes, so the scratch
## edits under scratchpad/ow5d/ are not shipped blind. Pattern borrowed from
## tools/_probe_corridor_footprint.gd and the 8m-box convention several
## data/config/*.json `_ground` comments already cite (e.g. relay_site.json).
##
## Because none of these new sites have an authored `flats` entry yet in the
## LIVE config (the scratch edits that add/move `flats` centres live only in
## this task's output files, not on disk), height_at here reports the RAW
## analytic terrain -- hills + valley + rises + rock_form -- which is exactly
## the "is this ground viable before anyone puts a flat pad on it" question
## the macro-layout doc's own section 10.2b asks OW5D to answer first.
##
##   godot --headless --path . --script scratchpad/ow5d/_probe_ow5d_sites.gd
##   (run from /workspace/tetherbound, or pass --path /workspace/tetherbound)

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const WATER_LEVEL := -22.5  # data/config/terrain_playground.json `water.level`, unmoved by this pass

const SITES := [
	{"name": "Pond centre (water.pond_centre)", "at": [-395.0, 545.0], "note": "water surface centre -- height_at reports raw ground here, not the water plane"},
	{"name": "Pond valley centre", "at": [-370.0, 560.0], "note": "basin centre, r180"},
	{"name": "Mill pad", "at": [-382.0, 514.0], "note": "flats[4] new centre; old explicit height -20.7 carried over UNVERIFIED"},
	{"name": "Ranger station pad", "at": [-350.0, 507.0], "note": "flats[5] new centre; old explicit height -18.2 carried over UNVERIFIED"},
	{"name": "Old Quarry floor", "at": [400.0, 1800.0], "note": "flats[8] new centre; old explicit height -0.5 carried over UNVERIFIED"},
	{"name": "Quarry pylon run end", "at": [418.1, 1763.2], "note": "farthest quarry_run_3 drain station"},
	{"name": "Burrow Warrens site.at", "at": [-420.0, 2470.0], "note": "needs a 10m skirt (macro-layout doc section 10.2b)"},
	{"name": "Tether Relay site.centre", "at": [350.0, 3760.0], "note": "old site was a gentle south-east shoulder, ~6deg along approach"},
	{"name": "Stronghold site.at", "at": [0.0, 7560.0], "note": "needs an 18m skirt (macro-layout doc section 10.2b)"},
	{"name": "Sigil gate", "at": [0.0, 7400.0], "note": "160m short of the stronghold on the new approach"},
	{"name": "Regional captain: Halder (field)", "at": [170.0, 5590.0], "note": "Band 4 spine waypoint"},
	{"name": "Regional captain: Vess (ridge)", "at": [-280.0, 6460.0], "note": "Band 4 spine waypoint, watchtower spur"},
	{"name": "Regional captain: Oreth (riverwatch)", "at": [-100.0, 4350.0], "note": "off-spine, Band 3/4 seam"},
	{"name": "spawns: trailpup (grove->Band2)", "at": [150.0, 1550.0], "note": ""},
	{"name": "spawns: duskhush (grove->Band2)", "at": [250.0, 1700.0], "note": ""},
	{"name": "spawns: meadowhart (upper ridge->Band4)", "at": [60.0, 6230.0], "note": "High pasture loop start"},
	{"name": "spawns: meadowhart (SH47 early cluster)", "at": [40.0, 1400.0], "note": "just past new South Bridge"},
]

const STEP := 4.0  # metres, matches the "8m box" convention several _ground comments cite


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config found -- run this from /workspace/tetherbound")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

	print("=== OW5D site ground-truth probe (READ-ONLY, samples raw analytic terrain) ===")
	print("world_bounds in the live config (should already be OW5B's corridor):")
	print("  %s" % str(config.get("world_bounds", {})))
	print("")

	for site: Dictionary in SITES:
		var cx: float = float(site["at"][0])
		var cz: float = float(site["at"][1])
		var centre_h: float = field.call("height_at", cx, cz)

		var offsets := [[STEP, 0.0], [-STEP, 0.0], [0.0, STEP], [0.0, -STEP]]
		var heights := [centre_h]
		var worst_deg := 0.0
		for off: Array in offsets:
			var h: float = field.call("height_at", cx + off[0], cz + off[1])
			heights.append(h)
			var deg := rad_to_deg(atan(absf(h - centre_h) / STEP))
			worst_deg = maxf(worst_deg, deg)

		var lo: float = heights[0]
		var hi: float = heights[0]
		for h2: float in heights:
			lo = minf(lo, h2)
			hi = maxf(hi, h2)
		var spread := hi - lo

		var flags: Array[String] = []
		if centre_h < WATER_LEVEL + 3.0:
			flags.append("NEAR/BELOW WATER LEVEL (%.1f vs level %.1f)" % [centre_h, WATER_LEVEL])
		if worst_deg > 45.0:
			flags.append("STEEP: worst local slope %.1f deg > player's 45 deg floor_max_angle" % worst_deg)
		elif worst_deg > 20.0:
			flags.append("moderate slope, worth a second look: %.1f deg" % worst_deg)

		var flag_str := "" if flags.is_empty() else "  !! " + " | ".join(flags)
		print("%-42s (%7.1f,%7.1f)  h=%7.2f  spread(8m box)=%.2fm  worst=%.1fdeg%s" % [
			site["name"], cx, cz, centre_h, spread, worst_deg, flag_str])
		if str(site.get("note", "")) != "":
			print("    note: %s" % site["note"])

	print("")
	print("Read worst-slope and spread against: player floor_max_angle 45deg, ridden-creature")
	print("climb limit 60deg (docs/specs/MEADOWS_MACRO_LAYOUT.md section 1.2). A site flagged STEEP")
	print("or NEAR/BELOW WATER LEVEL above needs re-siting or a skirt/flat before it is final --")
	print("this probe does not decide that, it only reports what is there today.")
	quit(0)
