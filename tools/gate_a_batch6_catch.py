#!/usr/bin/env python3
"""Gate A batch 6: held over-shoulder catch aim + explicit reticle."""
from pathlib import Path


def rep(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f"{rel}: batch6 expected one anchor, got {n}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch6 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    # Reticle is a lightweight screen-space overlay owned by aim mode itself.
    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''var _orb: Node3D = null\n\nvar _windup: float = 0.0''',
        '''var _orb: Node3D = null\nvar _reticle_layer: CanvasLayer = null\nvar _reticle: Control = null\n\nvar _windup: float = 0.0''',
    )

    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''\t_throw_cooldown = float(cfg.get("cooldown", _throw_cooldown))\n\tset_physics_process(false)''',
        '''\t_throw_cooldown = float(cfg.get("cooldown", _throw_cooldown))\n\t_build_reticle()\n\tset_physics_process(false)''',
    )

    # Held grammar: RB/Throw is the aim hold; RT/quick commits while held.
    old_tick = '''\t# Backing out is free and spends nothing, INCLUDING during the release\n\t# wind-up — the orb is only spent in _release() itself. The cancel used to\n\t# be unreachable once the wind-up started (the early return sat above it),\n\t# which turned a mis-press into a guaranteed spent orb 0.18s later.\n\tif _guard <= 0.0 and (Input.is_action_just_pressed("combat_run")\n\t\t\tor Input.is_action_just_pressed("menu_cancel")):\n\t\t_leave_aim()\n\t\treturn\n\n\tif _windup > 0.0:\n\t\t_windup -= delta\n\t\tif _windup <= 0.0:\n\t\t\t_release()\n\t\treturn\n\tif _guard > 0.0:\n\t\treturn\n\n\tif Input.is_action_just_pressed("combat_throw") or Input.is_action_just_pressed("combat_quick"):\n\t\t_windup = _release_windup'''
    new_tick = '''\t# Gate A held-aim grammar. The same RB/Throw press that ENTERS aim must\n\t# remain held to keep the shoulder camera. Releasing it or pressing B backs\n\t# out for free. RT (combat_quick) commits exactly one throw while held; the\n\t# combat manager is deaf while ThrowAim is busy, so RT cannot also attack.\n\tif _guard <= 0.0 and (not Input.is_action_pressed("combat_throw")\n\t\t\tor Input.is_action_just_pressed("combat_run")\n\t\t\tor Input.is_action_just_pressed("menu_cancel")):\n\t\t_leave_aim()\n\t\treturn\n\n\tif _windup > 0.0:\n\t\t# Let-go during the brief release windup still cancels free; the orb is\n\t\t# consumed only in _release(), never merely by starting the gesture.\n\t\tif not Input.is_action_pressed("combat_throw"):\n\t\t\t_leave_aim()\n\t\t\treturn\n\t\t_windup -= delta\n\t\tif _windup <= 0.0:\n\t\t\t_release()\n\t\treturn\n\tif _guard > 0.0:\n\t\treturn\n\n\tif Input.is_action_just_pressed("combat_quick"):\n\t\t_windup = _release_windup'''
    changed |= rep(root, "scripts/combat/throw_aim.gd", old_tick, new_tick)

    # Explicit reticle lifecycle.
    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''\t_apply_aim_camera()\n\t# Owner playtest report, second round:''',
        '''\t_apply_aim_camera()\n\t_set_reticle_visible(true)\n\t# Owner playtest report, second round:''',
    )
    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''\t_hide_preview()\n\t_set_trainer_movable(false)\n\taim_exited.emit()''',
        '''\t_hide_preview()\n\t_set_reticle_visible(false)\n\t_set_trainer_movable(false)\n\taim_exited.emit()''',
    )
    # Release hides reticle immediately while projectile flies.
    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''\t_hide_preview()\n\n\tvar camera := _aim_camera()''',
        '''\t_hide_preview()\n\t_set_reticle_visible(false)\n\n\tvar camera := _aim_camera()''',
    )

    # Add reticle builder before arc section.
    changed |= rep(
        root, "scripts/combat/throw_aim.gd",
        '''## --- the arc ---------------------------------------------------------------\n''',
        '''## --- reticle ---------------------------------------------------------------\n\nfunc _build_reticle() -> void:\n\tif _reticle_layer != null:\n\t\treturn\n\t_reticle_layer = CanvasLayer.new()\n\t_reticle_layer.name = "ThrowReticleLayer"\n\t_reticle_layer.layer = 25\n\tadd_child(_reticle_layer)\n\t_reticle = Control.new()\n\t_reticle.name = "ThrowReticle"\n\t_reticle.set_anchors_preset(Control.PRESET_FULL_RECT)\n\t_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\t_reticle.draw.connect(_draw_reticle)\n\t_reticle_layer.add_child(_reticle)\n\t_reticle.visible = false\n\n\nfunc _set_reticle_visible(value: bool) -> void:\n\tif _reticle != null:\n\t\t_reticle.visible = value\n\t\tif value:\n\t\t\t_reticle.queue_redraw()\n\n\nfunc _draw_reticle() -> void:\n\tif _reticle == null:\n\t\treturn\n\tvar c := _reticle.size * 0.5\n\tvar colour := Color(0.72, 0.94, 0.86, 0.95)\n\t# Open ring + four short ticks: readable against meadow/sky without\n\t# pretending there is a hard lock. The trajectory itself changes teal when\n\t# the real ballistic path intersects the target, which is the assist cue.\n\t_reticle.draw_arc(c, 18.0, 0.0, TAU, 32, colour, 2.5, true)\n\tfor dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:\n\t\t_reticle.draw_line(c + dir * 25.0, c + dir * 35.0, colour, 2.5, true)\n\n\n## --- the arc ---------------------------------------------------------------\n''',
    )

    # HUD/config copy: call the control what it actually is now. No new input
    # action or balance changes; RB remains combat_throw, RT remains quick.
    changed |= rep(
        root, "data/config/menu.json",
        '''        "combat_throw": "Throw an orb",''',
        '''        "combat_throw": "Hold to aim an orb",''',
    )

    return changed
