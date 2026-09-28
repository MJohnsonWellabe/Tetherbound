# F03#0 strict re-check (independent read-only subagent, tb/meadows 7e8b17cf7)

The re-checker read ACCEPTANCE §6.1 F03, STATE §1.1, CLAUDE_START_HERE §3.5 and §4 row 3, and judge F. It also read this folder's README, LURE-JUDGE-r12/r13 and receipts, and the band configs (5001, 1058), alpha_pins.gd, smoke_alpha_pins.gd and capture_activity_lures.gd. It opened these frames:
- herd_night_walk 04–06, 09 and 10;
- hall_south 10–16, with 3x crops of 12–14;
- vault_cleared 03 and 06–09;
- the Doss frames (walks_122a8efb and lure0/doss-f);
- bram_06 and juno_09.

| Item | Result | Evidence | Reason |
|---|---|---|---|
| Unstaged ordinary-discovery witness | MET, with the Doss citation corrected | walks_122a8efb/{bram,juno,herd}, herd_night_walk_8fc88f20, hall_south_14e917a3, vault_cleared_36d88a84; Doss: MEADOWS-PAYOFFS/six-activities/earned/lure0/doss-f | Receipts show `script_state_writes: none`, and load vs saved position is within 0.26 m. Bram, Juno, herd and Hall are first seen on the road with no deliberate look, at 79.6, 159.6, 63 and 146.6 m. Vault reaches "Engage Elder Trailpup", and frames 06–08 show the lit door with its fire-pots. The 122a8efb Doss walk first saw Doss at 24 m off the road after a deliberate look. doss-f's 60 m on-road glance shows pennant, smoke and perch (judge F: PASS). |
| Herd night cue | MET | herd_night_walk_8fc88f20 04–06, 09, 10; band1 props order 1058 | The clock reaches night unaided (08:12 start; frames at 23:31–00:22). At 63 m from the camera, on the road, the pale Meadowharts and the warm fire read in 04–06. They read again at 09 and at the prompt in 10. |
| Hall pack on a road sightline, nameplate depth-tested | MET | hall_south_14e917a3 12–16; spawns.json 5001 ((-45,7300), r8, wander 5, `no_depth_test: false`) | The name reads at about 112 m, clipped by the pylon and a tree, so the depth test is on. The alpha's pale body and pack members stand in open ground under the label from on-road positions at 58 m and 48 m. Judge r13 took the player's own Gale for the alpha. The pack reads at 29 m. |
| Overall: at least six activities show a visible lure | MET | judge F plus the six witnesses | Vault, Bram, Doss, Hall, herd and Juno. Bars A/B → Phase 2 catalog. |

**VERDICT: MET**

Disclosures to record: the README's section 6 lists them. The re-checker asked for the Hall decline smoke output to be committed; it is in `hall_decline_smoke.txt`.
