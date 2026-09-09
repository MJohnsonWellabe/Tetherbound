# Shared night grade — held after two-location review

Candidate: only `data/config/art.json` night environment adjustment_contrast
1.08→0.92, plus an explanatory JSON comment. No other production source change.
Both production catalogue captures exited 0, completed 2/2 frames at1280x800,
and had no ERROR/SCRIPT ERROR. All287 protected import hashes remain unchanged.
Candidate JSON and patch are retained in `.artifacts/shared-night-floor-candidate-0909.*`.
The production file was restored to its pre-candidate value after the verdict.

Matched pairs:

- Meadows baseline `shots/catalogue/meadows/round-ridgeline-night-shadow-20260909T1500Z/`;
  candidate `shots/catalogue/meadows/round-shared-night-floor-20260909Tcandidate/`.
- Stormwood baseline `shots/catalogue/stormwood/round-shadow-contract-20260909T1418Z/`;
  candidate `shots/catalogue/stormwood/round-shared-night-floor-20260909Tcandidate/`.

Each contains the named location's day/night pair. Source/manifests retain the
same player positions, weather/time/shadow controls; camera differences are
under0.000002m. Live creature poses/placement are not an isolated controlled
variable, so creature differences cannot be attributed to grading. Day serves
as an unchanged-condition control, not a night baseline. Raw logs:
`.artifacts/shared-night-floor-{meadows,stormwood}-0909-engine.log`.

Two separate fresh Astra judges received neutral copies F01–F04, the unchanged
visual-judge skill and actual keyart/Palworld references only. Neither received
source, desired outcome, prior verdicts or chronology. Each used all eight rubric
categories and answered A/B separately. F01/F02 map to baseline day/night;
F03/F04 to candidate day/night. Summaries below preserve their decision limits.

## Meadows judge receipt — /root/judge_meadows

1. Readability: trainer/tree masses survive reduction; creatures remain jagged
   unidentified forms, plants dissolve into noise, trainer legs disappear at night.
2. Colour/value: consistent grassy identity but harsh olive/lime/red competition;
   nights compress playable space into dark values. Danger-colour usage unproven.
3. Intentionality: grove/open-centre structure exists, but uniformly repeated
   shrubs and filament grass read as distribution rather than authored clearings.
4. Lighting: F04 retains more ground/grove information than F02, a navigation
   advantage, but both lose trainer lower-body separation. Graphic moon/clouds.
5. Depth: limited layering, low horizon and no strong destination silhouette.
6. UI: safe margins/legible quest; oversized empty slots and bright panels compete
   with the dark player; footer/health hierarchy weak.
7. Artefacts: stippling and broken vegetation edges; feet obscured, no proven
   penetration/z-fighting or motion conclusion.
8. Scale: shrubs/trees broadly plausible against1.80m trainer; differing depths
   and unidentified creature roles prevent precise creature-scale conclusions.

Top gaps: creature identity/appeal; authored meadow vegetation; destination/depth.
Scene, staging and material changes can help; expressive art might be needed,
but the judge did not inspect asset inventory. **A No; B Yes for genre only**,
explicitly not shipping-quality acceptance. Static evidence cannot establish
animation, traversal, performance or combat.

## Stormwood judge receipt — /root/judge_stormwood

1. Readability: trainer/trunks/boulder remain identifiable, legs merge into ground;
   no compelling central destination or visible creatures.
2. Colour/value: green canopy over muddy olive floor; pale vegetation and red
   undergrowth compete; danger semantics of red shrubs cannot be inferred.
3. Intentionality: some base clustering, but repeated trunks over a sparse floor
   read as a placement demonstration rather than a purposeful space.
4. Lighting: F04 lifts dark environment values relative to F02 but reduces shadow
   depth. This is a visibility/atmosphere tradeoff, not an unqualified improvement.
   Day F01/F03 has no confidently distinguishable material advantage/regression.
5. Depth: sparse, speckled distant band terminates the forest abruptly.
6. UI: safe margins and readable objective; empty panels consume scene space,
   tiny keycaps and weak health/food contrast; flat-green map lacks visible context.
7. Artefacts: distant stippling, blurred perspective ground, outlined leaves,
   awkward dark cloud streaks; no definite z-fighting or motion judgment.
8. Scale: mature trees/boulder plausible against trainer; oversized-looking
   mushrooms are not inherently invalid; no creature role-scale evidence.

Top gaps: character/creature presence; inhabited landscape; depth/atmosphere.
Scene/terrain/lighting first; unseen assets cannot be declared inadequate from
these views. **A No; B No.** No shipping-art, motion or performance acceptance.

## Disposition

Hold. The shared setting does not establish the intended legibility improvement
across both locations without a lighting tradeoff, and the trainer issue remains.
No third value-tuning capture is scheduled. Restore1.08, retain evidence and move
to a distinct cause (subject separation or terrain/value structure), not another
blind contrast adjustment. This is neither a whole-biome verdict replacement nor
a reason to stop earned-content work.
