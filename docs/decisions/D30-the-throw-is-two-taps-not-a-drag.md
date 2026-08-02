# D30. The throw is two taps, not a drag-and-release arc

Kind: spec-conflict

`GAME_DESIGN.md` section 7 describes the throw as "drag-and-release arc, with a
trajectory preview line". It is implemented as tap-to-arm, tap-to-release,
against a catch ring that closes on a fixed period.

The mechanic that carries the throw is the ring timing: `ringBonus` is worth up
to 1.7x, more than any other term the player controls in the catch formula. The
trajectory preview carries nothing, because the target is auto-framed in the
arena and there is nothing to aim at.

A drag also competes directly with the camera drag on a phone. Combat mode
rebinds horizontal swipes to dodge, so a drag starting anywhere on the canvas is
already claimed, and the throw would have needed its own exclusive region on the
one screen that is already carrying six controls.

Two taps keep the whole timing skill, cost the preview line, and leave the dodge
gesture alone. Revisit at M5 if the throw reads as too easy.
