# F42#2 / F10#6 code-blind verdicts (coordinator)

## r1 (Sun 11 Oct, 11:30 PM CT, 78270a4fb): FAIL
During the CHARGE telegraph the HUD switched to a legacy layout (no ultimate ring, a "[jump]" glyph token, no command fill). At 800p the command block faded to ~20% opacity.

## r2 (Mon 12 Oct, see the board timestamp; tb/ev-systems-b 2992b416e): PASS
Twelve frames: one live fight at 1920×1080 and 1280×800, frames 00–04 in-fight (including two CHARGE frames) and 05 after the fight. One code-blind judge, no code.
- The ultimate meter (RB ring + %), the command meter ("Commands N/100" with a track and fill, four costed commands) and the face-button move diamond are present in every in-fight frame, with one consistent layout.
- The HUD stays at the edges and corners. The fight, its telegraphs and the target stay clear.
- 7-inch readability: primary text about 17–26 px and secondary about 16 px at 800p; nothing cut off or faded.

Follow-ups, not blocking:
- B1: the threshold ticks don't sit above their command labels.
- B2: the D-pad direction arm is about 4 px at 800p.
- Minor: letter-only button glyphs differ from the round icons used in exploration; Sparkit's portrait reads as a placeholder; the unlabelled orange enemy sub-bar; a stray "9" in post-fight frame 05.

## r3 offline trainer duel (7:52 AM CT Mon 12 Oct; tb/ev-systems-b 88fda65d2, fixes fb140af94 + e2e397d88): WEAK
Eight frames: Oreth duel, no deployment, at 1920×1080 and 1280×800. One code-blind judge, no code.
- Fixed: one layout in every frame (ultimate ring, command meter with four costed slots, move diamond); no "[jump]" or legacy grid; the command label is at full opacity at 800p.
- Blockers:
  - No frame shows any meter fill (Commands 0/100 and Ultimate 0% even after "WEAK — it shrugged that off"). Verify that the meter fills in offline duels.
  - Dimmed command-slot labels are about 55% brightness with no backing ("Rally 50" over the lit path is about 1.3:1 at 800p).
  - strike and out-hit frames are byte-identical.
- Minor: no plate on the move cluster; a telegraph tail under the LB/RT bar; "B No utility", "60 —" and "incoming — move" wording.
