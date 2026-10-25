# b9 (24 Oct 2026, CPU): held shove hit sweep, second half (quadrupeds and swimmers) vs shipping

Standard prompt verbatim, three fresh code-blind judges, anchors f36_0_npc:C1, f36_0_gap, p2_094_r4 (confirming; top anchor 7.53, so the extrapolated Tanglevolt and Stormcapra scores are confirmed here). Fit linear slope 1.348, intercept -1.444, RMSE 0.63. Warning: "meets the bar only above the top anchor (7.53): stormcapra cand, tanglevolt cand; ... this batch's anchors reach 7.35 or more, so it is the confirming batch". Candidate = `--candidate-1024b` recipe.

| Species | Shipping | Candidate | Gain | Disposition |
|---|---|---|---|---|
| tanglevolt | 7.45 | **7.99** (above top anchor) | +0.54 | ON |
| stormcapra | 7.04 | **7.63** (above top anchor) | +0.59 | ON |
| solmane | 6.37 | **7.31** | +0.94 | ON (enabled) |
| ripplet | 6.73 | **7.04** | +0.31 | ON |
| tempestwing | 5.97 | 6.64 | +0.67 | OFF (below 6.7) |
| ribbonray | 5.07 | 5.97 | +0.90 | OFF (below 6.7) |
| reedwing | 6.37 | 6.37 | 0.00 | OFF |

Judge asks: naturalistic rebuilds for ribbonray, tempestwing, reedwing and Ripplet's sitter rig (four-legged otter). Raw scores in raw_scores.json, mapping in mapped.json.
