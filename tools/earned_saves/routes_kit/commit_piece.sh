#!/usr/bin/env bash
# Commit one passing piece's end save + receipt (+ PROVENANCE) as a handoff fixture and push at once.
#   EDIT=<worktree on tb/routes> RB=~/rb commit_piece.sh <run dir name> <fixture name>
set -e
RB="${RB:-$HOME/rb}"; EDIT="${EDIT:?worktree checkout of the lane branch}"; BR="${BR:-tb/routes}"
src="$RB/$1"; [ -d "$src/save" ] || src="$(dirname "$(ls -d "$RB/$1"/*/save | head -1)")"
dst="$EDIT/tests/fixtures/earned_saves/$2"
cd "$EDIT" && git fetch -q origin "$BR" && git merge -q --ff-only "origin/$BR" 2>/dev/null || true
rm -rf "$dst"; mkdir -p "$dst"; cp -r "$src/save" "$dst/"
for f in receipt.json PROVENANCE.json; do [ -f "$src/$f" ] && cp "$src/$f" "$dst/"; done
git add "$dst" && git commit -qm "F49#0 piece save: $2 (from $1)"
for i in 1 2 3 4; do git push -q origin "HEAD:$BR" && break; sleep $((2**i)); done
git log --oneline -1
