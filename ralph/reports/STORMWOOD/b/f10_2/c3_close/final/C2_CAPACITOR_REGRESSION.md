# F10#2 C2 regression: Capacitor Alpha with the route cue

**Measured at ce09e481**, locally, with `smoke_stormwood_b_named_c2c3.gd --seeds=24`.

| Fights | Result | Record |
|---|---|---|
| Five named fights | PASS, every starter row | `C2_other_four_ce09e481.txt`, `C2_blackwater_ce09e481.txt` |
| Capacitor Alpha | FAIL for Ripplet (ratio inf) and Galewisp (ratio 3.61) | `C2_capacitor_ce09e481_FAIL.txt` |

In both failing rows the reader pays more than the masher.

**Cause.** The 1.1 s `route_cue_seconds` added for BOSSES §7 (21b64184, landed via 47069dd1) came after the original SUMMARY_TABLE was recorded. A local run at ce09e481 with the cue removed passes Ripplet at ratio 0.43. With the cue:
- The masher staggers the body out of almost every dive during the 1.9 s wind-up (cue plus tell). The Ripplet masher takes no hits at all.
- The reader, who waits for the tell, gets hit.

**Tried and not kept:**
- `poise_max` 70: the masher gets hit again, but Ripplet still fails (ratio 1.97) and Galewisp fails (0.58).
- A reader pilot that dodges during the cue: worse. All three rows fail (0.94, inf, 4.14).

**Open decision.** The fix needs a rule for how the cue interacts with stagger. Candidates:
- The cue body cannot be broken during the cue.
- Poise damage during the cue is deferred.
- The cue counts as part of the wind-up for interrupts.
- A different BOSSES §7 cue shape.

Raised on #356.
