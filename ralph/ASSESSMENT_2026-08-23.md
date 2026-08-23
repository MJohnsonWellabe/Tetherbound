# Full-game assessment — 2026-08-23, post-weekend-sprint landing

Run overnight (owner asleep) on `main` at b923e202 (the full D landing),
per the owner's direction: verify the 2026-08-21 playtest list against the
real build, measure every gate against its documented end state, rank the
weakest parts, and feed a re-plan. Evidence: live test execution in this
container (Godot 4.7 headless for logic, xvfb+opengl3 for renders),
git-history verification, and a blind visual critique per
`.claude/skills/visual-judge`. ROG-hardware items are code-verified only —
no Ally in this environment.

## Headline

**The systems game is nearly real; the picture is not.**

- The OP21 playtest list (26 items) is substantially resolved: 18 verified
  FIXED (most by live smoke-test passes), 3 need only visual confirmation,
  and 3 are genuinely still open (chop swing, site frames, village layout).
- The unit suite is green but for 4 real content gaps (1355 tests, 4 fail).
- Gate B runs continuously from title through opening, catch, team, tools,
  gathering, and two villagers — and then stalls at one known defect
  (harness pathing at Mira's door). Tournament logic itself is 42/42.
- The D corridor D1–D3 plausibly pass their evidence criteria today; D4 is
  one data file short; D5 gameplay passes, visuals do not.
- The blind visual critique answered **NO to both bar questions**
  (keyart-world? Palworld-kind?). The world is too empty, the palette does
  not hold between regions, and the creatures/stronghold do not carry the
  frame. This matches the owner's own prediction and is now the critical
  path.

## OP21 verification (all 26 items)

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 01 | ROG lag | LIKELY FIXED | O(n²) arbiter registration fixed (ffcf2483); missing scatter bake committed (e66bf39e): 58–60s boot → ~1.3s. On-device number unverifiable here. |
| 02 | Satchel leaks to hotbar | FIXED | smoke_satchel_owns_hotbar PASS |
| 03 | Build menu vs creature cycle | FIXED | smoke_build_owns_creature_cycle PASS |
| 04 | Settings/teleport controller scroll | FIXED | smoke_settings PASS (138 bindings, 22 destinations) |
| 05 | Trainer battle camera loss | FIXED | smoke_trainer_battle_camera PASS (real Mira path) |
| 06 | Binding collisions | FIXED | smoke_dpad_hotbar_vs_cycle PASS + static enforcement test |
| 07 | Build rotate | FIXED | 98c377b0; smoke_free_build exercises the anchor path |
| 08 | Doors/kit scale | FIXED | build_door.gd shares authored modules, 1.6m/2.3m |
| 09 | Roof size | FIXED | 7aab9912; ridge requirement dropped by owner directive |
| 10 | Free build ≠ free craft | FIXED | 15c2ba4d + test_recipes contract test |
| 11 | Prompt dock legibility | FIXED | smoke_prompt_hotbar_dock PASS |
| 12 | Party cycling presentation | LIKELY FIXED | code landed (d066c39b, 02d7e109); needs visual confirm |
| 13 | "Pal" terminology | FIXED | ba234c4b; repo grep clean |
| 14 | Team count 2/5 | FIXED | smoke_party_count_after_catches PASS incl. save/reload |
| 15 | Map unusable | FIXED | tab_map follow/zoom + smoke_gate_a_map_cycle |
| 16 | Opening direction | FIXED (code) | 11-beat objective ladder, all flags set by real code; "followable ≠ teaches" caveat stands |
| 17 | Village layout | OPEN | no reshape landed; visual-judge scope |
| 18 | Signs in road | FIXED | 16ec79ff, 18 signposts offset |
| 19 | Pond-submerged veg | FIXED (data) | waterline re-anchor + scatter floor gate |
| 20 | Submersion damage | FIXED | water.gd + 8 tests |
| 21 | Washed-out grey | FIXED | weather retune + consecutive-cap + tests |
| 22 | Site rewrite | PARTIAL | copy shipped; 3 of 4 SITE-SHOTS frames still missing; stale CSS comment re village-square.jpg |
| 23 | Load Game dead end (P0) | FIXED | smoke_title_load_game PASS (physical pad, full restore) |
| 24 | Chop swing | **STILL BROKEN on main** | real fix stranded on `claude/gate-a-core-verbs-8aaw7g` (19d7d4a5) — land it |
| 25 | Arena phasing | FIXED | cf41c030 + smoke_arena_contain |
| 26 | Pond→village dead travel | LIKELY FIXED | 1600m gap → 84m; 56 wild clusters; no CI regression lock |

Also verified: **no hold-to-modify chords anywhere**; the authored
controller map matches `project.godot`. The old P0 "first catch fails
deterministically" **did not reproduce in three independent runs**
(reticle 0.213–0.405 vs 0.6 threshold) — the CATCH-BLOCKER fix holds.

## Test-suite baseline

1355 tests / 829,742 assertions / **4 failures**, all real content gaps:

1. `test_map_fog` ×2 — a fresh save reveals **nothing**; the owner's
   2026-08-22 ruling (village + roads start revealed, landmarks as icons)
   is not implemented.
2. `test_camp_supply_reaches_every_band` — band4 (Upper Meadows Ironwood)
   `harvest.json` has 5 nodes, all ironwood; no wood/stone/fiber, so a
   camp or creature bed cannot be paid from the band's own ground.
3. `test_wild_alphas` — 2 alpha encounters in the chapter vs prompt 60's
   "handful".

## Gate-by-gate against documented end states

- **Gate A** — effectively recovered. The reopened playtest table is
  contradicted by current evidence for nearly every row; the bookkeeping
  in `ACTIVE_TASKS.md` is stale and should be reconciled. Residual A-class
  work: chop clip (landing), map fog ruling, opening-pedagogy check.
- **Gate B** — one defect from a full continuous evidence pass. The run
  reaches: opening → tutorial catch → team-of-3 qualification → Tam's
  tools → hotbar assignment → 3 gathers → Oskar — then fails at Mira's
  door because the *test harness* walks straight lines through buildings
  (`tests/helpers/gate_a_npc_gather_segment.gd:376-408`). Everything after
  (home build, bed, sleep, tournament, South Bridge) is blocked from being
  *evidenced*, though tournament logic passes 42/42 in isolation.
- **Gate C** — backbone data live on main and exercised by the suite
  (curves, rewards, objectives all load and pass); alpha-count gap above
  is the one named shortfall found.
- **D1 Lower Meadows** — passes its evidence criteria on this container's
  run (dead-travel filled: longest gap 84m).
- **D2 Quarry/Warrens** — passes (guardian, vault gating, first-clear
  reward, 7 residents — all smoke-verified).
- **D3 River/Relay** — passes (Vance beaten live, captive rescued and
  relocated, mill gear granted, crossing restored; riding smoke passes).
- **D4 Upper Meadows** — blocked by exactly one data file:
  `data/config/bands/band4_upper_meadows_ironwood/harvest.json` needs
  wood/stone/fiber nodes. Sigil system fully implemented and tested.
- **D5 Stronghold Approach** — gameplay passes (5-room route, gauntlet,
  elite shutter, recovery, TetherMachine); visual bar still fails.
- **Gate E** — not started (children: stronghold materials 21, sky planes
  22, boss CI flake 34, release ceremony 46, five-creature bond 67,
  objective chain 68, Warden/legendary/world-healing).
- **Gate F** — not started; requires everything above plus tuning.

Wild-creature engine work holds: 0% underground across all five bands,
streaming activation verified live.

## Blind visual critique — the weakest part of the game

Both bar questions: **NO** (keyart-belonging: no; Palworld-kind: no).
Round 1 covered opening, band2, band3, stronghold frames; band4/village
round pending capture completion.

The three separating gaps, ranked:
1. **Emptiness** — 60–90% of most frames is one flat green terrain
   material with confetti scatter. Ground cover density and flower drifts
   are the single biggest lever.
2. **Palette incoherence** — warm noon, blue-grey wash, and crimson
   frames do not read as one game. Second-path reproduction with pinned
   clock/weather proved the **crimson band2 "day" frames are a capture
   artefact**, root-caused: `survey_band2.gd` pins but never freezes the
   `WorldLook`/`WorldWeather` clocks (vs `capture_band3_region.gd:266-277`
   which does), and parks the player at y=-500 — underwater — so the
   drowning overlay ramps to solid red over the whole run. Fix: port
   band3's pin-then-freeze + above-ground park into `survey_band2.gd`.
   The blue-grey cast appears even in pinned-noon frames and deserves one
   root-cause pass.
3. **Creatures and antagonist presence don't carry the frame** — wilds
   render as sub-half-metre pastel blobs or grass-coloured rabbits; the
   stronghold is an untextured toy-scale blockout (~30m) — Gate E's
   prompt-21 work, now visually confirmed as load-bearing. The black Team
   Tether figures are a **confirmed game bug**:
   `character_model.gd:386-388` multiplies the rank palette into both
   albedo AND emission, and `npc_ranks.json`'s `grunt` `#4a5049`
   (~0.30 luminance) crushes the rig to black — the same defect class
   fixed twice before (tether_oxblood emission floor; villager tint
   raised to 0.88 luminance) but never applied to the rank palettes.
   Fix: brighten grunt/officer palettes toward ~0.7–0.9 luminance or add
   the emission floor in `character_model.gd`.

Fixable by scene change: ground cover, day-grade unification, relay-yard
greybox dressing, picket/quarry/mill prop clustering, horizon landmark on
band3's dead stretch, Tether banners/lights on the stronghold.
Needs art not in the build: creature presentation at fightable scale,
stronghold model/kit-bash, bark/foliage materials for hero trees.
(Positives: relay pylons + tether cables, mill house, settlement cluster
— the keyart vocabulary exists; the sentences don't.)

## Ranked weakest parts (sprint scheme)

**SHIP BLOCKERS (for a full A–F playthrough)**
1. Gate B harness pathing at village doors — blocks the entire Gate B
   evidence tail. Authored waypoints or a real nav query.
2. band4 harvest.json wood/stone/fiber — one data file, D4's only gap.
3. Gate E does not exist — the chapter has no finale. Largest single
   block of missing work in the A–F path.

**QUALITY BLOCKERS**
4. World visual bar: emptiness + palette + creature/stronghold presence
   (blind critique above). The biggest gap vs the owner's stated bar.
5. Map fog fresh-save ruling not implemented (test red, black map).
6. OP21-24 chop clip stranded off-main (land `19d7d4a5` from
   `gate-a-core-verbs-8aaw7g`, plus that branch's CI wiring).
7. Alphas: 2 vs "handful" (prompt 60).
8. Black Team Tether figures — confirmed game bug (rank palette ×
   emission multiply, `character_model.gd:386-388` + `npc_ranks.json`
   grunt/officer values). Small fix, big presence gain.

**POLISH / bookkeeping**
9. survey_band2.gd clock/weather pinning (capture tool).
10. SITE-SHOTS: 3 frames + stale CSS comment.
11. ACTIVE_TASKS.md Gate A/B tables are stale vs this evidence.
12. band_split_baseline fixture policy decision.
13. D3 dark-band artefact (positional, rendering) — still unexplained.
14. run_tests.gd could use a single-file filter flag.

## Branch cleanup state

16 branches verified deletable (list + commands in
`ralph/reports/SUPERSESSION-2026-08-23.md`); deletion still requires
owner/ChatGPT credentials (403 from sessions). 4 branches carry unique
content; `gate-a-core-verbs-8aaw7g` is the one with player-facing work to
land (chop clip + CI wiring).
