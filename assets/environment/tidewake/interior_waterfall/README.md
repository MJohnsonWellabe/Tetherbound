# Veilfall interior waterfall — rejected WIP

Preserved revision-3 candidate; **not accepted and not wired into production**. Searches of production scripts, scenes, data and project configuration found no references to this candidate or its generated meshes. The asset-local scene and archived capture evidence remain for revision. Placement instructions in [source/provenance.json](source/provenance.json) describe the trial, not current wiring.

The independent [revision-3 judgment](../../../../ralph/reports/VISUAL/veilfall-assets-native/visual-judge-r3.md) rejects the scoped waterfall and gives full-scene Bars A/B **NO/NO**. Evidence is the nine frames in [after-r3](../../../../ralph/reports/VISUAL/veilfall-assets-native/after-r3/), especially `heart_chamber_crystal.png` and `motion_0.png`–`motion_2.png`:

- Flow appears suspended from rails against uninterrupted masonry, without a readable upstream opening/channel/reservoir.
- Opaque, smooth tapered sheets resemble cloth or flexible ribbons despite recognizable water streaks.
- Sharp repeated splash tufts end at a dark segmented curb; receiving water depth, spreading foam and drainage are not legible.

Next art revision must establish a convincing source connected to the chamber, break up continuous curtain silhouettes, and expose a receiving pool with coherent impact foam and an onward water route. The palette and distant water recognition are useful, but the decorative wall/tray construction fails. Chamber architecture and full-scene finish remain separate work. Keep the candidate unwired pending revised native evidence and independent scoped review; still samples do not certify motion and these notes close no acceptance criterion.

## Source reproduction

[source/provenance.json](source/provenance.json) records original project-authored meshes and Compatibility shaders, informed by the inspected Veilfall stronghold board. No reference pixels, third-party mesh, Meshy task or purchase was used.

From the repository root, run Python 3 (standard library only):

```powershell
python assets/environment/tidewake/interior_waterfall/source/generate_waterfall.py
```

The deterministic generator rewrites all seven OBJ meshes and `source/geometry_audit.json` in this candidate directory. Keep `interior_waterfall.tscn` and the checked-in shaders alongside them; the generator does not regenerate scene/material authoring. Geometry audit success is not visual acceptance.
