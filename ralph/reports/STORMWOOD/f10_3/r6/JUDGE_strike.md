# Lightning ground warning: code-blind visual judgement

Frames judged: seq_t000 to seq_t170 (19 frames, including t125), normal third-person camera, HUD hidden. I looked only at the images.

## Q1. Danger zone: PASS
- **Frame t000:** The zone is clear from the first frame. A thick, saturated magenta ring lies flat on the dark path and wraps around the trainer. The inside has a dim magenta tint. It stands out against the brown ground and green grass, and nothing else in the scene uses that colour.
- **Size estimate:** At the trainer's depth, the trainer is about 170 px tall, so 1.80 m is about 170 px. At that same depth the ring spans about 520 px, or roughly 5.5 m. That gives a **radius of about 2.8 to 3 m**. The widest part of the ellipse, about 750 px near the bottom of the frame, fits the same size. It matches the intended 3 m.
- **Position:** The trainer stands at or near the centre, where the cracks later meet. Because of the low camera, the far half of the ring is squashed into about 40 px behind the trainer's feet. That makes forward look like the short way out, but the real distance is about 3 m in every direction. This is a minor misread, not a failure.

## Q2. Time left: PARTIAL
- **Progress is readable:**
  - t000 to t090: jagged cracks grow inward from the rim and reach the trainer's feet at about t080 to t090.
  - t100: the inside fills with pink.
  - t110: the inside turns almost white and the rim goes white.
  - A player can tell the warning is building toward something that ends at the centre.
- **The last moment to leave is not marked:**
  - The rim looks the same from t000 to t090, and the cracks grow at a steady rate, so no frame says "go now".
  - The only strong cue, the fill change at t100 to t110, comes 0.1 to 0.2 s before impact. A player at the centre cannot run 3 m in that time.
  - The real deadline for leaving from the centre is about t060 to t070, and nothing on screen changes at that point.
  - The cracks also look nearly complete from about t050, so their growth stops working as a clock during the second half.

## Q3. Impact: PASS
- **t120 to t130:** A clear, branching white bolt comes down from the top of the frame and ends at the trainer's feet, where the cracks meet. Small arcs spread over the ground inside the ring, and the rim flares white. The trainer takes on a red-pink hit tint. It reads clearly as lightning striking this zone.
- **t140:** The ring fades to a faint outline. By t150 it is gone.
- **Minor issues:**
  - The bolt's long upper-right branch at t120 to t130 ends in mid-air near the top of the cyan pylon (about x 850, y 280). It could briefly look like an arc toward the pylon.
  - Nothing stays on the ground after the strike (no scorch mark), so the impact leaves no trace from t150 on.

## Q5. Competition: PASS for t000 to t110, with a caution just after the window
- **No bolt-like shapes in the sky from t000 to t110:**
  - t040 has a soft brightening of the clouds at the upper right. It is diffuse and does not read as a strike.
  - Rain streaks are thin, even and vertical, so they do not read as bolts.
  - The steady cyan pylon crystal, the dark-red tether line and the small yellow glows on the path behind the trainer (about x 580 to 720, y 440 to 460) stay the same the whole time. They do not compete with the ring. The yellow glows sit close behind the trainer's feet and add a little clutter.
- **Struck area matches the warned zone:** Yes. At t120 to t130 the bolt ends at the trainer's feet, inside the ring where the cracks meet.
- **Caution after the window:**
  - At t160 to t170 a large sky bolt appears at the upper right and comes down toward the tree canyon and the pylon (about x 880, y 270). Another faint bolt appears at the far left edge (about x 0 to 20, y 180 to 220).
  - Coming 0.4 to 0.5 s after the real strike, with no ground warning, the upper-right bolt can look like a second strike without warning near the pylon. That weakens the rule that lightning only hits where it was warned.

## Q6. Photosensitivity: PASS, with a caveat
- **No full-screen flash or white-out:** No frame has one, and brightness across the whole frame stays about the same.
- **Brightest moment:** The ring's inside goes from dark magenta at t090 to almost white at t110, then back to dark at t120 once the bolt appears. That area covers about 20 to 25% of the frame, so it is a bright pulse followed by a dark one.
  - One pulse per strike is acceptable.
  - If strikes come in quick succession, or several players have overlapping zones, this could approach a flash sequence. The pulse brightness is worth capping.
- **Sampling limit:** The frames are 0.05 to 0.1 s apart, so any faster flicker between frames cannot be ruled out.

## Overall: PARTIAL
Where the strike lands, how big the zone is, and the impact are all clear, and nothing competes during the warning. The warning still does not show when the player must leave. The only urgent cue comes too late to act on, and a sky bolt without warning just after the strike muddies the promise that lightning only hits the warned zone.

**The one change that would help most:** Add an explicit countdown that finishes when escape is still possible. For example, a bright second ring that shrinks steadily from the rim to the centre over the full 1.2 s, plus a clear "leave now" colour or brightness change at about t060 to t070 instead of t100 to t110. A second fix: stop decorative sky bolts from ending near the ground in the 0.5 s after a warned strike.
