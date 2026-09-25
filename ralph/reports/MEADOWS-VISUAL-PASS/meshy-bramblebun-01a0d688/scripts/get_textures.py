import sys, json, urllib.request, pathlib
sys.path.insert(0,'/home/user/tetherbound/tools/art_pipeline')
import meshy
t=meshy.request("GET", meshy.ENDPOINTS["texture"]+"/01a0d688-9a9b-718d-83c8-d5e4c0ce9abf")
out=pathlib.Path('candidate')
print({k:(v if not isinstance(v,(dict,list,str)) or k in ('status','art_style','task_error') else type(v).__name__) for k,v in t.items()})
for i,tex in enumerate(t.get('texture_urls') or []):
    for k,u in tex.items():
        if u: urllib.request.urlretrieve(u, out/f"tex{i}_{k}.png"); print('saved',k)
meta={k:t.get(k) for k in ('id','status','created_at','started_at','finished_at','progress','art_style','text_style_prompt','enable_original_uv','enable_pbr','ai_model')}
(out/'task_meta.json').write_text(json.dumps(meta,indent=2))
print(meta)
