# assemble.py <key.json> <j1.json> <j2.json> <j3.json> <out_batch.json> [<out_defects.json>]
import json,sys
key=json.load(open(sys.argv[1])); js=[json.load(open(p))['sets'] for p in sys.argv[2:5]]
b={'anchors':{},'candidates':{}}; dc={}
for code,k in key.items():
    for side in 'AB':
        vals=[]; calls=[]
        for j in js:
            s=j.get(code,{}).get(side)
            vals.append(None if s is None else s['bar_a']); calls.append(None if s is None else s.get('defects',{}))
        if k['anchor']: b['anchors'][k[side]]=vals
        else:
            arm='cand' if ('_b.' in k[side] or 'cand' in k[side]) else 'base'
            lab=f"{k['label']} {arm}"; b['candidates'][lab]=vals; dc[lab]=calls
json.dump(b,open(sys.argv[5],'w'),indent=1)
if len(sys.argv)>6: json.dump(dc,open(sys.argv[6],'w'),indent=1)
print(json.dumps(b)[:400])
