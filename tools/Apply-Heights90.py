"""One-time, height-only database migration, with an immutable field audit."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parent.parent
path=root/'assets/gameplay/league.json'
before=json.loads(path.read_text(encoding='utf-8-sig'))
report=json.loads((root/'.runtime/heights90/evidence.json').read_text(encoding='utf8'))
assert report['complete'] and len(report['players'])==169
evidence={p['id']:p for p in report['players']}
after=copy.deepcopy(before);catalog={}
for team in after['teams']:
    for player in team['roster']:
        record=evidence[player['id']];source=record['evidence']
        assert 150<=source['height_cm']<=230
        player['height_cm']=source['height_cm'];catalog[player['id']]=source['height_cm']
        player['height_metadata']={'source_url':source['source_url'],'player_url':source['player_url'],'checked_at':report['checked_at'],'source_sha256':source['page_sha256']}
audit=copy.deepcopy(after)
for team in audit['teams']:
    for p in team['roster']:
        p.pop('height_cm');p.pop('height_metadata')
baseline=copy.deepcopy(before)
for team in baseline['teams']:
    for p in team['roster']:
        p.pop('height_cm',None);p.pop('height_metadata',None)
assert audit==baseline,'Unrelated database change'
path.write_text(json.dumps(after,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(root/'assets/gameplay/player_heights90.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf8')
(root/'docs/player-heights90-sources.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('HEIGHTS: 169 verified; all other database fields unchanged; range',min(catalog.values()),max(catalog.values()))
