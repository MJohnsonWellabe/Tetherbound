#!/usr/bin/env python3
"""Apply the integrated Gate A fixes on the Claude delivery branch.

This file exists because the chat GitHub connector can create/replace files but
cannot apply a normal textual patch to the checked-out repository. GitHub
Actions runs this script against a real checkout, where each replacement is
asserted before it is made. A missing/changed anchor fails loudly instead of
silently corrupting a file.

The script is intentionally idempotent: a replacement already present is a
no-op. It is branch tooling for Gate A and can be removed after the gate lands.
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

    # RG1 owner repro: Pause -> Build must never inherit a stale paused tree.
    # The build menu is deliberately live-world UI; an armed build ghost while
    # SceneTree.paused is true is a total-control lock because the placer and
    # ordinary world input cannot tick.
    changed |= replace_once(
        "scripts/ui/tab_build.gd",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
        "\tif menu != null:\n\t\tmenu.call(\"close\")\n\t# RG1 (owner 2026-08-18): Build is a live-world surface. Never trust a\n\t# cached pause snapshot from the shell during this handoff; if it was stale,\n\t# the build menu opens visibly while the entire world/placer stays paused.\n\t# Closing the shell is the transition authority and Build explicitly needs\n\t# an unpaused tree before its deferred open.\n\tget_tree().paused = false\n\tvar build_menu := BUILD_MENU.get_or_make(get_tree())\n",
    )

    # The pause shell is only legal from the live world (story/combat/build
    # ownership already refuses it). Restoring a stale true snapshot on close
    # is therefore never correct and is exactly the systemic freeze shape.
    changed |= replace_once(
        "scripts/ui/game_menu.gd",
        "\tInput.mouse_mode = _mouse_before\n\tget_tree().paused = _paused_before\n\t_set_world_hud_visible(true)\n",
        "\tInput.mouse_mode = _mouse_before\n\t# RG1: the shell releases pause ownership; it must not resurrect a stale\n\t# paused snapshot captured during an earlier modal transition. All legal\n\t# open paths originate from the live world, so release means unpaused.\n\tget_tree().paused = false\n\t_set_world_hud_visible(true)\n",
    )

    # Paused interaction panels all participate in input_owner. Once a panel
    # marks itself closed, restore world control only when no newer/live owner
    # remains. This prevents an old _paused_before=true snapshot from winning
    # after a handoff while still respecting a genuinely stacked owner.
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

    print("Gate A patch driver complete" + (" (changes applied)" if changed else " (already applied)"))


if __name__ == "__main__":
    main()
