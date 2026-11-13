# THINGS-REDLEAF: the red "bush" by the Burrow Warrens (hard rule: red is Team Tether's)

**Flag from the judges.** `G-things-meadowground` (0f981658), 3/3 on both sides: "a bright red bush or crest on the back" of the badgers in the Burrow Warrens frames (F38#30, F38#24).

**What it is.** Not the creature. It is an ironwood harvest tree standing behind them. Six ironwood harvest nodes in band 2 and band 3 are built from `TwistedTree_1` and `TwistedTree_3`, whose leaf material ships crimson in the asset pack. Scatter layers swap that leaf sheet for the green one, and a harvest node borrows the swap from the scatter layer that lists its model; the grove layer lists only `TwistedTree_2` and `_4`, so `_1` and `_3` got nothing. GATE-D4b found the same leak in band 4 and re-authored that stand; bands 2 and 3 were flagged then and left.

**Change** (`scripts/world/harvest_node.gd`, no flag: a colour-rule fix). A harvest model that no layer lists takes the leaf tint and leaf swap of a listed sibling of the same family (same path, another number). No node is moved or re-authored; trunks and shapes are unchanged.

**CPU** (`_sheet_redleaf_off_vs_on_cpu.jpg`; left main, right this branch; Warrens walk_03): the crimson tree behind the badger is green. A scene probe (meshes still wearing the crimson leaf sheet within 120 m) lists three on main and none on this branch.

**Tests.** `tests/test_harvest_sibling_leaf_fixup.gd` (3), with test_felled_resource and test_band_pickups: 43 tests, 0 failed.

**Ask.** F38#30 and F38#24 job.json frames (the Warrens route), base = main, arm = tb/things, High. No overlay.
