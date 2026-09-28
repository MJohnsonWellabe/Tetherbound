# F10#2 C3 final code-blind judge (captures at ce09e481)

Judge: a subagent that could read only `final/judge_packet/*` and `final/frames/<letter>/`. It read no code, logs or other files.

**Verdict: all six fights C3 PASS.** Each fight passed all four questions: (a) tell visible, (b) marking matches the landing, (c) framing readable at actual creature scale, (d) a real hit or avoidance.

| Letter | Opponent (as judged) | (a) | (b) | (c) | (d) | C3 |
|---|---|---|---|---|---|---|
| P | Voltarach | PASS | PASS | PASS | PASS | PASS |
| Q | Voltarach | PASS | PASS | PASS (note) | PASS | PASS |
| R | Mosshock | PASS | PASS | PASS | PASS | PASS |
| S | Voltarach (Conductor Run) | PASS | PASS | PASS (note) | PASS | PASS |
| T | Staticub | PASS | PASS | PASS | PASS | PASS |
| U | Tanglevolt | PASS | PASS (note) | PASS (note) | PASS | PASS |

Letter key (kept outside the packet while judging): P hollows_alpha, Q glass_field_alpha, R blackwater_elder, S capacitor_alpha, T crown_guardian, U old_rodfolk_hall_guardian.

## Remaining look defects (non-blocking)

1. **Danger area under the left HUD.** The far end of a lane or cone runs under the TEAM list and pilot card (P tell2-c-late, R tell1-c-late, T tell1-c-late and T tell4-c-late).
2. **Near-edge dodges look like "in it and it missed".** Sparkit's body overlaps the lane edge while its feet are outside (U tell2-d-strike, P tell2-c-late, Q tell2-d-strike).
3. **Impact frames.** At impact the opponent's head ends up under the action panel (U tell3-e-impact, U i15). Sparkit is nearly hidden behind the spider's legs and the burst (S tell1-e-impact).

## Earlier rounds

- **A–F, captures at 518104f9.** Five fights passed. B (Blackwater Elder) failed two ways: the pilot was hidden inside or behind the frog, and the marking did not match the landing.
- **r2 (G, H).** Camera fixed (b8b14380). The marking was still wrong, because the strike tracked the pilot through the whole tell.
- **r3 (J, K).** Heading now locks halfway (45927814). The fan was buried by the sloping pool edge.
- **r4 (M, N).** The fan is now seated on the terrain (85ba1c57). Both fights passed.
- **final (P–U).** All six passed on the merged head.
