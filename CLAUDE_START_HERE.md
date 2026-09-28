# CLAUDE_START_HERE — Phase 1: finish every feature row

Owner-authorized working brief (2026-09-28). It sits beside the live set in
CLAUDE.md. CLAUDE.md and AGENTS.md still govern hard rules and precedence.
STATE records status, and this file says who works what, in what order.
Update STATE, not this file, as work lands.

## 1. The phase in one paragraph

There are four Claude lanes, one per biome. Each lane closes **only** its biome's
open dashboard criteria, in the order listed below, for **function and completeness**.
The goal is an ordinary player path that works, reads and can be proven.
Beautification (Bars A/B) is **not** this phase; it is Phase 2, the Codex visual
catalog (`CODEX_START_HERE.md`). When all four biomes are clear, one lane reorders
the biomes (§6). Then the Codex phase starts.

## 2. Lane setup (all four lanes)

- **One session per biome,** with a top-tier model at high effort. Branch
  `tb/<biome>`, one per lane (`tb/meadows`, `tb/cloudreach`, `tb/stormwood`,
  `tb/tidewake`). Start from current `main`.
- **Read first:** CLAUDE.md, then STATE §0–§1, then the ACCEPTANCE §6.1 row for your
  criterion, then the owning design spec.
- **The board:** `ralph/reports/COORDINATOR/dashboard/criteria.json`. The IDs below
  are `F0x#n`, criteria numbered from zero. Evidence goes in `ralph/reports/<BIOME>/`.
- **Channel:** post on lane channel issue #356 (reopen it, or use the channel the
  owner names). Post only `READY FOR INTEGRATION: tb/<lane> <sha> closes F0x#n`,
  shared-file requests, and questions with a recommended answer.
- **Landing:** a coordinator session batches READY heads through `tb/integration`.
  It runs the unit suite once per batch and CI once per PR. Lanes do not open PRs.

## 3. How a lane works its queue

1. **Work the first criterion until it is done.** Done means its committed evidence
   meets the ACCEPTANCE §6.1 wording under the relaxed-proof rule (STATE §1.1),
   with shortcuts disclosed.
2. **If it is blocked,** start the next criterion. Blocked means waiting on a render,
   a judge, a verifier, a shared-file grant or another lane.
3. **The moment the blocked item can move again, switch back to it and finish it.**
   The earliest unfinished item always has priority.
4. **Nothing outside the list.** If you find another defect or idea, write one line
   in the lane's STATE row or on #356, give it an owner, and keep going. Don't fix it.
5. **Function, not beauty.** A criterion that mixes readability with Bars A/B
   closes in this phase on its functional and readability clauses. The Bars A/B
   clause is recorded as `Bars A/B → Phase 2 catalog` in the criterion's note.
   Don't spend rounds on art, materials or lighting polish. Owner direction for
   this phase: "not beautification, just function and completeness".
6. **The biome is done** when every listed criterion is met and then the biome's
   chapter cards pass an integrated run (§5). The dashboard bars for that
   biome then read complete.

Standing rules:
- Build the game, not proof machinery: every round must be player-visible.
- Two strikes on the same harness fix, then change approach or disclose.
- Put `Balance: game N / tests-tools M` on every READY.
- Hand mechanical work (logs, mirrors, scripts) to lower-tier subagents with exact
  file ownership.
- Keep a `tests/fixtures/band_split_baseline/*` mirror exact whenever you edit band data.

## 4. Queues (in order)

Status was taken from the board after batch 67. Re-read the board before you
start, because batch 68 (the Balance lane) may already have closed items.

### Meadows — `tb/meadows`
| # | Criterion | What is open |
|---|---|---|
| 1 | **F01#2** Day walk reaches every opening NPC, camp and gate | Render the day walk on current main, then a code-blind readability verdict on the three gate frames, the camp and the key. Signposts are in; the firepit is unwired WIP (re-apply 631b8390). |
| 2 | **F01#3** Night walk, same | Same at night. The key reads only by its UI prompt; making the key read in the world is the fix. |
| 3 | **F03#0** Six activities show a visible lure | The lure read passes (judge F). Remaining: an unstaged ordinary-discovery witness, a night cue at the herd, and moving the Hall pack to a road sightline (the nameplate draw-through stays off). |
| 4 | **F04#0** Warrens guardian | Already **met** (batch 67). Skip it. |
| 5 | **F04#1** Relay officers: readable tell and tactical question | The Vance placement and `ignore_lunging_foe` camera flag are WIP, currently off. Re-apply, render, judge readability. |
| 6 | **F04#2** Three captains: tactical question at normal distance | Round-1 verdict: Oreth and Vess PARTLY, Halder FAIL. Fix the ally occluding the foe, the point-blank CHARGER open and wilds inside arenas. |
| 7 | **F04#3** Warden: tactical question at normal distance | PARTLY. Fix the dialogue camera crowding him and the combat HUD staying up in the victory dialogue. |
| 8 | **F04#6** Distinct aftermath per fight | Captain handover dialogue is in. Each post still needs a staged world change (Sigil standard lowered, captain stands down), and the Warden's key and heart shown. |
| 9 | **F04#7** Varied-size framing and C2/C3 pass | The difficulty half is with the Balance lane (batch 68). This lane owns the C3 framing and the DIVER 0.4 s harness exemption. |

Then the cards (§5): **M1, M2, M3**. M2's 326 m Hall-exit walk is exempt (owner).

### Cloudreach — `tb/cloudreach`
| # | Criterion | What is open |
|---|---|---|
| 1 | **F08#3** Correct high-perch production camera | The camera and readability verdict already PASS (`ralph/reports/CLOUDREACH/b/f08-3-c3-judge/`). Close it on function. Aerie environment art → Phase 2 (Codex). |
| 2 | **F08#4** Settlements and cliff identity pass the C2 matrix | Function: each settlement is occupied and reads as its place from the approach (people, activity, navigable layout); cliffs read as routes and landmarks. Codex's towers and terrace candidates are merged but **off**; turn them on only if they serve function. Material and look → Phase 2. |
| 3 | **F08#5** Solmane | Already **met** (batch 67). Skip it. |

Then the cards: **C2, C3**. Card C3 waits on F08#3 and F08#4. Open debt: owned-carrier Fly, since every flight uses Maela's loaner.

### Stormwood — `tb/stormwood`
| # | Criterion | What is open |
|---|---|---|
| 1 | **F09#3** Loops, shortcuts, pockets and alternate routes traversable | Pocket lures aren't visible from the road; needs an ordinary walk witness. |
| 2 | **F10#2** Named fights pass C2/C3 | C2 starter parity is with the Balance lane (batch 68). This lane re-captures C3 from the ordinary route on the new fight camera. Stormwood-B commits 07bc9cad, 45927814 and 85ba1c57 (Elder cone and heading, guard cone) are in history but reverted; cherry-pick them if the footage needs them. Capacitor Alpha no-stagger is owner-confirmed. |
| 3 | **F10#3** Readable lightning and phase cues without HUD | The telegraph passes all five questions (r5). Open: a Break-only cue readable in a single still. |
| 4 | **F10#4** Forest, rod line and restored sky pass the matrix | Close on readability (forest reads YES). The scorched Glass Field (flag off) and the Stormheart hero tree → Phase 2. |
| 5 | **F10#6** Device profile | Computer capture at 1920×1080, `opengl3`, code-blind 7-inch readability. The compact fight roster is in; re-judge. |

Then the cards: **S1** (waits only on F09#3) and **S2**.

### Tidewake — `tb/tidewake`
| # | Criterion | What is open |
|---|---|---|
| 1 | **F13#3** Six local chains satisfy WORLD §5 | One uninterrupted run with real swims, 619/0. Needs a strict re-check; the lure clause is open. |
| 2 | **F13#5** Currents, inhabited docks and Veilfall distance read | Function: currents read as currents at the normal camera, docks are inhabited, Veilfall is readable at distance. Pump, banner and sluice assets are merged but unplaced (placement notes are in each asset's `source/integration.md`); the Pump Hall kitbash is flag off. Look → Phase 2. |
| 3 | **F14#0** Named encounters pass C2/C3 on the ordinary route | Aquaryn C3 12/16 (camera arm against the cliff); Tidecoil tells (the ring is now on the surface; verify it in a frame); Tess needs an ordinary-route witness and a graded pad. |
| 4 | **F14#1** Veilfall and Guardian pass C2/C3 | Nerissa: re-judge after the pillar and vine fix, and re-run the in-world C2 after the Riptusk lane change. Veilfall interior readability. |

Then the card: **T2**.

## 5. Finishing a biome

- **Card integrated runs.** Each card (ACCEPTANCE §6) needs one integrated run
  once all of its feeders are met.
- **Then** post `BIOME COMPLETE: <biome>` on #356 with the board rows, and wind the
  lane down: push everything, post FINAL with a WIP list, stop.
- **Final step, after all four biomes and the reorder:** one checkpointed
  four-chapter earned run on a single save (STATE §0), then a short human play pass.

## 6. Phase 1b: biome reorder (after all four biomes are complete)

**Owner direction:** the new order is **Meadows → Tidewake (water) → Cloudreach →
Stormwood**. One lane does this, on `tb/reorder`, working from the list below.
Record it as an owner decision in STATE, GAME_BIBLE, WORLD, PROGRESSION and ROADMAP
before implementing.

1. **Order and gates.** Realm order config; realm keys and gates (which chapter's
   finale grants which key); Rift and crossing destinations; the Meadows finale
   now opens Tidewake.
2. **Levels.** Re-derive creature and trainer levels per band for the new
   position (PROGRESSION curve). This covers wild spawn tables and named-trainer
   teams. Keep the C2 bar.
3. **Ending.** Homecoming, Grandpa and credits now follow Stormwood, not Tidewake.
   The T3 dock exchange stays in Tidewake, but the final return and credits move.
   Check that no fourth key and no sequel prompt appear.
4. **Traversal dependencies.** Tidewake needs swimming (F12) before Fly exists.
   Check that nothing in Tidewake assumes Fly, and nothing later assumes an
   earlier legendary.
5. **Legendary offers.** Each chapter's per-participant offer is unchanged. Only
   the order they arrive in changes.
6. **Economy.** The solvency ledgers (four-character and two-loss) re-run in the
   new order.
7. **Saves and fixtures.** Regenerate the earned checkpoint saves
   (`tests/fixtures/earned_saves/`) for the new chapter boundaries. Migrate old
   saves; no player loses items.
8. **Docs and cards.** Update the ACCEPTANCE card order, the handoff criteria and
   the four-chapter run.

Expect more than a gates-and-levels change: fixtures, the ending location,
ledgers and traversal assumptions all move. Scope it as its own feature, with a
READY per numbered item.

## 7. Open owner items (not a lane's to decide)

- Internet co-op resources: Steam AppID, partner access, four accounts.
- Whether Phase 1 may close a mixed criterion with its Bars A/B clause moved to
  Phase 2 (§3.5). This file assumes yes, following the owner's "function now,
  beauty next".
