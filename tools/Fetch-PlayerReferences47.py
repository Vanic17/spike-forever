"""Cache official portraits for visual review; no identity/ancestry inference."""
import json,re,html,urllib.request,concurrent.futures,unicodedata
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'.runtime/players47'; OUT.mkdir(parents=True,exist_ok=True)
clubs=json.loads((ROOT/'docs/kits45-reference-sources.json').read_text())
pages={r['club']:r['page'] for r in clubs}
def download(url):
    return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=40).read()
def fetch(item):
    club,url=item; page=download(url).decode('utf-8',errors='replace'); rows=[]
    (OUT/f'{club}.html').write_text(page,encoding='utf-8')
    for tr in re.findall(r'<tr\b.*?</tr>',page,re.S|re.I):
        photo=re.search(r'(?:src|data-src)=[\"\']([^\"\']*Foto\.aspx[^\"\']*)',tr,re.I)
        if not photo: continue
        links=re.findall(r'<a[^>]+href=[\"\']([^\"\']+)[\"\'][^>]*>(.*?)</a>',tr,re.S|re.I)
        player=next(((u,html.unescape(re.sub('<.*?>','',name)).strip()) for u,name in links if '/player/' in u.lower()),None)
        if not player: continue
        image_url=html.unescape(photo[1]); image_url=urllib.request.urljoin(url,image_url)
        image_url=re.sub(r'heightImg=\d+','heightImg=350',image_url)
        key=re.search(r'Key=([^&]+)',image_url).group(1)
        target=OUT/f'{club}-{key}.jpg'
        if not target.exists(): target.write_bytes(download(image_url))
        rows.append({'club':club,'name':player[1],'page':urllib.request.urljoin(url,player[0]),'team_page':url,'photo':image_url,'file':target.name})
    print(club,len(rows),flush=True)
    return rows
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    groups=list(pool.map(fetch,pages.items()))
rows=[r for group in groups for r in group]
(OUT/'references.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False),encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
for group in groups:
    if not group: continue
    sheet=Image.new('RGB',(800,((len(group)+4)//5)*225),(230,234,240)); draw=ImageDraw.Draw(sheet)
    for i,r in enumerate(group):
        x=(i%5)*160;y=(i//5)*225
        im=Image.open(OUT/r['file']).convert('RGB'); im.thumbnail((156,192))
        sheet.paste(im,(x+(160-im.width)//2,y))
        draw.text((x+2,y+194),r['name'][:20],font=font,fill='black')
        draw.text((x+2,y+210),str(i),font=font,fill='black')
    sheet.save(OUT/(group[0]['club']+'-sheet.jpg'))
print('PORTRAITS',len(rows))
