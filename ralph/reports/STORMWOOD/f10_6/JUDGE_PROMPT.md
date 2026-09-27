You are a code-blind visual judge for a stylised creature-expedition action RPG played on a 7-inch handheld at arm's length (about 450 mm). Do not read any source code, config, git history, reports or other documents in the repository except the files named here. You judge pictures only.

Read `.claude/skills/visual-judge/SKILL.md` (sections "The target", "The rubric" and "The verdict") and apply that rubric, including the Interface criterion.

**References:**
- Bar A: `docs/reference/tetherbound-meadows-keyart.png` plus `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` and `-board-b.png`.
- Bar B: `docs/reference/palworld-01-boss-fight-forest.jpg` through `palworld-05-base-building.jpg`.

**Frames:** `ralph/reports/STORMWOOD/f10_6/`.
- `_sheet_7inch.jpg`: each cell is scaled to the physical width of a 7-inch 16:9 panel on a normal monitor. **Judge readability from this sheet at 100% zoom only**, as if each cell were the handheld screen.
- `explore/*.jpg` and `fight/*.jpg`: the same 1920x1080 frames at full size, for checking what a detail actually is. They are not for readability calls.
- The chapter is a permanently purple storm forest. Break is its lightning peak.

**The device-profile read.** Answer each yes or no, naming the frame:
1. HUD text is legible at 7-inch size: the objective card, the health and food bars, the enemy name and level, the tell text ("incoming — move", "it's open — hit it"), the team list and the move buttons.
2. Tells and danger are legible: the enemy's attack warning shapes and the lightning ground warning (the ring).
3. Subjects are legible: the trainer, the piloted creature and the opponent can each be found in under a second, and none is hidden by the HUD.
4. The HUD keeps a safe area and doesn't cover the fight's key action.

**Then give the full visual-judge verdict:** specific, addressable defects by frame; the three biggest gaps from the references, ranked; and **Bar A yes/no** and **Bar B yes/no**, each with what carried or sank it. Split the gaps into scene-fixable and needs-new-art.

**End with "TOP FIXES":** the three most important fixable changes for handheld readability and looks.

Write your whole answer to `ralph/reports/STORMWOOD/f10_6/JUDGE.md`. Your final message should give only the four device answers, Bar A/B and TOP FIXES.
