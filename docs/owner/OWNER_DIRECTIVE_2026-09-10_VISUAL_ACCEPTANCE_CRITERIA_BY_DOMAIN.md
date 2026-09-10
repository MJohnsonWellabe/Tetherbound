# GOAL: Visual acceptance criteria by domain, referenced against named games, executed as coordinated lanes

This is a visual-focused execution goal. `docs/prompts/78-CODEX-GOAL-build-the-four-biome-game.md`
remains the standing contract; this file supplies the acceptance criteria and lane
structure for the visual work it and the 2026-09-09 owner directives already called for.

## 0. Read first

1. `CLAUDE.md` — hard rules, still binding.
2. `docs/VISUAL_BIBLE.md` and `.claude/skills/visual-judge/SKILL.md` — the existing
   rubric and target. This file ADDS domain-specific reference points; it does not
   replace Bar A (Meadows key art) or Bar B (Palworld) as the two binding questions.
3. `docs/SECOND_PASS_BACKLOG.md` — every open visual deferral, with evidence paths.
   Do not re-diagnose what's already there; extend it.
4. `docs/owner/OWNER_DIRECTIVE_2026-09-09_VISUAL_ROOTCAUSE_PARALLEL_LANES.md` and
   `OWNER_DIRECTIVE_2026-09-09_CONTINUOUS_VISUAL_LANE.md` — still binding.
5. Recent reports under `ralph/reports/FOUR-BIOME-BUILD/`: `CREATURE-SHARED-MATERIAL-
   ROOTCAUSE-0909.md`, `SHARED-NIGHT-GRADE-RESUME-0909.md`, `VISUAL-BLIND-WAVE15-0909.md`,
   `WATERFRONT-BLANK-PANEL-DISPOSITION-0909.md` — current findings, don't rederive them.

## 1. How additional references work — read this before judging anything

The project's binding bar stays Meadows key art (Bar A) and Palworld (Bar B) — these
decide pass/fail and are never replaced. But several domains below (storms, cliffs,
swimming, mounts, finale architecture) are areas Palworld doesn't strongly demonstrate,
so a blind judge is ALSO given, per domain, one or two additional named games as a
**supplementary comparison point** — never as a new pass/fail bar, never as an asset or
composition to copy. State explicitly in every verdict which comparisons were bar
questions (key art / Palworld) and which were supplementary (named below).

## 2. Execution model — read before assigning any lane

**Astra coordinates, Ralph-style, across many lanes — do not hand this to one
undifferentiated context, and do not open a separate Codex session per domain below.**

- **Lanes split by SYSTEM, not by the domain list below.** Several domains share one
  underlying system (terrain shader + scatter pipeline underlies terrain/vegetation/
  cliffs/ground; one sky/weather shader underlies sky/storm; one creature material
  pipeline underlies every individual creature). A shared-system lane stays ONE lane,
  never split per biome or per domain — splitting it recreates the exact
  instance-by-instance conflicts already found and corrected twice this project
  (creature material, night grade).
- **Judging is never render-bound and is always parallel.** Fresh, blind judge
  instances, one per subject, never reused across rounds, never told what changed.
  This was a diagnosed failure mode (reviewers reused serially) — do not repeat it.
- **Capture/rendering is render-bound: one Godot process per machine** (`AGENT_WORKFLOW.md`
  §3). Test one second git worktree for a second concurrent render once; if it holds,
  use two capture lanes; if not, capture sequentially but completely. This is a hardware
  fact, not an org-chart choice, and adding more Codex sessions does not add render
  throughput.
- The domain list in §4 is the **priority/scheduling order** — work it top to bottom.
  It is not a lane boundary list. Map it onto system lanes per the rule above.

## 3. Judge protocol

Full `.claude/skills/visual-judge/SKILL.md` rubric every time. No numeric scores. Bar A
(key art) and Bar B (Palworld) answered every time, plus any domain-specific
supplementary comparison named in §4, clearly labeled as supplementary. A finding is not
a checkpoint (`CLAUDE.md` "Process rules") — every round must produce a render and a
verdict, not just a diagnosis.

## 4. Domains, in order of impact on player experience

### 4.1 Creatures — highest impact; the game is named after them

**References:** Palworld (the binding bar) for creature-as-focus, expressive
silhouettes and large readable color regions. **Pokémon** for face/eye legibility at
small size — a Pokémon is recognizable from a silhouette and a two-color-block face at
thumbnail size; that is the specific lesson to borrow, not the art style. **Monster
Hunter Stories / Cassette Beasts** for how a stylized companion creature reads clearly
beside a human character without either one dominating.

**Acceptance — shared/general (fix before per-creature work):**
- `mipmaps/generate=true` on every species' active albedo (currently false on all 32 —
  root-caused, not yet shipped).
- Scale ladder 1.90–7.20 m against the 1.80 m trainer ruler holds per species, verified
  by `tools/measure_models.gd`, grown never shrunk.
- No creature's combat-ready silhouette occupies enough of the fight-camera frame to
  make targeting or reading the opponent impossible — a runtime space check, not just
  a static scale check.
- Habitat contrast ≥1.5:1 value/hue against local ground, day and night, every biome.

**Acceptance — per creature:**
- A fresh blind judge can locate and describe an eye/face region without hedging
  ("an orange mass with turquoise scrapes" is a fail).
- No floor-contact/clipping in any authored pose.
- Named creatures still failing, do in this order: Torrentoad (round 3 of 3 — fix
  geometry/rig, not paint, or register to backlog), Pebblik, Skyrill, Cragclaw,
  Mirejaw, Riverdrake, Sirenseal, Riptusk, Tanglevolt, Voltwig, Mosshock, Staticub,
  Stormraven, Mangrove Monitor, Aeriex, Cloudfang.
- Sparkit, Galecrest, Mosshell are controls — do not spend a round on them.

### 4.2 Characters — the player's constant on-screen identity

**References:** Palworld's human cast for grounded stylized proportions. **Zelda:
Breath of the Wild / Tears of the Kingdom** — Link's silhouette and color-blocking read
instantly at any distance and light condition; that clarity, not the anime-adjacent
polish of something like Genshin Impact, is the target register for this project's
"between Valheim and Palworld" identity.

**Acceptance:**
- Trainer identity reads as distinctive at a glance (silhouette + 2-3 color-blocked
  regions), not generic. Arlo's accent-color fix is accepted as a floor, not the
  answer — a real fix needs a costume/accessory brief.
- Named NPC hair/face/clothing stays legible at gameplay distance — no blown-out
  white patches replacing hair shading.
- Oxblood/red reserved for Team Tether only, verified by direct pixel sampling
  wherever a human appears.
- No new humanoid mesh without owner reference art (unchanged hard rule).

### 4.3 Terrain & ground — the base of every frame

**References:** Valheim (the binding lower bar) for material transitions at close
range. **Zelda BOTW/TOTK** for how ground material communicates walkable path vs.
off-path terrain without a UI marker — the specific lesson: value and texture change
at path edges, not just color.

**Acceptance:**
- Every biome shows a real material transition at close range, never one repeating
  tiled texture read as "a blurred smear."
- Terrain mipmaps shipped (PR #107) confirmed by a fresh blind pass to have actually
  reduced shimmer, not just flipped a policy flag.
- No biome's ground reads less resolved than Meadows' — the cross-biome consistency
  bar.

### 4.4 Vegetation — the single most-cited defect across every review

**References:** Valheim and BOTW for clustering (groves, clearings, forest edges, not
uniform scatter). **Grounded** specifically for how dense stylized foliage still reads
as legible layers (ground cover → mid-layer → canopy) rather than noise — useful here
because Grounded's whole conceit is dense micro-vegetation staying readable.

**Acceptance:**
- All three layers present in every biome: ground cover, mid-layer (bush/sapling/rock
  line), canopy. Water and Stormwood currently have none of this — that is the bar,
  not a stretch goal.
- Vegetation reads as clustered/authored, never even spacing.
- Trunk-to-canopy ratio moves toward a real broadleaf's (~1:9) from the current
  1:3–1:3.6, once trunk geometry allows it.

### 4.5 Sky, clouds & atmosphere — always visible; currently the one thing that works

**References:** BOTW/TOTK and Genshin Impact for painterly cloud banks and a clear
day/night mood shift without needing expensive volumetrics — both ship this cheaply,
which matters on the Compatibility renderer this project is locked to.

**Acceptance:**
- Preserve what already passes (painted clouds, golden-hour/night mood) — do not
  regress this while fixing everything else.
- Distant terrain does not wash out via aerial-fade color coupled to fog (named,
  unfixed mechanism gap).
- Night does not crush the trainer's legs/lower body to black in any biome — the
  still-open core problem, independent of the already-rejected exposure-slider attempt.

### 4.6 Water — bodies of water, shading, the Water biome's identity

**References:** BOTW's water for stylized shading with no reflections (the same
constraint this project is under — no SSR on Compatibility). **Subnautica** specifically
for "swimming with a creature at scale" readability — not for its tone, only for how
it keeps a mounted/nearby creature legible against open water.

**Acceptance:**
- Existing converged water shading (8 blind-judged rounds, no reflections by design)
  stays untouched — do not re-open a closed, deliberate ceiling.
- Veilfall's unshaded alpha-plane (`water_veilfall.gd:134`, alpha 0.83) gets its own
  fix — a distinct local cause, not the general water shader.
- Coastal landmarks (Salt Crown tide shrine, Reedhaven woven hall, docks) read as built
  destinations, not isolated placed objects.

### 4.7 Storm & lightning — Stormwood's identifying weather

**References:** **Genshin Impact's** Electro/storm weather for a stylized lightning
flash and ambient charge effect that reads clearly without photoreal volumetrics —
the closest well-known touchstone for a storm effect at this project's render budget.

**Acceptance:**
- Storm weather has a visible delta from clear weather (named gap: currently
  indistinguishable).
- Red/danger undergrowth's meaning is either established as a real danger signal or
  desaturated — currently ambiguous and competing with the trainer for attention.
- Crown Overlook's daylight fix (PR #98) holds under a fresh judge, not just a
  self-report.

### 4.8 Cliffs — Cloudreach's identifying feature

**References:** **BOTW/TOTK's** Hyrule cliffs are the direct, well-known touchstone —
stylized rock strata, readable silhouette from distance, believable scale next to a
person without photoreal detail.

**Acceptance:**
- Cliff silhouettes read as distinct landforms at distance, not a repeated patterned
  wall texture.
- Cliffhold and similar high-perch stands pass a corrected-camera capture — the old
  survey camera was below-floor at several of these; fix the evidence bug before
  re-judging content.

### 4.9 Strongholds / biome finales — lowest frequency, highest peak impact

**References:** **Zelda BOTW/TOTK's** shrines and Palworld's towers/bases for how a
finale structure reads as a held, defended place from its approach, not just up close.

**Acceptance:**
- Meadows' Hall silhouette reads at 400 m and again at 100 m (currently soft at
  200–400 m — a silhouette lever, not weathering).
- Stormwood's Crown arch/shrine and Water's waterfall finale each pass a fresh blind
  judge — currently neither does.
- No finale renders as a bare/placeholder frame (South Bridge's prior fix is the proof
  this is achievable with existing assets).

### 4.10 Other named locations — landmarks, camps, waycamps, hollows

**References:** BOTW's towers and Palworld's bases for "every marked destination has
an actual built approach," not just a reachable coordinate.

**Acceptance:**
- Every location in the debug-teleport catalogue has a built approach and local
  dressing.
- Sweep for siblings of the blank-panel-class defect (Water's First Shore is fixed) —
  find them as a class, not one at a time.

### 4.11 Riding, swimming, swimming-with-a-creature, flying

**References:** BOTW for mount silhouette at speed and gliding/landmark readability
from altitude. Palworld for mounted-flight companion readability specifically.

**Acceptance:**
- Every rideable species keeps a readable mount/rider silhouette in motion, not just
  standing still.
- Swimming (solo and mounted) keeps trainer/creature visible at the surface, not
  swallowed by water shading.
- Flying preserves landmark readability from altitude — this is the same underlying
  cliff/terrain silhouette work in §4.8, not a separate art pass.

### 4.12 Placed items (world props/objects)

**References:** Stardew Valley and Animal Crossing for object silhouette clarity at a
glance, before reading any label.

**Acceptance:**
- No object reads as an unfinished placeholder (flat unshaded plane, blank box) in any
  authored scene — sweep for this class, the dock panel was one instance of it.
- Signposts/banners/structures use installed kit geometry, never a `Label3D` or
  box-mesh stand-in (the signpost fix is the proof this path works).

### 4.13 Gatherables & consumables

**References:** Stardew Valley / Genshin for at-a-glance item identification by
silhouette and color before a label is read.

**Acceptance:**
- Visually distinct enough to identify by silhouette/color at pickup range.
- No regressions to interaction height/reach (the Stone-harvest-height fix is the
  model: small, verified, shipped).

### 4.14 Tools (held/equipped items)

**References:** Monster Hunter and Zelda for equipped-gear silhouette clarity on the
character at gameplay distance.

**Acceptance:**
- Equipped tools/gear read clearly on the trainer at gameplay distance.
- Root-cause the saddle-building regression specifically here — not yet confirmed
  fixed anywhere in current evidence.

## 5. Root-cause discipline, restated

Before fixing anything in §4, check whether the defect is local (one asset, one
location) or systemic (a shared material/shader/pipeline many things read from). If
the same defect class shows up in more than one domain above, the fix belongs to the
shared system lane (§2), not repeated per-domain patches. Say explicitly, per finding,
which kind it is.

## 6. Evidence and reporting

After each systemic fix, re-run the judge against every previously reviewed subject
that showed that defect class, not just the one it was found on. Report in
`docs/CURRENT_STATE.md` / a `ralph/reports/` entry: which domain moved, which
supplementary reference game was used and why, before/after frames, and an explicit
split of what's fixable in-engine vs. needs new art/reference. Update
`docs/SECOND_PASS_BACKLOG.md` for anything deferred rather than fixed.

## 7. What never bends

Five creatures total, human never fights, real-time piloted combat, growing never
shrinking for scale, installed asset families only, oxblood reserved for Team Tether,
no new Meshy spend beyond the already-scoped pilot, multiplayer-native for anything
new. Don't silently invent a major gameplay/story decision — ask if genuinely blocked.
