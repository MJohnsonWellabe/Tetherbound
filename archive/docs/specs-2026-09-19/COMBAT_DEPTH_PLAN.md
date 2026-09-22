# Combat depth plan — why fights are a button mash, and the ladder out of it

**Status:** proposal, 2026-09-07. Planning only; nothing here is implemented.
**Trigger:** owner, 2026-09-07: *"Still feels not that fun but I think because combat
isn't good and that's most of what you're going to be doing early game is leveling up
by doing combat. Right now it's just button mash."*
**Outranked by:** `CLAUDE.md` hard rules (no shields, human never fights, five
creatures, no held buttons per D68), D07 (piloted, movement is the dodge), D77 (the
baseline fight costs something). Everything below fits inside those unless it says
"owner decision".

---

## 1. Why it is a button mash today (read from the code, not from feel)

The player's whole verb set in a fight, on the pad:

| Input | Verb | What actually decides the outcome |
|---|---|---|
| Left stick | move (5.6 m/s, no sprint, no dash; `jump` is listed in the combat context but the piloted creature never reads it) | almost nothing — see below |
| RT | quick (0.18 wind-up, 0.22 recovery, 0.4 cooldown, **100° cone**, facing auto-tracks the target through the wind-up) | pressing it |
| LT | charged (only when energy is full; energy comes only from four landed quicks) | pressing it when the meter fills |
| LB | switch (1.5 s lockout) | rarely needed: type chart is 1.25× / 0.8× |
| X / d-pad | throw orb, use food or potion | catching only |
| RB | recall = flee (wild only) | escape |

The opponent is a four-beat loop: **close → telegraph (0.55 s) → recover (0.75 s) →
reposition (0.7 s)**. `combat_ai.gd` is explicit that it does not react to anything:
no reaction to being hit, no reaction to the player's wind-up, no low-health
behaviour, never uses its own charged move (`wild_creature.gd`: "no charged-move AI").

Put those together and the optimal play is: stand inside 2.6 m and hold RT at the
buffer rhythm. Specifically:

1. **Nothing interrupts anything.** Landing a hit during the opponent's telegraph does
   not stop the telegraph. Being hit during your wind-up does not stop your wind-up.
   So there is never a reason to *not* be attacking. A hit is an HP subtraction and a
   0.4-lunge shove, nothing more.
2. **Moving off the telegraph costs more than eating it.** The tell is 0.55 s; a quick
   is 0.4 s of rooted time plus cooldown. To sidestep you give up a swing, and the
   swing you give up is worth more than the 15–21 % of HP the hit costs (D77's own
   measurement). D77 raised the *price* of standing still; it did not make standing
   still *wrong*.
3. **Aim is not a skill.** A 100° cone with facing that auto-corrects during wind-up
   means "in range" is the only aim condition. D07 chose forgiving on purpose for a
   7-inch screen; combined with (1) it deletes the second axis of skill.
4. **Charged is a reward for mashing, not a decision.** Energy fills only from
   quicks, so the LT press is the fifth press in a sequence you were already doing.
   The "rooted while charging, opponent closes on you" cost D07 wanted is real but the
   opponent's cycle is so slow you are never punished for it.
5. **No resource on the player's side.** Movement is free, attacks are free. Valheim's
   entire rhythm comes from the fact that neither is.
6. **Species differ in numbers, not in play.** `moves.json` already has projectile,
   cone, 360° area, and lunge shapes, so the *data* is richer than the *play*: every
   species still has one quick and one charged, and a Terrapup fight is piloted the
   same way as a Galewisp fight.
7. **Levelling gives stats only.** No move is learned by level. `progression.gd` has
   no learnset. So "levelling up by doing combat" (the owner's early-game loop) makes
   the numbers bigger and the fight identical, which is the thing the midgame
   directive names as the failure: *"Do not make progression only 'same fight, larger
   HP.'"*

The G-3 profiles (WALL / CHARGER / DIVER / CURRENT / ACE) are the right idea and
already ship, but they change the opponent's *timing*, and timing only matters if the
player is reading it. Today the player is not, because reading it is never rewarded.

**Definition of the defect, so it can be measured:** a fight is a button mash when a
pilot that only presses attack does as well as a pilot that reads the opponent.
`tests/smoke_combat_baseline.gd` already has the first pilot ("dodge nothing, use
nothing"). Section 7 adds the second and asserts the gap.

---

## 2. What is good about Valheim combat, and what of it we can use

Valheim's combat is a *rhythm* game with a *resource* in the middle. What makes it
work:

| Valheim | Why it works | Usable here? |
|---|---|---|
| **Stamina pays for everything** — every swing, dodge, sprint, block. Run dry and you are helpless. | Turns "press attack" into "spend stamina". The rhythm is attack → back off → breathe → attack. That rhythm *is* the fight. | **Yes, unchanged.** A creature stamina bar is not a shield and not a held button. This is the single biggest lever. |
| **Committed attacks with distinct timing** — a 3-swing combo where the third is heavy and slow. You choose *when* to start a combo you cannot cancel. | Commitment makes timing matter; the tell on your own side is a cost. | Yes. We already root the creature for wind-up + recovery. Missing: the sequence (see §4, "the quick chain"). |
| **Stagger / poise** — enough damage in a short window staggers an enemy, interrupts its attack, opens a punish window. Bigger enemies need more. | Gives the player a *reason* to attack at a specific moment (into the wind-up) and a reason to stop (the stagger comes, spend the charged now). | **Yes, and it is the cheapest win in this plan.** |
| **Parry → stagger → crit** | The best moment in Valheim. | **No shields (hard rule).** The *stagger* survives without the parry: a charged that lands during the opponent's telegraph interrupts it (§4). |
| **Dodge roll with i-frames, costs stamina** | Makes the tell readable *and* actionable at the last moment. | **Owner decision.** D07 says "movement is the dodge" and the first pass excluded a dodge roll. Movement is not currently a dodge (see §1.2). §5 puts the options. |
| **Enemies hit hard and have long, honest telegraphs** — a greydwarf brute's overhead is a full second, and it takes half your health. | Danger makes reading worth it. | Yes. D77 moved this halfway; the ACE profile already authors a 1.0 s tell at ×1.8 power. Bring the *shape* down the ladder: even Band 1 needs one hit that hurts. |
| **Terrain and knockback matter** — high ground, backing an enemy into a tree, being knocked off a cliff. | Space is a resource. | Partly. The arena is flat and bounded by design. Knockback on the charged, and a Charger that overshoots into the arena wall, are cheap. |
| **Preparation decides the fight** — food sets your HP and stamina before you walk in. | Ties camping/crafting into combat. | **Yes, and it answers OP-0904-6 (camping must be necessary).** Satiety already buffs; make the creature's stamina cap the thing a fed creature has more of. |

What we should *not* copy: Valheim's weapon skill grind, its parry, its hold-to-block,
and its heavy death penalty. All four either break a hard rule or cut against the
"a game about creatures, not about aim" reading in D07.

---

## 3. What is good about Palworld combat, and what of it we can use

Palworld's *player* combat is guns; its *Pal* combat is command-based, so the piloting
question was answered differently there. What is good about it and portable:

| Palworld | Why it works | Usable here? |
|---|---|---|
| **Three active skills on cooldowns, each a different shape** — a bolt, a cone, an area, a dash-strike — with an element each. | The decision is "which skill is off cooldown and fits this range and this target". That is a rotation, not a mash. | **Yes.** `moves.json` already has the shapes. We have one free face button in a fight (Y, since the pause shell refuses to open mid-fight) and A (jump is inert on the piloted creature). Two more move slots fit without a chord. |
| **Elements are loud** — 2× matchups, screen-filling VFX, the number is big. | You feel the switch to the right Pal. | Yes. Our chart is 1.25/0.8, which reads as noise. Widen to about 1.5/0.67 and the switch becomes the best move in a fight, which is what LB is for. |
| **Ranged and melee Pals play differently** | Variety by species, not by numbers. | Yes — same as above; give the ranged species a ranged *identity* (kite, keep distance, the opponent closes) instead of a projectile quick that plays like a melee quick. |
| **Weaken then catch, with the odds on screen; back-throw bonus** | Catching is a combat outcome, not an interruption. | Already ours (D31). Untouched here. |
| **Boss Pals with big telegraphed AoEs and phases** | Identity per major fight. | Yes — the ACE profile is the seed. Add a second beat (a 360° area that forces you *out*, then a lunge that forces you *in*) and the Warden fight has two things to read instead of one. |
| **Hitstop, knockdown, camera punch** — a hit *feels* like a hit. | Feedback. Their frame has ten thousand times our warm pixels (the blind critic's own count). | Yes. VFX landed (W09); what is missing is *time*: 40–60 ms of hitstop on a charged, a flinch animation on the hit body. |
| **Partner skills / the human fighting alongside** | — | **No.** Human never fights. |
| **Pal command AI** | — | **No.** D07: piloted. Our version is better for our game; do not regress it. |

Honest note: Palworld's Pal-vs-Pal combat is frequently criticised as shallow. Its
strength is *variety and spectacle*, not depth. Valheim is where the depth comes from.
The plan below takes Valheim's engine (stamina, stagger, commitment) and Palworld's
surface (three shaped skills, loud elements, hitstop).

---

## 4. The design: what a Tetherbound fight should be

**One sentence:** a fight is won by spending your creature's stamina at the right
moments — into the opponent's recovery, with the right shape of move for the range you
are at — and lost by spending it into its telegraph.

### 4.1 Creature stamina ("wind")

- Every creature has a wind bar under its HP in the combat HUD. Quick costs a little,
  charged costs a lot, the Y-slot skill costs a middle amount, the burst (§5) costs
  a chunk. Walking is free. Wind regenerates only while the creature is *not* in
  wind-up or recovery, faster after ~0.6 s of not attacking.
- **Out of wind:** the creature can still walk and still attack, but attacks come out
  slow (double wind-up) and weak (×0.6). No helplessness that reads as a bug; a
  visible, punishing slowdown that reads as "it is tired". Satiety-low already drains
  slowly; low satiety lowers the *cap*, which is the camping tie-in (D29, OP-0904-6).
- Why this and not just longer cooldowns: cooldowns are per-button and invisible to
  rhythm; a shared pool makes *every* press a trade against every other press, which
  is the Valheim lesson.
- Tunables: `combat.json` `wind` block: `max`, `quick_cost`, `charged_cost`,
  `skill_cost`, `burst_cost`, `regen_per_second`, `regen_delay`, `exhausted_windup_scale`,
  `exhausted_power_scale`. Per-species cap and regen in `species.json` (a Galewisp has
  less wind and faster regen; a Mosshell the reverse). Fed/bond bonuses in
  `creature_condition.json`.

### 4.2 Poise and stagger (both sides)

- Each body has a poise pool. Damage taken drains it; it refills over ~2 s of not being
  hit. When it empties the body **staggers**: its current action is cancelled, it is
  rooted for a short beat (0.6 s wild, longer per WALL/ACE profile), and the next hit
  on it is a critical (×1.5). The stagger beat is drawn with the existing telegraph
  glow in a different colour and a flinch on the body.
- **The player's creature staggers too.** Getting hit during your wind-up cancels the
  wind-up. This is the single change that ends "hold RT": a mashed swing into a
  telegraph now loses the swing *and* the stamina.
- **Charged into telegraph = interrupt.** A charged that lands while the opponent is
  in TELEGRAPH staggers it regardless of poise. This is the parry substitute: it is a
  read-and-commit decision (you are rooted 0.55 s to do it, so a wrong read eats the
  hit), it needs no shield and no held button.
- WALL and ACE bodies have deep poise; DIVER and CURRENT shallow. This makes the five
  profiles differ in *how you beat them*, not only in how they hit you: a Wall is
  a stagger race, a Diver is a punish-the-retreat race.
- Tunables: `combat.json` `poise` block: `max`, `regen_delay`, `regen_per_second`,
  `stagger_seconds`, `crit_scale`, `interrupt_on_charged_into_telegraph`. Per-profile
  overrides through the existing G-2 merge (`poise_max`, `stagger_seconds` join the
  allowed-key list).

### 4.3 Three shaped moves, not two

- Slots: **RT quick** (cheap, fast, builds energy as today), **LT charged** (the
  energy spend as today, now also the interrupt), **Y skill** (new; a cooldown move,
  8–12 s, mid wind cost, *never* a damage move alone: its job is to change the
  geometry of the fight). Per species, drawn from the shapes already in `moves.json`
  plus three new kinds:
  - **knockback cone** (Galewisp Gust, Galecrest Storm Gust): shoves the opponent to
    the arena wall; buys distance for a ranged species.
  - **slow field** (Terrapup Sand Kick, Burrowback Rubble): a patch that halves
    chase speed inside it; buys a punish window against a Current.
  - **snare / root** (Bramblebun Bramble Snare, Mudsnout Root Grip): roots the
    opponent for 1.0 s; the melee species' set-up for a charged.
  - **dash-strike** (Trailpup, Duskhush): closes 6 m and hits; the melee species'
    answer to a Diver.
  - **mist / veil** (Ripplet, Brooktail): a 1.5 s window where the next hit on you is
    ×0.5. Not a shield: it does not block, it does not stop damage, it has no held
    input, and it is spent whether or not it is used.
- **Learned by level, and the early ladder teaches them.** Level 4 learns the species
  skill (it lands in the first hour, before the tournament, and it is the first thing
  the player *gets* from levelling that is not a number). Evolution changes the skill.
  TMs (D44) can replace the Y slot as well as the quick/charged slots. This closes
  OP-0905-18 ("when and how does the pig evolve?") from the combat side: the Team
  screen shows *next skill at level N*.
- Ranged identity: a species whose quick is a projectile (Terrapup, Brooktail,
  Reedwing) gets `preferred_range` on the *player* side too: the HUD's target marker
  shows an "in range" ring so the player learns to kite, and the opponent's CLOSE beat
  is the threat, not its swing.

### 4.4 The opponent answers back

`combat_ai.gd::decide()` stays pure and stays four beats. It gains inputs, not
states:

- **Uses its charged.** With energy full (it builds from its own landed hits) the
  TELEGRAPH beat becomes the long one and the hit is the charged move. Wild bodies
  do this rarely (energy gain ×0.5); trainer bodies do it as authored.
- **Reacts to the player's wind-up** (trainer bodies and CHARGER/DIVER only): a
  player charged wind-up seen at more than 3 m triggers REPOSITION. Wilds do not
  do this, on purpose — a wild is what teaches the player the charged works.
- **Low-health behaviour** per profile: WALL stands (longer telegraph, harder hit);
  DIVER runs longer; CURRENT goes reckless (shorter cooldown, no reposition).
- **Uses its Y skill** at Team Tether officer rank and up, so the player meets
  snares and knockbacks from the other side before the Warden.

### 4.5 Feedback

- Hitstop: 30 ms on a quick, 70 ms on a charged, 120 ms on a stagger crit. Frame
  freeze on both bodies, camera untouched.
- Flinch on the hit body (procedural, off the model pivot, the D83 mechanism).
- Wind bar, poise pip and stagger flash in the HUD; a "STAGGERED" verdict through the
  existing effect banner so it is taught by the first fight that does it.
- Camera nudge on the charged landing only.

---

## 5. The open question that needs the owner: what is the "get out of the way" verb?

`CLAUDE.md` names dodge/block as a thing to ask about rather than invent. D07 said
"movement is the dodge" and excluded a dodge roll from the first pass. Section 1.2
shows walking does not currently function as a dodge, because the walk is slower than
the decision. Three options, cheapest first:

| Option | What it is | Cost | Risk |
|---|---|---|---|
| **A. Movement only, retuned** | Longer telegraphs (0.8 s baseline), a stagger on the player's wind-up, and a faster creature walk (6.4). No new button. | tuning | Reading is still marginal on a 0.55 s tell; hard fights become "walk in circles". Cheapest test of whether D07's reading holds. |
| **B. Burst step, no invulnerability (recommended)** | A on the pad (currently inert in a fight): a 3 m dash in the stick direction, 0.2 s, costs wind, cancels nothing, has no i-frames. You are safe if you are *out of the cone* when the hit resolves. Stamina makes it a decision, not a reflex. | small: a fifth `Action`, one impulse, one wind cost | Feels "wrong" to Souls players expecting i-frames; that is the point — it keeps D07's spatial reading and the cone-test hit model untouched. |
| **C. Dodge roll with i-frames** | Same button, 0.35 s of no-hit, costs more wind. | small–medium: a per-body invulnerable flag in the strike resolve | The best-feeling option and the one that moves the game towards Valheim; also the one that makes the aim cone and telegraphs less important, since a roll answers every tell the same way. |

Recommendation: **B**, with A's tuning underneath it, and C reserved as the fallback if
the owner's hands say B is not enough. B keeps every existing decision intact and is
reversible to C by one flag.

The second owner question: **should a trainer fight let you flee?** No (A-1 stands).
Nothing here reopens it.

---

## 6. Early game specifically: the first hour's fight ladder

The owner's diagnosis is that early levelling *is* combat, so each early fight has to
teach one thing and reward the thing it taught. Proposed ladder (existing encounters,
re-purposed; no new content):

| Fight | Teaches | How it is taught | Fails if |
|---|---|---|---|
| Tutorial wild (Practice Meadow) | **the punish window**: hit it while it recovers | Grandpa's line names it; the recovery beat glows; hits in the window show +crit | a masher wins as fast as a reader |
| First real wild, Band 1 | **the tell**: get out of the cone | telegraph 0.8 s here, hit worth 30 % | the hit is survivable *and* ignorable |
| Level 4 (first hour) | **the Y skill** | level-up flourish names the move; a HUD hint on Y for one fight | the player never presses Y before the tournament |
| Mira (floor trainer) | **wind**: a drilled creature makes you spend it | her creature is CURRENT; you cannot out-mash a Current, you must stagger it | won by mashing |
| Tournament round 2 | **types**: switch on LB | the opponent's type is the one your starter is weak to; effect banner says so; matchup widened to 1.5/0.67 | not switching still wins comfortably |
| Oskar (final) | **the interrupt**: charged into his ace's telegraph | ACE profile; the stagger beat is 1.2 s | the fight is won without a single interrupt |
| South Bridge grunt | **all of it, once** | the first opponent that uses its own charged | — |

Each row is measurable with the two-pilot harness in §7.

---

## 7. How "not a button mash" is measured

Extend `tests/smoke_combat_baseline.gd` with a second scripted pilot:

- **MASHER** (exists): close, quick on cooldown, charged when full, never moves off a
  tell.
- **READER** (new): steps out of the cone during TELEGRAPH, attacks during RECOVER,
  spends the charged into a telegraph when it can reach, uses the Y skill on cooldown,
  keeps wind above 25 %.

Asserted in `chapter_curve.json` `difficulty`, per band entry:

| target | value |
|---|---|
| READER lead HP cost vs MASHER lead HP cost, floor trainer | reader pays ≤ 55 % of what the masher pays |
| MASHER vs the band's top trainer | loses the lead every run; **loses the five ≥ 25 %** of runs from Band 3 up |
| READER vs the band's top trainer | wins ≥ 75 % |
| MASHER vs an ordinary wild | still wins (a wild must never wall a beginner) but costs ≥ 25 % of the lead |
| any single hit | < 50 % of a full-health entry-level creature (G-3 unchanged) |

D77's note that a *floor* trainer must not wall the five still holds; the wall moves
up to the band's *top* trainer and applies to the masher only. If both pilots produce
the same numbers, the change did nothing and the lane fails.

Also: a real-hands owner playtest is the only judge of *feel*. The harness proves the
decision space exists; it cannot prove it is fun.

---

## 8. Sequencing — what to build first, and what each step is worth

Ordered by value per line of code. Each is one lane, one PR, on top of the previous.

1. **COMBAT-1 Poise, stagger, player wind-up interrupt, hitstop, flinch** (§4.2, §4.5).
   Touches `combat_manager.gd` strike resolve and `_tick_action`, `wild_creature.gd`,
   `combat.json`, HUD. No new buttons. **This alone ends "hold RT"**, because a mashed
   swing into a telegraph now loses. Measure with the two pilots.
2. **COMBAT-2 Creature wind** (§4.1) with per-species caps and the satiety/bond ties.
   Touches the same files plus `species.json`, `creature_condition.json`, the party
   strip and combat HUD. This is the rhythm.
3. **COMBAT-3 Telegraph retune and the burst step** (§5, owner decision first).
   `combat.json` baseline `telegraph` 0.55 → 0.8, `enemy.power` shape per band;
   A = burst if approved.
4. **COMBAT-4 The Y skill and level learnsets** (§4.3). New `slot: "skill"` moves in
   `moves.json` with three new `kind`s (knockback, field, snare, veil), a `learnset`
   per species, `progression.gd` learning on level-up, Team screen "next move at",
   a TM can target the slot. Largest lane; the one that makes species play differently.
5. **COMBAT-5 The opponent answers back** (§4.4): AI charged use, wind-up reaction,
   low-health per profile, officer skill use. Pure-function changes in `combat_ai.gd`
   plus config; unit-testable.
6. **COMBAT-6 Loud types** — chart 1.25/0.8 → 1.5/0.67, VFX scaled by effectiveness,
   re-run the tournament and Warden smokes since both were tuned on the old chart.
7. **COMBAT-7 The early ladder** (§6): dialogue lines, the Practice Meadow's tutorial
   wild profile, Mira's profile, tournament round-2 type authoring. Content, no code.

Steps 1, 2 and 6 are config-plus-small-code and can be judged on the Ally within a
week. Steps 3 and 4 need the owner's answers to §5 and §9 first.

What is deliberately **not** in this plan: a second simultaneous opponent, combos
longer than a single move, blocking of any kind, held inputs, a separate combat
scene, human weapons, and any change to catching or the five-creature rule.

---

## 9. Owner decisions needed before COMBAT-3 and COMBAT-4

1. **The get-out-of-the-way verb** (§5): movement only / burst step without
   invulnerability / dodge roll with invulnerability. Recommendation: burst step.
2. **A on the pad in a fight** becomes the burst; the creature currently cannot jump
   while piloted, so nothing is lost. Confirm.
3. **Y on the pad in a fight** becomes the third move slot (inventory is refused
   mid-fight today, so Y is free). Confirm.
4. **Moves learned by level** (level 4 skill, evolution swaps it): confirm the shape,
   or say if the skill should be a TM-only thing.
5. **A wild can exhaust your creature** (out-of-wind slowdown): confirm this is the
   right kind of "cost" versus, say, a hard lockout.
6. **Type chart to 1.5/0.67**: confirm; this changes the tournament and Warden
   numbers that D77 and W-1 pinned.

Everything else in this document is ordinary work under existing decisions.
