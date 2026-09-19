# D38 — The release ceremony is three beats on the Team screen

**Date:** 2026-08-15 · **Item:** R4.10 · **Status:** shipped

## The decision

A catch that would overflow the belt suspends play immediately and runs the
release ceremony inside the Team screen — never a separate scene, never a
dialog, never a deferrable errand. Three player-paced beats:

1. **Choose.** The five belt rows stay exactly where they always are; the
   newcomer appears as a sixth row below a hairline under the caption "JUST
   CAUGHT - NOT ON THE BELT". Focus starts on the newcomer. The screen's own
   live 3D viewport and full detail column (level, type, stats, appraisal,
   traits, moves, bond) serve all six — the decision is made by comparing
   real creatures with real history, which is what spec M5's "inspect
   meaningful info" means and what "a generic delete dialog" fails.
2. **Confirm.** Pressing A on a row swaps only the detail column for the
   farewell question — "Let NAME go?" — with the cost restated (level, bond)
   at the exact press that pays it, and consequence stated plainly ("A
   released creature does not come back"). Focus lands on **Keep them**; the
   permanent choice is one deliberate stick move away and B backs out to
   more looking. Nothing is spent before this beat resolves.
3. **Done.** `party.remove_at()` returns the released creature so it can hold
   the viewport one last time while the belt rows behind it visibly settle
   into the final five. One button — "Back to the belt" — lands the player
   on the resulting Team screen.

## The plumbing this stands on

- The real gap R4.10 closed: `encounter_director.gd`'s catch resolution
  appended to a dead-end M3 list nothing read, so **no ordinary catch ever
  reached `Game.party` at all**. `_resolve_catch()` now owns catch→party for
  every catch in the game (the opening's tutorial catch included;
  `sequence_director.gd` no longer double-adds).
- When the belt is full the catch is parked on `Game.pending_catch` —
  exactly one, never saved, refused rather than queued if a second somehow
  arrives. It is a seam in the `pending_build` pattern, **not storage**: the
  ceremony cannot be left until it is empty.
- `Game._watch_pending_catch()` reopens the Team screen on any unpaused
  frame where a catch is pending and the menu is closed. That one retry loop
  makes the ceremony un-dodgeable *and* self-healing — any escape route
  (panic chord, a future `close()` caller) lands back in the ceremony.

## Why these choices

- **Immediate, not deferred.** A "decide later" pocket is a sixth creature
  the player owns while walking around — storage with a nicer name, and the
  exact dodge spec §5 forbids the biome making possible.
- **In place, not a new scene.** R4.6's evolution ceremony set the pattern:
  a beat machine swapped into the screen the player already knows, driven by
  the shell's own focus system. The belt rows staying visible through every
  beat is the point — during the question you look at the five you would
  keep, during the goodbye you watch the belt become final.
- **Buttons, not a polled confirm.** The choose press and a confirm press
  share the A button; a polled `menu_confirm` would see the very press that
  opened the question and resolve a permanent release on it. Buttons only
  fire on fresh presses, so every beat costs its own deliberate one.
- **Releasing the newcomer is a first-class answer.** "Not worth a holder"
  is an honest outcome; the belt comes through untouched and the wording
  ("NAME was never on the belt") says so without judgement.

## Deliberately not built

- No "time with you" line: `creature_instance` has no caught-day field and
  adding one is a save-format change this item does not make. Bond is the
  history proxy on screen. If the owner wants "caught on day N" on the
  farewell panel, that is a small follow-up touching `save_game.gd`.
- No release ledger, no memorial, no way to see released creatures again.
  Released is gone; that absence is the rule's weight.
