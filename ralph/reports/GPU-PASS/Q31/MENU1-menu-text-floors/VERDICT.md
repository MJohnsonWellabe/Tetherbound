# MENU-1: menu text floors (UI-R2 follow-up), High, gamepad (31 Oct 2026)

**Verdict: land MENU-1, for P2-031 only.**
- **P2-031** (settings and quick-binding text) moves **5.62 → 6.12 (+0.50; +0.502 unrounded)**. Its recorded defect goes from PRESENT 3 to **PARTIAL 3**. That clears the >0.5 qualifying gain by a hair: each judge moved it exactly +0.5 mapped.
- **The other four items score identically on both arms**, and the judges said those sides look the same: P2-001, P2-004, P2-007 and P2-032.
- **No regressions and no clipped or overflowing text.** I checked the candidate's settings, quick-binding and Satchel frames myself.
- **MET: none.** The best is P2-004 at 6.75, so no Medium runs (owner rule: High first).

| Item | Subject | High ctl → cand | Recorded defect, ctl → cand | >0.5 | Gap to 7.5 |
|---|---|---|---|---|---|
| **P2-031** | settings and binding instructions | 5.62 → **6.12 (+0.50)** | PRESENT 3 → **PARTIAL 3** | **yes, +0.502** | 1.38 |
| P2-004 | exploration HUD | 6.75 → 6.75 | PRESENT 3 → PRESENT 3 | no (unchanged) | 0.75 |
| P2-001 | menu shell (Satchel, Build, Creatures) | 6.25 → 6.25 | PARTIAL 3 → PARTIAL 3 | no (unchanged) | 1.25 |
| P2-007 | Quests, Build, Players panels | 5.91 → 5.91 | PRESENT 3 → PRESENT 3 | no (unchanged) | 1.59 |
| P2-032 | map active region | 5.74 → 5.74 | FIXED 3 → FIXED 3 | no (unchanged) | 1.76 |

**What changes on screen** (`_sheet_menu1.jpg`: control left, candidate right):
- **Settings controls:**
  - the literal "(or F10)" is gone;
  - a "More below ▼" cue and a bottom-edge fade replace the hard cut;
  - the fade covers the fourth row ("Step right"), so one fewer row is fully visible.
- **Quick bindings:** control cuts the "Fighting" header and its text line at the bottom edge. The candidate fades out under slot 5 with the "More below" cue; the fade dims slot 5's row a little.
- **Satchel:** control's worn-equipment list overflows (the fifth row, "Backpack: Empty", is cut). The candidate fits all five rows, which fixes the overflow UI-R2 found. The judges scored P2-001 identically on both arms; at the set's thumbnail size this change did not register.
- The skills tab, also touched by the change, is in none of these five items' frames.

**Path to 7.5 (from the judges' notes):**
- **P2-031:** the tables are still small grey-on-navy text, and the keyboard column shows bare W/S/A and 1–5. Brighter, larger table text and controller glyphs throughout.
- **P2-004:** group the ring of about seven dark HUD boxes; replace the placeholder white hotbar glyphs.
- **P2-001 and P2-007:**
  - one emphasised element per panel, with larger and brighter type;
  - fill the mostly empty Build, Players and Quest panels with art, or shrink them to their content.
- **P2-032:** the active-tab defect stays FIXED. The map itself is still a blurry blue field, so a painted Tidewake map is needed (new art).

**Capture:**
- **Tree M:** local commit c3bad166e = main ade041d97 + `tb/world-fix-menu-text` 305ac709c. Clean merge; with `menu_text_floors` OFF it renders as main. Imported once, shared with DLG-2. Not pushed.
- **Arms:**
  - Control = M.
  - Candidate = M with `data/config/menu.json` byte-copied from local commit 3697edaa0. That commit changes only `menu_text_floors.enabled` from false to true, as a text edit, so the file's ▼ and formatting stay intact. Receipt in `yardstick/flips.jsonl`.
- **Command:** each item's job.json command with `--gamepad` on both arms. Two boots per arm (Meadows c006, Tidewake c042), all first try.

**Method:**
- 5 two-sided sets in one batch, each with 4 anchor pairs, three code-blind judges, high anchors.
- Sides are balanced 2 A / 3 B: anchor seed 1, after the first draw put 4 of 5 candidates on side A.
- Fit r 0.98, RMSE 0.28, confirming.
