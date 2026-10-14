# F09#0 Earned traversal demonstrates all six Stormwood regions: PASS as pieces (routes, Tue 13 Oct 2026, CT)
Owner chain rule: pieces, each loading the previous piece's save, handoffs checked equal (UIDs, species, flags, items, portals, realm).
Earned from cloudreach_07_stormward_handoff (Cloudreach chain, 8818a47b37). No generated boundary inside Stormwood. No TB_WORLD_SEED.
Disclosed: 8x/480 Hz simulation clock (helpers switch fights and walks to 1x); crown_glass made Satchel room (fed berries, dropped 2 wood).

Regions entered, from each piece's own logged positions classified with the runtime's region rule (stormwood_surge.region_at over stormwood_world.json bounds; regions.py here):

| Piece | Commit | Wall | Regions |
|---|---|---|---|
| arrival_prefix | c7bda7aa6 | 4656 s | cinder_verge > glowmoss_hollows > conductor_run |
| crown_wood | 2994451be | 3421 s | conductor_run |
| crown_glass | 0e6716f99 | 1418 s | conductor_run |
| crown_arch | cc783d51a | 282 s | conductor_run (Still Grove arch) |
| rootgate | cc783d51a | 419 s | hollow_crown |
| dynamo | 57d676d9e | 5704 s | hollow_crown > conductor_run > deepwood > dynamo |
| marrow_aftermath | 700a77bc0 | 633 s | dynamo |

All six regions are covered: cinder_verge, glowmoss_hollows, conductor_run, hollow_crown, deepwood, dynamo.
Route facts earned on the way (flags in each receipt):
- act I: arches a/b relit, Verge/Hollows/Varga rods;
- act II: Capacitor Alpha, Crown glass, paid Crown arch, Crown guardian, Rootgate;
- act III: Deepwood station, all rods, Nysa/Sera/Kestrel, core;
- Marrow's five rounds and four conduits, the Stormheart kept at five, chapter_complete.
The earned team stayed at L40 (cap 40, breakthroughs 1-3) and won 12/13 dynamo-piece fights vs L48-51 and Marrow L54-55.
Criteria F09#1-#4 (Surge phases, Arch pairs, loops/shortcuts, two peers + reload) were already met; this closes #0.
Checkpoints: tests/fixtures/earned_saves/stormwood_01..07. Logs and receipts: ralph/reports/EVIDENCE/F19-5-stormwood/r2026-10-13/.
