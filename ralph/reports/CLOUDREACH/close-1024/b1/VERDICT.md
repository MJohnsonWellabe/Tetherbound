# Batch b1 — Cloudreach CPU pre-judge (24 Oct 2026, ~15:40 CT)

Renderer: Low preset, Compatibility, Mesa llvmpipe CPU, 1280x720. Yardstick: standard prompt verbatim (`judge_prompt_filled.txt`), `anchor_tiles.py --pairs 4 --include craft --seed 2410`, three fresh code-blind judges, `calibrate.py` (`batch.json` → `mapped.json`). Fit: linear, slope 1.548, intercept −2.284, r 0.89, anchor RMSE 0.50, 8 anchor points, top anchor 7.35 (confirming batch), no warnings. **CPU pre-judge only: GPU decides done (owner, 24 Oct).**

| Item | Arms | Raw j1/j2/j3 (cand.; control) | Mapped control | Mapped candidate | Defects (candidate, j1/j2/j3) |
|---|---|---|---|---|---|
| High Perches compass, day | control = F40 CPU recapture stand 7 (22b88b52); candidate `--cloudreach-high-perches-compass-candidate` (df2906c6d content) | 5.9/5.4/5.7; 4.9/4.6/4.8 | 5.10 | **6.49** (+1.39) | blue bands FIXED ×3; caption PRESENT ×3 (both arms) |
| High Perches compass, night | same | 5.2/4.9/5.0; 4.4/4.1/4.2 | 4.27 | **5.51** (+1.24) | blue bands FIXED ×3; caption PRESENT ×3 |
| Sky Shrine heartstone (P2-021) | control flag off; candidate `--cloudreach-f40-heartstone-candidate` (ca639609) | 5.5/4.7/5.1; 4.9/4.2/4.5 | 4.73 | **5.61** (+0.88) | egg FIXED ×3; approach rock PRESENT ×3 (camera set) |
| F08#3 r18b settlements | control c18 (shipping); candidate a18b `--cloudreach-settlement-r18-candidate` (ca639609) | 5.9/5.3/5.8; 5.6/5.0/5.5 | 6.02 | **6.49** (+0.47) | foreground PARTIAL ×3; moon-blue nights PRESENT ×3; rust road PARTIAL/FIXED/PARTIAL; windows PARTIAL/FIXED/PARTIAL |

Judges, shared asks: (1) keep the stone-inlay court marks and remove or anchor the world-space NPC caption that covers the right third of the High Perches reverse frame (scene; UI/NPC lane); (2) warm local lamp/window/fire light against the moon grade at night, lift subjects off murky grounds (scene); (3) the sky-shrine catalog cameras are blocked (boulder fills the approach, heartstone cropped by the top edge in the close frame) — the shrine never reads as a landmark whatever the heartstone (camera set, scene); (4) out of lane: Team Tether grunt face, Meadows ground smear (new art).

Evidence kept: key, recorded defects, filled prompt, per-judge Bar A, batch/mapped. Frames local (`.artifacts/`).
