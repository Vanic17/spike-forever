"""Apply verified dominant-hand facts only; archive all other DB fields verbatim."""
import json,pathlib,unicodedata,difflib,hashlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
def norm(s):return ''.join(c for c in unicodedata.normalize('NFKD',s.lower()) if c.isascii() and c.isalnum())
def main():
 path=ROOT/'assets/gameplay/league.json';backup=ROOT/'.runtime/review103/league-before.json';before=backup.read_bytes() if backup.exists() else path.read_bytes();db=json.loads(before.decode('utf-8-sig'))
 research=json.loads((ROOT/'docs/review103-hands-research.json').read_text(encoding='utf8'))
 aliases={'Henri Emmanuel Leon':'Henri Léon','Jose Miguel Gutierrez':'José Miguel Gutiérrez Suárez','Simon Valentin Torwie':'Simon Torwie','Adriano Xavier Cavalcante':'Adriano Xavier','Anders Mol':'Anders Berntsen Mol'}
 facts={};pending=[];used=set()
 for team in db['teams']:
  for p in team['roster']:
   name=aliases.get(p['name'],p['name'])
   ranked=sorted(research,key=lambda r:difflib.SequenceMatcher(None,norm(name),norm(r['name'])).ratio(),reverse=True)
   r=ranked[0];score=difflib.SequenceMatcher(None,norm(name),norm(r['name'])).ratio()
   if score<.75:pending.append(p['name']);continue
   assert r['url'] not in used,(p['name'],r);used.add(r['url'])
   if r['hand']:
    facts[p['id']]={'name':p['name'],'dominant_hand':r['hand'].lower(),'source':r['url']}
   else:pending.append(p['name'])
 print('Verified',len(facts),'unresolved',len(pending));print('Unresolved:',pending)
 # This manifest is consumed ONCE by the game; it contains no other writable fields.
 delta={'id':'dominant-hand-103-once','schema':1,'players':facts}
 (ROOT/'assets/gameplay/dominant_hand103.json').write_text(json.dumps(delta,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 # Only insert the authorized field, keeping the original JSON representation elsewhere.
 import re
 text=before.decode('utf-8-sig')
 for pid,fact in facts.items():
  pattern=r'("id": "'+re.escape(pid)+r'",\r?\n)'
  text,count=re.subn(pattern,lambda m:m[1]+'          "dominant_hand": "'+fact['dominant_hand']+'",\n',text,count=1)
  assert count==1,pid
 after=json.loads(text)
 for t0,t1 in zip(db['teams'],after['teams']):
  for p0,p1 in zip(t0['roster'],t1['roster']):
   if p0['id'] in facts:p1.pop('dominant_hand',None)
   assert p0==p1
 if not backup.exists():backup.write_bytes(before)
 path.write_text(text,encoding='utf8',newline='')
 (ROOT/'docs/review103-hands-summary.json').write_text(json.dumps({'reviewed':169,'verified':len(facts),'unresolved':pending,'left':[x['name'] for x in facts.values() if x['dominant_hand']=='left'],'before_sha256':hashlib.sha256(before).hexdigest(),'only_modified_field':'dominant_hand'},ensure_ascii=False,indent=2),encoding='utf8')
if __name__=='__main__':main()
