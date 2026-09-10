# Creature candidate 01 — anatomy-scoped eye retention and active alpha palette

Status: Voltarach alpha retained as the production candidate. The Skyrill eye-mask hypothesis was rendered and rejected by a fresh judge, so its config and production texture are withdrawn. No mesh, scale, runtime material, shader, combat, camera or environment file changed.

## Diagnosis and scope

The prior shared mipmap experiment remains held: it produced modest smoothing but repeated losses beyond the frozen 5% face-contrast guard. Runtime probes also disproved one universal material fault across the cast. The shared repaint default still finds the darkest 3% across an entire atlas and re-stamps it after smoothing. That protects arbitrary body speckle as readily as eyes because it has no anatomical selector.

The existing deterministic overlay pipeline can select model-space anatomy per species. This candidate uses that supported mechanism only where attribution is concrete; it does not claim one face mask fits unrelated meshes.

- Pebblik was inspected and left unchanged because its eyes already read in the isolated portrait.
- Torrentoad was excluded because its remaining authorized round requires geometry/rig attribution rather than another paint-only attempt.
- Skyrill's source-dark texels were measured against its rasterized GLB anatomy map. In the visible front-high region, pixels below value 0.30 cluster at unit `z 0.706–0.893`, `y 0.578–0.767`, centered at `x 0.555`. A candidate disabled the atlas-wide darkest-3% restamp and retained only that narrow region. The overlay landed over 0.1% of the surface, but the fresh judge found no meaningful visible difference and ambiguous eyes in both sets. It is withdrawn without a second near-identical mask tweak. The remaining issue needs source/UV eye attribution or installed facial geometry, a distinct mechanism.
- The owner-rejected pink spider is the active Voltarach alpha. Runtime prefers an authored `_alpha` texture and previously fell back to the magenta vivid texture because none existed. The candidate adds an explicit storm-indigo shell/cyan-node alpha colourway; ordinary Voltarach stays unchanged. The generated alpha has 0% of chromatic pixels in the Meadows terrain hue band.

## Exact production files

- `data/creatures/four_biome_colourways.json`
- `assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_alpha.png` (new)

The generator also extracted untracked source PNGs from the installed GLBs for local derivation. They are source intermediates and are outside the intended production diff.

## Evidence

Baseline isolated frames are under `.artifacts/creature-pipeline-0910/baseline/`. The Skyrill portrait shows broad aqua facial patches without a readily identifiable eye. `voltarach_alpha_x1.30.png` confirms the active alpha and ordinary body both use the rejected saturated magenta family.

The candidate was generated through `tools/repaint_creature_textures.py`, without hand painting. JSON parsing passed. Two consecutive generations produced identical SHA-256 outputs:

- Skyrill vivid: `F728AFD3364A9C3B0C80ED51BD6E7632C0DA7349AB7AF5F40EB8CCD89FA18896`
- Voltarach alpha: `2B40ECCEE1D1E52D1A1D173F850A5733A4086A452D3FC656A27FC966520DD104`

Candidate runtime import/readback and isolated capture completed. The Skyrill verdict is `JUDGE-SKYRILL-01.md` and rejects that half of the candidate. The fresh neutral Voltarach verdict is `JUDGE-VOLTARACH-01.md`: it prefers the indigo candidate because the two individuals separate and the palette is more restrained, while retaining explicit A No / broad-genre B Yes / shipping-art No. Remaining gaps are facial expression, dominant body/limb hierarchy and surface restraint. A production-world alpha-proximity comparison remains required. The earlier Cloudreach full-catalogue baseline failure is preserved; a later two-frame Cloudreach production capture completed, but it contains no evidence about alpha/ordinary creature relationship. Stormwood full-catalogue production evidence exists, but no isolated alpha-proximity judge has evaluated it. This report therefore does not claim a world-context colourway bar pass.

## Shared combat-camera candidate 03

The original 10m cap failed an actual maximum-body probe: an Abyssal Guardian ally and Solmane opponent produced two behind-camera AABB corners and severe side cropping at both 5m and 11m gaps. Candidate 01's flat-plane fit removed the behind-camera corners but still clipped the 11m pair because it ignored body depth. Candidate 02's bounding sphere accounted for depth but treated the roughly 20m horizontal sphere as vertical extent too; it requested 31.345m at both gaps and produced a detached overhead view.

Candidate 03 caches each live body's actual `RenderBounds.measure(model_pivot())` AABB, transforms its eight corners into the production camera basis, and solves the horizontal and vertical perspective planes independently. For each corner it requires `depth + max(abs(x) / (tan(hfov/2) * fill), abs(y) / (tan(vfov/2) * fill))`, then applies the existing lag, configured maximum and room-clearance ceiling. No mesh walk occurs per tick, and switching/releasing invalidates the cache.

The fresh native open-field probe exited 0 with no errors. At a 5m gap it requested and reached 18.076m; the projected union occupied normalized position `(0.221, 0.247)`, size `(0.689, 0.656)`, with zero behind-camera corners. At 11m it requested and reached 24.178m; union position was `(0.343, 0.298)`, size `(0.567, 0.460)`, again with zero behind-camera corners. The blind verdict in `JUDGE-CAMERA03.md` preferred the 5m candidate frame: both bodies and main appendages fit while remaining prominent. It found the 11m frame substantially more usable than the clipped baseline but somewhat too distant for the strongest creature-adventure presentation. It still rated key-art belonging No, broad genre Yes and commercial parity No; camera framing does not repair weak facial anatomy or surface finish.

The first camera03 headless smoke (`camera03-smoke-first`) failed its second encounter entry even though Ripplet remained healthy and the same Bramblebun was engageable at 1.509m: an anonymous spatial `Interactable` won the production arbiter. The changed diagnostic run passed twice with `EncounterDirector` winning, so the intermittent fixture conflict was not treated as fixed by retry. Code construction narrows the anonymous owner to a scatter harvest point or authored pickup, but no failing run with the expanded label/script diagnostics exists, so its exact type remains uncertain. The smoke now tests a deterministic, bounded set of grounded approach points around the same live wild and sends physical X only after the production arbiter publishes `EncounterDirector`; it does not change priorities or call combat directly. Its first native OpenGL validation, `camera03-published-approach-first` (03:00:46–03:02:25), exited 0 with no errors in 98 seconds and published `EncounterDirector` for both physical entries.

The ordinary camera smoke asserts open-field FOV-derived widening and the configured maximum. Tight-room and SpringArm behavior are covered separately by the existing Stronghold battle-camera smoke, now extended to invoke the real dynamic framing updater with live combatants and assert the requested distance remains under the production `_room_clearance()` result, the SpringArm does not extend beyond that request, and orbit/follow remain live. Its first headless validation over real production state and collision, `camera03-stronghold-room-first` (03:05:15–03:06:38), exited 0 with no errors in 83 seconds. The live production clearance, requested distance, SpringArm length and collision hit length were all 2.25m; raw orbit/follow and combat exit assertions also passed. This is behavioral/collision evidence, not rendered visual evidence.
