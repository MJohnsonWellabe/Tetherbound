# Gate D — what is still open after D3, D4 and D5 landed

**Written 2026-08-23 by the Gate D coordinator**, at the point where
`ralph/integration-D` carries D3, D4, D5 and the engine work they were blocked
behind. D1 and D2 are still in their own sessions and are **not** covered here.

This file exists because the findings below were sitting in commit messages and
in one archived session's ledger, and a commit message is not somewhere anyone
looks when asking "what is left". This repo has a documented history of
accumulating stale prose after the code moved; this is the opposite failure —
real, current findings with nowhere discoverable to live.

Every item says what was established, what was ruled out, and who owns it.
Nothing here is a guess dressed as a finding.

---

## 1. D3's checkpoint rendering artefact — OPEN, handed to terrain/rendering

**The loudest undocumented item, and the reason this file exists.** It appeared
only in commit `202e038c`'s message.

A dark band in the Band 3 checkpoint frame. **Measured, not impressioned:**
constant RGB within three levels across 700px, a dead-straight horizon-parallel
top edge, props inside it at full brightness, and terrain ending in mid-air at
the seam.

Two explanations were tested and **both are wrong** — recorded so nobody spends
the time again:

- **Not the camera underground.** That theory had a real basis (the analytic
  heightfield and the collision terrain disagree by up to 22m near the river)
  and produced a genuine fix that is kept — capture eyes and targets are
  raycast onto the physics surface now. But at this viewpoint the ray returns
  the analytic height unchanged, the eye is identical before and after, and so
  is the artefact.
- **Not water.** Global water level is -17.0, the river's is -9.0, the eye is
  at -2.

**Established:** it is positional, not a height effect. The same 1.7m eye 19m
further back renders clean. The repro is the viewpoint's own coordinates.

**Owner:** terrain/rendering. Nothing in a band's config can cause or fix it.
D3 raised that frame's eye to 3.0m so the checkpoint stays judgeable while the
artefact stands — so a later reader will see a workaround, not a fix.

## 2. The capture tooling needs a pass of its own — FIVE artefacts, three lanes

Five separate defects were reported this run as problems with the *game* and
turned out to be problems with the *capture path*:

1. **Bushes reading crimson** — a probe loaded models raw and skipped the
   layer's own `retexture`. The config already fixed it. (Coordinator's own
   probe; caught before it was reported as a bug.)
2. **A campfire with no flame, glow or smoke** — embers survived the headless
   renderer, flame billboards and the omni light did not. D1 is still working
   this; the scene may be correct and the capture lying.
3. **The trainer as "a solid black cut-out"** — D4's blind critic called it the
   loudest thing in its survey and said the Palworld bar could not be evaluated
   from those frames. Disproved by `tools/_capture_char_black.gd`, which builds
   the trainer through the same `character_model.gd` path with a wooden crate
   beside it as the critic's own control: both render correctly.
4. **A day/weather clock racing the multi-viewpoint pass** — found and fixed by
   D3 inside its own tools.
5. **The camera rig's parked player tripping the water-hazard overlay** — same,
   D3, same commit family.

D3 recorded that the same conventions live in the other capture scripts
(`capture_prop_clusters.gd` and friends) and did not fix them there, correctly,
as outside its band's ownership.

**Consequence for anyone picking this up: a defect seen only in a survey frame
must be reproduced through a second path before acting on it.** Three lanes
independently lost time to this. The tooling itself is the defect.

## 3. Visual verdicts are stale where density changed underneath them

`density_scale` was raised for band4 and band5 (0.03 → 0.05) **after** those
lanes' blind rounds concluded. Their verdicts were reached against different
foliage than what now ships. Neither region has been re-judged since the
re-bake.

`ralph/GATE_D5_VISUAL_PASS_2026-08-22.md` and `ralph/DONE.md`'s Gate D4b
entries are the records to re-read before re-judging — both are detailed and
neither should be repeated from scratch.

## 4. D5's bar question A is still "no"

Its round-2 blind critic answered **A no (unchanged), B yes (was no)**. D5's
position is that every remaining defect needs a file, system or asset outside
D5 — the stronghold's own art (the critic's own #1, explicitly "needs art not
in the build"), storm slabs, ground scatter density, night ambient and
moonlight, tree shading, clouds.

That is plausible and it is also **the lane assessing its own ceiling**. It
should be confirmed by the full-corridor pass rather than accepted on the
lane's say-so.

## 5. D4's round-4 leftovers

Named by its critic, not band content, so not fixed in-lane: scatter density
(granted since, item 3), ambient light and exposure, a cloudless sky,
**distant-LOD instances rendering white**, and the storm wall's viewing angles.

The distant-LOD-white one deserves the item-2 treatment: reproduce through a
second path before acting, because it has the shape of a capture artefact.

## 6. `tests/fixtures/band_split_baseline/` — a frozen reference that lanes edit

D3 and D5 both edited it. Each edit is individually defensible (D3 rewrote
`trainers.json` to match its relay pickets' new positions; D5 added six lines),
but the fixture exists to be a **frozen** pre-split reference that
`test_band_content.gd` compares the merged arrays against entry-for-entry. Once
lanes update it to match their own work it can no longer detect accidental
drift — the "test that passes because the feature is absent" failure
`ralph/conventions.md` names outright.

**Needs one decision, centrally**: either lanes stop editing it and the test is
reshaped so legitimate content edits do not force a fixture change, or the
fixture is explicitly redefined as tracking-current rather than frozen and the
test's claims are narrowed to match. D3's rewrite also re-escaped `§` to
`§` throughout, which is formatting churn either way.

## 7. The bark retint, deliberately not changed

D4 correctly identified the bone-grey twisted-oak trunk as
`vegetation.json`'s **top-level** `Bark_TwistedTree` retint (`#918178`), which
no band file can reach — the `grove` layer declares leaf keys only.

It was **not** changed, on purpose. `_comment_retint_bark_ev2` records that
value as solved from a measured per-channel gain (rendered vs source) against a
target of ~RGB(95,82,72), chosen so bark survives the cool ambient that the
ground-legibility fix depends on. Changing it moves every twisted oak in the
chapter on the evidence of one blind critique of one ironwood stand. It belongs
to the full-corridor visual pass, where it can be judged against the chapter.

---

## What is NOT open, so nobody re-investigates it

- **Creatures falling through the world.** Terrain3D builds collision around the
  camera, so anything spawned far from the player had no floor and fell at
  26 m/s² forever — 137 of Band 3's 155, Bands 4 and 5 at 100%. Fixed by
  distance activation plus `_reground_if_fallen`. Verified at real density:
  band3 156, band4 271, band5 78, **all 0% underground**.
  `tools/_probe_wild_grounding.gd` reproduces it in one boot.
- **Band 2 showing one or two creatures ~7m under.** The Burrow Warrens'
  hand-placed residents are inside a cave, which is correctly below the
  analytic surface the probe compares against, and are deliberately exempt from
  activation because a dungeon should not sleep. The probe's own header says so.
- **`smoke_art.gd`'s eleven failures.** Both broken checks looked for scattered
  props as named scene children of `Vegetation`, and there have been none since
  the scatter moved to `Terrain3DInstancer`. Fixed, and `smoke_art.gd` is now
  in CI, which had never run it.
- **The scatter fingerprint reporting a fresh bake as stale.** JSON has no
  integer type, so a 64-bit fingerprint lost precision past 2^53 on the round
  trip through `manifest.json`. Masked to 53 bits.
- **The trainer rendering black.** See item 2.3.
