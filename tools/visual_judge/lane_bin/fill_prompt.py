# fill_prompt.py <judge_dir> <key_dir> -> prints the standard prompt with its three slots filled
import sys,re
R='/home/user/Tetherbound/'; jd,kd=sys.argv[1:3]
t=open(R+'tools/visual_judge/JUDGE_PROMPT.md').read()
t=re.search(r'```text\n(.*?)```',t,re.S).group(1)
t=t.replace('[JUDGE FOLDER]',jd).replace('[SET LIST]',open(jd+'/sets.md').read().strip()).replace('[RECORDED DEFECTS]',open(kd+'/recorded_defects.txt').read().strip())
print(t)
