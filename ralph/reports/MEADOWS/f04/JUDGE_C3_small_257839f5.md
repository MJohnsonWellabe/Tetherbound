<!--
Render runs, all at commit 257839f5:
  36448656597 warden-galewisp
  36448661302 halder-galewisp
  36448666493 vance-galewisp
  36448670804 vess-ripplet
  36448676438 oreth-ripplet
  36448680952 dell-ripplet
The frames are not committed in full. This verdict cites them by file name as they appear in each run's artifact.
Code-blind judge: only the JPG frames and fight_log.txt were read. No source, config, tests or reports were read.
-->

# C3 small-body framing judge, commit 257839f5

Scope: C3 framing when the player's creature is small (Galewisp, Ripplet), seen from the normal fight camera. This covers function and readability only. Art polish is out of scope.

## Per-fight results

| Fight (opponent) | (a) both visible, opponent head/body unobstructed | (b) tell and hit/miss readable | (c) no camera in geometry, no subject cut at the edge |
|---|---|---|---|
| warden_galewisp (Warden Aldis, Tuskroot) | PARTLY | PASS | PASS |
| halder_galewisp (Captain Halder, Tuskroot) | PARTLY | PARTLY | PASS |
| vance_galewisp (Captain Vance, Tuskroot) | **FAIL** | PARTLY | PASS |
| vess_ripplet (Captain Vess, Galecrest) | PARTLY | PASS | PASS |
| oreth_ripplet (Captain Oreth, Mosshell) | PASS | PASS | PASS |
| dell_ripplet (Officer Dell, Mosshell) | PARTLY (minor) | PASS | PASS |

### warden_galewisp: warden_aldis-*
- **(a) PARTLY.** Both creatures are in frame in every fight frame. The Tuskroot's face is clear in -01, t01-stand-mid, -03, -05, -06, -07, -08, t02-dodge-start, t02-dodge-mid and -10. The Galewisp's head and ears cover the Tuskroot's snout in -02 and -04. In t01-stand-strike the Tuskroot's face sits behind the Galewisp's wing and the hit burst. The indoor hall never covers either creature.
- **(b) PASS.** "!! HEAVY — get clear" appears under the opponent bar, and a magenta ring at the Tuskroot's feet sits fully in frame (t01-stand-start, t01-stand-mid, t02-dodge-start, t02-dodge-mid). On a hit the player sees a teal stagger ring plus "Camera STAGGERED — recovering" (t01-stand-strike, -04), and "it hit YOUR weakness" in t02-dodge-strike. Both strikes are logged as hits, which matches. Minor issue: the dark-orange feedback line has low contrast on the dark brick and stacks right under the tell line (t02-dodge-start, t02-dodge-mid).
- **(c) PASS.** The camera never enters the walls or props, and no fight frame cuts off a creature. The Galewisp was knocked out after two strikes ("Your creature is out of the fight." in -11), so this run covers only two tells. The post-fight exploration camera in -99-after cuts the Tuskroot at the left edge, but that is outside the fight camera.

### halder_galewisp: captain_field-*
- **(a) PARTLY.** The face is clear in -03, t01-stand-mid, t03-stand-start, t03-stand-mid, -10, -13, -14, -17, -22, -23, -24 and every r frame (r01 Tuskroot, r04 Burrowback, r08 Mosshell). The Galewisp's head covers the Tuskroot's snout and tusks in -02, -09, -11, -16, -20 and t01-stand-start. The hit dust cloud completely covers the Tuskroot's face in t04-dodge-strike and -18.
- **(b) PARTLY.** The tell text ("! incoming — move" and "it's open — hit it") reads cleanly. Hits are clear from the teal stagger ring and "Camera STAGGERED — recovering" (-04, t01-stand-strike, t03-stand-strike, -18, -19). The log records all six strikes as hits, which matches. The problem is the magenta danger lane and rectangle. They run toward the camera, under the bottom-left creature HUD panel and past the bottom edge of the frame (t01-stand-start, t01-stand-mid, -01, -10, -17, t04-dodge-start, t04-dodge-mid). As a result, the player cannot see where the danger zone ends.
- **(c) PASS.** The open field has no clipping, and both creatures stay whole in frame.

### vance_galewisp: relay_captain-*
- **(a) FAIL.** The Tuskroot stands pressed against the stone arch. The camera sits directly behind the Galewisp, on the line between the two creatures, so the Galewisp's head and tall ears sit over the Tuskroot's snout and tusks through most of the fight. It is partly covered in t01-stand-mid, -04, t02-dodge-start, -07, -09, t03-stand-start, t03-stand-mid, t04-dodge-start and t04-dodge-mid. It is fully hidden, face behind the Galewisp, in t03-stand-strike, -08, -10, -11 and -13. On top of that, a dark-clad human NPC stands inside the Tuskroot's silhouette, in front of its legs and chest (t01-stand-strike, t02-dodge-start, t04-dodge-start, -11, -13, -24, r01, r02). That breaks up the opponent's outline. The face is clear only in -02, -03, -05, t02-dodge-strike, -14, -20 and -22.
- **(b) PARTLY.** The tell text is readable. Misses read as "it missed you" at bottom centre in t01-stand-strike, -04, t02-dodge-strike, t03-stand-strike, -11 and -22, which matches the logged misses on strikes 1–3. The strike-4 hit shows as an impact burst (t04-dodge-strike), and a stagger ring appears in -18. As in Halder's fight, the magenta danger lane runs under the HUD panel and off the bottom edge (t01-stand-start, -03, -17).
- **(c) PASS.** The camera stays outside the arch and the wall. t04-dodge-strike swings to a wider angle but does not clip. No fight frame cuts off a creature.

### vess_ripplet: captain_ridge-*
- **(a) PARTLY.** The Ripplet sits front-left and the Galecrest right, and both are clear in -01, -02, -03, -07, -08, -12, -16, -17, -20, -22, -24 and every tell start/mid. The Ripplet's head and body cover most of the Galecrest in -06, -15 and -19. The hit burst clouds wash over the Ripplet and half the Galecrest in -04, -13, -18 and t02-dodge-strike, though the Galecrest's head stays visible in -04 and -13.
- **(b) PASS.** The tell text is readable, and the magenta danger rectangle plus ring sit entirely in frame (t01-stand-start, t02-dodge-start, t03-stand-start, t04-dodge-start). Hits read as a white burst plus "it hit YOUR weakness" (-04, -05, -13, -14, t02-dodge-strike). The tell is only 0.40 s long. The log writes t01-stand-strike, t03-stand-strike and t04-dodge-strike before each strike resolves, so the result shows in the next numbered frame. That is a capture-timing issue, not a framing one.
- **(c) PASS.** No clipping, and both creatures stay whole in frame.

### oreth_ripplet: captain_riverwatch-*
- **(a) PASS.** In every fight frame the Ripplet stands left of centre and the Mosshell right of it, both unobstructed, with the Mosshell's head readable throughout (t01-stand-start through -23). The only small overlap is in -24, where the Ripplet faces the camera in front of the Mosshell's flank with its head still clear. During the team resolution, the Ripplet partly covers Trailpup (r04) and the Burrowback (r10). r14 shows a downed creature mostly behind the Ripplet.
- **(b) PASS.** The tell text is readable, with a magenta ring at the Mosshell's feet fully in frame (t01-stand-start, t02-dodge-start, t03-stand-start, t04-dodge-start, -09, -18, -19). The logged misses show "it missed you" (-06, t04-dodge-strike, -15), and the hits show a burst over the Ripplet (-02, -10, t03-stand-strike).
- **(c) PASS.** The wooden banner post at left stays clear of both creatures (-06, t02-dodge-strike, t04-dodge-strike). There is no clipping and no cut-off creature. The Ripplet cut at the left edge in -00-before and on the right in r16 are both from the exploration or dialogue camera, not the fight camera.

### dell_ripplet: relay_officer_dell-*
- **(a) PARTLY (minor).** Both creatures are visible in every fight frame, and the Mosshell's head stays readable throughout. The Ripplet's head overlaps the left edge of the Mosshell's shell in -01, -02 and t01-stand-mid. The red banner in the arena covers the Mosshell's rear or flank in -22, -24, r01 and t04-dodge-mid. In r06 the Burrowback sits partly behind the Ripplet's tail.
- **(b) PASS.** The tell text and the magenta foot ring are readable (t01-stand-start, t02-dodge-start, t03-stand-start, t04-dodge-start, -18). Misses read as "it missed you" (t02-dodge-strike, -07, -15), and hits as a burst plus the opponent's bar dropping (t01-stand-strike, t03-stand-strike).
- **(c) PASS.** The courtyard stairs and walls stay behind the action, and no fight frame cuts off a creature. The Ripplet filling the frame edge in -00-before, -a12 and -99-after comes from the exploration camera.

## Overall

**C3 SMALL-BODY FRAMING: FAIL — blocking: in vance_galewisp the fight camera sits on the line from the Galewisp to the Tuskroot. With the opponent pinned against the arch, the small Galewisp's head and ears cover the Tuskroot's snout and tusks through most tells and fully hide its face at strike moments (t03-stand-strike, -08, -10, -11, -13). An NPC also stands inside the opponent's silhouette (t02-dodge-start, t04-dodge-start, -11, -13).**

The camera never enters geometry and never cuts off a creature in any of the six fights, so (c) passes throughout. The tell text and hit/miss feedback are readable in all six. The Ripplet fights, and Oreth's in particular, frame cleanly. The occlusion that fails Vance's fight also shows up, less often, in Warden's, Halder's and Vess's. It is one camera-placement pattern, not a single bad spot.

## Ranked defects

1. **The player's creature covers the opponent's face at melee range** (vance_galewisp: t03-stand-strike, -08, -10, -11, -13, plus partial cover in t02-dodge-start, t03-stand-start, t04-dodge-start; also halder -02, -09, -11, -16, t01-stand-start; warden -02, -04; vess -06, -15, -19). The camera trails directly behind the player's creature on the line to the opponent. The Galewisp's upright ears in particular project onto the opponent's head, which sits low. A small creature should always leave the opponent's head clear, for example through a higher camera or a sideways offset at close range.
2. **An NPC stands inside the opponent's silhouette** in the Vance arena (t01-stand-strike, t02-dodge-start, t04-dodge-start, -11, -13, -24, r01, r02). A human figure clips through the Tuskroot's legs and chest and breaks up its outline.
3. **The danger lane's far edge is hidden under the HUD and off-frame** (halder t01-stand-start, t01-stand-mid, -01, -10, -17, t04-dodge-start; vance t01-stand-start, -03, -17). The player sees that they are inside the zone but cannot see where it ends.
4. **Hit VFX hides the opponent's head at impact** (halder t04-dodge-strike, -18; vess -18, t02-dodge-strike; warden t01-stand-strike). The hit still reads, but the opponent's reaction does not.
5. **An arena prop covers the opponent** (dell -22, -24, r01, t04-dodge-mid): the red banner overlaps the Mosshell's body, though its head stays readable.
6. **The orange feedback text has low contrast** on dark brick and bright grass, and stacks directly under the tell line (warden t02-dodge-start, t02-dodge-mid; halder -09, -19). It is readable at 720p but is the weakest text on screen.
7. **Coverage limits (not a framing defect).** The warden run ends after two tells because the Galewisp was knocked out (-11 "Your creature is out of the fight."). In vess, three strike frames were captured before the strike resolved (per the log order), so the hit shows only in the next numbered frame.
