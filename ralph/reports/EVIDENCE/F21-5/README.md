# F21#5 — code-blind judge prefers "after" on "hits feel weighty and readable" (matched frames) — CAPTURE-READY

systems-b, Mon 12 Oct 2026 (CT). Taken over from fights/ultimates.
Same commit (b782788bf) and the same fight, Captain Oreth's Mosshell vs a Terrapup (the trainer's Meadows bridge duel), policy stand,stand:
- After: `tools/capture_f04_strike_beats.gd --trainer=captain_riverwatch --policies=stand,stand`, shipped `combat.json`; finished 3:08 AM CT.
- Before: the same command with `impact.feedback` neutralised by `make_feedback_off.py`: weights, shake, rumble and critical hitstop set to 0, damage numbers off, class flashes set to the ordinary flash. The edit was in the working tree only and restored afterwards (verified); finished 4:31 AM CT.
Judge inputs: `pair/sequence-A.jpg` and `pair/sequence-B.jpg`, 2×2 sheets with the beats start, mid, strike and out-hit (3 frames after the outcome). Names are neutral; the mapping is in `private/mapping.json` (do not show it to the judge).
Disclosed:
- Each leg captured one strike sample (the tool's policy cycle), not a long sequence.
- Combat RNG differs between legs (the outcome text differs: a stagger in one, "hit your weakness" in the other).
- Not covered: the Medium-preset frame-time half (needs a real GPU; this host is llvmpipe).
