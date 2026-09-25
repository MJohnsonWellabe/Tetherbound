# F05 heal payoff: presentation hold (X03)

`tools/capture_presentation_hold.gd` through the production Meadows world,
player camera rig and HUD; 1280x720, opengl3 under xvfb; day clock held at
13:00. Adapted from the finale lane's `capture_heal.gd`.

- `*-no-hold.jpg`: the approach and works vantages right after
  `legendary_freed`, no hold. Visible: the cyan objective beam, the objective
  hint card ("Five is the whole team...") over the centre of the view, and the
  director's "Call out Terrapup" teaching line.
- `*-payoff-hold.jpg`: the same vantage with a presentation hold. Beam, hint
  card and teaching line stand down; the tracker and minimap stay.
- `_pair_*.jpg`: no-hold (top) vs hold (bottom).

Staging (tool header): chain up to the Warden set directly, then
`legendary_freed` set directly (the lever is not pulled), which leaves
"Settle who walks with you" open as in the judge's frames; the player is
placed at each vantage. The hold is a plain node the tool adds to
`presentation_hold.gd`'s group, standing in for the heal payoff's own node.
