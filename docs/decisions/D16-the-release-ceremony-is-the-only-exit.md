# D16 — The release ceremony is the only way out of a full party

**Status:** accepted
**Decided by:** implementation, during M5
**Builds on:** `D13-the-five-pal-cap-is-code.md`

## The decision

When a catch is refused because the party is full, the game presents all six
creatures and the player releases exactly one. **Permanently, and there is no
way to decline.**

`MEADOWS_VERTICAL_SLICE.md` M5 ends with the line the rest of this record is
about: *"Do not settle for a generic 'delete' dialog."*

## Why there is no cancel

Pressing B on the six does not close the screen. It prints, in the fiction's own
terms, that there is nowhere to put a sixth — no box, no storage, nothing
waiting outside — and stays.

This is not friction for its own sake. D13 established that a sixth pal is never
stored anywhere, which means there is no state the game could return to if the
player backed out. "Cancel" would have to mean *silently release the newcomer*,
and a button that destroys a creature without saying so is worse than the modal
it was trying to avoid.

So the choice is presented as what it is: six pals, five slots, and the decision
is which one. The newcomer is one of the six and can be the one released — that
is the "cancel", made explicit and given the same farewell as any other.

## Why the sixth pal is a plain reference and nothing more

`ReleaseCeremony` holds the newcomer in a `var`, and the roster it presents is a
snapshot copy taken at `open()`. The newcomer is **not** in that array — it is
appended into the return value of `candidates()` each time it is called.

That is deliberate, and it is the thing most likely to be "tidied up" later by
somebody who wants one array of six. The moment the sixth pal lives in an array
that outlives the decision, that array is storage, and D13's rule is broken by
a refactor nobody would flag in review. Storage does not have to be called
storage to be storage.

If the ceremony is destroyed without resolving, the newcomer is simply gone.
That is the same cost D08 attached to a throw, not a leak to fix with a holding
pen.

## Resolution is one-shot

`resolve()` refuses a second call with `already_resolved`. There is no undo and
no second list for released pals to land in.

The failure it guards against is not the player pressing A twice — the screens
handle that. It is any future code path that retries: an autosave, a retry after
an error, a signal connected twice. Losing two pals to one decision is
unrecoverable in a game whose whole premise is that you only have five.

A *refused* resolve does not count as resolved. Nothing chosen, or the party
refusing the newcomer, leaves the decision open so the player can still make it.
Only a successful release is final.

## Two screens, not one dialog

The six, then a farewell about one creature by name — pushed on top, so the six
stay visible and dim beneath it. `screen_stack.gd` had already written down why:
hiding the layer below made the confirm look like it threw the six pals away and
brought them back.

The farewell states what is being given up in the pal's own terms — the level it
reached, the experience it earned, the trait it carried, the appraisal you gave
it — and then what happens: it goes back to the meadow, it will not be waiting
there, and it will not come back.

Neither screen contains the word "delete", "remove", or "confirm" on its own.

## The save is written before the screens come down

Not after. If the save were last, the player would watch the ceremony close —
the game telling them it is finished — with the file still holding six pals'
worth of history. Saving first means the only order they can observe is
"written, then finished", and the window in which a crash could bring the
released pal back is the few milliseconds inside `save()` rather than the rest
of the session.

## What could not be judged yet

`CLAUDE.md` says an emotional release scene cannot be assessed on placeholder
art. The blind gate was therefore asked about the **flow** — whether the six are
presented, whether the information supports the choice, whether exactly one
leaves and stays gone. How the moment *feels* is recorded as not yet assessable
and stays open until the creatures are represented rather than stood in for.

## What the frames caught that the tests did not

Both screens shipped their first rendered frame with the appraisal panel cut in
half: Attack, Defence, the trait, its description and the xp line were all below
the fold, and the farewell sliced *"You appraised it"* through the middle of its
letters. Every assertion passed. The "inspect meaningful info" bullet was being
computed, logged, and then not shown.

This is D15's rule arriving on schedule, and it is why `tools/preview_ceremony.gd`
exists: it photographs both screens in seconds against a deliberately worst-case
party — longest trait description in the data, longest species name, levels high
enough to widen the xp line — because a layout that fits an average party is a
layout that clips on somebody's real save.
