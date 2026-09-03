extends OmniLight3D

## NIGHT-LEGIBILITY (ROADMAP 2.7): "a fill floor so an unlit camp does not go
## to black."
##
## A built camp with no campfire (tent + bedroll only -- `campfire` is its
## own independently-placed buildable since OWNER-0902-CAMP-SPLIT, and a
## player who has not built or reached one yet has no local light source at
## all) has nothing standing between it and the world's own deliberately dim
## night ambient. Measured directly (tools/_capture_night_legibility.gd): a
## tent and bedroll placed in open meadow at night rendered as a near-pure-
## black cutout, darker than the grass around them (subject/ground luma ratio
## 0.87 -- below 1.0), while the same meadow's own grass, flowers and hills
## stayed readable. `campfire_glow.gd` already solves the analogous "a real
## light source needs day/night scaling" problem for a LIT fire; this is the
## much smaller sibling for a camp that has none: one soft, unflickering,
## night-only OmniLight, low enough it reads as ambient presence rather than
## a light source a player would look for, so a lit campfire nearby still
## reads as the dominant light exactly as it does today.
##
## `attach()` is called once from each camp fixture's own `build_real()`
## (tent, bedroll, creature bed, storage) -- never from `build_ghost()`, a
## drag-around preview is not a camp yet. Fixtures placed together stack more
## than one of these, which is correct: a real cluster of camp furniture
## should read a little brighter than one lone piece, the same way two lit
## torches would.

const CONFIG_PATH := "res://data/config/art.json"

const RANGE := 5.0
const ATTENUATION := 1.6
const COLOUR := Color(0.65, 0.72, 0.85)

static var _config: Dictionary = {}

var _world_look: Node = null
var _night_energy := 0.0


static func _art_config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## `times.night.environment.camp_fill_energy` -- read once per attach rather
## than cached at the class level, the same reasoning `creature_visual.gd`
## gives for its own config cache: cheap, and a hot-reloaded config during
## development should not need every already-placed light rebuilt to notice.
static func _read_night_energy() -> float:
	var night: Dictionary = _art_config().get("times", {}).get("night", {}).get("environment", {})
	return float(night.get("camp_fill_energy", 0.0))


## Adds one fill light as a child of `parent`, at `height` metres above its
## origin (each fixture's own local floor offset already differs -- the
## tent's sink compensation, the bedroll's -- so the caller passes its own).
static func attach(parent: Node3D, height: float) -> Node3D:
	var light := load("res://scripts/world/camp_fill_light.gd").new() as OmniLight3D
	light.name = "CampFillLight"
	light.position = Vector3(0.0, height, 0.0)
	parent.add_child(light)
	return light


func _ready() -> void:
	light_color = COLOUR
	omni_range = RANGE
	omni_attenuation = ATTENUATION
	shadow_enabled = false
	light_energy = 0.0
	_night_energy = _read_night_energy()


## Lazy day_cycle lookup, same pattern `campfire_glow.gd::_daylight_scale()`
## already uses: a camp piece can be placed and added to the tree before
## `world_look.gd` has joined the "day_cycle" group.
func _process(_delta: float) -> void:
	if _world_look == null or not is_instance_valid(_world_look):
		_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	var dark := _world_look != null and _world_look.has_method("is_dark") \
		and bool(_world_look.call("is_dark"))
	light_energy = _night_energy if dark else 0.0
