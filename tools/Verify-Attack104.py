from pathlib import Path
import hashlib,json,zipfile
root=Path(__file__).resolve().parent.parent
previous=root/'dist/v0.97.0-review103/SpikeForever-Windows.zip'
with zipfile.ZipFile(previous) as z:
    for name in ['assets/gameplay/league.json','controls.cfg','src/ball_flight.gd','src/cpu_defense.gd','src/block_response.gd','src/timing.gd']:
        assert z.read(name)==(root/name).read_bytes(),name
    before=json.loads((root/'dist/source-0.97.0-ed49a076a91b4a168a44d881b344e81d/docs/attack104-before.json').read_text(encoding='utf-8-sig'))
after=json.loads((root/'docs/attack104-after.json').read_text(encoding='utf-8-sig'))
assert before['pass'] and after['pass'] and len(after['cases'])==24
rows=[]
for a,b in zip(after['cases'],before['cases']):
    assert (a['rotation'],a['direction'],a['hitter'])==(b['rotation'],b['direction'],b['hitter'])
    assert a['phase']=='CPU_RECEIVE'
    rows.append({'rotation':a['rotation'],'direction':a['direction'],'old_seconds':b['delivery']['seconds'],'seconds':a['delivery']['seconds'],'old_speed_m_s':b['speed'],'speed_m_s':a['speed'],'old_vertical_m_s':b['vertical'],'vertical_m_s':a['vertical'],'old_point':b['floor_point'],'point':a['floor_point']})
personal=root/'.runtime/roaming/Godot/app_userdata/Spike Forever'
saved=json.loads((root/'.runtime/personal98-before.json').read_text(encoding='utf-8-sig'))
for entry in saved:
    file=personal/entry['path'].lstrip('\\/').replace('\\','/')
    assert hashlib.sha256(file.read_bytes()).hexdigest().upper()==entry['sha256'],str(file)
report={'pass':True,'native_build_up_cases':24,'previous_version':'0.97.0','personal_existing_files_unchanged':len(saved),'database_controls_timing_ball_integrator_cpu_defense_block_response_byte_identical':True,'before_points':sum(x['floor_point'] for x in before['cases']),'after_points':sum(x['floor_point'] for x in after['cases']),'qualification':'Fixed seeded scenarios, not a general match win-rate estimate','comparison':rows}
(root/'docs/attack104-comparison.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='comparison'}))
