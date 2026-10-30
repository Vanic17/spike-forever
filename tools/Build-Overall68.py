"""Refresh derived OVR only, using the gameplay module as the weight source."""
from pathlib import Path
import json, math, re
root=Path(__file__).resolve().parents[1]
source=(root/'src/player_overall.gd').read_text(encoding='utf-8-sig')
weights={role:[int(n) for n in values.split(',')] for role,values in re.findall(r'"(setter|opposite|outside_hitter|middle_blocker|libero)":\[([\d,]+)\]',source)}
assert len(weights)==5 and all(sum(w)==100 for w in weights.values())
keys=['battuta','ricezione','difesa','palleggio','schiacciata','muro']
path=root/'assets/gameplay/league.json'
data=json.loads(path.read_text(encoding='utf-8-sig'))
report=[]
for team in data['teams']:
    for player in team['roster']:
        old=player['ratings']['generale']
        value=math.floor(sum(max(0,min(99,player['ratings'].get(k,50)))*w for k,w in zip(keys,weights[player['role']]))/100+.5)
        player['ratings']['generale']=value
        report.append({'id':player['id'],'role':player['role'],'before':old,'after':value})
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(root/'docs/patch68-overall-database.json').write_text(json.dumps({'formula':'round(sum(skill * role_weight) / 100)','keys':keys,'weights':weights,'players':report},indent=2),encoding='utf-8')
print('OVERALL68:',len(report),'players; only derived overall changed')
