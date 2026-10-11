
## Four-at-once attackers vanishing at contact (code-blind FAIL on 63e45388): harness-only
`creature_body._on_visibility_changed` re-enables physics when a body is shown. The four-at-once loop
(`for body in bodies: body.visible = true`, in the smoke and `tools/capture_f35_four_contact.gd`) re-showed
the three attackers `_attacker_origin` had hidden, so they fell through the collider-less stage floor.
Solmane, placed last, never toggled. Fix: keep them stationary after showing, and fail the run if any attacker
leaves its pose or is hidden at a captured beat. Re-run: 84 frames, 4 arrivals, 0 failures, all four posed at
every beat (`four-at-once-selfcheck.png`, llvmpipe, author's own look). Also Solmane's contact is cool
white-blue, and Veridian's spires/ring are pale lime against the grass.
