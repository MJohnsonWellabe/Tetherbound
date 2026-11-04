# usage: overlay.py file:dotted.path [...]  (path '' = top level). Temp capture overlay; revert with git checkout.
# A path ending at a dict flips its 'enabled'; a path ending at a bare false flips that key.
import json,sys
for spec in sys.argv[1:]:
    fn,path=spec.split(':',1); keys=[p for p in path.split('.') if p]
    d=json.load(open(fn)); o=d
    for k in keys[:-1]: o=o[k]
    if keys and o[keys[-1]] is False: o[keys[-1]]=True
    else:
        t=o[keys[-1]] if keys else o
        assert t.get('enabled') is False, spec
        t['enabled']=True
    open(fn,'w').write(json.dumps(d,indent=2)+'\n'); print('ON',spec)
