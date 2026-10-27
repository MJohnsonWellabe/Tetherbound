# b38 (CPU, 3 fresh code-blind judges, JUDGE_PROMPT verbatim, 3 anchor pairs + f36_0_npc:C1): P2-016 big wince + fight-effect ride-alongs

Candidate: tb/creatures-land f19176296 (b37's wince, plus: telegraph dust clears 2x the attacker's body radius; contact ground burst 5 puffs at alpha 0.3; impact flash radius 0.3/0.38). Base: main's animator, body, tell_style, telegraph and combat.json. 18 grunt-fight frames per arm (the main arm's later frames were lost to a full disk; both arms cut to 18).

Fit: linear slope 1.596 intercept -2.382; anchor RMSE 0.488; warnings [].

| arm | mapped |
|---|---|
| main | 5.92 |
| candidate | 5.92 (+0.00) |

Raw: {"Qv": [[6.3, 6.3], [6.4, 6.4], [6.3, 6.3]], "Ht": [[4.8, 5.0], [5.5, 5.3], [5.3, 5.3]], "Ub": [[4.3, 5.0], [4.5, 5.0], [4.5, 5.1]], "Ou": [[5.4, 5.2], [5.8, 4.8], [5.8, 5.2]]}

Defects: flinch PRESENT 2 / PARTIAL 1 on both arms; effects over the body main PRESENT 3, candidate PARTIAL 2 / PRESENT 1 (lighter dust, smaller disc). Judges could not see the head drop at 384 px tiles from the grunt camera; one noted the candidate's late frames were wider shots.

Disposition: with b37 (+0.31), two rounds under 0.5 on this approach (rule 1). Not posted GPU READY on its own. The code stays on tb/creatures-land for the coordinator's decision; next approach below in the note.
