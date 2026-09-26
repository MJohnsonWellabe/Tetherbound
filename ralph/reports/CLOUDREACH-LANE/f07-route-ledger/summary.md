# F07 route resource/XP ledger — Cloudreach, retained five, no new catch

Base: origin/main 08fcc2055 (includes ea1822b3f/4100f2188 wild-table lift). Pure-data replay; no save, no scene.
Test: `tests/test_cloudreach_route_ledger.gd`. Writer: `tools/cloudreach_ledger/write_route_ledger.gd`.
Files: `phases.csv` (per required fight), `steps.csv` (per ordered walk: sites credited vs passed while gated),
`controls.csv` (negative controls, gate-blind comparison, sensitivity), `ledger.txt`.

Method: the required route is replayed in the order of `tests/smoke_cloudreach_continuous.gd::_run`
(order asserted against the harness source), each walk using the harness's `_navigate` rule over ground
polylines unlocked at that moment; Fly legs pay nothing. Every step's data prerequisites must already hold.
A wild site / verge pickup is credited only if within 12 m of the walked path AND its gate
(`encounter_tables[].requires_unlock` / pickup `requires_unlock`) is held when that walk starts; each once.
Wild engagement: floor(50%) of a phase's credited sites, one defeat per (pair) site, table MIN level,
lowest first. XP: shipped `progression.gd` (award 30+16L to the lead, 50% share to the other four;
XP_to_next 40·L^1.15). Verge candy fed to the lowest member. Trainer reward items (e.g. Veyra's rare candy) not fed.

Entry party: lead L21, four at L18 = `chapter_curve.json` band5 `team.exit` 21 and PROGRESSION §3
"L3→L21 lead; others within 3" at its floor; matches WORLD §2.4 entry "18–21 overlap". (The harness fixture's L25 is not used.)
Band per fight: lead ≥ ace−2, weakest ≥ ace−5; exit lead ≥ 33, weakest ≥ 30 (WORLD §2.4, PROGRESSION §3).

| Phase | walk m | wild credited/avail | wild XP (lead) | candy lv | ace | need L/all | before | margin L/all | trainer XP | coins |
|---|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| Senn | 3261 | 14/28 | 4452 | 8 | 24 | 22/19 | 24 21 21 21 21 | +2/+2 | 796 | 80 |
| Maela | 2003 | 9/19 | 3534 | 8 | 25 | 23/20 | 26 25 25 25 25 | +3/+5 | 828 | 75 |
| Voss | 7919 | 15/31 | 6658 | 7 | 31 | 29/26 | 30 29 29 29 28 | +1/+2 | 1530 | 120 |
| Veyra | 1717 | 3/6 | 1530 | 4 | 34 | 32/29 | 32 30 30 30 30 | **0**/+1 | 1642 | 150 |
| Exit walk | 1122 | 0/0 | 0 | 0 | – | 33/30 | exit 33 31 31 31 30 | **0/0** | – | – |

Gate fix: 4 fly-gated Windscar return pairs are passed closed on the way to Maela (credited on the grounded
return after Fly), 2 east-anchor-gated plateau pairs are passed closed on the way east (credited on the walk
to Voss), 2 restored-winds summit pairs are never credited. The pre-fix gate-blind model overstated Maela lead
(27 vs 26) and the Veyra-phase party (31 vs 30).

Supply: aerie repair needs 3 gale_fiber; first-pass route supply before it 7 (233% ≥ 150%).
Coins: required pre-finale 275 vs two-loss basket 2×136 = 272. In-kind recovery on verges before the finale: 12 small potions, 3 large, 7 revives + trainer items.

Negative controls (all fail the same shortfall check): no Voss-phase wild XP (Voss lead short 2, Veyra short 4);
no Voss trainer XP + no Veyra-phase wild XP (Veyra lead short 2); no verge candy (weakest short 2 at Voss, 4 at Veyra);
wild fraction 0.25. Sensitivity: fraction 0.40 fails at Veyra (lead short 2).

Limitation: this is a data replay of the earned route, not an earned save; the ledger passes with zero slack
at the Veyra lead band and at exit, and the four non-leads depend on all 27 verge-candy levels being collected.
