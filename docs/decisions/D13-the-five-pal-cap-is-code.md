# D13 — The five-pal cap is code, not prose

**Status:** accepted
**Decided by:** implementation, during M4
**Builds on:** `D08-catching-costs-you-your-pal.md`

## The decision

`CLAUDE.md` states the rule twice — *"Player can own only five pals total"* and
*"Never implement pal storage beyond five"*. Until M4 that sentence existed only
in prose, and the code contradicted it: `EncounterDirector._caught` was an
unbounded `Array` whose own comment called it milestone-local, and whose
accessor had **zero callers**. Nothing in the running game had ever refused a
sixth pal, because nothing in the running game had ever counted them.

The cap now exists in exactly one place: `MAX_PARTY := 5` in
`scripts/pals/party.gd`.

## Why a `const` and not `data/config/party.json`

Every other number in this project that a designer might want to move lives in
`data/config/` and is labelled tunable — speeds, cooldowns, catch rates, build
costs. This one does not, and the difference is not arbitrary.

A config value can be edited. A `const` has to be argued with.

Party size is not a difficulty knob; it is the constraint the release ceremony,
the emotional stakes of catching, and half of `GAME_DESIGN.md` are built on
top of. If it lives in a JSON file, then some evening when the party feels
cramped it becomes a six, and nothing in the codebase objects. Putting it in
source means changing it is a code change with a diff and a reason.

## There is no overflow. Anywhere.

This is the part that is easy to violate by accident, so it is stated as a rule
rather than left as an emergent property:

**A sixth pal is never stored.** Not in a box, not in a PC, not in a "pending"
list, not in a private array on the director, not in a member variable on the
thing that caught it. `Party.add()` refuses and returns `false`, and the
instance is held only by whoever is mid-decision about it.

The reason is mechanical, not aesthetic. The moment a sixth pal can sit
*anywhere* in memory while the player thinks about it, the release ceremony
(M5) stops being the only way to resolve a full party, and the design's one
irreversible decision quietly becomes optional. Storage does not have to be
called storage to be storage.

The corollary the ceremony inherits: it holds the newcomer as an in-flight
reference for the duration of one decision, and if that decision never
completes the newcomer is simply gone. That is not a leak to be fixed with a
holding pen. It is the same cost D08 established for a throw.

## What a sixth catch does

1. `EncounterDirector._keep()` calls `Party.add()`, which refuses with
   `REFUSED_PARTY_FULL`.
2. The director does **not** swallow it. It emits
   `caught_refused(token, instance)` carrying the creature that has nowhere to
   go. A director that dropped it on the floor would make the ceremony
   unreachable — the player would never learn they had caught anything.
3. M5's ceremony opens on that signal, specifically on that token.

## Refusals are tokens, not sentences

`REFUSED_PARTY_FULL`, `REFUSED_NOT_A_PAL`, `REFUSED_ALREADY_HELD`,
`REFUSED_NO_SUCH_MEMBER`.

The party has no business knowing how a refusal is worded. A sentence written
in `party.gd` is a sentence the UI cannot shorten for a toast, lengthen for the
ceremony, or translate. The tokens are enumerated in the file so a UI has an
exhaustive set to map, and an unmapped token shows as itself rather than as
silence.

## `members()` returns a copy

An `Array` is passed by reference in GDScript. Handing out the live roster would
let any caller `append()` a sixth pal without going anywhere near `add()`, and
the one rule this file exists to enforce would be enforced only by politeness.

## `from_records()` caps too

A save file is a text file on a Windows machine. It will eventually be
hand-edited, copied between builds, or written by a bug. A loader that trusts
its own input length is a loader that can produce the six-pal party the whole
design forbids, from a file nobody remembers editing. It stops at `MAX_PARTY`
and warns.
