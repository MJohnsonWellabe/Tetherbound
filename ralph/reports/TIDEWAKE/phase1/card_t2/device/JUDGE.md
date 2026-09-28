# Tidewake card T2: device-profile readability judgement (7-inch, arm's length)

This was a code-blind judgement. I looked only at `_sheet_7inch.jpg`, which I viewed at native pixel size by cropping each row without rescaling, and at the full-size `explore/*.jpg` and `fight/*.jpg` frames. I used the full-size frames only to confirm what a detail was. Every readability call below comes from the 7-inch sheet cells. Glyph heights are given in 1080p pixels. On the 7-inch cell, multiply by about 0.3.

This is a Phase 1 function and readability read. It does not grade art quality or give a Bar A/B verdict.

## Device-profile read

### 1. HUD text legible at 7-inch: **NO** (mostly yes, with specific failures)

These items pass on the sheet:
- **Objective panel.** "MAIN STORY / Meet Pell at First Shore." is clear in every explore cell. It is the best-read element on screen.
- **Enemy name.** "Aquaryn" is clear in every fight cell.
- **Team list.** "TEAM 5/5", Ripplet, Bramblebun, Mudsnout, Pipwing and Trailpup, with their colour chips, all read.
- **Move names.** "Ripple Jab", "Undertow", "No orbs" and "Switch" read.
- **Tell lines.** "it's open — hit it" (hit-002.23, t-006.02, tell-ended-001.23, tell-ended-004.80) and "!! HEAVY — get clear" (tell-start-000.57, tell-start-004.10) read on close inspection.
- **Health number.** "100 / 100" reads.

The call is still NO because of these failures:
- **FOOD label by day.** It is tan-on-tan and disappears on sand in current-cradle-salt-crown-day, dock-reedhaven-arrival-day and veilfall-mid-salt-crown-day. Only the "100%" survives. The whole food panel's translucent fill goes sand-coloured, so at 7 inches the food meter reads as a smudge, not a bar.
- **Move-button trigger glyphs.** RT, LT and LB are about 9 px letters inside a 16 px plate, so on the device they are dots. The player can read *what* a move is but not *which button* fires it (every fight cell).
- **Explore quick-bind slots and prompt keys.** The five quick-bind slots show only tiny digit plates (1–5) on empty dark squares. The Map/Satchel/Build key glyphs (M/I/B) are about 9 px. Both are unreadable on the device, and they are keyboard glyphs on a controller-first build (every explore cell).
- **Enemy level and type.** "LEVEL 49" and "WATER" are about 18–20 px, readable only by leaning in. The level is the smallest line in the enemy plate even though it is a decision-relevant number.
- **Player panel sub-labels.** "Lv 43", "WIND" and "Energy" are about 18 px and marginal.
- **Clipped Undertow label.** The Undertow button has a grey sub-label (cooldown or cost) clipped under its name in t-000.00, hit-002.23, hit-002.57, tell-ended-001.23, tell-start-000.57 and tell-start-004.10. It is illegible at any size.
- **Night clock.** "Day 1 · 23:00" is mid-grey on navy and nearly vanishes on the sheet in all night cells.

The note "incoming — move" does not appear in any frame. The danger tell shown is "!! HEAVY — get clear".

### 2. Tells and danger legible: **YES** (marginal)

- **Ring.** The magenta ring under Aquaryn in tell-start-000.57 and tell-start-004.10 shows up against the green grass even on the sheet. It is the one saturated, non-natural colour on screen.
- **Banner.** The orange "!! HEAVY — get clear" line differs from the teal "it's open" line in colour and prefix.

Weaknesses (see the defects list):
- The ring is thin and dotted with no fill, about 15 x 5 mm on the device. It hugs Aquaryn's own footprint, so it shows *that* a heavy is coming but not *where not to stand*. In both tell-start frames Ripplet is already well outside it, so the ring says nothing about Ripplet's danger.
- The warning lives on the same small line, in the same place, as the neutral opening tell. The only difference is orange versus teal on a line about 8 px tall on the device, with no size, flash or position change.

### 3. Subjects legible: **NO**

**Fight frames**
- **Opponent.** Aquaryn is findable (white belly, upright stance).
- **Piloted creature.** Ripplet is findable by size, but the two creatures share the same teal/blue palette and nothing marks which one the player controls. There is no ownership ring or marker. In t-012.00, Ripplet faces the camera and the "my creature is the back-view one" cue is lost.
- **Trainer.** Not findable in under a second.
  - Absent or fully occluded: t-000.00, hit-002.23, hit-002.57.
  - Half-hidden behind Ripplet's tail: t-006.02.
  - Elsewhere (t-018.00, tell-ended-001.23, tell-ended-004.80, tell-start-000.57, tell-start-004.10), a brown figure about 8 x 25 px on the device cell, on brown-green grass, with no marker.
- **The "large alpha" does not read as large or alpha.** Aquaryn is about Ripplet's size in t-000.00 and t-018.00, and its plate has no alpha badge.

**Explore frames**
- **Docks.** Not picked out.
  - dock-reedhaven-arrival-day and -night show a sand flat, a grass bank, cliff walls and a tepee: no dock and no water.
  - dock-shellwatch-jetty-day and -night show a grassy hillside and boulders: no jetty and no water.
  - The only dock visible anywhere is a small jetty behind the fence in current-cradle-salt-crown-day and -night. Fence rails screen it and it reads as clutter at 7 inches.
- **Current.** Not picked out.
  - current-cradle-salt-crown-day and -night show faint white streaks behind the fence that read as surf, not a directional current.
  - current-sluice-veilfall-day and -night show a flat sea with glitter and no visible flow.
- **Distant waterfall.** Legible **by day only**.
  - Clear white vertical streak in current-sluice-veilfall-day and veilfall-mid-salt-crown-day. Faint in current-cradle-salt-crown-day.
  - At night it drops to a faint blue-on-blue dotted streak (current-sluice-veilfall-night, veilfall-mid-salt-crown-night, current-cradle-salt-crown-night) and is not identifiable on the sheet.
- **Trainer in explore.** Clearly legible in every explore cell (centred, about 25–30 px tall on the device, blue shirt and pack).

### 4. HUD keeps a safe area and does not cover the key action: **YES**

- **Margins.** All HUD panels sit about 55–60 px (about 3%) in from the edges, and nothing is clipped at the edges.
- **Fight layout.**
  - The enemy plate is top-centre.
  - The team list and player panel stack on the left quarter, over the scenery.
  - The move grid is bottom-right.
  - In every fight cell the creatures and the tell ring sit in the open centre and are not overlapped.
  - The plates are translucent.
  - Together the fight HUD covers roughly 22% of the screen. That is heavy for 7 inches, but it is not on the action.
- **Explore layout.** Everything stacks on the right edge. The one overlap is minor: the quick-bind bar's top edge cuts the feet of the NPC at right in current-sluice-veilfall-day and -night.

## Readability defects by frame

**All fight frames** (t-000.00, t-006.02, t-012.00, t-018.00, hit-002.23, hit-002.57, tell-start-000.57, tell-start-004.10, tell-ended-001.23, tell-ended-004.80)
- **F1.** RT, LT and LB trigger glyphs on the move buttons are unreadable at 7 inches. The binding for each move cannot be learned from the HUD.
- **F2.** Nothing marks the piloted creature. Ripplet and Aquaryn share a teal/blue palette and are told apart only by shape.
- **F3.** The trainer has no marker. At about 8 x 25 px on the device, brown on grass, the trainer can't be found at a glance.
- **F4.** "LEVEL 49", "WATER", "Lv 43", "WIND" and "Energy" are the smallest text on screen (about 18–20 px), which is too small for 7 inches.
- **F5.** The Undertow button has a clipped grey sub-label under its name, and it is illegible. Seen in t-000.00, hit-002.23, hit-002.57, tell-start-000.57, tell-start-004.10 and tell-ended-001.23.
- **F6.** Aquaryn does not read as a large alpha: similar size to Ripplet (t-000.00, t-018.00) and no alpha marker on its plate.

**t-000.00, hit-002.23, hit-002.57**
- **F7.** The trainer is not visible at all. It is off-frame or occluded behind Ripplet.

**t-006.02**
- **F8.** The trainer is half-hidden behind Ripplet's tail.
- **F9.** The blue hit or particle spray over the dark rock is low contrast and reads as noise, not impact.

**hit-002.23, hit-002.57**
- **F10.** Nothing on screen shows a hit landed. There is no visible impact effect on Aquaryn, and the enemy bar change is too small to notice at 7 inches.

**tell-start-000.57, tell-start-004.10**
- **F11.** The heavy-attack ring is a thin dotted outline hugging the enemy's footprint, with no fill. It marks the attacker, not the danger area, and does not show whether Ripplet is safe.
- **F12.** "!! HEAVY — get clear" sits on the same small line as "it's open — hit it". The only change is its colour (orange versus teal). There is no scale, pulse, flash or central banner, so it is easy to miss mid-fight on the device.

**All explore frames**
- **E1.** The five quick-bind slots are empty dark squares with about 9 px digit plates (1–5), which read on the device as a row of blank boxes. The digits are keyboard glyphs on a controller-first HUD.
- **E2.** The Map/Satchel/Build key glyphs (M/I/B) are about 9 px and keyboard-only. The words read; the buttons don't.

**current-cradle-salt-crown-day, dock-reedhaven-arrival-day, veilfall-mid-salt-crown-day**
- **E3.** The FOOD label and panel blend into the sand and disappear. Only "100%" is legible.

**All night explore frames**
- **E4.** The "Day 1 · 23:00" clock is grey on navy and nearly invisible.
- **E5.** No location title appears. The day frames show Tidal Cradle, Sluice Isle, Reedhaven and Shellwatch. This may be capture timing, but at night nothing on screen names where you are.

**dock-reedhaven-arrival-day and -night**
- **E6.** No dock and no water in frame. The frame named for the dock shows an inland sand flat between cliffs.

**dock-shellwatch-jetty-day and -night**
- **E7.** No jetty and no water in frame, only a grassy hillside and boulders. At night the scene is almost uniform dark teal grass. The trainer is the only readable subject.

**current-cradle-salt-crown-day and -night**
- **E8.** The only dock in the set sits behind fence rails and is broken up by them.
- **E9.** The "current" is faint white foam indistinguishable from surf, with no direction cue.

**current-sluice-veilfall-day and -night**
- **E10.** The sea shows no readable current.
- **E11.** Near-camera grass blades cover the lower-left third and cross the health and food panels, reducing panel contrast.
- **E12.** The quick-bind bar clips the NPC at right.

**current-sluice-veilfall-night, veilfall-mid-salt-crown-night, current-cradle-salt-crown-night**
- **E13.** The waterfall landmark goes blue-on-blue and can't be identified. It needs an emissive or moonlit highlight to hold as a night landmark.

## TOP FIXES

1. **Mark the three fight subjects in world space.**
   - Put a team-coloured ground ring or chevron under the piloted creature, distinct from the enemy's.
   - Give the trainer a small persistent marker or outline, and keep the trainer out from behind the creature, or show an occlusion silhouette.
   - Give the alpha an alpha badge on its plate and a scale that reads as larger than the player's creature.

   Today the trainer is missing or unfindable in 8 of 10 fight frames, and nothing marks which blue creature is the player's.
2. **Make the danger tell a zone, not a line of text.**
   - Draw the heavy's actual hit area as a filled, pulsing ground decal that grows through the windup, so the player can see whether they are inside it.
   - Promote "HEAVY — get clear" out of the enemy plate's small line into a larger, briefly flashing warning, so orange versus teal is not the only difference.
3. **Fix the HUD elements that fail at 7 inches.**
   - Enlarge the controller glyphs on the move buttons, quick-bind slots and Map/Satchel/Build prompts to at least the size of their labels, and show gamepad glyphs rather than keyboard 1–5/M/I/B.
   - Give the health and food panels an opaque dark backing so FOOD survives on sand.
   - Raise LEVEL, type, Lv, WIND and Energy to at least the team-list size.
   - Fix the clipped Undertow sub-label.

   Separately, the dock- and current-named explore frames do not show a dock or a current at all (E6, E7, E9, E10). The captures need re-aiming, or the features need a readable silhouette, before those can pass subject legibility.
