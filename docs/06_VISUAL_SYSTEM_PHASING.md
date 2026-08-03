# 06 — Visual System Phasing

**Scope note:** this doc covers rendering only — what the Meadows looks like.
It is not the list of game systems. Combat, catching, harvesting, crafting,
building, dialogue, and the Meadows Hall gym fight are gameplay systems and
they're built in the milestone order in `docs/05_ROADMAP.md`, gated by tests,
not a screenshot critic. The two orderings interleave: for example M2 in the
roadmap builds combat and catching logic, and this doc's system 5 ("pal
shading and readability") is the rendering slice of that same milestone, not
a separate thing. When in doubt, `docs/05_ROADMAP.md` is "what the game
does," this doc is "how the parts the player looks at get judged."

This is the checklist. `docs/02_ART_BIBLE.md` explains the critic-loop
mechanism and the style target; this doc is the literal order you work
through and the state of each system right now. Update the status table as
you go, this doc should always show ground truth for "what's actually
cleared its gate," not what's merely coded.

## The order

Sequential. Do not start system N+1 until system N has a sign-off entry in
`docs/archive/VISUAL_CRITIQUE_LOG.md`. This mirrors the real project this
process is drawn from, which built terrain, then vegetation, then lighting,
then structures, then water, then sound, then post-processing, strictly in
that order, and explicitly did not fan out in parallel across systems.

| # | System | What it covers | Depends on |
|---|---|---|---|
| 1 | **Terrain and ground shading** | Heightfield, ground `CustomProceduralTexture`, path/road stub materials | Nothing — this is the floor everything else stands on |
| 2 | **Vegetation** | Trees, bushes, grass, flowers, ThinInstance density | System 1's ground color, so foliage doesn't clash with what it's rooted in |
| 3 | **Lighting and atmosphere** | Sky CubeTexture, sun direction, ambient/IBL, fog, day/night transition | Systems 1-2 need to exist to judge lighting against, since lighting is judged on how it renders the world, not in isolation |
| 4 | **Buildings and camp structures** | Wood/stone piece materials, doors, snap-grid ghost preview | System 3's lighting, since building materials are judged under real light, not flat ambient |
| 5 | **Pal shading and readability** | Cel-shaded material, silhouette check at combat distance, idle/combat poses | System 3's lighting again, same reasoning |
| 6 | **Water** *(if in Meadows scope — a pond or river)* | Reflection, refraction, shore blend | Systems 1 and 3 |
| 7 | **Sound** | Ambient loops, footsteps, combat, UI | Independent of visuals — may run in parallel with system 5 or 6 once system 4 has passed, since audio can't visually clash with anything |
| 8 | **Post-processing** | Color grade, vignette, cheap bloom if free | Last, always — it's a global adjustment over everything else, so grading against an unfinished system 1-6 would mean redoing it |

## Per-system procedure

For whichever system is next in the table:

1. **Build it**, following the relevant technique section in
   `docs/02_ART_BIBLE.md` (procedural textures for 1/4, ThinInstance for 2,
   the sky-feeds-both-sky-and-IBL rule for 3, cel shading for 5, and so on).
2. **Capture.** Run `npm run capture` (the Playwright harness) to get
   screenshots specific to that system from fixed camera points.
3. **Spawn a separate sub-agent as the critic**, for this system only. It
   receives *only* the rendered screenshots plus the matching images from
   `docs/reference/`. It never sees source code, never sees this
   conversation or session history. It returns a 1-10 score and a specific,
   named fix list, not a vibe. See `docs/02_ART_BIBLE.md` for what counts as
   a usable critique versus a vague one.
4. **Fix what was flagged. Re-capture. Re-run the critic.** Loop until it
   signs off, or until improvement genuinely plateaus after several honest
   rounds — plateauing is a legitimate, logged outcome, not a failure to hide.
5. **Log it.** Append to `docs/archive/VISUAL_CRITIQUE_LOG.md`: system name,
   final score, round count, what got fixed, what's still weak if anything.
6. **Update the status table below.** Only then move to the next system.

Per `CLAUDE.md`'s development philosophy: if a system is taking too long to
clear its gate, the answer is to cut a different system out of the current
milestone, never to wave this one through under-baked. Time is the release
valve, not quality.

## Status

Update this table as each system clears. This is the single source of truth
for "is the Meadows visual pass actually done," not a memory or a feeling.

| # | System | Status | Score | Rounds | Notes |
|---|---|---|---|---|---|
| 1 | Terrain and ground shading | Not started | — | — | |
| 2 | Vegetation | Not started | — | — | |
| 3 | Lighting and atmosphere | Not started | — | — | |
| 4 | Buildings and camp structures | Not started | — | — | |
| 5 | Pal shading and readability | Not started | — | — | |
| 6 | Water | Not started / N/A | — | — | Confirm whether Meadows v0.1 includes a pond or river before this is reachable |
| 7 | Sound | Not started | — | — | |
| 8 | Post-processing | Not started | — | — | |

## When this runs again

Systems 1-5 (and 6 if applicable) run once seriously during `docs/05_ROADMAP.md`
milestones M0-M2. System 7 during M1-M2. System 8 and a full whole-scene
cohesion re-check run at M5, per `docs/02_ART_BIBLE.md`'s note that
individually-passing systems can still disagree with each other once
they're all on screen together — M5 is that check, not a first pass.
