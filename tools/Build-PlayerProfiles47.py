"""Approximate hair/beard/visible skin shades reviewed against official photos.
No faces, facial landmarks, ancestry or gameplay attributes are inferred.
Order is the official portrait contact sheet; persisted mapping uses player ID.
"""
import json,re,unicodedata
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
refs=json.loads((ROOT/'.runtime/players47/references.json').read_text(encoding='utf-8'))
# style / color / beard / shade; blanks use short brown hair, no beard, light.
review={
'allianz-milano': ['sfumati n - o','mossi c','corti n p o','frangia m','ricci m','mossi m','frangia n','?','corti c','pelato n p e','rasati n c o','riga n','ricci m','mossi n','sfumati m c'],
'cisterna-volley':['rasati m c','mossi m','riga m','riga n - o','ricci m c','rasati m','rasati m p o','mossi n','ricci m c','treccine n - e','rasati m','corti m','corti n','mossi m c'],
'cucine-lube-civitanova':['riga n','ricci m c','riga m c','sfumati m','sfumati m c','sfumati m','mossi m c','corti n c','riga n','pelato m','mossi c c','rasati c','corti m','ricci n c'],
'acqua-santanna-cuneo':['corti n','rasati m p o','frangia m c','ricci n - o','rasati m','riga m','ricci n','afro n c a','frangia n c o','corti n p o','mossi m','riga m c','frangia m','corti m'],
'gas-sales-bluenergy-piacenza':['rasati n - s','mossi c','riga m','rasati n - e','frangia n','riga c','sfumati m c','pelato m c','ricci m','rasati m p','frangia n','afro n - s','ricci n c s','ricci m'],
'itas-trentino':['sfumati n','frangia m','riga n c o','pelato m p','corti c','mossi m','rasati m','frangia n c','mossi n p o','lunghi m','rasati n c s','mossi n p o','corti n','mossi c c'],
'pallavolo-padova':['mossi n p o','mossi m','corti m','corti m','sfumati m c o','ricci c','sfumati n c','frangia m','sfumati n','sfumati c c','frangia m','riga n p o','mossi c c','mossi m'],
'rana-verona':['pelato m p','rasati m c','corti n','ricci n - o','sfumati n c o','ricci m','afro n p e','corti n - o','corti n','riga m p','sfumati b','riga m c','rasati c','sfumati m p'],
'sir-susa-scai-perugia':['sfumati m c','rasati n c o','mossi c c','ricci n','frangia n','frangia m','rasati n c o','mossi c c','corti m','corti c','sfumati n','pelato n p o','riga n p o','rasati n c o'],
'tinet-prata-di-pordenone':['corti b','riga n c o','sfumati n - o','ricci c','ricci n c','corti m c o','lunghi n c','rasati c c','sfumati n p','mossi c','sfumati c c','?','ricci c','ricci m p','corti n c o'],
'valsa-group-modena':['ricci n c o','rasati n','ricci m p','ricci m','mossi c c','rasati n','frangia n','sfumati n','sfumati n','mossi m','frangia m','rasati m p','rasati n','riga n'],
'vero-volley-monza':['riga c','riga n','corti n','ricci c','ricci n','rasati m p o','ricci c','rasati m p','rasati n - e','lunghi n p o','frangia m','corti m c','frangia c','rasati n']}
colors={'n':'nero','m':'marrone','c':'castano chiaro','b':'biondo'}
beards={'-':'nessuna','c':'corta','p':'piena'}
shades={'l':'chiara','o':'olivastra','a':'ambrata','s':'scura','e':'ebano'}
def key(name):
    name=unicodedata.normalize('NFKD',name).encode('ascii','ignore').decode().lower()
    return tuple(sorted(re.findall(r'[a-z]+',name)))
lookup={}; source_rows=[]
for club,tags in review.items():
    group=[r for r in refs if r['club']==club]; assert len(group)==len(tags),(club,len(group),len(tags))
    for r,tag in zip(group,tags):
        if tag=='?': continue
        parts=tag.split(); style=parts[0]; color=colors[parts[1]] if len(parts)>1 else 'marrone'
        appearance={'hair_style':style,'hair_length':'pelato' if style=='pelato' else ('lunghi' if style in ['lunghi','treccine'] else 'corti'),'hair_color':color,'beard':beards[parts[2]] if len(parts)>2 else 'nessuna','skin_tone':shades[parts[3]] if len(parts)>3 else 'chiara','status':'approximate_visual_review_official_portrait','photo_source_url':r['page']}
        lookup[(club,key(r['name']))]=(appearance,r)
db_path=ROOT/'assets/gameplay/league.json'; db=json.loads(db_path.read_text(encoding='utf-8'))
missing=[]
for team in db['teams']:
    for player in team['roster']:
        entry=lookup.get((team['id'],key(player['name'])))
        if not entry: missing.append({'id':player['id'],'name':player['name'],'reason':'no matched usable official portrait'}); continue
        appearance,r=entry; player['appearance'].update(appearance)
        source_rows.append({'id':player['id'],'name':player['name'],'team':team['id'],'page':r['page'],'photo':r['photo'],'appearance':appearance})
db_path.write_text(json.dumps(db,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(ROOT/'docs/appearance47-sources.json').write_text(json.dumps({'method':'manual approximate visible hairstyle/beard/skin-shade review; no facial identity reconstruction','players':source_rows,'unverified':missing},indent=2,ensure_ascii=False),encoding='utf-8')
print('PROFILE47',len(source_rows),'reviewed; unmatched',missing)
