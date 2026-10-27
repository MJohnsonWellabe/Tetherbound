# b37 (CPU, 3 fresh code-blind judges, JUDGE_PROMPT verbatim, 3 anchor pairs + f36_0_npc:C1): P2-016 G5 bigger wince

Candidate: tb/creatures-land f2afad52d (hit recoil: head drop ~1/3 of body height about the hindquarters, 0.08 s squash 0.86/1.08 on contact, shove 0.2 m per metre of body; hold timing kept; art node only). Base: main 1d5faebac's creature_animator.gd and creature_body.gd.
Capture: capture_named_fight.gd --trainer=south_bridge_grunt --frames=24 --interval=0.15 --attack, both arms; 24 frames cropped on the struck wild creature (Mudsnout boar). Fights drift between runs, so frames are not matched one to one.

Fit: linear slope 1.329 intercept -1.228; anchor RMSE 0.596; warnings [].

| arm | mapped |
|---|---|
| main | 5.81 |
| candidate | 6.12 (+0.31) |

Raw Bar A per judge (set: [A, B]): {"Pb": [[4.5, 5.0], [4.6, 5.3], [4.6, 5.2]], "Dw": [[5.4, 5.7], [5.0, 5.1], [5.5, 5.8]], "Xs": [[5.3, 5.5], [5.0, 5.4], [6.6, 5.3]], "Mh": [[6.8, 6.9], [6.8, 6.8], [6.6, 6.6]]}

Defect "hurt reaction keeps the idle or attack silhouette": main PRESENT 2 / PARTIAL 1; candidate PARTIAL 3/3. Judges saw the candidate 'lowered or pulled back after an impact' / 'head lowering or body pitching at the moment of impact' in a few frames; most frames still idle. Remaining blockers they name: dust puffs and the contact disc washing over the body at impact; the boar's facing turns reading as repositioning.
