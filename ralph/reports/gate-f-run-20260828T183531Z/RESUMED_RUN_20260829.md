# Resumption record — 2026-08-29

Two prior sessions ran this run; the second stopped mid-S06 when the account
hit its weekly rate limit. This file records what the resuming session found
and decided before continuing S06 through S10 and X01 through X08.

## RIG-11 is closed, not just recorded

`DIAG-S02-ENCOUNTER/FINDING.md` established RIG-11 as an open finding: no
journey step-script from S03 onward ever presses `creature_recall` after its
load, so `encounter_director.gd::_engageable()` returns null on every press
and no fight — and nothing downstream of a fight — can happen in S03-S10.
That file left it open because closing it means editing the rig mid-run,
which the protocol allows only when recorded as a restart.

This session fixed it: `tools/gate_f/segments/S06.json` through `S10.json`
now press `creature_recall` immediately after the post-load world-settle
wait, and `X04.json` (the combat lab, which loads the same way from
`S04-exit`/`S06-exit`/`S09-exit`) does the same at all three of its load
points. `X01`, `X02`, `X03`, `X03C` and `X06` already did this and are
untouched. Fix commit: `3fbcca3a2d6d460d8a8239815a1c5ff7a68b2d26`.

**This is load-bearing for every segment below.** Before this fix, `party
size`, `objective_is`, `flag_set` and `combat_*` assertions downstream of a
load were statements about the rig's own missing input, not about the game.
After it, a FAIL on one of those checks is eligible to be a real finding
again — S06 onward is re-run rather than salvaged for exactly this reason.

## RIG-12, found while resuming

Separately, this session found that the killed-mid-flight S06 attempt had
seeded its world from `S05-superseded-2/saves/S05-exit.json` rather than the
kept `S05/saves/S05-exit.json` — a rig bug in `seed_save`'s `run://`
resolution, not an operator typo (see `RESTARTS.md` and the fix commit for
the mechanism). Fixed in the same commit as RIG-11.

## Candidate decision: keep the original pinned candidate

Since S05 completed, 22 commits (`81e52f89`..`971da8d2`, all ancestors of
current `origin/main@caaf45d6`) landed a redesigned first hour: Creek Hollow
habitat encounters, the opening house replaced by a care camp, Mira teaching
Basic Orb crafting instead of Tam, the opening resequenced through
tournament signup, and three creature beds collapsed to one compact camp.

**Decision: finish S06-S10 and X01-X08 against the ORIGINAL frozen
candidate, `main@26f0db4f1f2006150e3578947fc8124fcdf76bee`, unchanged.**
`RUN_METADATA.json`'s `candidate_sha` is not edited.

Reasoning:

1. **The chain is save-handoff-coupled.** S06 loads `S05-exit.json`, S07
   loads `S06-exit.json`, and so on through S10. Those save files were
   produced by a build at `26f0db4`. Loading them into a build carrying the
   redesigned opening's changed save-relevant state (different starting
   items/flags from a different opening sequence, a collapsed bed count)
   risks a load that is neither a clean continuation of this run's own
   history nor a fair test of the new opening — it would be a save from one
   product loaded into a different one, and any defect that produced would
   be unreadable as belonging to either.
2. **Internal comparability.** S01-S05's evidence, RIG-9/10/11/12's
   findings, and this run's whole cost/disk/capture-lane accounting are all
   keyed to one candidate. Splitting candidates mid-chain would mean every
   S06-S10 finding needs a caveat about which product it describes, and
   Phase B would inherit that ambiguity in every downstream conclusion
   about pacing, gating and progression from band 2 onward.
3. **What this costs, stated plainly:** S01's and S02's opening-specific
   findings (the wake beat, Grandpa's house, Tam's tools, the starter catch
   sequence) describe a now-superseded opening. **Any Phase B reader must
   not treat this run's S01-S02 evidence as current-opening evidence.** The
   redesigned opening has not been Gate-F'd by this run and needs its own
   pass. S03 onward (village ladder, tournament, bands 1-5, finale) is
   less exposed to the redesign's stated scope, but nothing after S02 has
   been re-verified against it either — this run answers "does the frozen
   `26f0db4` candidate's Meadows chapter hold up," not "does current
   `main`'s."

This is recorded here rather than only in commit prose because
`RUN_METADATA.json`'s own rule (§A.2) is that a freeze record must state a
capability or limitation explicitly rather than leave a reader to infer it
from source — the same standard applies to this mid-run decision about which
product this run's second half describes.
