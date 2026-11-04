#!/bin/bash
# run_group.sh <arm> <rows-csv> : runs every merged launch for these rows into res://.artifacts/vl/<arm>/<n>
arm=$1; rows=$2; cd /home/user/Tetherbound
sha=$(git rev-parse HEAD); export XDG_DATA_HOME=/tmp/claude-0/work/xdg; mkdir -p $XDG_DATA_HOME .artifacts/vl/$arm
n=0
python3 /tmp/claude-0/work/bin/plan_runs.py "$rows" > .artifacts/vl/$arm/plan.jsonl
while IFS= read -r line; do
  n=$((n+1)); out="res://.artifacts/vl/$arm/$n"
  script=$(echo "$line" | python3 -c "import sys,json;print(json.load(sys.stdin)['script'])")
  args=$(echo "$line" | python3 -c "
import sys,json,shlex;e=json.load(sys.stdin);print(' '.join(shlex.quote(a) for a in e['args']+e['subsets']))")
  outflag="$(echo "$line" | python3 -c "import sys,json;print(json.load(sys.stdin)['outflag'])")=$out"
  sc=""; grep -q "source-commit" ${script#res://} $(grep -o 'extends "res://[^"]*"' ${script#res://} | sed 's/extends "res:\/\///;s/"//') 2>/dev/null && sc="--source-commit=$sha"
  if [ -f .artifacts/vl/$arm/$n.ok ]; then echo "  skip #$n (done)" >> .artifacts/vl/$arm/run.log; continue; fi
  rm -rf .artifacts/vl/$arm/$n; echo "[$(date -u +%H:%M)] $arm #$n $script $args" >> .artifacts/vl/$arm/run.log
  SL=""; [ -z "$SCENE_HELD" ] && SL="flock /tmp/claude-0/work/scene.lock"
  eval $SL flock /tmp/claude-0/work/godot.lock timeout 3000 xvfb-run -a -s \"-screen 0 1920x1080x24\" godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --resolution 1920x1080 --script $script -- $args $outflag $sc > .artifacts/vl/$arm/$n.log 2>&1
  rc=$?
  if [ $rc -ne 0 ] && [ -z "$(ls .artifacts/vl/$arm/$n 2>/dev/null)" ] && { grep -q "Phase 2 evidence\|VISUAL/phase2" .artifacts/vl/$arm/$n.log || [[ "$script" == *phase2_capture_* ]]; }; then
    b=$(echo "$args" | grep -o -- '--biome=[a-z]*' | head -1 | cut -d= -f2)
    case "$script" in *tidewake*|*swimming*|*current_states*) b=${b:-tidewake};; *cloudreach*) b=${b:-cloudreach};; *stormwood*) b=${b:-stormwood};; esac
    b=${b:-meadows}; [ "$b" = water ] && b=tidewake
    pdir=ralph/reports/VISUAL/phase2/$b/vl_${arm}_$n; rm -rf $pdir
    echo "  retry under $pdir" >> .artifacts/vl/$arm/run.log
    SL=""; [ -z "$SCENE_HELD" ] && SL="flock /tmp/claude-0/work/scene.lock"
  eval $SL flock /tmp/claude-0/work/godot.lock timeout 3000 xvfb-run -a -s \"-screen 0 1920x1080x24\" godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --resolution 1920x1080 --script $script -- $args ${outflag%%=*}=res://$pdir $sc > .artifacts/vl/$arm/$n.log 2>&1
    rc=$?; [ -d $pdir ] && mv $pdir .artifacts/vl/$arm/$n
  fi
  [ $rc -eq 0 ] && touch .artifacts/vl/$arm/$n.ok
  echo "  exit $rc files $(ls .artifacts/vl/$arm/$n 2>/dev/null | grep -c jpg)" >> .artifacts/vl/$arm/run.log
done < .artifacts/vl/$arm/plan.jsonl
echo DONE >> .artifacts/vl/$arm/run.log
