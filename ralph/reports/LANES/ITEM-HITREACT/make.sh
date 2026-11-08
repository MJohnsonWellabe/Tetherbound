# Provenance: the live owner-remake GLBs, re-grounded with the existing tool (no new mesh).
for sp in shadelet paddlenewt glimmermoth tempestwing; do
  src=assets/creatures/tetherbound/$sp/candidate_owner1101/models/creature_${sp}_owner1101.glb
  dst=${src%.glb}_grounded.glb; cp "$src" "$dst"
  python3 tools/art_pipeline/ground_clip.py "$dst" hit --settle
done
# r1 also grounded the winged species' faint on the lowest vertex: the downward wing tip then
# held the body ~1.5 m in the air (worse than the clip), so faint is left unchanged.
