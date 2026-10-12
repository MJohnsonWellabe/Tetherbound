import json,glob,os
kinds={}
_TC=json.load(open('data/config/type_chart.json'))['matchups']
_SP=json.load(open('data/creatures/species.json')); _SP=_SP.get('species',_SP) if isinstance(_SP,dict) else _SP; _SP=_SP if isinstance(_SP,dict) else {x['id']:x for x in _SP}
_NAMED={n['id']:n.get('species_id',n.get('species')) for n in json.load(open('data/config/water_encounters.json'))['named_encounters']}
def _mult(a,b): return float(_TC.get(a,{}).get(b,1.0))
def _advantaged(r):
    # COMBAT §7 type class from the project's own chart: the lead's type into
    # the foe vs the foe's type into the lead (species types, primary only).
    foe=_NAMED.get(r['case'],''); lt=_SP.get(r['starter'],{}).get('type',''); ft=_SP.get(foe,{}).get('type','')
    return _mult(lt,ft)/max(1e-9,_mult(ft,lt))>1.0
rows=[]
for f in sorted(sum([glob.glob(p) for p in __import__('sys').argv[1:]],[])):
    d=json.load(open(f))
    for r in d['rows']:
        m=r['pilots']['MASHER'];R=r['pilots']['READER'];k=r['kind']
        reasons=[]
        if k in ('top','top_critical','veilfall_top'):
            if R['win_rate']<0.75: reasons.append('rwin %.2f'%R['win_rate'])
            if m['lead_faint_rate']<1.0: reasons.append('m_leadfaint %.2f'%m['lead_faint_rate'])
            if R['median_party_cost']>0.55*m['median_party_cost']: reasons.append('party %.3f/%.3f'%(R['median_party_cost'],m['median_party_cost']))
        elif k=='named_wild' and _advantaged(r) and m['median_party_cost']<=0.15:
            # COMBAT §7 trivial-fight floor (coordinator, owner-delegated,
            # 2026-10-12): a type-advantaged lead whose masher pays <=15% party
            # HP passes if the reader wins at least as often and pays no more.
            k='named_wild/trivial_floor'
            if R['win_rate']<m['win_rate']: reasons.append('floor: rwin %.2f < masher %.2f'%(R['win_rate'],m['win_rate']))
            if R['median_party_cost']>m['median_party_cost']: reasons.append('floor: party %.3f > masher %.3f'%(R['median_party_cost'],m['median_party_cost']))
        else:
            if R['win_rate']<0.9: reasons.append('rwin %.2f'%R['win_rate'])
            if R['median_lead_cost']>0.55*m['median_lead_cost']: reasons.append('lead %.3f/%.3f'%(R['median_lead_cost'],m['median_lead_cost']))
        hit=max(m['max_single_hit_frac'],R['max_single_hit_frac']); tell=min(x for x in (m['min_tell_s'],R['min_tell_s']) if x>=0)
        if hit>=0.5: reasons.append('hit %.3f'%hit)
        if tell<0.8-1e-3: reasons.append('tell %.2f'%tell)
        st=m['stalled']+R['stalled']
        print(f"{r['case']:34s} {k:25s} {r['starter']:9s} L{r['party_level']} M win={m['win_rate']:.2f} lf={m['lead_faint_rate']:.2f} lead={m['median_lead_cost']:.2f} party={m['median_party_cost']:.2f} | R win={R['win_rate']:.2f} lead={R['median_lead_cost']:.2f} party={R['median_party_cost']:.2f} s={R['median_seconds']:.0f} hit={hit:.3f} tell={tell:.2f} st={st} {'PASS' if not reasons else 'FAIL '+'; '.join(reasons)}")
        rows.append((r,reasons))
# chapter masher loss over trainer cases
for s in ['terrapup','ripplet','galewisp']:
    surv=1.0;n=0
    for r,_ in rows:
        if r['starter']==s and r['kind']!='named_wild' and r['kind']!='alpha':
            surv*=r['pilots']['MASHER']['win_rate'];n+=1
    print('CHAPTER',s,'trainers',n,'masher_loss=%.2f'%(1-surv))
