# DLG-2: honest dialogue scores on main with the corrected capture fixture, High (31 Oct 2026)

**Verdict: new scores of record for six dialogue items.** No arm: main with the corrected dialogue fixture (a tool change only), judged one-sided.
- **MET: none.** The best are P2-087 at 6.94 and P2-076 at 6.92. No item maps to 7.5 at High, so no Medium runs (owner rule: High first).
- **The fixture fix moves every item well above its DLG-1 score**, because the camera now pushes in at the speaker.
- The DLG-1 numbers come from a different batch, so the deltas below are indicative. The new numbers are the scores of record.

| Item | Subject | DLG-1 (old fixture) | **DLG-2, High** | Recorded defect, judges | Gap to 7.5 |
|---|---|---|---|---|---|
| P2-087 | Meadows: Bram, stronghold courtyard, elite | 5.12 | **6.94** | speaker not shown: **FIXED 3** | 0.56 |
| P2-076 | Cloudreach: Kelm, Veyra, Veyra defeated | 4.39 | **6.92** | speaker absent: **FIXED 3** | 0.58 |
| P2-073 | Tidewake: Daro, Bex, Irva | 5.05 | **6.83** | small distant speaker: PARTIAL 2 / FIXED 1 | 0.67 |
| P2-081 | Stormwood: Wen, Senn, Marrow (dynamo core) | 6.38 | **6.62** | generic line, no portrait: **FIXED 3** | 0.88 |
| P2-074 | Tidewake: Nalia, Nerissa ×2 | 3.79 | **5.78** | no identifiable speaker: PARTIAL 3 | 1.72 |
| P2-083 | Stormwood: Marrow ×2, Nysa | 4.45 | **5.52** | overhead geometry hides speaker: PRESENT 3 | 1.98 |

**Push-in, per frame, on GPU: 12 of 17 dialogue frames push in.**
- **Pushed in:** Veyra, Veyra defeated, Kelm, Bram, Solene (courtyard), Hald (elite), Wen, Senn, Nysa, Bex, Daro, Irva.
- **Not pushed in:**
  - **Captain Marrow, both frames** (character and dynamo core). A wide shot under the overhead deck: the speaker is not visible, only the small player. This drives P2-083 (PRESENT 3) and the Marrow frame in P2-081. As the coordinator expected.
  - **Resident Nalia.** The camera faces a bare slope with no NPC in frame (not placed yet). As expected.
  - **Captain Nerissa, both frames** (character and trainer). A wide, dim shot of the chamber with both figures small. **This differs from CPU**, which showed Nerissa ×2 pushed in. Worth checking the fixture's stand for Nerissa on Forward+, or a timing difference in the chamber.

**Path to 7.5 (from the judges' notes):**
- **P2-087 and P2-076:** the speakers are visible now. What remains is finish:
  - break the single orange-brown grade on the stronghold frames (P2-087);
  - give the bare flat-dirt Cloudreach plaza stone and props (P2-076).
- **P2-073:** frame the speaker medium-close beside the panel. Today the speaker is mid-ground over the shoulder and the player's back takes about a third of the frame (Bex, Irva).
- **P2-081:** fix the Marrow frame (below). Wen's and Senn's frames already read.
- **P2-074:** place Nalia and give her a stand beside the body. Push in at Nerissa, and add key, rim and fog depth to the dim chamber.
- **P2-083:** a line-of-sight check on the dialogue camera, so the overhead deck never hides Captain Marrow. Marrow needs a stand beside the body.

**Capture:**
- **Tree M:** local commit c3bad166e = main ade041d97 + `tb/world-fix-menu-text` 305ac709c with `menu_text_floors` OFF, so it renders as main. Imported once, shared with MENU-1. Not pushed.
- **Arm:** M with `tools/phase2_capture_dialogue.gd` byte-copied from `tb/world-fix-dialogue-capture` c718cf325. Main has not changed that file since the branch point fc885aec9, so the copy is exact. Receipt in `yardstick/flips.jsonl`.
- **Command:** each item's job.json command, grouped one boot per biome: Tidewake 6 subsets, Stormwood 5, Meadows 3, Cloudreach 2, plus Veyra's defeated-dialogue tool on its own. Five launches in all, every one first try (`yardstick/runlog.jsonl`). 17 frames, all resolved.
- **Local frame-matching fix:** the tool writes Tidewake frames as `water__...`, while the item ids say `tidewake__...`. `frame_match.py` now also accepts the same id after the first segment, when the match is unique (`frame_match.py.txt`). It only applies when the exact match fails.

**Method:**
- 6 one-sided sets (the same strip on both sides) in one batch, each with 4 anchor pairs, three code-blind judges, high anchors.
- Fit r 0.87, RMSE 0.55, confirming.
