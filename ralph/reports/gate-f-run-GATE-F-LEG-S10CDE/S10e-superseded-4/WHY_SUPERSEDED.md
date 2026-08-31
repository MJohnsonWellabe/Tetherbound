# S10e, attempt 4 -- superseded

`INVENTORY.json`: `complete: true`, 31 pass / 5 fail. Real progress: this is
the first attempt where BOTH interact-range fixes from restart 3 held --
the trace shows the walker arriving at (10.39,0.9,-16.06), squarely within
Tam's 3.8m prompt radius, and later at (-22.57..-22.78,1.32,-15.1..-15.16),
within Grandpa's. `meadows_acknowledged` was set (village_tam_freed's
first line, confirmed by a `flag_set` event at distance_m 1423.41) and the
`distance_above: 1300.0` floor passed (1470.26 m walked). Neither of
restart 3's two defects recurred.

## New defect: Grandpa's dialogue never actually closed (CD-3, not a game defect)

All 5 fails are one cause cascading: `S10e-105` ("hear his post-win line
out") was still the original blind `press interact x14` count inherited
unedited from the pre-existing segment. The event trace shows
`grandpa_freed` opening (narrative_modal/DialoguePanel at t=501.75) and
still showing `narrative_modal`/`DialoguePanel` as the LAST recorded state
at t=514.067 -- after the 14 presses were meant to have finished it.
Downstream, every step that needed the world back failed identically:
`S10e-112` (open the pause shell) reported `context narrative_modal ->
narrative_modal (owner=DialoguePanel)`, then focus-move, the Save-tab
context assert, and the final save all failed the same way, because
`slot 4` was never actually written (still byte-identical to the seed).

This is exactly the CD-3 hazard `operator_harness.gd::_step_advance_dialogue`
(`advance_dialogue_until_closed`) was already built to eliminate, and its
own header spells out why a blind count fails in both directions: under-press
leaves the modal open, and over-press closes it and then RE-OPENS the same
greeting, because Grandpa (like a village NPC) is re-talkable and the next
`interact` while still standing in his prompt radius is a new open, not a
no-op. `grandpa_freed` is a 3-line conversation; 14 presses does not land on
an exact close boundary, so the excess wrapped into a fresh, partially-read
cycle. Not a game defect -- `dialogue_panel.gd`, `sequence_director.gd` and
`grandpa_freed`'s own data are all working exactly as designed. This
sub-segment's own `S10e-102` ("hear them out", Tam) had the identical
guessed-count shape and, on this same run, happened to land on a closed
boundary by luck (10 presses against Tam's own 3-line conversation) -- not
because it was actually safe.

## Fix applied

`tools/gate_f/segments/S10e.json`: replaced both blind press-count steps
(`S10e-102`, `S10e-105`) with `action: "advance_dialogue_until_closed"`,
the predicate-driven primitive `S02-28`/`S02C`/`S03` already use for this
exact failure mode -- it presses, reads the panel's own line, and stops
the instant the panel closes rather than guessing how many presses that
takes. The single opening `press` steps (`S10e-101`, `S10e-104`) are
unchanged: `advance_dialogue_until_closed` advances an already-open modal
and BLOCKERs on a closed one, so opening stays a separate, explicit press.

Re-running S10e (attempt 5) from the same `S10d-exit.json` seed.
