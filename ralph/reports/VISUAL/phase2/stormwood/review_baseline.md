# Stormwood retained-tile baseline

Method: independent `stormwood_visual_baseline` subagent, fresh context, images
and the repository `visual-judge` rubric only; no source, diffs, change narrative
or performance budget. Read the skill with `git show
HEAD:.claude/skills/visual-judge/SKILL.md` because sparse checkout omitted it.
Baseline checkout: `8a91b67e826dfe31d75d0fc515ece5feecacfb0a`; individual capture
provenance remains in `manifest.csv`. This review is triage, not fresh acceptance.

Inputs: `contact_sheet_time_and_weather_01.jpg`,
`contact_sheet_named_locations_04.jpg`, `contact_sheet_named_locations_05.jpg`;
both Stormheart stronghold boards, Meadows key art and all five
`docs/reference/palworld-0*.jpg` gameplay comparisons.

Independent verdict:

1. Finale landmark identity is lost. The Stormheart weather row and Dynamo-core
   location tiles are dominated by dark straight-edged surfaces; a branching
   silhouette, living crown and illuminated vertical core are not readable.
2. Four weather phases do not separate at tile size. Nearly identical purple
   skies, dark ground and rain retain the biome mood but do not identify phases.
3. Dark obstruction and compressed values dominate Dynamo and Crown Arch
   approaches; references preserve subjects, clearings and layered distance.

Bar A: **NO** for these views. Purple storm identity survives, but tree identity
and phase differentiation do not. Bar B: **NO** for scoped scene presentation and
readability against the actual Palworld frames. This does not require copying
their daylight palette.

Limits: retained pictures are 320x180 tiles. They cannot establish surface
finish, motion, lightning timing or transitions. Unseen crown/core features are
a presentation failure in these frames, not proof that geometry is absent.
P2-042 remains `needs_capture`; P2-037 remains open. No criterion closes.
