# Honesty note — this is conditional, isolated evidence

This run directory drives S10c, S10d and S10e (Gate F's post-win "world
healing" walk-back — Old Mill Crossing, Tether Relay, Burrow Warrens, South
Bridge, and home to the village/Grandpa's house) **in isolation**, seeded
from a hand-authored `S10b-exit.json` rather than one produced by a real
S10a/S10b run.

`ralph/GATE-F-FOUNDATION` and `ralph/GATE-F-LEG-S10AB` did not exist at the
time this lane ran (checked repeatedly by `git fetch origin` across this
session). Per this lane's own instructions, that is a stated assumption, not
a blocker: the seed is built by `tools/gate_f/build_s10b_synthetic_seed.gd`
using the real game arithmetic (`creature_species.gd::spawn` +
`creature_instance.gd::set_level`, the same D30 curve a real playthrough
uses) for a party of 5 at levels 19–22, full HP, with every main-chain
progression flag through `settle_the_roster` set (`defeated_warden`,
`legendary_freed`, `legendary_joined`, `legendary_settled`, and the 26 flags
before them — see the script for the exact list), positioned at the
approach-drain start near the Hall exit (8.0, 7508.0). `meadows_acknowledged`
is deliberately NOT set — that is exactly what S10c/S10d/S10e are supposed to
set along the walk.

**Every finding in this run directory's notes must be read as**: "S10c/d/e,
given a clean entry at this state, does X" — never "the chapter does X". In
particular this run says nothing about whether a real player's S09→S10a→S10b
chain actually produces a save shaped like this one, whether the roster
ceremony or the Warden fight themselves work, or about pacing/difficulty
before this seed's entry point.

See `ralph/reports/handover-GATE-F-LEG-S10CDE-<date>.md` for the full report.
