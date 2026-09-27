# B4: Venn's fight pad on the Veilfall climb

Terrain `graded_pads` `veilfall_venn_fight_pad` (16 m flat, 12 m feather) at (329.8, 138.7, 3880.4); Venn's offset moved 23 m onto it (5e11bc56); the spine_01 roadside pair moved clear of his ring (5c1897d6). Approved by the coordinator 11:41.

- Baked probe (`tests/probe_tidewake_venn_pad.gd`): arena deviation 0.00 m, max rise 0.03 m within 16 m. Old stand: 69 m rise.
- Water/Tidewake/Veilfall tests: 443 ran, 1 failed (the ring clearance, fixed in 5c1897d6; that test and the other affected ones then passed, 15/15). The full set was not rerun.
- In-world fights on the pad by input (`tests/smoke_tidewake_named_inworld_c2.gd`, seed 0): READER won in 275 s (lead lost 0.43, max hit 12%); MASHER wiped in 151 s (max hit 24%). Consistent with the earlier C2 table. Shortcuts: granted L43 party, player placed at the trainer, pump flags set.
- C3 framing: recapture waits on Stormwood-B's fight-camera fix.
- Late segment on the pad (`tests/smoke_tidewake_dry_run.gd --from=tidal --through=late`, at 586f7384): **PASS**. Human sheltered crossings to Salt Crown, Sluice and Veilfall; Venn beaten on the pad by the harness pilot along the walked spine; the interior pumps, Nerissa and the tether follow; reload drift 0.00 m, same party (`late_resume_on_pad.txt`). The shortcuts are those of F13#0 run 2 (declared start, checkpoint resume, harness pilot).
