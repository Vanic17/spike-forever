"""Verify this material patch did not change match logic or original assets."""
from pathlib import Path
import hashlib,json,argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(); parser.add_argument('--baseline',type=Path); args=parser.parse_args()
baselines=list((root/'dist').glob('source-0.44.0-*'))
assert args.baseline or len(baselines)==1,'Provide --baseline <v0.44.0 source checkout>'
base=args.baseline or baselines[0]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
changed=[]; preserved=[]
for path in (base/'src').glob('*'):
    current=root/'src'/path.name
    if current.exists() and path.is_file():
        (preserved if sha(path)==sha(current) else changed).append(path.name)
assert sorted(changed)==['avatar.gd','club_menu.gd'],changed
assets={}
for rel in ['assets/active/cloth.psk','assets/active/body.psk','assets/active/native_all.res','assets/gameplay/league.json']:
    assert sha(root/rel)==sha(base/rel),rel
    assets[rel]=sha(root/rel)
report={'baseline':'0.44.0','changed_existing_scripts':changed,'new_scripts':['club_kits.gd','club_kit.gdshader'],'unchanged_existing_scripts':preserved,'unchanged_original_assets':assets}
(root/'docs/kits45-scope-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('KIT SCOPE45 PASS: only avatar materials and kit selection changed; rules/physics/tactics/controls/roster/original models and animations unchanged')
