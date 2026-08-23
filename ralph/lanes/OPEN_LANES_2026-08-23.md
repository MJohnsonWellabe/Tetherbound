# Open lane briefs — 2026-08-23 afternoon

Paste one of these as the first message of a fresh claude.ai/code session
on this repo (or hand it to any idle worker). Each is self-contained.
Check `git branch -r` first — if the lane's branch already exists, the
lane is taken; pick another or coordinate in `ralph/ACTIVE_TASKS.md`.

Setup common to all: install Godot 4.7
(`mkdir -p ~/godot-bin && cd ~/godot-bin && curl -sSL -o g.zip
https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
&& unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64`), run
`--headless --import` once, NEVER combine `--headless` with
`--rendering-driver opengl3` (hangs forever — renders go through
`xvfb-run -a`). Read CLAUDE.md, ralph/START_HERE.md,
ralph/ASSESSMENT_2026-08-23.md, ralph/ACTIVE_TASKS.md,
ralph/conventions.md before working. Ship on the named `ralph/<lane>`
branch, DONE.md entry, one push at the end, no PR.

## LANE: SITE-SHOTS (small, ~1-2h)
Branch `ralph/SITE-SHOTS`. `ralph/BACKLOG.md` "SITE-SHOTS" entry: the
website (site/index.html) still wants, in value order: (1) a close
`tether-site.jpg` relay frame; (2) a Meadows Hall approach frame with the
Warden; (3) a dressed farmhouse-interior reshoot; (4) `camp-dusk` /
`weather-rain` fixes+reshoot. Also fix the stale CSS comment in
site/index.html (~line 342) claiming village-square.jpg is absent — the
file exists now. Use tools/capture_site_shots.gd patterns. JPEG exports
go in site/img/ (their .import sidecars are gitignored).

## LANE: RUN-TESTS-FILTER (tiny, <1h)
Branch `ralph/RUNTESTS-FILTER`. tests/run_tests.gd has only `--shard=I/N`;
give it `--only=<substring>` filtering (documented in its header), so
targeted reruns stop needing hand-rolled scratch runners (three sessions
have now built one). Keep shard semantics unchanged; add a unit test if
the harness has self-tests.

## LANE: BAND2-FOREST-FLOOR (medium)
Branch `ralph/BAND2-FLOOR`. Blind critique: band2's forest floor is the
same mown lawn as open fields — no leaf litter, undergrowth, fallen
branches, saplings; canopy splits into black interior vs acid-lime rim
with uniform salmon trunks. Scene-fixable half only: floor scatter under
canopy (leaf litter/deadfall/undergrowth entries in band2's config —
coordinate with ralph/VISUAL-GROUNDCOVER if it landed; do not touch
vegetation.json globals another lane owns), and vary trunk tint/girth
within the installed material set. Bark MATERIAL redesign is needs-art —
record, don't attempt. Blind-judge convergence per conventions.
