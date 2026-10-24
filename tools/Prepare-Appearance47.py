from pathlib import Path
import shutil,json
from PIL import Image
root=Path(__file__).resolve().parents[1]
source=root/'assets/appearance47_source'; out=root/'assets/art/appearance47'; out.mkdir(parents=True,exist_ok=True)
rows={}
for file in source.rglob('*'):
    if file.suffix.lower() in ['.psk','.png']: shutil.copy2(file,out/file.name)
    if file.suffix=='.mat':
        entries={}
        for line in file.read_text().splitlines():
            if '=' in line:
                k,v=line.split('=',1); entries[k]=v+'.png'
        # UE hair uses separate opacity, not the exported glitter diffuse.
        # Pack that original mask into alpha for Godot's cutout material.
        mask=entries.get('Opacity')
        if not mask and file.stem in ['MAS_Char_Hair02','M_Char_Hair02_Black']: mask='HairClump02_Alpha.png'
        if not mask and file.stem=='M_Hair_V2_Brown': mask='Hairtest_Mask.png'
        if mask:
            alpha=Image.open(out/mask) if (out/mask).exists() else Image.open(next(source.rglob(mask)))
            alpha=alpha.getchannel('A') if alpha.mode=='RGBA' and alpha.getchannel('A').getextrema()!=(255,255) else alpha.convert('L')
            rgba=Image.new('RGBA',alpha.size,(255,255,255,255)); rgba.putalpha(alpha)
            packed=file.stem+'-cutout47.png'; rgba.save(out/packed); entries['Diffuse']=packed
        rows[file.stem]=entries
(out/'materials.json').write_text(json.dumps(rows,indent=2))
print('Prepared',len(list(out.glob('*.psk'))),'meshes',len(list(out.glob('*.png'))),'textures')
