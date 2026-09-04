# Owner directives — 2026-09-04

Recorded verbatim from the owner, answering the ten questions in
`ralph/reports/G3-CLOSURE-PLAN-0904/REPORT.md` (plan: `docs/GATE2_GATE3_CLOSURE_PLAN.md`
§4). Per `CLAUDE.md` precedence this outranks every other document for what it covers
and reopens any item a ledger says is fixed.

> yes, yes, seen again roaming the land but uncatchable, sure, halda, we will run
> separate visuals I thought we already had visual tracks going last night what
> happened to those, let's use meshy for the additional art we can't get from free
> packs- try to find free packs and if the first three choices fail I'll design in
> meshy, fix number 8 also fix the picture during dialogue always being the main
> character, we don't need grass clumps we have the procedural grass and grandpas loft
> bed doesn't work, Ill play it later

## Triage (closure-plan lane, same day)

| # | Question | Answer | Consequence | Lane |
|---|---|---|---|---|
| 1 | V-5, heal the relay's own drain stations on `relay_disabled` | **yes** | implement: `meadow_healing` filtered to the relay's three stations, fired on `relay_disabled`; the contract's *fails if* (a before/after frame from the `06-relay-standing` stand shows no ground change inside the site radius) is the evidence | healing/world lane (`meadow_healing.gd`, `tether_relay.gd`); plan CL-E12 |
| 2 | W-1, the Warden's front raised to 18/18/19/19/20 | **yes** | confirmed as shipped; the contract's §9 item 2 closes | none |
| 3 | R-8, a refused Veridian | **seen again, roaming the land, uncatchable** | not stationary at one herd: it roams; no engage prompt, no catch, ever. Where it roams and how it is met is the lane's design call inside that rule (recommended: the healed meadows, seen from the road, never in the way) | finale/world lane; plan CL-E11 |
| 4 | R-3, the once-only doorstep alpha at 16–19 | **sure** | confirmed as intended pressure; stays optional and catchable | none |
| 5 | 2.10, who restores the team after the tournament | **Halda** | the champion beat: Halda hands over the revives (and the saddle recipe she already gives); the refusal line names the real block; the Trail Camp stays the field stop | G3-OPENING-FIX; plan CL-G3 |
| 6 | The Gate 2 acceptance bar | **"we will run separate visuals"** — and a question: *what happened to last night's visual tracks?* | the visual half runs as its own track with its own gate, which is the §5 correction. The answer to the question is below. | coordinator (roadmap edit) |
| 7 | Art the judge says is not in the build | **free packs first; if the first three choices fail, the owner designs in Meshy** | for each art ask (South Bridge gate and Team Tether presence; a Meadows landmark; a branching tree form; combat/reward VFX; distinct NPC bodies): a lane finds up to three free-pack candidates that match the installed families' style and scale, renders each in place, and puts them to a blind judge. If none passes, the owner designs the reference in Meshy. This is the owner exercising `CLAUDE.md`'s own carve-out (Meshy needs owner-supplied reference art; the owner is supplying it) and it relaxes "no new nature mesh" for the one branching tree form, on the same terms | a new ART-SOURCING lane; plan CL-A1 |
| 8 | The dialogue camera (villagers read too small) | **fix it** | a conversation camera that frames the speaker at a readable size | UI/camera lane (`camera_rig.gd`); plan CL-G10 |
| 8b | *New:* "the picture during dialogue always being the main character" | **fix it** | root cause is data, not the panel: `assets/ui/portraits/` holds two images, `trainer.png` and `grandpa.png`, and 125 of 138 authored `portrait` entries across `data/dialogue/` point at `trainer.png` — every villager, trainer, Team Tether rank and the Warden is drawn with the player's face. `dialogue_panel.gd` shows exactly what the line names. Fix: one portrait per installed humanoid rig (villager male, villager female, grunt/officer/captain by rank, the Warden, Grandpa, the trainer), rendered from the installed meshes, and every conversation's `portrait` re-pointed to its speaker; a test that no non-player speaker uses `trainer.png` | same lane; plan CL-G11 |
| 9a | The grass clump-card blade redesign | **no — the procedural grass is enough** | closes the question in `CURRENT_STATE.md` §3; no lane | none |
| 9b | Grandpa's loft bed | **"doesn't work"** | owner-reproduced. Reopens `CURRENT_STATE.md` §3's "loft bed verified in-engine": the in-engine probe passes and the owner cannot sleep in it, so the defect is between the probe's path and the real one (prompt, reach, interact arbitration, or the bed's own placement). Root-cause on a real body from the loft stair | G3-OPENING-FIX by adjacency; plan CL-G12 |
| 10 | The hardware pass | **later** | stays open; the four [OWNER-ONLY] items are not blockers for starting any stage of the plan | owner |

## What happened to last night's visual tracks

They all landed. Nothing was lost:

- BAND1-COMPOSITION (2.1), MID-LAYER (2.2), TREE-SILHOUETTE (2.3), CREATURE-LEGIBILITY
  (2.4), NIGHT-LEGIBILITY (2.7), WORLD-TREES, WORLD-LIFE, CAMP-SHELTER, OPENING-BED,
  HUD-INPUT and TOURNAMENT-FLOW all merged to `main` on 2026-09-03 through PRs #28 and
  #29; their branches were deleted after landing, which is why they no longer show on
  `origin`. Each carries its contact sheet and, where it ran one, its blind-judge
  verdict under `ralph/reports/<LANE>-0903/`.
- Each moved the thing it was scoped to move, measured: Bramblebun's grass separation
  1.33:1 → 1.57:1; unlit camps 0.85 → above 1.0 at night; canopy scale variation
  named as improved; the Band 1 route re-composed and re-baked.
- Then the Gate 2 evidence run (2.8) put a blind judge on sixteen frames from the
  played route, and the verdict was still no / no — for props, the unbuilt South
  Bridge, lighting, terrain form, the red family leaking onto roofs and trunks, and no
  creature ever in frame. **None of that was any of last night's lanes' scope.** That
  is the finding the closure plan §5 is about: the residual visual gap (roadmap 2.13)
  was never assigned to a track, and the gate was graded on it anyway. "Separate
  visuals" is the right call; the plan names what that track has to contain
  (CL-B2, CL-B3, CL-B6) and what it depends on (CL-H9, the capture lane never showing a
  creature).
