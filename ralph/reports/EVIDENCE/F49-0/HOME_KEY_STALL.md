# F49#0 homecoming piece: Home Key arrival never finishes (routes, Tue 13 Oct 2026, CT): BLOCKER for Systems
Piece: `stormwood_chain_runner.gd --segment=homecoming` (Home Key → hang the Stormwood relic → Grandpa → credits). Input: stormwood_09_marrow_aftermath.

Runs:
- r3 (acb198c59, old save): the Home Key reached home within 299 frames. It then failed only at the relic hang: no relic, because of the Marrow hand-off defect, fixed in 4187155b0.
- r4 and r6 (new save, relic and fifth key held): stall after arrival.
- A/B (current code on the OLD save, hco): **the same stall.** So the trigger is not the save content.
- Product diff acb198c59..HEAD: only the Marrow hand-off (session.gd/stormwood) and one stations.json line. Neither touches arrival.

Diagnostics (f49_portal_travel `HOME WAIT`, read-only):
- PortalArrival: seated=true, pose_saved=true, journal_started=true. saver_busy=false.
- `foundation_grounded_arrival` never reports saved; the helper waits for `home_key_finish` (result none).
- The character's single `creature_training:<ns>:<char>` row reads `action=combat_mastery status=accepted pending=false local_has_receipt=true`, not `portal_arrival`.
- This lineage retains 1,040 combat_mastery and 357 research_event foundation duties. One research_event stays "held: journaled; awaiting publish".

Most likely: a race on the per-character training row. The arrival journals `portal_arrival` (journal_started), then the retained-backlog scan commits combat_mastery into the same row before the arrival is accepted.
`foundation_grounded_arrival` then finds `row.action != portal_arrival`. Its re-commit cannot place the arrival again, so the Home Key never completes. r3 won the race by timing.
Meadows runs at ~1 fps on this host (2 s process frames), which widens the window.

Ask (Systems): never let the retained-duty scan take the character's training row while a portal arrival (or any foreground owner action) is journaled and unsaved. Or let `foundation_grounded_arrival` recover its own journaled arrival.
Logs: homecoming_hc.r3/r4/r6/hco.txt here.
