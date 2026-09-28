# F04 boss capture judge, round 2 (build 17a80aa4)

Code-blind judge. Inputs: the JPG frames and `fight_log.txt` in each capture folder. No source, config, tests or reports were opened. Art quality (Bars A/B) is deferred for this phase, so it is noted but does not fail anything.

## A: Warden Aldis, live ace Tuskroot (ACE HEAVY)

**Q1 Tactical question readable: PARTLY.**
- The HUD makes the question clear. The banner reads "!! HEAVY — get clear" (08, 12, t01-start/mid, t02-start/mid, t03-start/mid, t04-start/mid), a magenta ring sits under Tuskroot, and "it's open — hit it" follows the strike (04, 24, t01/t02/t03/t04-strike).
- The creature itself shows no big final-exam blow. Tuskroot's pose barely changes from start to mid (t01, t03). The ring only hugs Tuskroot's feet, so it does not show the danger area.
- The recovery window is never seen on the body. In every strike frame Tuskroot is behind the player's creature or off-screen (t01, t03, t04 strike).

**Q2 Tell readable, hit vs avoided: PARTLY.**
- Hit and avoided look different. On a stand, a bright impact burst lands on Camera and its HP drops (t01-stand-strike, t03-stand-strike; the log records hits of 37.4 and 37.7). On a dodge, Camera is displaced and the text says "it missed you" (t02-dodge-strike).
- t04-dodge-strike does not show "it missed you". It shows "missed — too far, or facing the wrong way", which reads as feedback on the player's own attack. Tuskroot is also off-screen in that frame.
- The windup is carried by HUD text and the ring, not by the body.

**Q3 Framing: FAIL.**
- **The creature fills the frame:** Camera fills the center of 12, 16, 20 and 24, and covers most of Tuskroot in t03-stand-strike.
- **Wall geometry against the camera:** a dark wall fills the left 35–40% of 08 and 20. In t04-dodge-strike the right third is a black/green wall and Tuskroot is gone except a tusk tip.
- **The resolution frames lose the boss:** in r01 and r02 the camera is almost inside Camera's back, and Tuskroot is not visible at the moment the fight resolves.

**Q4 Aftermath: PARTLY.**
- These parts work:
  - The combat HUD is gone in a01–a06.
  - The objective changes from "Go down and hear Grandpa out" (00-before) to "Open the village gate and follow the road in" (a01 onward, 99-after).
  - A key icon and a heart icon float beside the Warden in a01–a24.
- These parts do not:
  - The Warden is small, about one fifth of frame height, and dim in the dialogue shot (a01).
  - A mossy green mass crowds the left third in a01–a03, and an orange paw crowds the left edge in a04–a06.
  - The Realm Key and Heart are only floating icons. Nothing hands them over, no pickup toast appears, and the hotbar still shows the same x2/x4 items. The icons simply vanish at a25.

**Overall: PARTLY, not accepted.** The climax reads through HUD text, but the camera loses the boss at the key moments and the handover of the rewards is never shown.

## B: Captain Oreth, opener Mosshell (WALL)

**Q1 Tactical question readable: PARTLY.**
- The opening after the heavy is readable: "it's open — hit it" appears after each strike (12, 16, 20, t01/t02/t03/t04-strike).
- The idea of a guarding creature that punishes approach is not shown at all. The tell uses the same generic "! incoming — move" as the other fights, and the magenta ring only hugs Mosshell's base (01, t01-start, t02-start).
- There is no guard pose, no approach zone and no punish radius. Camera stands next to Mosshell the whole fight. As shown, this plays as the same telegraph, dodge, punish loop as C.

**Q2 Tell readable, hit vs avoided: PASS (with caveat).**
- Each tell follows the same sequence: the ring and "incoming" banner appear, Mosshell lowers and lunges slightly, then the strike lands.
- A hit shows blue water mist, the red text "it hit YOUR weakness" and an HP drop (t01-stand-strike, t03-stand-strike). An avoided strike shows "it missed you" (t02-dodge-strike, t04-dodge-strike, 16).
- Caveat: the hit mist is faint and spread toward the screen edges rather than at the point of contact, so the text does most of the work.

**Q3 Framing: PARTLY.**
- There is no camera clipping, and the meadow reads clearly.
- Mosshell is small next to Camera and often sits behind Camera's shoulder (08, 12, 16, t04-dodge-start).
- In 20, dust from an impact hides Camera.
- The follow-up members Trailpup (r04–r06) and Brooktail (r07–r08) are clearly named in the HUD, so it is always clear who is fighting.

**Q4 Aftermath: FAIL.**
- The dialogue shot works: player and captain are both framed and the HUD is gone (a01–a09), although the player creature's face crowds the top-left (a02–a09).
- Nothing in the world changes:
  - The red standard is identical before and after the fight (00-before vs a10–a28).
  - Oreth just wanders idly (a13–a28).
  - The objective stays "Go down and hear Grandpa out".
- The only change is the prompt, which goes from "Challenge" to "Greet Captain Oreth" (a10–a14).
- The "one more sigil" that Oreth mentions is never shown.

**Overall: PARTLY.** This is the most readable of the three fights, but the WALL identity does not come through visually and the win leaves no visible mark.

## C: Captain Vess, live Galecrest (DIVER)

**Q1 Tactical question readable: PARTLY.**
- The lane is shown. A magenta strip runs from Galecrest through the player (t01–t04 start/mid).
- There is no long positional cue. The log gives each tell a total of 0.40 s. Galecrest stays next to the player from start through strike in every tell, so it never visibly repositions or dives along the lane.
- Because Galecrest starts so close, the lane is short and mostly hidden under Camera's body (t01-stand-strike).

**Q2 Tell readable, hit vs avoided: FAIL.**
- The start to mid change is visible: the wings raise.
- The strike frames show no difference between outcomes. None has an impact effect, "it hit" text or "it missed you" text. Compare t01-stand-strike (logged hit, 13.5), t02-dodge-strike (logged miss) and t04-dodge-strike (logged hit, 13.6).
- In t04-dodge-strike the player dodged, but Camera's body still sits on the lane. With a 0.4 s window and a creature this large, the dodge did not clear the lane in one of the two tries.

**Q3 Framing: PARTLY.**
- Galecrest is a good size and readable, and the camera is clean.
- Camera covers part of Galecrest and most of the lane (t01-stand-strike, t03-stand-strike, r01/r02).
- Wild rock-backed badger creatures sit at the arena edge (t01 top-left, t02, t04, 00-before, and a27–a28 at the right edge). They are a mild source of confusion about who is in the fight.

**Q4 Aftermath: FAIL.**
- Vess shows only as a small figure behind the signpost in a01. From a02 to a09 the player's creature hides her completely during her own victory lines.
- The downed Galecrest shows only as a wing tip (a01–a03).
- Nothing changes afterward. The banner and the objective stay the same, and "The Ridge Sigil" she hands over is never shown (a10–a28).

**Overall: FAIL.** The lane is the one strong element, but the outcome of the strike is invisible and the victory scene is hidden.

## Ranked defects

1. **The Warden arena camera loses the boss.** In r01 and r02 Tuskroot is not visible at resolution because the camera is buried in Camera's back. In t04-dodge-strike the right third is a wall and Tuskroot is off-screen. Dark wall mass fills 35–40% of 08 and 20. Camera covers Tuskroot in 12, 16, 24 and t03-stand-strike. This is the region's final exam, and its key moments are unreadable.
2. **The DIVER strike has no outcome feedback and no positional cue.** The strike frames of t01, t02, t03 and t04 look the same whether the log records a hit or a miss. The whole tell is 0.40 s, and Galecrest never repositions or dives. In t04-dodge-strike the dodge ended with Camera still on the lane and took a hit.
3. **The victory dialogue shots are occluded.** In C a02–a09 Vess is fully hidden behind the player's creature. In A a01–a06 the Warden is small and dim, with a mossy mass or paw filling the left third. In B a02–a09 the creature's face crowds the top-left.
4. **Winning against a captain changes nothing visible.** In B and C the standards, captain placement and objective stay the same (00-before vs a10–a28). The sigils named in the dialogue ("one more sigil", "The Ridge Sigil") are never shown or awarded on screen. The Warden's Realm Key and Heart are floating icons that vanish at a25 with no handover or pickup confirmation.
5. **HUD text carries the tactical identity, not the creatures.**
   - The WALL has no visible guard or approach-punish zone (B t01–t04).
   - Tuskroot's HEAVY windup barely changes its pose (A t01 and t03, start vs mid).
   - Both captains use the same "! incoming — move" wording.
   - A t04 shows "missed — too far, or facing the wrong way" where "it missed you" is expected.

## Notes, not failed

- Both captains stand beside crimson standards (B throughout, C 00-before and t03). The owner should confirm this does not clash with the rule that oxblood and red are reserved for Team Tether.
- Art (Bars A/B, deferred): the Meadows exterior reads lush and coherent. The Warden hall is very dark, and the Warden's face is unlit in a01.
- The fight log for A says the ace was fought only after the earlier members "resolved: disclosed". Only the ace's tells are judged here.
