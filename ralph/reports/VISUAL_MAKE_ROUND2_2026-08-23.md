# VIS-MAKE round 2 — two blind Fable critics, harnesses repaired

Two independent Fable critics, blind, per `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5.
Neither judged evidence it produced.

| domain | A (keyart) | B (Palworld) |
|---|---|---|
| D8 combat + D6 items | **no** | **yes, narrowly** |
| D5 structures + player builds | **no** | **no** |

Both rounds named many NEW defects, so by `ralph/conventions.md`'s stopping rule
this round **improved**. Nothing here is close to convergence.

## What round 2 settles about round 1

**The impact flash is real and now photographs.** Round 1 called 01/02/03 "the
same still life three times". Round 2's critic separates them and describes
`03-hit-landing`'s burst directly — as "a flat beige starburst decal", which is
criticism of the effect rather than a report that it is missing. That is the
whole question from round 1, closed: the effect was always there and the shutter
was late. It is now judged, and judged harshly, which is the correct outcome.

**The camera finding is confirmed and now has a mechanism.** Round 2, blind:
*"The camera shoots the player creature's hindquarters. In 01, 02, 03 and 05 the
Terrapup's rear fills the bottom-center third of frame."* That is
`data/config/combat.json` — `enemy.preferred_range` 2.1 m against
`camera.distance` 4.6 m puts the ally 69% of the way along the sight line for
the whole fight. Recorded in full in
`ralph/reports/VISUAL_MAKE_LANE_FINDINGS_2026-08-23.md` §1.

**The structures close frames became judgeable.** Round 1: *"a third of the
structures close-ups are framed inside the eaves and show nothing judgeable."*
Round 2 does not mention eaves once, and instead reports specific close-range
defects that were previously invisible — floating shutters and sills on
`03-cottage_b-close`, gable braces clipping the wall on `02-cottage_a-close`, a
sliced-off brace on `21-wall-close`. The reframe to a person's eye at the door
converted a third of the sheet from waste into findings.

## The harness is STILL wrong in three ways, and round 2 proves each

Recorded first, because findings made against an invalid frame are not findings.

1. **The icon sheet is STILL cropped.** *"Header claims 55 items; roughly 26
   tiles are visible and the sheet is cut off mid-way through the GEAR row."*
   This is the second consecutive round in which the game's most-opened screen
   could not be audited, and `VISUAL_LEDGER.md` records the crop as fixed
   (2200 -> 2800px). It was not enough. **Every icon finding in rounds 1 and 2
   covers less than half the set.**

2. **The clock is pinned but not frozen — the trap the ledger names by name.**
   *"Exposure disagrees across the same encounter. Frames 01-03 are mid-day
   olive; `04-catching-clean` is several stops darker, near-dusk, same sky."*
   `04` is simply the shot taken latest in the sequence. `VISUAL_LEDGER.md`:
   *"Pin the clock AND freeze it. A pin that is not frozen wears off across a
   multi-viewpoint pass and the late frames come back in a dusk wash."* The
   combat capture never pinned it at all.

   The structures sheet has its own version: *"frames 01-18 have a light grey
   horizon band; frames 19-27 have a near-black one."*

3. **`05-trainer-battle` is still not a trainer battle.** `is_fighting()` is
   true and `enemy_body()` is non-null, so a fight is genuinely open — but the
   critic reports the HUD still showing *"You backed off."* and a target plate
   reading *"Bramblebun LEVEL 2"*, which is the wild creature from encounter A.
   The frame carries a stale toast and a stale target from the previous
   encounter, and the trainer's own creature is not in shot. Whether the stale
   plate is a capture-sequencing problem or a real HUD defect is not yet
   established and is NOT recorded as either.

## New defects worth acting on that no previous round named

- **A hard-edged teal light band across the hillside** (`01-engagement-clean`,
  `04-catching-clean`) — *"matches no sun direction and no time of day; it reads
  as a misconfigured spotlight or lightmap seam, and it is the single most
  artificial thing in the combat set."*
- **No tool is gripped.** The held-tool set is valid for the first time — the
  camera now stands in front of the trainer and the hand is unoccluded — and
  what it shows is that *"the right hand is open, fingers splayed, and the shaft
  passes behind/through the hand. There is no grip pose anywhere in the set."*
  Round 1 could not have seen this; it was looking at his back.
- **Tools are two to three times too large.** The knife reads ~1.4 m, the
  pickaxe head ~1.4 m, the hammer ~2.1 m against a 1.80 m man. This matches the
  capture's own measurements (`held/hoe ... 78% of a 1.80m trainer`) and
  `scripts/player/tool_hold.gd` has **no `held_scale`**, so it cannot currently
  be corrected from data at all.
- **The Bramblebun is a different game's art.** *"a near-photoreal brown rabbit
  with leaf ears added"* beside the painterly Terrapup and the toon trainer.
  Named plainly, as the rubric demands. Creature art is D3's lane, not this
  one, but the finding is recorded here because this is where it was made.
- **The engaged Bramblebun and the roaming one differ in size by ~2x.**
- **Structures: three named landmarks are still literal duplicates** —
  `10-inn` = `09-farmhouse_shell`, `15-ranger_station` = `03-cottage_b`,
  `13-mill` has no sails, wheel or hopper. Round 1 said this; round 2 says it
  again with frame numbers, so it is unmoved rather than new.
- **The well has no well** — *"a hollow, open-sided frame you can see straight
  through... no hole, no water, no winch, no rope."*
- **Bridges and gates are fence panels.** `18-south_bridge_gate` is *"visibly
  two fence pieces overlapped"* with a stacked double post.

## What both critics independently agree the one good asset is

The trainer. Structures: *"the trainer character himself does hold up beside
Palworld's characters — he is the one element in these frames at bar."*
Combat/items: *"the trainer model itself is genuinely good — the best asset in
every frame it appears in — which makes everything around him read one
production stage behind."*

That is now **seven** critics across this sweep saying the same thing.
