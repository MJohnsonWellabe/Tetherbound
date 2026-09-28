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
  `P2-008/dunes-02-visual-judge.md`. Controlled render ablation is the next step.

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
