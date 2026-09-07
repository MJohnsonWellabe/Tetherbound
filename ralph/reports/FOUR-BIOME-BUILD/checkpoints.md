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
