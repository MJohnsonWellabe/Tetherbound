#!/bin/bash
# chain.sh <base_arm> <cand_arm> <rows> <overlay_file> : wait base DONE, overlay, run cand, revert.
# Holds scene.lock from overlay to revert so no other job's capture runs with this overlay applied.
cd /home/user/Tetherbound; export GIT_OPTIONAL_LOCKS=0
until grep -q DONE .artifacts/vl/$1/run.log 2>/dev/null; do sleep 30; done
exec 7>/tmp/claude-0/work/scene.lock; flock 7; export SCENE_HELD=1
OV="$(cat $4) $(cat $4.extra 2>/dev/null)"
files=$(for s in $OV; do echo ${s%%:*}; done | sort -u)
python3 /tmp/claude-0/work/bin/overlay.py $OV > .artifacts/vl/overlay_$2.log 2>&1 || { git checkout -- $files; echo OVERLAY_FAIL >> .artifacts/vl/overlay_$2.log; exit 1; }
/tmp/claude-0/work/bin/run_group.sh $2 "$3"
for i in 1 2 3 4 5; do git checkout -- $files && break; sleep 5; done
echo REVERTED >> .artifacts/vl/$2/run.log
