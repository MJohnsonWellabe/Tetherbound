# Card T3 "Tidewake ending and continuation": tb/tidewake-full 95aa8357

**Result:** all 8/8 steps exit 0 at one checkout with 0 dirty tracked files (`SHA.txt`,
`results.tsv`, one log per step). Command: `tests/card_t3_tidewake_ending.sh`.

## The integrated two-peer run (`card_t3_two_peer.log`, `proof/card_t3_two_peer/PROOF.md`)
The run is `tools/net/proof_scenarios/card_t3_tidewake_ending.json`: one two-peer run, 73
steps, ALL CHECKS PASSED. It goes through these stages in order.

1. **Shared dock exchange, settled once.**
   - The guest pays for the Reedhaven repair through the real prompt (6 reed + 4
     driftwood, debited and saved at the press).
   - The host does the free Deep Watch chart action.
   - Stale re-presses of the finished repair by either peer charge nothing.
   - Final state: the guest is charged exactly once and the host never.
2. **Guardian.** The host, at a full five, frees the Guardian at the chamber control. It asks
   at the real invite prompt and lets Rill go through the **real release menu** (controller
   presses). The guest, with room, accepts its own Guardian. This resolution is what sets
   `water_currents_restored`.
3. **Crossing home** by both peers.
4. **Grandpa names each character's current team.** The host hears Acorn, Pip, Abyssal
   Guardian, Shelby and Volt, never Rill (`regional_homecoming_5`). The guest hears
   Kestrel, Bramble and Abyssal Guardian (`regional_homecoming_3`).
5. **Credits once each.** Each peer watches its own roll and presses Continue once. It is
   acknowledged once, with the receipt in memory and on disk, and no reopen.
6. **Disk reload.** Save, empty memory, reload. The world is completed and safe: currents
   restored, homecoming and credits seen, credits not pending, local requests offered,
   **`sequel_or_chapter_prompt: false`**, and no tracked chapter objective.
   - Keys after reload: host `realm_key_cloudreach`, `realm_key_water`; guest
     `realm_key_water`. There is **no fifth key**.
   - Pressing Grandpa again gives the repeat greeting and **no second roll**.
   - The saved characters hold their own team, Guardian, homecoming and credits receipts.
     The world save holds the restored currents and no personal receipts.

## The rest of the suite (all exit 0 at 95aa8357)
- Dock paid-debit crash/retry, all three settle once: `f15_dock_crash_after_send`,
  `f15_dock_crash_after_delta`, `f15_dock_commit_delta_lost`.
- `f15_homecoming_real_save_reload`: host and guest title-continue from real saves, and the
  ending survives.
- `return_cadence`: the measured physical return, **A7**. `test_tidewake_return_cadence.gd`
  is 5/5; the whole live return has `over_a7: []`, 114 min without the arches and 100 min
  with them; this is the F15#2 head.
- `ending_units`: `test_homecoming_ending_invariants.gd` and `test_regional_homecoming.gd`,
  23 tests, 0 failed.
- `credits_reload_smoke`: 40 checks, 0 failures.

## Shortcuts disclosed
These are carried over from the three source proofs.
- Story flags stand in for earlier play: `defeated_warden`, the Water gate/key, the swim
  lesson, Tidecoil resolved, and `old_champion_met` for one Local Request.
- Companions are granted by name through `party_grant`.
- `guardian_fixture` commits the Veilfall prerequisites and Nerissa's defeat through the
  ledger. It stands in for playing the Veilfall and the fight, which belong to the
  fights lane's F14#1.
- The dock materials are granted.
- The home crossing uses `Game.enter_realm`, the production crossing, **not a physical walk
  of the return**. The return is measured at data level by the cadence test (A7), not
  walked two-peer.
- `grandpa_homecoming` teleports each player beside Grandpa before the real prompt.
- The dock actions are pressed standing 1.4 m from the prompt, after a teleport.
- Loopback ENet on one machine, headless.
- The integrated run starts from the Water scene fixture, not an earned end-of-Tidewake save.
