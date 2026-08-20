#!/usr/bin/env python3
"""Apply the integrated Gate A fixes on the Claude delivery branch.

GitHub Actions runs this against a real checkout. Every source edit is anchored
and asserted: if current code differs from what was inspected, the job fails
instead of guessing. The driver is idempotent and temporary; remove it after
Gate A lands.
"""
from pathlib import Path
from gate_a_batch2 import apply as apply_batch2

ROOT = Path(__file__).resolve().parents[1]


def replace_once(rel: str, old: str, new: str) -> bool:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{rel}: expected exactly one patch anchor, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"patched {rel}")
    return True


def main() -> None:
    changed = False

    # RG1 batch already applied on the first run. Keep these exact target texts
    # here so later runs recognize them as satisfied rather than trying to
    # rewrite the comments themselves.
    changed |= replace_once(
        "scripts/ui/tab_build.gd",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\t# RG1 (owner 2026-08-18): Build is a live-world surface. Never trust a\n\t# cached pause snapshot from the shell during this handoff; if it was stale,\n\t# the build menu opens visibly while the entire world/placer stays paused.\n\t# Closing the shell is the transition authority and Build explicitly needs\n\t# an unpaused tree before its deferred open.\n\tget_tree().paused = false\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
    )

    changed |= replace_once(
        "scripts/ui/game_menu.gd",
        "\tInput.mouse_mode = _mouse_before\n\tget_tree().paused = _paused_before\n\t_set_world_hud_visible(true)\n",
        "\tInput.mouse_mode = _mouse_before\n\t# RG1: the shell releases pause ownership; it must not resurrect a stale\n\t# paused snapshot captured during an earlier modal transition. All legal\n\t# open paths originate from the live world, so release means unpaused.\n\tget_tree().paused = false\n\t_set_world_hud_visible(true)\n",
    )

    old_release = "\tInput.mouse_mode = _mouse_before\n\tget_tree().paused = _paused_before\n"
    new_release = (
        "\t# RG1: release is determined by the live ownership graph, not by the\n"
        "\t# pause bit this panel happened to observe when it opened. A cached\n"
        "\t# true value can come from a previous modal in the same handoff and\n"
        "\t# restoring it after every visible panel is gone freezes the world.\n"
        "\tif INPUT_OWNER.current(get_tree()) == null:\n"
        "\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED\n"
        "\t\tget_tree().paused = false\n"
    )
    for rel in [
        "scripts/ui/shop_panel.gd",
        "scripts/ui/swap_panel.gd",
        "scripts/ui/creature_bed_panel.gd",
        "scripts/ui/craft_panel.gd",
        "scripts/ui/storage_panel.gd",
    ]:
        changed |= replace_once(rel, old_release, new_release)

    # BUILD-FLOW: keep the selected piece armed after every successful placement.
    changed |= replace_once(
        "scripts/build/build_placer.gd",
        "\tgame.call(\"register_building\", armed, placed.global_position, yaw_deg)\n\tgame.set(\"pending_build\", \"\")\n\tAUDIO_CUES.play(&\"build_place\")\n\t_drop_ghost()\n",
        "\tgame.call(\"register_building\", armed, placed.global_position, yaw_deg)\n\t# BUILD-FLOW (owner 2026-08-18): selection persists after a successful\n\t# placement. The next physics tick moves the same ghost to the next candidate\n\t# location; costs and registration still happen once per fresh Place edge.\n\t# Only explicit Cancel or choosing another catalogue entry clears/replaces it.\n\tAUDIO_CUES.play(&\"build_place\")\n",
    )

    # Exact RG1 regression: production Pause -> Build-tab button handoff.
    changed |= replace_once(
        "tests/smoke_post_modal_control.gd",
        "\tawait _check_control_survives_a_trader_conversation_and_shop()\n\tawait _check_control_survives_placing_a_build()\n",
        "\tawait _check_control_survives_a_trader_conversation_and_shop()\n\tawait _check_pause_menu_to_build_handoff()\n\tawait _check_control_survives_placing_a_build()\n",
    )

    insert_anchor = "\n\n## A build: arm a camp (free build, so cost is not the variable under test),\n"
    new_test = r'''

## Owner's severe repro: Pause/Main menu -> Build -> Open Build Menu. This must
## hand pause ownership back before the live-world build surface opens.
func _check_pause_menu_to_build_handoff() -> void:
	if not bool(_menu.call("open", "build")):
		_fail("pause->build: pause menu refused to open on Build tab")
		return
	for i in 3:
		await process_frame
	if not paused:
		_fail("pause->build: pause menu did not pause the tree")
		return

	var launch: Button = _find_button_with_text(_menu, "Open Build Menu")
	if launch == null:
		_fail("pause->build: Build tab has no Open Build Menu button")
		_menu.call("close")
		return
	launch.emit_signal("pressed")
	for i in 5:
		await process_frame

	if paused:
		_fail("pause->build: tree stayed paused after handoff to live build menu")
		return
	if bool(_menu.call("is_open")):
		_fail("pause->build: pause shell remained open after handoff")
		return

	var build_menu: Node = null
	for node: Node in root.get_children():
		if node.name == "BuildMenu" and node.has_method("is_open") and bool(node.call("is_open")):
			build_menu = node
			break
	if build_menu == null:
		_fail("pause->build: live BuildMenu never opened")
		return
	build_menu.call("close")
	for i in 3:
		await process_frame
	await _assert_control_returned("pause->build")


func _find_button_with_text(node: Node, needle: String) -> Button:
	if node is Button and needle in (node as Button).text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button_with_text(child, needle)
		if found != null:
			return found
	return null
'''
    changed |= replace_once(
        "tests/smoke_post_modal_control.gd",
        insert_anchor,
        new_test + insert_anchor,
    )

    changed |= apply_batch2(ROOT)

    print("Gate A patch driver complete" + (" (changes applied)" if changed else " (already applied)"))


if __name__ == "__main__":
    main()
