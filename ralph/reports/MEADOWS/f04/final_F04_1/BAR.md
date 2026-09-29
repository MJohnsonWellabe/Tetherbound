# F04#1 "relay officers: readable tell and distinct tactical question at the normal camera": the pass bar for the final judge round

This bar is written before any frame of the final round is rendered or seen, and it does not change after that. It is given to the code-blind judge unchanged, before the frames. This is the criterion's one final round (coordinator, 2026-09-28 22:04). If it fails, the remaining defects go into STATE and to the coordinator, and no further round is started.

The round is rendered on `main` after the Combat Spacing PR merges. The last judge's main framing failure was the player's creature overlapping the opponent at contact range (JUDGE_F04_1_relay_ccecb414.md), and that lane owns the fix.

## Sources
- **ACCEPTANCE §6.1 F04:**
  - a named tactical question visible at normal player distance;
  - a real hit/avoidance witness;
  - the specified tell and recovery.
- **BOSSES §4.2, Vance (Galecrest12, Duskhush12, Burrowback12, Mosshell12, Tuskroot12):**
  - Tuskroot "closes 7 m after a .8 s minimum full-body charge cue, then recovers .9 s".
  - "The player must switch rather than solve all three with one type."
- **BOSSES table, Dell (Mosshell10, Burrowback10, Galecrest10):** "relay officer composition". His question is the three-type team itself: each member is a different type and body, answered by switching to meet it. It is **not** a different tell per creature, so a shared generic tell does not fail Dell.
- **C3_RUBRIC:** per-frame clauses, applied to every fight frame here.

## Frames
Rendered with render.yml at 1280x720 on main.

**Vance.**
- Command: `tools/art_pipeline/capture_named_fight.gd --trainer=relay_captain --live-member=relay_captain:4 --attack --dodge --tell-frames --keep-alive`
- The judge sees the Tuskroot `tNN-{stand,dodge}-{start,mid,strike}` frames, the in-fight frames `01`–`24`, `fight_log.txt` and `RUN.txt`.

**Dell.** The same command with `--trainer=relay_officer_dell`, once per member: `--live-member=relay_officer_dell:0` (Mosshell), `:1` (Burrowback) and `:2` (Galecrest). The judge sees the same kinds of frames.

**Witness.** `tests/smoke_named_fight_hit_avoid.gd` with `--live-member` for Vance's Tuskroot and Dell's three members, run on the same main commit.

## Vance must show all of these
- **V1: the tell reads.**
  - In at least 3 of the 4 tell-start frames, the "CHARGE" tell text is legible.
  - Tuskroot's ground lane marking is visible along most of its length, not hidden under the player's creature.
- **V2: the charge reads as a charge.**
  - In at least 2 tell-start frames, Tuskroot and the player's creature stand visibly apart, with open ground between them along the lane. It is not nose-to-nose.
- **V3: stepping off the lane works on screen.**
  - At least one `dodge` sequence shows the player's creature off the lane at `mid` or `strike`.
  - The same strike logs `outcome=miss`, and the miss is presented (the "missed" caption or no impact).
- **V4: a hit reads.** At least one `stand` sequence shows an impact on the player's creature and an HP drop.

## Dell must show all of these
- **D1: the tell reads.** Each member's tell text and ground marking is legible in at least half of its tell-start frames.
- **D2: the composition reads.**
  - The three members are recognisably different creatures, by silhouette and type label.
  - At least one member shows type feedback: a "weakness" or "your type held" line, or a damage contrast.
  - Together these tell the player that the team is answered by switching.
- **D3:** every member has at least one strike avoided by moving (a logged miss) in the witness.

## Framing, over all fight frames of each fight
Tally per fight:
- **EXCLUDED:** C3_RUBRIC's excluded frames.
- **FAIL:** a frame hitting any of C3 clauses 1–5.
  - Clause 3 counts a person standing in the fight and covering a combatant's head.
  - The player's creature rendered as a see-through close-up counts as clause 2.

A fight passes framing at 90% or more PASS among its non-excluded frames.

## Witness
`smoke_named_fight_hit_avoid.gd` PASSes for Vance's Tuskroot and for each of Dell's three members: a landed player hit, a landed strike held still, and a strike avoided by moving.

## Verdict
- **PASS:** V1–V4, D1–D3, framing for both fights, and the witness all hold.
- **Non-blocking, reported:**
  - a HUD tint or legibility dip in one frame;
  - a fixture name in the HUD;
  - the 0.25 s occlusion clause (stills cannot test it).
