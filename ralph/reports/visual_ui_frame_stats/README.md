# D2 UI survey — measured frame stats, per round

`tools/frame_stats.py` output for `shots/ui/*.png`, one file per blind round.

Kept here because `shots/` is gitignored: the frames themselves are rebuildable
by re-running the survey, but the NUMBERS are the only durable half of
`ralph/conventions.md`'s convergence rule ("stop after two consecutive rounds
that name no new defect AND move no measured axis"). A firing with no previous
round's numbers cannot apply the second half of that test at all, and would
have to treat a flat round as if it were the first.

Regenerate with:

    python3 tools/frame_stats.py shots/ui/*.png > ralph/reports/visual_ui_frame_stats/roundN.txt

Round 2 -> round 3 moved a measured axis on 17 of 24 frames. The large chroma
drops on the menu and station-panel frames are not a palette change: those
screens were previously captured with no world scene loaded (a flat navy
backdrop, measuring as 100% blue), and are now shot over the real world.
