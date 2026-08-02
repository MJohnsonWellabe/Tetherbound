# D46. Combat asks the player rig to reframe; it never moves the camera

Kind: implementation

`Player.setCameraFraming(framing | null)` records a request. The player's own
camera rig eases its distance, height, shoulder offset and pitch toward it every
step and keeps being the only thing that writes camera position. Passing null
returns to the exploring framing.

Combat wants a wider, higher shot that holds two creatures and the player.
The obvious implementation is for the combat stage to move the camera while a
fight runs. That produces two writers for one transform, and the loser is
whichever ran first that frame. Camera bugs of that shape are miserable to
find because the symptom is a jitter that depends on system update order.

Keeping one writer also keeps the feel layer composable. `Fx` displaces the
camera for screen shake in the render phase and subtracts its own previous
offset first (D40), which only works if the rig has already put the camera
where it belongs. A second writer between those two steps would make the shake
either double-apply or vanish.

Two details:

- **The blend is on the rig parameters, not on the camera.** Interpolating the
  camera's world position toward a target fights the collision pullback that
  stops the boom clipping into hillsides. Interpolating distance and height and
  letting the existing rig math run means the pullback keeps working mid-blend.
- **Look input cancels the pitch blend.** If the player touches the stick
  during the transition, the framing stops steering pitch. Wrestling someone
  for their own camera is worse than an imperfect angle.

Tunables live in `src/data/combatStage.json` alongside the rest of the combat
presentation numbers.
