# Owner directive — systems are good; shift primary focus to content and visuals

**Owner call, 2026-09-19, verbatim:** "I think the game plays well as far as
systems go. We should primarily be focused on content throughout the map and
how the game looks."

This is a priority shift, not a reopening of `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`'s
sequencing (Meadows first) or `OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`'s
lane structure. It changes what kind of work each lane reaches for next.

## What this means concretely

**Deprioritized: net-new mechanical systems work.** The clearest example is
`docs/specs/COMBAT_DEPTH_PLAN.md`'s ladder beyond what's already decided.
COMBAT-1 through COMBAT-3 (poise/stagger, creature wind, the telegraph retune
and burst-step dodge) were already approved by the 2026-09-12 playtest and may
already be in flight — finish those if in progress, don't abandon mid-repair.
**Do not start COMBAT-4 through COMBAT-7** (the Y-skill/learnsets, AI reactions,
widened type chart, the authored early-fight ladder) or any other comparable
net-new system (new building mechanics, new progression systems, new UI
systems) unless a real, reported bug requires touching that code. The owner's
read is that the systems layer is good enough as it stands.

**Correctness and verification work is not "systems work" and continues
unaffected.** Bug fixes, the Gate F continuous-campaign proof toward Meadows'
A0–A11, save/multiplayer reliability, and CI health are confirming that what
already exists works — they are not new mechanical scope, and this directive
does not pause any of them. The Meadows lane's current village-passage repair
and campaign replay continue as planned.

**Primary new work, once current repairs land, is content and visuals:**

- **Content throughout the map** — `docs/acceptance/MEADOWS_EXIT_CRITERION.md`
  category G (optional activities at 6-10 density, every detour pays into
  preparation, genuine roster temptation per region) and the off-path draws
  named in `OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` Tier 3 (distant
  villages/glows/creature clusters visible from the path, NPCs who tell you
  where things are). The Tier 1 wayfinding items in that same directive (the
  beacon system, map markers, NPC-driven map reveals) are content-delivery
  infrastructure, not systems depth — they stay in scope, because they are
  how the player finds the content this directive asks for.
- **How the game looks** — categories B (creatures), C (NPCs/human cast), D
  (terrain/world), E (locations), J (one deliberate game, the Palworld/key-art
  bars) in the same exit criterion. This is exactly what the Cloudreach lane
  (`docs/CODEX_GOAL_2026-09-19_CLOUDREACH_VISUAL_PRODUCTION.md`) is already
  scoped to — no change needed there, this directive confirms and reinforces
  that scope rather than altering it.

## For the next session picking up either lane

Read this directive alongside the newest handoff. If you find yourself about
to design a new mechanic or expand an existing system's depth, stop and check
whether it's fixing a reported defect (fine) or adding new capability (hold,
unless the owner asks for it specifically). If in doubt, default to content or
visual work instead.
