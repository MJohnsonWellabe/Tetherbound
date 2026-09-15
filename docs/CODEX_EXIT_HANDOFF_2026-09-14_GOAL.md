# Codex Exit Handoff — Persistent Production-Closeout Goal — 2026-09-14

## Mandatory operating mode for the next session

Start by creating or resuming this as an explicit persistent goal. Do not treat a
status question as permission to stop, do not end after reporting a failed visual
round, and do not stop at a ledger milestone. Continue autonomously until the
objective is complete or a genuine blocker requires owner input.

> Complete Tetherbound production closeout from the consolidated integration
> branch: first finish and verify Meadows through gates A0–A11 with tests,
> production captures, independent visual evidence, documentation, and pushed
> checkpoints; then finish, test, visually validate, document, and push the
> remaining work for all four biomes. Preserve recovered branch work and do not
> stop at the 41/43 Meadows playtest milestone.

The canonical Meadows player-voice gates are A1–A11; the owner's “A0–A11” phrase
also includes the prerequisite technical/ledger/package closeout before the
continuous campaign. Treat both as required.

## Repository and integration baseline

- Workspace: `D:\tetherbound\source`
- Correct GitHub repository: `https://github.com/mjohnsonwellabe/Tetherbound`
- Integration branch: `codex/all-branches-integration-0913`
- Current committed HEAD: the commit containing this document, titled
  `handoff persistent Meadows and biome closeout goal`
- Push state: local commit is safe but the attempted push hung on this desktop's
  GitHub credential UI and was cancelled. Push this branch after authentication;
  do not assume the handoff commit is remote until `git status -sb`/remote refs
  confirm it.
- Previous promoted checkpoint: `0afca2ed finish Terrapup authored rest proof`
- Godot: `C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`
- Blender: `C:\Users\mattj\.cache\tetherbound-art\blender-4.2.9-windows-x64\blender.exe`

The worktree has extensive unrelated `.import` churn and untracked `.uid` files.
Never blanket-add, clean, reset, or checkout them. Exact-stage only. Preserve all
recovered/user work.

## Strict acceptance state

| Requirement | Proven | Open |
|---|---:|---|
| 2026-09-12 playtest ledger | **42/43** | Burrow Warrens visual quality |
| Named Meadows locations | **20/23** | The Rise; The Old Quarry; Old Mill Crossing |
| Current continuous player-voice gates | **0/11** | A1–A11 require a fresh full campaign |

Do not promote from focused tests or a clean manifest alone. A named location needs
current production pixels and an independent blind PASS. A1–A11 need the complete
non-Quick campaign after the four location rows, ledgers, regressions, and package
are current.

## Completed promotion in this desktop session

Terrapup rest is accepted and committed in `0afca2ed`:

- dedicated authored `rest` animation using the existing local rig;
- focused contracts: 16 tests / 201 assertions / 0 failures;
- production R41: 4/4, complete, no failures;
- independent blind PASS;
- playtest ledger advanced from 41/43 to 42/43.

No Meshy key was needed. No Meshy key is currently required for Warrens; use local
procedural geometry/Blender unless a genuinely new owner-authored asset becomes
necessary under the art-sourcing rules.

## Burrow Warrens current work

### Committed R25 checkpoint

Commit `9c542c3e` contains:

- replacement of the rejected complete threshold shell with an open excavated
  apron (floor plus low side cuts, no roof);
- hidden legacy `Throat`, `BankCap`, and `DoorwayCollar` visuals with collision
  retained;
- a wider/deeper organic mouth opening;
- actor exclusion moved immediately before threshold frame serialization;
- restored safe guardian evidence framing;
- R25 production evidence at
  `ralph/reports/MEADOWS-0912/final-warrens-25-desktop-01`.

R25 manifest: 9/9, `complete:true`, no failures, one apron, four hidden collision
visuals, zero rejected carriers visible. Focused suite at that point: 8 tests / 118
assertions / 0 failures.

Independent R25 verdict remained FAIL for both the final playtest row and named
location. Improvements: no actor/camera obstruction; recognizable entrance;
guardian fully visible. Remaining blockers: pyramidal/generic mound silhouette,
flat crown/material patch, dark slab shapes, nested portal/box seams, weak night
modeling, and guardian still hiding much of the den.

### Committed R26/R27 checkpoint — continue from it

Modified files:

- `scripts/world/burrow_warrens.gd`
- `shaders/earth_bank.gdshader`
- `tests/test_burrow_warrens_visual_identity.gd`
- `tools/capture_burrow_warrens_visual_identity.gd`

R26 changed `earth_bank.gdshader` from `cull_disabled` to verified `cull_back`.
The bank grid emits upward winding (`a,c,b` / `a,d,c`), so this safely removes the
grass-covered top surface when viewed from beneath the mouth. R26 production
completed 9/9 at
`ralph/reports/MEADOWS-0912/final-warrens-26-desktop-01`.

R26 pixel result: the exterior mound became grassy and materially more coherent,
and the bright green underside ceiling slabs disappeared. It also exposed grey
rectangular vertical sides from legacy floor-plinth boxes around the threshold, so
R26 is diagnostic and must not be promoted or blindly reviewed unchanged.

R27 hides the rendered floor-plinth box meshes for the three organic chambers and
two organic passages while leaving their separate `StaticBody3D`/`BoxShape3D`
colliders intact. It adds a fail-closed receipt requiring five
`OrganicFloorHidden_*` visuals. Focused suite currently passes **8 tests / 119
assertions / 0 failures**.

R27 production completed successfully at:

`ralph/reports/MEADOWS-0912/final-warrens-27-desktop-01`

Its manifest records `complete:true`, 9/9 frames, no failures,
`hidden_organic_floor_visual_count == 5`, and zero visible rejected carriers.
Self-review found that the obvious right-side floor-plinth face was reduced, but
the set is not yet credible enough to request another blind verdict: large
foreground vegetation partly obscures the entrance in the oblique view, grey
rectangular forms remain near the mouth, and a pale rectangular cap seam remains
above the inner arch in the inside-threshold view. Treat R27 as the current
diagnostic baseline, fix those production-subject defects directly, rerun the
focused suite and production capture, and request blind review only once the new
pixels no longer show those defects.

### R32 production diagnostic — 2026-09-14

R28–R32 extended the organic replacement across all five chambers and all four
passages, removed the oblique foreground blade, excluded the ambient Band-2
Burrowback from threshold composition frames, and scoped a higher crown to the
mouth-to-hall transition. Focused R32 coverage passes **8 tests / 125 assertions /
0 failures**. Native production evidence at
`ralph/reports/MEADOWS-0912/final-warrens-32-desktop-01` is complete 9/9 with no
manifest failures and no visible rejected carrier receipts.

Independent blind review still returns **FAIL** for both the final playtest row and
the named-location row. The R27 blade, grey carrier rectangles, creature obstruction,
and near-threshold pale cap are gone, but the façade now fails as a composition:
the grassy bank planes and brown mouth shell read as separate shapes, the stepped
apron exposes horizontal bands and abrupt joins, and the guardian frame does not
establish enough den identity. Strict ledgers therefore remain **42/43 playtest**
and **19/23 named locations**. The next production correction is continuous visible
apron geometry, bank-to-mouth integration, and a den frame/subject fix; do not
recapture R32 unchanged.

### R35 production diagnostic — 2026-09-14

R33–R35 replaced the ten visible approach-ramp steps with one continuous visual
apron while retaining their proven collision, joined both threshold sides back to
the analytic bank surface, retired the oversized satellite-hole spoil fans,
varied the mouth cut edge, and reframed the guardian inside the den. Focused
coverage passes **8 tests / 127 assertions / 0 failures**. Native production
evidence at `ralph/reports/MEADOWS-0912/final-warrens-35-desktop-01` is complete
9/9 with no manifest failures; its receipt records one continuous apron, ten
hidden ramp carriers, two bank blends, five organic chambers, four organic
passages, and zero visible rejected carriers.

Independent blind review remains **FAIL** for both Warrens rows. The continuous
apron and den framing are real gains, but the exterior still reads as intersecting
green wedges around a separate brown trapezoidal mouth, and the threshold-to-den
route does not carry a strong repeated location motif. The strict ledgers remain
**42/43 playtest** and **19/23 named locations**. Continue with a single authored
landmark pass: unify the mouth with the bank material, increase the organic shell
resolution, add a legible production-distance Warrens marker, and repeat its
rootstone/root motif in the den. Do not promote or recapture R35 unchanged.

### R38 production verdict — 2026-09-14

R36–R38 added a legible physical `THE BURROW WARRENS` trail sign, repeated its
amber rootstone motif in the guardian den, increased the organic shell resolution,
and carried the existing wet-earth finish into the exposed mouth. Focused coverage
passes **8 tests / 127 assertions / 0 failures**. Native production evidence at
`ralph/reports/MEADOWS-0912/final-warrens-38-desktop-01` is complete **9/9**
with no manifest failures.

Independent blind review gives the named-location presentation a high-confidence
**PASS**: the readable sign, distinctive mound, centered approach, and unmistakable
entrance establish identity and wayfinding. The canonical named-location ledger
therefore advances to **20/23**. The visual playtest row remains **FAIL**, so the
playtest ledger remains **42/43**: overlapping faceted mouth planes, a dark repeated
rib corridor, stretched den surfaces, sparse staging, and a foreground obstruction
still prevent production quality. Continue by correcting those production subjects;
do not recapture R38 unchanged.

Focused test command:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_burrow_warrens_visual_identity.gd
```

Production capture command:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/capture_burrow_warrens_visual_identity.gd -- --output=res://ralph/reports/MEADOWS-0912/final-warrens-27-desktop-01
```

Each full Meadows boot takes roughly eight minutes because it builds hundreds of
thousands of vegetation placements. Quiet output during that interval is normal.
Keep the turn active and communicate brief progress without ending it.

## Other three red locations

- **The Rise:** source has extensive focused coverage, but no accepted current-
  revision production traversal/visual verdict. Existing retries include R17–R19.
  Verify the newest manifest and verdict; do not infer PASS from focused route
  tests.
- **The Old Quarry:** R35 produced a clean 8/8 manifest and focused 10/442/0, but
  independent review failed repetitive rectilinear slab geology, ambiguous wagon/
  conduit relationships, and lost night detail. Do not recapture unchanged R35.
- **Old Mill Crossing:** R16 produced a clean 8/8 manifest and focused 7/223/0,
  but independent review failed the obstructed arrival, stair/blockout-looking
  segmented water, and unclear source/headpond/contact causality. Do not recapture
  unchanged R16.

Close these with direct subject fixes, production evidence, and independent blind
PASSes. Update the 20/23 ledger only after each pass.

## Required sequence after the four locations pass

1. Rebuild the strict 43-row playtest audit from current evidence; do not reuse a
   stale audit as proof.
2. Update the 23-location ledger from the four independent verdicts.
3. Run proportionate full regressions and build/package verification.
4. Run the complete non-Quick Gate F/KICKOFF campaign using
   `docs/prompts/70-MEADOWS-full-chapter-integration-playthrough.md` and
   `docs/acceptance/KICKOFF_RUN.md`.
5. Judge and repair A1–A11 from that same continuous campaign.
6. Commit, push, and document Meadows closeout.
7. Continue the same persistent goal through the remaining work for all four
   biomes, with tests, production visual evidence, documentation, and pushed
   checkpoints. Do not declare success at Meadows alone.

## Stop conditions

Do not stop because a capture or blind review fails, because a status question was
asked, because a turn is long, or because one ledger advances. Continue to the next
safe implementation/verification step. Stop only when the complete goal is done or
when owner authority/input is genuinely required and safe alternatives are
exhausted.
