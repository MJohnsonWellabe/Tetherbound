extends SceneTree

## T3-TYPECHART's two HUD tells, rendered so they can actually be looked at.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_type_tell.gd
##
## `docs/AGENT_WORKFLOW.md` ("Visual-affecting work needs a blind pass, not a
## look") requires representative frames of the actual change before a
## visual-affecting task is done, and endorses a small purpose-built capture
## where the existing tools do not fit. They do not fit here, for one specific
## reason: **the tells only appear in a NON-NEUTRAL matchup**, and which types
## meet in a real fight is the encounter director's choice. `survey_combat.gd`
## and `capture_ui_suite.gd` both boot the meadows world and shoot whatever
## spawned -- `tests/smoke_combat.gd` drew ground-vs-ground and produced three
## neutral verdicts, which is a legitimate fight and a useless frame for this.
##
## So this boots `scenes/combat/combat_hud.tscn` ALONE against a stub manager,
## which is both far faster than the world (no terrain, no streaming, no
## software-rendered meadow) and the only way to pin the matchup. What is being
## judged is a HUD panel, and a HUD panel drawn over a grey field is the same
## HUD panel.
##
## `_StubManager` implements the nineteen methods `combat_hud.gd` calls plus the
## signals it connects. It is deliberately dumb: every method returns a fixed
## value chosen to put the HUD in an ordinary mid-fight state, so the only thing
## varying between frames is the matchup.
##
## Four frames into `shots/_diag/`:
##
##   type_tell_advantage - water ally vs ground foe: the arrow reads UP
##   type_tell_weak      - air ally vs ground foe: the arrow reads DOWN
##   type_tell_neutral   - ground vs ground: no arrow, the tag exactly as it
##                         was before this system existed (the regression frame)
##   type_tell_banner    - the per-hit STRONG verdict up under the enemy plate

const HUD_SCENE := "res://scenes/combat/combat_hud.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const OUT_DIR := "res://shots/_diag"

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _manager: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	# `root` is not usable yet in `_init`: adding a node here without waiting
	# first leaves it out of the tree, so `get_path()` fails and the HUD gets an
	# empty `manager_path` -- which does NOT crash, because `combat_hud.gd`
	# null-guards its manager. It just draws nothing, and the frames come back
	# as a flat blue field that looks like a rendering problem rather than a
	# wiring one. Cost an hour once; one await is the whole fix.
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_manager = _StubManager.new()
	_manager.name = "StubManager"
	root.add_child(_manager)

	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	_hud.set("manager_path", _manager.get_path())
	root.add_child(_hud)
	for i in 20:
		await process_frame

	# Ground foe throughout, because ground is 57.6% of the chapter's authored
	# opposition -- the matchup a player meets most is the one worth judging.
	await _shoot_matchup("type_tell_advantage", "ripplet", "mudsnout")
	await _shoot_matchup("type_tell_weak", "galewisp", "mudsnout")
	await _shoot_matchup("type_tell_neutral", "terrapup", "mudsnout")

	# T3-MATCHUPS. The five expansion types had no colour of their own, so the
	# enemy tag drew every one of them in GROUND_OCHRE -- the GROUND colour,
	# under a matchup verdict that is now real. These three frames are the ones
	# that check the new colours against each other and against the three that
	# were already there, which is the thing a unit test cannot do: whether
	# ICE_FROST reads as separable from WATER_BLUE and AIR_SKY, and whether
	# DARK_VIOLET and PSYCHIC_LILAC are two colours or one, is a question about
	# pixels.
	#
	# Ripplet is the ally throughout so the arrow varies with the row rather
	# than staying constant: water is neutral into dark, 1.25 into fire and
	# 1.00 into psychic under this chart.
	await _shoot_matchup("type_tell_dark", "ripplet", "nightburrow")
	await _shoot_matchup("type_tell_electric", "ripplet", "stormtrail")
	await _shoot_matchup("type_tell_psychic", "ripplet", "riftfrill")
	await _shoot_matchup("type_tell_fire", "ripplet", "ashtusk")

	# The double weakness, which is the whole reason the tag now writes both
	# halves: a Water move into Ashtusk (Ground/Fire) is 1.5625, the only
	# pairing in the game that reaches it. Before this the plate read "GROUND"
	# and the player had no way to tell why the hit landed harder here than
	# against the Burrowback behind them.
	await _shoot_matchup("type_tell_dual_word", "ripplet", "ashtusk")

	# THE ONE PLACE THE NEW COLOURS ARE REACHABLE TODAY, and the reason this
	# frame exists rather than being assumed: the enemy tag paints the VERDICT
	# colour whenever the matchup is non-neutral, and all four live dual-typed
	# creatures have a ground or water PRIMARY -- so no shipped foe can put a
	# fire/electric/ice/psychic/dark colour on that tag at all. The action
	# grid's move hairlines can. Stormtrail's quick is `spark_bite` (Electric),
	# so piloting it draws ELECTRIC_GOLD under the quick cell where it used to
	# draw GROUND_OCHRE, which was the fallback bug.
	await _shoot_matchup("type_tell_move_hairline", "stormtrail", "mudsnout")

	# The banner, on the same advantaged pairing that produces it in play.
	_manager.set_pair(_make("ripplet", 12), _make("mudsnout", 12))
	for i in 10:
		await process_frame
	_manager.emit_signal("hit_effectiveness", true, 1)
	# Fewer frames than the banner's 0.7s life, so it is still up when the
	# shutter opens.
	for i in 6:
		await process_frame
	await _shoot("type_tell_banner")

	_report()


func _make(species_id: String, level: int) -> RefCounted:
	var definition: Dictionary = SPECIES.definition(species_id)
	if definition.is_empty():
		_failures.append("species '%s' is missing" % species_id)
		return null
	var creature: RefCounted = INSTANCE.from_species(species_id, definition)
	creature.level = level
	# Mid-fight, not pristine: a full bar tells you nothing about how the plate
	# reads while a fight is actually being lost or won.
	creature.hp = creature.max_hp * 0.62
	return creature


func _shoot_matchup(name: String, ally_id: String, foe_id: String) -> void:
	var ally := _make(ally_id, 12)
	var foe := _make(foe_id, 12)
	if ally == null or foe == null:
		return
	_manager.set_pair(ally, foe)
	for i in 10:
		await process_frame
	print("%s: %s (%s) vs %s (%s) -> arrow %d"
		% [name, ally_id, ally.creature_type, foe_id, foe.creature_type,
			int(_manager.call("active_matchup"))])
	await _shoot(name)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: no framebuffer" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
	else:
		print("wrote %s" % path)


func _report() -> void:
	if _failures.is_empty():
		print("\ntype-tell capture: OK")
		quit(0)
		return
	for failure: String in _failures:
		printerr("FAIL  %s" % failure)
	quit(1)


## Everything `combat_hud.gd` asks a CombatManager for, and nothing else.
##
## Values are fixed at "an ordinary mid-fight moment": fighting, not aiming, not
## resolving a catch, quick ready, charged not, a switch available. The HUD
## draws its full furniture from that, so the frames show the tells IN CONTEXT
## rather than floating on an otherwise empty screen -- which is the whole point
## of rendering them.
##
## `active_matchup` is the one method that is NOT stubbed to a constant: it runs
## the real `type_chart.gd` lookup over the real pair, so the arrow in these
## frames is produced by the shipping code path rather than posed.
class _StubManager extends Node:
	const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
	const MOVE_DB := preload("res://scripts/creatures/move_db.gd")

	signal exited(outcome: String)
	signal attack_missed(by_player: bool)
	signal hit_effectiveness(on_enemy: bool, effectiveness: int)
	signal catch_refused(reason: String)
	signal catch_resolved(success: bool, shakes: int)
	signal creature_switched(index: int)
	signal orb_shook(index: int)

	## `combat_hud.gd::_update_party_strip` reads this FIELD directly
	## (`_manager.get("_active_index")`) rather than calling a method, so the
	## stub has to carry it by name or the strip errors every frame.
	var _active_index: int = 0

	var _ally: RefCounted = null
	var _foe: RefCounted = null
	var _moves: RefCounted = null

	func _init() -> void:
		_moves = MOVE_DB.load_default()

	func set_pair(ally: RefCounted, foe: RefCounted) -> void:
		_ally = ally
		_foe = foe

	func active_creature() -> RefCounted:
		return _ally

	func enemy() -> RefCounted:
		return _foe

	## The real lookup, deliberately duplicated from combat_manager rather than
	## called through it: this tool exists to render what the HUD draws, and
	## instantiating the whole manager would drag the scene tree, the arena and
	## the encounter director in behind it.
	func active_matchup() -> int:
		if _ally == null or _foe == null:
			return 0
		var defending := str(_foe.creature_type)
		var quick := TYPE_CHART.multiplier(
			str(_moves.call("type_of", str(_ally.move_quick))), defending)
		var charged := TYPE_CHART.multiplier(
			str(_moves.call("type_of", str(_ally.move_charged))), defending)
		return TYPE_CHART.classify(maxf(quick, charged))

	func is_fighting() -> bool: return true
	func is_aiming() -> bool: return false
	func is_resolving_catch() -> bool: return false
	func enemy_is_winding_up() -> bool: return false
	func enemy_is_rooted() -> bool: return true
	func quick_ready() -> bool: return true
	func charged_ready() -> bool: return false
	func can_switch() -> bool: return true
	func switchable_indices() -> Array: return [1]
	func cycle_active() -> void: pass
	func orbs_left() -> int: return 3
	func current_orb_id() -> String: return "orb_basic"
	func catch_chance_now() -> float: return 0.0
	func last_catch_chance() -> float: return 0.0
	func catch_aim_is_locked() -> bool: return false
	func outcome() -> String: return ""
