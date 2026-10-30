from pathlib import Path
import json,math
path=Path('assets/gameplay/league.json')
data=json.loads(path.read_text(encoding='utf-8-sig'))
keys=['battuta','ricezione','difesa','palleggio','schiacciata','muro']
weights={'setter':[15,5,10,45,5,20],'opposite':[20,5,10,5,40,20],'outside_hitter':[15,20,15,5,30,15],'middle_blocker':[15,5,5,5,35,35],'libero':[0,45,45,10,0,0]}
report=[]
for team in data['teams']:
    for p in team['roster']:
        old=p['ratings']['generale']
        ovr=math.floor(sum(max(0,min(99,p['ratings'].get(k,50)))*w for k,w in zip(keys,weights[p['role']]))/100+.5)
        p['ratings']['generale']=ovr
        report.append({'id':p['id'],'team':team['id'],'role':p['role'],'before':old,'after':ovr})
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
Path('docs/overall67-database.json').write_text(json.dumps({'formula':'round(sum(skill * role_weight) / 100)','keys':keys,'weights':weights,'players':report},ensure_ascii=False,indent=2),encoding='utf-8')
print('OVERALL67 base database updated:',len(report),'players')
