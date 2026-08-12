# Regenerating the Ralph Ledger

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
   - Some open `-remainder` items are unreadable without an immediately
     preceding *closed* item's own paragraph (it supplies "here's the
     evidence, here's the bar to clear"). Flag those specifically as
     `load_bearing_closed` on the phase, with `why_load_bearing` stating
     which open item needs it.
   - Output shape — write `data/phases.json` as a bare JSON array:
     ```json
     [
       {
         "phase_number": "-1",
         "title": "urgent PC bugs (owner-reported, 2026-08-10)",
         "line_start": 79,
         "open_items": [
           { "id": "R6-...", "title": "...", "line": 28,
             "meta": "model: sonnet · tests: none · area: village",
             "done_when": "one to two sentence paraphrase" }
         ],
         "closed_count": 5,
         "load_bearing_closed": [
           { "id": "EV2", "title": "...", "line": 234,
             "why_load_bearing": "one sentence" }
         ]
       }
     ]
     ```
   - Be precise about open vs closed — err toward double-checking
     ambiguous cases over guessing; this feeds a page the owner actually
     relies on. If unsure, spawn a subagent with the exact rules above
     rather than skimming — that's how the first version of this file
     was built (see git log on this path for the original prompt).

3. **Re-derive `data/leases.json`.** From fresh `STATUS.md`, one entry per
   live lease block:
   ```json
   { "firing": "...", "task": "...", "area": "...",
     "state": "working|started|...", "updated": "HH:MMZ",
     "note": "the block's own latest note, trimmed to ~2-3 sentences" }
   ```
   Keep `lane-heartbeat` entries too (the template filters them out of the
   card grid but still counts distinct non-`lane-*` areas from them for
   the "live lanes right now" stat).

4. **Re-derive `data/blocked.json` and `data/info_strip.json`** from fresh
   `BLOCKED.md`. `blocked.json` is the real "waiting on the owner" stops —
   each with `title`, `body` (the evidence/why-it's-stuck), `clears` (what
   resolves it). `info_strip.json` is short one-line notes that don't need
   a full card: things that recently cleared, the reference-art queue
   state, and which play gates the loop deliberately doesn't block on.
   Drop items from both once `BLOCKED.md` shows them resolved; add new
   ones as they appear. Don't just append — this file should reflect
   current state, not accumulate history.

5. **Update `data/meta.json`** with the short SHAs actually used
   (`git rev-parse --short`) and today's date.

6. **Regenerate the HTML:**
   ```
   cd ralph/ledger && python3 generate_ledger.py
   ```
   This only does template substitution — steps 2-5 are where the real
   work (and any judgment calls) happen. If the script errors on an
   unfilled placeholder, one of the `data/*.json` files is missing a key.

7. **Commit and push** to `claude/branch-cleanup-ralph-npc-snanmh`
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

8. **Republish the artifact**, keeping the same public URL, by calling
   the `Artifact` tool with `file_path` pointing at the regenerated
   `ralph/ledger/dashboard.html` and `url` set to
   `https://claude.ai/code/artifact/00b64dd7-3dae-4e93-9bc2-64f442538d31`
   (the owner's canonical link — always pass `url`, never republish
   without it, or a duplicate artifact gets created instead of updating
   this one). Reuse the same favicon (📒) and title ("Ralph Ledger").

## Cost note

Step 2 is the expensive part (a full read of a 2000+ line file). If the
loop's own cadence means `BACKLOG.md` genuinely hasn't changed since the
last refresh (check `git log -1 --format=%H origin/main -- ralph/BACKLOG.md`
against the previous run's recorded main SHA), it's fine to skip
re-deriving `phases.json` and only refresh `leases.json` /
`blocked.json` / `info_strip.json` / `meta.json`, which are cheap. Don't
skip silently — note in the commit message that phases were carried
forward unchanged.
