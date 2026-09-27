# Stormheart hero tree — rejected WIP

Preserved candidate art; **not accepted and not wired into production**. Searches of production scripts, scenes, data and project configuration found no references to this candidate. The asset-local scene/script and archived capture evidence remain for revision. The integration text in [provenance.json](provenance.json) describes a proposed placement, not current wiring.

The independent [living-finish judgment](../../../../ralph/reports/VISUAL/stormheart-hero-candidate/visual-judge-living.md) rejects the scoped tree and gives full-scene Bars A/B **NO/NO**. Its six native frames are in [living-corrected1080](../../../../ralph/reports/VISUAL/stormheart-hero-candidate/living-corrected1080/):

- `stormheart_road_220m.png`: upper crown and branch ends read as pointed, torn sheets rather than wood/foliage.
- `stormheart_road_120m_verge.png` and `stormheart_road_120m.png`: stretched vertical bark grain, blurry patches and abrupt faceted transitions fail on approach.
- `stormheart_road_320m.png`: thin pale canopy plates mismatch the surrounding dense dark-green forest.

Next art revision must repair branch/crown geometry, bark mapping and malformed transitions, and build substantial irregular canopy volume while preserving the monumental split silhouette. Full-scene rings/core, approach obstruction and creature staging are separate unresolved work. Keep this candidate unwired until revised art has fresh native evidence and independent scoped review; these notes close no acceptance criterion.

## Source reproduction

[provenance.json](provenance.json) and [submission.json](source/submission.json) retain the inspected image reference, hashes, settings and existing-license Meshy task `01a0e4a2-5b8b-77c4-bf72-2b340d0a8f00`. The original download is [source/model.glb](source/model.glb); no new Meshy submission is needed to reproduce preparation.

From the repository root, create `assets_raw/stormheart_hero/` if absent, then run Blender 4.2:

```powershell
blender --background --python assets/environment/stormwood/stormheart_hero/source/prepare_stormheart.py
```

This regenerates `stormheart_hero.glb` and writes the prepared blend and geometry audit under `assets_raw/stormheart_hero/`. The checked-in `stormheart_hero.tscn`, `stormheart_hero.gd` and two shaders supply the later living finish using installed `stylized_nature` bark and leaf assets. Preserve those files and source audits together. Reproduction is not visual acceptance.
