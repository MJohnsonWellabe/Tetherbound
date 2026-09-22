# Owner directives — progression visibility, exploration rewards, and companion presence

**Recorded 2026-09-04.** These directives are additive to `docs/FINISH_THE_MEADOWS.md` and outrank older planning where they overlap.

## 1. Bonding and leveling must become a major visible part of the game

Owner direction:

> Bonding and leveling creatures is basically invisible. It needs to be a big thing. Not just when the bond goes up but also while trying to bond.

This means the problem is larger than a level-up flourish. The player must be able to understand and feel creature progression while it is happening.

### Bonding requirements

The player should be able to understand:

- the creature's current bond state;
- progress toward the next bond milestone;
- which meaningful actions are strengthening the bond;
- when a creature is getting close to a milestone;
- when a milestone is reached;
- what increased bond actually changes or unlocks.

Bond progress should come from meaningful shared play using existing supported systems where possible: traveling together, fighting and winning together, caring/healing, feeding, camping/resting, riding, and other real shared actions. Do not add arbitrary meter-filling chores just to create grind.

Ordinary gains should have subtle but readable feedback. Actual bond milestones should feel important, with strong audiovisual feedback and a clear explanation of the benefit.

The creature/party UI must expose current bond and progress clearly enough that a player can answer: **"How bonded am I with this creature, and what am I doing that increases it?"**

### Leveling requirements

Creature XP and leveling must also become legible during play.

The player should understand:

- XP gained after meaningful events;
- progress toward the next level;
- when a level is close;
- when a level occurs;
- what changed because of the level, especially meaningful stat, move, trait, or progression changes.

A level-up should be a noticeable audiovisual event rather than a background number changing.

This directive supersedes any narrower interpretation of the existing `FINISH_THE_MEADOWS.md` row **"Bonding and levelling made visible."** Treat that row as shorthand for this full requirement.

---

## 2. Add three finite creature-leveling candies as exploration rewards

Add three single-use consumables:

- **Good Candy** — raises the selected creature by 1 level.
- **Great Candy** — raises the selected creature by 2 levels.
- **Rare Candy** — raises the selected creature by 3 levels.

They are finite world pickups. Once collected, that pickup stays collected for that save.

Target approximately **100 candy pickups across the full Meadows chapter**, to be tuned after route-density/play evidence. Initial distribution target:

- about 60 Good Candy;
- about 30 Great Candy;
- about 10 Rare Candy.

Do not distribute them uniformly or randomly merely to hit the count.

Placement should reward exploration:

- Good Candy: ordinary side exploration and lesser discoveries;
- Great Candy: meaningful detours, tougher encounters, stronger points of interest;
- Rare Candy: memorable secrets, landmarks, difficult encounters, deep exploration, or other significant discoveries.

Avoid placing large quantities directly on the critical path. Candy should answer **"Why should I explore over there?"**

Verify that spending all available candy on one creature cannot break chapter progression, level caps, encounter assumptions, or other settled gates.

---

## 3. Increase useful world findables to the same general density

Revives, potions/healing items, and other useful existing consumables should become common enough that exploring the Meadows repeatedly produces useful finds.

Treat these as part of the same authored world-density pass as candy, creatures, harvest nodes, trainers, NPCs, and landmarks.

Target roughly **100–150 meaningful placed item pickups across the full Meadows chapter, including candy**, then tune from actual route evidence. This is a density target, not permission for pickup spam.

Placement should follow authored world logic:

- main routes: occasional basic supplies;
- side routes: better rewards;
- landmarks: deliberate rewards;
- dangerous spaces: stronger supplies;
- secrets: high-value pickups;
- deep travel and difficult regions: recovery resources where useful.

The pickup economy should support the attrition/camping loop rather than eliminate it.

Important world pickups must persist correctly so one-time rewards do not respawn after save/load unless their existing design explicitly says they should.

---

## 4. Pickup art and readability

Candy, revives, potions, and other important findables need to be visually recognizable during ordinary play.

For Good/Great/Rare Candy, use one coherent three-tier visual family with an immediately readable value hierarchy.

Follow the project's art-source order:

1. suitable installed asset;
2. suitable free-pack candidate;
3. owner-approved generated asset only after the required reference-art process.

Do not block the underlying system solely because bespoke art is not ready, but the visual task is not complete until important pickup categories can be distinguished at normal gameplay distance and pass the normal visual-review process.

---

## 5. New accepted improvement — companion personality must be visible in ordinary play

The five-creature rule and bond system will not carry their intended emotional weight if creatures behave like interchangeable combat units outside fights.

Make the active/deployed creature visibly feel like a companion using the rigs, animations, systems, and interactions already available wherever possible.

This does **not** mean building a giant pet-simulation system. It means adding a small number of high-value contextual reactions that make the creature seem present in the journey.

Examples to design from, not a mandatory literal checklist:

- looks toward or acknowledges the player at appropriate moments;
- reacts after winning a meaningful fight;
- shows a readable hurt/tired state when badly injured;
- has a small camp/rest reaction;
- responds to care/feeding/healing;
- higher bond can modestly alter frequency, confidence, or warmth of reactions;
- important bond milestones can trigger a stronger companion moment than a UI pop-up alone.

Prefer a reusable behavior layer over species-specific one-off scripting unless a species already has a suitable authored animation.

Do not make reactions constant, noisy, blocking, or repetitive. They should reinforce presence without interrupting normal play.

The acceptance question is: **after traveling and fighting with the same creature for a meaningful stretch, does it feel more like a companion the player has a relationship with than a model that appears when needed?**

---

## Combined intent

These additions solve three related gaps in the current Meadows experience:

1. **Progress must feel rewarding while it happens** — bond and level visibility.
2. **Exploration must repeatedly pay off** — candy and useful findables.
3. **The five creatures must feel emotionally distinct and present** — companion reactions tied into the bond journey.

Implement them as part of finishing the Meadows, not as Biome 2 work and not as optional post-launch polish.
