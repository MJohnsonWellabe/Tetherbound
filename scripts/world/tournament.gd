extends Node3D

## TOURNAMENT-1. The village tournament's bracket board, and the two entry
## conditions that decide whether the player is allowed to sign up.
##
## What this file is NOT is a tournament state machine. The 2026-08-22 owner
## directive locked an eight-slot bracket with three fought rounds, and every
## piece of that already existed:
##
##   * the fights are ordinary `trainers.json` entries, run by
##     `encounter_director.begin_trainer_battle()`;
##   * the rounds are opened by the marshal's own `battle:` dialogue effect,
##     the same one every villager challenge uses;
##   * which of her seven lines she says is chosen by `village_npcs.gd`'s
##     ordered `greeting_when` branches against progression flags;
##   * a win is recorded by the trainer's own `defeat_flag`, and the saddle
##     pattern by its own `reward.flags`.
##
## So exactly two jobs were left over, and they are the two things in this file:
##
##   1. THE BOARD. The directive is explicit that the bracket has to be visible
##      -- "the board must be visible to the player so the bracket reads as
##      real" -- because four of the eight slots are never fought and would
##      otherwise be a claim in a dialogue box. It is a physical object in the
##      tournament ground with all eight names painted on it, and it fills in
##      the simulated results between the player's own matches.
##   2. THE ENTRY CONDITIONS. `tournament_team_ready` and
##      `tournament_training_ready` are contract flags
##      (data/progression/objectives.json) that nothing set. They are set here,
##      from thresholds in data/config/tournament.json, by watching the party
##      the same polling way every other flag-reading node in this project
##      watches its store. The numbers are data; the rule is four lines.
##
## Neither job needs a quest engine and neither builds one -- spec sec19 and
## CLAUDE.md both ban that, and `progression_state.gd` is still a flat set of
## ids that are either set or not.

const CONFIG_PATH := "res://data/config/tournament.json"

## The statement prompt bolted to the board. Same node every berry bush and
## signpost uses; nothing about a bracket board justifies a second one.
const INTERACTABLE := preload("res://scripts/world/interactable.gd")

## Metres. The board reads its own state out as a one-line statement so a
## player who cannot make out the painted text still learns where they are in
## the bracket. Deliberately tighter than a villager's greeting radius (3.8m)
## and tighter than a trainer's challenge (4.2m): it is a thing you walk up to
## and read, and it must never be the nearest offer while somebody is standing
## next to it wanting to be talked to.
const PROMPT_RADIUS := 2.6

const POST_HEIGHT := 2.3
const POST_RADIUS := 0.075
## The painted panel. Wide enough for the longest bracket line at a legible
## size and low enough that its top edge sits under the posts' caps, so the
## thing reads as a board nailed to two posts rather than as a floating plane.
const BOARD_WIDTH := 2.5
const BOARD_HEIGHT := 1.55
const BOARD_THICKNESS := 0.07
const BOARD_CENTRE_HEIGHT := 1.5
const BOARD_SPACING := 0.9

const LABEL_FONT_SIZE := 40
## Metres per font pixel, the CEILING rather than the value used. The board is
## redrawn as the bracket fills in and the longest line grows with it, so
## `pixel_size_for()` refits the block every redraw and this only caps how
## large the text is allowed to get on a sparse board. Without the refit an
## edit to tournament.json's `bracket` -- a longer opponent name, a fifth
## simulated bout -- would silently push painted text off the panel, which is
## the exact defect signpost.gd already paid for once with its arm labels.
const LABEL_PIXEL_SIZE := 0.0034
## Label3D stacks lines at roughly 1.2x the font size. Used to fit the block
## vertically as well as horizontally, so a bracket that grows a round does not
## overrun the panel's top and bottom edges instead of its sides.
const LABEL_LINE_SPACING := 1.35
## Mean glyph advance as a fraction of the font size, for the same estimate.
## 0.62 rather than signpost.gd's 0.55: the widest line on this board is the
## all-caps title, and uppercase Latin runs wider than the mixed-case text that
## figure was picked for. The first render clipped "LOWER MEADOWS TOURNAMENT"
## off both ends of the panel with 0.55.
const LABEL_GLYPH_ADVANCE := 0.62
## Fraction of the panel the text block is allowed to occupy.
const LABEL_MARGIN := 0.88

var _board: Node3D = null
var _text: Label3D = null
var _prompt: Node = null
var _built := false

## Last revisions acted on, so the board is redrawn and the thresholds are
## re-checked only when something actually changed. Same polling idiom
## `village_npcs.gd`, `party.gd`, `inventory.gd` and `map_state.gd` all use --
## `progression_state.gd` has no signal, by design.
var _progression_revision := -1
var _party_revision := -1


## `world` is asked for ground height the same way `signpost.gd` and
## `village.gd` are (D09: never a raycast).
func build(world: Node) -> void:
	var at := board_position()
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the tournament board at %.0f, %.0f; the bracket has nowhere to stand" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)
	rotation.y = deg_to_rad(board_facing_deg())
	_build_board()
	_built = true
	set_process(true)
	_refresh(true)


func built() -> bool:
	return _built


## --- the board ----------------------------------------------------------------

func _build_board() -> void:
	_board = Node3D.new()
	_board.name = "Board"
	add_child(_board)

	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color("#6b4a2f")
	timber.roughness = 0.85

	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post_%s" % ("L" if side < 0.0 else "R")
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = POST_RADIUS
		post_mesh.bottom_radius = POST_RADIUS * 1.15
		post_mesh.height = POST_HEIGHT
		post_mesh.material = timber
		post.mesh = post_mesh
		post.position = Vector3(side * BOARD_SPACING, POST_HEIGHT * 0.5, 0.0)
		_board.add_child(post)

	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(BOARD_WIDTH, BOARD_HEIGHT, BOARD_THICKNESS)
	var panel_mat := StandardMaterial3D.new()
	# A limewashed board, not bare timber: the text is dark ink and needs a
	# pale ground to be read against, and the posts either side keep the object
	# reading as village carpentry rather than as a UI panel dropped in a field.
	#
	# Warm, weathered limewash rather than paper. The first render read as a
	# white UI plane dropped in a field from any distance -- the panel was the
	# brightest thing in the frame, brighter than the sky's horizon band. Darker
	# and yellower keeps the dark ink readable while letting the board sit in
	# the meadow's own palette.
	panel_mat.albedo_color = Color("#bfa87e")
	panel_mat.roughness = 0.9
	panel_mesh.material = panel_mat
	panel.mesh = panel_mesh
	panel.position = Vector3(0.0, BOARD_CENTRE_HEIGHT, 0.0)
	_board.add_child(panel)

	# One collider for the whole assembly. The board is a solid object in a
	# field the player fights in: a combat arena centred nearby will push a
	# creature into it, and something to push against is better than something
	# to walk through.
	var body := StaticBody3D.new()
	body.name = "Board_Collision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BOARD_WIDTH + POST_RADIUS * 2.0, POST_HEIGHT, BOARD_THICKNESS * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, POST_HEIGHT * 0.5, 0.0)
	body.add_child(shape)
	_board.add_child(body)

	# The painted face. A single Label3D rather than one per line: the bracket
	# is one block of text with its own internal alignment, and eleven separate
	# nodes would each need their own vertical placement kept in step with the
	# panel's height.
	_text = Label3D.new()
	_text.name = "Bracket"
	_text.font_size = LABEL_FONT_SIZE
	_text.pixel_size = LABEL_PIXEL_SIZE
	_text.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_text.no_depth_test = false
	# CENTRED, not left-aligned, and the first render is why. A Label3D with
	# HORIZONTAL_ALIGNMENT_LEFT puts its ORIGIN at the left edge of the text
	# block rather than at its centre, so the whole bracket sat starting at the
	# middle of the panel with "LOWER MEADOWS TOURNAMENT" and two of the
	# results hanging off the right-hand edge into open air. Centring is the
	# fix that needs no glyph measurement: the block is centred on the panel it
	# is painted on, whatever the longest line turns out to be.
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.modulate = Color("#241a10")
	# Same reason signpost.gd carries one: dark ink loses its edges wherever
	# the board crosses a shadow, and the panel is stood in a field with trees
	# behind it.
	# Small. At 8 the outline haloed every glyph and, with the pale panel
	# behind it, washed the whole board out to a flat white rectangle in the
	# walk-up frame. 3 is enough to hold the ink's edges without becoming the
	# thing you see from twenty metres.
	_text.outline_size = 3
	_text.outline_modulate = Color("#f4ecd8")
	# A hair proud of the panel's front face so the two never z-fight.
	_text.position = Vector3(0.0, BOARD_CENTRE_HEIGHT, BOARD_THICKNESS * 0.5 + 0.008)
	_board.add_child(_text)

	var prompt := INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.radius = PROMPT_RADIUS
	# A STATEMENT, not an offer. There is nothing to press here: signing up is
	# the marshal's job and the bracket is already painted on the board in
	# front of you. `actionable: false` is interactable.gd's own supported
	# answer to exactly this -- a line drawn with no button glyph.
	prompt.actionable = false
	prompt.label = ""
	prompt.position = Vector3(0.0, BOARD_CENTRE_HEIGHT, BOARD_THICKNESS * 0.5)
	_board.add_child(prompt)
	_prompt = prompt


## --- polling ------------------------------------------------------------------

func _process(_delta: float) -> void:
	_refresh(false)


func _refresh(force: bool) -> void:
	var progression := _progression()
	var party := _party()
	var progression_revision: int = int(progression.get("revision")) if progression != null else -1
	var party_revision: int = int(party.get("revision")) if party != null else -1
	if not force and progression_revision == _progression_revision and party_revision == _party_revision:
		return
	_progression_revision = progression_revision
	_party_revision = party_revision

	_write_entry_flags(party, progression)
	if _text != null:
		var lines := board_lines(progression)
		_text.text = "\n".join(lines)
		_text.pixel_size = pixel_size_for(lines)
		_fit_to_panel()
	if _prompt != null:
		_prompt.set("label", status_line(progression))


## Shrink the painted block until its REAL bounds fit the panel.
##
## `pixel_size_for()` is an estimate from a glyph-advance constant, and an
## estimate is exactly what put "LOWER MEADOWS TOURNAMENT" off both ends of the
## board and "You vs Oskar" off the bottom edge in the first render: the font's
## actual advances and line height are not the constants, and no constant will
## be right for every string a future bracket can produce. This asks the node
## that already laid the text out how big it came out and scales to suit --
## a measurement, not a better guess. Only ever shrinks: the estimate is the
## ceiling and a block that already fits is left alone.
func _fit_to_panel() -> void:
	if _text == null:
		return
	var bounds := _text.get_aabb()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	var shrink := minf(
		(BOARD_WIDTH * LABEL_MARGIN) / bounds.size.x,
		(BOARD_HEIGHT * LABEL_MARGIN) / bounds.size.y)
	if shrink < 1.0:
		_text.pixel_size *= shrink


## The two contract flags, written from data/config/tournament.json's own
## thresholds.
##
## Set-only. Neither is ever cleared once written, and that is deliberate: they
## are contract flags recording that something HAPPENED, and a player who
## releases a creature after signing up must not find the tournament has
## un-happened. `progression_state.set_flag()` is idempotent, so re-writing a
## set flag costs nothing and does not move its revision.
func _write_entry_flags(party: RefCounted, progression: RefCounted) -> void:
	if party == null or progression == null:
		return
	if team_ready(party):
		progression.call("set_flag", "tournament_team_ready")
	if training_ready(party):
		progression.call("set_flag", "tournament_training_ready")


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _party() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("party") if game != null else null


## --- the entry conditions, as pure functions ----------------------------------

## Enough creatures to field a team. `min_party_size` in the config, bounded
## above by the five-creature cap -- an entry condition the player is not
## allowed to satisfy would stop the chapter dead, so the threshold is clamped
## here rather than trusted. Static and pure so `tests/test_tournament.gd` can
## drive the real rule with a real party instead of booting a world.
static func team_ready(party: RefCounted) -> bool:
	if party == null:
		return false
	return int(party.call("size")) >= required_party_size()


## And trained: the `min_party_size` STRONGEST creatures each at `min_level`.
##
## The strongest ones rather than every one owned, on purpose. Checking the
## whole party would mean a player who catches a fresh level-1 bramblebun on
## the walk back to the village loses an entry they had already earned, which
## punishes exactly the behaviour the chapter spends its first hour asking for.
static func training_ready(party: RefCounted) -> bool:
	if party == null:
		return false
	var wanted := required_party_size()
	var levels: Array[int] = []
	for i in int(party.call("size")):
		var member: RefCounted = party.call("at", i)
		if member != null:
			levels.append(int(member.get("level")))
	if levels.size() < wanted:
		return false
	levels.sort()
	levels.reverse()
	var floor_level := required_level()
	for i in wanted:
		if levels[i] < floor_level:
			return false
	return true


static func required_party_size() -> int:
	var wanted := int(entry_config().get("min_party_size", 3))
	return clampi(wanted, 1, PARTY_CAP)


static func required_level() -> int:
	return maxi(1, int(entry_config().get("min_level", 6)))


## The five-creature cap, restated here rather than reached for through
## `/root/Game`: these are static functions a test calls with no autoloads, and
## the number is a CLAUDE.md hard rule that must not be quietly exceeded by a
## config edit. `tests/test_tournament.gd` pins this against `party.gd`'s own
## `MAX_CREATURES`, so the two cannot drift apart in silence.
const PARTY_CAP := 5


## --- the bracket text ---------------------------------------------------------

## Every line painted on the board right now, given what has happened.
##
## Pure and static apart from the flag store it is handed, for the same reason
## `village_npcs.greeting_for()` is: the board's content is the interesting
## part and a test should be able to read it without standing a panel on
## Terrain3D. A null store (a capture tool, a bare test scene) reads as a fresh
## save -- the draw with nothing resolved, which is the honest answer.
static func board_lines(progression: RefCounted) -> PackedStringArray:
	var out := PackedStringArray()
	out.append("LOWER MEADOWS TOURNAMENT")
	var slots := bracket()
	var by_round: Dictionary = {}
	for entry: Variant in rounds():
		var spec := entry as Dictionary
		by_round[str(spec.get("id", ""))] = spec

	# Quarter-finals: the player's own bout is slot 1 vs slot 2, then the three
	# simulated pairings in the order the config lists them.
	#
	# No blank spacer lines between the sections. Label3D collapses an empty
	# line to zero height, so the three that used to be here bought no visual
	# separation at all and only made `pixel_size_for()` fit the block for
	# fourteen lines when it draws eleven -- shrinking the text for whitespace
	# that never appeared.
	out.append("Quarter-finals")
	var quarter := by_round.get("quarter", {}) as Dictionary
	var semi := by_round.get("semi", {}) as Dictionary
	var final_round := by_round.get("final", {}) as Dictionary
	out.append(_bout_line(
		_slot_name(slots, 0), _opponent_of(quarter),
		_round_result(quarter, progression)))
	for sim: Dictionary in simulated_for("quarter"):
		out.append(_bout_line(str(sim.get("a", "")), str(sim.get("b", "")),
			_simulated_result(sim, progression)))

	out.append("Semi-finals")
	out.append(_bout_line(_slot_name(slots, 0), _opponent_of(semi),
		_round_result(semi, progression)))
	for sim: Dictionary in simulated_for("semi"):
		out.append(_bout_line(str(sim.get("a", "")), str(sim.get("b", "")),
			_simulated_result(sim, progression)))

	out.append("Final")
	out.append(_bout_line(_slot_name(slots, 0), _opponent_of(final_round),
		_round_result(final_round, progression)))
	return out


## One painted row: "You vs Mira  --  You". The result column is a row of
## dots until the bout has been decided, which is what makes a half-filled
## board read as a bracket in progress rather than as a list of names.
static func _bout_line(a: String, b: String, result: String) -> String:
	return "%s vs %s  --  %s" % [a, b, result if result != "" else "...."]


static func _slot_name(slots: Array, index: int) -> String:
	if index < 0 or index >= slots.size():
		return "?"
	return str((slots[index] as Dictionary).get("name", "?"))


static func _opponent_of(round_spec: Dictionary) -> String:
	return str(round_spec.get("opponent", "?"))


## The player's own bout. Won when the round's flag is set; otherwise
## undecided. A LOSS is deliberately not a state the board can show: the round
## stays open, the marshal offers it again, and a board that said "You -- lost"
## while the fight was still available would be lying about the rule the owner
## locked ("you can lose and retry after healing your creatures").
static func _round_result(round_spec: Dictionary, progression: RefCounted) -> String:
	var flag := str(round_spec.get("won_flag", ""))
	if flag == "" or progression == null or not bool(progression.call("has", flag)):
		return ""
	return "You"


static func _simulated_result(sim: Dictionary, progression: RefCounted) -> String:
	var flag := str(sim.get("reveal_after", ""))
	if flag == "" or progression == null or not bool(progression.call("has", flag)):
		return ""
	return str(sim.get("winner", ""))


## The one line the board says out loud when the player is standing at it --
## where they are in the bracket, in words, for a player who cannot read a
## painted panel across a field.
static func status_line(progression: RefCounted) -> String:
	if progression == null:
		return "Tournament board"
	if bool(progression.call("has", "tournament_won")):
		return "Tournament board: champion of the Lower Meadows"
	if not bool(progression.call("has", "tournament_entered")):
		return "Tournament board: the draw is open"
	for entry: Variant in rounds():
		var spec := entry as Dictionary
		if not bool(progression.call("has", str(spec.get("won_flag", "")))):
			return "Tournament board: %s, you vs %s" % [
				str(spec.get("label", "Next")), str(spec.get("opponent", "?"))]
	return "Tournament board"


## Metres per font pixel that keeps this whole block inside the panel, fitted
## on whichever of width or height binds first. Static and pure so a test can
## assert the fit without a panel in the world -- text that does not fit is a
## defect nobody notices in a headless run and everybody notices in a frame.
static func pixel_size_for(lines: PackedStringArray) -> float:
	var longest := 0
	for line: String in lines:
		longest = maxi(longest, line.length())
	var glyphs := maxf(1.0, float(longest) * LABEL_GLYPH_ADVANCE * float(LABEL_FONT_SIZE))
	var by_width := (BOARD_WIDTH * LABEL_MARGIN) / glyphs
	var stack := maxf(1.0, float(lines.size()) * LABEL_LINE_SPACING * float(LABEL_FONT_SIZE))
	var by_height := (BOARD_HEIGHT * LABEL_MARGIN) / stack
	return minf(LABEL_PIXEL_SIZE, minf(by_width, by_height))


## --- the table ----------------------------------------------------------------

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("%s is missing; there is no tournament" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not valid JSON; there is no tournament" % CONFIG_PATH)
		return {}
	_config = parsed as Dictionary
	return _config


static func entry_config() -> Dictionary:
	return config().get("entry", {}) as Dictionary


static func rounds() -> Array:
	return config().get("rounds", []) as Array


static func round_spec(id: String) -> Dictionary:
	for entry: Variant in rounds():
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
			return entry as Dictionary
	return {}


static func bracket() -> Array:
	return config().get("bracket", []) as Array


static func simulated() -> Array:
	return config().get("simulated", []) as Array


static func simulated_for(round_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Variant in simulated():
		if entry is Dictionary and str((entry as Dictionary).get("round", "")) == round_id:
			out.append(entry as Dictionary)
	return out


static func marshal_name() -> String:
	return str((config().get("marshal", {}) as Dictionary).get("name", ""))


static func board_position() -> Vector2:
	var at: Array = (config().get("board", {}) as Dictionary).get("position", [])
	var x := float(at[0]) if at.size() > 0 else 0.0
	var z := float(at[1]) if at.size() > 1 else 0.0
	return Vector2(x, z)


static func board_facing_deg() -> float:
	return float((config().get("board", {}) as Dictionary).get("facing_deg", 0.0))
