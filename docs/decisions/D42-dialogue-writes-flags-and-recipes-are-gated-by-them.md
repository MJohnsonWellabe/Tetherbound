# D42 — Dialogue writes progression flags, and a recipe can wait on one

**Date:** 2026-08-15 · **Decided by:** this firing, implementing `OF30` (Tam the
blacksmith) against the owner's report: *"Make one of the villagers a blacksmith
who will give you a torch, an axe for trees and a pickaxe for stones. Then he'll
give you the recipe for basic orbs."*

## What was already true, and needed no decision

The first instruction in `OF30`'s brief was to **prove** that a village
conversation's `give:` effects already reach the satchel before writing any
plumbing for them. They do, and the reason is a seam nobody planned:

- `scripts/story/sequence_director.gd::_drain_effects()` drains the dialogue
  panel every frame and never asks which conversation is in it.
- there is exactly one dialogue panel, and `scripts/world/village_npcs.gd`
  opens village lines on that one (through the `dialogue_panel` group) rather
  than on a panel of its own.

So Grandpa's effect pipeline was already the villagers' pipeline.
`tests/smoke_village_smith.gd` proves it end to end against the real autoload:
`village_tam_tools` puts a real axe and a real pickaxe in the real satchel with
no new routing code. Nothing in `village_npcs.gd`, `dialogue_panel.gd` or
`dialogue_runner.gd` had to learn what an effect is.

`data/dialogue/village.json`'s original rule — *"No `give:` or `beat:` effects —
these people have nothing to hand over"* — is retired for `give:`. `beat:` stays
forbidden there: beats are the opening's spine.

## The three decisions

### 1. `flag:<id>` is a third dialogue effect

The director knew `beat:` and `give:`. It now knows `flag:`, which writes one id
into `autoload/progression_state.gd` — the same flat store `item_gate.gd` and
`tm_pickup.gd` already write to. There is one flag store and there must never be
a second.

**Not a beat.** Beats are ordered, refuse to run backwards, and are checked
against `data/config/opening.json` at boot; they are the first fifteen minutes'
state machine. A villager's handover is a flat, unordered fact about the save.
Folding it into beats would put the village inside the opening's machine, and
every later villager with something to give would have to become a beat too.

**One flag per effect, no payload.** `flag:tam_tools_given`, never
`flag:tam:tools:2`. The moment a flag carries a value it is a variable, and a
store of variables read by dialogue is a scripting language — which
`MEADOWS_PROGRESSION_SPEC.md` §19, `CLAUDE.md` and `progression_state.gd`'s own
header each ban separately.

### 2. `greeting_when` — a villager's conversation is chosen by flag

`data/config/village_npcs.json` gains an optional, ordered
`greeting_when: [{ if_flag | unless_flag, conversation }]` per villager, checked
ahead of the existing `greeting`; first match wins, no match falls through.
Resolved by `village_npcs.greeting_for()` (static and pure, so the one-time-gift
rule is tested in milliseconds rather than by booting a world).

This is what makes the gift one-time: the conversation sets `tam_tools_given` on
the same line as the gifts, and that entry stops matching forever. The gift and
the flag being one line is deliberate — a conversation cut short can then never
bank one without the other.

**Additive, never a replacement.** `greeting` is untouched and stays what the
villager says once every branch is spent, so Tam is still NP3's Field Scout with
opinions about the bramblebun. This is the owner's dual-role rule for villagers
(recorded in the `Phase -1.3` batch header, referred to there as `D39`): `SC12`
appends Tam's battle offer as a third entry here, `OF31` gives Mira and Oskar
lists of their own, and no one's greeting is ever consumed by a role.

No `and`/`or`/`not` beyond "every named flag holds", and no nesting. This is a
lookup table, not a quest engine.

### 3. A recipe may name `unlocked_by`

`data/recipes/recipes.json` entries gain an optional `unlocked_by` flag id.
Absent means known from the first minute (`potion_small`); present means the
craft screen does not list it and `game_state.can_craft()` refuses it until the
flag is set (`orb_basic`, taught by Tam's second conversation).

Refused, not merely hidden: a gate that exists only in the list is one hotbar
shortcut or one capture tool away from not existing.

A plain flag rather than a recipe-book system, because the flag store already
exists, already saves and already loads. A parallel "what do I know" list would
be a second thing to migrate and a second thing to get out of step.

## The one place this went past the owner's words

He named two tools; the handover gives three. `items.json` gates `fiber` on
`knife`, and `harvest_yield()`'s rule since R2.1 is right-tool = full,
**no** tool = half, **wrong** tool = nothing. A player carrying only an axe and
a pickaxe owns "a tool, just not that one" at every patch of meadow grass and
gathers zero fiber, where bare hands a minute earlier paid two — and fiber is
two of the five materials in the orb recipe Tam teaches in his very next
conversation. A gift that makes the game worse is not a gift. All three tools
come off one bench in one line; `test_harvest.gd` now fails if any tool-gated
resource is left stranded by the handover.

Reversing it is one deleted `give:` and a re-gate of `fiber` — flagged here
rather than done quietly.
