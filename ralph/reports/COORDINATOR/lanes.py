import json,sys
t=open(sys.argv[1]).read()
dec=json.JSONDecoder(); i=0
ids={'013jXLSe':'Meadows','01P23DEK':'F05','01LrLvG3':'Cloudreach','01VywYV1':'Stormwood','01Ry9obq':'Tidewake','017eCNMo':'Art','01SGs4NG':'X05','01Q3qAp6':'X03','01M1k6F6':'VIS'}
while True:
  j=t.find('{"id":"session_',i)
  if j<0: break
  try: s,e=dec.raw_decode(t[j:]); i=j+e
  except Exception: i=j+10; continue
  k=[v for p,v in ids.items() if s['id'][8:].startswith(p)]
  if not k: continue
  pts=s.get('post_turn_summary') or {}
  print(k[0], s.get('session_status','')[15:], s.get('updated_at','')[11:16], '|', pts.get('status_detail',''), '|', s.get('task_summary',''))
