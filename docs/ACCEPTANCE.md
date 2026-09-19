# Tetherbound — Acceptance

**What this is.** What "done" looks like, concretely enough to check against.
It replaces `acceptance/MEADOWS_EXIT_CRITERION.md`, the visual
acceptance-by-domain directive, the Gate F protocols, `VISUAL_PROGRESS_SCORECARD.md`
and the per-biome exit criteria scattered through the old `BUILD_*` briefs.

**How to use it.** This is not a task list to clear top-down. It is the standard
the work is measured against. A row closes only with **evidence of the kind
named beside it**, and a newer owner reproduction reopens any row a ledger says
is closed.

`STATE.md` records which rows are currently open. This file records what the
rows are.

---

# 1. The one-sentence test

> A fresh player wakes in Grandpa's house, plays through to freeing the
> legendary, and — through their actions, not a survey — demonstrates every
> statement in §2.

Everything else on this page exists to make that outcome reachable.

---

# 2. The player-voice acceptance (A1–A11)

These are the finish line for a chapter. Each must be true of a real player's
behaviour, not of a config file.

| # | The player should be able to say | Verified by |
|---|---|---|
| A1 | I understood what I was trying to become strong enough to do | objective clarity at every band, in a continuous run |
| A2 | I cared which creatures made my five | roster pressure observed before the legendary |
| A3 | I repeatedly found reasons to fight, catch, explore, gather and prepare | activity cadence; no dead stretches |
| A4 | Building and rest mattered because they supported the journey | rest/injury decisions actually taken in play |
| A5 | Different parts of the region felt like distinct real places | per-band identity; blind judge |
| A6 | I was tempted off the direct route | optional discoveries taken voluntarily |
| A7 | I did not spend long periods running through empty scenery | dead-travel interval measurement |
| A8 | My team at the end felt earned and different from my team at the beginning | roster diff, start vs. end |
| A9 | The boss felt like the culmination of the chapter | climax difficulty and identity |
| A10 | Freeing the legendary and choosing the final five mattered | release ceremony carries real history |
| A11 | The world looked changed because of what I did | post-climax healing visible |

---

# 3. The evidence bar

The standard is **tests pass + it actually ran + a screenshot if it's visual.**
Not a research project per change.

| Kind of change | What counts as evidence |
|---|---|
| Logic / data | the named tests pass, with the exact command and counts |
| A player-facing behaviour | a smoke or probe that exercises the real path, not a config assertion |
| World / spawn / creature / encounter code | plus a world boot (`smoke_playground.gd`) grepped for `^ERROR:` |
| Anything visual | plus a real shipping-build capture, day and night where relevant |
| A **big** visual pass (a whole domain, a named location, a creature's identity) | plus a **code-blind judge verdict** — see §4 |
| Save format or autoload | plus the full unit suite |

**Two rules that were learned expensively and are not negotiable:**

1. **Evidence that does not show the shipping game is worse than no evidence.**
   A capture harness once produced frames with no grass geometry and haze the
   build does not have, and a share of "verified" visual work was judged against
   a game that wasn't shipping. No row closes on a frame that hasn't been
   sanity-checked for real grass, real lighting and real geometry.
2. **Config-level assertions and passing tests are not evidence a player can
   reach a thing.** A played path is.

---

# 4. Visual acceptance

## 4.1 The two bar questions

Every blind judge answers both, every time. They decide pass/fail and are never
replaced.

- **Bar A:** do these frames read as belonging to the world in
  `docs/reference/tetherbound-meadows-keyart.png`?
- **Bar B:** shown beside `docs/reference/palworld-0*.jpg`, would someone say
  these are trying to be the same kind of game?

## 4.2 How judging works

Only a **code-blind** critic judges. Render real frames, hand the critic the
frames, `docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, and tell
it **nothing** about what changed or what you hope it says. It scores nothing.
It names addressable defects per frame, ranks the three biggest gaps to the
references, and answers both bar questions.

Rubric axes: silhouette and readability at small size; colour and value
structure; intentionality (authored vs. generator output); lighting; horizon and
depth; interface; artefacts; scale agreement — **the trainer is 1.80 m and is
the ruler in every frame**.

Two things the critic must never be told: **the performance budget** (a critic
looking at pictures judges pictures; frame time is measured with a profiler on
the Ally) and **what changed** (that produces agreement, not criticism).

Frames from a Linux container use the Compatibility renderer under software GL:
trust composition, silhouette, colour relationships, scale and geometry; do not
trust fine lighting or post-processing.

**When to run it.** On a big visual pass — a whole domain, a named location's
identity, a creature's look. Not on every small fix. A small, obviously-correct
visual fix ships on a before/after capture.

**Stopping rule.** Two consecutive rounds that name no new defect and move no
measured axis means a ceiling under the current mechanism. Record the ceiling
and the mechanism; do not run a tenth tuning round. Four chronic visual items
each failed 3–5 tuning rounds and were then fixed by a clean restart that
root-caused them. **Tuning rounds are not progress.**

**Prove by number** — crop medians, luminance, pixel-diff percentages — decided
*before* the render, not chosen afterwards to fit the result.

**Weigh a critic's finding against owner intent before acting.** The critic once
shrank the starters because a rubric said the human should dominate the frame.
The owner wants creatures to loom.

## 4.3 Domains, in order of impact

Work top to bottom. These are the priority order, **not** lane boundaries — lanes
split by *system* (one terrain/scatter pipeline underlies terrain, vegetation,
cliffs and ground; one sky/weather shader underlies sky and storm; one creature
material pipeline underlies every creature), and a shared-system lane stays one
lane.

Each domain names supplementary comparison games. These are **comparison
points, never a new pass/fail bar and never something to copy.** Every verdict
states which comparisons were bar questions and which were supplementary.

**1. Creatures** — the game is named after them.
*Supplementary: Pokémon for face/eye legibility at thumbnail size; Monster
Hunter Stories / Cassette Beasts for a stylised companion reading clearly beside
a human.*
- Mipmaps generated on every species' active albedo.
- The scale ladder holds per species against the 1.80 m trainer ruler, grown
  never shrunk.
- No combat-ready silhouette fills enough of the fight camera to make targeting
  or reading the opponent impossible — a runtime space check, not a static one.
- Habitat contrast **≥ 1.5:1** value/hue against local ground, day and night,
  every biome.
- A fresh blind judge can locate and describe an eye/face region without hedging.
  "An orange mass with turquoise scrapes" is a fail.
- No floor-contact or clipping in any authored pose.
- Every creature reads as a **distinct designed animal**, not a retint.
- Rarity is legible on sight — common / uncommon / rare / alpha differ in
  presentation, not just in a stat block.
- Creatures sit correctly in the world: on the ground not embedded in slopes, at
  correct depth in water, with contact shadows so they aren't pasted on.
- Silhouette reads at **gameplay** distance, not only in a close crop.
- Every species that exists in data is reachable in play. Built is not done.

**2. Characters** — the player's constant on-screen identity.
*Supplementary: BOTW/TOTK for silhouette and colour-blocking that read instantly
at any distance — that clarity, not anime-adjacent polish, is the register.*
- Trainer identity reads as distinctive at a glance: silhouette plus 2–3
  colour-blocked regions.
- Named NPC hair/face/clothing stays legible at gameplay distance; no blown-out
  white patches replacing hair shading.
- NPCs read as **people in clothing**, never silhouette cutouts.
- **Rank is readable** — grunt vs. officer vs. captain vs. Warden, on sight,
  without a nameplate.
- The cast is varied enough that the region feels populated rather than six rigs
  repeated — achieved through material and variant work, not new meshes.
- Named characters are visually individual and match their story weight.
- Oxblood/red reserved for Team Tether, verified by direct pixel sampling.

**3. Terrain and ground** — the base of every frame.
*Supplementary: Valheim for material transitions at close range; BOTW for ground
material communicating walkable path vs. off-path — value and texture change at
path edges, not just colour.*
- Every biome shows a real material transition at close range, never one
  repeating tiled texture reading as a blurred smear.
- The region **does not read as a flat green test environment** — the oldest
  standing complaint.
- No biome's ground reads less resolved than the Meadows'.
- No visible terrain seams.
- Aerial perspective gives distance real depth, as a terrain-material gradient
  (fog was tried and rejected).
- Day / night / golden hour / weather are all attractive and readable.

**4. Vegetation** — the single most-cited defect across every review.
*Supplementary: Valheim and BOTW for clustering; Grounded for dense stylised
foliage that still reads as legible layers rather than noise.*
- All three layers present in every biome: ground cover, mid-layer
  (bush/sapling/rock line), canopy.
- Vegetation reads as clustered and authored, never evenly spaced.
- Trunk-to-canopy ratio moves toward a real broadleaf's (~1:9) from the current
  ~1:3.
- Open fields are attractive **without clutter** — interest from terrain shape,
  silhouettes, herds, outcrops, ruins and weather, not asset spam.

**5. Sky, clouds and atmosphere** — always visible, and currently the thing that
works.
*Supplementary: BOTW/TOTK and Genshin for painterly cloud banks and a clear
day/night mood shift without expensive volumetrics.*
- **Preserve what already passes.** Do not regress the painted clouds or the
  golden-hour/night mood while fixing anything else.
- Distant terrain does not wash out via aerial-fade colour coupled to fog.
- Night does not crush the trainer's legs and lower body to black in any biome.

**6. Water.**
*Supplementary: BOTW for stylised shading with no reflections (the same
constraint — no SSR on Compatibility); Subnautica for keeping a mounted or
nearby creature legible against open water.*
- The converged water shading (8 blind-judged rounds, no reflections by design)
  stays untouched. Do not reopen a closed, deliberate ceiling.
- No unshaded alpha-plane water surfaces.
- A river reads as a **river, not an engineered canal**, and a stream is visible
  from its own bank.
- Coastal landmarks read as built destinations, not isolated placed objects.
- Swimming, solo and mounted, keeps trainer and creature visible at the surface.

**7. Storm and lightning** — Stormwood's identity.
*Supplementary: Genshin's Electro/storm weather for a stylised flash and ambient
charge at this render budget.*
- Storm weather has a **visible delta** from clear weather.
- Danger-coloured undergrowth either means something real or gets desaturated;
  ambiguous colour competing with the trainer for attention is a defect.

**8. Cliffs** — Cloudreach's identity.
*Supplementary: BOTW/TOTK's Hyrule cliffs for stylised strata, readable
silhouette from distance, believable scale beside a person.*
- Cliff silhouettes read as distinct landforms at distance, not a repeated
  patterned wall texture.
- High perches and stands pass a **corrected-camera** capture — fix a below-floor
  survey camera before re-judging the content it was pointed at.

**9. Strongholds and biome finales** — lowest frequency, highest peak impact.
*Supplementary: BOTW/TOTK shrines and Palworld towers for a finale reading as a
held, defended place from its approach.*
- The finale silhouette reads at **400 m and again at 100 m**.
- Important structures look deliberately authored.
- Team Tether presence visibly changes the land — pylons, hardware and drained
  ground escalating toward the stronghold.
- No finale renders as a bare or placeholder frame.
- Interiors and dungeons read as **places, not corridors**.

**10. Other named locations** — landmarks, camps, waycamps, hollows.
*Supplementary: BOTW towers and Palworld bases for "every marked destination has
a built approach."*
- Every location in the debug-teleport catalogue has a built approach and local
  dressing.
- Major landmarks orient the player: they can answer "where did I come from /
  where can I go / what region is this / what looks optional" without the minimap.
- Paths, settlements and water edges integrate — no props standing in ponds, no
  signs in travel lanes.
- Sweep for blank-panel-class defects as a **class**, not one at a time.

**11. Riding, swimming and flying.**
*Supplementary: BOTW for mount silhouette at speed and landmark readability from
altitude; Palworld for mounted-flight companion readability.*
- Every rideable species keeps a readable mount/rider silhouette **in motion**,
  not just standing still.
- Flying preserves landmark readability from altitude — the same underlying
  cliff/terrain silhouette work as domain 8, not a separate art pass.

**12. Placed items and props.**
*Supplementary: Stardew and Animal Crossing for object silhouette clarity at a
glance.*
- No object reads as an unfinished placeholder — flat unshaded plane, blank box
  — in any authored scene.
- Signposts, banners and structures use installed kit geometry, never a
  `Label3D` or box-mesh stand-in.
- The campsite kit is coherent: one art family, one sense of scale, no
  interpenetrating props.

**13. Gatherables and consumables.**
*Supplementary: Stardew and Genshin for at-a-glance identification before a label
is read.*
- Visually distinct enough to identify by silhouette and colour at pickup range.
- No regressions to interaction height or reach.

**14. Tools and held items.**
*Supplementary: Monster Hunter and Zelda for equipped-gear silhouette clarity.*
- Equipped tools and gear read clearly on the trainer at gameplay distance.

## 4.4 Root-cause discipline

Before fixing anything above, decide whether the defect is **local** (one asset,
one location) or **systemic** (a shared material, shader or pipeline many things
read from). If the same defect class appears in more than one domain, the fix
belongs to the shared-system lane, not to repeated per-domain patches. State
which kind it is, per finding. After a systemic fix, **re-run the judge against
every previously reviewed subject that showed that defect class**, not just the
one it was found on.

## 4.5 The per-biome named-location ledger

Each biome keeps one ledger of its named locations, each graded **PASS /
POLISH / FAIL / unknown** on the latest accepted production capture and
independent verdict. The live grades are in `STATE.md`.

Rules that keep the ledger honest:

- A grade comes only from a completed capture plus a fresh code-blind verdict.
  **An unseen source candidate does not change a grade.**
- Do not stack a new art change on top of a queued capture — it erases the
  ability to attribute the result to the repair already waiting for evidence.
  Serialize: capture, judge, then edit.
- Residual shared polish (mottled ground, simple camp materials, a cool crushed
  night foreground) is **non-blocking** and is not a reason to reopen a row.

---

# 5. Content acceptance

## 5.1 Density and payoff

- **6–10 optional activities per major region.** Count from real game data, not
  from a remembered number.
- **Every detour pays** into preparation with at least one of: XP, bond, a catch
  opportunity, useful materials, a TM, a recipe or build unlock, a consumable,
  coins with a real use, a shortcut, world information, a rare trait or special
  individual, or a genuine discovery. **No empty rewards** — an off-path detour
  that pays nothing is worse than no detour, because it teaches the player to
  stop exploring.
- **Content that exists but cannot be noticed does not count.** The delivery
  mechanisms are the deliverable too: a distant village glimpse, something
  glowing far off, a visible cluster of unseen creatures, an NPC who names a
  place *and reveals it on the map*, and a wayfinding beacon pointing at the
  next real objective. Verify discoverability — sightline, cue, pointer — not
  just presence in the data.
- **No long creature-free stretches** along a travelled route.
- **Long purposeless travel is rare**, measured as dead-travel intervals.
- **The player would voluntarily keep exploring.** This is the primary judgment
  and the one the others serve.

## 5.2 Roster and progression pressure

- **Every major region creates genuine roster temptation**, and at least one
  real moment of five-slot pressure lands **before** the legendary.
- The next serious challenge is usually clear.
- The player repeatedly has understandable ways to improve, never forced into
  grinding a number.
- **Catching stays relevant to the last hour.**
- Major fights test **different aspects** of the five, not the same fight scaled
  up.
- Major victories change **capability, access or world state**, not just XP.

## 5.3 A finished region

Every region must have: recognizable geography · a clear reason to enter ·
ordinary wild ecology · at least one team-building temptation · useful gathering
· trainer presence appropriate to the region · at least one optional discovery ·
at least one memorable encounter · a sensible camp or recovery spot where the
journey warrants one · visible route hierarchy · a clear payoff into the next
region · no long purposeless stretch · day/night readability · acceptable
target-hardware performance.

It must also pass a **continuous playthrough from the prior gate to the next
gate.** A region is not finished because its data exists or its triggers fire.

---

# 6. Combat acceptance

Combat depth is a ladder. Each rung is independently shippable and each has a
player-facing acceptance statement, not a code checklist.

| Rung | Acceptance |
|---|---|
| **Readable state** | The player can tell, from the creature's body and the HUD alone, whether it is recovering, committed to an attack, or open to be hit. Poise and stagger are visible events, not hidden numbers. |
| **Telegraphed threat** | Every attack that can hurt the player's creature has a wind-up the player can see and react to at gameplay distance and camera angle. A hit that could not be seen coming is a defect. |
| **A real spatial answer** | The player has a movement answer to a telegraph that is not "walk backwards": the **burst step** — a short, committed, cost-bearing repositioning move. **No shields, no blocking, no held buttons.** |
| **Fight identity** | A named fight is distinguishable from a generic wild fight by what it does, not by its HP bar. A blind player describing two major fights should describe two different fights. |
| **Type legibility in the moment** | The player can tell a matchup is going well or badly from the fight itself, without opening a menu. |
| **The camera never loses the fight** | Framing holds both fighters through the whole exchange, including switches, at every creature-size pairing. A camera that frames more body than ground is a defect. |
| **The exam** | The final boss tests preparation, composition and the player's learned reading of telegraphs — not reflexes alone and not a larger HP pool. |

---

# 7. Systems and reliability acceptance

- **Core verbs never fail.** No modal freezes, no lost camera control, no arena
  phase-outs, no softlocks.
- **Controller-first everywhere at ROG Ally scale.** No menu unreachable by
  stick, no input leaking between contexts.
- **Save/load preserves position, facing and story state.**
- **Objectives** answer "what now and why it matters" without becoming a quest
  engine or a GPS trail.
- **The map** records exploration; it is not a creature radar and does not
  compensate for unreadable geography.
- **Gathering/crafting**: resources have known uses.
- **Building**: a basic shelter is fast and pleasant; pieces snap, rotate and
  dismantle with refund; it never becomes a factory game.
- **Care**: injury creates real expedition decisions; a creature in a bed visibly
  rests, is unavailable, and recovers over meaningful time.
- **Satiety** influences readiness without becoming starvation punishment.
- **Performance**: beauty that kills the frame rate is not a pass. Structural
  ceiling — the Meadows Hall builds to **≤ 4,000 draw calls** at the
  `hall_approach` stand, and **≤ 4** shadow-casting Omni/Spot lights reach any
  one location. Actual frame time is the owner's measurement on the Ally.

---

# 8. Story acceptance

- The opening **establishes stakes without a wall of text** and cannot be
  accidentally skipped.
- Team Tether escalates **rumor → evidence → confrontation → operation →
  hierarchy → boss**, never as unrelated fights.
- **Home stays relevant**: dialogue changes, rescued people return, returning is
  worth it.
- The boss is **a character and an exam**, not an HP pool.
- The legendary **volunteers**, and the release ceremony carries enough history
  to hurt.
- The ending **shows** the world healed rather than stating it, and points at
  the next biome without entering it.

---

# 9. It looks like one deliberate game

- **Cohesive from opening through stronghold** — one art direction, not a
  gallery of lane outputs.
- Bar A and Bar B both answered **yes** on a fresh survey of the real build.

---

# 10. It actually works, played end to end

- **3–4 hour focused pacing** without cutting required beats.
- A **continuous fresh-save run** from waking to the legendary, with no
  developer intervention.
- **No major core-verb reliability failures** across that run.
- Every change **survives integration** — do not accumulate individually
  successful changes that fail together.

## 10.1 The automated campaign proof (Gate F)

An automated scripted-walker harness that plays the campaign end to end is the
only way to get repeatable, no-intervention evidence for the row above.

**It is a measurement instrument, not the goal, and it is run rarely** — at a
chapter milestone, not continuously. A green run says the chapter *runs*; it
does not say the chapter is beautiful or that anyone wants to keep playing it.

If a work window is spending more time fixing the harness's own walker, timing
math or wrapper scripts than on the game the harness exists to measure, stop and
re-scope. Two weeks and 15+ attempts, mostly fixing the walker, is what that
looks like when it isn't caught. If the question the harness answers already has
a good-enough answer from direct human play, further automated-proof chasing is
opportunistic — worth finishing a specific mid-flight check, not worth starting
fresh for its own sake.
