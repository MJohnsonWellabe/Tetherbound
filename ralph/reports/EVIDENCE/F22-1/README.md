# F22#1 / F47#3: band-order anti-mash sweep (tb/ev-systems-a)
Command, one process per band, 3 detached workers, 15:37–16:57 CT Sun 11 Oct 2026, Godot 4.7 headless:
`godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=12 --band=<band> --policies=MASHER,READER --json=<out>`
Commits: bands 1–3 on caadfd7cf, the other 20 on 9c7379e08. The diff between them is evidence only.
Disclosed (coordinator ruling c): 12 seeds; MASHER and READER only (no SWITCH_READER); bare gear; flat-collider fixture.
Rows: `sweep12_rows.json` (23 bands × 3 starters = 69). `lead_cost_reading.txt` is the alternative reading below.

## Result under the harness rule: all 69 rows FAIL
- The harness fails a row when masher lead-faint minus reader lead-faint is below 0.25 (`masher_lead_faint_gap_min`).
- Against ordinary wilds the masher almost never loses its lead: masher median lead-HP cost is 0.105 / 0.330 / 0.649 (min / median / max).
- Reader win is ≥0.9 in 63 of 69 rows. The exceptions are all Ripplet in Cloudreach: broken_causeways 0.67, high_roost 0.75, summit 0.67, upper 0.75; and Galewisp at 0.92 in two bands.
- There are 3 reader fixture errors, in Cloudreach high_roost (2) and summit (1).

## Spec conflict (decision held by the coordinator)
- COMBAT §7 (COMBAT.md:143) says an ordinary wild costs a masher 15–30% lead HP with ≥90% wins and "is not an early progression wall".
- A lead-faint gap of ≥0.25 would need wilds that knock out the masher's lead in a quarter of fights, which contradicts that.
- Alternative reading for wild bands: reader win ≥0.9 and reader median lead-HP cost ≤0.55× the masher's (the floor-trainer form, COMBAT.md:141). Under it, 40 of 69 rows pass:

| Chapter | Rows passing |
|---|---|
| Meadows | 14/15 |
| Tidewake | 15/18 |
| Cloudreach | 6/18 |
| Stormwood | 5/18 |

- Under that reading, the Cloudreach and Stormwood readers pay close to the masher's lead cost. This points at the reader pilot or the pattern geometry in those bands, not at power.

EV F22#1 FAIL 9c7379e08 12-seed MASHER/READER sweep, 69/69 rows fail the lead-faint gap (masher rarely loses its lead vs wilds per COMBAT §7); 40/69 pass the lead-cost reading; decision pending
EV F47#3 FAIL 9c7379e08 same sweep data as F22#1; Cloudreach/Stormwood reader ≈ masher lead cost; decision pending

## Re-measure on the adopted reader (1032b96d3), wild-band bar per the coordinator ruling (603417ace)
- Every band was re-run after the reader fix 1032b96d3: arena-edge exits stay open inward, and diver landings are remembered.
- Commits: d83f2d3b7, d1f3efc0b, eda3c0095, 5a54b97a3, 5b18ea665 and 8792cbd3a, Oct 11 20:59 to Oct 12 02:25 CT. They share that reader and the band smoke; between them only evidence files, the water smokes and the opt-in punish flag (default off) differ.
- A low-Wind hold change (ea5d65a5f) was tried and reverted (5b18ea665): it flipped no row and regressed broken_causeways.
- Rows are in `sweep_adopted_reader_rows.json`.

**60 of 69 rows PASS:**

| Chapter | Rows passing | Before (old reader) |
|---|---|---|
| Meadows | 15/15 | 14/15 |
| Tidewake | 18/18 | 15/18 |
| Cloudreach | 10/18 | 6/18 |
| Stormwood | 17/18 | 5/18 |

**FAIL rows:**
- Cloudreach high_roost (×3) and summit_final_stronghold (×3). Reader 0.13–0.47 against masher 0.19–0.56; Ripplet win 0.67.
- Cloudreach broken_causeways, Ripplet and Galewisp (0.433/0.544, 0.312/0.387).
- Stormwood dynamo, Ripplet (0.253/0.336).

**Causes** (scratchpad analysis of per-hit events):
- The reader takes CURRENT fields (current_zone) and craghorn lanes while short of Wind. That accounts for 29–55% of its damage in those bands.
- Ripplet against tempestwing (140 HP, attack 32) reaches the 240 s per-foe cap in 6–7 runs. The masher's lead faints in every one of those fights: a class-C overmatch.

EV F22#1 FAIL 5b18ea665 60/69 band rows pass on the adopted reader (Meadows 15/15, Tidewake 18/18, Cloudreach 10/18, Stormwood 17/18); fails are CURRENT-heavy Cloudreach bands plus Ripplet x tempestwing overmatch
EV F47#3 FAIL 5b18ea665 same sweep as F22#1 (60/69)

## Adopted reader, attempt 2 (904c3c537): remembered fields are no-go for every reader step
- 23 bands, 12 seeds, MASHER/READER, wild-band bar. Run 02:49–07:37 CT Mon 12 Oct. stormwood/dynamo was re-run on 5e334e393 (evidence-only diff) after a full-disk truncation.
- Rows are in `sweep_904c3c537_rows.json`.
- **67 of 69 PASS:** Meadows 15/15, Tidewake 18/18, Cloudreach 16/18, Stormwood 18/18. No row that passed on the previous reader regressed.
- The only FAILs are high_roost and summit on Ripplet.
  - Reader win is 0.67 because of 4 tempestwing timeouts each (240 s per-foe cap).
  - Their lead cost passes: 0.202/0.562 and 0.083/0.531.
  - This is a class-C overmatch, classified under the existing rules and not reclassified. The masher's lead faints in those fights too, and tempestwing (140 HP, attack 32) outclasses Ripplet (110/23).

EV F22#1 FAIL 904c3c537 67/69 band rows pass on the adopted reader; the 2 fails are Ripplet x tempestwing (class C overmatch: reader timeouts, masher lead faints)
EV F47#3 FAIL 904c3c537 same sweep as F22#1 (67/69)

