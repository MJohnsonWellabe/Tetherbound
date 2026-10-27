# b34 (CPU, 3 fresh code-blind judges, JUDGE_PROMPT verbatim, 3 anchor pairs + f36_0_npc:C1)

Candidates (tb/creatures, reverted after this verdict): Mirejaw faint end rolled ~52 deg belly-to-camera (3b01a7985); land Riverdrake faint end rolled ~72 deg belly-to-camera with head dropped (affed2ad5). Base: main's recipes.

Fit: linear slope 1.350 intercept -2.049; anchor RMSE 0.267; confirming batch True; warnings [].

| species | live mapped | candidate mapped | delta |
|---|---|---|---|
| mirejaw | 6.77 | 5.60 | -1.17 |
| riverdrake | 6.77 | 5.69 | -1.08 |

Raw Bar A per judge (set: [A, B]): {"Xw": [[7.0, 7.0], [7.0, 7.1], [6.8, 6.8]], "Vr": [[6.9, 5.9], [6.6, 5.8], [6.1, 5.3]], "Wp": [[6.6, 5.3], [6.5, 5.3], [6.2, 5.2]], "Nw": [[5.8, 6.8], [5.9, 6.6], [5.5, 6.2]], "Bi": [[7.0, 5.4], [7.1, 5.2], [6.7, 4.9]]}

Defects: all three judges read both candidate faints as a belly-up flip (PRESENT 3/3 each), and both live faints as down (Mirejaw FIXED 2, PARTIAL 1; Riverdrake FIXED 3, with a 'stretched' note).
Disposition: both candidates lose by more than 1.0; reverted (eef7659e1, 025841918). Mirejaw moves to the verdict's other route (lift the back's value); Riverdrake's live faint reads as prone on this CPU stage, so the GPU 'seated coil' frame is asked for.
