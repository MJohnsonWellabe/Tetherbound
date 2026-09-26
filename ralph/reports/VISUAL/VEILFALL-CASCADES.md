# X04 / F13#5 — Veilfall cascade conformance and flow

Base: `0e2a3b60c9263d4d96d447869d6e34d57efa2506`, main re-fetched before publication.
Implementation: `accf65e02596368113cce83d63829ee7ca2a10a9`.
PR: #322, `tb/x04-veilfall-waterfalls`. Claude owns integration and merge.
Anchor: ACCEPTANCE §4, ART_DIRECTION §4, Codex visual queue V2.

## Result

The fresh code-blind judge **prefers the candidate** for its internal watery texture and less conspicuous exposed white wedge at the close cliff. This is a bounded presentation repair. **Both base and candidate fail Bar A and Bar B.** No Veilfall, Tidewake or whole-game acceptance is claimed.

The highest remaining gap is landmark construction: the distant smooth cone and close stretched cliff walls need stepped rock masses, distinct ledges, waterfall origins and receiving water, and architecture that makes the stronghold entrance legible. The cascade still ends in angular fragments above a dry grassy cleft. Tint or scatter alone cannot close that gap.

## Defects and changes

- The fall shader decoded opacity from `COLOR.g` as the Y component of its lateral direction. Distance widening therefore sheared lower-opacity falls vertically. Lateral displacement now decodes only red/blue, with explicit zero Y.
- A cascade up to 96 m wide sampled terrain at only two edges. It could bridge through a shoulder between them. The mesh now samples transversely at up to 6 m intervals for current widths, including the outward standoff in the queried position. Neighboring triangles share normals derived from the grid rather than changing lighting at every row.
- At the center of the old ribbon, the alpha modulation was always saturated, while far colour had a narrow range near white. The shader now preserves moving strand variation after the detail fade, with a subdued base opacity.
- Remaining distance to the ribbon's foot is carried in UV2 and fades the terminal row into mist. This reduces the raw sheet edge; it does not create a receiving pool or repair the mountain's shape.

No collision, terrain bake, authored route, gates, controls, roster, palette exception or world state changed. The ribbon remains one surface; the existing spray mesh is unchanged. No generated assets or Meshy submissions were used.

## Evidence

Windows Godot 4.7 `5b4e0cb0f`, Compatibility OpenGL, GTX 1060 3GB. Captures are native 1920×1080 with 1280×720 reductions inspected. They use the production Water scene, trainer, CameraRig and HUD at teleported far/mid/near stands with frozen day/night. They are visual fixtures, not earned traversal evidence or an Ally performance result.

| Check | Observed |
|---|---|
| `test_veilfall_fall_surface`, `test_water_veilfall_geometry` | 2 tests, 595 assertions, zero failures |
| Surface regression strength | Independent source/math review: old first triangle penetrates the ridged fixture by 10.5 m, and its 96 m span fails the transverse-sample bound |
| Native far/mid/near capture | Six of six final day/night PNGs saved; exit 0; no ERROR or SCRIPT ERROR in the capture logs |
| Native temporal supplement | Twelve frames at ten-frame intervals with fixed 30 fps, covering four seconds at the mid stand; flow variation visible across samples. This is a short animation witness, not a sustained performance or traversal check |
| Independent exact-diff review | `veilfall_source_review`: no blocking correctness findings on implementation commit |
| Fresh code-blind visual review | `veilfall_blind_judge`: candidate preferred; both bars NO for both sets |

The regression fixture covers terrain penetration and normal consistency but does not isolate every old cause: its constant longitudinal slope does not independently reproduce row-lighting discontinuity, and its descending slope does not isolate pre-offset terrain sampling. Six-metre tessellation and later shader widening also cannot guarantee conformity to every narrow terrain feature; native inspection remains necessary.

Reproduction:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_veilfall_fall_surface,test_water_veilfall_geometry
godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/art_pipeline/capture_tidewake_matrix.gd -- --out=res://shots/veilfall-<fresh-round> --only=veilfall-far-first-shore,veilfall-mid-salt-crown,veilfall-near-arrival
```

For a native motion recording, add `--fixed-fps 30 --write-movie <local-file.avi>` to the rendered command. The final single contact sheet is `_sheet_veilfall_cascades.jpg`; individual frames, diagnostic toggles and short temporal supplement remain local under `shots/` and `D:/tetherbound/visual-acceptance-local/`, following WORKFLOW evidence hygiene. The renderer reports an existing deprecated physics-interpolation warning.

## Attribution and blind judgment

The first candidate improved streaks but retained angular edges. Diagnostic captures hid the far mountain proxy, spray, fall columns and gate curtain in separate comparisons. Hiding the proxy did not eliminate the angular fragments. Removing the gate curtain identified the lower hanging strip as a separate presentation layer; it is not resolved by the column shader. These diagnostic images were not substituted for the production review frames.

The blind judge received only neutral A/B sheets, all twelve native frames and their 720p reductions, ART_DIRECTION, the Veilfall board, Meadows key art and all five Palworld screenshots. A was the candidate; B was the base. It had no source, diff, change narrative or budget. Its findings:

1. Both sets lack a convincing source-ledge → falling water → receiving-pool relationship. The smooth cone, inflated close walls and stretched materials do not express the reference's layered mountain and hidden stronghold.
2. Creature presentation is weak in these stands. Distant creatures are noisy shapes in bright water. A base night frame also contains a visibly buried creature; the candidate has no corresponding creature in that position, so this is an open grounding defect, not evidence that this patch fixed it.
3. Large repetitive sand fields, abrupt grass/rock boundaries, sparse hillside props and uniformly filled grass strips lack authored transition and composition.

The base's thicker distant white falls are somewhat easier to spot, but read as solid ribbons and expose a worse slanted shelf and tapering strip. The candidate's internal variation is preferable. Other differences in water phase, notifications and creature positions are capture variability, not established regressions or improvements.

**Bar A: NO. Bar B: NO.** The next major visual work is the landmark's geometry and water integration, followed by representative approaches, night views, grounding and continuous movement. The full visual goal remains active.
