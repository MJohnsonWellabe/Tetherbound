# F04#6 "distinct aftermath per fight": the pass bar for the final judge round

This bar is written before any frame of the final round is rendered or seen, and it does not change after that. It is given to the code-blind judge unchanged, before the frames. Under the coordinator's 2026-09-28 22:04 rule this is the criterion's one final round. If it fails, the remaining defects go into STATE and to the coordinator, and no further round is started.

## Sources
- **ACCEPTANCE §6.1, F04:** the Warrens guardian, the relay officers, the three captains and the Warden "each have ... a distinct aftermath".
- **BOSSES §4.2–4.5:**
  - Each captain awards a Sigil.
  - Vance's defeat frees the captive and disables the relay.
  - The Warden's victory hands over the Heart and the Realm Key.
- **C3_RUBRIC (framing):** per-frame fail clauses 2, 3 and 4, applied here to the speaker in the victory shot, not to combatants.
- **Out of scope:**
  - The Warrens guardian's aftermath (the vault opening) is out of this round. It is criterion 0's physical door change, already judged with that criterion.
  - Bars A/B look-dev polish goes to Phase 2: materials, token art quality, portrait reuse.

## Frames
The six fights are rendered once, on `main` after #437 merges, with this command:

`tools/art_pipeline/capture_named_fight.gd --trainer=<id> --frames=4 --keep-alive --resolve=won --after-frames=16` (render.yml, 1280x720)

The ids are `captain_field` (Halder), `captain_riverwatch` (Oreth), `captain_ridge` (Vess), `relay_captain` (Vance), `relay_officer_dell` (Dell) and `warden_aldis` (Warden).

The judge sees only each folder's `a01`–`a12`, `99-after` and `RUN.txt`:
- **Lines frames:** the dialogue box is on screen.
- **Resume frames:** the box has closed.

## Per-frame fail clauses (lines frames)
- **L1:** the camera is inside or behind geometry. This includes the player's creature rendered as a see-through close-up.
- **L2:** the speaking trainer's head is covered by the player's creature, another person, scenery or a token.
- **L3:** the combat HUD is on screen: creature bars, move buttons or target reticles.

A fight fails framing if more than 2 of its lines frames hit L1–L3.

## Per-fight required beat
Each must be visible in the frames without reading the dialogue text.

| Fight | Required, visible | Fails if |
|---|---|---|
| Halder, Oreth, Vess | 1. Their Sigil token, with its own emblem, is on screen during the lines. 2. The Team Tether standard (the oxblood banner) is seen up in an early lines frame and then visibly lowering or gone in a later one. 3. Either the Sigil moves toward the player (at least two frames showing it closer to the player or shrinking into them) or the captain visibly steps away. | Any of 1–3 is missing, or the banner is already gone or near-invisible in the first lines frame and never seen up. |
| Vance | 1. His standard is seen up and then visibly struck during the lines. 2. He visibly steps aside or turns away in at least one frame where he is on screen. | Either is missing, or his only change is a banner that is already faint in the first frame. |
| Dell | He visibly steps aside or turns away in at least one frame where he is on screen and unobstructed. | Dell is not visible in any frame after his stand-down begins, or he is covered by the player's creature in all of those frames. |
| Warden | The Heart and the Realm Key are on screen during the lines, and they move toward the player or leave by the end of the resume frames. | Either token is missing, or both still float unchanged in `99-after`. |

## Distinctness across the six
Using only the frames, the judge sorts the six aftermaths. A pair **fails** if the two are indistinguishable apart from their text. Setting alone is not enough for a pair that shares the same token, the same beat and the same trainer model; at least one staged element must differ.

## Verdict
- **PASS:** every fight meets its required beat and passes framing, and no pair fails distinctness.
- **Non-blocking (reported, not failing):**
  - a token overlapping the trainer's body without covering the head;
  - token colours close to each other when the emblems differ;
  - a reused portrait or model;
  - the stills cannot show motion smoothness.
