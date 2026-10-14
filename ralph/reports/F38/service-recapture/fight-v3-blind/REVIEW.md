# F38 Warden fight baseline review

- Status: three independent blind reviews completed; mapping unblinded below.
- Scope: all 14 retained live frames from each of the v3 High and Medium Warden Aldis/Galewisp runs, paired by manifest state index and blinded as A/B. The set includes P2-062 sighting states 01/02/03/05 and P2-064 sighting states 03/05/08; P2-064 r12/r21 are not represented.
- These are baseline captures from separate runs. The manifests mark every included frame `candidate=false`; this batch cannot establish a before/after fix or causal preset effect.
- Review targets P2-062 ally size, trainer/opponent visibility, other-creature visibility and apparent mesh intersection, plus P2-064 turquoise arena rails crossing creature silhouettes. Still images cannot establish collision.
- Source manifests and source/output SHA-256 values are recorded in `private-selection.json`.
- No impact score, catalog status or acceptance gate changed.

## Blind review findings

### P2-062 ally framing

- All three reviewers said the ally stays well below half of the view. None found the Galewisp hidden or a visible creature-to-creature intersection.
- Trainer overlap is less consistent. One reviewer reported partial overlap in Pair 06B, 07A/B, 09B, 10B, 13B and 14A/B; another flagged Pair 07B only; the third saw close projected spacing in Pairs 07/09/13/14 but said the trainer remained visible. These views do not establish full trainer occlusion or collision.
- The exact catalog states 01/02/03/05 are Pairs 06/14/12/04, respectively. The claimed half-view, Galewisp hiding and intersection are not observed in those exact samples; partial trainer overlap is disputed in Pair 06B and Pairs 14A/B.
- The source manifests also contain `warden_aldis-15.png` for High and Medium, but mark state 15 `live_fight=false`; both images show the battle-lost recovery screen and say Galewisp is out of the fight. Manifest SHA-256 values are `1fe12989ee559c8eb1efcc93bcf85882764f87af2795c0471ac246141b2086f3` (High) and `4eae8dd6b320a46c1b0357fe47217f29706719e51323e1caffccf7ee16726525` (Medium). The exact catalog sighting `meadows__fights__warden_aldis-r15` has not been proven to map to these `-15` files, so they are not counted as that missing live-fight sighting or a candidate comparison.
- Retained-manifest coverage for P2-062: Warden Aldis states 01/02/03/05 have reviewed High/Medium baseline pairs only. Exact `south_bridge_grunt` sightings 01/02/03/05/r05 and exact `warden_aldis-r15` receipts were not found in the retained service-catalog manifests. No candidate pairs were found for any listed P2-062 sighting.

### P2-064 arena boundary

- Reviewers disagree on whether turquoise rails cross silhouettes. One found no crossing in any pair; one marked crossings in Pairs 01A, 03B, 06A/B, 07A/B, 08A/B, 09A/B, 11A/B, 13B and 14A/B; the third identified Pair 01B as the clearest possible crossing and called other near-foot cases ambiguous.
- The exact catalog states 03/05/08 are Pairs 12/04/05. None of the reviewers identified a crossing in those three pairs. This packet therefore does not confirm the defect in the matched catalog sightings.

### Other visible clutter

- Foliage silhouettes intrude into multiple views. Reviewers also noted magenta attack graphics, warning/event text and small bottom HUD/log text competing with the action. These are sample observations, not causal diagnoses.
- Neither side was consistently more readable. The presets came from separate baseline runs, so preference does not establish a fix or a preset effect.

## Unblinded pair mapping

| Pair | State | A | B |
|---|---:|---|---|
| 01 | 09 | High | Medium |
| 02 | 06 | Medium | High |
| 03 | 04 | High | Medium |
| 04 | 05 | High | Medium |
| 05 | 08 | Medium | High |
| 06 | 01 | High | Medium |
| 07 | 14 | Medium | High |
| 08 | 11 | Medium | High |
| 09 | 12 | Medium | High |
| 10 | 13 | High | Medium |
| 11 | 07 | Medium | High |
| 12 | 03 | High | Medium |
| 13 | 10 | Medium | High |
| 14 | 02 | Medium | High |

## Disposition

Keep P2-062 blocked: the selected baseline does not support the half-view, other-creature hiding or clipping parts of the defect, and partial trainer overlap is disputed. Keep P2-064 open: no reviewer confirmed rails crossing silhouettes in the three exact catalog states, while other sampled views drew mixed judgments. Both rows still need matched candidate views and any remaining listed sightings; no numeric impact is inferred.
