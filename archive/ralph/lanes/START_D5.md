# START D5 — Stronghold Approach

**Branch:** `ralph/gate-d-band5-stronghold-approach`
**Band directory:** `data/config/bands/band5_stronghold_approach/` — yours whole
**Also yours:** `data/config/stronghold.json`, **exterior and approach keys only**
**Reserved `order` range:** 5000–5999
**Owning prompt:** `docs/ralph-prompts/66-BAND5-finished-stronghold-approach.md`
**Spine:** z 7000 → 7680, **680 m — the shortest region in the chapter and
deliberately the densest per metre.**

Read `ralph/lanes/COMMON.md` first, then `ralph/GATE_D_LANE_CONTRACT.md`, then
your prompt, then `ralph/DONE.md`'s D5 entries.

Your segment starts when the three-Sigil approach opens and **ends at Meadows
Hall entry.** The region's question: **am I ready to commit my five to the final
assault?**

## Hard scope boundary

**The Hall interior, the trainer gauntlet, the elite, the Warden, the tether
reveal, the legendary choice, the release ceremony and the world healing are
Gate E**, owned by `docs/ralph-prompts/69-STRONGHOLD-chapter-finale.md`.
`data/config/stronghold_climax.json` is **not yours**. If the approach genuinely
needs a change inside the finale's files, describe it in your report and leave
it for Gate E.

## Already done on this branch

Branch head is `9bfa38b` plus one coordinator commit that saved
`tools/_probe_stronghold_mat_quick.gd` — the lane was moved to this session
before it could finish, and that probe was the only uncommitted file left in its
worktree. Nothing was lost, but **this lane's own final report was never
written**, so treat the list below as what is visible in the branch rather than
as a verified account.

- **Density**: 4 clusters / 9 creatures → **22 clusters / 75 creatures** over
  680 m, inside the owner's 18–28 / 70–110 target. **Density is done.**
- Initial content commit covering trainers, ecology and a materials fix.
- A stronghold-material probe kept for re-running that check.

**Your first job is to establish ground truth**: run
`python3 tools/_probe_chapter_map.py`, read the branch's own diff against
`926ba04`, and read whatever `ralph/DONE.md` entries exist. Do not assume the
list above is complete or correct.

## What prompt 66 still wants

1. **Trainer siting.** At baseline all four trainers sat inside a 12 m span at
   z=7557–7569 — the Hall's doorstep, not an approach. Prompt 66 wants ordinary
   faction patrols and checkpoints building pressure **across the 680 m**, and
   warns *"do not consume every major combat beat before the stronghold."*
   Note `warden_aldis` and the interior gauntlet belong to Gate E. Check what
   the branch has actually changed here before authoring more.
2. **Gatherables and props.** At baseline both files were empty arrays — the
   approach fielded Team Tether's gauntlet and nothing else authored. Prompt 66:
   *"must still contain Meadows ecology and resource decisions. It should not
   become an empty faction corridor."* Verify current state.
3. **Navigation spine** — pylons and landmarks creating readable world-space
   direction without becoming magical GPS. Owning prompt
   `16-RG17-continuous-tether-pylon-navigation-spine.md`. Fix stale coordinate
   drift **only from current evidence**; reproduce before changing.
4. **Storm/gated crossings** — `19-STORM-GATE-two-grunts-guard-bridge.md`. Use
   the current canonical placement if it belongs on this route. A physical gorge
   or barrier must actually constrain travel and must not be trivially
   bypassable. Verify current state first.
5. **Final preparation point** — a memorable place to stop, adjust the five,
   rest or camp, or return home before the stronghold. **Do not create an
   automatic free heal** unless current canon already provides one.
6. **Special encounter** — one final optional strong wild or discovery that
   tempts a prepared player to risk resources before entering the Hall.
7. **Environmental storytelling** — the land visibly under the tether system's
   effect before Hall entry, using the existing machinery, the drained-ground
   and healing systems (`data/config/meadow_healing.json`) and the faction's own
   language. No new lore.
8. **Visual cleanup, reproduce-first, fix only if still present**:
   `21-STRONGHOLD-MAT` (materials), `22-SKY-PLANES` (sky-plane artifacts),
   `23-BILLBOARD-WHITE` (white billboards), and torch/night readability on the
   final route. Several of these have been fixed already and the repo has a
   documented habit of carrying stale bug prose — **reproduce on the current
   branch before touching any of them.** `tools/_probe_stronghold_mat_quick.gd`
   is on the branch for exactly this.

## Verification still owed

- A driven run — `tests/smoke_stronghold.gd`, `tests/smoke_traversal.gd`, or a
  purpose-built probe. Record route readability, wild/trainer/resource
  opportunities, whether the stronghold grows in visual dominance as you
  approach, whether faction occupation escalates, the longest dead-travel
  interval in metres, and any collision or gate failures.
- **A blind visual pass — this region is unusually visually load-bearing.** The
  stronghold silhouette, the pylons, the drained ground and the night route are
  the whole point of it. Produce captures, then **ask the coordinator to
  dispatch the independent critic.** Do not judge your own frames.
- Full suite green before push.
- A `ralph/DONE.md` entry — this lane does not have a complete one.
- A `density_scale` request for band5 (currently at the 0.03 chapter floor) if
  the region reads bare, **reported as a number, not edited into the shared
  file.**

## The Warden

He **is already rebuilt** from the owner's board-16 character sheet. Do not
reopen historical notes claiming his face is painted or unmodelled — inspect
`assets/characters/warden/warden_lod0.glb` instead. Team Tether personnel use
the grunt rig with rank presentation from `data/config/npc_ranks.json`.
