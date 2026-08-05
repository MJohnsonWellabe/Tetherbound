extends RefCounted

## Team Tether's data, read once and handed out.
##
## Same shape and the same reasons as `combat_math.config()` and
## `catch_math.config()`: static, cached, no nodes, so every question about what
## a trainer IS can be asked from a headless test without standing up a scene.
##
## Two files, deliberately split:
##
##   * `data/config/trainers.json` — the route, the timings, the tether grades,
##     the dressing. Wiring and tunables.
##   * `data/trainers/<id>.json` — one trainer each. Content.
##
## The split is the one CLAUDE.md asks for ("keep data out of gameplay code when
## it will clearly vary by species/move/item"): adding a fourth Tether trainer is
## a new file and one line in the route, and rebalancing every trainer at once is
## one edit to the grades.

const CONFIG_PATH := "res://data/config/trainers.json"
const TRAINERS_DIR := "res://data/trainers"
const PALETTE_PATH := "res://data/config/palette.json"

static var _config: Dictionary = {}
static var _trainers: Dictionary = {}
static var _palette: Dictionary = {}


static func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("missing data file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("%s did not parse as a JSON object" % path)
		return {}
	return parsed


static func config() -> Dictionary:
	if _config.is_empty():
		_config = _read(CONFIG_PATH)
	return _config


## One trainer's definition, by id. Empty for an unknown id rather than a
## half-built default: a typo in the route should fail where the typo is.
static func trainer(id: String) -> Dictionary:
	if _trainers.has(id):
		return _trainers[id]
	var loaded := _read("%s/%s.json" % [TRAINERS_DIR, id])
	if loaded.is_empty():
		return {}
	_trainers[id] = loaded
	return loaded


## Every trainer id the route names, in route order.
##
## The ROUTE is the enumeration, not the directory listing. `data/trainers/`
## also holds `species_addendum.json`, and a scan of the folder would try to
## stand a species table up on the road.
static func route_posts() -> Array:
	var posts: Array = config().get("route", {}).get("posts", [])
	var out: Array = []
	for entry: Variant in posts:
		if entry is Dictionary:
			out.append(entry)
	return out


## What a tether does to a creature's timings. Unknown grades come back as the
## untethered one rather than as an empty Dictionary, so a typo produces a
## creature that fights normally instead of one whose beats are all zero and
## which therefore attacks every frame.
static func tether_grade(name: String) -> Dictionary:
	var grades: Dictionary = config().get("tether_grades", {})
	var entry: Variant = grades.get(name)
	if entry is Dictionary:
		return entry
	if name != "none":
		push_warning("no tether grade '%s'; falling back to 'none'" % name)
	var fallback: Variant = grades.get("none")
	return fallback if fallback is Dictionary else {
		"beat_scale": 1.0, "cooldown_scale": 1.0, "chase_scale": 1.0, "live": false
	}


## --- the reserved accent ---------------------------------------------------

## A colour from `palette.json`'s `accent` block, by id.
##
## THIS IS THE ONLY READER OF THAT BLOCK IN THE GAME, and it must stay that way.
## `palette.json` reserves the Team Tether accent project-wide — it appears on
## banners, equipment and uniforms and on nothing friendly or neutral — and a
## reservation is only worth having while there is exactly one door to it.
## `map_canvas.gd`, `ui_style.gd` and `release_screen.gd` each carry a comment
## saying they deliberately do not use it; this is the file that does.
##
## Ids, never hexes, everywhere upstream. A hex written into a scene or a script
## is a copy of a reserved colour that nobody can find later.
static func accent(id: String) -> Color:
	if _palette.is_empty():
		_palette = _read(PALETTE_PATH)
	var accents: Dictionary = _palette.get("accent", {})
	if not accents.has(id):
		push_error("palette.json has no accent '%s'; Team Tether will be drawn untinted" % id)
		return Color.MAGENTA
	return Color(str(accents[id]))


## --- convenience -----------------------------------------------------------

static func engage_range() -> float:
	return float(config().get("engage", {}).get("range", 8.5))


static func release_range() -> float:
	return float(config().get("engage", {}).get("release_range", 12.0))


static func flow() -> Dictionary:
	return config().get("flow", {})


static func dress() -> Dictionary:
	return config().get("dress", {})


static func legendary() -> Dictionary:
	return config().get("legendary", {})


## Forget everything. Only for tests that rewrite a config on disk; nothing in
## the running game calls it.
static func forget() -> void:
	_config = {}
	_trainers = {}
	_palette = {}
