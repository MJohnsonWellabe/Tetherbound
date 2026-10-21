# Cloudreach lane — close plan from 20 Oct 2026 (tb/cloudreach)

Renderer for every capture here: Low preset, Compatibility (gl_compatibility), Mesa llvmpipe CPU, 1280x720, xvfb. CPU-provisional bar 6.7 (owner 17 Oct).

## F08#3 settlements and cliff identity

Fixed set: `tools/capture_cloudreach_settlement_identity.gd` (5 stands x day/night, 10 frames). Control c0 = main 2124b1f6c (branch head eb3b9504b, art refs only).

| Round (US Central, 21 Oct) | Candidate | Judges (3, code-blind, shuffled L/R) | Control | Candidate | Gain |
|---|---|---|---|---|---|
| r2 | f4b51e798 `--cloudreach-settlement-life-candidate` (lamp posts, market edge, Cliffhold hearth, trees, darker warm spires, Cliffhold window glow + door lanterns via cliffhold_detail, Galefoot lantern line removed) | j1 4.90/5.10, j2 4.76/5.07, j3 5.03/5.29 | **4.90** (spread 0.27) | **5.15** (spread 0.22) | +0.25 |

Three-judge CPU scoring of the unchanged main build is 4.90, below the old single-judge 5.85 best.
r2 defects every judge named in the candidate: a dark-red prop at the Cliffhold approach (apple barrel/crate, removed in r3), a salmon tree trunk (realm tree palette applied in r3), white rather than warm lamp glow, no lit windows. All three name the same top gaps: (1) no height: the villages sit on flat lawns with no drop, terrace or cloud sea; (2) the spires read cool, smooth and grey, not warm stratified limestone; (3) the nights are moon-blue and the villages look unoccupied. All three say (3) is scene-fixable and the spire/cliff and Cloudreach building kit need new art.
r3 (27655046f, adds `--cloudreach-look-candidate`): captured, not judged. The biome-look rig turns the day spires back to near-white (shared geology) and makes night skies almost black. The lane's own check found no likely gain, so it is not spent on judges and the rig stays out of this candidate.
Status: first round under 0.5. The next approach that is clearly different is new art: the Meshy request (13 assets: strata spires, cliff shelf edge, islet, Cloudreach cottages and tower, lamp post, aviary pieces) went to the coordinator on 21 Oct. Not parked. Candidate stays OFF.
