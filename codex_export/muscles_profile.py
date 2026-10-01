from PIL import Image, ImageDraw
from pathlib import Path
import json
W,H=281,760
out=Path('streetlift_tracker/assets/muscles')
# profile-left neutral figure, matched to original grayscale/ink language.
regions={
 'epaules':[(123,137),(151,128),(170,143),(166,184),(145,205),(125,183)],
 'pectoraux':[(105,167),(137,153),(148,190),(135,225),(106,231),(91,211)],
 'dos':[(151,158),(174,158),(181,240),(164,311),(143,279),(144,205)],
 'biceps':[(97,220),(122,218),(126,286),(111,310),(94,279)],
 'triceps':[(125,211),(146,206),(148,278),(132,309),(119,279)],
 'avant_bras':[(100,294),(124,292),(119,390),(102,420),(91,393)],
 'gainage':[(111,235),(144,229),(158,320),(146,375),(113,365),(103,294)],
 'fessiers':[(143,319),(178,320),(188,366),(176,402),(144,391),(131,356)],
 'quadriceps':[(117,370),(151,369),(153,500),(132,541),(109,501)],
 'ischios':[(151,384),(177,391),(174,506),(153,548),(139,494)],
 'mollets':[(126,528),(164,527),(169,649),(151,691),(126,644)],
}
# Full silhouette pieces including head/neck/hand/foot.
sil=[(105,46),(139,37),(165,50),(173,78),(164,115),(148,137),(172,157),(181,237),(166,319),(184,338),(188,374),(175,405),(174,503),(168,527),(169,648),(164,698),(190,714),(192,731),(180,739),(109,739),(101,730),(107,715),(126,700),(121,650),(109,532),(103,504),(103,390),(88,414),(79,407),(87,385),(89,293),(91,231),(84,211),(87,180),(105,153),(123,135),(108,113),(99,79)]
base=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(base)
# soft modeled body fill
d.polygon(sil,fill=(121,121,121,255),outline=(43,43,43,255),width=3)
for name,p in regions.items():
 d.polygon(p,fill=(178,178,178,255),outline=(58,58,58,255),width=2)
# head/neck anatomical marks
d.ellipse((101,42,173,137),fill=(75,75,75,255),outline=(42,42,42,255),width=3)
d.polygon([(125,128),(148,117),(157,153),(126,155)],fill=(158,158,158,255),outline=(55,55,55,255),width=2)
# subtle highlights overlay clipped approximately per region
for p in regions.values():
 q=[(x-3,y-4) for x,y in p[:max(3,len(p)//2)]]
# save base
base.save(out/'profile_base.png',optimize=True)
# grayscale masks preserve same modeled fill and outlines, transparent elsewhere
for name,p in regions.items():
 im=Image.new('RGBA',(W,H),(0,0,0,0)); md=ImageDraw.Draw(im)
 md.polygon(p,fill=(205,205,205,255),outline=(72,72,72,255),width=2)
 # add a restrained inner highlight matching old shaded plates
 cx=sum(x for x,y in p)/len(p); cy=sum(y for x,y in p)/len(p)
 inner=[(int(cx+(x-cx)*.72),int(cy+(y-cy)*.72)) for x,y in p]
 md.polygon(inner,fill=(232,232,232,90))
 im.save(out/f'profile_{name}.png',optimize=True)
meta=json.loads((out/'meta.json').read_text())
meta['profile']={'w':W,'h':H}
(out/'meta.json').write_text(json.dumps(meta,ensure_ascii=False,sort_keys=True)+'\n')
