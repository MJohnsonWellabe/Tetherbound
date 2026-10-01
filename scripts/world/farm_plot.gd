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
## ## Stage B Wave 6 lane 6.E: PICKING is a claim; tilling and sowing are not
##
## D103. Picking a ripe bed paid the crop straight into this peer's satchel and
## wrote the bed back to TILLED locally. Two players reaching for the same ripe
## bed therefore each got the full yield. Picking now submits a `harvest`
## INTENT -- the same kind `harvest_node.gd` uses -- against a flag that names
## THIS CROP CYCLE:
##
##     farm:<realm>:<plot index>#<ripe_on_day>
##
## The day the crop ripened is part of the id on purpose. A farm bed is the one
## gather point in this game that comes back, so a flag naming only the bed
## would refuse the second crop it ever grew; a flag naming the bed AND the
## cycle is claimed exactly once per crop and is fresh again the moment the bed
## is re-sown. The host commits the first claim and refuses the rest in one
## sentence the loser can read.
##
## The bed's own `{state, ripe_on_day}` record is NOT replicated, and that is a
## known gap rather than an oversight: `WorldState` has no farm op and
## `world_ledger.gd`/`world_state.gd` are outside this lane's file list. What
## closes most of it anyway is that the committed flag reaches every peer, so
## every peer returns that bed to TILLED off the delta -- see
## `_on_delta_applied`. Tilling and sowing remain local writes; the residual and
## the op that would close it are written down in
## `ralph/reports/MP-6E-CLOUDREACH-0906/REPORT.md`.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
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

var _prompt: Node3D = null
var _soil: MeshInstance3D = null
var _plant: Node3D = null
var _drawn_state: String = ""
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
	LEDGER_CLAIM.listen(self, _on_delta_applied)


## The prompt has to answer for the CURRENT day and the CURRENT satchel, and
## both change without this node being told: the player rests at a camp, or
## spends their last seed on the plot next door. Polled for the same reason
## `sequence_director.gd` polls its own gates -- a label written once at
## build time is a label that is wrong the first time anything moves.
func _process(_delta: float) -> void:
	_refresh()


## --- state ------------------------------------------------------------------

func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _plot() -> Dictionary:
	var game := _game()
	if game == null or _index < 0:
		return FARM_LOGIC.fresh()
	return game.call("farm_plot_at", _index) as Dictionary


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
	var plot := _plot()
	var day := _day()
	var has_hoe := _has_hoe()
	var seeds := _seed_count()

	var state := FARM_LOGIC.state_of(plot, day)
	if state != _drawn_state:
		_drawn_state = state
		_redraw(state)

	var label := FARM_LOGIC.label_for(plot, day, has_hoe, seeds)
	if label != _drawn_label:
		_drawn_label = label
		_prompt.call("configure", label, PROMPT_RADIUS, true)
	# Set separately from configure(), which has no parameter for it: a
	# statement line ("Ripens tomorrow", "Needs a Hoe") has to draw without a
	# button glyph or the HUD promises a press that does nothing. See
	# `interactable.gd`'s own `actionable` export, added for this.
	_prompt.set("actionable", FARM_LOGIC.is_actionable(plot, day, has_hoe, seeds))


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


func _redraw(state: String) -> void:
	_soil.material_override = _material(
		COL_TILLED if state != FARM_LOGIC.FALLOW else COL_FALLOW)

	if _plant != null and is_instance_valid(_plant):
		_plant.queue_free()
	_plant = null
	if state == FARM_LOGIC.FALLOW:
		return
	_build_furrows()

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
	var game := _game()
	if game == null or _index < 0:
		return
	var inventory: RefCounted = game.get("inventory")
	var items: RefCounted = game.get("items")
	if inventory == null or items == null:
		return

	var plot := _plot()
	var day := _day()
	match FARM_LOGIC.action_for(plot, day, _has_hoe(), _seed_count()):
		FARM_LOGIC.ACTION_TILL:
			_till(game, inventory)
		FARM_LOGIC.ACTION_SOW:
			_sow(game, inventory, day)
		FARM_LOGIC.ACTION_HARVEST:
			_harvest(game, inventory, items)
		_:
			# Nothing to do, and the prompt already says why (it is drawn
			# non-actionable in that case). OF20's rule -- a silent refusal
			# reads as "this does nothing at all" -- is answered by the label,
			# not by a second toast on every press.
			pass
	_refresh()


func _till(game: Node, inventory: RefCounted) -> void:
	var slot := HARVEST_LOGIC.tool_slot(FARM_LOGIC.TILL_TOOL, inventory)
	if slot < 0:
		return
	game.call("set_farm_plot", _index, FARM_LOGIC.tilled(_plot()))
	# The hoe wears down on the one thing it does, through the same call an
	# axe pays for a tree (R2.2). D50: once per plot, not once per crop --
	# harvesting returns the bed to TILLED, so a 40-durability hoe is not a
	# tax on farming forever.
	inventory.call("damage_tool", slot)


func _sow(game: Node, inventory: RefCounted, day: int) -> void:
	if not bool(inventory.call("remove", _seed_id, 1)):
		return
	game.call("set_farm_plot", _index, FARM_LOGIC.sown(_plot(), day, _grow_days))


func _harvest(game: Node, inventory: RefCounted, items: RefCounted) -> void:
	# The fourth caller of the shared gather body, alongside harvest_node.gd
	# and vegetation_harvest_point.gd. Berries carry no `gathered_with`, so
	# this returns the full yield and `required_slot` -1 (nothing wears down)
	# -- but it is routed through here anyway so that the day someone DOES
	# tool-gate a crop, the farm already obeys the same durability and
	# wrong-tool rules as every other gather in the game rather than needing
	# to grow its own copy of them.
	var gathered: Dictionary = HARVEST_LOGIC.gather(_crop_id, _yield, inventory, items)
	var amount := int(gathered["amount"])
	if amount <= 0:
		return
	if not bool(inventory.call("has_room_for", _crop_id, amount)):
		# INTERACT-SWEEP-0903: this claimed "refused, visibly" without ever
		# saying anything -- `FARM_LOGIC.is_actionable()` has no notion of
		# satchel capacity, so the prompt stays green and a press on a full
		# satchel produced nothing a player could tell apart from a dropped
		# press. Now speaks, matching `harvest_node.gd`'s own fix.
		#
		# Still LOCAL and still ahead of the intent: `world_ledger.gd`'s own
		# header says the host cannot see a client's satchel, so "is there room"
		# is a question only the pressing peer can answer.
		game.call("push_world_message", "Satchel is full.")
		return
	if not _claim.is_empty():
		# A press while this peer's own claim is still with the host. Waiting is
		# the honest answer; submitting again would only lose to itself.
		return
	# Recorded BEFORE the submit, because solo and host commit in-process and
	# `submit()` emits the delta before it returns -- `_on_delta_applied` has
	# already run by the time the next line finishes.
	_claim = {"flag": claim_flag(), "slot": int(gathered["required_slot"])}
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "harvest",
		"realm": _realm,
		"flag": _claim["flag"],
		"item": _crop_id,
		"amount": amount,
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		# Refused outright (someone else picked this crop, or there is no
		# transport). `ledger_claim.gd` has already shown the sentence.
		_claim = {}
		if str(verdict.get("code", "")) != "offline":
			harvest_refused.emit(str(verdict.get("code", "")), str(verdict.get("reason", "")))
		if str(verdict.get("code", "")) == "offline":
			# No transport at all: a unit fixture or a capture tool. The old
			# local path, unchanged, for the same reason every other consumer
			# keeps one -- a farm that grows crops and refuses to pay them is
			# worse than one written locally in a process with nobody to tell.
			inventory.call("add", _crop_id, amount)
			var slot := int(gathered["required_slot"])
			if slot >= 0:
				inventory.call("damage_tool", slot)
			game.call("set_farm_plot", _index, FARM_LOGIC.harvested(_plot()))


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


## A committed delta landed on this peer, host or client.
##
## Two halves, and the order matters. The DELTA is checked first: any peer whose
## delta carries a claim on this bed returns the bed to worked soil, which is
## what keeps six beds looking the same on two screens without a farm op in
## `WorldState`. Only then is this peer's own `_claim` consulted, for the half
## no delta carries -- the tool it wore down. Written the other way round, a
## guard on `_claim` alone would drop the mirror on every peer but the presser
## (the ordering lane 3.B paid for, in `ledger_rpc.gd::_rpc_delta`).
##
## The crop itself is NOT added here: `harvest`'s item grant is a player-scope
## op addressed to the winning peer, and `ledger_rpc.gd::_apply_player_ops`
## already put it in their satchel.
func _on_delta_applied(delta: Dictionary) -> void:
	if _index < 0:
		return
	var prefix := claim_prefix()
	var claimed := ""
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("scope", "")) != "world" or str(op.get("op", "")) != "flag":
			continue
		var id := str(op.get("id", ""))
		if id.begins_with(prefix) and bool(op.get("value", true)):
			claimed = id
			break
	if claimed.is_empty():
		return
	var game := _game()
	if game != null:
		game.call("set_farm_plot", _index, FARM_LOGIC.harvested(_plot()))
	if _claim.is_empty() or str(_claim.get("flag", "")) != claimed:
		return
	var slot := int(_claim.get("slot", -1))
	_claim = {}
	if slot >= 0 and game != null:
		var inventory: RefCounted = game.get("inventory")
		if inventory != null:
			inventory.call("damage_tool", slot)
	_refresh()
