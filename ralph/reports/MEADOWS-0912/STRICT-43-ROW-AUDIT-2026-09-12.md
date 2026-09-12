# Meadows 09/12 strict 43-row acceptance audit

**Audited revision:** `e0db2f860e61e7edb3e85201edbbb39829eca0d3`

**Scope:** the 17 Tier 0, 7 Tier 1, 12 Tier 2, 2 Tier 3 and 5 Tier 4
rows in `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`.

**Mode:** static reconciliation only. No Godot, capture, import, bake or network
process was run for this audit.

## Strict result

| State | Rows | Count |
|---|---|---:|
| Complete | T0 `1,3,4,5,6,7,9,10,14,15,16`; T1 `2,3,4`; T2 `11`; T3 `2` | **16** |
| Source-complete, awaiting runtime and/or visual acceptance | all rows mapped below | **27** |
| Missing production source | none | **0** |
| Total |  | **43** |

This preserves the strict distinction between an implementation, an instrument
capable of producing evidence, and accepted evidence. A committed smoke or capture
harness is not itself completion. A mechanically complete manifest without a visual
judgment is also not visual completion. A prior FAIL/HOLD stays open after a source
repair until the repaired production view is recaptured and accepted.

## Count reconciliation

The last exact acceptance audit recorded in
`ralph/reports/FOUR-BIOME-BUILD/checkpoints.md` counted **15 Complete, 24 Partial and
4 Untouched**. Checkpoint 2 records that the four genuine production-source gaps were
then implemented by the route/overlook pull, Warrens approach, Relay and Stonewater
slices. That changes the source classification to **15 Complete, 28
source-complete-awaiting-evidence, 0 missing-source**; it does not make those rows
accepted.

After that checkpoint, the standalone production
`tests/smoke_meadows_route_prompt_nessa_0912.gd` run passed without an ERROR
diagnostic: both placed prompts traversed their production dialogue/effect paths once,
retired to fallback, and their personal flags plus Nessa's berry gift survived a
Game save/load without replay. This closes the remaining runtime gate for T1 #3 and
is the only acceptance promotion in this reconciliation: **16 / 27 / 0**.

The later harness commits are counted accurately but conservatively:

- `9f5b39c5a` adds the full-satchel production smoke; it has not earned a clean run.
- `27195c07a` adds the cleared-cluster cooldown production smoke; it has not earned a
  clean run.
- `d6f7e0ebf` adds the map/teleport/pin production acceptance smoke; it has not earned
  a clean run.
- `b68b5e18a` hardens the riding smoke; the current `final-riding-01` manifest is
  incomplete at 0/6.
- `15e5a2fe0` adds the real Terrapup rest/companion-formation capture; it has not run.
- `e0db2f860` adds the four-treatment banner capture; it has not run.

## Remaining gates, disjoint row mapping

| Gate bundle | Owner rows | Exact remaining proof |
|---|---|---|
| Companion formation and rest | T0 #2, #13 | Run the production companion/Terrapup capture; accept beside-not-behind camera clearance and the real grounded Lay/rest state in day/night frames. |
| Stateful production smokes | T0 #8, #11 | Clean runs of the new respawn-cooldown and full-satchel pickup smokes, including cooldown/load and all configured pickup-path feedback. |
| Riding mechanics and appearance | T0 #12; T2 #7 | Rerun the hardened riding smoke and produce the currently missing 6/6 riding frames; accept saddle/back and rider/seat contact together. |
| Map, teleport and remote-map behavior | T0 #17; T1 #5; T4 #1 | Clean map-interaction run covering collapsed biome sections, personal persistent pins, repeated open/rebuild, and a same-realm second-player marker. |
| Objective and off-path visual read | T1 #1, #6, #7; T3 #1 | `final-wayfinding-pulls-01` is mechanically complete at 12/12 but unjudged. It needs strict review of the objective beam, Long Field signal, south-trail creature sightlines and off-path draw; repair/recapture any failed view. The Nessa gift's runtime half is already proven. |
| Opening-village composition | T2 #1, #2 | The 14/14 `final-village-03` set was independently FAIL. Production was repaired and rebaked afterward; a fresh bidirectional street/Mira/crest day-night recapture and acceptance are required. |
| Remaining Meadows visual/story repair set | T2 #3, #4, #5, #6, #8, #9, #10, #12 | Bramblebun has unreviewed comparison pixels. Banner evidence has not run. Warrens, Stonewater and Relay have independent FAIL/HOLD reports followed by production repairs, so need fresh required views and judgment (plus their bounded traversal where specified). Ironwood remains HOLD on night fissure dominance/workyard integration and needs the Juno/Halder story smoke. Far-country prominence and thin-woods variation still need production visual acceptance. |
| Multiplayer identity and fresh-join flow | T4 #2, #3, #4, #5 | Clean title/name path plus serialized two-peer proof that each trainer's chosen name/body replicates, the compact badge reads correctly, a fresh join starts in Grandpa's Village, and the late arrival receives exactly one starter. |

The eight bundles contain `2 + 2 + 2 + 3 + 4 + 2 + 8 + 4 = 27` distinct rows.

## Evidence cautions that affect scheduling

- The current independent visual reports are authoritative for the pixels they judged:
  `final-village-03` FAIL, `final-warrens-01` HOLD, `final-stonewater-01` FAIL,
  `final-relay-01` HOLD and `final-ironwood-01` HOLD. Later source changes do not
  retroactively change those verdicts.
- The route/pulls and Bramblebun directories have complete capture manifests but no
  retained independent acceptance report. They are ready for judgment, not complete.
- Banner and companion/Terrapup now have bounded production capture tools, but no PNG
  or complete manifest from those tools exists at this revision.
- The current riding output explicitly says `complete: false`, expected 6 and captured
  0. It cannot be used as visual evidence.
- No missing-source row remains. The critical path is now execution, judgment, repair
  after genuine visual failures, serialized multiplayer/runtime proof, and finally the
  full Meadows regression/campaign package—not more speculative feature authoring.
