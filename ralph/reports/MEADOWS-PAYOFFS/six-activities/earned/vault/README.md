# Warrens branch vault from the earned save

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save`, loaded unmodified with `--save-dir` (earned C1 chain; receipts in that checkpoint).
- **Run:** render.yml 36284353244 at 4bffc5bc, `--act --activity=vault --budget-s=2400`.
- **Walk:** the player leaves the Hall, walks the road to the Burrow Warrens, lines up on the doorway, and walks mouth → hall → den → vault.
- **Action:** "Engage Elder Trailpup" (Lv13), fight won ("The Elder Trailpup yields two large potions"), then "Take the heartstone" is offered.
- **Flags:** the game set `warrens_once_elder_trailpup`.

Wild fights on the road are omitted from the committed frames; the receipt lists them.
