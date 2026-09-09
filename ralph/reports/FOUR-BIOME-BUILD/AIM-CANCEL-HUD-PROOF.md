# Aim cancel and hotbar input ownership

## Bounded brief — before execution, 2026-09-09

The first cancellation proof passed 19 checks but omitted the real HUD. B maps
both menu_cancel and hotbar_1. The HUD excludes active aim, but its idle poll may
run after the physics callback has canceled aim. This new experiment checks that
specific ownership interval; it is not another camera convergence attempt.

`tools/aim_cancel_hud_probe.gd` mounts the actual PlaygroundHUD scene with the
retained native camera/player/ThrowAim fixture and synthetic Combat wrapper.
An independent positive control must equip a seeded slot-one axe through a real
B press outside aim. The measured case then starts with no equipped tool and
uses the previous stale-commit/physical-cancel mechanism, allowing subsequent
natural HUD idle polls before teardown. No direct HUD polling call, inventory
repair, production edit, or campaign state is used. Stock and hotbar assignment
are disclosed initial fixture state. This is not a full combat-manager proof.

One native execution after parse check, isolated profile, 20-second watchdog;
stop at its first result. Pass requires no extra tool equip, no orb spend and no
reopened aim after cancellation. A failing result blocks driver integration.

## Result

The first execution passed eight checks (exit 0). The positive control equipped
the axe through physical B. The measured stale commit occurred at physics frame
49/process 33, was canceled at physics 50/process 34, and subsequent actual HUD
idle polls left equipped_tool empty, stock at four and aim closed. No orb was
released. The suspected duplicate hotbar action did not reproduce in this case.

Payload: `.artifacts/aim-cancel-hud-20260909/engine.log`. Native parse passed;
the installed Godot 4.7 binary ran headless with isolated APPDATA/LOCALAPPDATA.
The log contains no ERROR or SCRIPT ERROR. One expected warning says the
positive-control HUD has no player; that independent control deliberately has
only a live HUD and inventory. The measured fixture has the production player.

This establishes the tested ordinary HUD polling interval, not every frame ratio,
slot action or full combat-manager side effect. No production or earned driver
change was made by the experiment.
