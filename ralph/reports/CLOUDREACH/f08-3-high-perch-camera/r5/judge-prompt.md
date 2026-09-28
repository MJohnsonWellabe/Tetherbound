# Verbatim prompt given to the code-blind judge (general-purpose subagent, no conversation context)

You are a code-blind visual readability judge for a third-person creature action RPG. You judge ONLY rendered game frames. Do NOT open, read or search any source code, JSON, config, test, tool, manifest, markdown or report file in the repository, and do not look at git history. Open only the image files listed below, each with the Read tool.

Context you may use: the player-character (a trainer, about 1.8 m tall) glides by hanging from a large bird carrier. "The High Perches" is a tall rock pillar in a sky region, topped by a flat grassy crown with several tall stone needles/columns; players reach it only by gliding. Every frame is from the game's ordinary third-person camera following the trainer. HUD is hidden. Other creatures in frame are wild creatures that live there.

Directory: /home/user/Tetherbound/ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5/
Frames (each has a -day.jpg and a -night.jpg):
high-perches-arrival-far-*       — gliding in, about 50 m out
high-perches-arrival-lip-*       — gliding in, about 20 m out
high-perches-arrival-landed-*    — 1 s after landing on the crown
high-perches-crown-rim-out-*     — standing at the crown's edge looking out over the drop
high-perches-crown-court-*       — standing on the crown looking back at the needles
high-perches-departure-lookback-* — gliding away, camera turned back toward the perch
(Say if any file is missing.)

Judge ONLY readability and camera function, NOT art quality, polish or beauty (those are out of scope; do not fail anything for looking unpolished). For each frame answer YES / PARTLY / NO with one sentence of evidence, for each question, then give an overall verdict per question:
Q1 Readable height: can a player tell the perch is high above the surrounding land/cloud floor (the drop is legible)?
Q2 No rim crowding: is the trainer (and carrier when flying) clearly visible, not cut off by the frame edge, and not hidden or crowded by geometry or a creature pressed against the lens?
Q3 Arrival and departure legible: in the flight frames, can a player tell they are arriving at / leaving the perch, and where they will land / what they left?
Q4 Day and night: do the same reads hold at night?
Finish with a line "CAMERA READ: PASS" or "CAMERA READ: FAIL" (PASS only if Q1–Q4 are each YES or PARTLY overall with no NO frame that would block play), then the worst 3 readability defects, each naming the frame. Keep it under 600 words.
