# Four-biome build checkpoints

## Checkpoint 0 — 2026-09-07

- Player-visible capability added: none in this checkpoint; the integration base
  was stabilized and landed before new content work.
- Paths newly reachable: none yet.
- Systems newly working in real play: hosted Stormwood combat now keeps the
  client's opponent stand-in synchronized to the host before each real attack,
  and the hosted multiplayer proof passes.
- Content added: none.
- Merged SHA: `7ab4a12647a377a400c43335b64aff8b03ca6d43` (PR #79).
- Evidence: final PR #79 CI run `34151037848` completed all 26 executable jobs
  successfully; the three non-executed jobs were intentional known-red/export
  skips. All seven multiplayer shards and solo regression passed.
- Blockers: the save rewrite, HUD map second-open behavior, and second-bed freeze
  still require their contract proofs before new biome content. Meshy spend is
  blocked because the supplied API key and credit ceiling are placeholders.
- Next highest-value task: run the SAVE, HUD-MAP, and STAB proof lanes in parallel,
  then integrate only evidence-backed results.

## Checkpoint 1 — 2026-09-07 14:32 CDT

- Player-visible capability added: the Settings debug-teleport catalogue now offers
  Meadows, Cloudreach Cliffs, Stormwood, and Water Archipelago, with two authored
  destinations in every named band, region, or island.
- Paths newly reachable: the menu can request no-key debug crossings among all four
  implemented realm scenes. The full production traversal smoke is pending the end
  of the freeze lane's timing-sensitive soak.
- Systems newly working in real play: the PR #80 scatter-freshness failure was fixed
  by rebaking the committed Meadows manifest after the vegetation change. The bake
  retained 825,979 placements and the focused freshness check passes 1/1.
- Content added: 58 curated test destinations across 5 Meadows bands, 6 Cloudreach
  regions, 6 Stormwood regions, and 12 Water islands. The fast catalogue/anchor
  contract passes 3 tests and 394 assertions.
- Integration head: `160c598f7`; pushed CI head: `9d4712497` on draft PR #80.
- Evidence: PR #79 is merged after all executable jobs passed. PR #80 rerun
  `34155697795` has entered its full matrix. SAVE and STAB agents remain active.
  HUD-MAP's automated rollback checks passed, but its first visual capture set was
  rejected because a foreground desktop window obscured the game; a capture-only
  replacement is in progress.
- Blockers: Meshy spend remains blocked by placeholder API key/credit ceiling. Full
  teleport traversal waits only to avoid contaminating the 180-second freeze soak.
- Next highest-value task: finish and integrate SAVE/STAB/HUD-MAP proof, execute the
  four-realm teleport smoke, then start ROAD and build-size lanes in parallel with
  the Stormwood/Water completion work.
