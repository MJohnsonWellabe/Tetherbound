# F03#1 distinct optional action: code-blind judge, earned save, set D (all six)

Set D is the current judgement for F03#1. It supersedes sets A, B and C.

**Judge input:** the 28 frames in `distinct-d/` plus the six ledger action lines (WORLD §11) and one start-state fact: in the save, the Warrens guardian had already been beaten in play. No code, data, config, docs or other reports were opened.

**Frames:**

| activity | frames | source |
|---|---|---|
| herd | 4 | set C (run 36284588023 @ 9841c075) |
| bram | 4 | set C (run 36284586383 @ 9841c075) |
| juno | 4 | set C (run 36282587113 @ 67dd6eab) |
| hall | 4 | recorded run 36289584698 @ e315d4ca |
| doss | 6 | recorded run 36293529797 @ c9b311ef: gather, Satchel before, perch before, payment line, Satchel after, perch after |
| vault | 6 | recorded run 36293531808 @ c9b311ef: den toward the lit vault, branch passage, Engage prompt, fight start, fight end, after |

| activity | matches ledger | distinct from nearest | overall |
|---|---|---|---|
| herd | PASS | PASS (nearest: doss) | PASS |
| bram | PASS (weak: forest, not "eastern fields") | PASS, narrowly (nearest: hall) | PASS (weak) |
| doss | PASS, weakly (rebuild visible; fiber 2→1 visible; payment line) | PASS (nearest: herd) | PASS (weak) |
| juno | PASS (the lead and the fight appear only as their result) | PASS (nearest: bram) | PASS (weak) |
| hall | PASS (the band5/off-road site is not established in frame) | PASS, narrowly (nearest: bram) | PASS (weak) |
| vault | PASS (glow beyond the arch, branch taken, encounter resolved) | PASS (nearest: hall) | PASS |

**Result: 6 of 6 pass. Four pass weakly.**

## Weaknesses the judge listed (none fails the criterion)

1. **The four fights share one combat HUD.** Each fight's distinct framing sits around the fight, not in it.
2. **Vault frame 01 shows an engageable wild Burrowback at the branch.** It is not the guardian: a cleared Warrens spawns no guardian. It is resident population.
3. **Doss.** Wood 1→0 does not read, because the stack simply disappears. The river shows only as the channel's bank. The rebuilt perch reads as a fenced pen. The perch mesh and material defect is V-MA-1 in the Codex queue.
4. **Juno.**
   - The lead and the patrol fight are not shown.
   - "Greet Tether Patrol" persists after the defeat. That is a known product defect, noted since set A.
5. **Bram's stakes.** A Lv6–7 team against a Lv15–18 party gives the fight no threat. That is a tuning note.
6. **Hall's site.** The frames do not establish the band5/Hall-approach location.
7. **Duplicates.** Herd frames 02 and 03 are near duplicates. The team panel shows two Mudsnouts and two Bramblebuns. That is the earned party: two caught members of each species, five total.
