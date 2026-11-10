from pathlib import Path
import json,hashlib,zipfile
root=Path(__file__).resolve().parent.parent
with zipfile.ZipFile(root/'dist/v0.98.0-attack104/SpikeForever-Windows.zip') as z:
    for name in ['assets/gameplay/league.json','controls.cfg','src/timing.gd','src/ball_flight.gd','src/block_response.gd','src/attack_reference78.gd','src/attack_reference_right78.gd','src/attack_middle_style80.gd','src/attack_middle_style_right80.gd']:
        assert (root/name).read_bytes()==z.read(name),name
    # Archive this run under the current patch, preserving the old reports.
    for name,dest in [('docs/attack104-after.json','docs/attack105-initial-live.json'),('docs/middle102-live.json','docs/attack105-middle-live.json')]:
        if not (root/dest).exists():
            (root/dest).write_bytes((root/name).read_bytes())
        (root/name).write_bytes(z.read(name))
profile=root/'.runtime/roaming/Godot/app_userdata/Spike Forever'
rows=json.loads((root/'.runtime/personal98-before.json').read_text(encoding='utf-8-sig'))
for entry in rows:
    file=profile/entry['path'].lstrip('\\/').replace('\\','/')
    assert hashlib.sha256(file.read_bytes()).hexdigest().upper()==entry['sha256'],str(file)
test=json.loads((root/'docs/attack105-tests.json').read_text(encoding='utf-8-sig'))
assert test['pass']
result={'pass':True,'personal_files_preserved':len(rows),'database_controls_timing_integrator_and_attack_authors_unchanged':True,'new_clip':'approach105','new_clip_source_reference':'https://www.youtube.com/watch?v=w6IevIgUfxY','checks':test['checks']}
(root/'docs/attack105-preservation.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result))
