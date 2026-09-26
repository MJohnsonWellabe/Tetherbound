# F07 route resource/XP ledger — Cloudreach, retained five, no new catch

Base: origin/main 81b8c59df (includes ea1822b3f/4100f2188 wild-table lift); F07#4 tune on `ralph/cloudreach-f07-ledger-margin`. Pure-data replay; no save, no scene.
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
XP_to_next 40·L^1.15). Verge candy fed to the lowest member. Trainer reward items (e.g. Veyra's rare candy) not fed; a trainer tier's flat `xp_bonus` is paid whole to all five after the fight's defeat XP.

Entry party: lead L21, four at L18 = `chapter_curve.json` band5 `team.exit` 21 and PROGRESSION §3
"L3→L21 lead; others within 3" at its floor; matches WORLD §2.4 entry "18–21 overlap". (The harness fixture's L25 is not used.)
**Criteria chosen for this ledger (not spec numbers):** lead ≥ ace−2 and weakest ≥ ace−5 before Senn, Maela
and Voss; **before Captain Veyra (the finale) and at exit a positive margin of ≥ +1 level for both** (F07#4,
`LATE_MARGIN`): Veyra lead ≥ 33 / weakest ≥ 30, exit lead ≥ 34 / weakest ≥ 31. No spec states a per-fight band:
PROGRESSION §3's Cloudreach row says only "L18–21 overlap → L33", WORLD §2.4 gives exit 33 vs Veyra ace 34, and
PROGRESSION §3's "deficit≤2" concerns a replacement catch, not a fight band.

## F07#4 tune: before → after (coordinator-authorised declared-number tune)

| File | Key | Before | After | Reason |
|---|---|---:|---:|---|
| `data/config/cloudreach_encounters.json` | `reward_tiers.elite.xp_bonus` (Officer Voss, required) | 0 (absent) | **1600** | Lead met Veyra's band with 0 slack (L32, 659/2152). PROGRESSION §7 "tune existing awards so the ordinary route can support its intended encounters"; §2 "authored trainer/quest XP bonuses remain in their source rows". A guaranteed required-fight payout, not more optional wild XP. |
| `data/config/cloudreach_encounters.json` | `reward_tiers.captain.xp_bonus` (Captain Veyra, required) | 0 (absent) | **600** | Exit was L33/L30 on the line (149/2230 past L33). Carries the retained five to L34/L31 at the overlook. |

Nothing else changed: coins (80/75/120/150), reward items, trainer levels, wild tables, verge candy, the XP curve
and `progression.json` are untouched, so the coin solvency check below is unchanged (275 vs 272). `xp_bonus` is the
existing SC15 reward key (`trainer_npc.gd::reward_xp_bonus`): solo `encounter_director.gd::_pay_trainer_reward` gives it
whole to every living party member; in co-op `encounter_rewards.gd` issues one per-participant XP receipt and each peer
applies it to its own party (no split, no repeat). Both tiers map to exactly one trainer (elite = Voss, captain =
Veyra); `ace` (Tavi and the Tavi rematch) is untouched. For scale: Meadows' authored `xp_bonus` rows go to 400 at
~L20 (≈0.3 level); 1600 at L31 is ≈0.8 level and 600 at L34 ≈0.26 level.

## Margins at 50% engagement (baseline)

| Phase | walk m | wild credited/avail | wild XP (lead) | candy lv | ace | need L/all | before | banked XP before (lead ; weakest) | margin L/all (before → after tune) | trainer XP | xp_bonus each | coins |
|---|---:|---:|---:|---:|---:|---:|---|---|---|---:|---:|---:|
| Senn | 3261 | 14/28 | 4452 | 8 | 24 | 22/19 | 24 21 21 21 21 | 255/1546 ; 973/1326 | +2/+2 → +2/+2 | 796 | 0 | 80 |
| Maela | 2003 | 9/19 | 3534 | 8 | 25 | 23/20 | 26 25 25 25 25 | 1419/1695 ; 266/1620 | +3/+5 → +3/+5 | 828 | 0 | 75 |
| Voss | 7919 | 15/31 | 6658 | 7 | 31 | 29/26 | 30 29 29 29 28 | 1672/1998 ; 544/1846 | +1/+2 → +1/+2 | 1530 | **1600** | 120 |
| Veyra | 1717 | 3/6 | 1530 | 4 | 34 | 32/29 (+1) | 33 31 31 31 30 | 107/2230 ; 1828/1998 | 0/+1 → **+1/+1** | 1642 | **600** | 150 |
| Exit | 1122 | 0/0 | 0 | 0 | – | 33/30 (+1) | 34 32 32 32 31 | 119/2308 ; 1251/2075 | 0/0 → **+1/+1** | – | – | – |

The +1 margins are real but thin in XP: the lead enters Veyra 107 XP past L33 and leaves 119 XP past L34.

**Where the XP comes from:** optional wild fights now supply **69.8%** of the lead's XP (16,174 wild vs 4,796
required-trainer defeat XP + 2,200 required-trainer `xp_bonus`), down from 77.1%. Still wild-dependent.

**Disclosure of prior data changes that feed this ledger:** commit 4100f2188 (rescued ea1822b3f) raised the
post-Fly wild table minimums (windscar 22→24, high_roost 24→28, upper 26→28, summit 29→30) explicitly so that
this ledger's lead reaches the exit envelope. The 11 `_why_cadence_f07` wild sites (gated return-leg pairs) were
added by commit 69601391c for route cadence (the 885 s gap), not by 4100f2188; they are on required return legs and
contribute to the XP credited here.

## Sensitivity (controls.csv), after the tune; verdict uses the +1 finale/exit criterion

| Variant | Verdict | Veyra margin L/W | Exit margin L/W | Exit levels | Before tune (old verdict, ≥0 criterion) |
|---|---|---|---|---|---|
| engagement 0.30 | FAIL | −2/−1 | −2/−1 | 31 30 30 29 29 (also Voss lead −1) | FAIL (−3/−2 at Veyra) |
| engagement 0.40 | FAIL | −1/0 | −1/0 | 32 31 31 31 30 | FAIL (−2/−1 at Veyra) |
| engagement 0.50 (baseline) | **PASS** | **+1/+1** | **+1/+1** | 34 32 32 32 31 | PASS at 0/0 |
| engagement 0.60 | PASS | +2/+2 | +2/+2 | 35 33 33 33 32 | PASS (+1/+1) |
| bench lands 1 Veyra-phase kill | FAIL | 0/+2 | 0/+1 | 33 32 32 32 31 (lead 136 XP short of L33 before Veyra) | FAIL (exit −1) |
| bench lands 2 Veyra-phase kills | FAIL | 0/+2 | 0/+1 | 33 32 32 32 31 | FAIL (exit −1) |
| ON_ROUTE_M 8 | PASS | +1/+1 | +1/+1 | 34 32 31 31 31 | PASS at 0 |
| ON_ROUTE_M 20 | PASS | +1/+1 | +1/+1 | 34 32 32 32 31 | PASS at 0 |
| Veyra rare_candy fed before overlook | PASS | +1/+1 | +1/+2 | 34 33 33 32 32 | PASS at 0 |

Under the old ≥0 criterion the bench-kill rows now meet the bands (0 at Veyra and exit) where they previously
failed the exit by one level; they fail only the new +1 margin. 0.40 engagement still misses Veyra by one level.

Gate fix: 4 fly-gated Windscar return pairs are passed closed on the way to Maela (credited on the grounded
return after Fly), 2 east-anchor-gated plateau pairs are passed closed on the way east (credited on the walk
to Voss), 2 restored-winds summit pairs are never credited. The pre-fix gate-blind model overstated Maela lead
(27 vs 26) and the Veyra-phase party (31 vs 30).

Supply: aerie repair needs 3 gale_fiber; first-pass route supply before it 7 (233% ≥ 150%).
Coins: required pre-finale 275 vs two-loss basket 2×136 = 272. In-kind recovery on verges before the finale: 12 small potions, 3 large, 7 revives + trainer items.

Negative controls (all fail the same shortfall check, +1 margin at Veyra/exit): no Voss-phase wild XP (Voss lead
short 2, Veyra short 4); no Voss trainer XP incl. its `xp_bonus` + no Veyra-phase wild XP (Veyra lead short 3);
no verge candy (weakest short 2 at Voss, 4 at Veyra); wild fraction 0.25.

Limitation: this is a data replay of the earned route, not an earned save. After the tune the finale and exit hold
+1 level at 50% engagement, but with ~110 XP of slack; the +1 is lost at engagement ≤0.40 or if a bench member lands
a Veyra-phase kill (the bands themselves still hold in the bench-kill rows); the four non-leads still depend on all 27
verge-candy levels being collected.
