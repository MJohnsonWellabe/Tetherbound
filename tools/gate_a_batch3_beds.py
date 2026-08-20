#!/usr/bin/env python3
"""Gate A batch 3: physical, gradual creature-bed recovery.

Builds on batch2's CreatureInstance.resting field and save version 12. Keeps the
runtime recovery on Game/party state so it continues even when a bed is offscreen;
the placed bed owns only assignment UX and presentation.
"""
from pathlib import Path


def rep(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f"{rel}: batch3 expected one anchor, got {n}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch3 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    # Tunable: two minutes of ordinary world time takes a creature from 0->full.
    changed |= rep(
        root, "data/config/progression.json",
        '''  "xp_award": {\n    "base": 30,\n    "per_enemy_level": 16,\n    "party_share": 0.5,\n    "rest_bonus": 5\n  },''',
        '''  "xp_award": {\n    "base": 30,\n    "per_enemy_level": 16,\n    "party_share": 0.5,\n    "rest_bonus": 5\n  },\n  "creature_bed": {\n    "_comment": "Gate A owner contract. TUNABLE. A creature in a physical bed heals continuously over ordinary world time and becomes unavailable. full_heal_seconds is the time 0->100% would take if the player never sleeps; sleeping through the night completes any occupied bed immediately and grants the rested state.",\n    "full_heal_seconds": 120.0\n  },''',
    )

    # Instance fields travel with the creature, so party reorder cannot put a
    # different creature in the bed. bed index is the stable placed-build record.
    changed |= rep(
        root, "scripts/creatures/creature_instance.gd",
        '''var resting: bool = false\n\n## --- progression (D30)''',
        '''var resting: bool = false\n## True only after the creature remained assigned through player sleep/night.\n## Waking early always clears this while preserving HP already regenerated.\nvar rested: bool = false\n## Index into Game.placed_buildings for the creature_bed this instance occupies.\n## -1 when not assigned. Stored on the creature rather than by party slot so\n## reordering the five cannot silently put the wrong pal in a bed.\nvar rest_bed_index: int = -1\n\n## --- progression (D30)''',
    )

    # Save the full bed relationship/state in the already-unmerged v12 format.
    changed |= rep(
        root, "scripts/save/save_game.gd",
        '''\t\t\t"resting": bool(instance.get("resting")),\n\t\t\t"level": int(instance.get("level")),''',
        '''\t\t\t"resting": bool(instance.get("resting")),\n\t\t\t"rested": bool(instance.get("rested")),\n\t\t\t"rest_bed_index": int(instance.get("rest_bed_index")),\n\t\t\t"level": int(instance.get("level")),''',
    )
    changed |= rep(
        root, "scripts/save/save_game.gd",
        '''\t\tcreature.resting = bool(d.get("resting", false))\n\t\tcreature.level = int(d.get("level", 1))''',
        '''\t\tcreature.resting = bool(d.get("resting", false))\n\t\tcreature.rested = bool(d.get("rested", false))\n\t\tcreature.rest_bed_index = int(d.get("rest_bed_index", -1))\n\t\tcreature.level = int(d.get("level", 1))''',
    )
    changed |= rep(
        root, "scripts/save/save_game.gd",
        '''\t\tif typeof(raw) == TYPE_DICTIONARY:\n\t\t\t(raw as Dictionary)["resting"] = false\n\tmigrated["party"] = party''',
        '''\t\tif typeof(raw) == TYPE_DICTIONARY:\n\t\t\t(raw as Dictionary)["resting"] = false\n\t\t\t(raw as Dictionary)["rested"] = false\n\t\t\t(raw as Dictionary)["rest_bed_index"] = -1\n\tmigrated["party"] = party''',
    )

    # Party is the sole availability authority. Setting the active pal to rest
    # automatically tries to move selection to the next eligible member.
    changed |= rep(
        root, "autoload/party.gd",
        '''func cycle_active(direction: int) -> bool:\n\tif _creatures.is_empty() or direction == 0:\n\t\treturn false''',
        '''func set_resting(index: int, value: bool, bed_index: int = -1) -> bool:\n\tvar creature: RefCounted = at(index)\n\tif creature == null:\n\t\treturn false\n\tcreature.set("resting", value)\n\tcreature.set("rest_bed_index", bed_index if value else -1)\n\tif value:\n\t\tcreature.set("rested", false)\n\t\tif index == _active:\n\t\t\tcycle_active(1)\n\trevision += 1\n\treturn true\n\n\nfunc cycle_active(direction: int) -> bool:\n\tif _creatures.is_empty() or direction == 0:\n\t\treturn false''',
    )

    # Game owns gradual progression because a bed node may be offscreen or
    # reconstructed. Direct hp manipulation is intentional: potion heal() is
    # forbidden from reviving, while bed rest is explicitly allowed to.
    changed |= rep(
        root, "autoload/game_state.gd",
        '''const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")\n\nconst ITEM_DB''',
        '''const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")\nconst CREATURE_PROGRESSION := preload("res://scripts/creatures/progression.gd")\n\nconst ITEM_DB''',
    )
    changed |= rep(
        root, "autoload/game_state.gd",
        '''func _process(delta: float) -> void:\n\t_tick_autosave(delta)\n\t_watch_pending_catch()''',
        '''func _process(delta: float) -> void:\n\t_tick_autosave(delta)\n\t_tick_creature_bed_recovery(delta)\n\t_watch_pending_catch()''',
    )
    # Insert recovery API before save/load section.
    changed |= rep(
        root, "autoload/game_state.gd",
        '''# --- save / load (R3.1) ------------------------------------------------------\n''',
        '''# --- creature-bed recovery (Gate A) -----------------------------------------\n\nfunc _tick_creature_bed_recovery(delta: float) -> void:\n\tif party == null or delta <= 0.0:\n\t\treturn\n\tvar cfg := CREATURE_PROGRESSION.config()\n\tvar seconds := maxf(float(cfg.get("creature_bed", {}).get("full_heal_seconds", 120.0)), 1.0)\n\tfor member: Variant in (party.call("members") as Array):\n\t\tvar creature := member as RefCounted\n\t\tif creature == null or not bool(creature.get("resting")):\n\t\t\tcontinue\n\t\tvar max_hp := float(creature.get("max_hp"))\n\t\tif max_hp <= 0.0:\n\t\t\tcontinue\n\t\tvar hp := minf(max_hp, float(creature.get("hp")) + max_hp / seconds * delta)\n\t\tcreature.set("hp", hp)\n\t\t# A bed is explicitly allowed to recover a fainted pal; unlike a potion,\n\t\t# it has paid the time/unavailability cost. Once it has real HP again the\n\t\t# faint flag no longer describes its physical state.\n\t\tif hp > 0.0:\n\t\t\tcreature.set("fainted", false)\n\n\n## Player sleep is the completion boundary. Only pals ACTUALLY assigned to a\n## creature bed receive the full overnight recovery/rest reward; otherwise the\n## bed would be optional decoration because ordinary sleep healed everyone.\nfunc complete_creature_bed_rests() -> int:\n\tif party == null:\n\t\treturn 0\n\tvar cfg := CREATURE_PROGRESSION.config()\n\tvar rest_xp := CREATURE_PROGRESSION.rest_xp(cfg)\n\tvar rest_bond := CREATURE_PROGRESSION.rest_bond(cfg)\n\tvar completed := 0\n\tfor i in party.call("size"):\n\t\tvar creature: RefCounted = party.call("at", i)\n\t\tif creature == null or not bool(creature.get("resting")):\n\t\t\tcontinue\n\t\tcreature.call("heal_fully")\n\t\tcreature.set("rested", true)\n\t\tcreature.set("resting", false)\n\t\tcreature.set("rest_bed_index", -1)\n\t\tif rest_xp > 0:\n\t\t\tcreature.call("gain_xp", rest_xp, cfg)\n\t\tif rest_bond > 0:\n\t\t\tcreature.call("gain_bond", rest_bond, cfg)\n\t\tcompleted += 1\n\tif completed > 0:\n\t\tparty.set("revision", int(party.get("revision")) + 1)\n\treturn completed\n\n\n# --- save / load (R3.1) ------------------------------------------------------\n''',
    )

    # Camp sleep no longer heals the whole belt for free. Bed-assigned pals
    # complete; trainer still rests, clock resets, autosave remains identical.
    old_camp = '''\tvar party: RefCounted = game.get("party")\n\tif party != null:\n\t\tvar cfg := PROGRESSION.config()\n\t\tvar rest_xp: int = PROGRESSION.rest_xp(cfg)\n\t\tvar rest_bond: int = PROGRESSION.rest_bond(cfg)\n\t\tfor member: Variant in (party.call("members") as Array):\n\t\t\t(member as RefCounted).call("heal_fully")\n\t\t\t# R4.1-remainder (spec §11): a bonding XP source, separate from\n\t\t\t# combat's. Every member gets it, fainted or not — see\n\t\t\t# progression.gd::rest_xp()'s own comment for why.\n\t\t\tif rest_xp > 0:\n\t\t\t\t(member as RefCounted).call("gain_xp", rest_xp, cfg)\n\t\t\t# R4.7 (spec §12: "Bond increases through... time together...\n\t\t\t# resting"). Same "every member, fainted or not" shape as rest_xp\n\t\t\t# above — resting is not something a hurt party member opts out of.\n\t\t\tif rest_bond > 0:\n\t\t\t\t(member as RefCounted).call("gain_bond", rest_bond, cfg)'''
    new_camp = '''\t# Gate A creature-bed contract: sleep completes only pals physically put\n\t# to bed. Non-resting party members keep their current HP, which is the\n\t# meaningful preparation tradeoff the bed is supposed to create.\n\tgame.call("complete_creature_bed_rests")'''
    changed |= rep(root, "scripts/build/camp.gd", old_camp, new_camp)

    # Bed receives its placed-building index after metadata is attached.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tif index >= 0:\n\t\tplaced.set_meta(PLACED_INDEX_META, index)\n\tplaced.add_to_group(PLACED_GROUP)''',
        '''\tif index >= 0:\n\t\tplaced.set_meta(PLACED_INDEX_META, index)\n\t\tif id == "creature_bed" and placed.has_method("set_build_index"):\n\t\t\tplaced.call("set_build_index", index)\n\tplaced.add_to_group(PLACED_GROUP)''',
    )

    # Rewrite creature_bed.gd wholesale through one anchored replacement. It
    # remains a small stateful wrapper over BUILD_PIECE, but now owns assignment
    # and the physical sleeping body.
    bed_path = root / "scripts/build/creature_bed.gd"
    old_bed = bed_path.read_text(encoding="utf-8")
    marker = "## Gate A physical-rest implementation"
    if marker not in old_bed:
        new_bed = '''extends Node3D\n\n## Gate A physical-rest implementation. The authoritative recovery state lives\n## on the CreatureInstance/Game; this placed node owns only which bed index it is,\n## assignment UI, and the visible sleeping body.\n\nconst BUILD_PIECE := preload("res://scripts/build/build_piece.gd")\nconst INTERACTABLE := preload("res://scripts/world/interactable.gd")\nconst REST_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")\nconst CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")\nconst CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")\n\nconst MESH_PATH := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"\nconst REST_ANCHOR := Vector3(0.0, 0.42, 0.0)\n\nstatic var _panel: CanvasLayer = null\nvar _piece: Node3D = null\nvar _build_index: int = -1\nvar _rest_body: Node3D = null\nvar _last_occupant: int = -2\n\n\nfunc build_ghost() -> void:\n\t_piece = BUILD_PIECE.new()\n\tadd_child(_piece)\n\t_piece.call("build_ghost", MESH_PATH)\n\n\nfunc build_real() -> void:\n\t_piece = BUILD_PIECE.new()\n\tadd_child(_piece)\n\t_piece.call("build_real", MESH_PATH)\n\tvar prompt: Node3D = INTERACTABLE.new()\n\tprompt.name = "Interactable"\n\tprompt.position = Vector3(0.0, 0.6, 0.7)\n\tprompt.call("configure", "Rest a Creature", 2.6, true)\n\tprompt.connect("activated", _on_rest)\n\tadd_child(prompt)\n\n\nfunc tint_ghost(ok: bool) -> void:\n\tif _piece != null and is_instance_valid(_piece):\n\t\t_piece.call("tint_ghost", ok)\n\n\nfunc set_build_index(index: int) -> void:\n\t_build_index = index\n\t_sync_rest_body(true)\n\n\nfunc build_index() -> int:\n\treturn _build_index\n\n\nfunc occupant_index() -> int:\n\tif _build_index < 0:\n\t\treturn -1\n\tvar game := get_node_or_null(^"/root/Game")\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tif party == null:\n\t\treturn -1\n\tfor i in party.call("size"):\n\t\tvar creature: RefCounted = party.call("at", i)\n\t\tif creature != null and bool(creature.get("resting")) \\\n\t\t\t\tand int(creature.get("rest_bed_index")) == _build_index:\n\t\t\treturn i\n\treturn -1\n\n\nfunc assign_creature(index: int) -> bool:\n\tif _build_index < 0 or occupant_index() >= 0:\n\t\treturn false\n\tvar game := get_node_or_null(^"/root/Game")\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tvar creature: RefCounted = party.call("at", index) if party != null else null\n\tif creature == null or bool(creature.get("resting")):\n\t\treturn false\n\tif not bool(party.call("set_resting", index, true, _build_index)):\n\t\treturn false\n\t_sync_rest_body(true)\n\treturn true\n\n\nfunc wake_creature_early() -> bool:\n\tvar index := occupant_index()\n\tif index < 0:\n\t\treturn false\n\tvar game := get_node_or_null(^"/root/Game")\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tvar creature: RefCounted = party.call("at", index) if party != null else null\n\tif creature == null:\n\t\treturn false\n\t# HP already regenerated directly on the instance; clearing assignment is\n\t# all early wake does. No full-heal/rested bonus is granted.\n\tcreature.set("rested", false)\n\tparty.call("set_resting", index, false)\n\t_sync_rest_body(true)\n\treturn true\n\n\nfunc is_occupied() -> bool:\n\treturn occupant_index() >= 0\n\n\nfunc _process(_delta: float) -> void:\n\t_sync_rest_body(false)\n\n\nfunc _sync_rest_body(force: bool) -> void:\n\tvar index := occupant_index()\n\tif not force and index == _last_occupant:\n\t\treturn\n\t_last_occupant = index\n\tif _rest_body != null and is_instance_valid(_rest_body):\n\t\t_rest_body.queue_free()\n\t_rest_body = null\n\tif index < 0:\n\t\treturn\n\tvar game := get_node_or_null(^"/root/Game")\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tvar creature: RefCounted = party.call("at", index) if party != null else null\n\tif creature == null:\n\t\treturn\n\t_rest_body = CREATURE_SCENE.instantiate() as Node3D\n\tif _rest_body == null:\n\t\treturn\n\t_rest_body.name = "RestingCreature"\n\t_rest_body.set_script(CREATURE_BODY)\n\tadd_child(_rest_body)\n\t_rest_body.call("setup", str(creature.get("species_id")), bool(creature.get("shiny")))\n\t_rest_body.position = REST_ANCHOR\n\t_rest_body.rotation.y = PI * 0.5\n\t_rest_body.collision_layer = 0\n\t_rest_body.collision_mask = 0\n\t_rest_body.set_physics_process(false)\n\t# Reuse the shipped creature faint/lie animation as the closest authored\n\t# resting pose. The body is visibly in bed and non-interactive; visual-judge\n\t# decides whether a later dedicated sleep pose is warranted.\n\t_rest_body.call_deferred("play_faint")\n\n\nfunc _on_rest() -> void:\n\tif _panel == null or not is_instance_valid(_panel):\n\t\t_panel = REST_PANEL.new()\n\t\tget_tree().root.add_child(_panel)\n\t_panel.call("open", self)\n'''
        bed_path.write_text(new_bed, encoding="utf-8")
        print("batch3 rewrote scripts/build/creature_bed.gd")
        changed = True

    # Replace instant-heal UI handler with assign/wake semantics and status rows.
    changed |= rep(
        root, "scripts/ui/creature_bed_panel.gd",
        '''\t\tif creature == null:\n\t\t\tbutton.text = "  %d.  empty" % (i + 1)\n\t\t\tbutton.disabled = true\n\t\telse:\n\t\t\tvar fainted := bool(creature.get("fainted"))\n\t\t\tvar status := "fainted" if fainted else "HP %d / %d" % [\n\t\t\t\tint(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp")))),\n\t\t\t]\n\t\t\tbutton.text = "  %d.  %-16s %s" % [i + 1, str(creature.call("label")), status]\n\t\t\tvar index := i\n\t\t\tbutton.pressed.connect(func() -> void: _on_rest_row(index))''',
        '''\t\tif creature == null:\n\t\t\tbutton.text = "  %d.  empty" % (i + 1)\n\t\t\tbutton.disabled = true\n\t\telse:\n\t\t\tvar fainted := bool(creature.get("fainted"))\n\t\t\tvar resting := bool(creature.get("resting"))\n\t\t\tvar this_bed := resting and _bed != null and int(creature.get("rest_bed_index")) == int(_bed.call("build_index"))\n\t\t\tvar status := "Resting — HP %d / %d" % [int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp"))))] \\\n\t\t\t\tif this_bed else ("Resting elsewhere" if resting else ("fainted" if fainted else "HP %d / %d" % [int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp"))))]))\n\t\t\tbutton.text = "  %d.  %-16s %s" % [i + 1, str(creature.call("label")), status]\n\t\t\tvar occupied := _bed != null and int(_bed.call("occupant_index")) >= 0\n\t\t\tbutton.disabled = (occupied and not this_bed) or (resting and not this_bed)\n\t\t\tvar index := i\n\t\t\tbutton.pressed.connect(func() -> void: _on_rest_row(index))''',
    )
    old_handler = '''func _on_rest_row(index: int) -> void:\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tvar creature: RefCounted = party.call("at", index) if party != null else null\n\tif creature == null:\n\t\treturn\n\n\tvar was_fainted := bool(creature.get("fainted"))\n\tvar label := str(creature.call("label"))\n\tHOME_RECOVERY.rest(creature, PROGRESSION.config())\n\n\tif _message != null:\n\t\t_message.text = (\n\t\t\t"%s wakes up, fully rested." % label if was_fainted\n\t\t\telse "%s rests and wakes refreshed." % label\n\t\t)\n\n\t_refresh()'''
    new_handler = '''func _on_rest_row(index: int) -> void:\n\tvar party: RefCounted = game.get("party") if game != null else null\n\tvar creature: RefCounted = party.call("at", index) if party != null else null\n\tif creature == null or _bed == null or not is_instance_valid(_bed):\n\t\treturn\n\tvar label := str(creature.call("label"))\n\tvar this_bed := bool(creature.get("resting")) and int(creature.get("rest_bed_index")) == int(_bed.call("build_index"))\n\tif this_bed:\n\t\tif bool(_bed.call("wake_creature_early")) and _message != null:\n\t\t\t_message.text = "%s wakes early. Partial HP kept; no full-rest bonus." % label\n\telif bool(_bed.call("assign_creature", index)):\n\t\tif _message != null:\n\t\t\t_message.text = "%s is resting. HP will recover gradually; sleep overnight to complete the rest." % label\n\telse:\n\t\tif _message != null:\n\t\t\t_message.text = "That bed or creature is not available."\n\t_refresh()'''
    changed |= rep(root, "scripts/ui/creature_bed_panel.gd", old_handler, new_handler)

    # The panel no longer owns instant HOME_RECOVERY/PROGRESSION arithmetic.
    changed |= rep(
        root, "scripts/ui/creature_bed_panel.gd",
        '''const PARTY := preload("res://autoload/party.gd")\nconst PROGRESSION := preload("res://scripts/creatures/progression.gd")\nconst HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")''',
        '''const PARTY := preload("res://autoload/party.gd")''',
    )

    # A resting active follower must disappear immediately and cannot be summoned.
    changed |= rep(
        root, "scripts/combat/encounter_director.gd",
        '''\tvar creature: RefCounted = party.call("active")\n\tif creature == null or bool(creature.get("fainted")):\n\t\treturn false''',
        '''\tvar creature: RefCounted = party.call("active")\n\tif creature == null or bool(creature.get("fainted")) or bool(creature.get("resting")):\n\t\treturn false''',
    )
    changed |= rep(
        root, "scripts/combat/encounter_director.gd",
        '''\tvar active_creature: RefCounted = party.call("active")\n\tif active_creature == null or active_creature == _ally:\n\t\treturn  # The change wasn't to the creature that is actually out.''',
        '''\tvar active_creature: RefCounted = party.call("active")\n\tif _ally != null and bool(_ally.get("resting")):\n\t\tdismiss_active_creature()\n\t\tif active_creature != null and not bool(active_creature.get("resting")):\n\t\t\tsummon_active_creature()\n\t\treturn\n\tif active_creature == null or active_creature == _ally:\n\t\treturn  # The change wasn't to the creature that is actually out.''',
    )

    # Combat itself refuses a resting member even if a malformed caller passes it.
    changed |= rep(
        root, "scripts/combat/combat_manager.gd",
        '''\tvar creature := active_creature()\n\tif creature == null or creature.fainted:\n\t\treturn false''',
        '''\tvar creature := active_creature()\n\tif creature == null or creature.fainted or bool(creature.get("resting")):\n\t\treturn false''',
    )

    return changed
