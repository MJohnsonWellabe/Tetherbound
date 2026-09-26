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
**Criteria chosen for this ledger (not spec numbers):** lead ≥ ace−2 and weakest ≥ ace−5 before each required
fight; at exit lead ≥ 33 and weakest ≥ 30. No spec states a per-fight band: PROGRESSION §3's Cloudreach row says
only "L18–21 overlap → L33", WORLD §2.4 gives exit 33 vs Veyra ace 34, and PROGRESSION §3's "deficit≤2" concerns a
replacement catch, not a fight band.

| Phase | walk m | wild credited/avail | wild XP (lead) | candy lv | ace | need L/all | before | banked XP before (lead ; weakest) | margin L/all | trainer XP | coins |
|---|---:|---:|---:|---:|---:|---:|---|---|---:|---:|---:|
| Senn | 3261 | 14/28 | 4452 | 8 | 24 | 22/19 | 24 21 21 21 21 | 255/1546 ; 973/1326 | +2/+2 | 796 | 80 |
| Maela | 2003 | 9/19 | 3534 | 8 | 25 | 23/20 | 26 25 25 25 25 | 1419/1695 ; 266/1620 | +3/+5 | 828 | 75 |
| Voss | 7919 | 15/31 | 6658 | 7 | 31 | 29/26 | 30 29 29 29 28 | 1672/1998 ; 544/1846 | +1/+2 | 1530 | 120 |
| Veyra | 1717 | 3/6 | 1530 | 4 | 34 | 32/29 | 32 30 30 30 30 | **659/2152** ; 152/1998 | **0**/+1 | 1642 | 150 |
| Exit | 1122 | 0/0 | 0 | 0 | – | 33/30 | 33 31 31 31 30 | **149/2230 ; 973/1998** | **0/0** | – | – |

The two 0 margins are thin: the lead enters Veyra 31% into L32 and leaves 149 XP (7%) past L33.

**Where the XP comes from:** about **77% (77.1%) of the lead's combat XP comes from optional wild fights**
(16,174 wild vs 4,796 required-trainer XP). The pass therefore rests on the player choosing half the wild sites.

**Disclosure of prior data changes that feed this ledger:** commit 4100f2188 (rescued ea1822b3f) raised the
post-Fly wild table minimums (windscar 22→24, high_roost 24→28, upper 26→28, summit 29→30) explicitly so that
this ledger's lead reaches the exit envelope. The 11 `_why_cadence_f07` wild sites (gated return-leg pairs) were
added by commit 69601391c for route cadence (the 885 s gap), not by 4100f2188; they are on required return legs and
contribute to the XP credited here.

## Sensitivity (controls.csv)

| Variant | Verdict | Worst lead margin | Worst weakest margin | Exit |
|---|---|---|---|---|
| engagement 0.30 | FAIL | −3 (Veyra) | −2 (Veyra) | 30 29 29 28 28 |
| engagement 0.40 | FAIL | −2 (Veyra) | −1 (Veyra) | 31 30 30 30 29 |
| engagement 0.50 (baseline) | PASS | 0 (Veyra) | 0 (exit) | 33 31 31 31 30 |
| engagement 0.60 | PASS | +1 (Veyra) | +1 (Veyra) | 34 32 32 32 31 |
| bench member lands 1 Veyra-phase kill | FAIL | −1 (exit; lead L32, 106 XP short of 33) | 0 | 32 31 31 31 30 |
| bench member lands 2 Veyra-phase kills | FAIL | −1 (exit; lead L32, 361 XP short of 33) | 0 | 32 31 31 31 30 |
| ON_ROUTE_M 8 | PASS | 0 (Veyra) | 0 (Veyra) | 33 30 30 30 30 |
| ON_ROUTE_M 12 (baseline) | PASS | 0 | 0 | 33 31 31 31 30 |
| ON_ROUTE_M 20 | PASS | 0 | 0 | 33 31 31 31 30 |
| Veyra rare_candy fed before overlook (exit only) | PASS | 0 (Veyra; exit lead unchanged 33) | +1 | 33 32 32 31 31 |

Gate fix: 4 fly-gated Windscar return pairs are passed closed on the way to Maela (credited on the grounded
return after Fly), 2 east-anchor-gated plateau pairs are passed closed on the way east (credited on the walk
to Voss), 2 restored-winds summit pairs are never credited. The pre-fix gate-blind model overstated Maela lead
(27 vs 26) and the Veyra-phase party (31 vs 30).

Supply: aerie repair needs 3 gale_fiber; first-pass route supply before it 7 (233% ≥ 150%).
Coins: required pre-finale 275 vs two-loss basket 2×136 = 272. In-kind recovery on verges before the finale: 12 small potions, 3 large, 7 revives + trainer items.

Negative controls (all fail the same shortfall check): no Voss-phase wild XP (Voss lead short 2, Veyra short 4);
no Voss trainer XP + no Veyra-phase wild XP (Veyra lead short 2); no verge candy (weakest short 2 at Voss, 4 at Veyra);
wild fraction 0.25.

Limitation: this is a data replay of the earned route, not an earned save. The pass is fragile: zero slack at the
Veyra lead band and at exit; it fails at engagement ≤0.40 or if a bench member lands a single Veyra-phase kill;
the four non-leads depend on all 27 verge-candy levels being collected.
