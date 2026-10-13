# Earned Master loop, Aster (master_t4): BLOCKED by a design gap (routes, Tue 13 Oct 2026, CT)
Piece: tools/earned_saves/cloudreach_chain_runner.gd `06m_aster_duel` from the earned cloudreach_06_veyra_relay summit save (commit 29660cee3; aster_r1.txt).
Result: FAIL at the first leg, "Double-jump input deployed Fly". The team cannot fly after the chapter ends.

Why (code facts):
- Aster Windward's pad is `access: fly_only` (masters.json; WORLD §2.10: "The L40 Master sits on the High Perches, reached by Fly").
- fly_traversal.json mentor_loaner `ends_at_flag: cloudreach_chapter_complete`. fly_controller.eligible_creature() returns the active owned carrier if it qualifies, else the loaner, which is gone once the chapter is complete.
- The earned five (Terrapup, 3 Bramblebun, Mudsnout) has no Fly-capable carrier. So after Cloudreach a ground team cannot reach Aster (cap 40 → 50) at all, without catching a flier into its five.
- Before chapter completion the loaner flies, but the earned team is L31 there (cap 40). feast_t4 can only be fed at level 40 (breakthrough_panel.feast_matches_current_cap), so a duel won early still cannot lift the cap until L40.

Also on this loop (code): the chest needs Satchel room for ~18 stacks of supplies (prepare_chest), and cooking needs a homestead Kitchen at station tier 4 (prepare_cook). The earned homestead has no Kitchen.
Decision needed (owner/coordinator): e.g. keep the loaner for the Master perch, give the perch a grounded or lift route, or accept that a no-flier team stays at cap 40 (it still clears Stormwood, see F09-0).
