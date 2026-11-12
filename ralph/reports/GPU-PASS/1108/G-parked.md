# GPU arm round 1108, G-parked: six parked scene arms (summary, GPU High, mapped)

The six arms come from `PARKED-ARMS.json`. Each has its own file, `G-<id>.md`. They were judged together in one batch, `G-parked` (11 live-vs-arm pairs, three code-blind judges, 3 pinned anchors; fit slope 1.412, r 0.897). The fight rim was re-judged against its matched live2 control in batch `G-rim2`.

| Arm | Row | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|---|
| `G-f41-13-charged` arm (`charged_1105`) | F41#13 | 5.53 | **6.14** | **+0.61** | **3/3** | **Ships** |
| `G-f41-13-charged` armGlow (plus ghost-glow settings) | F41#13 | 5.53 | **6.14** | **+0.61** | **3/3** | **Ships** (the comparison that counts, since ghost-glow ships) |
| `G-f40-2-windows` (window energy 2.4) | F40#2 | 6.75 | 6.80 | +0.05 | 1/3 | No |
| `G-f41-10-glass` (shards plus fused glass) | F41#10 | 5.72 | 5.76 | +0.04 | 1/3 | No |
| `G-f41-2-building-glow` | F41#2 | 5.62 | 5.62 | 0.00 | 0/3 (level) | No |
| `G-f39-16-cap-scatter` | F39#16 | 6.52 | 6.52 | 0.00 | 0/3 (level) | No |
| `G-f39-16-cap-scatter` | F39#17 | 6.47 | 6.47 | 0.00 | 0/3 (level) | No |
| `G-f41-fight-rim` arm, vs live2 (i01, tell1-a-start) | F41#3 | 5.16 | 5.16 | 0.00 | 0/3 (level) | No |
| `G-f41-fight-rim` armTone, vs live2 | F41#3 | 5.16 | 5.16 | 0.00 | 0/3 (level) | No |

**Ship:** `charged_1105` (F41#13), with or without the ghost-glow settings. The two score the same. It reaches 6.14, short of 7.5. The judges' remaining asks:
- Both creatures are no taller than the trainer, which breaks the scale rule.
- The glow is a body wash, not veins.

**Don't ship:** the other five.
- **Windows and glass:** visible, but they barely move the score, because the judges' objection is the landmark's form.
- **Building glow and cap scatter:** no visible change even on GPU, so these levers are spent.
- **Rim:** no change against the matched control.

**GPU lane cautions applied:**
- The fight rim was re-judged against live2, and tell1-e-impact was left out.
- F40#2's night frame was also checked by eye.
- The rock difference in the cap-scatter frames did not matter: all three judges scored those pairs level.
- Rows were assigned from job.json, so F41#6 and F39#17 frames are judged under their own rows.

**Correction:** my first `G-f41-fight-rim.md` blamed a tiled-sky regression on the arm. Live2 shows the same tiled sky, so it is a live Stormwood artefact on that side of the capacitor arena, not the arm. The file now carries the correction at the top.
