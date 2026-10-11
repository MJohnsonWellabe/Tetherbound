# F19#5, Cloudreach part: earned checkpoint saves at each segment boundary

All times are US Central. Run date: 2026-10-11, 06:50–08:42 CT. Base: main 9e39d0086, branch tb/ev-cloudreach-route.

- **Commands:** `GODOT=godot tools/earned_saves/run_cloudreach_chain.sh tests/fixtures/earned_saves/cloudreach_arrival_generated <root>` (segments 01–04, commit 2c1d38f09). Segment 05 was re-run from the 04 checkpoint with `... <root> 05_stronghold` (commit 3596183f2).
- **Per piece:** `godot --headless --path . --script tools/earned_saves/cloudreach_chain_runner.gd -- --segment=<id> --from=<prev> --out=<dir>`. Clock is 1x; no `--accelerated`.
- **Protocol:** fresh process per piece. The production title is driven by controller focus: Load Game → Autosave (slot 0). The piece runs a verbatim slice of `cloudreach_live_segment.gd::_run_route()` on `f49_cloudreach_chapter.gd`, then `Game.save_game(0)`. There are no teleports and no flag, inventory, party or HP writes.
- **Completion check:** each piece is proven by its terminal flags. A script error can never pass a piece.
- **Handoff check:** each piece compares its loaded ordered UIDs, flags and inventory with the previous piece's saved after-state.

| Seg | Result | Checkpoint | Notes |
|---|---|---|---|
| 01 arrival + lower-cliffs gate | PASS | tests/fixtures/earned_saves/cloudreach_01_arrival_gate | Loaded UIDs equal the generated start's order. |
| 02 broken causeways | PASS | tests/fixtures/earned_saves/cloudreach_02_broken_causeways | Senn won; handoff matches. |
| 03 flight training | PASS | tests/fixtures/earned_saves/cloudreach_03_flight_training | Maela won; aerie rest; Fly ring trial; handoff matches. |
| 04 aviary/roost (High Roost shrine) | PASS | tests/fixtures/earned_saves/cloudreach_04_high_roost | Shrine landing, vanes, Sora, windlass, return flight to the aerie; handoff matches. |
| 05 stronghold | FAIL | none written (05_stronghold.receipt.json) | Lost Officer Voss. |
| 06 Veyra + relay | NOT RUN | none | Blocked by 05. |
| 07 Stormward handoff | NOT RUN | none | Blocked by 05. |

## Gaps

1. **05: Officer Voss is unwinnable for the party this route produces.**
   - Voss fields stormcapra L41, cloudfang L42 and skyrill L42 (`cloudreach_chapter.json` level_band 41–42).
   - The required-path route reaches him with the generated five still at L31 and full HP after the summit bivouac. The required beats (Senn, Maela) gave little XP. `redesign_level_curve.json` expects 39–42 by upper Cloudreach.
   - Live SPACER pilot result: all five fainted. Hits 69 dealt / 31 taken; damage 732 dealt / 1568 taken.
   - The progression between arrival L31 and the Voss band is not supplied by the required route or the helper. This needs a curve/route decision; no small code fix exists.
2. **Static cliff-shoulder stall (open game defect).** On the 05 first attempt, the capsule stopped dead (velocity 0, floor normal y 0.93) on the counterweight pass at (-791.8, 641.4, 3536.3), against `WindscarCounterweightPassCliffShoulders/Ridge003`. This is the same family as the witness-route C1 stalls.
   - The runner now carries the witness route's disclosed stick-sidestep recovery.
   - The 05 re-run passed that spot without needing it (`static_sidesteps: []`).
3. **Stale resource prompt on a day roll (helper defect).**
   - The generated arrival clock is 512.7 s into a 600 s day, so `Game.day` rolls about 87 s after load. `cloudreach_resource_patch.gd` then rebuilds its DailyHarvest child, and the helper's pre-walk prompt reference is freed: SCRIPT ERROR in `_arrival_gather`.
   - Without the completion check, the earlier runner would have saved a false PASS here.
   - The runner's Piece re-reads the prompt after the walk (disclosed). The shared helper is unchanged.

## Disclosures

- The start save is the generated arrival (`prior_earned_play: false`).
- The helper's camp rest snaps the day cycle to night (F47#4, helper-disclosed).
- Fly climb uses held jump (owner's Fly exception).
- Each checkpoint's PROVENANCE.json and receipt.json carry its own command, commit, start save and disclosures.
