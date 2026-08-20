#!/usr/bin/env python3
"""Apply the integrated Gate A fixes on the Claude delivery branch.

GitHub Actions runs this against a real checkout. Every source edit is anchored
and asserted: if current code differs from what was inspected, the job fails
instead of guessing. The driver is idempotent and temporary; remove it after
Gate A lands.
"""
from pathlib import Path

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

    # RG1: Pause -> Build is a live-world handoff. Never let a stale pause
    # snapshot leave the build menu visible over a frozen SceneTree.
    changed |= replace_once(
        "scripts/ui/tab_build.gd",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\t# RG1 (owner 2026-08-18): Build is a live-world surface. Closing the\n\t# pause shell is the transition authority; Build must never inherit a\n\t# stale paused tree from another modal snapshot.\n\tget_tree().paused = false\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
    )

    # GameMenu is only allowed to open from world ownership. Closing it means
    # relinquishing pause, not restoring a historical true bit.
    changed |= replace_once(
        "scripts/ui/game_menu.gd",
        "\tInput.mouse_mode = _mouse_before\n\tget_tree().paused = _paused_before\n\t_set_world_hud_visible(true)\n",
        "\tInput.mouse_mode = _mouse_before\n\t# RG1: release pause ownership. A cached true value can belong to an old\n\t# modal handoff and restoring it here produces a menu-free frozen world.\n\tget_tree().paused = false\n\t_set_world_hud_visible(true)\n",
    )

    # Other paused panels all join input_owner. Once a panel marks itself
    # closed, world control returns iff no other live owner remains. This makes
    # ownership, not stale open-time snapshots, authoritative.
    old_release = "\tInput.mouse_mode = _mouse_before\n\tget_tree().paused = _paused_before\n"
    new_release = (
        "\t# RG1: release from the live ownership graph, not a cached pause bit.\n"
        "\t# If another modal still owns input it remains authoritative; if none\n"
        "\t# does, the world must be live and mouse-captured again.\n"
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

    # Prompt 40: successful placement consumes/registers exactly one piece but
    # keeps the selected buildable armed. Existing just_pressed/_place_blocked
    # logic already guarantees a fresh edge for each copy; cancel remains the
    # explicit path that clears pending_build and drops the ghost.
    changed |= replace_once(
        "scripts/build/build_placer.gd",
        "\tgame.call(\"register_building\", armed, placed.global_position, yaw_deg)\n\tgame.set(\"pending_build\", \"\")\n\tAUDIO_CUES.play(&\"build_place\")\n\t_drop_ghost()\n",
        "\tgame.call(\"register_building\", armed, placed.global_position, yaw_deg)\n\t# BUILD-FLOW (owner 2026-08-18): selection persists after a successful\n\t# placement. The next physics tick moves the same ghost to the next candidate\n\t# location; costs and registration still happen once per fresh Place edge.\n\t# Only explicit Cancel or choosing another catalogue entry clears/replaces it.\n\tAUDIO_CUES.play(&\"build_place\")\n",
    )

    # Exact RG1 regression: exercise the production Pause -> Build tab button
    # handoff, not merely a direct pending_build assignment.
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

    print("Gate A patch driver complete" + (" (changes applied)" if changed else " (already applied)"))


if __name__ == "__main__":
    main()
