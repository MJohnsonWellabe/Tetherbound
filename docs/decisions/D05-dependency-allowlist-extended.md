# D05. Dependency allowlist extended

Kind: spec-conflict

`CLAUDE.md` sets the approved runtime dependency list at three, howler and
simplex-noise, and requires a one-line justification for any addition.

- `@babylonjs/core`, `@babylonjs/loaders`: the renderer, per D1. Replaces `three`.
- `firebase`: accounts and cloud checkpoints, per D2. Dynamically imported in
  `src/cloud/`, so it lands in its own chunk and never loads for a signed-out or
  locally-configured player.
