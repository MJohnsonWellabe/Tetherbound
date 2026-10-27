# r1 (24 Oct 2026, CPU): F36#1 whole-roster pose verdict, batch 1 of 7 (land head c74eb3908, shipping state)

Shipping-state tiles, identical on both sides: row 1 standing, hit react, faint end; row 2 the roles each species uses in play (swim: water roster and swim mounts; fly-grip: Fly carriers; ride: rideable). Standard prompt verbatim, three fresh code-blind judges, anchors f36_0_gap:C4, f36_0_npc:C1, p2_094_r4 (confirming). Fit linear slope 1.162, intercept -0.187, RMSE 0.67. One judge ran a single Bash command on a set image inside the judge folder (size print, crops deleted unviewed); no other file opened.
Pass rule: no judge marks an applicable pose PRESENT, and mapped >= 6.7 (CPU-provisional).

| Species | Mapped | Hit | Faint | Swim | Fly-grip | Ride | Verdict |
|---|---|---|---|---|---|---|---|
| stormursa | 8.07 | Pa/F/Pa | Pa/Pa/Pa | | | | pass (faint half-roll muddy) |
| trailpup | 7.95 | Pa x3 | F x3 | | | | pass |
| mudsnout | 7.76 | Pa x3 | F x3 | | | | pass |
| meadowhart | 7.64 | Pa x3 | Pa/F/F | | | Pa x3 | pass (antler tips clip in faint; seat at the withers) |
| bramblebun | 7.76 | Pr/Pa/Pa | F x3 | | | | FAIL: hit reads as a leap |
| burrowback | 7.17 | Pr/Pa/Pr | Pr/F/Pa | | | Pa/Pr/F | FAIL: lunge hit, belly-to-camera faint, rider high |
| terrapup | 7.02 | Pr/Pa/Pr | Pa/Pa/Pr | | | Pa/Pr/Pa | FAIL: lunge hit, crouched faint, rider high |
| tuskroot | 6.90 | Pa x3 | Pr x3 | | | Pa/Pr/Pa | FAIL: belly-up faint |
| ripplet | 6.71 | Pa x3 | F x3 | Pr x3 | | Pa/Pa/F | FAIL: swim stands upright in the water |
| galewisp | 6.42 | Pa/F/Pa | F x3 | | Pa x3 | | FAIL: score (stylised model), fly-grip seated curl |

Judges' asks: a recoil hit (head snapped away, weight back, feet planted) instead of rear-ups and lunges; side collapses for stocky bodies (no belly-up flips or crouches); seat lower on plated backs; a level, low, paddling swim; an extended flight pose for fly-grip.
