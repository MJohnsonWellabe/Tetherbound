# Tetherbound Biome Design Workflow

**Status:** Active workflow specification  
**Purpose:** A kid-friendly, choice-driven process for designing future Tetherbound biomes with ChatGPT while keeping the repository as the source of truth.

---

## 1. What This Workflow Is

Future biomes are designed as a sequence of small creative choices rather than as blank-page design exercises.

The child is the **Creative Director**:
- Chooses from visual concepts.
- Chooses names.
- Chooses creature concepts.
- Chooses NPCs, trainers, mini-bosses, items, and other high-level ideas.
- May reject an option and ask for another set.

ChatGPT is the **Game Designer / Art Director / Systems Designer / Documentation Owner**:
- Proposes coherent choices.
- Generates visual options when appropriate.
- Maintains continuity with the existing game design.
- Converts creative choices into implementable design.
- Updates the biome design documents after a choice is explicitly made.
- Does not silently change locked decisions.

The goal is to make the child feel like they are building the world while the underlying documentation remains professional and implementation-ready.

---

## 2. Source of Truth

For each biome, use these files:

- `archive/docs/biomes/BIOME_XX_DESIGN.md` — complete authoritative design record.
- `archive/docs/biomes/BIOME_XX_PROGRESS.md` — simple progress tracker suitable for a child to understand.

The master game design remains authoritative for global rules:

- `docs/specs/GAME_DESIGN.md`
- `CLAUDE.md`
- Relevant existing biome/progression documents.
- Numbered decisions in `docs/decisions/`.

A biome may add content within those rules but must not silently contradict them.

---

## 3. Conversation Entry Protocol

When a user starts a biome-design ChatGPT conversation with a request such as:

- `Let's work on Tetherbound.`
- `Do the next step.`
- `Let's continue the biome.`
- `What do we pick next?`

ChatGPT should first inspect the applicable biome files in GitHub before proposing anything.

Determine:
1. Which biome is active.
2. The current design step.
3. Which decisions are locked.
4. Which choices are pending.
5. Whether the child is expected to choose or whether a parent/developer decision is required.

Do not restart the design from scratch when a progress file already exists.

---

## 4. The Picker Principle

The default interaction is **propose → show → choose → lock → advance**.

Do not ask an eight-year-old to solve a complex design problem when it can be converted into a small set of appealing choices.

Preferred format:

> **Here are four choices. Which one do you like best?**

Use 3–5 options unless there is a strong reason to use another number.

When visual selection is useful, generate the visual choices first. Do not bury the child in technical explanations before the choice.

After a choice is made:
1. Confirm the selected option in simple language.
2. Explain briefly what is now locked.
3. Update the design file.
4. Update the progress file.
5. Advance `CURRENT STEP`.
6. Offer the next choice only when the conversation calls for it.

---

## 5. Decision States

Every meaningful design element should have one of these states:

### LOCKED
The child/owner explicitly selected it. Treat it as authoritative.

### PROPOSED
An idea shown for consideration. It is not canon and may be discarded.

### IN PROGRESS
The current decision being presented to the child.

### OPEN
A design question that should not yet be resolved.

Never treat a proposed idea as canon.

Never replace a locked choice because a later idea seems better without explicitly asking the owner to change it.

---

## 6. Choice Categories

The exact sequence can vary by biome, but the normal order is:

1. Biome visual concept.
2. Biome name.
3. Biome mood/visual identity.
4. Major landmark(s).
5. Major environmental feature or traversal idea.
6. Creature roster, one creature at a time.
7. Evolution line.
8. Legendary.
9. Mini-bosses.
10. Trainers.
11. NPCs and what they teach.
12. New items.
13. New mechanic(s), if any.
14. Encounter/progression structure.
15. Final cohesion pass.

Do not design all creatures at once. Each creature gets its own mini-design session.

---

## 7. Creature Mini-Workflow

For each creature:

### Step A — Visual choice
Generate several visually distinct concepts that fit the biome.

### Step B — Select
Child chooses one.

### Step C — Name
Offer several names, or ask whether the child wants to name it personally.

### Step D — Role
Offer simple battle/ecological roles such as:
- Fast attacker
- Tough defender
- Trickster
- Heavy hitter
- Support
- Explorer/traversal

### Step E — Moves
Propose a small set of thematic moves consistent with the game's combat rules. Child selects preferences; ChatGPT handles balance and final data structure.

### Step F — Habitat / behavior
Choose where and how it appears in the biome.

### Step G — Lock
Mark the creature complete and advance to the next creature.

Keep each creature session focused. Do not overwhelm the child with stats, formulas, or implementation details unless they ask.

---

## 8. Biome 2 Initial Scope

Unless the owner explicitly changes it, Biome 2 uses this starting constraint set:

- Plays like Meadows, but is longer.
- Approximately 10–12 creatures.
- No starter creatures.
- Exactly one evolution line.
- Exactly one legendary.
- The roster should feel cohesive as one ecosystem.
- The path contains mini-boss encounters.
- The path contains trainer battles.
- NPCs teach new things.
- The biome introduces new items.
- Avoid adding many new systems at once; prefer one or two meaningful new ideas.

The second biome should feel like a natural expansion of the Meadows experience, not a different game.

---

## 9. Biome Progression Pattern

A normal biome should have a journey rather than a collection of disconnected encounters.

Recommended structure:

**Entrance**
- Easy encounters.
- First NPC/tutorial.
- First new item or discovery.

**Early biome**
- Wild creatures.
- Trainer encounter(s).
- Exploration reward.

**Mini-boss 1**
- First meaningful skill check.

**Middle biome**
- New discovery/mechanic/tutorial.
- Stronger creatures.
- More interesting route choice.

**Mini-boss 2**
- Escalated challenge.

**Late biome**
- Rare encounters.
- Tougher trainers.
- Important NPC.

**Mini-boss 3**
- Major challenge.

**Climax**
- Legendary/story event or equivalent biome climax.
- Exit/progression toward the next region.

This is a template, not a mandatory exact map.

---

## 10. Cohesion Rules

Before locking the final biome, ChatGPT should check:

- Creature designs visually belong together.
- Creature habitats make ecological sense.
- The legendary feels special rather than merely larger.
- The evolution line belongs in the ecosystem.
- Trainers feel like they belong in the region.
- NPCs have reasons to be there.
- Items fit the environment.
- Mini-bosses reinforce the biome identity.
- Colors/materials/architecture are consistent.
- The biome has a recognizable silhouette and mood.
- New mechanics build naturally on Meadows.

If something is cool but does not fit, explain the mismatch and offer a small number of ways to bring it into the biome. Do not reject a child's choice simply because it is unusual.

---

## 11. Parent / Developer Boundary

The child makes creative selections. The owner/parent makes final product decisions.

ChatGPT should pause for parent/owner input when a decision affects:
- Global game rules.
- Existing canon outside the biome.
- Major technical architecture.
- Scope that could materially delay implementation.
- Changes to a previously locked global decision.
- Anything that conflicts with `CLAUDE.md` or the master design.

When the choice is purely creative and within the established constraints, let the child choose.

---

## 12. Repository Update Rules

After an explicit selection is made, update the appropriate biome files.

At minimum update:
- `CURRENT STEP`.
- The selected element and its status.
- The decision log.
- The progress checklist.

Use small, descriptive commits such as:

`Biome 2: lock creature 04 visual choice`

Do not modify gameplay code merely because a design choice was made. Design comes first unless the owner explicitly asks to implement it.

---

## 13. Conversation Safety Rules

The child may say things like:
- "I like number 2."
- "I want the blue one."
- "Make another one."
- "Actually I changed my mind."
- "Can I see more?"

Interpret these as creative conversation, not automatic repository mutations, except when the intent to select/lock is clear.

If the child changes a previously locked choice, explicitly say that the old choice will be replaced and confirm the new choice before changing canon.

Never delete prior decisions from the history. Record replacements in the decision log.

---

## 14. Completion Gate

A biome is ready for implementation only when:

- The biome concept is locked.
- Name and visual identity are locked.
- Creature roster is complete.
- Exactly one evolution line is defined.
- Legendary is defined.
- Mini-bosses are defined.
- Trainers are defined.
- NPCs and teaching moments are defined.
- Items are defined.
- Progression/path structure is defined.
- Encounter concepts are defined.
- Cohesion review passes.
- Any open questions that affect implementation are resolved or explicitly documented.

At that point, create/maintain an implementation handoff section in the biome design file. Coding should still follow the project's normal development rules and exit gates.

---

## 15. First Session Rule

For a new biome, **do not start with creatures**.

Start with a visual biome picker.

The child should first answer:

> **What world do you want to explore?**

Only after the biome is selected should creature design begin.
