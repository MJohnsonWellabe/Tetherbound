# F19#5 Meadows fresh opening → camp_tournament → bridge → warrens (routes-west)

All pieces are hosted (live session; Session.host falls back from a taken udp/27015). The `TB_HOST_BUDGET_SCALE=3` slow-host scale on the opening navigator's consecutive-deferral cap is disclosed (pre-approved).

| Piece | Result | Source |
|---|---|---|
| opening_team (fresh) | **PASS**, 5515 s | `1f78dc45` |
| camp_tournament | **PASS**, 4349 s | `1f78dc45` |
| bridge | **PASS**, 4423 s. South Bridge guardian 2/2 wins, 35 hits; key rewarded then spent; crossed (depth -11.6 → +9.4); same five; flags `defeated_south_bridge_grunt`, `south_bridge_open` | `1f78dc45`, from the camp_tournament out-save |
| warrens | **NOT PROVEN.** Stopped at the owner wind-down (6:00 PM CT, Oct 12) while still running: station bypass, then 7 quarry rootstone pickups (14 carried); no new receipt after about 5:38 PM | `1f78dc45`, from the bridge out-save |

**camp_tournament beats**
- Rounds: Mira won (26 landed hits), then Tam (42), then a camp recovery (Bud revived, creature-bed night), then Oskar won the final (65).
- After each round, the beaten trainer's dialogue was read (`tournament_quarter/semi/final_beaten`).
- Flags: `tournament_won`, `recipe_saddle`.

## Root causes fixed on the way
1. **Grandpa (helper).** `_find_interactable` took the first "grandpa/talk" prompt in tree order. After the coordinator merge that was a "talk" prompt about 4 km away. It now takes the nearest match (`7cc95e9a`).
2. **Input latency (GAME).** `tether_command_input._unhandled_input` ran `OWNER.current()` for every input event, each stick axis included. That cost about 0.5 ms per event and produced a 14 ms input flush per frame during wild training.
   - Measured by elimination in a live run: 550 µs per event with it, 39 µs without.
   - Fix (`df9ec22e`): match the event first. `home_key._input` now skips non-press events.
3. **Camp to Halda (helper).** The built camp blocks the direct chord from the westernmost bed. The walk now follows the authored Practice Meadow and lawn roads (`73cffa4d`). An isolated probe with no camp arrived in 1400 frames.
4. **Halda "no semi offer" (helper, not a game bug).** At the failure: input owner `DialoguePanel`, arbiter disabled, the win recorded, nothing pending, Halda's own prompt actionable. The beaten trainer's lines open a frame after the win. The helper now reads them through (`1f78dc45`).

**Open**
- The bridge helper printed no receipt before the guardian, so the fail-fast watchdog (45 min without a receipt) aborted bridge once. Waypoint receipts were added in `a8eba879`.
- The `1f78dc45` bridge run predates them, so it ran with a disclosed 90-min no-receipt limit. Its walks and fights are frame- and timeout-bounded.
- A save from one commit cannot feed a piece on another (F49 lineage); the cross-cut manifest requires stderr free of `ERROR:`, and every hosted run logs a benign ENet bind error.
