"""Download the unmodified complete uniforms exposed by the official league."""
import hashlib,json,urllib.request,concurrent.futures
from pathlib import Path
root=Path(__file__).resolve().parents[1]
clubs={'allianz-milano':6858,'cisterna-volley':6859,'cucine-lube-civitanova':6860,'acqua-santanna-cuneo':6863,'gas-sales-bluenergy-piacenza':6861,'itas-trentino':6862,'pallavolo-padova':6866,'rana-verona':6864,'sir-susa-scai-perugia':6865,'tinet-prata-di-pordenone':6897,'valsa-group-modena':6867,'vero-volley-monza':6868}
out=root/'assets/art/kits45/reference/official'; out.mkdir(parents=True,exist_ok=True)
def fetch(item):
    club,key,nr=item; url=f'https://ww2.legavolley.it/GetDivisaWP.aspx?Key={key}&nr={nr}'
    request=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})
    data=urllib.request.urlopen(request,timeout=30).read()
    target=out/f'{club}-{nr}.jpg'; target.write_bytes(data)
    return {'club':club,'page':f'https://www.legavolley.it/team/{key}','url':url,'reference_order':nr,'path':target.relative_to(root).as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    rows=list(pool.map(fetch,[(club,key,nr) for club,key in clubs.items() for nr in [1,2]]))
(root/'docs/kits45-reference-sources.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(f'Official complete uniform references: {len(rows)}')
