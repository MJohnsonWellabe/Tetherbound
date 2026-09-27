# Warrens branch vault from the earned save

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save`, loaded unmodified with `--save-dir` (earned C1 chain; receipts in that checkpoint).
- **Run:** render.yml **36293531808** at **c9b311ef** (replaces 36284353244, whose frames judge C failed), `--act --activity=vault --budget-s=2400`.
- **Walk:** the player leaves the Hall, walks the road to the Burrow Warrens, lines up on the doorway, and walks mouth → hall → den, then takes the branch passage to the vault. It frames the den looking down the passage to the lit vault (`branch-den-toward-vault`) and the passage itself (`branch-passage`). The required guardian was beaten earlier in the earned chain (`receipts/warrens.json`: `warrens_cleared`), and a cleared Warrens spawns none.
- **Action:** "Engage Elder Trailpup" (Lv13), fight won ("The Elder Trailpup yields two large potions"), then "Take the heartstone" is offered.
- **Flags:** the game set `warrens_once_elder_trailpup`.

Wild fights on the road are omitted from the committed frames; the receipt lists them.
