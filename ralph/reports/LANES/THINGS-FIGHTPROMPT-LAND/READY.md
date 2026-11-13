# THINGS-FIGHTPROMPT-LAND: no world verb across the fight HUD

STATUS: land

- **Branch:** `tb/things-fightprompt-land`, cut from `origin/main` d4960ba6.
- **Kind:** correctness fix (UI). No GPU verdict needed; the Tidewake fight rows (F39#7, F39#19, F39#3) should be re-captured after it.
- **Fault:** `_sheet_gpu_main_prompt_in_fight.jpg` (main at High, `G-things-foestand-tidewake`, Venn t-000.00): "Gather Reef Stone" with its button glyph sits in the middle of the fight HUD, above the command strip, in every Venn fight frame. It has been reported and patched three times in `playground_hud.gd` (22 Oct, close-1024, close-1025) and was still on screen on 12 Nov.
- **Cause (CPU probe at each saved fight frame):** the earlier fixes all hid PlaygroundHUD's prompt, and that one is hidden. The text on screen is a second label, `CombatHUD/Root/Prompt`. `combat_hud.gd _draw_prompt` skipped its "is this line the encounter director's own?" check while fighting, on the assumption that the interaction arbiter is disabled in a fight. That holds only in Meadows, where a SequenceDirector disables it. Tidewake, Cloudreach and Stormwood have none, so a harvest node beside the fighters keeps winning the arbiter and the fight HUD repeats its verb.
- **Fix:** `scripts/ui/combat_hud.gd _draw_prompt`: the ownership check runs in and out of a fight (one condition). The row still shows the director's own lines ("Engage X", recall lines).
- **Shown (CPU, same probe after the fix):** no visible label carries "Gather" in any of the four saved Venn fight frames; before, `CombatHUD/Root/Prompt` did in all four.
- **Tests:** new `tests/test_combat_hud_fight_prompt_ownership.gd` (2 tests).
- **Tests run on this branch:** all `test_combat_hud*` and `test_*prompt*` files (10 files): 34 tests, 154 assertions, 0 failed. `tests/smoke_no_double_prompt.gd` run directly: OK ("CombatHUD only shows its own offers").
- **Not run:** a Cloudreach or Stormwood fight capture (same code path; not captured on CPU), and the full smoke suite.
- **Behaviour note:** in a realm without a SequenceDirector, a fight line that the director does not own would now be blank instead of mirrored. Meadows fights already showed nothing there, so this makes the other realms match.
- No `.uid` files are included.
