# b36 (CPU, 3 fresh code-blind judges, JUDGE_PROMPT verbatim, 3 anchor pairs + f36_0_npc:C1)

Candidate: tb/creatures-land 8c27cb42e, Mosshock retexture regraded from r1 for PR #745 CI (coat moss at hue 100 with lighter values, darker folds olive-brown, pale cream belly and throat). Base: main (the neon camo repaint).

Fit: linear slope 1.238 intercept -1.163; anchor RMSE 0.272; confirming batch True; warnings [].

| species | main mapped | candidate mapped | delta |
|---|---|---|---|
| mosshock | 4.90 | 6.01 | +1.11 |

Raw Bar A per judge (set: [A, B]): {"Er": [[6.0, 5.0], [5.6, 4.8], [5.8, 4.9]], "Fk": [[7.2, 7.2], [7.2, 7.2], [7.0, 7.0]], "Vh": [[5.8, 3.8], [5.6, 3.8], [6.3, 4.0]], "Kv": [[4.9, 6.8], [5.0, 7.0], [5.0, 6.8]]}

Judges: main's neon patches 'bury the face', 'far past don't go overboard'; the candidate is an even matte green, face and eye readable, but 'clay-like, narrow value range'. Both sides: hit PARTIAL 3/3, faint end read as a belly-up roll (PRESENT 2, PARTIAL 1). Next levers (judges and GPU P path): value range and texture on the coat, rim light, a side-slump faint with the head up.
