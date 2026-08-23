extends SceneTree

## THE UI SURVEY. Every HUD element and every menu screen the player ever
## sees, in one contact sheet's worth of frames, for a blind visual critic
## judging criterion 6 (Interface: safe area, hierarchy, legibility at a
## glance) against `.claude/skills/visual-judge/SKILL.md`.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_ui_survey.gd
##
## NEVER `--headless` with a real rendering driver. Verified 2026-08-22 on a
## bare ColorRect with no project scenes: `--headless` + `--rendering-driver
## opengl3` prints one line and then hangs forever with no error, no crash and
## no partial output -- exit 124/143 from `timeout`. It is the COMBINATION
## that hangs, not the scene weight (`ralph/conventions.md`, "Art pipeline
## traps already paid for" -- the single most expensive trap in this repo,
## having already cost four abandoned LOD captures and two abandoned HUD
## captures on one day alone, one of them a 43-minute hang). Drop `--headless`,
## keep `xvfb-run` for the virtual display, and the identical script writes
## its PNGs and exits 0. (`--headless` stays correct and fast for TESTS, which
## render nothing -- it is only wrong once a real rendering driver joins it.)
##
## FRAME BUDGET, MEASURED REASONING NOT A GUESS. `tools/_probe_corridor_survey.gd`
## (this coordinator's own tool, just committed) measured every awaited frame
## at ~2.4s under llvmpipe WHILE THE 143,630-PROP MEADOWS WORLD IS LOADED --
## that cost is the render, not the physics tick, so `process_frame` and
## `physics_frame` waits cost the same while the world scene is in the tree.
## The corridor survey's own header states the number is a property of what
## has to be DRAWN, not of the world being "slow to build" (it stands up
## complete in under a minute). A `.tscn`-only menu screen with no Terrain3D,
## no 143k-prop scatter and often nothing but flat Controls has nothing close
## to that much to draw, and `tests/smoke_build_menu_footprint.gd`'s own
## header already banks on exactly this gap: "No world scene is loaded. `Game`
## is an autoload, which is everything `build_menu.gd::open` actually needs,
## and standing up the Meadows for a layout assertion costs ten minutes under
## software GL for nothing." This tool follows that same discipline as far as
## it will go: `Game` (`autoload/game_state.gd`, `project.godot`'s one
## `"*res://autoload/game_state.gd"` autoload) mounts its own pause menu in
## `_ready()` -- BEFORE any world scene exists -- so the title screen, the
## starter picker, the naming grid, the dialogue panel, six of the seven pause
## tabs (every one that does not bake a Terrain3D texture) and all five
## standing-at-a-fixture panels (craft/shop/storage/swap/creature-bed) never
## need `meadows_playground.tscn` loaded at all. Only the Map tab (which bakes
## a real terrain texture, `scripts/world/map_baker.gd`) and the world-anchored
## HUD elements (exploration HUD, input-glyph legend, minimap, combat HUD,
## the capture reticle) load the world, and they share exactly ONE boot.
##
## The arithmetic, added up from the actual `_settle()`/`_shoot()` constants
## in the world phase below (`_phase_world`) -- every one of these frames has
## `meadows_playground.tscn` in the tree, so every one is charged at the
## measured 2.4s/frame:
##
##   boot (BOOT_FRAMES)                                       90
##   camera placement settle                                  12
##   party-strip pin + HUD settle                              12
##   shoot 05-hud-exploration (6 pose + shutter)                6
##   gamepad-glyph toggle settle + shoot 06                    12
##   minimap reveal settle + shoot 07                          12
##   menu open (map tab) transition                             6
##   map-bake settle -- proven number, not guessed: the exact
##     wait `capture_map_tab.gd`'s own header measured after a
##     shorter one came back a blank white square                 90
##   shoot 14-menu-map + menu close settle                     12
##   combat: teleport into practice cluster + settle           12
##   _start_fight + settle                                     12
##   shoot 10-combat-hud                                        6
##   _try_throw + aim-camera settle                            12
##   aim-at-target + settle + shoot 11-capture-reticle          12
##   ------------------------------------------------------------
##   TOTAL                                                    306 frames
##
##   306 * 2.4s  =  734s  ~=  12.2 minutes  -- world phase alone.
##
## The seventeen standalone shots (title, starter picker, name prompt,
## dialogue, party-strip closeup, stamina-arc closeup, six pause tabs, five
## fixture panels) sum to 276 more awaited frames (`_phase_standalone`), but
## NONE of them has `meadows_playground.tscn` in the tree -- so none is
## drawing the 143,630-prop scatter the 2.4s/frame figure above is the cost
## of, and charging them at that rate would be wrong, not conservative.
## Unmeasured in THIS repo, so stated honestly rather than invented: each
## frame here draws a plain Control tree, or at most a couple of small
## SubViewports (the starter picker's three orb turntables, the Creatures
## tab's one creature preview) -- a tiny fraction of the world's geometry on
## any renderer. Even in the worst case of no speed-up at all, 276 more
## frames at the world rate is ~11 more minutes, for a hard ceiling of ~23
## minutes total; in the ordinary case of a UI-only frame actually being
## faster to draw than a 143k-prop one, the real total lands close to the
## world phase's own 12.2 minutes, comfortably inside the ~15 minute budget
## this task sets.
##
## POPULATION. An empty inventory or an empty quest log tells a blind critic
## nothing about hierarchy or legibility (this task's brief, point 4), so
## every panel below is fed real data through its own real public API --
## never a literal string poked onto a Label -- read out of the panel's own
## script before writing this tool:
##   - `craft_panel.gd`, `shop_panel.gd`, `storage_panel.gd`, `swap_panel.gd`,
##     `creature_bed_panel.gd` all say plainly in their own headers that they
##     read `/root/Game` and nothing else -- "Built entirely in code... opened
##     the same pause-and-release-mouse way" -- so a chest/bed built with
##     `build_real()` and a `Game.party`/`Game.inventory` seeded before they
##     open gives each one the real state it was built to show.
##   - `bond_meter.gd` has no mount of its own; `tab_creatures.gd` is its only
##     caller (`_bond_meter.call("set_bond", ...)`, fed off the party's real
##     `creature.bond`), so the dedicated "bond meter" element the brief names
##     is the Creatures tab with a party whose first member has real,
##     non-zero bond -- not a separate widget invented for this tool.
##   - `party_strip.gd` and `stamina_arc.gd` both say in their own headers that
##     they never reach `/root/Game` -- they are pure Controls fed a fraction/
##     entries array by whoever mounts them (`playground_hud.gd` in real
##     play). That is what lets this tool drive each one directly and
##     legibly, standalone, the same contract `tests/test_hud_widgets.gd`
##     already exercises with no player, no vitals and no tree.
##
## WHAT NEEDED THE WORLD AND WHY (so the choice is visible, not silent):
##   - the Map tab bakes a live Terrain3D texture (`map_baker.gd`); a menu
##     capture with no world would show it permanently blank, which is a
##     worse silent failure than the one extra boot this tool already pays for.
##   - the exploration HUD, minimap and input-glyph legend are drawn AT their
##     real screen-space scale over the real 3D view -- that scale, not a
##     mocked-up backdrop, is exactly what criterion 6 judges.
##   - the combat HUD and capture reticle only exist while `CombatManager`
##     is mid-fight; there is no standalone `.tscn` for either.
##
## COULD NOT BE STAGED. None found -- every element and screen named in the
## brief has a real, reachable open()/build() path from a script already read
## above. If a future addition breaks that (a panel that starts asking for
## something only a live save can supply), this tool's job is to print a FAIL
## line naming which shot and why, never to fabricate the frame.

const OUT_DIR := "res://shots/ui"

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")
const SHOP_PANEL := preload("res://scripts/ui/shop_panel.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")
const SWAP_PANEL := preload("res://scripts/ui/swap_panel.gd")
const CREATURE_BED_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")
const STAMINA_ARC := preload("res://scripts/ui/stamina_arc.gd")

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const STARTER_PICKER_SCENE := "res://scenes/ui/starter_picker.tscn"
const NAME_PROMPT_SCENE := "res://scenes/ui/name_prompt.tscn"
const DIALOGUE_PANEL_SCENE := "res://scenes/ui/dialogue_panel.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"

## Five real species with shipped portrait art (assets/ui/portraits/creatures),
## so the seeded belt and its standalone strip closeup both draw real chips,
## not a fallback square.
const STARTER_SPECIES: Array[String] = ["terrapup", "ripplet", "galewisp"]
const PARTY_SPECIES: Array[String] = ["terrapup", "ripplet", "galewisp", "brooktail", "tuskroot"]

const BOOT_FRAMES := 90

var _written: Array[String] = []
var _failures: Array[String] = []
var _game: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_failures.append("no Game autoload in the tree -- nothing here can be staged")
		_finish()
		return

	_seed_game_state()

	await _phase_standalone()
	await _phase_world()

	_finish()


# --- shared plumbing ---------------------------------------------------------


## One seeding pass, reused by every standalone panel and (because `Game` is
## one singleton for the whole run) carried straight into the world phase too
## -- the world's own HUD reads the same `Game.party`/`Game.inventory` this
## sets, so nothing needs reseeding after the boot.
func _seed_game_state() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var party: RefCounted = _game.get("party")
	var progression: RefCounted = _game.get("progression")
	if inventory == null or party == null:
		_failures.append("seed: Game.inventory/Game.party not reachable -- every panel below will show empty")
		return

	# A full five-member belt (CLAUDE.md: "player can own only five creatures
	# total" -- shown at the cap, not a partial roster), varied so the
	# creatures tab, the swap panel, the creature-bed panel and the combat/HUD
	# frames all have something real and non-uniform to draw: one fainted
	# (creature-bed panel's revive state), one worn down (HP bar colour lerp),
	# one with real bond progress (bond_meter's own nodes).
	for i in PARTY_SPECIES.size():
		var species: String = PARTY_SPECIES[i]
		var creature: RefCounted = _game.call("make_creature", species, "")
		if creature == null:
			continue
		match i:
			1:
				creature.take_damage(float(creature.get("max_hp")) * 0.72) # badly worn down
			2:
				creature.take_damage(float(creature.get("max_hp"))) # fainted
			3:
				creature.bond = 46 # a real, partial bond -- not zero, not maxed
		party.call("add", creature)

	inventory.call("add", "wood", 40)
	inventory.call("add", "stone", 16)
	inventory.call("add", "fiber", 24)
	inventory.call("add", "berries", 10)
	inventory.call("add", "potion_small", 3)
	inventory.call("add", "orb_basic", 10)
	inventory.call("add", "axe", 1)

	# One real DONE entry so the quest log shows a mix, not a flat "nothing
	# started yet" list -- `data/progression/objectives.json`'s own first
	# main-line flag.
	if progression != null:
		progression.call("set_flag", "opening:beat:road")

	# One real save file in slot 2, so the Save tab shows a populated row
	# beside the empty ones rather than five identical blanks. save_game.gd's
	# own `save()` reads everything off `Game` directly and needs no Player/
	# world node, so this is safe before the world phase ever boots.
	var save_system: RefCounted = _game.get("save_system")
	if save_system != null:
		save_system.call("save", _game, 2)


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-28s -> %s" % [name, path])


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering (Compatibility renderer). Frame times from this")
	print("harness are not a performance measurement.")
	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


# --- phase 1: everything Game.menu() mounts with no world in the tree -------


func _phase_standalone() -> void:
	await _shoot_title_screen()
	await _shoot_starter_picker()
	await _shoot_name_prompt()
	await _shoot_dialogue_panel()
	await _shoot_party_strip_closeup()
	await _shoot_stamina_arc_closeup()
	await _shoot_menu_tabs()
	await _shoot_craft_panel()
	await _shoot_shop_panel()
	await _shoot_storage_panel()
	await _shoot_swap_panel()
	await _shoot_creature_bed_panel()


func _shoot_title_screen() -> void:
	var packed: PackedScene = load(TITLE_SCENE)
	if packed == null:
		_failures.append("01-title: could not load %s" % TITLE_SCENE)
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await _settle(12)
	await _shoot("01-title")
	screen.queue_free()
	await _settle(2)


func _shoot_starter_picker() -> void:
	var packed: PackedScene = load(STARTER_PICKER_SCENE)
	if packed == null:
		_failures.append("02-starter-picker: could not load %s" % STARTER_PICKER_SCENE)
		return
	# A plain meadow-green field behind it, same reasoning
	# `capture_starter_picker.gd` gives: the picker never draws its own
	# full-screen background, so a bare instance over nothing reads as a UI
	# test rather than a moment in the opening.
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = 0
	root.add_child(backdrop_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.36, 0.46, 0.24)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.add_child(backdrop)

	var picker: CanvasLayer = packed.instantiate() as CanvasLayer
	root.add_child(picker)
	picker.call("open", STARTER_SPECIES)
	await _settle(20) # a couple seconds of turntable spin, not frame zero
	await _shoot("02-starter-picker")
	picker.queue_free()
	backdrop_layer.queue_free()
	await _settle(2)


func _shoot_name_prompt() -> void:
	var packed: PackedScene = load(NAME_PROMPT_SCENE)
	if packed == null:
		_failures.append("03-name-prompt: could not load %s" % NAME_PROMPT_SCENE)
		return
	var namer: CanvasLayer = packed.instantiate() as CanvasLayer
	root.add_child(namer)
	namer.call("open", "Terrapup")
	await _settle(8)
	await _shoot("03-name-prompt")
	namer.queue_free()
	await _settle(2)


func _shoot_dialogue_panel() -> void:
	var packed: PackedScene = load(DIALOGUE_PANEL_SCENE)
	if packed == null:
		_failures.append("04-dialogue-panel: could not load %s" % DIALOGUE_PANEL_SCENE)
		return
	var dialogue: CanvasLayer = packed.instantiate() as CanvasLayer
	root.add_child(dialogue)
	if bool(dialogue.call("start", "grandpa_house")):
		await _settle(8)
		await _shoot("04-dialogue-panel")
		dialogue.call("close")
	else:
		_failures.append("04-dialogue-panel: start('grandpa_house') refused -- conversation id may have moved")
	dialogue.queue_free()
	await _settle(2)


## `party_strip.gd` never reaches `/root/Game` (its own header) -- fed here
## directly with five entries in the shapes `update_from_party()` documents,
## covering the states a real belt actually shows: an out/selected member,
## an ordinary healthy one, one worn down, one fainted (KO badge), one
## resting. A close standalone frame reads its hierarchy far more legibly
## than a corner of a 1920x1080 exploration shot would.
func _shoot_party_strip_closeup() -> void:
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = 0
	root.add_child(backdrop_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.09, 0.10)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.add_child(backdrop)

	var strip: Control = PARTY_STRIP.new()
	strip.position = Vector2(80.0, 80.0)
	root.add_child(strip)

	var entries: Array = [
		{"label": "Biscuit", "level": 12, "hp_fraction": 1.0, "tint": Color(0.55, 0.75, 0.45),
			"portrait": "res://assets/ui/portraits/creatures/terrapup.png", "fainted": false, "resting": false},
		{"label": "Ripplet", "level": 9, "hp_fraction": 0.62, "tint": Color(0.35, 0.55, 0.80),
			"portrait": "res://assets/ui/portraits/creatures/ripplet.png", "fainted": false, "resting": false},
		{"label": "Kite", "level": 7, "hp_fraction": 0.0, "tint": Color(0.75, 0.80, 0.90),
			"portrait": "res://assets/ui/portraits/creatures/galewisp.png", "fainted": true, "resting": false},
		{"label": "Brooktail", "level": 10, "hp_fraction": 1.0, "tint": Color(0.40, 0.60, 0.55),
			"portrait": "res://assets/ui/portraits/creatures/brooktail.png", "fainted": false, "resting": true},
		{"label": "Tuskroot", "level": 14, "hp_fraction": 0.88, "tint": Color(0.65, 0.55, 0.35),
			"portrait": "res://assets/ui/portraits/creatures/tuskroot.png", "fainted": false, "resting": false},
	]
	strip.call("update_from_party", entries, 0, true)
	strip.call("set_pinned", true) # stays revealed; no fade timer to race against the shutter
	await _settle(8)
	await _shoot("08-party-strip")
	strip.queue_free()
	backdrop_layer.queue_free()
	await _settle(2)


## `stamina_arc.gd` also never reaches `/root/Game` (its own header) -- fed a
## fraction and a draining flag exactly the way `playground_hud.gd` feeds it
## mid-sprint. Mid-value and draining puts it in the warning colour tier
## (`WARNING_BELOW`), which is more informative than a full or empty arc.
func _shoot_stamina_arc_closeup() -> void:
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = 0
	root.add_child(backdrop_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.09, 0.10)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.add_child(backdrop)

	var arc: Control = STAMINA_ARC.new()
	arc.position = Vector2(400.0, 300.0)
	root.add_child(arc)
	arc.call("update_stamina", 0.34, true, 0.1)
	await _settle(6)
	await _shoot("09-stamina-arc")
	arc.queue_free()
	backdrop_layer.queue_free()
	await _settle(2)


## Every pause tab except Map (which needs a baked Terrain3D texture and is
## shot in the world phase, as `14-menu-map`). `Game._mount_menu()` already
## built all seven tab bodies at autoload `_ready()`, so `Game.menu()` here is
## the real shell, fully wired, with no world underneath it.
func _shoot_menu_tabs() -> void:
	var menu: Node = _game.call("menu")
	if menu == null:
		_failures.append("menu tabs: Game.menu() not reachable")
		return

	var tabs: Array = [
		["backpack", "12-menu-backpack"],
		["creatures", "13-menu-creatures"], # bond_meter.gd's only real caller -- see header
		["quest_log", "15-menu-quest-log"],
		["build", "16-menu-build"],
		["save", "17-menu-save"],
		["settings", "18-menu-settings"],
	]
	for pair: Variant in tabs:
		var tab_id: String = str((pair as Array)[0])
		var shot_name: String = str((pair as Array)[1])
		menu.call("close") # open() no-ops while already open on another tab
		menu.call("open", tab_id)
		if str(menu.call("current_tab_id")) != tab_id:
			_failures.append("%s: menu did not land on tab '%s'" % [shot_name, tab_id])
			continue
		await _settle(8)
		await _shoot(shot_name)
	menu.call("close")
	await _settle(2)


func _shoot_craft_panel() -> void:
	var panel: CanvasLayer = CRAFT_PANEL.new()
	root.add_child(panel)
	panel.call("open")
	await _settle(8)
	await _shoot("19-craft-panel")
	panel.call("close")
	panel.queue_free()
	await _settle(2)


func _shoot_shop_panel() -> void:
	var panel: CanvasLayer = SHOP_PANEL.new()
	root.add_child(panel)
	panel.call("open", "mira") # data/config/trade.json's own vendor id
	await _settle(8)
	await _shoot("20-shop-panel")
	panel.call("close")
	panel.queue_free()
	await _settle(2)


func _shoot_storage_panel() -> void:
	var chest := STORAGE_CONTAINER.new()
	root.add_child(chest)
	chest.call("build_real")
	var inventory: RefCounted = _game.get("inventory")
	if chest.state != null and inventory != null:
		# Real transfers through the real state object -- half the satchel's
		# stock moves into the chest, so BOTH columns (satchel-to-chest,
		# chest-to-satchel) have real rows, not one empty side.
		chest.state.call("deposit", inventory, "wood", 20)
		chest.state.call("deposit", inventory, "stone", 8)

	var panel: CanvasLayer = STORAGE_PANEL.new()
	root.add_child(panel)
	panel.call("open", chest)
	await _settle(8)
	await _shoot("21-storage-panel")
	panel.call("close")
	panel.queue_free()
	chest.queue_free()
	await _settle(2)


func _shoot_swap_panel() -> void:
	var panel: CanvasLayer = SWAP_PANEL.new()
	root.add_child(panel)
	panel.call("open", "oskar") # data/config/trade.json's own creature-trader id
	await _settle(8)
	await _shoot("22-swap-panel")
	panel.call("close")
	panel.queue_free()
	await _settle(2)


func _shoot_creature_bed_panel() -> void:
	var bed := CREATURE_BED.new()
	root.add_child(bed)
	bed.call("build_real", false) # player_built=false: a capture prop, not a real placement

	var panel: CanvasLayer = CREATURE_BED_PANEL.new()
	root.add_child(panel)
	panel.call("open", bed)
	await _settle(8)
	await _shoot("23-creature-bed-panel")
	panel.call("close")
	panel.queue_free()
	bed.queue_free()
	await _settle(2)


# --- phase 2: the one world boot, for everything that genuinely needs it ----


func _phase_world() -> void:
	var packed: PackedScene = load(WORLD_SCENE)
	if packed == null:
		_failures.append("world phase: could not load %s -- hud/minimap/glyphs/menu-map/combat/reticle all skipped" % WORLD_SCENE)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[world] boot settled")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var menu: Node = _game.call("menu")
	if player == null or rig == null or hud == null:
		_failures.append("world phase: missing Player/CameraRig/PlaygroundHUD -- cannot proceed")
		return

	var field: RefCounted = HEIGHTFIELD.new()
	rig.set_process(false)
	rig.set_physics_process(false)

	# Same three-quarter over-the-shoulder framing `capture_exploration_hud.gd`
	# uses -- close enough that the HUD's real screen-space scale is judged,
	# not a tiny figure in a wide establishing shot.
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var eye_xz := Vector2(-9.0, -4.0)
	camera.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + 3.4, eye_xz.y)
	player.global_position = Vector3(-15.0, field.height_at(-15.0, -1.0) + 0.4, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	await _settle(12)

	# The party seeded in `_seed_game_state()` is already `Game.party` --
	# `PlaygroundHUD` reads that same singleton, so it needs no reseeding
	# here, only a pin so the strip's own fade timer does not race the shutter.
	var strip: Variant = hud.get("_party_strip")
	if strip != null and strip is Object and (strip as Object).has_method("set_pinned"):
		strip.call("set_pinned", true)
	await _settle(12)
	await _shoot("05-hud-exploration")

	# Input glyphs: the bottom-dock legend redraws in gamepad-button form the
	# moment `Game._last_input_was_gamepad` is true -- same flip
	# `capture_ui_suite.gd` uses -- so this is the real legend in its other
	# real state, not a mocked-up glyph sheet.
	_game.set("_last_input_was_gamepad", true)
	await _settle(6)
	await _shoot("06-hud-input-glyphs")
	_game.set("_last_input_was_gamepad", false)

	# Minimap: a broad reveal plus a nearby wild creature, same seeding
	# `capture_minimap.gd` uses, so the rim clamp, fog edge and creature
	# marker are all genuinely on screen rather than an all-fog frame.
	var map_state: RefCounted = _game.get("map")
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if map_state != null:
		map_state.call("reveal_circle", Vector3(-6.0, 0.0, -13.0), 55.0)
		for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
			map_state.call("mark_visited", point)
		_game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	var minimap_wild: Node3D = null
	if director != null:
		minimap_wild = director.call("wild_creature") as Node3D
	if minimap_wild != null:
		minimap_wild.global_position = player.global_position + Vector3(20.0, 0.0, 0.0)
	await _settle(6)
	await _shoot("07-minimap")

	# Map tab: needs the world for `map_baker.gd`'s live Terrain3D bake.
	# 90-frame settle is not a guess -- it is the exact number
	# `capture_map_tab.gd`'s own header records after a shorter wait came
	# back a blank white square (a real software-rendering race: a freshly
	# baked ImageTexture is not guaranteed uploaded to the GPU before the same
	# frame samples it).
	if menu != null:
		menu.call("open", "map")
		await _settle(6)
		if str(menu.call("current_tab_id")) == "map":
			await _settle(90)
			await _shoot("14-menu-map")
		else:
			_failures.append("14-menu-map: menu did not land on the map tab")
		menu.call("close")
		await _settle(6)
	else:
		_failures.append("14-menu-map: Game.menu() not reachable")

	# Combat HUD + capture reticle: one real fight serves both. Teleport
	# straight into the "practice" spawn cluster and enter combat through
	# `encounter_director.gd`'s own entry point (`_start_fight` ->
	# `CombatManager.begin`) -- the same one every real engage route (the
	# interact prompt, an aggressive creature's ambush) already funnels
	# through, and the no-walk shortcut `capture_ui_final.gd` proved works.
	if director != null:
		var manager: Node = world.get_node_or_null(^"CombatManager")
		if manager == null:
			_failures.append("10-combat-hud: no CombatManager in the world")
		else:
			if director.call("ally_instance") == null:
				await director.call("adopt_starter", "terrapup")
			var cluster := _cluster_centre(director, "practice", Vector3(30.0, 0.0, -40.0))
			player.global_position = Vector3(
				cluster.x, float(world.call("ground_height_at", cluster.x, cluster.z)) + 1.0, cluster.z
			)
			player.velocity = Vector3.ZERO
			await _settle(12)

			var wild: Node3D = director.call("wild_creature") as Node3D
			if wild == null:
				_failures.append("10-combat-hud: no practice-role wild creature near the cluster")
			else:
				director.call("_start_fight", wild)
				await _settle(12)
				if not bool(manager.call("is_fighting")):
					_failures.append("10-combat-hud: _start_fight did not enter combat")
				else:
					await _shoot("10-combat-hud")

					# try_begin_aim's own real entry point, called directly the
					# same way `_start_fight` above is -- `_try_throw()` is
					# `combat_manager.gd`'s own handler for the throw input, not
					# a shortcut invented here.
					manager.call("_try_throw")
					await _settle(12)
					if bool(manager.call("is_aiming")):
						_aim_at(rig, wild)
						await _settle(6)
						await _shoot("11-capture-reticle")
					else:
						_failures.append("11-capture-reticle: try_begin_aim did not open (no orbs, or already busy)")
	else:
		_failures.append("10-combat-hud / 11-capture-reticle: no EncounterDirector in the world")


## Reads data/config/spawns.json through the director's own cached accessor,
## same idiom `capture_ui_final.gd::_cluster_centre` uses -- this always
## agrees with whatever the director actually spawned.
func _cluster_centre(director: Node, role: String, fallback: Vector3) -> Vector3:
	var cfg: Dictionary = director.call("spawns_config") as Dictionary
	var roles: Dictionary = cfg.get("roles", {}) as Dictionary
	var species := str(roles.get(role, ""))
	if species.is_empty():
		return fallback
	for raw in (cfg.get("spawns", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("species", "")) != species:
			continue
		var centre: Array = entry.get("centre", [])
		if centre.size() >= 3:
			return Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
	return fallback


## Points the rig's yaw/pitch at the wild creature from the rig's own camera,
## same shape `capture_ui_final.gd::_aim_at` uses -- close enough for a
## legible reticle frame; this is a screenshot, not a real thrown orb, so no
## launch-assist precision is needed.
func _aim_at(rig: Node, wild: Node3D) -> void:
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var velocity := Vector3.ZERO
	if wild is CharacterBody3D:
		velocity = (wild as CharacterBody3D).velocity
	var predicted: Vector3 = (wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))
