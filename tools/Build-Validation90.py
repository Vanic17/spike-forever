from pathlib import Path
import json
root=Path(__file__).resolve().parent.parent
baseline=root/'dist/source-0.89.0-04691aee2ff043d4acf39c8494a02a28'
allowed={'avatar.gd','character_quality89.gd','club_menu.gd','online_session.gd','pilot_quality89.gd','player_card.gd','player_stature90.gd','player_wear90.gd','render_smoother84.gd','sideline_animation.gd','view_controls.gd'}
changed=[]
for p in (root/'src').glob('*'):
    if p.suffix not in ['.gd','.gdshader']:continue
    old=baseline/'src'/p.name
    if not old.exists() or old.read_bytes()!=p.read_bytes():changed.append(p.name)
assert set(changed)==allowed,changed
assert (root/'src/main.gd').read_bytes()==(baseline/'src/main.gd').read_bytes()
a=json.loads((baseline/'assets/gameplay/league.json').read_text(encoding='utf-8-sig'))
b=json.loads((root/'assets/gameplay/league.json').read_text(encoding='utf-8-sig'))
for t in b['teams']:
    for p in t['roster']:p.pop('height_cm');p.pop('height_metadata')
assert a==b
evidence=json.loads((root/'docs/player-heights90-sources.json').read_text(encoding='utf8'))
assert evidence['complete'] and len(evidence['players'])==169
checks=json.loads((root/'docs/stature90-validation.json').read_text(encoding='utf8'));assert checks['pass']
presets=json.loads((root/'docs/stature90-presets.json').read_text(encoding='utf8'));assert presets['pass']
suites=[]
for p in sorted((root/'.runtime').glob('*-graphics90-current.stdout.log')):
    data=p.read_text(encoding='utf-8-sig',errors='replace')
    assert 'PASS' in data,p.name
    errors=p.with_name(p.name.replace('stdout','stderr')).read_text(encoding='utf-8-sig',errors='replace')
    assert not any(x in errors for x in ['SCRIPT ERROR','Parse Error','Assertion failed','SHADER ERROR']),p.name
    suites.append(p.name.split('-graphics90-current')[0])
assert len(suites)==21,len(suites)
for case in ['database','contacts']:
    for peer in ['host','guest']:
        data=(root/'.runtime'/f'stature90-online-{case}-{peer}.stdout.log').read_text(encoding='utf-8-sig',errors='replace')
        assert 'PASS' in data
soak=json.loads((root/'docs/stature90-full-match.json').read_text(encoding='utf8'));assert soak['pass']
report={'pass':True,'version':'0.90.0','height_sources':169,'source':'Official Lega Volley roster heights','height_only_database_migration':True,'main_gameplay_source_unchanged':True,'changed_source_files':sorted(changed),'equipment_contacts_and_controller':checks,'graphics_presets':presets['checks'],'regression_suites':suites,'actual_enet_pairs':['separate host/guest database heights','physical contacts and disguised sets'],'full_set':{'points':soak['points'],'contacts':soak['contacts'],'seconds':soak['real_seconds']},'limits':['Local ENet clients, not a real WAN latency survey','Uniform proportional stature, not 169 new anatomical meshes','One full-set rendered soak and isolated graphics samples, not every PC configuration']}
(root/'docs/stature90-audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report))
