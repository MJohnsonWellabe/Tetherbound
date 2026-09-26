import json,os,re,urllib.request,subprocess
H={'Authorization':'Bearer '+os.environ['GITHUB_TOKEN']}
def get(u): return json.load(urllib.request.urlopen(urllib.request.Request(u,headers=H),timeout=30))
R='https://api.github.com/repos/MJohnsonWellabe/Tetherbound'
prs=[p['number'] for p in get(R+'/pulls?state=all&sort=updated&direction=desc&per_page=40') if p['head']['ref'].startswith('ralph/')]+[221,226]
pat=re.compile(r'READY FOR INTEGRATION[:\s*]*`?(ralph/[\w./-]+)`?\s*@?\s*`?([0-9a-f]{7,40})')
seen={}
for n in prs:
  for c in get(R+f'/issues/{n}/comments?since=2026-09-25T12:00:00Z&per_page=100'):
    for m in pat.finditer(c['body']): seen[m.group(1)]=(m.group(2),c['created_at'])
for b,(s,t) in sorted(seen.items(),key=lambda x:x[1][1]):
  ok=subprocess.run(['git','cat-file','-e',s]).returncode==0
  on=ok and subprocess.run(['git','merge-base','--is-ancestor',s,'origin/main']).returncode==0
  if not on: print('PENDING' if ok else 'MISSING',t[11:16],b,s)

# READY lines that name a branch but no SHA: report so they are not missed.
loose=re.compile(r'READY FOR INTEGRATION[:\s*]*`?(ralph/[\w./-]+)(?![\w./-])`?(?![\s@`]*[0-9a-f]{7,40})')
for n in prs:
  for c in get(R+f'/issues/{n}/comments?since=2026-09-25T12:00:00Z&per_page=100'):
    for m in loose.finditer(c['body']):
      b=m.group(1)
      if b not in seen:
        subprocess.run(['git','fetch','-q','origin',b])
        on=subprocess.run(['git','merge-base','--is-ancestor','origin/'+b,'origin/main']).returncode==0
        if not on: print('NOSHA',c['created_at'][11:16],b,'head of origin/'+b)
