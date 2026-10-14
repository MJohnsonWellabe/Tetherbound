import json,re,sys,gzip
regs=json.load(open('data/config/stormwood_world.json'))['regions']
def region(x,y,z):
    if ((x-700)**2+(z-2700)**2)**0.5<245 and y>50: return 'hollow_crown'
    for r in regs:
        b=r['bounds']
        if b['min_x']<=x<=b['max_x'] and b['min_z']<=z<=b['max_z']: return r['id']
    return 'cinder_verge'
pat=re.compile(r'STORMWOOD CHAIN clock .* at=\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)')
for name,path in [a.split('=') for a in sys.argv[1:]]:
    op=gzip.open if path.endswith('.gz') else open
    seen=[]
    for line in op(path,'rt',errors='replace'):
        m=pat.search(line)
        if m:
            r=region(*map(float,m.groups()))
            if not seen or seen[-1]!=r: seen.append(r)
    print(name, '->', ' > '.join(seen))
