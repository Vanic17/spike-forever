"""Mechanical rasterization/layout of original marks; no generated logos.
Original files and source hashes are retained alongside the game textures.
"""
from pathlib import Path
import hashlib, io, json, math, re, xml.etree.ElementTree as ET
import pymupdf as fitz
from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/art/arenas70'; (OUT/'marks').mkdir(parents=True,exist_ok=True)
sources=json.loads((OUT/'sources.json').read_text(encoding='utf8'))
artwork={}
for key,row in sources.items():
 if 'error' in row: raise RuntimeError((key,row))
 path=ROOT/row['original']; raw=path.read_bytes()
 if raw.lstrip().startswith(b'<'):
  # MuPDF's SVG reader does not implement CSS classes. Materialize those exact
  # source declarations before rasterization, retaining the official colours.
  svg=raw.decode('utf8'); classes={}
  for block in re.findall(r'<style[^>]*>(.*?)</style>',svg,re.S):
   for name,style in re.findall(r'\.([\w-]+)\s*\{([^}]+)\}',block):classes[name]=style.strip()
  if classes:
   ET.register_namespace('','http://www.w3.org/2000/svg');tree=ET.fromstring(raw)
   for el in tree.iter():
    styles=';'.join(classes.get(c,'') for c in el.get('class','').split())
    if styles:el.set('style',styles+';'+el.get('style',''))
   raw=ET.tostring(tree,encoding='utf8')
  doc=fitz.open(stream=raw,filetype='svg'); page=doc[0]
  pix=page.get_pixmap(matrix=fitz.Matrix(2048/max(page.rect.width,page.rect.height),2048/max(page.rect.width,page.rect.height)),alpha=True)
  image=Image.frombytes('RGBA',(pix.width,pix.height),pix.samples)
 else: image=Image.open(io.BytesIO(raw)).convert('RGBA')
 # Remove only uniform document margins. White ink is preserved on dark cards.
 bg='#ffffff'
 flat=Image.new('RGBA',image.size,bg);flat.alpha_composite(image)
 diff=ImageChops.difference(flat.convert('RGB'),Image.new('RGB',image.size,bg)).convert('L').point(lambda v:255 if v>24 else 0)
 bounds=diff.getbbox()
 if not bounds:
  bg='#142b4a';flat=Image.new('RGBA',image.size,bg);flat.alpha_composite(image)
  diff=ImageChops.difference(flat.convert('RGB'),Image.new('RGB',image.size,bg)).convert('L').point(lambda v:255 if v>24 else 0)
  bounds=diff.getbbox()
 if bounds: image=flat.crop(bounds)
 else: raise RuntimeError('Invisible mark: '+key)
 # A uniform 2:1 sponsor card means the same source is legible on floor and LEDs.
 # Raster originals are not enlarged; vector originals are rendered at 2048 px.
 w,h=image.size
 canvas_w=max(w,round(h*2)); canvas_h=round(canvas_w/2)
 canvas=Image.new('RGB',(canvas_w,canvas_h),bg)
 image.thumbnail((round(canvas_w*.90),round(canvas_h*.84)),Image.Resampling.LANCZOS)
 canvas.paste(image.convert('RGB'),((canvas_w-image.width)//2,(canvas_h-image.height)//2))
 if canvas.width>2048:canvas=canvas.resize((2048,1024),Image.Resampling.LANCZOS)
 target=OUT/'marks'/(key+'.png');canvas.save(target,optimize=True)
 artwork[key]={'path':target.relative_to(ROOT).as_posix(),'width':canvas.width,'height':canvas.height,'background':bg,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source':row['url']}

# Colours are calibrated approximations from the supplied broadcasts, not sampled
# white balance/exposure artifacts. Geometry remains the regulation 9 x 18 m.
rows=[
 ('allianz-milano','milano.png','174a99','baa887','b8a381',['allianz','joma']),
 ('cisterna-volley','cisterna 2.png','075596','bda37d','bba17a',['conit','gesa','marini','mizuno']),
 ('cucine-lube-civitanova','civitanova.png','235bb4','b7a79c','b2a398',['lube','joma']),
 ('acqua-santanna-cuneo','cuneo.png','075c9f','b6ac92','b2a68e',['santanna','banca-alpi','macron']),
 ('gas-sales-bluenergy-piacenza','piacenza.jpeg','218bad','b76c51','bd7959',['gas-sales','bluenergy','macron']),
 ('itas-trentino','trentino.png','2765aa','b79688','b28c80',['itas','trentino','errea']),
 ('pallavolo-padova','padova1.png','07509a','baaa84','b2a17b',['kioene','joma']),
 ('rana-verona','verona.png','075795','b9a479','b5a378',['rana','airone','joma']),
 ('sir-susa-scai-perugia','perugia.jpg','29868b','29864b','c9c5b5',['sir','susa','vim','suntory','joma']),
 ('tinet-prata-di-pordenone','prata.png','155ba9','b2a481','aea080',['tinet','joma']),
 ('valsa-group-modena','modena.png','195491','b29c78','b9a27d',['valsa','bper','daken','errea']),
 ('vero-volley-monza','monza.png','215caa','b1a28a','b5a58d',['homcom','bcc-carate','freddy']),
]
clubs={}
for club,ref,free,court,attack,sponsors in rows:
 floor=[]
 def pair(mark,x,z,width,height):
  for side in [-1,1]:floor.append({'mark':mark,'x':x,'z':round(z*side,3),'width':width,'height':height,'yaw':90})
 # Centre stamps and near-side free-zone rectangles follow broadcast placement.
 primary=sponsors[0]
 pair(primary,0,1.55,2.65,1.325)
 secondary=sponsors[1] if sponsors[1] not in ['joma','errea','macron','freddy'] else primary
 pair(secondary,6.65,5.8,3.25,1.625)
 pair(primary,0,10.3,3.8,1.9)
 pair(sponsors[-1],-6.5,6,2.5,1.25)
 if len(sponsors)>3:pair(sponsors[2],-6.5,10.5,2.6,1.3)
 clubs[club]={'reference':ref,'free_zone':'#'+free,'court':'#'+court,'attack_zone':'#'+attack,'sponsors':sponsors,'floor':floor}
 if club=='sir-susa-scai-perugia':clubs[club]['second_half']='#a33e54'
manifest={'home_selection':'exhibition left; online host; career fixture.home','universal_floor':['Credem Banca','Del Monte'],'artwork':artwork,'clubs':clubs}
(OUT/'profiles.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
sheet=Image.new('RGB',(1200,math.ceil(len(artwork)/4)*180),'#283447');draw=ImageDraw.Draw(sheet)
for i,(key,row) in enumerate(artwork.items()):
 im=Image.open(ROOT/row['path']);im.thumbnail((290,145));x=i%4*300;y=i//4*180
 sheet.paste(im,(x,y+22));draw.text((x+5,y+4),key,fill='white')
sheet.save(ROOT/'.runtime/stadi70/marks.jpg')
print('ARENA70 ART:',len(clubs),'profiles;',len(artwork),'original sponsor marks')
