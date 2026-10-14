# F19#5 Stormwood crown_build: earned, as three chained pieces (routes, Tue 13 Oct 2026, CT)
Owner chain rule (no long runs): crown_build = crown_wood → crown_glass → crown_arch. Each loads the previous piece's save; each handoff is checked equal (UIDs, species, flags, items, portals, realm).
Lineage: earned cloudreach_07 → arrival_prefix (PASS, 23:26–00:44, 4656 s) → the pieces below.
Runner: tools/earned_saves/stormwood_chain_runner.gd. Disclosed: 8x/480 Hz sim clock (helpers switch fights and walks to 1x). No TB_WORLD_SEED. Commits (wood/glass/arch): 2994451be8 0e6716f992 cc783d51ac.

| Piece | CT | Wall | Result |
|---|---|---|---|
| crown_wood | 10:02–10:59 | 3421 s | PASS: Still Grove rest (5 nights, ordinary beds), Capacitor Alpha cleared, 8 thunderwood + 6 vine from four authored sites |
| crown_glass | 11:02–11:26 | 1418 s | PASS: carried berries fed and 2 wood dropped via the Satchel (disclosed, to make room), Crown window waited, 6 Crown glass, 2 frames crafted at Rodline Refuge |
| crown_arch | 11:26–11:31 | 282 s | PASS: Still Grove footing, paid Crown arch placed by controller; stormwood:crown_arch_built |

Defects found and fixed on the way (r1–r6 of the single-run crown_build):
- **Product:** stations.json field_allowed lacked thunderwood_frame (3016e7e9b; coordinator accepted; HOMESTEAD §8 line added). Since stations runtime_enabled, the Rodline bench offered 26 recipes and no frame, so the act-II arch could not be built in the field.
- **Helper (disclosed):** a full 24/24 earned Satchel made the Crown glass gain 0. The fix makes room by feeding berries, then dropping the smallest gathered material through the Satchel.
- **Helper (disclosed):** hotbar re-press after a fight (a press was lost while the result settled); CraftPanel focus settle.
- **Runner:** the watchdog counts item changes and a declared Surge-window wait as progress, and names the input owner on load. The Still Grove soft-lock (old r19) did not recur on main's batched mastery drain.
rootgate (from crown_arch, 11:31–11:38, 419 s): PASS. Crown guardian cleared, engine truth learned, Rootgate released, act II complete. The earned Stormwood route is proven through act II.
Checkpoints: tests/fixtures/earned_saves/stormwood_01_arrival_prefix, _02_crown_wood, _03_crown_glass, _04_crown_arch, _05_rootgate.
Logs and receipts: r2026-10-13/. Next: dynamo/marrow on the earned lineage (they passed before only from the generated L50 rootgate_crown boundary).
