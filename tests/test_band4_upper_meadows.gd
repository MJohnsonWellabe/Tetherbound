extends "res://tests/test_case.gd"

## G3-BAND4. Prompt 65 (docs/prompts/65-BAND4-finished-upper-meadows.md) and
## prompt 67's five-creature-pressure requirement, pinned as data assertions
## so a later edit to any band's spawn/trainer/route data cannot silently
## regress a claim this lane verified true on 2026-09-03 without failing a
## build.
##
## This file does not re-test what tests/test_trainers_data.gd's SF34 section
## already covers in depth (per-captain team-shape contrast, sigil
## uniqueness, the Hall gate, readiness dialogue). It only pins the
## band-specific, prompt-65-specific claims nothing else asserts: that the
## three captains read as distinct PLACES (not just distinct rosters), that
## the route out of Band 4 is a set of loops and not one line, that the
## wild table is not a Meadowhart monoculture, that Band 4 still fields its
## own alpha/special encounter and its own optional trainer, and — prompt
## 67's own acceptance question — the actual measured number of distinct
## wild species a normal player has met by this band, against the five-slot
## cap.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const PARTY := preload("res://autoload/party.gd")

const TERRAIN_PATH := "res://data/config/terrain_playground.json"

## Every band up to and including Band 4, in corridor order — the same list
## a player walks before reaching the three captains.
const BANDS_THROUGH_4 := [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
]

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _band_spawns(band: String) -> Array:
	var doc := _load_json("res://data/config/bands/%s/spawns.json" % band)
	return doc.get("spawns", []) as Array


func _band_harvest(band: String) -> Array:
	var doc := _load_json("res://data/config/bands/%s/harvest.json" % band)
	return doc.get("nodes", []) as Array


## --- prompt 67: roster pressure must be validated explicitly, with a number ---

## By Band 4, a normal player should already have encountered more than five
## plausible desirable creatures (prompt 67's own acceptance question).
## Measured 2026-09-03 against the merged wild tables for bands 1-4: 15
## distinct species. This asserts the real floor prompt 67 actually cares
## about — meaningfully above the 5-slot cap, not merely one over it — and
## keeps the number itself visible so a future edit that quietly thins the
## early wild tables cannot silently make the cap free again by the time the
## player reaches the captains.
func test_cumulative_roster_pressure_by_band4_beats_the_five_slot_cap() -> void:
	var species := {}
	for band: String in BANDS_THROUGH_4:
		for entry: Variant in _band_spawns(band):
			var id := str((entry as Dictionary).get("species", ""))
			if id != "":
				species[id] = true
	# Margin, not just "> MAX_CREATURES": one extra option over the cap is not
	# a floor a player can feel while packing a team of five, it is a tie.
	var floor_count := PARTY.MAX_CREATURES + 3
	assert_true(species.size() >= floor_count,
		("by band4_upper_meadows_ironwood the wild table should offer at least %d distinct "
			+ "species against the %d-creature cap (measured 15 on 2026-09-03); found %d — %s")
			% [floor_count, PARTY.MAX_CREATURES, species.size(), str(species.keys())])


## --- prompt 65: "current Band 4 population cannot remain effectively one ---
## --- Meadowhart cluster" ------------------------------------------------------

## Guards the specific claim prompt 65 made about the state of the world
## before this lane: verified false against the live table on 2026-09-03
## (meadowhart is 9 of 81 entries, 8 distinct species total), but nothing
## previously asserted it, so a future edit could silently regress into the
## exact thing the prompt was complaining about. No single species may
## dominate the band's own table, and the band must keep real variety on its
## own (not merely by inheriting earlier bands' species).
func test_band4_wild_ecology_is_not_a_single_species_monoculture() -> void:
	var entries := _band_spawns("band4_upper_meadows_ironwood")
	assert_false(entries.is_empty(), "band4_upper_meadows_ironwood/spawns.json has no wild entries at all")
	var counts := {}
	for entry: Variant in entries:
		var id := str((entry as Dictionary).get("species", ""))
		counts[id] = int(counts.get(id, 0)) + 1
	assert_true(counts.size() >= 5,
		"band4_upper_meadows_ironwood fields only %d distinct species across %d entries — too thin to read as its own ecology"
			% [counts.size(), entries.size()])
	var total := float(entries.size())
	for id: String in counts:
		var share := float(counts[id]) / total
		assert_true(share <= 0.4,
			("'%s' is %.0f%% of band4's own wild entries (%d of %d) — that is a monoculture, the exact "
				+ "thing prompt 65 named as the band's starting state") % [id, share * 100.0, int(counts[id]), entries.size()])


## Band 4 keeps a genuine rare/special encounter, not just more of the same
## roster at a higher level — prompt 65's "at least one special encounter."
func test_band4_fields_at_least_one_alpha_or_special_encounter() -> void:
	var entries := _band_spawns("band4_upper_meadows_ironwood")
	var found := 0
	for entry: Variant in entries:
		var spec := entry as Dictionary
		if spec.has("alpha") and not (spec["alpha"] as Dictionary).is_empty():
			found += 1
	assert_true(found >= 1,
		"band4_upper_meadows_ironwood fields no alpha/special wild encounter at all")


## --- prompt 65: three captains must occupy believable, DISTINCT sub-locations ---

## The three regional captains (Field/Ridge in band4_upper_meadows_ironwood's
## own trainers.json, Riverwatch deliberately sited on the band3/4 seam in
## band3_the_river_lock's own trainers.json — see that entry's own OW5D note,
## which this lane was told not to move) must read as three separate places
## on the map, not three prompts standing near each other. Pinned as a real
## minimum pairwise distance rather than merely "not identical", so a future
## reposition cannot quietly collapse them back into one cluster.
func test_the_three_captains_occupy_spatially_distinct_places() -> void:
	var field := TRAINERS.trainer("captain_field")
	var ridge := TRAINERS.trainer("captain_ridge")
	var riverwatch := TRAINERS.trainer("captain_riverwatch")
	for pair: Array in [[field, "captain_field"], [ridge, "captain_ridge"], [riverwatch, "captain_riverwatch"]]:
		assert_false((pair[0] as Dictionary).is_empty(), "'%s' is not in the trainer table" % str(pair[1]))

	var positions := {
		"captain_field": _xz(field),
		"captain_ridge": _xz(ridge),
		"captain_riverwatch": _xz(riverwatch),
	}
	const MIN_SEPARATION_M := 300.0
	var ids: Array = positions.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Vector2 = positions[ids[i]]
			var b: Vector2 = positions[ids[j]]
			var dist := a.distance_to(b)
			assert_true(dist >= MIN_SEPARATION_M,
				("'%s' and '%s' sit only %.0fm apart (%s vs %s) — too close to read as two distinct "
					+ "sub-locations rather than one cluster") % [ids[i], ids[j], dist, str(a), str(b)])


func _xz(trainer: Dictionary) -> Vector2:
	var pos: Array = trainer.get("position", [0.0, 0.0])
	return Vector2(float(pos[0]), float(pos[1]))


## --- prompt 65: "avoid one captain line ... regional loops/branches/reconnects" ---

## Route structure is authored in `terrain_playground.json`'s own `trail.loops`
## (each entry names a `leaves`/`rejoins` pair off the band spine and its own
## `points`) — this is the mechanism that would make the corridor a set of
## connected places instead of one line. Verified 2026-09-03: three loops tag
## `band: 4` (wind_ridge_traverse, high_pasture_loop, watchtower_spur). Reading
## only — this lane does not own or edit `terrain_playground.json`.
func test_band4_has_more_than_one_route_loop_off_its_own_spine() -> void:
	var doc := _load_json(TERRAIN_PATH)
	var trail: Dictionary = doc.get("trail", {})
	var loops: Array = trail.get("loops", [])
	var band4_loops: Array = []
	for entry: Variant in loops:
		var loop := entry as Dictionary
		if int(loop.get("band", -1)) == 4:
			band4_loops.append(loop)
	assert_true(band4_loops.size() >= 2,
		("band4_upper_meadows_ironwood authors only %d route loop(s) in terrain_playground.json's "
			+ "trail.loops — prompt 65 asks for regional loops/branches/reconnects, plural, not one "
			+ "captain line") % band4_loops.size())
	for loop: Dictionary in band4_loops:
		assert_false((loop.get("leaves", []) as Array).is_empty(),
			"loop '%s' has no 'leaves' point — it does not actually branch off the spine" % str(loop.get("id", "")))
		assert_false((loop.get("rejoins", []) as Array).is_empty(),
			"loop '%s' has no 'rejoins' point — it does not actually reconnect" % str(loop.get("id", "")))


## --- prompt 65: "at least one meaningful optional trainer ... competing ---
## --- for attention with the captain route" ------------------------------------

## Band 4 must field at least one trainer whose defeat is NOT required to
## open the Hall approach — an optional fight the player can choose to skip
## with no progression cost. patrol_ridgeline and pasture_drover_juno are
## both authored this way today; this pins that at least one such trainer
## keeps existing rather than pinning either by name, so either may be
## retired in favour of a replacement without breaking this test for no
## reason.
func test_band4_fields_at_least_one_optional_trainer_outside_the_sigil_gate() -> void:
	const REQUIRED_CAPTAIN_IDS := ["captain_field", "captain_ridge", "captain_riverwatch"]
	var doc := _load_json("res://data/config/bands/band4_upper_meadows_ironwood/trainers.json")
	var trainers: Array = doc.get("trainers", [])
	assert_false(trainers.is_empty(), "band4_upper_meadows_ironwood/trainers.json has no trainers at all")
	var optional_count := 0
	for entry: Variant in trainers:
		var spec := entry as Dictionary
		var id := str(spec.get("id", ""))
		if not REQUIRED_CAPTAIN_IDS.has(id):
			optional_count += 1
	assert_true(optional_count >= 1,
		"band4_upper_meadows_ironwood fields no trainer beyond the three captains — nothing competes for attention with the Sigil route")


## --- prompt 65: "Ironwood tier ... enable real utility/riding/final-assault ---
## --- preparation rather than become another collectible" ----------------------

## The tier must actually be gatherable IN the region spec names for it
## (Band 4), not only inherited from an earlier band's dungeon. Guards
## against the exact gap `harvest.json`'s own `_comment_ironwood_d4` records
## having found and fixed: "the only ironwood anywhere in the chapter was
## five nodes in band2 ... a player who reaches Band 4's captains without
## having taken the Warrens spur had no ironwood at all."
func test_band4_fields_its_own_gatherable_ironwood() -> void:
	var nodes := _band_harvest("band4_upper_meadows_ironwood")
	var ironwood_nodes := 0
	for entry: Variant in nodes:
		if str((entry as Dictionary).get("item", "")) == "ironwood":
			ironwood_nodes += 1
	assert_true(ironwood_nodes >= 3,
		"band4_upper_meadows_ironwood/harvest.json fields only %d ironwood node(s); Band 4's own material tier should be gatherable inside Band 4"
			% ironwood_nodes)
