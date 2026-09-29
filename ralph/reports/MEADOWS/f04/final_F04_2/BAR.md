# F04#2 "three captains: named tactical question visible at normal distance": the pass bar for the final judge round

This bar is written before any frame of the final round is rendered or seen, and it does not change after that. It is given to the code-blind judge unchanged, before the frames. This is the criterion's one final round (coordinator, 2026-09-28 22:04). It is rendered on `main` after the Combat Spacing PR merges. If it fails, the remaining defects go into STATE and to the coordinator, and no further round is started.

## Sources
- **ACCEPTANCE §6.1 F04:**
  - a named tactical question visible at normal player distance;
  - a real hit/avoidance witness;
  - the specified tell and recovery.
- **BOSSES §4.3:**
  - **Oreth** (Mosshell16 WALL opener … Brooktail16 CURRENT) tests patience and a neutral reset, then sustained pressure.
  - **Halder** (Duskhush16, then Tuskroot16 CHARGER, …) tests range control across an exposed field.
  - **Vess** (… Galecrest16 DIVER ace) supplies the reposition read.
- **COMBAT:** the WALL / CHARGER / DIVER tells.
- **C3_RUBRIC:** per-frame clauses, applied to every fight frame here.

## Frames
Rendered with render.yml at 1280x720 on main, each with `tools/art_pipeline/capture_named_fight.gd --attack --dodge --tell-frames --keep-alive` and:

| Captain | Trainer | Member (its question) |
|---|---|---|
| Oreth | `captain_riverwatch` | `--live-member=captain_riverwatch:0` (Mosshell WALL) |
| Halder | `captain_field` | `--live-member=captain_field:1` (Tuskroot CHARGER) |
| Vess | `captain_ridge` | `--live-member=captain_ridge:4` (Galecrest DIVER) |

The judge sees, per captain, the `tNN-{stand,dodge}-{start,mid,strike}` frames, the in-fight frames `01`–`24`, `fight_log.txt` and `RUN.txt`.

The witness is `tests/smoke_named_fight_hit_avoid.gd` with the same `--live-member` for each captain, on the same commit.

## Each captain must show all of these
- **Q1: the question is named on screen.**
  - In at least 3 of 4 tell-start frames, the member's tell text is legible, and its ground marking is visible along most of its extent, not hidden under the player's creature.
  - The three captains' tell texts differ from one another, so WALL, CHARGE and DIVE are each their own words.
- **Q2: the answer is shown.**
  - **Oreth:** at least one frame shows the WALL's commitment or recovery and the player's hit landing in it, or a strike avoided by holding off. A stand or dodge sequence shows that trading into the wall costs HP.
  - **Halder:** the Tuskroot stands visibly apart at at least 2 tell starts, with open ground along the lane. At least one `dodge` sequence shows the player's creature off the lane with a logged, presented miss.
  - **Vess:** the DIVER's tell reads as different from a CHARGER's, by text and by marking or motion. At least one sequence shows the Galecrest repositioning, and at least one strike is avoided by moving (logged miss).
- **Q3: a hit reads.** At least one `stand` sequence shows an impact on the player's creature and an HP drop.

## Framing, over all fight frames
- Tally EXCLUDED, PASS and FAIL per C3_RUBRIC.
- Clause 3 counts a person standing in the fight and covering a combatant's head.
- The player's creature rendered as a see-through close-up counts as clause 2.
- Each captain passes at 90% or more PASS among non-excluded frames.

## Witness
`smoke_named_fight_hit_avoid.gd` PASSes for each captain's named member.

## Verdict
- **PASS:** Q1–Q3, framing and the witness all hold for all three captains.
- **Non-blocking, reported:**
  - a one-frame HUD legibility dip;
  - a fixture name in the HUD;
  - a reused portrait;
  - the 0.25 s occlusion clause, which stills cannot test.
