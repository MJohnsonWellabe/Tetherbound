# Regenerating the Ralph Ledger ("Ralph's Field Log")

This is a read-only dashboard over `ralph/BACKLOG.md`, `ralph/BLOCKED.md`
and the live leases on `ralph-status`. It has no effect on the loop — the
loop never reads anything in this directory. It exists purely so the owner
can scan project state without holding `BACKLOG.md`'s 2000+ lines of
priority-ordered, mostly-machine-authored prose in their head.

A Routine fires this procedure on a schedule (see the trigger named
"Ralph Ledger refresh" — `list_triggers` to find it if needed). Each firing
is a fresh session with no memory of the last one — follow this file
top to bottom.

## Steps

1. **Pull fresh sources.**
   ```
   git fetch origin main ralph-status
   git show origin/main:ralph/BACKLOG.md > /tmp/BACKLOG.md
   git show origin/main:ralph/BLOCKED.md > /tmp/BLOCKED.md
   git show origin/ralph-status:STATUS.md > /tmp/STATUS.md
   ```
   (STATUS.md may live at a different path on that branch — `git show
   origin/ralph-status:ralph/STATUS.md` if the first form 404s.)

2. **Re-derive `data/phases.json`.** Read the fresh `BACKLOG.md` in full
   (it's long — read it in chunks, don't stop partway). Structure:
   - `## Phase N — title` sections, in priority order top to bottom,
     including negative-numbered phases (`-1`, `-0.95`, ... `-0.5`) that
     are spliced-in urgent work ahead of the main plan.
   - `### ID — title` item headers within each phase, each followed by
     prose (area/model/tests tags, a done-when/acceptance description).
   - An item is **closed** if its own text block carries a closure marker
     for itself — "DONE", "CLOSED", "SHIPPED", "shipped", "closed",
     "merged", etc. — appearing in or right after its own prose. Don't be
     fooled by a *different* nearby item's marker, or a marker describing
     one of this item's *dependencies*.
   - Output shape — write `data/phases.json` as a bare JSON array, one
     entry per phase, each item using the Field Log's own item schema
     (not a separate `meta`/`done_when` field — this design keeps titles
     clean and pulls `model`/`area` out as their own fields):
     ```json
     [
       {
         "num": "-1",
         "name": "urgent PC bugs (owner-reported, 2026-08-10)",
         "items": [
           { "id": "R6-...", "title": "SceneTree teardown throws a real freed-instance error",
             "gate": false, "model": "sonnet", "area": "village" }
         ],
         "closed": 5
       }
     ]
     ```
     `gate` is true for play-gate items (marked `▶` in the raw file, or
     titled "Play gate — ..."). `model`/`area` come from the item's own
     `model:`/`area:` tags where present, else `null`. Don't reproduce the
     `tests:`/section-reference suffix in `title` — keep titles clean, the
     way most (not all) items in the current file already are.
   - Be precise about open vs closed — err toward double-checking
     ambiguous cases over guessing; this feeds a page the owner actually
     relies on. If unsure, spawn a subagent with the exact rules above
     rather than skimming.

3. **Re-derive `data/categories.json`** — the "By Feature" tab's 12 fixed
   buckets. **Do not invent new categories** — every item goes into one of
   these twelve, chosen by subject matter a player would recognize, not by
   phase or execution order:

   | Category | What belongs here |
   |---|---|
   | Story & The Meadows Chapter | Named trainers, the river/relay, the stronghold, every authored story beat, chapter pacing/gates |
   | Terrain & World | Vegetation, paths, water, lighting, weather, the world's physical edges/spokes |
   | Village & Settlement | The starting settlement as a place: buildings, props, site plan, village-specific bugs |
   | Characters & Cast | The trainer/Grandpa/Warden/NPC identity work itself (not their story beats — that's the Story bucket) |
   | Creatures & Roster | The wild/starter roster: models, palettes, production, evolution art |
   | Combat & Progression | Levels, moves, bond, evolution mechanics, the team, fainting/recovery |
   | Building & Crafting | Tools, structures, orbs/potions, harvesting, storage, food — what the player makes |
   | UI & HUD | HUD, menus, glyphs, backpack/build panels, input |
   | Traversal & Riding | Movement across the world, mounts |
   | Systems & Persistence | Save/load, quest tracking, player HP/death, any state that survives a session |
   | Polish & Performance | Feel, framerate, controller readability, whole-build passes, the exit gate |
   | Pipeline & Tooling | Not player-facing — the loop's own infrastructure, vocabulary sweeps, dev tools, doc corrections. Kept last/separate in the UI. |

   For each category compute `openCount` (items now open in that bucket),
   `shippedCount`, and `pct = round(100 * shipped / (open + shipped))`.
   `items` is the open items only (same shape as `phases.json` items,
   minus `num`).

   **This total is inherently approximate** — the source file gives you
   individual item identities for open work but only aggregate counts for
   closed work, so there's no ground truth for exactly which category a
   long-since-shipped item belonged to. Anchor it instead: take the
   *previous* `data/categories.json` (in the repo already) as your prior
   for each category's total item count (open+shipped as of last cycle).
   For each item still open, keep it in whatever category it was already
   in. For items that disappeared from open (shipped since last cycle),
   just decrement nothing explicitly — recompute `shippedCount = category
   total − new openCount`. For genuinely new items (no prior entry, not a
   `-remainder`/suffix continuation of one), add 1 to that category's
   total. After doing this for all 12, the categories' summed
   `openCount`/`shippedCount` may drift slightly from `phases.json`'s
   authoritative totals — if the drift exceeds a few items, rescale each
   category's `shippedCount` proportionally (largest-remainder rounding)
   so the sum matches `phases.json` exactly. The Overview tab always uses
   `phases.json`'s totals directly; only the Feature tab depends on this
   derived breakdown.

4. **Re-derive `data/leases.json` and `data/areas.json`.** From fresh
   `STATUS.md`, one row per *held* lease (skip `lane-heartbeat` entries —
   those aren't area claims):
   ```json
   [{ "area": "village", "task": "R6-...", "state": "working", "when": "10:56" }]
   ```
   `areas.json` is a flat array of area names — the dashboard's watchlist.
   It's a **growing union, never pruned**: start from the existing file,
   add any area name seen in this cycle's `STATUS.md` that isn't already
   listed. Being marked "free" (no current lease) is exactly the useful
   signal this table exists to show, so don't remove an area just because
   it's idle. `generate_ledger.py` computes the free rows itself — don't
   hand-write them.

5. **Re-derive `data/blocked.json` and `data/gates.json`** from fresh
   `BLOCKED.md`. `blocked.json` is `{t, d}` cards — real "waiting on the
   owner" stops, description folding in what clears it (no separate field
   for that in this design). `gates.json` is `{id, d}` — the play gates
   the loop deliberately doesn't wait on. Drop resolved items, don't just
   append — this should reflect current state.

6. **Update `data/meta.json`** with the short main SHA actually used
   (`git rev-parse --short origin/main`) and a snapshot timestamp
   (`YYYY-MM-DD HH:MM UTC`, the time you pulled sources in step 1).

7. **Regenerate the HTML:**
   ```
   cd ralph/ledger && python3 generate_ledger.py
   ```
   This only does template substitution and the leases free/held merge —
   steps 2-6 are where the real work (and any judgment calls) happen. If
   the script errors on an unfilled placeholder, one of the `data/*.json`
   files is missing a key.

8. **Commit and push** to `claude/branch-cleanup-ralph-npc-snanmh`
   (the branch this directory currently lives on):
   ```
   git add ralph/ledger/
   git commit -m "Refresh Ralph Ledger"
   git push -u origin claude/branch-cleanup-ralph-npc-snanmh
   ```
   This is a docs/data-only change with no gameplay-code risk, so it does
   not need to go through the Ralph loop's own CI-gated ralph/* branch
   flow. If a future firing finds this branch has since been merged and
   deleted, recreate it from `main` (`git checkout -B
   claude/branch-cleanup-ralph-npc-snanmh origin/main`) and carry this
   directory forward onto it, same as any other branch-restart case.

9. **Republish the artifact**, keeping the same public URL, by calling
   the `Artifact` tool with `file_path` pointing at the regenerated
   `ralph/ledger/dashboard.html` and `url` set to
   `https://claude.ai/code/artifact/00b64dd7-3dae-4e93-9bc2-64f442538d31`
   (the owner's canonical link — always pass `url`, never republish
   without it, or a duplicate artifact gets created instead of updating
   this one). Title stays "Ralph's Field Log"; keep whatever favicon the
   artifact already has.

## Cost note

Step 2 is the expensive part (a full read of a 2000+ line file). If the
loop's own cadence means `BACKLOG.md` genuinely hasn't changed since the
last refresh (check `git log -1 --format=%H origin/main -- ralph/BACKLOG.md`
against the previous run's recorded main SHA), it's fine to skip
re-deriving `phases.json`/`categories.json` and only refresh
`leases.json`/`areas.json`/`blocked.json`/`gates.json`/`meta.json`, which
are cheap. Don't skip silently — note in the commit message that phases
were carried forward unchanged.
