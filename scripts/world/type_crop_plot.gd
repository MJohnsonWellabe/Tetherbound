extends Node3D

## One bed of the berry farm beside Grandpa's house: a patch of ground, a
## prompt, and whichever of till/sow/pick the patch is ready for.
##
## R7.6. The rules are all in `scripts/world/farm_logic.gd` (pure, tested by
## `tests/test_farming.gd`); this file is the body that draws them and wires
## them to the satchel. `harvest_node.gd`/`vegetation_harvest_point.gd` are
## the two existing gather bodies and this is deliberately built the same
## shape as both -- an `interactable.gd` child that emits `activated`, a
## public `gather()` so a tool swing reaches the identical code path, and
## membership of `harvest_logic.gd`'s `harvestable` group so
## `scripts/player/tool_hold.gd` can find it without knowing what drew it.
##
## ## One verb, four states
##
## `gather()` means "do whatever this plot is ready for" rather than "pick".
## That is not cleverness for its own sake: `tool_hold.gd::_resolve_swing()`
## calls `gather()` on the nearest thing in the swing cone and has no
## vocabulary for anything else, so a plot that wanted a second entry point
## for tilling would need a second swing verb in the player controller --
## which is precisely what R7.6's brief rules out ("a hoe is an items.json
## entry and a swing target, not new player code"). One method, and
## `farm_logic.action_for()` decides which of the three it is.
##
## The consequence worth stating: swinging an AXE at a fallow plot tills it,
## as long as a working hoe is in the satchel, because the gating is on what
## you OWN and not on what is in your hand -- exactly how
## `harvest_logic.gather()` has always gated wood and stone. Making the farm
## the one place in the game where the equipped item matters would be a new
## rule, not a smaller one.
##
## ## The crop is not respawn
##
## `harvest_node.gd` hides itself for 60 seconds and comes back; this does
## not. A picked plot returns to bare worked soil and stays there until the
## player sows it again, which is the whole difference between a farm and a
## bush -- and why the state has to be saved (`game_state.gd::farm_plots`)
## rather than rebuilt from nothing on load the way a respawn timer can be.
##
## F32: every durable verb is a typed host intent. The host resolves the
## authored plot, day, seed/crop definition, Greenhouse and inventory. This
## consumer only selects a crop and refreshes after an internal farm_plot_set
## delta; it never writes a plot, debits seeds or awards harvest locally.
## Landing requires the foundation's atomic world/character transaction.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const TYPE_PRESENTATION := preload("res://scripts/world/essence_node_mount.gd")
const PRESENTATION_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LOCAL_PAUSE := preload("res://scripts/ui/local_pause.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

## The host refused this peer's pick, with one sentence a player can act on.
## The mirror of `item_cache_pickup.gd::claim_refused`, and it exists for the
## same reason: a HOST that loses a race is refused synchronously inside
## `submit()`, where nothing on the transport ever fires -- `intent_refused` is
## only emitted for the peer a `_rpc_verdict` was addressed to. Without this a
## losing host would be observable only as a bed that quietly stayed ripe.
signal harvest_refused(code: String, reason: String)

## The nature kit again (D24: one nature family). The ripe bush is the SAME
## model `data/config/harvest.json`'s two wild berry nodes use -- a farmed
## berry bush and a wild one are the same plant, and giving the farm its own
## species would be a crop variety, which §21 does not have.
const NATURE_DIR := "res://assets/environment/stylized_nature"
const RIPE_MODEL := "%s/Bush_Common_Flowers.gltf" % NATURE_DIR
const SPROUT_MODEL := "%s/Grass_Common_Short.gltf" % NATURE_DIR

## Soil colours per state. Flat colour, not the kit's trim atlas: a 1.6m bed
## sampling a trim sheet is the same defect `grandpa_house.gd`'s KIT_TEXTURES
## comment records for its loft beam. TUNABLE.
const COL_FALLOW := Color("#6b6446")
const COL_TILLED := Color("#4a3524")
const COL_EDGE := Color("#6b4f30")

## Metres. The bed itself, and how proud of the ground it sits -- enough to
## read as a raised seedbed from standing height, low enough that the player
## walks over it rather than onto it (no collider: a farm you trip on is a
## farm you stop visiting).
##
## Round 1 of the visual pass had this at 1.5 x 1.5 x 0.08, and the frames
## showed exactly what that costs: at 0.08m a bed has no visible SIDE, so it
## renders as a brown rectangle painted onto the grass rather than as turned
## earth. Raised, and given the timber lip and furrow ridges below, so the
## thing has a thickness and a direction you can read from standing height.
const BED_SIZE := Vector2(1.4, 1.4)
const BED_HEIGHT := 0.16
const EDGE_T := 0.09
const EDGE_H := 0.22
const FURROWS := 3
const FURROW_H := 0.07

## Model scales, per state. Round 1's ripe bush at 1.0 measured wider than its
## own 1.5m bed: six of them merged into one continuous flowering hedge
## against the farmhouse wall, so the frames showed a garden border and not a
## farm — no rows, no plots, no soil. A crop has to sit IN its bed for six
## beds to read as six.
const RIPE_SCALE := 0.5
const SPROUT_SCALE := 0.3

const PROMPT_RADIUS := 2.0
const PROMPT_HEIGHT := 0.9

## Which entry of `game_state.gd::farm_plots` this bed is. Assigned by
## `playground_world.gd` from the order in data/config/farm.json, so a plot's
## saved state follows its POSITION in the data rather than its node name.
var _index: int = -1
var _grow_days: int = 1
var _yield: int = 3
var _seed_id: String = "berry_seeds"
var _crop_id: String = "berries"
var _plot_id := ""
var _source_service: Node


func setup_source(plot_id: String, config: Dictionary, service: Node) -> void:
	_plot_id = plot_id
	_source_service = service
	if service != null and not service.is_connected("settled", _on_source_settled):
		service.connect("settled", _on_source_settled)
	setup(int(plot_id.trim_prefix("authored:")), config, "meadows")
var _config: Dictionary = {}
var _selected_crop: String = "berries"
var _seed_picker: CanvasLayer
var _closing_cancel := false
var _closing_confirm := false
var _queued_sow_crop := ""
var _mouse_before := Input.MOUSE_MODE_CAPTURED

var _prompt: Node3D = null
var _soil: MeshInstance3D = null
var _plant: Node3D = null
var _drawn_state: String = ""
var _drawn_crop: String = ""
var _drawn_label: String = ""
var _materials: Dictionary = {}

## D97. The realm this BED belongs to, stamped on every intent it raises. Set by
## whoever places the plots; never read off `Game.current_realm`, which from
## Wave 6 is the local player's realm and not the record's.
var _realm: String = "meadows"

## The claim this peer has with the host: `{"flag", "slot"}`. Empty whenever
## nothing is in flight. NOTHING local moves while it is set -- no crop, no tool
## wear, no state change.
var _claim: Dictionary = {}


func setup(index: int, config: Dictionary, realm_id: String = "meadows") -> void:
	_index = index
	_config = config.duplicate(true)
	_selected_crop = str(config.get("default_crop", "berries"))
	_realm = realm_id if not realm_id.is_empty() else "meadows"
	_grow_days = maxi(1, int(config.get("grow_days", 1)))
	_yield = maxi(1, int(config.get("yield", 3)))
	_seed_id = str(config.get("seed_item", "berry_seeds"))
	_crop_id = str(config.get("crop_item", "berries"))

	_soil = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(BED_SIZE.x, BED_HEIGHT, BED_SIZE.y)
	_soil.mesh = box
	_soil.position = Vector3(0.0, BED_HEIGHT * 0.5, 0.0)
	add_child(_soil)
	_build_edging()

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * PROMPT_HEIGHT
	_prompt.call("configure", "", PROMPT_RADIUS, true)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)

	_refresh()


func _ready() -> void:
	# So a hoe swing finds this the same way an axe swing finds a tree
	# (`harvest_logic.gd::GROUP`).
	add_to_group(HARVEST_LOGIC.GROUP)
	add_to_group(INPUT_OWNER.GROUP)
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	var transport := LEDGER_CLAIM.transport(self)
	if transport != null and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


## The prompt has to answer for the CURRENT day and the CURRENT satchel, and
## both change without this node being told: the player rests at a camp, or
## spends their last seed on the plot next door. Polled for the same reason
## `sequence_director.gd` polls its own gates -- a label written once at
## build time is a label that is wrong the first time anything moves.
func _process(_delta: float) -> void:
	if _closing_cancel and not Input.is_action_pressed("menu_cancel"):
		_closing_cancel = false
	if _closing_confirm and not Input.is_action_pressed("ui_accept"):
		_closing_confirm = false
	# Closing confirm remains owned until release. Submit only afterwards, so
	# the host sees ordinary world input instead of this picker's closing edge.
	if not _queued_sow_crop.is_empty() and not owns_input() and INPUT_OWNER.current(get_tree()) == null:
		var crop := _queued_sow_crop
		_queued_sow_crop = ""
		_submit_action(FARM_LOGIC.ACTION_SOW, crop)
	if is_open():
		if Input.is_action_just_pressed("menu_cancel"):
			INPUT_OWNER.suppress_pause_reopen(get_tree())
			_close_seed_picker()
		elif FARM_LOGIC.state_of(_plot(), _day()) != FARM_LOGIC.TILLED:
			_close_seed_picker()
	_refresh()


## --- state ------------------------------------------------------------------

func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _plot() -> Dictionary:
	if _source_service != null and is_instance_valid(_source_service):
		return _source_service.call("plot", _realm, _plot_id)
	return {} # Unknown typed stock is never a fresh/free plot.


func _day() -> int:
	var game := _game()
	return int(game.get("day")) if game != null else 1


func _has_hoe() -> bool:
	var game := _game()
	if game == null:
		return false
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return false
	return HARVEST_LOGIC.tool_slot(FARM_LOGIC.TILL_TOOL, inventory) >= 0


func _seed_count() -> int:
	var game := _game()
	if game == null:
		return 0
	var inventory: RefCounted = game.get("inventory")
	return int(inventory.call("count", _seed_id)) if inventory != null else 0


## --- what the player sees ---------------------------------------------------

func _refresh() -> void:
	if _prompt == null:
		return
	var plot := _plot()
	if plot.is_empty():
		_prompt.call("set_enabled", false)
		return
	_prompt.call("set_enabled", true)
	var day := _day()
	var has_hoe := _has_hoe()
	var greenhouse := _greenhouse_built()
	var choices := FARM_LOGIC.available_crops(_config, _seed_counts(), greenhouse)
	var state := FARM_LOGIC.state_of(plot, day)
	var visual_crop := str(plot.get("crop_id", _config.get("default_crop", "berries")))
	if state != _drawn_state or visual_crop != _drawn_crop:
		_drawn_state = state
		_drawn_crop = visual_crop
		_redraw(state, visual_crop)
	var label := FARM_LOGIC.crop_label_for(plot, day, has_hoe, _selected_seed_count(),
		_config, _selected_crop, greenhouse)
	var actionable := FARM_LOGIC.crop_action_for(plot, day, has_hoe, _selected_seed_count(),
		_config, _selected_crop, greenhouse) != FARM_LOGIC.ACTION_NONE
	if state == FARM_LOGIC.TILLED:
		label = "Choose seeds" if not choices.is_empty() else "Needs seeds"
		actionable = not choices.is_empty()
	if not _claim.is_empty():
		label = "Waiting for the world"
		actionable = false
	if label != _drawn_label:
		_drawn_label = label
		_prompt.call("configure", label, PROMPT_RADIUS, true)
	_prompt.set("actionable", actionable)


## Four boards round the rim of the bed, standing proud of the soil.
##
## Built once and never redrawn: the frame of a bed does not change with what
## is growing in it, and it is what makes a FALLOW bed still read as somebody's
## plot rather than as a patch of dead grass — which matters, because fallow is
## the state a player meets the farm in before they own a hoe.
func _build_edging() -> void:
	var half := BED_SIZE * 0.5
	for spec: Array in [
		[Vector3(BED_SIZE.x + EDGE_T * 2.0, EDGE_H, EDGE_T), Vector3(0.0, 0.0, half.y + EDGE_T * 0.5)],
		[Vector3(BED_SIZE.x + EDGE_T * 2.0, EDGE_H, EDGE_T), Vector3(0.0, 0.0, -half.y - EDGE_T * 0.5)],
		[Vector3(EDGE_T, EDGE_H, BED_SIZE.y), Vector3(half.x + EDGE_T * 0.5, 0.0, 0.0)],
		[Vector3(EDGE_T, EDGE_H, BED_SIZE.y), Vector3(-half.x - EDGE_T * 0.5, 0.0, 0.0)],
	]:
		var mesh := MeshInstance3D.new()
		var board := BoxMesh.new()
		board.size = spec[0] as Vector3
		mesh.mesh = board
		mesh.material_override = _material(COL_EDGE)
		mesh.position = (spec[1] as Vector3) + Vector3.UP * (EDGE_H * 0.5)
		add_child(mesh)


## Parallel ridges across a worked bed: the difference between "brown" and
## "turned over". Cleared and rebuilt with the plant, because a FALLOW bed has
## no furrows in it — that is the whole visual difference between unworked
## ground and a seedbed, and round 1 had none.
func _build_furrows() -> void:
	var pitch := BED_SIZE.y / float(FURROWS + 1)
	for i in FURROWS:
		var mesh := MeshInstance3D.new()
		var ridge := BoxMesh.new()
		ridge.size = Vector3(BED_SIZE.x * 0.92, FURROW_H, pitch * 0.42)
		mesh.mesh = ridge
		mesh.material_override = _material(COL_EDGE)
		mesh.position = Vector3(
			0.0, BED_HEIGHT + FURROW_H * 0.35, -BED_SIZE.y * 0.5 + pitch * float(i + 1))
		_plant_holder().add_child(mesh)


## Everything that changes with the state hangs off one node, so `_redraw` can
## clear the lot without tracking each piece.
func _plant_holder() -> Node3D:
	if _plant == null or not is_instance_valid(_plant):
		_plant = Node3D.new()
		_plant.name = "Growth"
		add_child(_plant)
	return _plant


func _redraw(state: String, crop_id: String = "") -> void:
	_soil.material_override = _material(
		COL_TILLED if state != FARM_LOGIC.FALLOW else COL_FALLOW)

	if _plant != null and is_instance_valid(_plant):
		_plant.queue_free()
	_plant = null
	if state == FARM_LOGIC.FALLOW:
		return
	_build_furrows()
	if _try_typed_crop_candidate(state, crop_id):
		return

	var model := ""
	var model_scale := 1.0
	match state:
		FARM_LOGIC.SOWN:
			model = SPROUT_MODEL
			model_scale = SPROUT_SCALE
		FARM_LOGIC.RIPE:
			model = RIPE_MODEL
			model_scale = RIPE_SCALE
	if model.is_empty() or not ResourceLoader.exists(model):
		return

	# The nature kit's pieces are glTF, so they load as PackedScene rather than
	# Mesh -- the same fork `harvest_node.gd::_build_visual` documents at
	# length after every one of its twelve authored props silently failed to
	# render for exactly this reason.
	var resource: Resource = load(model)
	if not (resource is PackedScene):
		push_warning("farm plot model '%s' did not load as a PackedScene" % model)
		return
	var wrapper := Node3D.new()
	wrapper.add_child((resource as PackedScene).instantiate())
	wrapper.scale = Vector3.ONE * model_scale
	wrapper.position = Vector3(0.0, BED_HEIGHT, 0.0)
	_plant_holder().add_child(wrapper)


func _material(colour: Color) -> StandardMaterial3D:
	if _materials.has(colour):
		return _materials[colour]
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 1.0
	_materials[colour] = m
	return m


## --- the verb ----------------------------------------------------------------

func _on_activated() -> void:
	gather()


## Do whatever this plot is ready for. See the header for why there is only
## one of these.
##
## Public and identically named to `harvest_node.gd::gather()` and
## `vegetation_harvest_point.gd::gather()` so a swing and a prompt press can
## never disagree -- and so `tool_hold.gd` needs no knowledge that farm plots
## exist at all.
func gather(_equipped_tool: Variant = null) -> void:
	if _game() == null or _index < 0 or not _claim.is_empty() or owns_input():
		return
	var state := FARM_LOGIC.state_of(_plot(), _day())
	match state:
		FARM_LOGIC.FALLOW:
			if _has_hoe():
				_submit_action(FARM_LOGIC.ACTION_TILL)
		FARM_LOGIC.TILLED:
			_open_seed_picker()
		FARM_LOGIC.RIPE:
			if not FARM_LOGIC.harvest_candidate(_plot(), _day(), _config).is_empty():
				_submit_action(FARM_LOGIC.ACTION_HARVEST)
	_refresh()


func _submit_action(action: String, crop_id: String = "") -> void:
	if not _claim.is_empty():
		return
	if _source_service == null or not is_instance_valid(_source_service) or _plot_id.is_empty():
		return
	var txn := Crypto.new().generate_random_bytes(16).hex_encode()
	var expected := int(_plot().get("revision", 0))
	_claim = {"txn_id": txn, "action": action, "expected_revision": expected}
	var intent := {"plot_id": _plot_id, "action": action, "crop_id": crop_id,
		"expected_stock_revision": expected, "action_id": txn}
	var verdict: Dictionary = _source_service.call("submit", "farm", intent, self)
	if not LEDGER_CLAIM.in_flight(verdict):
		_claim = {}
		harvest_refused.emit(str(verdict.get("code", "")), str(verdict.get("reason", "")))


func _on_source_settled(op: String, source_id: String, action_id: String, verdict: Dictionary) -> void:
	if op != "farm" or source_id != _plot_id: return
	if not _claim.is_empty() and str(_claim.get("txn_id", "")) == action_id:
		_claim = {}
		if verdict.get("ok") != true or verdict.get("owner_saved") != true or verdict.get("owner_acknowledged") != true:
			harvest_refused.emit(str(verdict.get("code", "awaiting_settlement")), str(verdict.get("reason", "")))
	_refresh()


## The world fact "this crop cycle has been picked". Realm-qualified and
## cycle-qualified: see the header for why the ripening day is part of the id.
func claim_flag() -> String:
	return claim_flag_for(_realm, _index, int(_plot().get("ripe_on_day", 0)))


static func claim_flag_for(realm: String, index: int, ripe_on_day: int) -> String:
	return "farm:%s:%d#%d" % [realm, index, ripe_on_day]


## Every claim id this bed could ever mint, so a peer that did NOT press can
## still recognise its neighbour's committed pick without having to agree about
## which day the crop ripened.
func claim_prefix() -> String:
	return "farm:%s:%d#" % [_realm, _index]


## Internal world op is already applied durably by the foundation transport.
## Never write another local copy off a flag; never pay inventory/tool wear here.
func _on_delta_applied(delta: Dictionary) -> void:
	for raw: Variant in delta.get("ops", []):
		if not raw is Dictionary:
			continue
		if str(raw.get("op", "")) != "farm_plot_set" or str(raw.get("scope", "")) != "world" \
				or str(raw.get("realm", "")) != _realm or int(raw.get("index", -1)) != _index:
			continue
		if _source_service == null and not _claim.is_empty() and str(raw.get("txn_id", "")) == str(_claim.get("txn_id", "")):
			_claim = {}
		_refresh()


func _on_intent_refused(kind: String, code: String, reason: String, detail: Dictionary) -> void:
	if kind != "farm_plot_action" or _claim.is_empty() \
			or str(detail.get("txn_id", "")) != str(_claim.get("txn_id", "")):
		return
	_claim = {}
	harvest_refused.emit(code, reason)
	_refresh()


func _seed_counts() -> Dictionary:
	var result := {}
	var game := _game()
	var inventory: RefCounted = game.get("inventory") if game != null else null
	if inventory == null:
		return result
	for crop_id: Variant in _config.get("crop_order", []):
		var definition := FARM_LOGIC.crop_definition(_config, str(crop_id))
		if not definition.is_empty():
			var seed := str(definition["seed_item"])
			result[seed] = int(inventory.call("count", seed))
	return result


func _selected_seed_count() -> int:
	var definition := FARM_LOGIC.crop_definition(_config, _selected_crop)
	return int(_seed_counts().get(str(definition.get("seed_item", "")), 0))


func _greenhouse_built() -> bool:
	var game := _game()
	if game == null:
		return false
	var definition: Dictionary = _config.get("greenhouse", {})
	var id := str(definition.get("buildable_id", ""))
	if id.is_empty():
		return false
	for row: Variant in game.get("placed_buildings"):
		if row is Dictionary and str(row.get("id", "")) == id and str(row.get("realm", "meadows")) == _realm:
			return true
	return false


func is_open() -> bool:
	return is_instance_valid(_seed_picker) and _seed_picker.visible


func owns_input() -> bool:
	return is_open() or _closing_cancel or _closing_confirm


func _open_seed_picker() -> void:
	if is_open() or INPUT_OWNER.current(get_tree()) != null:
		return
	var choices := FARM_LOGIC.available_crops(_config, _seed_counts(), _greenhouse_built())
	if choices.is_empty():
		return
	_seed_picker = CanvasLayer.new()
	_seed_picker.layer = 80
	add_child(_seed_picker)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_seed_picker.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var presentation: Dictionary = _config.get("presentation", {})
	panel.custom_minimum_size.x = float(presentation.get("panel_width", 560))
	var style := UI_TOKENS.panel_box(UI_TOKENS.BG_PANEL, UI_TOKENS.BORDER)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	panel.add_child(rows)
	var title := Label.new()
	title.text = "Plant a crop"
	title.add_theme_font_size_override("font_size", UI_TOKENS.FONT_TITLE)
	rows.add_child(title)
	var first: Button
	var counts := _seed_counts()
	var greenhouse := _greenhouse_built()
	for raw_id: Variant in _config.get("crop_order", []):
		var crop_id := str(raw_id)
		var crop := FARM_LOGIC.crop_definition(_config, crop_id)
		if crop.is_empty():
			continue
		var count := int(counts.get(str(crop["seed_item"]), 0))
		var allowed := FARM_LOGIC.can_grow(_config, crop_id, greenhouse)
		var button := Button.new()
		button.text = "%s · %d seeds · %d days" % [str(crop.get("name", crop_id)), count, int(crop["grow_days"])]
		if not allowed:
			button.text += " · Needs a Greenhouse"
		button.disabled = not allowed or count < 1
		button.custom_minimum_size.y = float(presentation.get("crop_row_height", 36))
		button.add_theme_font_size_override("font_size", UI_TOKENS.FONT_BODY)
		button.pressed.connect(_choose_crop.bind(crop_id))
		rows.add_child(button)
		if first == null and not button.disabled:
			first = button
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_close_seed_picker)
	rows.add_child(cancel)
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	LOCAL_PAUSE.hold(get_tree())
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if first != null:
		first.grab_focus()


func _choose_crop(crop_id: String) -> void:
	_selected_crop = crop_id
	_close_seed_picker()
	if FARM_LOGIC.state_of(_plot(), _day()) == FARM_LOGIC.TILLED \
			and FARM_LOGIC.available_crops(_config, _seed_counts(), _greenhouse_built()).has(crop_id):
		_queued_sow_crop = crop_id


func _close_seed_picker() -> void:
	if not is_open():
		return
	_seed_picker.visible = false
	_seed_picker.queue_free()
	_seed_picker = null
	var release_world := INPUT_OWNER.current(get_tree()) == null
	_closing_cancel = Input.is_action_pressed("menu_cancel")
	_closing_confirm = Input.is_action_pressed("ui_accept")
	if release_world:
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)
		Input.mouse_mode = _mouse_before
		LOCAL_PAUSE.release(get_tree())


func _exit_tree() -> void:
	_close_seed_picker()


## F32 flag-off visual candidate. Reads the host-mirrored crop id and draws;
## it does not plant, pay, advance time or replace any durable plot state.
func _try_typed_crop_candidate(state: String, crop_id: String) -> bool:
	if crop_id == str(_config.get("default_crop", "berries")) \
			or not state in [FARM_LOGIC.SOWN, FARM_LOGIC.RIPE]:
		return false
	var candidate: Variant = _config.get("crop_presentation_candidate")
	if not candidate is Dictionary or typeof(candidate.get("enabled")) != TYPE_BOOL \
			or candidate["enabled"] != true:
		return false
	var profiles: Variant = candidate.get("profiles")
	var multipliers: Variant = candidate.get("state_scale_multipliers")
	if not profiles is Dictionary or not multipliers is Dictionary:
		return false
	var profile: Variant = profiles.get(crop_id)
	var multiplier: Variant = multipliers.get(state)
	if not profile is Dictionary or not profile.get("model") is String \
			or not TYPE_PRESENTATION._candidate_scale(profile.get("scale")) \
			or not TYPE_PRESENTATION._candidate_scale(multiplier) \
			or not TYPE_PRESENTATION._candidate_number(profile.get("floor_offset_m")) \
			or float(profile["floor_offset_m"]) < 0.0 \
			or not profile.get("surface_accents") is Dictionary:
		return false
	var model := str(profile["model"])
	if not ResourceLoader.exists(model):
		return false
	var resource: Resource = load(model)
	if not resource is PackedScene:
		return false
	var instance: Node = (resource as PackedScene).instantiate()
	if not instance is Node3D:
		if instance != null:
			instance.free()
		return false
	var part := instance as Node3D
	if not TYPE_PRESENTATION._candidate_render_only(part) \
			or not TYPE_PRESENTATION._candidate_accents(part, profile["surface_accents"]):
		part.free()
		return false
	PRESENTATION_MATERIALS.make_dielectric(part)
	var wrapper := Node3D.new()
	wrapper.name = "TypedCropPresentationCandidate"
	wrapper.add_child(part)
	part.scale = Vector3.ONE * float(profile["scale"]) * float(multiplier)
	part.position.y = float(profile["floor_offset_m"]) * float(multiplier)
	wrapper.position = Vector3(0.0, BED_HEIGHT, 0.0)
	_plant_holder().add_child(wrapper)
	wrapper.set_meta("crop_presentation_candidate", crop_id)
	return true
