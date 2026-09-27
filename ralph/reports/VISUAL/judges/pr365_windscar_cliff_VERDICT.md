# Code-blind judge — Windscar cliff (F08#4)

Inputs: A.png (baseline) and B.png (candidate), 1920x1080, same camera. References: ART_DIRECTION.md, the visual-judge SKILL.md and the two Cloudreach boards. Scale anchor: the 1.80 m trainer.

A pixel diff confirms that only three areas changed: the tall left spire (x≈280–640, y 0–460), the small pale pillar behind it (x≈575–640), and the upper-right cliff wall (x≈1510–1820, y≈80–390). The foreground, the arch, the banners, the masonry boulders, the grass and the sky are identical between the frames.

## Frame A (baseline)

- **Left spire:** a tall, soft, rounded column. The faces are long vertical streaks that look like a mesh pulled upward: shading smears top to bottom with no horizontal break, ledge or strata. The whole face carries a fine cross-hatch/screen-door texture that reads as a stretched or undersampled texture rather than grain. The silhouette edges are jagged in a stair-step way, not a rock-fracture way. Two flat, disc-like grey slabs stick out of the left and right flanks at mid-height, like floating shelf fungus or plates. The base disappears behind the masonry boulder and the grass lip, so no contact with the ground is visible.
- **Right wall:** a long, uniform, pale cool-grey curtain with soft vertical flutes and almost no internal detail. It is smooth-shaded like clay, with a thin khaki strip of "grass" along the top edge laid in a sawtooth zigzag. It sits behind a flatter grey rock shelf with patchy moss, which reads better.
- **Distant:** a mesa with a green top in the arch, and pale block pillars and cloud blobs at left. They are low-detail but acceptable at that distance.
- **Material:** every cliff has one untextured cool grey-green with no colour variation, no warm/cool separation, no moss, no vegetation on ledges, and no weathering or strata. It clashes with the warm, olive, hand-painted masonry texture on the two near boulders, which look like a different asset family (a brick wall wrapped onto a rock).

## Frame B (candidate)

- **Left spire:** the same silhouette and position, but the surface is broken into sharper angular plates and prisms. There is more light/dark facet contrast, a visible horizontal break partway up (the first hint of a joint or ledge), and a diagonal pale fracture line. The long vertical smear is broken up, and the spire reads more like columnar or fractured rock than a stretched cylinder. The screen-door micro-pattern is still present, slightly weaker. Along the left flank there is a new comb or zigzag stripe artefact (fine "////" hatching around y≈400–470). The same flat floating side-slabs remain.
- **Pale pillar behind (x≈600):** a slightly different, more faceted top. It is a neutral change.
- **Right wall:** a new jagged vertical crack/step near the lower centre, plus some added fluting. Just above the moss shelf there is a thin, lighter curved sliver edge that reads like the lip of a surface cutting through or hovering in front of the wall (a minor intersection/seam). Otherwise it is the same smooth, flat-grey curtain.
- **Material:** unchanged. It is the same single pale grey with no strata colour, moss, vegetation or warm tone, and it is still mismatched with the masonry boulders.

## Answers

1. **More believable cliff rock: B.** Its faceting and the first horizontal break turn the left spire from a stretched, smeared cylinder into something that reads as fractured rock. The improvement is modest and mostly confined to the left spire.
2. **Defects introduced by B: yes, minor.** There is a new zigzag/comb stripe on the spire's left flank, and a thin lighter curved sliver at the base of the right wall where a surface appears to cut through or float in front of it. B adds no floating pieces or scale errors (the pre-existing floating side-slabs are unchanged), and a still frame cannot show popping.
3. **Does B's cliff meet the Cloudreach board identity? NO.** The board's cliffs are warm, weathered, layered stone with strata, moss and trees clinging to ledges, waterfalls and grass on the tops. B's cliffs are still monochrome grey clay with no strata, no vegetation and no warm/cool separation. The form is better, but the material and regional identity are not there.
4. **Overall for this cliff slice of F08#4: FAIL.** B is a real step in form, but the criterion asks for believable, integrated rock that matches the boards, and the material, integration and identity are still missing. Remaining fixes:
   - **Material:** replace the flat grey shader with a triplanar weathered-stone material. It needs horizontal strata banding, warm/cool value variation (warm sunlit tops, cooler shadowed faces), and moss or grass on the upward-facing normals only.
   - **Strata and ledges:** carry the horizontal break B began across the whole spire and the right wall, as stacked, stepped layers like the board's cliffs, not a single joint.
   - **Surface artefacts:** remove the screen-door/cross-hatch micro-pattern on the spire (it looks like texture stretch or an undersampled normal/detail map) and the new zigzag stripe on its left flank.
   - **Right wall:** break up its uniform curtain with buttresses, overhangs and recesses. Replace the sawtooth khaki top strip with a real grass/turf lip and some clinging shrubs or trees.
   - **Seams:** fix the curved sliver at the right wall's base and the floating disc-slabs on the spire's flanks. Either seat them as ledges carrying vegetation or remove them.
   - **One rock family:** make the near boulders and the cliffs share one material. The olive brick-pattern boulders currently read as a separate masonry asset in front of grey clay cliffs.
   - **Board lures (not rock, but they carry the identity):** at least one waterfall, trees on the cliff tops, or visible rope/timber bridge anchors in this view, so that it reads as Cloudreach and not a generic grey-cliff meadow.

Top three gaps from the reference, ranked:
1. Monochrome untextured grey rock versus the board's layered, weathered, warm stone (A and B).
2. No vegetation, waterfalls or settlement structure on or against the cliffs (A and B).
3. Surface artefacts: screen-door micro-texture and vertical smear (A; reduced but still present in B, plus B's new zigzag stripe).

Fixable by changing the scene (material, scatter, placement): items 1–2, most of the right-wall treatment, and the boulder material unification. Needs new art: a set of layered cliff meshes with authored strata silhouettes, if the current meshes cannot carry banding after a material change.

---
Provenance (VIS, added after the judge returned): frames are `ralph/reports/VISUAL/cliff-family/ownership/windscar-baseline.png` (A) and `windscar-sections.png` (B) at #365 head `b1b2b425`, native 1920×1080, one stand, day. The judge saw only these, `/tmp/claude-0/judge/refs/` and neutral labels. The Tidewake coastal-rock pairs in `b9cecc17` were not judged (C4 TW7 / V18, not an open FOCUS criterion).
