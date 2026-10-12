# F04#7 re-measure: Meadows named fights, C2/C3, full table on one game commit (tb/ev-systems-a)
Command, one job per starter × case: `godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd -- --seeds=24 --starter=<s> --case=<id> --json=<out>`
- Game commit: cf5137cb5, 21:0x–22:48 CT Sun 11 Oct 2026. The Galewisp jobs recorded b241114c5, whose only change from cf5137cb5 is evidence files.
- It contains the coordinator batch (Riverwatch mosshell power 20.5, 94df51854), the guardian_wall_quick face lock 0.5 (35e0a9c58) and reader fix 1032b96d3.
- Fixture as in ../F04#7/EVIDENCE.md: the retained five at each band's team.enter, flat collider, no gear. Rows are in `rows.txt`.

## Result: FAIL on one row; the chapter bar and every other row PASS
- 23 of 24 case verdicts PASS. All 7 trainer cases pass on all three starters.
- **FAIL: warrens_guardian × Ripplet**, reader/masher lead cost 0.268/0.350 (was 0.457/0.350). With the face lock, Terrapup's guardian row now passes (0.277/0.678; before 0.485/0.678).
- Chapter masher loses at least one named trainer fight, 1−Π masher win, bar ≥0.25:
  - Terrapup **0.38**: Riverwatch 0.62 (was 0.21).
  - Ripplet **0.44**: Riverwatch 0.58, Field 0.96 (was 0.21).
  - Galewisp **0.27**: Riverwatch 0.96, Elite 0.92, Warden 0.83 (was 0.23).
- C3: every case verdict passes. The worst any-matchup hit is 0.510 (Riverwatch/Warden vs Ripplet at ×1.25, reported, not gated), the same as the original F04#7 table. Tells stay 0.85–1.40 s.
- Note: the Galewisp masher loses the guardian 24/24 (win 0.00, lead-faint 1.00) while its reader pays 0.000. The guardian is a named wild and does not count in the chapter product.

## Ripplet × guardian (parked under the two-attempt rule)
- The masher kills the guardian in 13.4 s and takes 3 hits. The reader takes 40.9 s and 2 hits, spending its wind on 14 bursts and throwing 1 charged to the masher's 3.
- The two earlier reader gates both failed (../F04#7/EVIDENCE.md).
- The coordinator's re-scope is a NEW approach: a separate punish-window reader mode, validated on every F04#7 row. If it cannot clear this row, it goes to the owner as a matchup-balance question.

EV F04#7 FAIL cf5137cb5 chapter bar PASS (0.38/0.44/0.27) and 23/24 rows PASS; Ripplet x guardian 0.268/0.350 remains (parked, new reader mode next)

## Re-measure on the adopted reader, attempt 2 (904c3c537: remembered fields are no-go for every reader step)
- Run 02:49–04:57 CT Mon 12 Oct, 24 jobs. Rows are in `rows_904c3c537.txt`.
- The result is the same as above: 23 of 24 rows PASS, and the only FAIL is warrens_guardian × Ripplet (0.268/0.350).
- Chapter masher-loss: 0.38 / 0.44 / 0.27. Worst any-matchup hit 0.510; every C3 verdict passes.
- Ripplet × guardian is on the owner end-list as a matchup-balance question: see `punish_mode.md` for the punish-reader and heavy-power attempts.

EV F04#7 FAIL 904c3c537 adopted reader: chapter bar PASS (0.38/0.44/0.27), 23/24 rows PASS; Ripplet x guardian (0.268/0.350) is the owner matchup-balance item

