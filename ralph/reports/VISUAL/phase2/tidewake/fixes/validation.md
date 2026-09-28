# Tidewake Phase 2c — validation evidence

Local Windows Godot 4.7 stable (`5b4e0cb0f`), four headless unit shards using
separate scratch APPDATA directories. Main prerequisite was merged at
`2e13ba43f9cd549e6eeb47ea2654d654f014e381`; the full suite started from the first
dune candidate. Subsequent bounded changes received the focused checks below.
These checks establish implementation invariants, not visual acceptance.

| Check | Observed |
|---|---|
| Unit shard 1/4 | 1346 tests, 247648 assertions, one missing-evidence failure |
| Missing-evidence confirmation | Restored four tracked historical Meadows evidence directories omitted by sparse checkout; reran the sole failing `test_final_polish_locations_have_complete_accepted_evidence_rounds`: 1 test, 16 assertions, 0 failed |
| Unit shard 2/4 | 1194 tests, 2607820 assertions, 0 failed, exit 0 |
| Unit shard 3/4 | 1307 tests, 156613 assertions, 0 failed, exit 0 |
| Unit shard 4/4 | 1402 tests, 948984 assertions, 0 failed, exit 0 |
| Dune cover and named-character clearance | 9 tests, 69 assertions, 0 failed |
| Dune colonies, shared groves and clearance confirmation | 15 tests, 129 assertions, 0 failed, no script errors; supersedes a misleading earlier 10/70 summary whose new material test aborted on null dummy-renderer defaults |
| Offshore material isolation | 2 tests, 12 assertions, 0 failed |
| Current field and visual-state preservation | 14 tests, 169 assertions, 0 failed; subsequent shader-only length correction retains authored restored short-dash response and still requires native motion review |
| Water decorative bedding | 3 tests, 46 assertions, 0 failed |
| Capture displacement rejection | 2 tests, 6 assertions, 0 failed |
| Human swim pose | 7 tests, 115 assertions, 0 failed |
| Human surface contact | 7 tests, 46 assertions, 0 failed |
| Veilfall far decorative geometry | 2 tests, 16 assertions, 0 failed |
| Shiny gate scope | 2 tests, 36 assertions, 0 failed |
| Combat roster lifecycle | Live child: 208 assertions; outer test: 1 test, 5 assertions, 0 failed |
| Appearance/dune/ground profiles/texture policy | 14 tests, 656 assertions, 0 failed |
| Creature viewport framing | 13 tests, 38 assertions, 0 failed |
| Art smoke | Models loaded, sized and dressed; exit 0 |
| Dune atlas derivation | Offline deterministic derivation check passed; source alpha/neutral pixels retained, source atlas unchanged |
| Capture scripts | Parser checks passed for dialogue interaction, filtered creature poses and location stand validation |
| Rooted dune mesh, grass profiles and supported capture stands | 34 tests, 87947 assertions, 0 failed; no script errors in `.local/phase2/dune-shape-support-focused.log` |
| Victory hierarchy candidate | Root confirmation at 720p: 99 headless HUD lifecycle checks, PASS; `.local/phase2/victory-hierarchy-720-confirm.log`. Independent source review clean; native comparison pending |

The full shard run totals 5249 test methods and 3961065 assertions. The single
missing-evidence failure was confirmed resolved by its targeted rerun; this is
not presented as a second whole-suite run. Logs remain local in
`.local/phase2/`. Expected negative-path diagnostics, off-tree transform warnings
and dummy-renderer resource leak diagnostics occur in the suite; “0 failed”
does not mean a clean engine-error log.

## Native evidence and independent review

- P2-008 first weathering round: 24 before/24 after images; independent PARTIAL,
  chapter Bars A No/B Yes. Candidate disabled.
- P2-008 first dune round: 24 written images; independent FAIL, Bars A No/B No.
  Salt Crown walk02/03 contain displaced/respawned player observations and are
  invalid paired evidence despite matching commands. See `P2-008/dunes-01-visual-judge.md`.
- P2-008 second dune diagnostic pass: four of four island views passed the new
  displacement checks, native Compatibility GTX 1060 3GB, actual root/image
  1920×1080, source `aaaa04a43bca987c36458c50efcbf9deae2a5c90`. Both dune gates
  were enabled for capture and restored false. Independent PARTIAL, limited
  Bars A No/B No: palette and trainer readability pass; banding, jagged shading,
  diffuse grass and weak sheltered woodland remain. See
  `P2-008/dunes-02-visual-judge.md`. Subsequent controlled render ablation is
  recorded below.
- Three controlled surface/shadow rounds completed 5/5, 6/6 and 6/6 native
  frames with exact camera matches. Texture-detail removal did not fix bands;
  terrain-only 0.05 m caster-depth offset did at Gull Rest while retaining the
  trainer shadow. See `P2-008/{surface,shadow,receiver}-01-ablation/`. The gated
  implementation compiled in the subsequent dunes-03 native island/route run;
  steep bluff shading remains a visible concern.
- Shared grove placement uses actual upwind terrain relief with unchanged
  gameplay clearances. A placement-only probe and native scene report 73 groves
  across eleven candidate islands, 426 trees and 339 shrubs. Counts establish
  placement, not art acceptance. Veilfall's static mountain vegetation/authored
  groves and separate terrain treatment remain excluded; the shared
  camera-relative grass profile can affect eligible flat Veilfall grass.

- Dunes-03 source `8f4cb049d`: four location and three route images passed
  native validation, seven of eight required sightings. Brine Steps walk03
  failed with 5.56 m drift, matching its invalid old baseline exactly. A new
  physically supported before/after pair is required. See
  `P2-008/dunes-03-capture-validation.md`. Independent dunes-03 review confirms
  the direction, but item acceptance remains incomplete and limited Bars A/B
  are No/No: sand-coated sheer banks, rigid pale grass strips, jagged shading
  and weak destination/creature composition remain.
- Dunes-04 source `0930716ac`: all sixteen native 1920×1080 images complete,
  eight fresh before/after pairs covering all eight required sightings. Raw and
  compact manifest metadata and SHA-256 hashes match; all four compact rounds
  verify. Player positions match exactly; maximum camera drift is 0.000011445 m.
  Brine Steps walk03 rejects six candidates in each run and selects the same
  supported shallow-water land stand at offset 12 m/lateral 0 m. The fresh pair
  replaces its invalid old baseline; optional Salt Crown walk02/03 remain
  excluded. Independent item PARTIAL, surface direction PASS, ecology/transitions
  PARTIAL, limited Bars A/B No/No. Angular bank boundaries, smooth steep forms,
  regular grass colonies and weak midground/ecological layering remain. Both
  gates are off. See `P2-008/dunes-04-{capture-validation,visual-judge}.md`.
- P2-032 selected-realm styling is fixed/enabled by `8c5009e09` after MAP-01:
  six native boots / 24 actual 1920x1080 frames on source `0930716ac`, with
  only the temporary config gate changed before/after. Explicit Meadows and
  production-realm selections pass independent visual judgment and strict item
  recheck across all three affected realms. Prior and actual enabled tests each
  pass 8 methods / 36 assertions, no errors; independent source review is clean.
  See `P2-032/map-01-{validation,visual-judge}.md`. No chapter bar acceptance.
- P2-103 victory hierarchy candidate `0930716ac` remains off. It identifies the
  persistent five-slot bar as QUICK ITEMS, separates exact reward receipts from
  growth rows and keeps receipt-bearing cards gold. TEAM counts remain occupied
  roster slots, including KO members, rather than available-fighter counts.
  Root-confirmed headless 720p lifecycle passes 99 checks and independent source
  review is clean; native Venn/Nerissa win/aftermath comparison is outstanding.

Independent source reviews found no remaining issues in named-character grass
clearance, Water offshore material isolation and decorative bedding. The current
review found a lost restored short-dash cue, corrected in `ad6eccc5c`. The normal
dialogue capture review found save isolation, camera identity and manifest-error
handling issues; fixes are included in `f0012d3d0`, with a passing parser check.
These source reviews do not replace the required native item and chapter judges.

No new visual candidate is accepted or enabled by this report. The full chapter
matrix, native paired item reviews, 720p stress rasters and CI landing remain
separate outstanding requirements. Device evidence is computer capture, no Ally
hardware; fixed-frame recording cannot establish real-time performance.

Scoped independent review at `0930716ac` found no actionable source findings in trainer swim posing, human water contact, creature shiny overrides, compact party strip and capture reticle, including their five disabled config gates. Disabled paths preserve prior rendering; enabled paths contain no gameplay-state, velocity, collision, input, catch-chance, save or network mutations. These shared component flags are not restricted to Tidewake. Native acceptance remains outstanding.

Landing source review through `e22fdbcb2`: independent review of the remaining
production appearance changes from origin/main found no actionable issues in
Water vegetation, gated materials, bedding, named-character clearance, far
crags, world bindings or the current shader/configs. Disabled paths remain
unchanged; no gameplay, collision or encounter mutation was found. The new
grass/mineral patch also passes source review and focused tests 35/87970
(`.local/phase2/dune05-focused.log`). This source review does not claim native
visual acceptance; dunes-05 remains off pending capture and judgment.
