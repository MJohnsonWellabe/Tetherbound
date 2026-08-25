# BLOCKER — S02 could not complete, and the journey chain stops here

**Segment:** S02 (Opening: wake → starter caught & named → first wild catch → road gate).
**Verdicts:** 52 PASS / 19 FAIL. **Handoff produced:** none. `saves/` is empty.
**Consequence:** S03–S10 each need the previous segment's exit save (§B), so the
journey chain cannot continue past S02. X01–X06 seed from journey saves and are
blocked with it. X07 and X08 are DIAG segments that need no journey save and
remain runnable.

Per §A's blocker rule the evidence is preserved, the blocker is reported, and the
fix happens outside the run against a newly frozen SHA. I have changed no code,
data, config or step-script.

## What happened, from the telemetry rather than from inference

`route.csv`'s `input_context` column changes exactly five times in the whole
segment:

| t (s) | input_context | player position |
|---|---|---|
| 0.38 | `title` | — |
| 2.68 | `world` | — |
| 53.94 | `locked` | (-25.40, -15.60) — the wake beat |
| 56.00 | `world` | (-25.40, -15.60) |
| **253.38** | **`narrative_modal`** | (-17.74, -17.34) |

and it never changes again. The segment ran on to t≈2000 with that modal up.

Against the step clock:

| step | t | what it did / saw |
|---|---|---|
| S02-16 | 237.24 | pressed `interact` to talk to Grandpa |
| S02-18 | 237.24 | assert dialogue owns input → **`world`** |
| S02-19 | 242.28 | pressed `interact` ×30 |
| S02-22 | 245.27 | assert starter picker owns input → **`world`** |
| S02-23/24 | 245.4 | `ui_right`, then `menu_confirm` — into the world, no modal present |
| S02-26 | 248.43 | assert naming prompt → **none; input owner is `nothing`** |
| S02-28 | 250.43 | pressed `interact` ×12 |
| — | **253.38** | **a modal finally opens and takes input ownership** |
| S02-30 | 373.21 | walk → **held 7201 frames by `narrative_modal`, 52.8 m short** |

So the opening's modal arrives roughly **three seconds after the last input burst
and sixteen seconds after the first `interact`**, by which point the script has
already run past every step that would have answered it.

## The candidate defect, stated with its caveat

Three later steps identify the modal and probe it:

- S02-63: `game_menu` did not open the pause shell — `narrative_modal ->
  narrative_modal (owner=StarterPicker)`.
- S02-66: `4 × ui_down did not move focus off nothing`.
- S02-69: slot 4 has no file — nothing could be saved.

**The StarterPicker modal holds input ownership while no control holds focus.**
With focus owner `nothing`, directional input has nothing to move between and
confirm has nothing to activate, so the modal cannot be answered and cannot be
dismissed — locomotion stays held, the pause shell will not open, and the run
cannot save. In that state the chapter is unexitable.

**The caveat is real and travels with this finding.** The script pressed
`ui_right` and `menu_confirm` *before* the picker existed, and only probed it
after. It is therefore **not established** that a human, seeing the picker appear
and pressing then, would be locked out. What *is* established: the picker was
open and owning input for ~1,750 s, and every input the harness sent it in that
window — `ui_down` ×4, `game_menu` — did nothing at all.

Two readings survive this evidence and only a fix-side investigation separates
them: (1) the picker genuinely opens with no focused control, which is a
chapter-ending defect; (2) the picker focuses a control only along a path this
script missed, in which case the defect is that it does not recover focus when
input arrives late. Diagnosis is not the operator's (§13), and I am not making it.

## What this does not say

No pacing, difficulty or economy claim is drawn from this segment. The ~3 s
latency before the modal appears is reported as measured wall-clock in this
container at ~5–6 ms/frame (i.e. the game was running at real speed, not
starved), but whether that latency is what a player feels on device is
[OWNER-ONLY] territory and is not claimed here.
