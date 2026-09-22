# Reward delivery closeout evidence

The reward/session source checkpoint is `fabba89e9`; the final save-locator discovery patch is `ec9671d4c`. This report records bounded proof for the reward-delivery and save-authority changes; it is not release or full-suite acceptance.

## Results

- Focused units on the preceding source checkpoint `b2d563671`: 219 tests, 1,315 assertions, 0 failed, with no `SCRIPT ERROR` or plain `ERROR`. The selectors covered reward delivery/RPC, authoritative split loading, ledger races, satchel escrow, world/character/save formats, legacy-slot splitting and HUD widgets. Log: `%TEMP%/tetherbound-reward-save-focused-final-clean.log`.
- Bounded reward validation on `fabba89e9`: 12 tests, 49 assertions, 0 failed. Log: `%TEMP%/tetherbound-reward-bounded-count-final.log`.
- Final targeted validation on `ec9671d4c`: 7 tests, 52 assertions, 0 failed, with no `SCRIPT ERROR` or plain `ERROR`. The new regression proves two corrupt pre-locator split files cause refusal, leave live state unchanged and retain their exact bytes. Existing backup fallback is unchanged. Log: `%TEMP%/tetherbound-authoritative-split-presence-final.log`.
- The stock Godot 4.7 `tests/smoke_playground.gd` on `b2d563671` completed with exit 0 and `smoke: OK` in `%TEMP%/tetherbound-smoke-playground-final.log`. It emitted the established dummy-renderer material-null and shutdown allocator diagnostics; no `SCRIPT ERROR` occurred.
- The final two-process `tests/smoke_net_boss_rewards_each_participant.gd` run on `fabba89e9` completed with exit 0 and `ALL CHECKS PASSED`. It proved host/client ENet join, one trainer defeat and world flag, matching durable reward journals, and each participant receiving the authored 20 coins plus 1 potion. Coordinator log: `%TEMP%/tetherbound-smoke-net-boss-rewards-final-fabba89e9.log`; run `local-3021321`.
- HUD geometry smoke passes after the measured-anchor reveal fix. The OpenGL capture is [`_sheet-hud.png`](_sheet-hud.png), 1920x1080, showing the roster and active panel with 24px measured clearance. It is synthetic geometry evidence with HUD processing frozen after setup, not a real fight or performance claim.

## Boundaries

The focused unit and ENet reward proof does not establish Steam internet relay, separate-account joining, four-account play, overlay/device behavior, export packaging, or release readiness. `server_relay=true` remains game-host forwarding, not proof of Valve SDR. The old merged-slot reload ambiguity is now refused when authority is corrupt or physically absent, but legacy peer-id receipts remain ambiguous and are not retroactively recovered. Portable character IDs can still be renamed by slot-based autosave in the unresolved cross-host case. No current full-suite result is claimed.

The implementation uses merged save version 25, world format 2 and character format 3. The bounded snapshot/reward evidence does not prove a grown-world packet ceiling or a shipped content fingerprint.

The final net peers emitted only the known `adopt_starter` “already has a creature” plain runtime error during late-arrival catch-up; no `SCRIPT ERROR` occurred. This diagnostic did not fail the coordinator checks and is retained as a runtime limitation.
