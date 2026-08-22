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
## Where the posts stand, as an offset from the panel's centre. OUTSIDE the
## painted face, not across it. At 0.9 they stood in front of the panel and
## covered the entire left-hand column of the draw and the champion's slot --
## a bracket board whose posts hide two of its four columns. They also read as
## two dowels with a rectangle floating between them, which is the "no
## joinery" half of the same defect.
const POST_SPACING := BOARD_WIDTH * 0.5 - 0.04
## How far behind the panel the posts and rails sit. The panel is nailed to
## the FRONT of the frame, the way a real notice board is built, so nothing
## structural crosses the thing you are meant to read.
const FRAME_DEPTH := 0.05
## The two rails the panel is nailed to, top and bottom.
const RAIL_THICKNESS := 0.055

## The painted bracket. Sizes are in metres unless the name says otherwise.
##
## The board draws a REAL BRACKET -- four columns of slots joined by
## connectors -- rather than a paragraph of "A vs B -- winner" lines. Two
## owner rulings sit behind that, given on the first render of this board:
## "the tournament bracket should be a bracket", and "it should only fill in
## after events not be filled in from the start". The first is this layout;
## the second is `bracket_state()`, which refuses to name anybody in a round
## whose feeding bouts have not been decided yet.
const NAME_FONT_SIZE := 40
## Metres per font pixel for a slot's name. Sized so the longest authored name
## fits inside one slot cell; `fitted_pixel_size()` is the check, and a test
## pins it against the real bracket so a longer name in tournament.json cannot
## silently overrun its cell.
const NAME_PIXEL_SIZE := 0.0022
## Mean glyph advance as a fraction of the font size. Same estimate
## `signpost.gd` uses, at the 0.62 the all-caps title needed.
const LABEL_GLYPH_ADVANCE := 0.62
## The four columns' centres, as offsets from the panel's own centre: the
## draw, the quarter-final winners, the semi-final winners, the champion.
const COLUMN_X: PackedFloat32Array = [-0.95, -0.32, 0.28, 0.90]
## One slot cell. Names are centred in it and connectors start at its edge.
const SLOT_WIDTH := 0.52
## The eight draw slots, top to bottom, as offsets from the panel's centre.
const ROW_TOP := 0.34
const ROW_STEP := 0.145
## The title sits above the draw.
const TITLE_Y := 0.62
const TITLE_FONT_SIZE := 40
const TITLE_PIXEL_SIZE := 0.0026
## Connector lines and the empty-slot rules waiting to be filled in.
const LINE_THICKNESS := 0.012
const LINE_DEPTH := 0.006
## An undecided slot is drawn as an empty ruled line rather than left blank,
## so a bracket with nothing decided still READS as a bracket with places
## waiting in it -- which is the whole of what the owner asked for.
const EMPTY_RULE_WIDTH := 0.34
## The one ink colour every painted thing on this board shares.
const INK := Color("#241a10")

var _board: Node3D = null
## One Label3D per bracket slot, by column: 8 in the draw, then 4, 2 and 1.
var _slot_labels: Array = []
## The empty rules under the slots nobody has earned yet, hidden as they fill.
var _slot_rules: Array[MeshInstance3D] = []
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
		post.position = Vector3(side * POST_SPACING, POST_HEIGHT * 0.5, -FRAME_DEPTH)
		_board.add_child(post)

	# The frame the panel is nailed to: two rails between the posts, top and
	# bottom, behind the painted face. Cheap carpentry, and the difference
	# between "a board built out of boards" and "a rectangle floating between
	# two dowels".
	for edge in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "Rail_%s" % ("B" if edge < 0.0 else "T")
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(POST_SPACING * 2.0 + POST_RADIUS * 2.0,
			RAIL_THICKNESS, RAIL_THICKNESS)
		rail_mesh.material = timber
		rail.mesh = rail_mesh
		rail.position = Vector3(0.0,
			BOARD_CENTRE_HEIGHT + edge * (BOARD_HEIGHT * 0.5 - RAIL_THICKNESS),
			-FRAME_DEPTH)
		_board.add_child(rail)

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
	box.size = Vector3(POST_SPACING * 2.0 + POST_RADIUS * 2.0, POST_HEIGHT,
		BOARD_THICKNESS + FRAME_DEPTH * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, POST_HEIGHT * 0.5, 0.0)
	body.add_child(shape)
	_board.add_child(body)

	# The painted face: a real bracket. One Label3D per SLOT plus the
	# connectors that join them, rather than one Label3D holding a paragraph.
	#
	# The paragraph is what the owner rejected on sight -- "the tournament
	# bracket should be a bracket" -- and it could not have been anything else:
	# a single centred text block in a proportional font cannot hold columns in
	# line, and this project ships no monospace face to fall back on. Slots
	# placed in metres do not need one.
	var title := Label3D.new()
	title.name = "Title"
	title.font_size = TITLE_FONT_SIZE
	title.pixel_size = TITLE_PIXEL_SIZE
	title.text = "LOWER MEADOWS TOURNAMENT"
	_paint(title, Vector3(0.0, BOARD_CENTRE_HEIGHT + TITLE_Y, 0.0))
	_board.add_child(title)

	_slot_labels.clear()
	var rows := _row_layout()
	for depth in rows.size():
		var column: Array[Label3D] = []
		for i in (rows[depth] as PackedFloat32Array).size():
			var slot := Label3D.new()
			slot.name = "Slot_%d_%d" % [depth, i]
			slot.font_size = NAME_FONT_SIZE
			slot.pixel_size = NAME_PIXEL_SIZE
			_paint(slot, Vector3(
				COLUMN_X[depth], BOARD_CENTRE_HEIGHT + (rows[depth] as PackedFloat32Array)[i], 0.0))
			_board.add_child(slot)
			column.append(slot)
			# The rule a name is written on. Drawn for every slot the player
			# has not earned yet and hidden the moment one is, so an empty
			# bracket still reads as a bracket with places waiting in it
			# instead of as a mostly blank board.
			if depth > 0:
				var rule := _line(
					Vector2(COLUMN_X[depth], (rows[depth] as PackedFloat32Array)[i] - 0.055),
					EMPTY_RULE_WIDTH, LINE_THICKNESS)
				rule.name = "Rule_%d_%d" % [depth, i]
				_board.add_child(rule)
				_slot_rules.append(rule)
		_slot_labels.append(column)

	_build_connectors(rows)

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
	_repaint_bracket(progression)
	if _prompt != null:
		_prompt.set("label", status_line(progression))


## Write the current bracket onto the slots.
##
## Every slot's text comes from `bracket_state()`, so the board can only ever
## show what has actually been decided -- the owner's second ruling, and the
## one that is a RULE rather than a layout: "it should only fill in after
## events, not be filled in from the start."
func _repaint_bracket(progression: RefCounted) -> void:
	if _slot_labels.is_empty():
		return
	var state := bracket_state(progression)
	var fitted := fitted_pixel_size(progression)
	var rule := 0
	for depth in _slot_labels.size():
		if depth >= state.size():
			continue
		var column: Array = state[depth]
		var labels: Array[Label3D] = _slot_labels[depth]
		for i in labels.size():
			if i >= column.size():
				continue
			var name := str((column[i] as Dictionary).get("name", ""))
			labels[i].text = name
			labels[i].pixel_size = fitted
			if depth > 0 and rule < _slot_rules.size():
				# The rule is the empty place; a filled one does not need it.
				_slot_rules[rule].visible = name.is_empty()
				rule += 1


## Where every slot sits vertically, per column: eight places in the draw,
## then four, two and one, each centred between the two it is fed by. Returned
## rather than stored so the connectors and the labels cannot disagree about
## where a row is.
func _row_layout() -> Array:
	var rows: Array = []
	var draw := PackedFloat32Array()
	for i in 8:
		draw.append(ROW_TOP - float(i) * ROW_STEP)
	rows.append(draw)
	for depth in 3:
		var previous: PackedFloat32Array = rows[depth]
		var column := PackedFloat32Array()
		for i in (previous.size() / 2):
			column.append((previous[i * 2] + previous[i * 2 + 1]) * 0.5)
		rows.append(column)
	return rows


## The lines that make it a bracket rather than four lists side by side: for
## every pair, a stub out of each feeding slot, a vertical joining the two,
## and a stub into the slot they feed.
func _build_connectors(rows: Array) -> void:
	for depth in 3:
		var previous: PackedFloat32Array = rows[depth]
		var next: PackedFloat32Array = rows[depth + 1]
		var edge := COLUMN_X[depth] + SLOT_WIDTH * 0.5
		var spine := (COLUMN_X[depth] + COLUMN_X[depth + 1]) * 0.5
		for i in next.size():
			var top := previous[i * 2]
			var bottom := previous[i * 2 + 1]
			for y: float in [top, bottom]:
				_board.add_child(_line(
					Vector2((edge + spine) * 0.5, y - 0.03), spine - edge, LINE_THICKNESS))
			_board.add_child(_line(
				Vector2(spine, (top + bottom) * 0.5 - 0.03),
				LINE_THICKNESS, absf(top - bottom)))
			_board.add_child(_line(
				Vector2((spine + COLUMN_X[depth + 1] - SLOT_WIDTH * 0.5) * 0.5, next[i] - 0.03),
				COLUMN_X[depth + 1] - SLOT_WIDTH * 0.5 - spine, LINE_THICKNESS))


## One painted line on the board's face: a thin dark box a hair proud of the
## panel, the same ink the names are written in.
func _line(at: Vector2, width: float, height: float) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	bar.name = "Line"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(maxf(width, LINE_THICKNESS), maxf(height, LINE_THICKNESS), LINE_DEPTH)
	var ink := StandardMaterial3D.new()
	ink.albedo_color = INK
	ink.roughness = 0.95
	mesh.material = ink
	bar.mesh = mesh
	bar.position = Vector3(at.x, BOARD_CENTRE_HEIGHT + at.y, BOARD_THICKNESS * 0.5 + LINE_DEPTH * 0.5)
	return bar


## The shared setup every painted label on this board wants: dark ink, no
## billboarding (it is paint on a physical panel, not a floating tag), and a
## hair of clearance off the panel face so the two never z-fight.
func _paint(label: Label3D, at: Vector3) -> void:
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = INK
	# Small. At 8 the outline haloed every glyph and, with the pale panel
	# behind it, washed the whole board out to a flat white rectangle in the
	# walk-up frame.
	label.outline_size = 3
	label.outline_modulate = Color("#f4ecd8")
	label.position = Vector3(at.x, at.y, at.z + BOARD_THICKNESS * 0.5 + 0.008)


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

## The bracket as it stands right now: four columns of slots, each either
## NAMED or still waiting.
##
## Returns `[[slot, ...], ...]` -- one array per column, 8/4/2/1 long -- where
## a slot is `{"name": String, "decided": bool}`. An undecided slot carries an
## empty name, and that is the load-bearing part: the owner's ruling is that
## the board "should only fill in after events, not be filled in from the
## start", and the previous board printed "You vs Tam" and "You vs Oskar" from
## the moment the draw opened -- pairings that only exist if you already know
## who wins the quarter-finals. A bracket that prints the future is not a
## bracket, it is a spoiler.
##
## The tree needs no new data. `bracket`'s slot order IS the draw: slots pair
## (1,2), (3,4), (5,6), (7,8), their winners pair up in turn, and the config's
## own `_comment_pairings` describes exactly that shape. So the four
## quarter-final bouts are the four pairs of the first column, and every later
## bout is a pair of winners.
##
## Pure and static, like `status_line()` and for the same reason: the board's
## CONTENT is the interesting half and a test should be able to read it
## without standing a panel up in a world.
static func bracket_state(progression: RefCounted) -> Array:
	var slots := bracket()
	var columns: Array = []

	# Column 0: the draw. Known the moment the draw is posted -- who is IN the
	# tournament is not a result, and a bracket board with no names on it at
	# all would tell a player nothing about what they have entered.
	var draw: Array = []
	for i in 8:
		draw.append({"name": _slot_name(slots, i), "decided": true})
	columns.append(draw)

	# Columns 1-3: winners only, and only once their own bout is decided.
	var round_ids: PackedStringArray = ["quarter", "semi", "final"]
	var previous := draw
	for depth in 3:
		var column: Array = []
		var bouts := previous.size() / 2
		for i in bouts:
			var a := previous[i * 2] as Dictionary
			var b := previous[i * 2 + 1] as Dictionary
			column.append(_bout_winner(
				str(a.get("name", "")), str(b.get("name", "")),
				str(round_ids[depth]), progression))
		columns.append(column)
		previous = column
	return columns


## Who won the bout between `a` and `b`, or an undecided slot.
##
## Three ways a bout can stand:
##
## * one of its two places is still empty -- the bout does not exist yet, so
##   it cannot have a winner. This is what stops the final from naming Oskar
##   before the semi-finals have been fought;
## * the player is in it -- it is one of the three FOUGHT rounds, decided by
##   that round's own `won_flag`, which is the trainer's `defeat_flag`;
## * neither is the player -- it is one of the simulated bouts, decided by its
##   own `reveal_after` flag, which is deliberately the flag of the player's
##   preceding match so the far half of the draw resolves while they fight.
static func _bout_winner(a: String, b: String, round_id: String,
		progression: RefCounted) -> Dictionary:
	var undecided := {"name": "", "decided": false}
	if a.is_empty() or b.is_empty():
		return undecided

	var player := player_slot_name()
	if a == player or b == player:
		var spec := round_spec(round_id)
		var flag := str(spec.get("won_flag", ""))
		if flag.is_empty() or progression == null or not bool(progression.call("has", flag)):
			return undecided
		return {"name": player, "decided": true}

	for entry: Dictionary in simulated_for(round_id):
		var sim_a := str(entry.get("a", ""))
		var sim_b := str(entry.get("b", ""))
		if not ((sim_a == a and sim_b == b) or (sim_a == b and sim_b == a)):
			continue
		var reveal := str(entry.get("reveal_after", ""))
		if reveal.is_empty() or progression == null or not bool(progression.call("has", reveal)):
			return undecided
		return {"name": str(entry.get("winner", "")), "decided": true}
	return undecided


## The name the player's own slot carries on the board. Read from the
## bracket's `player: true` entry rather than written down here, so renaming
## the slot is a data edit.
static func player_slot_name() -> String:
	for entry: Variant in bracket():
		var slot := entry as Dictionary
		if bool(slot.get("player", false)):
			return str(slot.get("name", "You"))
	return "You"


## Metres per font pixel that keeps the longest name the bracket can currently
## show inside one slot cell. Static and pure so a test can assert the fit
## without a panel in the world -- text that does not fit is a defect nobody
## notices in a headless run and everybody notices in a frame.
static func fitted_pixel_size(progression: RefCounted) -> float:
	var longest := 0
	for column: Variant in bracket_state(progression):
		for entry: Variant in (column as Array):
			longest = maxi(longest, str((entry as Dictionary).get("name", "")).length())
	if longest <= 0:
		return NAME_PIXEL_SIZE
	var widest := float(longest) * LABEL_GLYPH_ADVANCE * float(NAME_FONT_SIZE)
	return minf(NAME_PIXEL_SIZE, SLOT_WIDTH / widest)


static func _slot_name(slots: Array, index: int) -> String:
	if index < 0 or index >= slots.size():
		return "?"
	return str((slots[index] as Dictionary).get("name", "?"))


static func _opponent_of(round_spec: Dictionary) -> String:
	return str(round_spec.get("opponent", "?"))


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
