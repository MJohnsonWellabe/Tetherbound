# D31. Gamepad is a third input layer, not a replacement

Kind: implementation

`GamepadLayer` follows the pattern D26 established: it owns its own `move`
vector and `Input.beginFrame()` sums all three layers. A layer that assigns
`intent.move` directly erases whatever the others wrote, which is the exact bug
D26 exists to document, and a handheld genuinely has all three devices at once.

Look needed care. A mouse reports a DELTA and a stick reports a RATE, while
`Intent.look` is defined as a per-frame delta. The gamepad layer integrates,
deflection x rate x `FIXED_DT`, before writing. `beginFrame()` runs once per
fixed simulation step, which is what makes that exact rather than approximate,
and it means `Intent` keeps one meaning and nothing downstream knows a pad
exists.

Dead zones are radial rather than per-axis, because per-axis dead zones make
diagonals reachable at lower deflection than cardinals, which is why so many
pads feel like they snap to eight directions. Stick magnitude gets a response
curve so fine aim survives near centre.

Mapping: left stick move, right stick look, L3 sprint, A jump, X interact, RT
the one combat verb, shoulders dodge left and right in combat, d-pad plus Y for
the five party slots. Sprint is a stick click rather than a face button so the
thumb never leaves the stick.

Which prompts the HUD shows is decided by the device most recently USED, not
the devices attached. Capability detection cannot answer that question on a
device that has a pad, a touchscreen and a keyboard simultaneously.
