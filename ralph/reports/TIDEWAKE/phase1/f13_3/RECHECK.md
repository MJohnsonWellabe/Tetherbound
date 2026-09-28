# F13#3 independent strict re-check: MET

A fresh read-only subagent scored the evidence in this folder against:
- ACCEPTANCE §6.1 F13 ("Six selected local chains, one per group, satisfy §5");
- WORLD's activity rule (discoverable lure, distinct action, useful reward,
  acknowledgement, saved completion, a route that works through ordinary play) and §11's
  six Tidewake rows;
- the Phase 1 function rule (STATE §1 ruling 4) and the relaxed-proof rule.

It checked the run log itself:
- 619 checks, 0 failures, exit 0;
- 12 `CHAIN ... PASS` lines: six on first completion and six after save, reset and load;
- six reload acknowledgements;
- 35 real-input swim legs;
- one POSE line.

**RESULT: MET**

| Chain | Lure | Action | Reward | Ack | Saved | Route |
|---|---|---|---|---|---|---|
| Lantern | MET | MET | MET | MET | MET | MET |
| Gull | MET | MET | MET | MET | MET | MET |
| Cradle | MET | MET | MET | MET | MET | MET |
| Garden | MET | MET | MET | MET | MET | MET |
| Deep Watch | MET (Orsen's greeting; no toast, pin after the win) | MET (real fight, then a separate chart control) | MET | MET | MET | MET (one disclosed POSE) |
| Lastlight | MET | MET | MET | MET | MET | MET |

**Lure clause:** WORLD §11 counts "physical lure/NPC knowledge" as discovery, and every
Tidewake row's lure is a requester naming a place. All six requesters are main-route dock
NPCs, reached through the ordinary Greet prompt. The lead is backed by the dialogue, the
quest-log row and the new map pins. The weak physical props (Lantern WEAK 4/4) are a
Phase 2 look item under ruling 4.

## Shortcuts to disclose on the board
1. Declared fixture start: the retained five at L43, a pickaxe, axe and knife, and the
   upstream flags.
2. The log's "DRY RUN - does not count" self-label predates the relaxed rule. The run counts
   under that rule.
3. One position write to the Deep Watch landing after the Tidecoil win.
4. Walks are harness-planned and steered by real stick input. The run is headless.
5. The run used the Tidecoil surface-mode setup that 414eff8e reverted. Main's setup is
   covered by the a524fb4d run (619/0).
6. The map frame is a fixture capture at 1280x720, not from the continuous run.
7. The two-peer proof is the older 1fa83a57 run, which itself used teleports and fixture
   materials.

## Open follow-ups (not blocking)
- Route risk: after Tidecoil, a player without a swimmer may be left in the cliff-foot
  shallows where the harness walk back stalled. It is recorded in the STATE Tidewake row.
  The F14#0 Tidecoil stand change addresses the same geometry.
- The WORLD §11 3-10 minute detour budget is not measured by this run.
- Phase 2: physical lure props, and the look of the map pins.

The re-check's two text corrections (Orsen has no HUD toast; the log's self-label) are
applied in SUMMARY.md.
