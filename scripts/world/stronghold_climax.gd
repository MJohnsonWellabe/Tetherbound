extends Node3D

## R8.3 / SG40 / R8.4 — the Warden, the reveal, and freeing the legendary.
##
## The chapter's climax, and it is deliberately a THIN node. Everything it
## does is already somebody else's system:
##
##   * the Warden is an ordinary row of data/config/trainers.json, placed by
##     the ordinary `trainer_npc.gd` placer (group `stronghold_climax`) and
##     fought by the ordinary `encounter_director.begin_trainer_battle()`.
##     There is no boss combat mode, no boss script, and catching is refused
##     for his creatures exactly as it is for every other trainer's.
##   * the reveal is an ordinary `interactable.gd` prompt opening an ordinary
##     conversation out of the ordinary dialogue table.
##   * the five-creature decision is R4.10's release ceremony, reached the
##     one way it is reachable: `Game.pending_catch`. Not reimplemented.
##   * where things stand comes from R8.2's `stronghold.gd::marker()`, by
##     NAME, so this file hard-codes no metre inside somebody else's building.
##
## What is left over — the small amount that is genuinely this item's — is the
## ORDER, and spec §28 says the order is not optional:
##
##   reach the chamber → the legendary is freed → it voluntarily offers to
##   join → the five-creature decision if the belt is full → the tether
##   machinery fails → the world event fires.
##
## That order is a state machine below (`_stage`), and the one thing it will
## not do is skip a step. SG44's world event is a SEPARATE item; all this file
## does at the end is set `legendary_freed`, once, which is the flag SG44 reads.

const CONFIG_PATH := "res://data/config/stronghold_climax.json"

const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

## The climax's own stages, in §28's order. "" is "nothing has started".
const STAGE_CHAMBER := "chamber"
const STAGE_FREED := "freed"
const STAGE_JOIN := "join"
const STAGE_CEREMONY := "ceremony"
const STAGE_FAILURE := "failure"
const STAGE_DONE := "done"

var _config: Dictionary = {}
var _world: Node = null
var _player: Node3D = null

var _stronghold: Node = null
var _trainers: Node3D = null
var _readout: Node3D = null
var _machine_prompt: Node3D = null
var _legendary: Node3D = null
var _cage: Node3D = null
var _light: OmniLight3D = null

var _stage: String = ""
var _pending_conversation: String = ""
var _cage_time: float = 0.0
var _freed_visual: bool = false
var _seen_warden_defeat: bool = false
var _chamber_told: bool = false
var _joined: RefCounted = null


func build(world: Node, player: Node3D) -> bool:
	_world = world
	_player = player
	_config = _load_config()
	if _config.is_empty():
		push_warning("stronghold_climax.json missing; the chapter has no ending")
		return false

	_stronghold = _find_stronghold()
	_place_warden()
	_place_readout()
	_place_machine_prompt()
	_place_legendary()
	_watch_the_dialogue_panel()
	return true


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## R8.2's building, if it is in the tree. Everything below degrades to its own
## `fallback` world coordinates when it is not — a bare test scene, or this
## branch before the route merges — so the climax is drivable either way and
## the merge is a matter of the markers simply starting to answer.
func _find_stronghold() -> Node:
	var site: Dictionary = _config.get("site", {})
	var node_name := str(site.get("stronghold_node", "Stronghold"))
	var found: Node = _world.get_node_or_null(NodePath(node_name)) if _world != null else null
	if found == null:
		print("[climax] no '%s' node; standing the climax on its own fallback coordinates" % node_name)
	return found


## A named spot, asked of R8.2's building first and only then of this file's
## own fallback. `spec.mark` is the marker's id in data/config/stronghold.json.
func _spot(spec: Dictionary) -> Vector3:
	var mark := str(spec.get("mark", ""))
	if _stronghold != null and mark != "" and bool(_stronghold.call("has_marker", mark)):
		return _stronghold.call("marker", mark) as Vector3
	var at: Array = spec.get("fallback", [])
	var x := float(at[0]) if at.size() > 0 else 0.0
	var z := float(at[1]) if at.size() > 1 else 0.0
	return Vector3(x, _ground_at(x, z), z)


func _ground_at(x: float, z: float) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		var y := float(_world.call("ground_height_at", x, z))
		if not is_nan(y):
			return y
	return 0.0


## The stronghold's own world yaw, or 0 when it is not in the tree (the bare
## fallback-coordinate case every other lookup in this file also degrades to).
func _stronghold_yaw_deg() -> float:
	if _stronghold != null and _stronghold is Node3D:
		return rad_to_deg((_stronghold as Node3D).rotation.y)
	return 0.0


## --- R8.3: the Warden ---------------------------------------------------------

## Placed through `trainer_npc.gd` with his own group, so his body, his prompt,
## his challenge conversation, his battle and his defeat flag are all the
## chapter's ordinary trainer machinery and none of it forks here.
func _place_warden() -> void:
	var spec: Dictionary = _config.get("warden", {})
	var id := str(spec.get("trainer", ""))
	if id == "":
		return
	var at := _spot(spec)
	_trainers = TRAINER_NPCS.new()
	_trainers.name = "WardenTrainer"
	# Parented to the WORLD, not to this node, and that is load-bearing rather
	# than tidy: `trainer_npc.gd::_director()` reaches the encounter director
	# through `get_parent()`, so a placer hung under anything but the world
	# finds no director, quietly decides the trainer cannot be challenged, and
	# opens their BEATEN conversation instead of their challenge — a boss who
	# greets you politely and never fights. Found exactly that way.
	if _world != null:
		_world.add_child(_trainers)
	else:
		add_child(_trainers)
	_trainers.call(
		"build",
		_player,
		str(spec.get("placed_by", "stronghold_climax")),
		{id: Vector2(at.x, at.z)},
		# T1-HALL (2026-08-30): `facing_deg` is authored in the stronghold's own
		# LOCAL frame, same as `stronghold.gd::_place_gauntlet()`'s gauntlet
		# trainers -- and the Warden's body lands under this same world-parented
		# Trainers node, so his facing needs the same yaw composition theirs
		# does, for the same reason (see that function's own comment). Missing
		# here, the Warden faces 90 degrees off in his own arena the moment
		# `stronghold.json`'s `site.yaw_deg` is anything but the value his
		# `facing_deg` was tuned against.
		{id: float(spec.get("facing_deg", 0.0)) + _stronghold_yaw_deg()}
	)
	if int(_trainers.call("placed")) == 0:
		push_warning("the Warden was not placed; trainers.json has no row '%s'" % id)
		return

	# Stand him on the ARENA FLOOR, not on the terrain under it.
	#
	# `trainer_npc.build()` takes an (x, z) and grounds to `ground_height_at`,
	# which is right everywhere in the open meadow and wrong inside R8.2's
	# stronghold: its five spaces are built slabs at a single authored floor
	# height with an 18 m revetment skirt below them, so the terrain under the
	# Warden Arena is metres beneath the floor the player walks in on. Placed
	# by terrain, the Warden sinks below his own arena, the player standing in
	# front of him is nowhere near him, and the prompt line goes to whatever
	# global offer is left -- in the failing run, "Put Terrapup away". The
	# marker already carries the floor height; this uses it.
	#
	# Only visible once the real stronghold exists: this item was built against
	# its own fallback coordinates out on open ground, where terrain IS the
	# floor, and passed. Integration is what found it.
	var body := warden_body()
	if body != null and _stronghold != null:
		body.global_position = Vector3(body.global_position.x, at.y, body.global_position.z)


func warden_body() -> Node3D:
	if _trainers == null:
		return null
	return _trainers.call("body_for", str((_config.get("warden", {}) as Dictionary).get("trainer", ""))) as Node3D


## --- SG40: the reveal ---------------------------------------------------------

## A Team Tether maintenance readout on the threshold of the Warden Arena.
## Environmental storytelling the player chooses to read, standing where §28
## puts the discovery: BEFORE the Warden speaks and before the fight.
func _place_readout() -> void:
	var spec: Dictionary = _config.get("reveal", {})
	if spec.is_empty():
		return
	var at := _spot(spec)
	var panel := Node3D.new()
	panel.name = "TetherReadout"
	add_child(panel)
	panel.global_position = at

	var size := _vector3_of(spec.get("panel_size", []), Vector3(1.5, 1.1, 0.28))
	var body := MeshInstance3D.new()
	body.name = "Panel"
	var box := BoxMesh.new()
	box.size = size
	body.mesh = box
	body.material_override = _material(str(spec.get("colour", "#332228")), 0.0)
	body.position = Vector3(0.0, float(spec.get("height", 1.35)), 0.0)
	panel.add_child(body)

	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var face := QuadMesh.new()
	face.size = Vector2(size.x * 0.8, size.y * 0.7)
	screen.mesh = face
	screen.material_override = _material(str(spec.get("screen_colour", "#7fd8c4")), 1.6)
	screen.position = Vector3(0.0, float(spec.get("height", 1.35)), size.z * 0.51 + 0.01)
	panel.add_child(screen)

	_readout = INTERACTABLE.new()
	_readout.name = "ReadoutPrompt"
	_readout.position = Vector3(0.0, float(spec.get("height", 1.35)), 0.0)
	panel.add_child(_readout)
	_readout.call("configure", str(spec.get("label", "Read the Tether readout")), _prompt_radius(), true)
	_readout.connect("activated", _on_readout.bind(str(spec.get("conversation", ""))))


func _on_readout(conversation: String) -> void:
	_start(conversation)


## --- R8.4: the chamber, in §28's order ----------------------------------------

## The lever. Refused until the Warden has fallen — the Legendary Chamber is
## through his arena, and this gate is the one place §28's "after the Warden
## loses" could otherwise be walked around.
func _place_machine_prompt() -> void:
	var spec: Dictionary = _config.get("machine", {})
	if spec.is_empty():
		return
	var at := _spot(spec)
	var anchor := Node3D.new()
	anchor.name = "MachineControl"
	add_child(anchor)
	anchor.global_position = at

	_machine_prompt = INTERACTABLE.new()
	_machine_prompt.name = "MachinePrompt"
	_machine_prompt.position = Vector3(0.0, float(spec.get("height", 1.2)), 0.0)
	anchor.add_child(_machine_prompt)
	_machine_prompt.call("configure", str(spec.get("label", "Shut down the tether machine")), _prompt_radius(), false)
	_machine_prompt.connect("activated", _on_machine)


## The bound legendary. CLAUDE.md's hard rule is the shape of this function:
## an EXISTING roster mesh (`veridian`, already in species.json with real
## production art and already the tallest body in the game), differentiated by
## scale and VFX and nothing else. No new model, no generation, no repaint
## beyond OF28's colourway system that the body already applies for itself.
func _place_legendary() -> void:
	var spec: Dictionary = _config.get("legendary", {})
	if spec.is_empty():
		return
	if _has_flag(_flag("legendary_settled")):
		# A save from a PAST session already resolved the roster decision --
		# joined the belt, or walked free after the player kept their five.
		# `build()` runs again on every load (this is a fresh node, `_stage`
		# reset to ""), and with no check here it would stand a caged copy of
		# the very creature that already left this room straight back up,
		# which contradicts both endings at once: one where it is walking
		# around on the party belt right now, and one where the story says it
		# is gone. `key_pickup.gd` and `meadow_healing.gd` already keep this
		# same rule for their own one-time world state -- check the flag
		# before spawning, not after -- and this chamber is that same kind of
		# one-time thing. `_stage` is set to DONE so `_advance()` never tries
		# to replay the sequence, and the machine prompt stays refused via
		# `_sync_gate()`'s own `legendary_is_freed()` check.
		_stage = STAGE_DONE
		return
	var at := _spot(spec)
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.name = "BoundLegendary"
	body.set_script(CREATURE_BODY)
	add_child(body)
	body.global_position = at
	body.call("setup", str(spec.get("species", "veridian")), false)
	body.rotation.y = deg_to_rad(float(spec.get("facing_deg", 0.0)))

	# Differentiation, half one: scale, on the model pivot only, so the
	# collider and the species' own fit are untouched.
	var pivot: Node3D = body.call("model_pivot") as Node3D
	if pivot != null:
		var factor := float(spec.get("scale", 1.0))
		pivot.scale = Vector3(factor, factor, factor)

	_legendary = body
	_build_cage(spec.get("bound", {}) as Dictionary)

	if legendary_is_freed():
		# Loaded from a save taken between the lever being pulled and the
		# decision resolving -- the flag is set the instant the lever is
		# pulled (`_free_the_legendary`), but the join offer and the ceremony
		# still run through the DIALOGUE PANEL first, which (unlike the
		# ceremony's own menu) does not pause the tree, so `_tick_autosave()`
		# in `autoload/game_state.gd` can still land inside that window. Rare,
		# but `_stage` resets to "" on every fresh `build()` regardless, and
		# `_sync_gate()` refuses the machine prompt whenever the legendary is
		# already freed -- so without this, a save taken in that exact window
		# would come back caged, with no way to ever reach the join offer or
		# the decision again. Show it freed, not caged, and resume at the
		# join offer rather than replaying the chamber/free lines it has
		# already heard.
		_release_visual()
		_chamber_told = true
		_stage = STAGE_FREED


## Differentiation, half two: the containment VFX. A cold teal ring of light
## tight around it while it is held, replaced on release by a warm light of
## its own that is wider and brighter than the machine's ever was — the only
## moment in the chapter lit by something that is not Team Tether.
func _build_cage(bound: Dictionary) -> void:
	if _legendary == null:
		return
	_cage = Node3D.new()
	_cage.name = "ContainmentVFX"
	_legendary.add_child(_cage)

	var radius := float(bound.get("ring_radius", 3.4))
	var segments := maxi(6, int(bound.get("ring_segments", 24)))
	var material := _material(str(bound.get("colour", "#7fd8c4")), 2.2)
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		var bar := MeshInstance3D.new()
		bar.name = "CageBar%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.09, 3.2, 0.09)
		bar.mesh = mesh
		bar.material_override = material
		bar.position = Vector3(cos(angle) * radius, 1.6, sin(angle) * radius)
		_cage.add_child(bar)

	_light = OmniLight3D.new()
	_light.name = "ContainmentLight"
	_light.light_color = Color(str(bound.get("colour", "#7fd8c4")))
	_light.light_energy = float(bound.get("energy", 2.4))
	_light.omni_range = float(bound.get("range", 9.0))
	_light.position = Vector3(0.0, 2.0, 0.0)
	_legendary.add_child(_light)


func legendary_body() -> Node3D:
	return _legendary


func legendary_is_freed() -> bool:
	return _has_flag(_flag("legendary_freed"))


## --- the state machine --------------------------------------------------------

func _process(delta: float) -> void:
	_pulse_cage(delta)
	_sync_gate()
	_advance()


func _pulse_cage(delta: float) -> void:
	if _cage == null or _freed_visual or _light == null:
		return
	var bound: Dictionary = (_config.get("legendary", {}) as Dictionary).get("bound", {})
	var period := maxf(0.2, float(bound.get("pulse_seconds", 2.6)))
	_cage_time += delta
	var base := float(bound.get("energy", 2.4))
	_light.light_energy = base * (0.75 + 0.25 * sin(TAU * _cage_time / period))


## The lever only becomes touchable once the Warden is down, and the moment he
## IS down the chamber has something to say. Polled rather than signalled for
## the same reason the stronghold's own door is: a trainer defeat is written
## to the flag store by the encounter director, and a fight won before the
## last save has to count exactly as much as one won this second.
func _sync_gate() -> void:
	var open := _has_flag(_flag("gate"))
	if _machine_prompt != null:
		_machine_prompt.call("set_enabled", open and _stage == "" and not legendary_is_freed())
	if open and not _seen_warden_defeat:
		_seen_warden_defeat = true


## §28's order, and the only thing in this file that is genuinely its own.
## Each stage waits for the dialogue panel to close before the next begins, so
## nothing lands on top of an open box, and the five-creature decision gets a
## whole stage of its own because it is a decision the player may sit with.
func _advance() -> void:
	match _stage:
		STAGE_CHAMBER:
			if not _panel_busy():
				_stage = STAGE_FREED
				_free_the_legendary()
		STAGE_FREED:
			if not _panel_busy():
				_stage = STAGE_JOIN
				_offer_to_join()
		STAGE_JOIN:
			if not _panel_busy():
				_stage = STAGE_CEREMONY
				_hand_over_the_legendary()
		STAGE_CEREMONY:
			# R4.10's ceremony is on screen for as long as the player needs.
			# The machinery does not fail until they have answered it, which
			# is §28's order: join, then the five-creature decision, then the
			# machinery.
			if not _ceremony_pending() and not _panel_busy():
				_stage = STAGE_FAILURE
				_start(str((_config.get("machine", {}) as Dictionary).get("failure_conversation", "")))
		STAGE_FAILURE:
			if not _panel_busy():
				_stage = STAGE_DONE
				print("[climax] the tether machinery has failed; '%s' is set for SG44" % _flag("legendary_freed"))
		_:
			pass


## Step 1 of §28: the player reaches the chamber and pulls the lever.
func _on_machine() -> void:
	if _stage != "" or legendary_is_freed():
		return
	if not _has_flag(_flag("gate")):
		return
	if _machine_prompt != null:
		_machine_prompt.call("set_enabled", false)
	_stage = STAGE_CHAMBER
	var machine: Dictionary = _config.get("machine", {})
	# Told in two beats: what the room is, then what pulling it does. The
	# second carries `flag:legendary_freed` on the line the ring actually
	# drops, so a conversation cut short cannot bank the freeing without the
	# words or the words without the freeing.
	if not _chamber_told:
		_chamber_told = true
		_start(str(machine.get("chamber_conversation", "")))
	else:
		_start(str(machine.get("free_conversation", "")))


## Step 2: it is freed. The flag is set by the conversation's own `flag:`
## effect through the sequence director, and set here as well — belt and
## braces, because `legendary_freed` is what SG44 reads and a world event that
## silently never fires is the worst failure this item has.
func _free_the_legendary() -> void:
	var machine: Dictionary = _config.get("machine", {})
	if not _chamber_told:
		_chamber_told = true
	_start(str(machine.get("free_conversation", "")))
	_set_flag(_flag("legendary_freed"))
	_release_visual()


func _release_visual() -> void:
	if _freed_visual:
		return
	_freed_visual = true
	if _cage != null:
		_cage.queue_free()
		_cage = null
	var freed: Dictionary = (_config.get("legendary", {}) as Dictionary).get("freed", {})
	if _light != null:
		_light.light_color = Color(str(freed.get("colour", "#e8d79a")))
		_light.light_energy = float(freed.get("energy", 5.5))
		_light.omni_range = float(freed.get("range", 22.0))


## Step 3: it VOLUNTARILY offers to join. No orb is thrown and no fight
## happens — the word in §28 is "voluntarily" and it is load-bearing.
func _offer_to_join() -> void:
	_start(str((_config.get("machine", {}) as Dictionary).get("join_conversation", "")))


## Step 4: the five-creature decision, if one is needed.
##
## `Game.pending_catch` is R4.10's ONE seam and this hands the creature to it
## rather than reimplementing a single beat of the ceremony: the Game autoload
## notices the seam, opens the menu on the creatures tab, and will not let it
## be closed until the player has chosen. With room on the belt it simply
## joins, which is the same seam behaving the way it behaves for any catch.
func _hand_over_the_legendary() -> void:
	var game := _game()
	if game == null:
		push_error("no Game autoload; the freed legendary has nowhere to go")
		return
	var spec: Dictionary = _config.get("legendary", {})
	# Built through the SAME reader a trainer's creature is built through
	# (`trainer_npc.creature_for`), so it is levelled by D30's own arithmetic
	# and nothing here re-derives a stat table.
	var creature: RefCounted = TRAINER_NPCS.creature_for({
		"species": str(spec.get("species", "veridian")),
		"level": maxi(1, int(spec.get("level", 1))),
	})
	if creature == null:
		push_error("could not build the legendary from species.json; it cannot join")
		return
	_joined = creature

	var party: RefCounted = game.get("party")
	if party != null and not bool(party.call("is_full")):
		party.call("add", creature)
		_set_flag(_flag("legendary_joined"))
		_settle()
		print("[climax] the legendary joined a belt with room on it")
		return
	# Full belt: the decision, through the system that already ships it.
	game.set("pending_catch", creature)
	print("[climax] the belt is full; R4.10's release ceremony has the decision")


func _ceremony_pending() -> bool:
	var game := _game()
	if game == null:
		return false
	if game.get("pending_catch") != null:
		return true
	# The ceremony resolved: record which way it went, once.
	if _joined != null and not _has_flag(_flag("legendary_joined")):
		var party: RefCounted = game.get("party")
		if party != null and (party.call("members") as Array).has(_joined):
			_set_flag(_flag("legendary_joined"))
	if _joined != null:
		_settle()
	return false


## GATE-E: the roster decision is OVER, whichever way the player answered it.
##
## `legendary_joined` deliberately does not answer this. A player who reaches
## the ceremony with five they will not give up and lets the legendary walk
## away has resolved the decision exactly as completely as one who kept it, and
## that is a legitimate ending — CLAUDE.md's five-creature rule is the reason
## the choice exists at all. Prompt 68's chain therefore waits on THIS flag for
## its "resolve join/release if the roster is full" beat, because waiting on
## `legendary_joined` would strand the player who chose the other answer on a
## tracked objective they have already finished and can never finish again.
##
## Set exactly once, like every other flag in this file: `progression.set_flag`
## is idempotent and `_advance()` leaves STAGE_CEREMONY the frame after this,
## so a reload cannot re-run the beat.
func _settle() -> void:
	if _has_flag(_flag("legendary_settled")):
		return
	_set_flag(_flag("legendary_settled"))


## --- plumbing -----------------------------------------------------------------

func _panel() -> Node:
	return get_tree().get_first_node_in_group("dialogue_panel")


func _panel_busy() -> bool:
	var panel := _panel()
	return panel != null and bool(panel.call("is_open"))


func _start(conversation: String) -> bool:
	if conversation == "":
		return false
	var panel := _panel()
	if panel == null:
		# No panel (a bare test scene) is not a reason to stall the sequence:
		# the beats still run, they simply have nobody to speak them.
		return false
	if bool(panel.call("is_open")):
		return false
	_pending_conversation = conversation
	return bool(panel.call("start", conversation))


## The Warden's own conversations are watched by `trainer_npc.gd`, not here.
## What this needs from the panel is only the chamber sequence's beats, and
## `_advance()` reads `is_open` for that — so this connection exists purely so
## a future beat can be hung off `finished` without rewiring.
func _watch_the_dialogue_panel() -> void:
	var panel := _panel()
	if panel == null or not panel.has_signal("finished"):
		return
	if not panel.is_connected("finished", _on_conversation_finished):
		panel.connect("finished", _on_conversation_finished)


func _on_conversation_finished(conversation_id: String) -> void:
	if conversation_id == _pending_conversation:
		_pending_conversation = ""


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _progression() -> RefCounted:
	var game := _game()
	return game.get("progression") as RefCounted if game != null else null


func _flag(key: String) -> String:
	return str((_config.get("flags", {}) as Dictionary).get(key, ""))


func _has_flag(flag: String) -> bool:
	if flag == "":
		return false
	var progression := _progression()
	return progression != null and bool(progression.call("has", flag))


func _set_flag(flag: String) -> void:
	if flag == "":
		return
	var progression := _progression()
	if progression == null:
		push_error("no progression store; '%s' was recorded nowhere" % flag)
		return
	progression.call("set_flag", flag)


func _prompt_radius() -> float:
	return float((_config.get("site", {}) as Dictionary).get("prompt_radius", 4.2))


func _material(colour: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(colour)
	material.roughness = 0.7
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = Color(colour)
		material.emission_energy_multiplier = emission
	return material


func _vector3_of(raw: Variant, fallback: Vector3) -> Vector3:
	if not raw is Array or (raw as Array).size() < 3:
		return fallback
	var values: Array = raw
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
