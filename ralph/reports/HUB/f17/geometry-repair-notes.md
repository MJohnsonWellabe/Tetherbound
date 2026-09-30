# F17 geometry first-run repairs

Pinned first run: 6f083d1d4c399c9d231d7628147bc82037b671ec. Warm import native 0 (463.391s); focused 44 methods / 3982 assertions / 4 failing methods, native 1. Original warm-import.txt and geometry-initial.txt retained.

The actual nave doorway was at local +15 while the road and entrance were at -15; move end-wall modules, rendered Wall_Arch and split front colliders to the road-facing -15 together. Side-room, scale and modules remain unchanged. The same actual wall-box assertions remain.

Stoneyard fingerpost now stands at [17,-24], 3m off the actual field side lane, and points along it. Its name/resources remain unchanged.

Berry harvest order1031 moves only position [28,6] to [30,8], 4.24m from Mira's moved door. Python normalized whole-document equality after restoring only that tuple passes. Item, amount, model, identity and all other rows remain unchanged; owner approved exact tuple. No earned-save edit/reset.

No repeat runtime or F17 acceptance claimed yet. Four failing methods will receive one affected-file correction check with their retained assertions. All visual/player/terrain-bake gates remain open.
