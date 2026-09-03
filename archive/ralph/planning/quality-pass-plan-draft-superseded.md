> **Superseded.** This was an earlier AI-drafted version of the Meadows
> quality-rebuild plan, written before the owner reviewed and revised it.
> `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` is the current,
> owner-directed version and is what lanes should actually read and follow.
> Kept here only as a dated reference for how the plan evolved — notably,
> the owner's revision explicitly overrode two calls this draft made
> differently: `PW3` (this draft proposed a "tribute" stat-sacrifice
> mechanic on the sixth pal; the owner's version says do not build a
> stat-tribute system at all) and the world-scale target (this draft
> proposed a fixed 10–20 minute critical-path walk; the owner's version
> says do not target a size for its own sake — density over kilometers).

# The Meadows quality pass — full plan

Draft only. Nothing here has been added to `ralph/BACKLOG.md`, `CLAUDE.md`,
or `docs/decisions/` yet. Written so it can be reviewed, edited, and then
split into real backlog entries once you're happy with it.

All items tagged `model: fable` are creative/aesthetic authorship, dispatched
per `ralph/PROMPT.md`'s existing fable-dispatch rule — the fable pass owns
the judgment call and delegates wiring, tests, and git bookkeeping to `opus`
subagents of its own.

**Suggested build order:** `MQ1` (rig) → `MQ4a` (catching visibility) →
`MQ2` (world) → `MQ3` (loop content, including `PW2`/`PW4`), with `MQ4b`
(catch floor) and `MQ3`'s side-quest XP rewards parked until `R4.1`
(leveling) ships. `PW1` and `PW3` are not sequenced — they need your call
before they're sequenced at all. Reasoning below each item.

---

# Part 1 — The four core items

## MQ1 — Rebuild the character rig for walking and running

`area: player, animation` · `model: fable` · `tests: smoke_traversal` (extend
with a foot-plant/slide check)

### Why this is being redone
`OF5` (shipped) root-caused the original ice-skating bug and fixed the worst
of it, but its own numbers admit overshoot ("reads as grip," not zeroed),
and it closed by convention, not by hitting a target. There has never been a
real target: `GAME_DESIGN.md` §5 explicitly defers movement feel as "a
prototype tuning problem, not a paper-design problem," and no rig spec
existed beyond `HUMANOIDS_PRODUCTION_REPORT.md`'s retrospective (24-bone
Meshy auto-rig, procedural sine-curve clips, no IK). This item exists to
give the rebuild an actual target instead of another round of the same
tuning.

### The brief
- **Feel target:** grounded and weighty, in the same register as the
  project's existing Palworld reference (already used for control bindings
  and environment art — extend it to locomotion). Not floaty, not
  hyper-responsive arcade movement. A slight settle on stops; real
  weight-transfer on turns.
- **Technical bar (the full rebuild, not another tuning pass):**
  - Real foot-planting IK — feet lock to the ground contact point during
    stance phase, release cleanly at toe-off. This is the direct fix for
    slope/uneven-terrain sliding that pure playback-rate scaling cannot
    solve.
  - A real blend space (walk↔run driven by actual speed, not a single-clip
    playback-rate hack via `match_gait_rate()`), so transitions read as
    accelerating, not gear-shifting.
  - Keep `data/config/art.json`'s `gait_reference_speeds` (walk 5.0, sprint
    8.6) as the ground-truth speeds the IK/blend system reads from — don't
    re-derive them.
- **Scope:** the shared humanoid base (the trainer's own rig plus the
  reused Grandpa/Warden/villager rigs, per `CLAUDE.md`'s per-material-variant
  reuse rule) — fix it once at the rig level rather than patching the
  player and leaving NPCs on the old cycles.
- **Reference capture:** reuse `OF5`'s Muybridge-style capture tooling to
  measure the result, not just eyeball it.

### Done when
A blind capture-and-measure pass shows foot-sweep speed within a stated
tolerance of body speed (pick a tolerance — e.g. ±10% — when this is
written up for real) at both walk and sprint, on flat ground AND on the
existing sloped test terrain, with no visible foot slide in the rendered
clips.

**Required screenshot verification, not just numbers.** Render a contact
sheet of stills at several points across one full walk cycle and one full
run cycle (minimum: contact, mid-stance, toe-off, mid-swing for each leg —
the same phases `OF5`'s Muybridge capture already isolates) and inspect
each frame directly for anatomically correct joint bend: knees bending
backward (never hyperextending or bending the wrong way at any phase),
elbows bending correctly on the arm swing, no visible clipping or double-
jointed poses at the extremes of the stride. This is a real defect class
procedural sine-curve rigs are prone to and a foot-sweep-speed number alone
would not catch — a leg can match the right average speed while still
bending backward at the knee mid-stride. A second blind critic pass
(visual-judge style) confirms the feel reads as "grounded/weighty" rather
than "floaty" or "stiff," against the Palworld reference stills already in
`docs/reference/`.

---

## MQ2 — Redesign the world layout for the full Meadows chapter

`area: terrain, world-layout` · `model: fable` · `tests: smoke_traversal`,
`test_region_connectivity` (new)

### Why this is being redone
`R7.3` already exists in the backlog as "the single largest unpriced piece"
of the plan — the current 512m test area cannot hold spec §3's five bands, a
quarry, a dungeon, a river, a relay outpost, an upper region, or the
stronghold. This item **is** `R7.3`, made concrete: it gives the redesign an
actual shape instead of leaving "how do the bands connect" for whoever picks
it up to invent.

### The brief
- **Shape:** one long connected route. Spatial order matches unlock order —
  the village sits at one end, the stronghold at the other, and the bands
  string together along the path between them in the same sequence
  `MEADOWS_PROGRESSION_SPEC.md` §3 already unlocks them: Lower Meadows
  (village/oak grove/starter stream/South Bridge) → Old Quarry/Burrow
  Warrens (Rootstone tier) → the River Lock (Old Mill Crossing, Tether
  Relay Station) → Upper Meadows/Ironwood (wind ridge, ruined watchtower) →
  the stronghold. The spine is one continuous route, but it is not a bare
  corridor — it needs short side spurs and detours off the main path for
  `MQ3`'s off-route content to live in. "One long connected route" describes
  the backbone and the traversal order, not a single-width tunnel.
- **Scale:** roughly 10–20 minutes of straight, uninterrupted walking end to
  end — that number describes the critical-path *distance*, consistent with
  §30's "not enormous" rule and its own gate ("prove movement is fun first,"
  which `MQ1` exists to do). It is not the same number as how long a real
  playthrough takes: with rest stops, combat, and side content (see below),
  an actual crossing should span **several in-game days**, tracked through
  the day counter that already exists (`Game.day`, advanced today by
  `camp.gd`'s rest interaction) rather than a new calendar system.
- **Authored campsites along the route.** In addition to the player's own
  buildable camp (`data/items/buildables.json`'s existing campfire+bedroll,
  unchanged), place several fixed, pre-authored rest points spaced along the
  route — landmarks in their own right, not generic waypoints, reusing
  `camp.gd`'s existing rest interaction rather than a new mechanic. Spacing
  should assume a player who doesn't sprint the whole way and stops for the
  night realistically — that's what turns the 10–20 minute critical path
  into a multi-day *experience* rather than a speedrun. Exact count and
  placement is this item's own authorship, done after the route's shape is
  laid out, not before.
- **Must not contradict:** `D24`'s asset-family lock (Quaternius nature/
  village/prop families only), `D05` (Terrain3D, authored geography, not
  procedural), the Meshy-reserved-for-hero-objects rule, and the existing
  `ENVIRONMENT_AND_UI_BIBLE.md` composition/palette rules (layered
  vegetation, clusters-not-scatter, the locked palette). Existing shipped
  work — the village, the settlement rebuild, the stronghold silhouette,
  the hillside — is not being thrown out; it gets positioned into the new
  layout, not redone from scratch, unless something about the new layout
  genuinely requires it.
- **What this does NOT cover:** the actual encounter/dungeon/story content
  inside each band — that's `MQ3` and the existing `SC12`–`SF34` items,
  which this item's new geography unblocks rather than replaces.

### Done when
A real map (even a rough top-down authored-geography sketch, per `D05`'s
convention) exists showing all five bands connected along one route, at the
stated scale, with a terrain rebake and Terrain3D regions to support it. A
blind traversal pass confirms the route reads as one continuous journey
rather than disconnected pockets, and a blind visual-judge pass confirms
nothing already-shipped (village, stronghold, hillside) reads as
contradicted by its new placement. A played (not simulated) end-to-end
crossing that stops to rest at each authored campsite lands in the
several-in-game-days range on `Game.day`, not one long unbroken sprint.

---

## MQ3 — Build out the full Meadows gameplay loop into that world

`area: content, quests` · `model: fable` · `tests:` whatever each band's
existing item already specifies (`smoke_trainer_battle`, etc.)

### Why this is listed separately from MQ2
`MQ2` gives the bands a place to exist. This item is the actual content
inside them — largely the work already scoped by `SC12`–`SF34` and the
progression-plumbing items (`SB9`–`SB11`) in the existing backlog, pulled
forward and built with the benefit of the new map rather than against the
old placeholder space. The loop itself is already unusually
well-specified — `MEADOWS_PROGRESSION_SPEC.md` gives a macro loop, a
six-act/40-step beat sheet, and time-banded targets — so this item is
authorship inside a real template, not invention from nothing.

### The brief
- Build the progression plumbing first (`SB9` state system, `SB10` keys/
  gates, `SB11` quest log) — nothing else in this item can be tested
  end-to-end without it.
- Then populate each band along `MQ2`'s route in unlock order: the three
  Band 1 trainers and their battles, the Old Quarry/Burrow Warrens dungeon
  and its Rootstone reward, the River Lock crossing and relay rescue, the
  Upper Meadows region and its three captains, and the stronghold finale.
- Each band's specific encounters, dungeon layout, and dialogue are this
  item's own authorship — the spec names *what* each band contains (named
  trainers, a required dungeon, a captive to free) but not room-by-room
  layout or script, matching how every other content item in this backlog
  already works.
- **Off-route side quests, placed in `MQ2`'s side spurs.** Optional content
  that pulls the player off the critical path into the wider space around
  it — the spurs exist for exactly this. Reward these with a faster XP rate
  than the equivalent time spent on the critical path, so exploring off-
  route is genuinely worth it rather than just flavor. **Depends on `R4.1`
  (levels/XP) the same way `MQ4b` does** — there is no XP to grant until
  that system exists, so side-quest content can be authored and placed
  ahead of time but its actual rewards can't be wired or tested until
  `R4.1` ships.
- **Fold in `PW2` (alpha/elder variants) and `PW4` (signature dungeon
  gimmicks) here** — see Part 2. Both are content-depth notes for this
  item's own authorship, not separate systems.

### Done when
`docs/GAME_DESIGN.md` §33's twelve exit-gate criteria and
`MEADOWS_PROGRESSION_SPEC.md` §39's mechanical checklist are both walkable
end to end — every listed action (clear the dungeon, defeat the three
captains, free the captive, etc.) is actually possible in the built game,
on the real map from `MQ2`, not the placeholder area. At least one side
quest exists off each of `MQ2`'s spurs, each one reachable without leaving
the critical path blocked, and (once `R4.1` lands) grants XP at the stated
faster-than-critical-path rate.

---

## MQ4 — Fix catching: visibility now, floor later

`area: combat` · `model: fable` for the feel/judgment half, `model: sonnet`
for the mechanical wiring · `tests: test_catch_math`, `smoke_combat`

### Why this is two items, not one
The original ask ("catching is too hard, needs lock-on, 26% floor before
damage") ran into a real conflict: `D08` explicitly considered and rejected
lock-on ("it would delete the skill the milestone exists to create"), and
the brutal full-health odds are a stated design pillar (`GAME_DESIGN.md`
§15: "powerful/full-health pals should be extremely difficult to catch"),
not a bug. The resolution kept D08's aiming-skill rule intact and split the
fix in two:

**MQ4a — trajectory visibility (do now, no dependency).**
`R4.9`'s own notes claim a trajectory preview/lock-on-adjacent system was
already "absorbed" from an older item — worth verifying honestly against
what's actually experienced in play, not just checked off against old
notes. Done when: the orb's arc is visibly previewable before release
(not just during flight), aiming remains fully player-controlled per D08,
and a fresh playtest confirms the "can't see the throw before committing"
complaint is actually resolved.

**MQ4b — a catch-chance floor for low-level creatures (blocked on `R4.1`).**
The floor is defined by the creature's actual level, not its species
`catch_rate` — which means this item cannot be built until `R4.1`
(levels/XP) ships and a level stat exists to key off of. Until then, this
half of the item is a `BLOCKED.md` entry, not a build task. Once `R4.1`
lands, done when: a low-level creature at full health has a stated minimum
catch chance (pick the actual number — 26% was the opening suggestion —
when this gets written up for real) that rises as it takes damage,
implemented as a floor on top of the existing `hp_factor`/`species_rate`
formula in `catching.json` rather than a formula rewrite, and rarer/higher-
level creatures keep something close to today's odds.

### Done when (both halves)
A blind playtest of an early-game catch against a common, low-level
creature no longer produces "I can't see what I'm throwing at" or "that
felt impossible even after I hurt it" as the dominant complaint, without a
fresh critic flagging that catching stopped feeling like a skill.

---

# Part 2 — Palworld-inspired additions

The brief for this part: read everything above plus the wider spec, and
propose what would make Tetherbound more Palworld-like without breaking
its own rules. A lot of Palworld's signature hooks are structurally off the
table here on purpose — pal-operated base labor, player weapons,
multiplayer, and deep storage are explicit hard rules in `CLAUDE.md`, not
oversights. What's below is filtered for what's left: ideas that borrow the
*feeling* Palworld earns without importing mechanics this project has
already ruled out.

Two of these (`PW2`, `PW4`) are low-risk and already folded into `MQ3`
above. Two (`PW1`, `PW3`) are real design decisions and are **not**
sequenced anywhere yet — they need your call first, per `CLAUDE.md`'s own
"ask/flag instead of inventing" rule.

## PW1 — Partnered traversal abilities ⚠ needs your decision

**The idea:** a caught pal opens ground you couldn't reach alone — a water
pal lets you cross the river before the bridge exists, an air pal lets you
glide down from the ridge. Palworld's mounts double as traversal tools, and
it's one of its best hooks: team composition affects *where you can go*,
not just what you can fight.

**Why it fits:** the project already has the scaffolding — `R6.1`/`R6.2`
riding, and pillar 4 of `GAME_DESIGN.md`'s own design pillars ("the world
is not level-gated by UI — difficulty and danger tell you, not a wall").
This would be a sharper version of the five-pal pillar than combat alone
gives you: exploration gated by which five pals you chose to keep.

**Why it's flagged, not just written up:** this edges into "changing
traversal philosophy," which is explicitly on `CLAUDE.md`'s own list of
things to ask about before building, not invent. Needs a real decision on
scope (how many pals get a traversal ability, which abilities, whether any
of them gate story-critical progress or only shortcuts) before it becomes
a brief like `MQ1`–`MQ4` above.

## PW2 — Alpha/elder wild variants ✅ folded into MQ3

**The idea:** rare, landmark versions of pals you already have installed —
bigger, distinctly materialed, tougher, better reward on catch or defeat —
placed as notable encounters along `MQ2`'s route and side spurs.

**Why it fits, and why it's ready to build (unlike PW1/PW3):** this is
free under the project's own asset lock. `D23`/`D24` already forbid new
creature meshes and mandate differentiating installed meshes by "material,
texture, modest scale, animation, VFX, habitat and behaviour" — an
alpha/elder variant is exactly that, not a new system. `GAME_DESIGN.md`
§24 already says rare pals can depend on habitat/time/weather. This also
gives `MQ2`'s new side spurs something concrete worth a detour for, which
directly serves `MQ3`'s side-quest goal of making off-route exploration
worth it.

## PW3 — A meaningful sixth-pal moment ⚠ needs your decision

**The idea:** pillar 1 of `GAME_DESIGN.md` is blunt — "catching a sixth
forces a permanent release decision," and today that's pure loss. Palworld
answers the equivalent problem (what to do with a duplicate catch) with
condensing: fuse a duplicate into a stat boost. I wouldn't import that
mechanically — it's a spreadsheet move, and this game is explicitly
building toward an *emotional* release ceremony (pillar 2, `R4.10`). The
same shape, reframed as **tribute** — sacrificing the sixth into the one
you keep, so something of it carries forward — fits Tetherbound's own
theme better than Palworld's original does.

**Why it's flagged, not just written up:** this touches the canonical
release-ceremony scene (`R4.10`, `model: fable`) directly, and changes what
"releasing a pal" means emotionally, not just mechanically. That's a real
tone decision for you, not something to hand to a fable pass and hope it
lands right — the whole point of `R4.10` being fable-tier in the first
place is that a weak first pass on ceiling-setting narrative work becomes
the ceiling nothing later can rescue.

**Owner's later call, recorded in `MEADOWS_QUALITY_REBUILD_PLAN.md`:
rejected.** Do not implement a stat-tribute system — it would incentivize
catching creatures specifically to sacrifice them, which undermines the
emotional release choice this was meant to strengthen. A non-power
remembrance (journal entry, camp keepsake, later sighting) is the approved
direction if the release moment needs more weight at all.

## PW4 — Signature dungeon/captain gimmicks ✅ folded into MQ3

**The idea:** Palworld's tower bosses are memorable because each one
changes how you play for that specific fight, not just how much HP it has.
`SD17` (Burrow Warrens, the required dungeon) and the regional captains
(`SF34`) are already planned in the existing backlog — this isn't a new
system, just a note for whoever authors them under `MQ3`: don't let
"required dungeon" or "regional captain" collapse into a reskinned combat
arena with a different coat of paint.

## Explicitly not recommended
Breeding/egg mechanics and a skill-point tech tree were considered and set
aside — bigger swings that don't obviously serve this game's own pillars,
and each would need its own owner sign-off before anyone builds toward
them. Not included here; raise them separately if you want them explored.

---

# Master list of open decisions

Everything below needs your call before any of this goes into
`BACKLOG.md`, `CLAUDE.md`, or `docs/decisions/`:

1. **`MQ1`'s foot-sweep tolerance number** (±10% was a placeholder).
2. **`MQ4b`'s actual catch-chance floor number** (26% was your opening
   number — confirm or revise once `R4.1` exists to hang it off of).
3. **Whether `MQ2`/`MQ3` become new backlog IDs** or fold into/rename the
   existing `R7.3`/`SC`–`SF` items they overlap with.
4. **How many authored campsites, and how many in-game days** the crossing
   should actually take — "several" needs a number or range to be testable.
5. **How many off-route side quests, and their XP multiplier** over
   critical-path content — needed before `R4.1` ships so the numbers are
   ready the moment leveling exists to receive them.
6. **Whether `R4.1` (levels/XP) gets pulled to the front of the whole
   sequence.** It's now a harder dependency than it looked at first —
   `MQ4b` and `MQ3`'s side-quest rewards both need it.
7. **`PW1` — do you want partnered traversal abilities at all**, and if so,
   how far they go (shortcut-only vs. gating real progress).
8. **`PW3` — do you want the sixth-pal tribute mechanic**, and does it
   belong inside `R4.10`'s release ceremony or as a separate moment.
   **(Resolved above: rejected.)**
