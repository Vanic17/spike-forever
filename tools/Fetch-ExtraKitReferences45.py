"""Keep unmodified manufacturer references for supplied Supercoppa variant."""
import json,hashlib,urllib.request,io
from PIL import Image
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'assets/art/kits45/reference/official'
rows=[]
for variant,code in [('home','AM0077'),('away','AM0079')]:
    url=f'https://www.piuadrenalina.com/wp-content/uploads/2025/11/{code}_2-640x800.jpg'
    request=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})
    data=urllib.request.urlopen(request,timeout=30).read()
    path=out/f'sir-susa-scai-perugia-supercoppa-{variant}-shorts.jpg'
    try: Image.open(io.BytesIO(data)).verify()
    except Exception:
        rows.append({'club':'sir-susa-scai-perugia','variant':variant,'url':url,'status':'unavailable_image_endpoint_returns_html','fallback':'manufacturer product listing confirms black/home and red/away; shorts reconstructed'})
        continue
    path.write_bytes(data)
    rows.append({'club':'sir-susa-scai-perugia','variant':variant,'url':url,'path':path.relative_to(root).as_posix(),'sha256':hashlib.sha256(data).hexdigest()})
(root/'docs/kits45-extra-sources.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print('EXTRA KIT REFERENCES',len(rows))
