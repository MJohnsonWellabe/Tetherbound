# Tidewake calibrated batch 1 (22 Oct 2026, ~13:05 CT)

## Setup

- **Renderer:** CPU, llvmpipe gl_compatibility, preset Low, 1920x1080.
- **Captures:** `capture_f39_catalogue.gd --biome=water --times=day --seed=2042 --f39-weather=clear`, with 8 destination subsets.
- **Control:** look candidate OFF, at 807adae56. The production code is identical to the candidate commit.
- **Candidate:** `--tidewake-look-candidate`, at 0e13ef0cf.
- **Batch tooling:**
  - The batch was built with `tools/visual_judge/anchor_tiles.py --pairs 3`, giving 3 anchor pairs (6 tiles) from F10#2 and F36#0, plus 4 candidate sets.
  - Three fresh code-blind judges each received `JUDGE_PROMPT.md` verbatim.
  - Scores were mapped with `calibrate.py`: linear fit, slope 0.857, intercept 1.198, r = 0.855, anchor RMSE 0.63, top anchor 7.53.
  - **Warning:** "named destinations A, control" lies more than 0.5 outside the anchors' measured range (extrapolated low). No candidate score is above the top anchor.
- Files: `key.json`, `batch.json`, `mapped.json`, `judges.json`, `sets.md`, `recorded_defects.txt`, `b1_spec.json`, and `_sheet_b1.png` (sets Kr, Sy, Gq, Uv as judged).

## Mapped Bar A

| Row | Set | Control j1/j2/j3 → mapped | Candidate j1/j2/j3 → mapped | Gain |
|---|---|---|---|---|
| P2-011 named destinations, heading 0 (Reedhaven, Deep Watch, Salt Crown, Lantern Cove) | Kr | 3.4/3.9/3.8 → **4.37** | 5.5/5.8/5.6 → **6.03** | +1.66 |
| P2-011 named destinations, other headings (Veilfall gate, Drowned Garden, Deep Watch -45, Reedhaven 45) | Sy | 3.5/4.3/3.8 → **4.51** | 5.8/6.0/6.0 → **6.28** | +1.77 |
| P2-026/P2-009 water and shoals | Gq | 4.8/5.0/4.8 → **5.37** | 4.6/5.4/5.3 → **5.57** | +0.20 |
| F13#5 dock (Brine Steps east) | Uv | 4.3/4.7/4.5 → **5.06** | 6.4/6.6/6.4 → **6.74** | +1.68 |

- No row is at 7.5.
- Bar B is "no" for every candidate set.

## Recorded defects (three judges)

- **Dock corral fence:** FIXED ×3 on the candidate.
- **Named destination missing:**
  - Candidate: PARTIAL ×3 on both sets. The Drowned Garden terraces and the Salt Crown shrine still fail.
  - Control: PRESENT.
- **Shoal disc chain:** candidate PARTIAL ×2, PRESENT ×1.
- **Bubble-sprite foam:** candidate PARTIAL ×3.
- **Flat shallow/deep bands:** PRESENT ×3 on the candidate, which is worse than the control's PARTIAL.

## Judges' asks (worklist)

1. **Water (scene).**
   - The candidate's shallow halo is a hard bright-cyan collar on flat navy. The control's softer step read better. Grade it.
   - A translucent white "wireframe/lattice slab" runs diagonally across the Drowned Garden channel on both sides. This is a real artefact; find it.
   - The shoals are still an evenly spaced straight line.
2. **Drowned Garden (art).**
   - The lone brown wooden arch reads as a stand-in standing in the sea. Remove it.
   - The terraces are still missing.
3. **Salt Crown (art).** The shrine reads as a dark curved shape on a pole half-hidden behind the crest. It needs a real hero piece.
4. **Veilfall gate.** Integrate it with the falls and rock.
5. **Lighting (scene).**
   - Flat noon with no haze or atmosphere.
   - Dune shadow faces read as large untextured planes.
   - Uniform grass scatter.
6. **Dock.** Buildings cluster to one side with empty dune to the left.

Disposition: all candidates stay OFF. Every row is open, and the best mapped score is 6.74 (dock).
