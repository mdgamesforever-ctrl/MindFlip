"""Original vector-style raster assets, supersampled once and batched at runtime."""
from PIL import Image, ImageDraw
from pathlib import Path
import math
OUT=Path(__file__).resolve().parents[1]/'assets/visual';OUT.mkdir(parents=True,exist_ok=True)
# Three 128px cards in one atlas; subtle top light, anti-aliased contour.
S=4
atlas=Image.new('RGBA',(128*3*S,128*S))
for i,(fill,border) in enumerate([('#1d2d3c','#34495a'),('#213c40','#49766d'),('#101c29','#1b2b39')]):
 card=Image.new('RGBA',(128*S,128*S));mask=Image.new('L',card.size);d=ImageDraw.Draw(mask)
 d.rounded_rectangle((S,S,127*S,127*S),radius=19*S,fill=255)
 rgb=tuple(int(fill[j:j+2],16) for j in (1,3,5))
 q=ImageDraw.Draw(card)
 for y in range(128*S):
  add=int(3*(1-y/(128*S)));q.line((0,y,128*S,y),fill=tuple(min(255,c+add) for c in rgb)+(255,))
 card.putalpha(mask);q=ImageDraw.Draw(card);q.rounded_rectangle((S,S,127*S,127*S),radius=19*S,outline=border,width=S)
 atlas.alpha_composite(card,(i*128*S,0))
atlas.resize((384,128),Image.Resampling.LANCZOS).save(OUT/'tile_atlas.png')
# Background lighting baked once, eliminating large overlapping transparent draws.
bg=Image.new('RGB',(512,288));pix=bg.load()
for y in range(288):
 for x in range(512):
  t=y/287;glow=math.exp(-(((x-384)/155)**2+((y-92)/120)**2))*3
  pix[x,y]=(int(16*(1-t)+11*t),int(28*(1-t)+18*t+glow),int(44*(1-t)+32*t+glow))
bg.save(OUT/'background.png')
print('Generated original batched tile atlas and baked background gradient.')
