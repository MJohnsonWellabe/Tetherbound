# P2-037 canopy material candidate

The installed TwistedTree_2 and TwistedTree_4 leaf meshes use UVs authored for
`Leaves_TwistedTree_C.png`. Stormheart's current recolouring substitutes
`derived/Leaves_NormalTree_C_desat55.png`, including its different alpha mask.
The candidate retains the imported atlas and alpha cutoff, then recolours its
red leaf texture green in a double-sided shader. Both presentation and canopy
flags remain false. No mesh, placement, collision, deck or ascent changes occur.

## Evidence and limits

`audit_crown_atlas.py` reproduces `crown-atlas-audit.json` from repository root
using Python with numpy and Pillow. It samples 78 barycentric points per actual
leaf triangle, weighted by triangle area. At alpha >0.2, the substituted atlas
removes approximately 50% of the authored opaque area in both installed trees;
approximately 43% of its opaque area lies outside the authored mask. These are
source UV/mask diagnostics, **not screen coverage or visual acceptance**.

The existing installed nature family supplies both meshes and textures. The
shader adapts the material technique already present in the rejected, unwired
Stormheart hero candidate; it does not adopt that mesh or its provenance as an
accepted asset. No external generation, texture import or purchase is involved.

Focused engine checks passed 26 tests / 826 assertions across canopy material,
Stormheart presentation and wayfinding, water return, texture import policy,
and creature viewport framing. That run included two dummy-renderer null-material
diagnostics during destruction of the new enabled and legacy-disabled fixtures,
plus separate existing framing teardown leaks. After retaining and detaching
surface overrides in test cleanup, the two canopy tests passed 10 assertions
with no diagnostics. Cleanup log SHA256:
`6806949b520815902c434eae4e5c5bc6b0f66414a80ab125314beb865c185e15`.
The broader log SHA256 is
`9e1966703487f1f02315c63736d7809a1dd7a4fef142dc423bf2e6a63f5efe14`.
Texture import policy passed all 424 runtime 3D sidecars in mode 2.

Independent source review found no imported-material mutation or changes to
bark, geometry, placements or collision. The native Compatibility capture
completed six frames with no shader/script errors in its error log; existing
interpolation-deprecation, shared-model-retint and wild-cluster spacing warnings remain. Cutout
appearance, crown identity and preservation were independently reviewed below.

## Native comparison scope

The completed comparison repeats the six exterior frames at 400 m and 100 m,
Calm, Break and aftermath, using `capture_stormwood_f10_matrix.gd`. Compare with
`after-exterior-r1`, which already enables the grounding candidate, to isolate
the canopy material change. Capture metadata must disclose the current source
commit and temporary presentation flags. The fixture uses debug travel, pinned
weather and aftermath state; it is not earned progression proof.

`after-canopy-r1` retains the six native-source hashes and one compact page from
commit `832a8ebdca5cbf2e80df90167a38ef0ab307fdbf`. Every source image is
1920x1080, with identical camera positions, phase names and aftermath states to
the grounded baseline at `ecb7a8515edeaab90bb13c1d895a5f453cfd57f7`.
`canopy-comparison-coverage.json` records the comparisons. The legacy exterior
fixture does not record orientation; the repeated command is supporting evidence,
not numerical proof of equal camera basis. Rain, lightning and light animation
are not synchronized between the runs. Both candidate flags were restored off.

`canopy-pair-verdict.md` records the fresh blind review of all twelve native
images. The correction gives a small distant crown-contrast improvement but
also makes pale flat cutouts more apparent. Near views are essentially unchanged.
P2-037 remains open: cylindrical trunk, sparse branching/canopy architecture,
dark bands and construction detail still fail. Bars A/B remain NO/NO, and both
candidate flags remain off.
