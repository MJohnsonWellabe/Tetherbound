# Blind judge prompt — N07-VFX-POLISH-0905

Given verbatim to a code-blind sub-agent (Agent tool, model `opus`) with only: the two
contact sheets named below, the individual frames under them, `docs/reference/`, and
`.claude/skills/visual-judge/SKILL.md`. It was told nothing about what changed between the
two sheets, which sheet is newer, or what this lane hoped it would say.

---

You are judging in-game frames from Tetherbound, a Godot creature-training game. Read
`.claude/skills/visual-judge/SKILL.md` first and apply its rubric; `docs/reference/` holds
the art board and the Palworld bar. Score nothing; name specific, addressable defects and
say which frame each is in.

There are two sheets, `A` and `B`, of the same five moments shot the same way. You are not
told which is earlier. For every question below answer for A and for B separately, then say
which sheet you prefer for that question and why.

Two moments matter:

**The wind-up.** Frames `05-telegraph`, `06-telegraph-behind` and `07-telegraph-control`
are a fight between the player's creature (the larger, plated one, nearest the camera in 06)
and a wild creature. In 05 and 06 the wild creature is winding up an attack; 07 is the same
fight a moment later with nothing happening. Something is drawn on the ground during the
wind-up.

1. Can you find the wind-up mark in 05 and in 06? Describe its colour in plain words and, if
   you can, as a hue (red / orange / amber / gold / green / blue / violet).
2. Which creature does the mark read as belonging to: the wild creature winding up, or the
   player's creature? Say why (position, occlusion, colour).
3. The rubric's second criterion asks whether the Team Tether oxblood is reserved for danger
   and Team Tether. Does this mark use that reserved family? Does it clash with, or read as
   the same signal as, anything else warm in the frame (the creatures' coats, the grass)?
4. Does it read as a warning that a blow is coming, as a reward, as a buff, or as nothing?

**The seal.** Frames `04a-catch-seal` and `04-catch-success` are the instant a wild creature
is caught: the orb has landed and sealed, and the camera is a close-up on the orb.

5. What is drawn around the orb at 04a and at 04? Describe shape, colour and how much of the
   frame each element covers.
6. Does the seal read clearly at this camera distance as a reward moment on the orb, or does
   it wash the frame? Are there hard edges, spikes, seams, flat discs or anything that reads
   as a rendering bug rather than a choice?
7. Is the orb itself still legible as the subject?

Then the rubric's usual pass over everything else you see (artefacts, scale against the
1.80 m trainer where visible, HUD if present), and the two bar questions from the skill.

Finish with: for the wind-up, which sheet's mark is the better read and the one thing you
would still change; for the seal, the same.
