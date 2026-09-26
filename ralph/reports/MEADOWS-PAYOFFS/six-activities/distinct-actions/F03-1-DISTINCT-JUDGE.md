# F03#1 distinct optional action: code-blind judge, round 1

**Judge input:** the 24 frames in this folder (`<activity>_01..04.jpg`), from `capture_activity_lures --act` renders at 2304ea30 (render.yml), plus the WORLD §11 action lines. The judge saw no code or data.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| herd | "Watch the Meadowhart herd" up close with a companion; tracks dialogue; no fight | PASS | PASS (vs doss) | **PASS** |
| bram | "Challenge Old Bram" trainer battle in a woodland; no win shown | FAIL (win and second creature not shown) | FAIL (vs juno: same trainer-challenge template) | FAIL |
| doss | Doss asks for 1 wood and 1 fiber to fix the buckled perch; repair prompt still pending | FAIL (repair not shown) | PASS (vs herd) | FAIL |
| juno | "Challenge Tether Patrol" trainer battle at night; no win or rescue shown | FAIL (not shown) | FAIL (vs bram) | FAIL |
| hall | "Engage Alpha Galecrest", a Lv19 wild alpha; the player's team is knocked out | FAIL (a loss) | PASS (vs vault) | FAIL |
| vault | "Engage Elder Trailpup" in an underground vault; Elder downed; "Take the heartstone" | PASS | PASS (vs hall) | **PASS** |

**Result: 4 of 6 distinct; 2 of 6 pass overall.** F03#1 is **not met**.

**Our reading, separating capture gaps from game findings:**
- **bram / juno, "win not shown": a capture-selection gap.** Both `--act` receipts record the fights as won: bram twice (his two creatures), juno twice. The sheet used the mid-fight frames, not the `act-04-fight-end` ones. Next round: use the fight-end frames.
- **doss, "repair not shown": a capture gap.** `--act` stopped after Doss's explanation. The re-press fix is at 92c6aa4c, and x03-act-doss2 is re-rendering.
- **hall, "a loss": real at this save.** The input pilot's Lv12 team lost to the Lv19 alpha. It needs a capture from a save whose team can win or catch, or a judged catch attempt.
- **bram vs juno, "same template": a real finding.** Both are "Challenge <NPC>" trainer fights. WORLD §11's Juno action is "defeat the named Tether patrol", but what makes it a rescue is the escort afterwards ("Lead the Meadowhart home" to Juno, `lost_companion_reunion`), which `--act` does not yet capture. Next round: capture the escort and the reunion.
