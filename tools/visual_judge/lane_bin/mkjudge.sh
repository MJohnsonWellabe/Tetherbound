#!/bin/bash
# mkjudge.sh <batch> <base_arm> <cand_arm> <rows_csv> <seed> [include]
set -e; cd /home/user/Tetherbound; J=/tmp/claude-0/work/judge/$1; rm -rf $J; mkdir -p $J/k $J/j
python3 /tmp/claude-0/work/bin/build_spec.py $2 $3 "$4" $J/k
python3 tools/visual_judge/anchor_tiles.py --out $J/folder --key $J/k/key.json --candidates $J/k/spec.json --pairs 3 --include ${6:-craft} --seed $5 >/dev/null
cp -r docs/reference $J/folder/reference
python3 /tmp/claude-0/work/bin/fill_prompt.py $J/folder $J/k > $J/folder/JUDGE_INSTRUCTIONS.txt
cat $J/folder/sets.md | head -20
