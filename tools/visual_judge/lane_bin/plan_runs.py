import json,re,collections,sys,shlex
ROOT='/home/user/Tetherbound/'
want=set(sys.argv[1].split(',')) if len(sys.argv)>1 else None
d=json.load(open(ROOT+'ralph/reports/VISUAL/item-scores/job.json'))
bs=d['biomes']; bs=bs.values() if isinstance(bs,dict) else bs
launch=collections.OrderedDict()   # key=(script, normalized args) -> {subsets, frames, rows}
for bi in bs:
  for it in (bi['items'] if isinstance(bi,dict) else bi):
    if want and it['board_row'] not in want: continue
    for f in it.get('frames',[]):
      toks=shlex.split(f['repro'])
      i=toks.index('--script'); script=toks[i+1]; rest=toks[toks.index('--')+1:] if '--' in toks else []
      subs=[t for t in rest if t.startswith('--subset=')]
      norm=tuple(t for t in rest if not t.startswith(('--subset=','--output=','--out=')))
      k=(script,norm, bool(subs))
      e=launch.setdefault(k,{'subsets':[],'frames':[],'rows':set(),'outflag':next((t.split('=')[0] for t in rest if t.startswith(('--output=','--out='))),'--output')})
      for s in subs:
        if s not in e['subsets']: e['subsets'].append(s)
      e['frames'].append(f['id']); e['rows'].add(it['board_row'])
      if not subs: e.setdefault('single',[]).append(f['repro'])
for (script,norm,hs),e in launch.items():
  print(json.dumps({'script':script,'args':list(norm),'subsets':e['subsets'],'frames':sorted(set(e['frames'])),'rows':sorted(e['rows']),'single':e.get('single',[])[:3],'outflag':e['outflag']}))
