# Branch supersession, recorded 2026-08-22

Six `ralph/*` branches were superseded during today's Gate A/B/C
consolidation. Their content either shipped to `main` (via
`ralph/integration-ABC`) under a different branch/commit lineage, or was
replaced outright by a later owner-directed design (CONTROLLER-MAP). None
of the six should be re-shipped. Each carries its own marker commit at its
tip recording this; this file is the single index.

Branch deletion is currently blocked at the platform/credential level for
this session (both the GitHub MCP server and a direct `git push --delete`
return no delete-branch capability / HTTP 403). Delete these six once an
account with branch-delete permission is available:

- `ralph/TOURNAMENT-1` -- superseded by `claude/tournament-gate-b-kn9wpv`
  (see the "ralph/TOURNAMENT-1 is superseded by..." section below, recorded
  earlier today; that session's Gate B work is what actually shipped, as
  `ralph/TOURNAMENT-2` onto `ralph/integration-B` onto
  `ralph/integration-ABC` onto `main`, a22534ff).
- `ralph/TOURNAMENT-2` -- its own tip commit ("Handover: the green CI badge
  on this branch verified nothing but markdown") says not to trust its
  green CI. Its real, verified content shipped via
  `ralph/integration-B: merge TOURNAMENT-2 onto Gate C, exempt gate fights`
  onto `ralph/integration-ABC` onto `main`.
- `ralph/HUD-GLYPHS`, `ralph/HUD-LAYOUT`, `ralph/HUD-POPUP` -- all three are
  ancestors of `ralph/HUD-EMPHASIS`'s own history (their fixes reappear
  under different commit hashes further up that branch's log). HUD-EMPHASIS
  is what shipped, via `ralph/integration-ABC` onto `main`.
- `ralph/WEATHER-LIGHT` -- verified by dry-run merge: `git merge --no-commit
  --no-ff origin/ralph/WEATHER-LIGHT` against `main` (a22534ff) produces a
  zero-diff clean merge. Already shipped, via `ralph/integration-ABC`.
- `ralph/DPAD-COLLISION` -- fixed the same d-pad/hotbar collision
  CONTROLLER-MAP later fixed differently (and incompatibly: CONTROLLER-MAP
  bans held-button chords outright, D68). CONTROLLER-MAP is the version on
  `main`.

## ralph/TOURNAMENT-1 is superseded by claude/tournament-gate-b-kn9wpv

Both independently implement the village tournament from the same owner
directive (`ralph/OWNER_DIRECTIVES_2026-08-22.md` §2). `claude/tournament-gate-
b-kn9wpv` is materially more complete:

- an end-to-end smoke test that actually fights the bracket on real ground
  through the production route (marshal dialogue -> `battle:` effect ->
  `encounter_director.begin_trainer_battle()`), which `ralph/TOURNAMENT-1`'s
  own report flagged as a known gap and never built;
- found and fixed two real bugs the smoke test surfaced (a hard-coded 2.0m
  attack range that undercut the game's own reach; a body-clearance edge case
  where the final's Meadowhart genuinely needs 2.9m to land a swing);
- a bracket board rebuilt against a direct owner ruling this coordinator never
  received ("the tournament bracket should be a bracket and it should only
  fill in after events, not be filled in from the start") -- `bracket_state()`
  refuses to name a bout's participants until both feeding bouts are decided;
- three rounds of real blind visual critique on the board's geometry;
- a genuine fresh-save evidence run, honestly reported: it reaches the first
  wild encounter and stalls there -- eight orb throws, one strike, no catch,
  reticle reading 1.24/1.36/1.55 against a 0.6m body radius. Not yet proven a
  defect (that box is software-rendered; CI is not) but it is real evidence
  nobody else produced;
- confirmed directly with the owner and added the rested/fed/happy entry gate
  from the owner's *original* tournament wording ("catch five pals and get
  them to level 3... well rested, well fed, and happy"), which no other branch
  had built.
