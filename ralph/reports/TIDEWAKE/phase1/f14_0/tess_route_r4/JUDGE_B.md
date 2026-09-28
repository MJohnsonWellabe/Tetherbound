# Judge B (code-blind, default model): Tess r4
FRAMING 29/36 (81%). TELLS 4/6 readable.

Failures:
- tell-start-000.32: the ally is between the camera and Mirejaw's head; its facing can only be guessed from the tail.
- tell-ended-072.33: the ally hides Riverdrake's head completely.
- t-108.02: the camera is too close; Riverdrake's tail runs off the right edge and the tell ring is under the action panel.
- tell-ended-134.85 and tell-ended-135.75: the ally hides Sirenseal's head and front.
- t-168.00: the camera is close behind the ally; Sirenseal is cut off at the bottom right, partly under the Orbs bar.
- t-204.00: Sirenseal is cut off at the right edge, its lower body behind the action panel.

Borderline passes (bodies overlap at the head, but facing reads from the body): t-000, t-012, hit-003.65, t-036, t-156.

Tells:
- NO at 000.32 and 001.25: Mirejaw's ring is mostly hidden under its own body.
- YES at 072.12, 072.92, 134.55 and 135.45 (the last two marginal).

Breaks:
- The action buttons vanish on "it's open" / "it missed you" frames.
- t-132: Riverdrake's HP is empty but it is still standing.
- Bodies pass through each other at contact.
- The trainers stand inside the ring.
