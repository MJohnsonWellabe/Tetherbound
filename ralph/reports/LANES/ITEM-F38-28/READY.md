STATUS: parked
BRANCH: tb/item-f38-28  HEAD: (this commit; see git log)

**Row:** F38#28 Warden arena boundary (P2-064). Live 6.09 (board). Lane LANE-SW.

**Result:** no arm beat base on CPU; nothing turned ON. Stopped after two consecutive rounds with no gain (stop rule).

| Round | Arm | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Dir |
|---|---|---|---|---|---|---|
| r1 | together: `combat.json arena.boundary_per_trainer_candidate` (alpha 0.12, h 0.45) + `stronghold.json p2_064_r2_candidate` (six arena torches 12 -> 7.5, att 1.8, #ffc68f) | 6.82 | 6.36 | -0.46 (3/3 worse) | 6.0 6.0 5.9 / 5.6 5.6 5.5 | `ralph/reports/LANES/LANE-SW/qj/F38-28-fb337d752d81-11071807/` |
| r2 | ring only, softer than the committed arm (merge patch: warden_aldis alpha 0.05, h 0.3); torches unchanged | 6.71 | 6.50 | -0.21 (2/3 worse) | 5.2 6.0 6.3 / 5.6 5.6 5.8 | `ralph/reports/LANES/LANE-SW/qj/F38-28-8f2e44a31d79-11071939/` |

CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors. r1 anchor RMSE 0.753 (at the 0.75 flag), r2 0.63.

**Flags turned ON:** none. **Tests flipped:** none. **Files touched:** only this READY.md and the two round dirs (no config change).

**Flags left OFF and why:**
- `data/config/stronghold.json p2_064_r2_candidate`: dimmer, cooler arena torches. All three judges in r1 said the creatures' white rim halo then reads "pasted on" against the darker hall; base's warm torch grade "integrates" the creatures better. The torch dimming is the main loss in r1 (r2 isolates the ring at -0.21 of the -0.46).
- `data/config/combat.json arena.boundary_per_trainer_candidate` (committed values 0.12/0.45, unchanged): judged together (r1, worse); a softer version of the same arm alone (r2) was also worse. Judges split: removing the cyan arc FIXES the recorded rails defect (2/3 call it FIXED) but "the boundary no longer reads at all", while base's thin curved arc "reads as an authored ring".

**Recorded defect:** the thick straight rails are already gone on base (conduits_stop_at_arena_wall, landed earlier): base defect calls are PARTIAL/FIXED; the remaining teal is a thin wall-foot conduit line at the left doorway and the thin ring arc.

**Judges' remaining asks (both rounds):**
- The hall is one murky mid-low orange-brown value: add a cool fill/key on the floor to give a value range (not dimmer torches).
- Creatures' white rim halo looks over-bright (stronger once the room is dimmer).
- Replace the emissive boundary line with an in-world edge (stone curb, rune inlays, torch posts along the ring).
- HUD covers about a third of the frame (UI lanes own it).

**Next idea (needs a fresh approach, not this arm a third time):** a grounded stone-curb ring at the Warden arena radius built from the installed Hall stone kit (new geometry, stronghold.gd, flag OFF), plus a cool floor fill that keeps the torches at energy 12. Expected gain uncertain; parked until there is a new idea per the two-failure rule.
