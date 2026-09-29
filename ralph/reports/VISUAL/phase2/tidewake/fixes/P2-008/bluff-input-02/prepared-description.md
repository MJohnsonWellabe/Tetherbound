# Gull Rest isolated mask-input comparison — scratch proposal

Prepared only; no Godot, import, renderer or native capture launched. This is four diagnostic masks in one boot, not a material candidate or visual acceptance. All production files and both production dune gates remain unchanged.

The prior exact-final-mask capture established that the cap/foot teeth survive unshaded output. It does **not** establish which input causes them. This comparison isolates the final height fade, painted-control interpolation, and height-derived slope separately. Palette, thresholds and mineral coverage targets are not tuned.

## Files and launch

- `bluff-input-02-wrapper.gd` extends the existing `dune_bluff_mask_ablation.gd`; its explicit `super()` reaches the parent's process-local ZIP mount and explicit base initializer.
- `bluff-input-02-{common,height,control,slope}.gdshader.txt` are injection snippets read at runtime.
- `bluff-input-02-launch.ps1` is the sole intended launch path. It claims an empty render lock atomically, refuses even an existing same-lane owner, records a unique token, and releases only its own token after its child has exited. Timeout terminates only that child before release. A kill/lock error must be investigated; never override an occupied lock.
- `bluff-input-02-check.py` runs CPU/source checks without Godot.
- `bluff-input-02-review.patch` contains the new scratch files for review, not a production patch.

After the suite freeze is lifted and the owner grants a GPU slot:

```powershell
& 'D:/tetherbound/x04-tidewake/.artifacts/phase2/bluff-input-02-launch.ps1' -Round bluff-input-02
```

Exactly one native boot uses `opengl3`, fullscreen 1920×1080, seed 2042, day/close, `water__gull_rest__20__gull_rest_beach`. Four outputs are written under `.artifacts/phase2/p2008-bluff-input-02/`; isolated APPDATA and stdout/stderr use the same round prefix. Output, APPDATA and log paths must be fresh. Use a new suffix for retries; do not overwrite failures.

The launcher verifies `dune05-runtime.zip` SHA-256 `f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12`. This existing ZIP enables dune configs **only inside the diagnostic process**. It refuses if either production dune config is enabled. It records actual launch HEAD rather than pretending that later runs use the original diagnostic source.

## Independent variants and cost

Each variant rebuilds from the exact installed original shader, never the previous variant. All four substitute final fragment output with the unshaded final bluff mask. Vertex code, mesh LOD, height/control assets, actual terrain lighting-normal calculations, Sun, camera, collision and gameplay are untouched.

| Variant | Only input changed | Added height/control texture fetches: `bilerp` | Added height/control: nearest branch |
| --- | --- | --- | --- |
| `mask_baseline` | None; exact final mask | 0 / 0 | 0 / 0 |
| `height_only` | Final `smoothstep(1.3, 3.5, v_vertex.y)` uses continuous four-height reconstruction | 0 / 0 | 1 / 3 |
| `control_only` | `painted_bluff` uses continuous four-control reconstruction | 0 / 0 | 0 / 3 |
| `slope_only` | Both bluff slope arguments use continuously weighted **raw forward gradients**, normalized once | 0 / 4 | 5 / 7 |

These are maximum *additional* texture calls on valid footprints, not total shader cost or measured GPU time. Common validity checks add no height reads and reuse control values already fetched when `bilerp` is true. Missing controls cost three reads in the nearest branch. The slope case checks four extra footprint controls in both branches; nearest also needs the missing corner height and four forward-neighbor heights. Near slope reconstructs raw gradients from the already-computed `index_normal[]` ratios, adding no height reads. This avoids a 40-fetch filter as the first experiment.

The stock fragment switches between interpolated and nearest signals using `region_mip < 0.0`. Control-only should therefore match baseline wherever stock interpolation already applies and the footprint is valid. Height-only changes the final height fade alone; it deliberately retains `v_vertex.y` in bluff noise. Slope-only removes the nearest-cell slope discontinuity and also changes near interpolation from weighted normalized normals to weighted raw gradients. That latter distinction is intentional and means it tests an alternate slope reconstruction, not only the mip branch. It does not blur over a configurable metre radius or guarantee less mineral coverage.

## Exact anchors and safety

The wrapper checks the live generated shader's final-mask anchor, both slope expressions, painted-mask assignment, fragment/vertex anchors, bilerp condition, all four normal formulas, and zero added `u/v` derivatives. Source drift aborts rather than guessing at another shader layout.

Four base lattice coordinates use existing `index_id`/`weights`, and the common path reuses existing `h[0,2,3]`, `h[1]` where initialized, and controls. Strict region-map bounds and layer checks run before extra texture reads; coordinates must agree with Terrain3D's installed lookup. Hole or invalid/nonfinite footprints retain the original scalar input. Slope additionally validates its forward-neighbor footprint and positive finite normal Y. These checks preserve the existing Veilfall exclusion and do not sample through absent neighboring regions. Fallback borders can themselves remain discontinuous; report that instead of interpreting them as success. No original `h`, controls, normals, vertex or index variables are assigned by the snippets.

The mask output is assigned after all ordinary fragment outputs. Fog and tonemapping remain, so grayscale is boundary-shape evidence rather than calibrated scalar data. Live creatures may move and are not diagnostic subjects.

## Provenance and success conditions

Manifest metadata includes actual source HEAD, config ZIP hash, source/wrapper/snippet hashes, original shader hash, expected per-case shader hashes, actual active shader hash per image, enabled override/gate readbacks, APPDATA, viewport, Sun transform/shadow settings/energy, player position and camera transform, and actual `mesh_size`, `mesh_lods`, `vertex_spacing`. Existing capture stand metadata is retained. Expected historical LOD is 48/7/1, but the wrapper records the actual initial values and rejects any subsequent changes; review against the previous capture before treating it as the same fixture.

Each case requires the installed diagnostic shader and unchanged LOD. Post-capture checks require exact player/camera/Sun agreement against the first mask plus the inherited stand checks. Tiny physics drift is a recorded failure, not silently accepted evidence. File-open/store errors fail the run. Launcher requires exit zero, manifest complete, zero failures, four image paths, and no shader/script errors in logs. Native shader compilation and all exact readbacks still need validation in the eventual queued run.

Compare only the fixed cap and foot boundary in the four native images. A change isolates sensitivity to that input but does not by itself prove causation or select a shipping fix. No visible change means that isolated reconstruction was insufficient at this fixture; it does not rule out all variants of that input. Do not combine successful-looking changes until their separate masks have been reviewed. Do not infer broad terrain safety, performance or art acceptance from this diagnostic.

## Completed checks and limits

CPU/source checker: **7 tests passed**. Checks cover direct versus recovered raw gradients, affine planes, lattice/region-boundary continuity on synthetic data, height/control continuity, distinction from normalized-normal interpolation, strict region mapping and fallback guards, exact current-source assembly and unchanged vertex function. PowerShell AST parser: **PASS**. Neither check invokes Godot. Real Gull height/control data, native shader compilation, render timing and runtime equal-fixture checks remain untested.
