S10e attempt 2: still 5 fails, meadows_acknowledged still not set. My own
budget split was wrong -- S10e-98g (South Bridge to the gate, ~1300m, the
bulk of the original single leg's distance) and S10e-99 (gate to village
centre, ~20m) both got 15000 frames each, when the original undivided leg
had 60750 for the whole distance. S10e-98g itself fell 173.3m short with
that budget, so S10e-99 then started from far away again and repeated the
same fence-oscillation shape it was split out to avoid. The Grandpa leg
(S10e-103) was also still 5.9m short at the doubled 6000-frame budget,
still steadily closing the gap rather than stuck.

Fixed: S10e-98g budget_frames 15000 -> 54000 (most of the original total,
matching its own much longer real distance), S10e-99 kept at a smaller
10000, S10e-103 doubled again to 12000. Re-running S10e fresh from the
same S10d-exit.
