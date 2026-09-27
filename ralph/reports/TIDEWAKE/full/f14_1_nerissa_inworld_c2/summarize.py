import json,glob,statistics as st,sys
rows=[]
for f in glob.glob('' + (sys.argv[1] if len(sys.argv) > 1 else 'runs') + '/*.jsonl',recursive=True):
    for l in open(f):
        l=l.strip()
        if l: rows.append(json.loads(l))
cells={}
for r in rows: cells.setdefault((r.get('starter'),r.get('pilot')),[]).append(r)
print("starter pilot n win wipe med_lead_lost med_party_lost max_hit tells_min-max reached_all err")
for k in sorted(cells):
    R=cells[k]; n=len(R)
    ok=[r for r in R if not r.get('error')]
    print(k[0],k[1],n, round(sum(r['won'] for r in ok)/max(1,len(ok)),2), round(sum(r['party_wiped'] for r in ok)/max(1,len(ok)),2),
      round(st.median([r['lead_lost_frac'] for r in ok]),3), round(st.median([r['party_lost_frac'] for r in ok]),3),
      round(max(r['max_hit_frac'] for r in ok),3), min(r['min_tell_s'] for r in ok), max(r['max_tell_s'] for r in ok),
      sum(1 for r in ok if r.get('opponents_seen',0)>=4), len(R)-len(ok))
