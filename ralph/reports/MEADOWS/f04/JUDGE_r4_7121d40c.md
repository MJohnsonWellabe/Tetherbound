<!-- Render runs judged, all at commit 7121d40c:
     36444470231 halder (captain_field)
     36444485821 warden (warden_aldis)
     36444458864 vance (relay_captain)
     36444464477 dell (relay_officer_dell)
     36444475773 vess (captain_ridge)
     36444480302 oreth (captain_riverwatch) -->

# F04 fight judge, round 4, commit 7121d40c

The frames are not committed in full because of their size. This verdict cites them by file name,
using the prefixes captain_field / warden_aldis / relay_captain / relay_officer_dell / captain_ridge /
captain_riverwatch. I judged without reading the code. I read only the JPG frames and each fight_log.txt.

## Strike outcomes from the logs, set against the policy

| Fight | Stand strikes | Dodge strikes | Note |
|---|---|---|---|
| Vance (charger) | 1 miss, 2 hit | **3/3 hit** | Stand missed and every dodge was hit. The "step off the lane" answer did not work once. |
| Halder (charger) | 3/3 hit | 2/3 hit | Stepping off the lane mostly failed. |
| Dell (Mosshell opener) | 3/3 hit | 2/3 hit | |
| Vess (diver) | 2/2 hit | 1/1 hit, tell 4 never struck | 0.40 s tell. The fight ended before strike 4. |
| Oreth (wall) | 3/3 hit | 0/2 hit | Consistent. |
| Warden (heavy) | 3/3 hit | 0/2 hit | Consistent. |

With these results the harness cannot show that either charger question can be answered. In
Vance's capture the outcome is the inverse of the intended lesson.

---

## Vance (relay captain), Tuskroot CHARGER, "step off the lane"

- **Q1 FAIL.** The lane is not readable as a lane. In `relay_captain-t01-stand-start` / `-t01-stand-mid`
  it renders as broken magenta shards scattered on the dirt and yellow floor tiles, mostly underneath
  the player's creature. In `-t02-dodge-start` / `-t02-dodge-mid` it is a short smear beside the boar,
  and a dark-armoured Team Tether bystander stands inside the arena at the boar's snout, in the lane.
  The tell text is the generic `! incoming — move`, which is identical to Halder's, Vess's, Oreth's and Dell's.
  The log also contradicts the question. Standing still got "it missed you" (`-t01-stand-strike`),
  and all three dodges were hit.
- **Q2 PARTLY.** The miss is readable: the caption "it missed you" in `-t01-stand-strike`. The hit in
  `-t04-dodge-strike` is readable from "Camera STAGGERED — recovering" and a cyan ring, and
  `-t03-stand-strike` shows an impact burst. The logged hit in `-t02-dodge-strike` (23.7) has no marker:
  no caption, no ring, only faint dust over the boar. It cannot be told from a whiff.
- **Q3 PARTLY.** In `-a01` / `-a05` the victory lines play ("Station's yours…", "Take our prisoner
  too…"), the combat HUD is gone, Vance stands to the player's right, and the banner is mid-fade as a
  translucent pink column. A red-haired figure (the prisoner) is visible down the lane. Problems:
  Vance's head is bowed and the face cannot be read. By `-a10` the camera has swung and the player's body
  completely covers Vance, with the rock creature cut off at the right edge. The portrait is **the same
  white-haired eyepatch portrait used for Halder**, and the model looks the same too. By `-a16`/`-a22`/`-99-after`
  the banner is gone and Vance stands beside the player's creature. The staged change is "banner
  removed", the same as three other captains, plus the prisoner figure.
- **Q4.** The bystander NPC is inside the fight lane (`-t01-*`, `-t02-*`). In `-r02` the player creature's
  rear fills the frame centre and hides the boar's head. In `-t03-stand-strike` the stagger flash washes out
  the player creature. In `-a10` the player body blocks the trainer.
- **Overall: FAIL.** The named question is neither shown nor answerable in this capture.

## Dell (relay officer), composition, Mosshell opener tells only

- **Q1 PARTLY.** The Mosshell opener shows a magenta ring around the turtle and the generic
  `! incoming — move` (`relay_officer_dell-t01-stand-start`, `-t04-dodge-mid`). Nothing in the tell says
  how the Mosshell should be fought *differently* from the later Burrowback or Galecrest. The
  composition itself is only visible in the resolve frames (`-r08` Galecrest). No Burrowback frame was seen
  that shows a different read.
- **Q2 PASS.** The hit is "▼ it hit YOUR weakness" (`-t01-stand-strike`, `-t04-dodge-strike`). The miss is
  "it missed you" (`-t02-dodge-strike`). The two are distinct and match the log.
- **Q3 PARTLY.** In `-a01` Dell is framed clearly walking out of the arch, with his own line ("Beaten
  cleanly, at my own post…") and the HUD down. In `-a05` he has stepped aside against the arch wall, with
  a second line. This is the one distinct staged beat. But from `-a08` through `-a12` to `-99-after`
  the camera sits behind the player's rock creature, whose back covers about 40% of the frame. Dell is
  out of frame and the arch is empty. Apart from Dell moving, no world change is visible.
- **Q4.** In `-00-before` the creature body fills the left third. In `-r03` the camera is directly behind
  the creature. In `-r08` the player creature's shoulder covers the Galecrest's head. In `-t02-dodge-mid`
  the player creature turns to face the camera. Tell 4 fires with the cartoon face in the foreground and the
  turtle pushed to the back.
- **Overall: PARTLY.** The tells and outcomes are readable. The composition question and the aftermath world change are not shown.

## Halder (field captain), Tuskroot CHARGER, exposed field

- **Q1 PARTLY.** This is the best lane in the set. In `captain_field-t01-stand-start` and
  `-t02-dodge-mid` a solid magenta rectangle runs from the boar through the player's creature on
  open grass, seen from a high camera. But the player's creature stands in the lane in both dodge
  frames and never visibly leaves it (`-t02-dodge-mid` → `-t02-dodge-strike`). In the log, 2 of 3
  dodges were hit.
- **Q2 PARTLY.** The miss is clear ("it missed you", `-t04-dodge-strike`). The hit in
  `-t01-stand-strike` shows only a dust cloud with no caption or ring. The logged hit in
  `-t02-dodge-strike` shows nothing: the player creature's body completely hides the boar's head,
  and there is no marker.
- **Q3 PARTLY.** In `-a01`–`-a03` the line plays ("Clean. No arguing with clean.") with the HUD down. The
  banner is a translucent ghost in `-a01` and gone in `-a02`. But the interact marker disc sits on
  Halder's face and shoulder. The player's head fills the lower centre. The portrait is the one Vance
  also uses. In `-a12` / `-99-after` Halder stands up-slope beside the player's creature, and the gallows is
  empty. The staged change is again only the banner removal.
- **Q4.** In `-t02-dodge-strike` the player creature covers the opponent's head. The gallows post is in the
  lower-left foreground over the player (`-t02-*`, `-t04-*`). A stray wild creature sits top-left next to
  the name plate (`-t01-stand-strike`, `-t02-*`).
- **Overall: PARTLY.** The lane reads, but the dodge does not visibly clear it, and two of three hits are unmarked.

## Oreth (riverwatch captain), Mosshell WALL, patience then punish

- **Q1 PARTLY.** The punish half is readable. "↯ it's open — hit it" appears, and the player's hits into the
  shell get "▼ WEAK — it shrugged that off" (`captain_riverwatch-t04-dodge-strike`), which does teach
  "don't chip the wall". The patience half has no visible wall state. The Mosshell looks the same in
  `-t01-stand-start`, `-06` and `-14`, with no closed or shell-up pose. The tell is the generic
  `! incoming — move`.
- **Q2 PASS.** The hit is "▼ it hit YOUR weakness" (`-t01-stand-strike`). The misses are "it missed you"
  (`-t02-dodge-strike`, `-t04-dodge-strike`). All match the log.
- **Q3 PARTLY.** `-a01`/`-a05` show the lines ("A plan, then. Good.", "One more sigil…") with the HUD down and
  Oreth unobstructed to the player's right. The banner is a translucent ghost in `-a01` and gone in
  `-a05`. In `-99-after` Oreth stands off the path to the right of the empty gallows. The interact disc
  sits beside his head. The staged change is the same banner removal as Halder, Vance and Vess, so it is
  not distinct.
- **Q4.** In `-06` the player creature turns to face the camera and dominates the frame. In `-r08` the player
  creature partly covers the Burrowback's head. `-00-before` has the creature body over the left third.
- **Overall: PARTLY.** Outcomes are the clearest in the set. The wall state and a distinct aftermath are missing.

## Vess (ridge captain), Galecrest DIVER, positional read

- **Q1 FAIL.** The diver uses **the same magenta lane rectangle plus ring as the Tuskroot charger**
  (`captain_ridge-t01-stand-start`, `-t02-dodge-mid`). Nothing marks altitude, a dive point or a
  landing zone, so the diver reads as a charger. The tell lasts 0.40 s.
- **Q2 FAIL.** The logged hits carry no hit marker. In `-t02-dodge-strike` (hit 13.0) the player
  creature has turned to face the camera and hides the Galecrest, with no caption. In `-t03-stand-strike`
  the only caption is the player's own "▲ STRONG — you hit a weakness". Tell 4 (`-t04-*`) never strikes.
  The only clear state in the whole capture is `-12`'s "STAGGERED — punish now", and that is the opponent's stagger.
- **Q3 PARTLY.** `-a01`/`-a04` show the lines ("You read the gusts…", "The Ridge Sigil, then…") with the HUD
  down. The banner is a translucent ghost in `-a01` and gone in `-a10`. But Vess stands *behind* the
  "Watchtower Spur" signpost, under the gallows rather than to one side, and the interact disc
  covers her chest. Her face is dark and small in frame. By `-a10`/`-99-after` she is a distant figure, and
  the player's creature's rear blocks the right third in `-a10`.
- **Q4.** The signpost occludes the trainer (`-a01`, `-a04`, `-r02`). In `-t02-dodge-strike` the creature faces
  the camera and covers the opponent. In `-t04-dodge-start` the player creature covers the Galecrest's lower body.
- **Overall: FAIL.** The diver cannot be told from a charger, and hits cannot be told from misses.

## Warden Aldis (final boss), Tuskroot HEAVY, "get clear"

- **Q1 PARTLY.** This is the only fight with a named tell: `!! HEAVY — get clear`, plus a magenta ring round the
  boss (`warden_aldis-t01-stand-start`, `-t02-dodge-start`). The question reads. But in `-t04-dodge-start`
  the camera is wedged between two pillars, with black geometry covering both side thirds.
- **Q2 PARTLY.** The hit is "Camera STAGGERED — recovering" with a cyan ring and impact star
  (`-t01-stand-strike`, `-t03-stand-strike`). The miss is "it missed you" (`-t02-dodge-strike`). In
  `-t04-dodge-strike` (a logged miss) the camera is half inside a black pillar and the caption is the
  player-attack message "missed — too far, or facing the wrong way", not "it missed you", so the
  avoided strike is mislabelled. `-18` is fully inside wall geometry, and `-r01` has a wall over the left third.
- **Q3 PARTLY.** In `-a01` the Warden is centred and unobstructed with the HUD down, holding up a gold
  **Realm Key**, while the line names it. In `-a06` the line names the **Heart of Meadows**, but no Heart
  object can be identified. There is only a small white puff shape to his left, which could be anything.
  The key is a flat, icon-like shape beside his head. The banners in `-a10`/`-99-after` have ragged,
  torn lower edges where `-00-before` shows clean swallowtails. This may be a staged change, but it is
  subtle, and the Warden is a tiny far figure by then. The objective does change to "Open the village gate…".
- **Q4.** `-t04-dodge-start` has pillars on both sides, `-t04-dodge-strike` is half inside a pillar, `-18` is fully
  inside the wall, and `-r01` has a wall slab on the left. The boss's head is visible in most other frames.
- **Overall: PARTLY.** The tell and the key beat work. Camera clipping and the missing Heart of Meadows keep it from passing.

---

## Ranked defects

1. **The charger question fails in play (Vance, Halder).** The Vance log has a stand miss and 3/3 dodge hits. Halder has 2/3 dodge
   hits, and in `captain_field-t02-dodge-mid`→`-strike` the player creature never leaves the lane. Either
   the dodge cannot clear the lane or the harness dodge direction is wrong. The capture cannot prove the
   lesson.
2. **Vance's lane is not a lane.** It renders as fragmented magenta shards under the player creature, and a
   bystander NPC stands in it (`relay_captain-t01-stand-start`, `-t02-dodge-start`).
3. **Diver = charger.** Vess's Galecrest shows the identical lane-rectangle tell (`captain_ridge-t01-stand-start`), with a 0.40 s window.
4. **Camera inside geometry during the final boss:** `warden_aldis-18` fully in the wall, `-t04-dodge-start`,
   `-t04-dodge-strike`, `-r01`.
5. **Unmarked hits.** Logged hits show no hit feedback in `relay_captain-t02-dodge-strike`,
   `captain_field-t02-dodge-strike` and `captain_ridge-t02-dodge-strike`, and `warden_aldis-t04-dodge-strike` shows the wrong
   caption for an avoided strike.
6. **The aftermath world change is not distinct.** Halder, Vance, Oreth and Vess all use the same banner fade
   (a translucent ghost in `-a01`, then gone). Only Vance's prisoner figure and Dell's step-aside differ. The Heart of
   Meadows is never visibly shown (`warden_aldis-a06`).
7. **Trainer occlusion during victory lines.** The interact marker disc sits over Halder, Oreth and Vess
   (`captain_field-a01`, `captain_riverwatch-a01`, `captain_ridge-a01`). A signpost covers Vess. The player
   body covers Vance (`relay_captain-a10`). The player's creature fills the post-line camera in the
   `relay_officer_dell-a08`…`-99-after` frames with Dell out of frame.
8. **Identity collision.** Captain Halder and Captain Vance share the same white-haired eyepatch portrait and model
   (`captain_field-a01`, `relay_captain-a01`).
9. **The player creature covers the opponent's head** in `captain_field-t02-dodge-strike`, `relay_captain-r02`,
   `relay_officer_dell-r08`, `captain_riverwatch-r08` and `captain_ridge-t02-dodge-strike`. The creature also turns to face the camera
   during tells (`captain_riverwatch-06`, `relay_officer_dell-t04-dodge-mid`).
10. **Generic tell text.** Every captain uses `! incoming — move`. Only the Warden names the question.
11. **Stale objective.** "Go down and hear Grandpa out." stays on screen after every captain win (all `-a01`).

## Per-fight overall

- **Vance (relay captain): FAIL.** The lane is unreadable and a bystander stands in it. Standing avoided the charge and every dodge was hit. The aftermath lines work, but the portrait duplicates Halder's.
- **Dell (relay officer): PARTLY.** The tells and hit/miss are readable. The composition read is not shown. The step-aside beat lands, but the camera then buries Dell behind the player's creature.
- **Halder (field captain): PARTLY.** The clearest lane in the set, but the dodge never visibly clears it and 2 of 3 hits are unmarked. The aftermath is only the banner fade, with the marker over his face.
- **Oreth (riverwatch captain): PARTLY.** Best hit/miss feedback. The wall/patience state is invisible, and the aftermath is the shared banner fade.
- **Vess (ridge captain): FAIL.** The diver tell is identical to the charger's, hits are unmarked, and the trainer is behind a signpost in the aftermath.
- **Warden Aldis (final boss): PARTLY.** The HEAVY tell and Realm Key beat read. The camera clips into walls, the avoided strike is mislabelled, and the Heart of Meadows is not visible.
