extends "res://tests/test_case.gd"

## F32#4: no item implies hunting or butchering. Scans the player-facing text of
## the actual runtime ItemDB (canonical items plus the F32 overlay and display
## overrides) and the authored shed wording. A creature's own living hide,
## shell or feather is not butchery and is deliberately not a banned term.
const SHED := preload("res://scripts/world/shed_drop_rules.gd")
const BANNED := "\\b(hunt\\w*|butcher\\w*|slaughter\\w*|carcass\\w*|pelts?|skinn(ed|ing)|flay\\w*|gutt(ed|ing)|meat|flesh\\w*|trophy|trophies|leather\\w*)\\b"

func _banned() -> RegEx:
	var pattern := RegEx.new()
	pattern.compile("(?i)" + BANNED)
	return pattern

func test_runtime_item_text_never_implies_hunting_or_butchery() -> void:
	var db: RefCounted = preload("res://autoload/item_db.gd").new()
	var pattern := _banned()
	var scanned := 0
	for raw: Variant in db.ids():
		var id := str(raw)
		var definition: Dictionary = db.definition(id)
		for field: String in ["name", "blurb", "description"]:
			var text := str(definition.get(field, ""))
			var hit := pattern.search(text)
			assert_true(hit == null, "%s.%s implies hunting/butchery: '%s'" % [id, field, hit.get_string() if hit != null else ""])
		scanned += 1
	assert_true(scanned > 100, "scanned the whole runtime catalogue")

func test_shed_items_are_registered_and_described_as_naturally_shed() -> void:
	var db: RefCounted = preload("res://autoload/item_db.gd").new()
	var config := SHED.read()
	var pattern := _banned()
	for species: String in config.species:
		var row: Dictionary = config.species[species]
		assert_true(db.has(str(row.item)), species + " shed item is registered")
		assert_true(config.allowed_shed_items.has(row.item), species + " shed item is allowed")
		assert_true(pattern.search(str(row.source_wording)) == null, species + " shed wording")
		var wording := str(row.source_wording).to_lower()
		assert_true(wording.contains("shed") or wording.contains("brushed") or wording.contains("loose"),
			species + " wording says the material came loose, was shed or was brushed free")
	var policy: Dictionary = config.den_grooming
	assert_eq(policy.automatic_production, false)
	assert_eq(policy.offline_production, false)
	assert_eq(policy.manual_tap, true)

func test_the_scan_catches_butchery_wording() -> void:
	var pattern := _banned()
	for bad: String in ["Hunting trophy", "butchered remains", "a fresh pelt", "skinned hide", "raw meat", "tanned leather"]:
		assert_true(pattern.search(bad) != null, "detects: " + bad)
	for fine: String in ["a permanent thickening of hide, shell or feather", "naturally shed fur", "gale fiber"]:
		assert_true(pattern.search(fine) == null, "allows: " + fine)
