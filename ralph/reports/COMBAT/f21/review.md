# F21 independent code review (tb/f21, `git diff origin/main...HEAD`, ralph/ excluded)

The reviewer was a separate sub-agent working from static reading only.

## Round 1: FAIL

- **B1 (blocking):** foreground dithers stayed on when throw aim, the resolve close-up or the held round left the fight composer.
- **Non-blocking:**
  - N1: a near-plane straddle dithered every body in range.
  - N2: the foreground fade and the ally fade could stack on the same mesh.
  - N3: the comments overstated how cover ranks a view.
  - N4: the smoke's scoring string was stale.
  - N5: the smoke's hitstop bound missed the ultimate weight.
  - N6: per-frame sort and allocation cost.
  - N7: the `--no-fade` label was misleading.
  - N8: a stale comment.
  - N9: 1,037 editor `.uid`/`.import` files had been swept into the branch.

## Round 2 at 53b8e9fd: PASS

- **Fixed:** B1, N1, N2, N5, N7, N8 and N9.
- **Partly addressed, accepted and documented:**
  - N3: there is no penalty tie-break among passing lenses.
  - N4: the smoke does not prove the dither is applied; the code-blind matrix stills do.
  - N6: the `OCCLUSION_FADE.apply` subtree walk is not cached. Revisit it if the Medium-preset frame time is short.
- **Residual:** during hitstop (≤0.14 s) the framing tick does not run, so a fade clears one tick late.

## Evidence validity after the fixes

The camera changes after the r4 matrix capture are B1 (aim/resolve/hold clearing), N1 (near-plane straddle), N2 (a body becoming a combatant) and N6 (cull order, same set). None of them changes the matrix stills' path: the rig follows the ally, every subject sits in front of the lens and no body changes role. So r4's frames and verdict stand for 53b8e9fd under RD-36's reuse rule.
