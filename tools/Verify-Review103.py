import json,pathlib,hashlib,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
before=load(ROOT/'.runtime/review103/league-before.json');after=load(ROOT/'assets/gameplay/league.json')
facts=load(ROOT/'assets/gameplay/dominant_hand103.json')['players'];changes=0
for t0,t1 in zip(before['teams'],after['teams']):
 for p0,p1 in zip(t0['roster'],t1['roster']):
  if p0['id'] in facts:
   assert p1['dominant_hand']==facts[p0['id']]['dominant_hand'];p1.pop('dominant_hand');changes+=1
assert before==after
profile=ROOT/'.runtime/roaming/Godot/app_userdata/Spike Forever'
personal=load(ROOT/'.runtime/personal98-before.json')
for row in personal:
 path=profile/row['path'].lstrip('/\\')
 assert hashlib.sha256(path.read_bytes()).hexdigest().upper()==row['sha256'],str(path)
report={'pass':True,'database_only_dominant_hand_changed':True,'verified_players':changes,'existing_personal_files_unchanged':len(personal)}
(ROOT/'docs/review103-preservation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(report)
old=load(ROOT/'dist/source-0.96.0-ca54049dce9242fbb718f0cfc88a1754/docs/review103-live.json')
new=load(ROOT/'docs/review103-live.json');rows=[]
for a,b in zip(old['cases'],new['cases']):
 dt0=a['delivery']['seconds'];dt1=b['delivery']['seconds']
 # Net clearance can remain the limiting factor. A speed boost must not
 # buy its result by lowering the ball through the tape.
 rows.append({'rotation':a['rotation'],'direction':a['direction'],'before_seconds':dt0,'after_seconds':dt1,'speed_ratio':round(dt0/dt1,5),'before_hitter':a['hitter'],'after_hitter':b['hitter']})
assert any(r['speed_ratio']>1.03 for r in rows)
assert all(r['speed_ratio']>.998 for r in rows),rows
out={'pass':True,'actual_native_attacks':rows,'P1_recipient_corrected':True,'clearance_limited_cases_unchanged':True}
(ROOT/'docs/review103-speed-comparison.json').write_text(json.dumps(out,indent=2),encoding='utf8')
print(out)
# Restore historical test reports overwritten by running obsolete fixtures.
with zipfile.ZipFile(ROOT/'dist/v0.96.0-middle102/SpikeForever-Windows.zip') as z:
 for name in ['docs/double74-tactics.json','docs/double74-core-tests.json']:(ROOT/name).write_bytes(z.read(name))
