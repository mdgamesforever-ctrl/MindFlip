"""Original Mosslight Reach art. Deterministic, integer-pixel source, no external assets."""
from PIL import Image, ImageDraw
import random, math, json
from pathlib import Path
R=random.Random(7341)
OUT=Path(__file__).resolve().parents[1]/'assets/generated'; OUT.mkdir(parents=True,exist_ok=True)
P={'ink':'#233a39','grass':'#537757','grass2':'#60825a','light':'#92a96a','dark':'#3a604c','earth':'#a28a64','sand':'#c2aa78','water':'#336c79','water2':'#438594','foam':'#9bbcb0','wood':'#75574a','wood2':'#aa8058','cream':'#e6d8af','gold':'#e9b768','roof':'#375e65'}
def save(im,name): im.save(OUT/(name+'.png'))
def poly(d,pts,c):d.polygon(pts,fill=c)
def ellipse(d,box,c):d.ellipse(box,fill=c)
def rect(d,box,c):d.rectangle(box,fill=c)
def river_x(y):return 1055+75*math.sin(y/180)+30*math.sin(y/69)
W,H=1600,1152
g=Image.new('RGBA',(W,H),P['grass']);d=ImageDraw.Draw(g)
# Subtle broad meadow hues, irregular islands of clover.
for i in range(420):
 x,y=R.randrange(W),R.randrange(H);w,h=R.randrange(12,55),R.randrange(5,20)
 ellipse(d,(x,y,x+w,y+h),R.choice(['#577c58','#597f59','#4e7354','#587957']))
paths=[[(100,1030),(290,930),(480,775),(650,680),(742,570),(750,450),(695,400),(670,370)],[(742,570),(860,584),(1030,600),(1210,600),(1360,470),(1480,350)],[(650,680),(535,550),(420,500),(290,370),(180,290)],[(1360,470),(1390,690),(1300,820),(1400,990)]]
for path in paths:
 d.line(path,fill='#435e46',width=55,joint='curve');d.line(path,fill='#8c7c59',width=49,joint='curve');d.line(path,fill=P['earth'],width=43,joint='curve')
 for x,y in path:ellipse(d,(x-21,y-21,x+21,y+21),P['earth'])
# Pixel wear across paths and meadow; texture never substitutes placement.
for i in range(26000):
 x,y=R.randrange(W),R.randrange(H); c=g.getpixel((x,y))[:3]
 if c==(162,138,100):
  rect(d,(x,y,x+R.randrange(1,4),y),R.choice(['#b0976b','#947e5c','#b8a174']))
 else:
  if R.random()<.65:
   d.line((x,y,x,y-2),fill=R.choice(['#66865d','#486d51','#6c8a60']))
   if R.random()<.35:d.point((x+1,y-3),fill='#7d985e')
# Stream has irregular stepped shore, bank ledges and animated overlay later.
left=[(int(river_x(y)-50),y) for y in range(0,H+12,6)];right=[(int(river_x(y)+50),y) for y in range(H,-12,-6)]
for widen,c in [(11,'#314e44'),(8,'#b4a076'),(4,'#758c72'),(0,P['water'])]:
 poly(d,[(x-widen,y) for x,y in left]+[(x+widen,y) for x,y in right],c)
for i in range(900):
 y=R.randrange(H); x=int(river_x(y)+R.randrange(-43,44));d.line((x,y,x+R.randrange(2,9),y),fill=R.choice(['#3c7887','#397381','#4a8590']))
# Crossing, hand laid planks and posts.
bx=int(river_x(600));rect(d,(bx-79,578,bx+80,631),'#233d3e');rect(d,(bx-75,580,bx+76,619),'#71594a')
for x in range(bx-74,bx+76,9):
 rect(d,(x,583,x+7,616),'#b18c61');d.line((x+1,585,x+1,614),fill='#cfab76');d.line((x+3,604,x+6,604),fill='#8a684d');d.point((x+2,587),fill='#485047');d.point((x+2,613),fill='#485047')
for y in (577,618):
 rect(d,(bx-82,y,bx+82,y+3),'#453f35');rect(d,(bx-82,y-2,bx+82,y),'#c3a476')
 for x in (bx-80,bx-25,bx+25,bx+78):rect(d,(x,y-7,x+4,y+9),'#665341');rect(d,(x,y-8,x+4,y-6),'#e1c58b')
# Flower beds in deliberately clustered clearings.
for cx,cy in [(750,705),(515,427),(1205,710),(285,655),(1410,318),(878,396),(348,1015)]:
 for i in range(55):
  x=int(R.gauss(cx,27));y=int(R.gauss(cy,18));d.line((x,y,x,y-4),fill='#345e47')
  col=R.choice(['#dec380','#cf9081','#aab5cd']);d.line((x-1,y-4,x+1,y-4),fill=col);d.point((x,y-5),fill=col);d.point((x,y-4),fill='#f3e0a3')
# Stepping stones and decorated overlook plaza.
for cx,cy in [(1340,948),(210,280)]:
 ellipse(d,(cx-48,cy-26,cx+48,cy+26),'#455d4e')
 for i in range(60):
  a=R.random()*math.tau;r=R.random()*45;x=int(cx+math.cos(a)*r);y=int(cy+math.sin(a)*r*.5)
  poly(d,[(x-5,y),(x-3,y-3),(x+4,y-2),(x+6,y+2),(x,y+4)],R.choice(['#949984','#7d8978','#adb098']))
save(g,'reach_ground')
# Sprite atlas, cell-separated props with foot anchors.
atlas=Image.new('RGBA',(1024,512));ad=ImageDraw.Draw(atlas);meta={};cx=cy=rowh=0

def add(name,im,anchor=None):
 global cx,cy,rowh
 w,h=im.size
 if cx+w+2>1024:cx=0;cy+=rowh+2;rowh=0
 atlas.alpha_composite(im,(cx,cy));meta[name]={'rect':[cx,cy,w,h],'anchor':anchor or [w/2,h-3]};cx+=w+2;rowh=max(rowh,h)
def tree(seed,autumn=False):
 r=random.Random(seed);im=Image.new('RGBA',(84,104));q=ImageDraw.Draw(im)
 ellipse(q,(12,83,79,101),'#2c4b3b70');poly(q,[(37,54),(48,52),(48,88),(57,96),(44,94),(32,98),(38,88)],'#334a3b');rect(q,(41,60,46,92),'#735c43');q.line((43,66,43,90),fill='#a18856');q.line((44,78,57,62),fill='#66553f')
 colors=['#25493e','#315e48','#437751','#618d59','#7d9e60'] if not autumn else ['#635e43','#87784c','#ab9459','#c1ac67','#d5c17e']
 # Hand-designed asymmetric lobe silhouette; nested stepped shading.
 lobes=[(22,49,19),(51,46,24),(36,28,22),(62,30,17),(21,30,16),(42,14,14)]
 for x,y,radius in lobes:
  ellipse(q,(x-radius,y-radius,x+radius,y+radius),colors[0]);ellipse(q,(x-radius+2,y-radius+1,x+radius-1,y+radius-4),colors[1]);ellipse(q,(x-radius+3,y-radius+2,x+radius-5,y+radius-10),colors[2]);ellipse(q,(x-radius+4,y-radius+3,x+radius-9,y+radius-17),colors[3])
 for i in range(190):
  x,y=r.randrange(6,76),r.randrange(4,68)
  if im.getpixel((x,y))[3]:
   col=r.choice(colors[1:]);q.line((x,y,x+2,y),fill=col)
 for x,y in [(28,15),(18,31),(45,9),(60,25),(30,45),(48,35)]:q.line((x,y,x+5,y),fill=colors[4]);q.point((x-1,y+1),fill=colors[3])
 return im
for i in range(3):add('tree'+str(i),tree(i),[42,95])
add('goldtree',tree(32,True),[42,95])
# Dense layered bushes, rocks, supplies, lanterns, signs.
for kind in ['bush','rock','crate','barrel','lantern','sign','stump','reeds','bench','shrine']:
 im=Image.new('RGBA',(48,64));q=ImageDraw.Draw(im);ellipse(q,(5,49,44,61),'#29473970')
 if kind=='bush':
  for x,y,r in [(13,46,10),(32,43,12),(23,36,13)]:
   ellipse(q,(x-r,y-r,x+r,y+r),P['ink']);ellipse(q,(x-r+1,y-r+1,x+r-1,y+r-3),'#3b6d4c');ellipse(q,(x-r+3,y-r+2,x+r-4,y+r-8),'#6b925c')
  for x,y in [(10,41),(23,32),(30,39),(22,44),(34,44)]:rect(q,(x,y,x+2,y+1),'#a0b56f')
 elif kind=='rock':
  poly(q,[(7,54),(8,43),(17,34),(31,35),(40,45),(41,54),(31,59),(15,59)],'#2f4c43');poly(q,[(9,51),(11,43),(18,36),(30,37),(37,45),(31,51)],'#9aa38c');poly(q,[(9,52),(24,52),(31,47),(38,46),(38,54),(29,57),(14,56)],'#657b6e');q.line((17,40,26,40,30,43),fill='#bbc0a2');q.line((25,53,29,48),fill='#485f55')
 elif kind=='crate':
  rect(q,(10,34,37,57),'#3c4537');rect(q,(12,36,35,55),'#94724f')
  for x in range(14,35,6):q.line((x,38,x,54),fill='#b99766')
  rect(q,(12,37,35,39),'#ccaa73');rect(q,(12,51,35,54),'#c0a170');q.line((13,50,33,40),fill='#d0ac77',width=3)
 elif kind=='barrel':
  ellipse(q,(12,30,36,58),'#414436');rect(q,(12,34,36,52),'#96734c');ellipse(q,(12,28,36,38),'#c09a63');ellipse(q,(15,30,33,35),'#775d41')
  for x in range(15,35,5):q.line((x,38,x,54),fill='#b28b59')
  rect(q,(12,40,36,42),'#4f6260');rect(q,(12,50,36,52),'#4f6260')
 elif kind=='lantern':
  rect(q,(23,17,25,56),'#634f3c');q.line((24,18,35,18,35,24),fill='#c7a373',width=2);rect(q,(30,25,40,39),'#293e3d');rect(q,(32,27,38,36),'#e8b66d');rect(q,(34,28,36,34),'#fff0b4');poly(q,[(29,24),(35,20),(41,24)],'#536c62');rect(q,(29,39,41,41),'#52635c')
 elif kind=='sign':
  rect(q,(23,35,26,58),'#806544');rect(q,(7,25,42,41),'#3d493b');rect(q,(8,26,40,38),'#b69765');q.line((12,30,30,30),fill='#66583e');q.line((12,34,24,34),fill='#66583e');poly(q,[(32,28),(37,32),(32,35)],'#655941')
 elif kind=='stump':
  poly(q,[(11,53),(13,36),(33,36),(36,54),(40,57),(8,57)],'#705741');ellipse(q,(12,31,34,41),'#b69b69');ellipse(q,(16,33,30,39),'#765f43');ellipse(q,(19,34,27,37),'#c9ae79');q.line((17,43,16,52),fill='#ac8656')
 elif kind=='reeds':
  for x,y in [(15,37),(20,30),(26,34),(32,39),(36,33)]:q.line((24,59,x,y),fill='#91a26c');q.line((x,y,x,y-7),fill='#bd9970',width=2)
 elif kind=='bench':
  rect(q,(9,40,12,59),'#4b4c3a');rect(q,(35,40,38,59),'#4b4c3a');rect(q,(5,38,43,44),'#aa895c');rect(q,(5,29,43,34),'#c0a173');q.line((7,39,41,39),fill='#e0bc81')
 elif kind=='shrine':
  poly(q,[(8,58),(8,52),(15,49),(16,22),(23,15),(31,22),(32,49),(39,52),(39,58)],'#3c5950');rect(q,(17,24,30,49),'#879885');q.line((18,25,18,46),fill='#bbc3a0');poly(q,[(24,27),(28,33),(24,40),(20,33)],'#e2bb6d');rect(q,(10,53,37,56),'#a4ad92');q.line((22,44,26,44),fill='#536e62')
 add(kind,im,[24,57])
# The keeper's lodge: asymmetrical copper-green roof, plaster/timber, glowing windows.
im=Image.new('RGBA',(220,192));q=ImageDraw.Draw(im)
poly(q,[(13,154),(195,151),(217,183),(25,188)],'#29473888')
rect(q,(28,72,188,164),'#34453b');rect(q,(31,74,185,161),'#b8ac87');rect(q,(35,86,180,155),'#d0bd91')
for y in range(93,155,13):q.line((34,y,182,y),fill='#bead87')
for x in (34,102,181):rect(q,(x,78,x+5,159),'#655647');rect(q,(x,78,x+1,157),'#a18a62')
q.line((39,111,65,88),fill='#7c684e',width=4);q.line((175,111,150,88),fill='#7c684e',width=4)
for x in (51,137):
 rect(q,(x-3,98,x+29,129),'#725c45');rect(q,(x,99,x+26,124),'#314b4a');rect(q,(x+2,101,x+24,122),'#d9b572');rect(q,(x+4,103,x+11,111),'#f3d697');q.line((x+13,100,x+13,124),fill='#685f45',width=2);q.line((x,113,x+26,113),fill='#685f45',width=2);rect(q,(x-4,127,x+30,130),'#99774e');rect(q,(x-2,131,x+28,138),'#655c3e')
 for xx in range(x,x+27,4):q.line((xx,132,xx+1,125),fill='#567c50');q.point((xx+1,125),fill='#d6a082')
rect(q,(91,116,125,164),'#594b3c');rect(q,(95,119,121,161),'#6e6550')
for x in range(97,121,6):q.line((x,121,x,158),fill='#92815a')
ellipse(q,(115,139,118,142),'#e7c578');rect(q,(85,161,132,166),'#aaa88b');rect(q,(80,166,137,171),'#687d6a');q.line((82,167,135,167),fill='#c1b895')
# roof high contrast silhouette and many individual staggered shingles
poly(q,[(17,82),(36,27),(99,9),(186,27),(206,83)],'#263e3e');poly(q,[(20,77),(39,29),(99,14),(182,29),(201,77)],'#416c70')
for y in range(28,78,7):
 lo=int(39-(y-28)*.36);hi=int(182+(y-28)*.36)
 for x in range(lo,hi,11):
  xx=x+(5 if (y//7)%2 else 0)
  q.line((xx,y,min(xx+9,hi),y),fill=R.choice(['#66918b','#5b8581','#73988c']));q.line((xx+9,y+1,xx+9,y+5),fill='#305658');q.line((xx,y+6,min(xx+9,hi),y+6),fill='#355b5f')
q.line((17,79,205,79),fill='#b59a68',width=3);q.line((36,27,99,9,186,27),fill='#809e8e',width=3)
# chimney, attic gable and iron lamp
rect(q,(149,8,165,38),'#566b61');rect(q,(147,6,167,11),'#a9ad8b');q.line((152,15,161,15),fill='#7e8a72');q.line((153,22,164,22),fill='#7e8a72')
poly(q,[(75,70),(99,37),(128,70)],'#314b48');poly(q,[(80,68),(99,44),(123,68)],'#b4ad87');rect(q,(93,52,107,68),'#435e56');rect(q,(95,54,105,65),'#e3bf78');q.line((100,54,100,65),fill='#6b704f');q.line((77,69,126,69),fill='#ceac74',width=2)
rect(q,(129,114,137,127),'#3a4e45');rect(q,(131,115,135,124),'#f1cc84');q.line((128,112,138,112),fill='#ad9566');add('lodge',im,[108,168])
# Character sheets: 4 directions x 6 gait frames, full handmade pixel silhouettes.
def person(name,coat,hair,skin,scarf):
 sheet=Image.new('RGBA',(24*6,32*4))
 for direction in range(4):
  for f in range(6):
   im=Image.new('RGBA',(24,32));q=ImageDraw.Draw(im);stride=[0,1,2,0,-1,-2][f];bob=0 if f in (0,3) else -1
   # boots & walking alternation
   rect(q,(7+stride,25,10+stride,29),P['ink']);rect(q,(13-stride,25,16-stride,29),P['ink']);rect(q,(7+stride,25,9+stride,27),'#82684d');rect(q,(13-stride,25,15-stride,27),'#82684d')
   poly(q,[(7,13+bob),(16,13+bob),(19,23+bob),(16,26),(7,26),(4,23+bob)],P['ink']);poly(q,[(8,14+bob),(15,14+bob),(17,23+bob),(14,25),(8,24),(6,22+bob)],coat)
   q.line((8,17+bob,8,22+bob),fill='#b4c4a0');rect(q,(8,23,15,24),'#6b6348');rect(q,(11,23,12,24),'#e9c682')
   arm=stride//2;rect(q,(4,17+bob+arm,6,22+bob+arm),P['ink']);rect(q,(5,19+bob+arm,6,22+bob+arm),skin);rect(q,(17,17+bob-arm,19,22+bob-arm),P['ink']);rect(q,(17,19+bob-arm,18,22+bob-arm),skin)
   poly(q,[(6,5+bob),(9,2+bob),(15,2+bob),(18,6+bob),(18,12+bob),(15,16+bob),(8,15+bob),(5,11+bob)],P['ink']);rect(q,(7,6+bob,16,12+bob),skin);rect(q,(9,13+bob,14,15+bob),skin)
   poly(q,[(6,6+bob),(8,3+bob),(15,3+bob),(17,6+bob),(16,8+bob),(12,6+bob),(8,8+bob)],hair);q.line((9,4+bob,14,4+bob),fill='#bdac7b')
   if direction==0: # south
    q.point((9,10+bob),fill=P['ink']);q.point((15,10+bob),fill=P['ink']);q.line((10,13+bob,13,13+bob),fill='#ae7960')
   elif direction==1: # west
    rect(q,(13,6+bob,17,13+bob),hair);q.point((8,10+bob),fill=P['ink']);rect(q,(5,9+bob,7,11+bob),skin)
   elif direction==2: # east
    rect(q,(6,6+bob,10,13+bob),hair);q.point((15,10+bob),fill=P['ink']);rect(q,(16,9+bob,18,11+bob),skin)
   else:
    rect(q,(6,6+bob,17,12+bob),hair);rect(q,(9,14+bob,15,22+bob),'#9f8960');q.line((10,15+bob,14,15+bob),fill='#d5bb80')
   rect(q,(7,15+bob,16,16+bob),scarf);rect(q,(15,16+bob,17,20+bob),scarf)
   sheet.alpha_composite(im,(f*24,direction*32))
 save(sheet,name)
person('rowan','#6b8f8a','#514b3e','#dab68a','#e1b26b');person('iona','#a57862','#d1c7a6','#c99c79','#8fb19c');person('bram','#687354','#5c4b42','#bd8b65','#cd9d6b')
save(atlas,'props_atlas');(OUT/'props.json').write_text(json.dumps(meta,indent=2))
# Cozy interior, baked floor/walls; furniture remains on atlas and collisions separate.
im=Image.new('RGBA',(640,432),'#203936');q=ImageDraw.Draw(im)
rect(q,(79,44,561,381),'#293e36');rect(q,(88,94,552,373),'#8c6d50')
for y in range(95,374,14):
 for x in range(88,553,43):
  xx=x+(21 if (y//14)%2 else 0);rect(q,(xx,y,min(xx+41,551),y+12),R.choice(['#907555','#977b58','#a0835c','#896e50']));q.line((xx+3,y+4,min(xx+28,550),y+4),fill='#ab8a60');q.point((min(xx+2,550),y+10),fill='#67563f')
rect(q,(88,47,552,96),'#b5ab84')
for x in range(91,553,64):rect(q,(x,47,x+5,96),'#5b5843')
rect(q,(88,90,552,99),'#5c5540');q.line((90,91,550,91),fill='#d1bd8a')
# windows & blue daylight
for x in (162,419):
 rect(q,(x,55,x+48,87),'#5a5b46');rect(q,(x+3,58,x+45,84),'#629093');rect(q,(x+5,59,x+21,70),'#9db7a7');q.line((x+24,57,x+24,85),fill='#d2be8b',width=2);q.line((x+3,73,x+45,73),fill='#cbb887',width=2)
 poly(q,[(x+4,101),(x+45,101),(x+82,164),(x+34,164)],'#ab9365')
# bordered woven carpet
rect(q,(249,183,407,302),'#574d42');rect(q,(252,186,404,299),'#a45f54');rect(q,(257,191,399,294),'#bd8060');rect(q,(263,196,393,289),'#586f65')
for y in range(201,289,8):
 for x in range(268,394,10):q.line((x,y,x+4,y+3),fill='#708877')
for x in range(258,400,12):poly(q,[(x,190),(x+4,194),(x,198),(x-4,194)],'#e0b478');poly(q,[(x,288),(x+4,292),(x,296),(x-4,292)],'#e0b478')
# built-in shelves with books, crockery
for x in (100,480):
 rect(q,(x,111,x+59,179),'#414939');rect(q,(x+3,114,x+56,173),'#6c5742')
 for y in (129,151,174):rect(q,(x+1,y,x+58,y+3),'#bd9866')
 for i in range(8):
  xx=x+6+i*6;hh=R.randrange(9,16);rect(q,(xx,128-hh,xx+3,127),R.choice(['#9e6353','#74928a','#cfb57d']));q.point((xx+1,127-hh+3),fill='#e5d19a')
 for xx in (x+12,x+32,x+46):ellipse(q,(xx,138,xx+9,149),'#c2baa0');ellipse(q,(xx+2,137,xx+7,140),'#5e6a57')
# fireplace on east wall
rect(q,(490,226,546,302),'#3e4b3d');rect(q,(492,225,544,232),'#b0a78a');rect(q,(497,240,538,294),'#746f59');rect(q,(503,249,532,289),'#302e29')
for y in (242,259,276):q.line((496,y,540,y),fill='#948c6c')
rect(q,(507,281,528,285),'#9b7045');poly(q,[(508,280),(511,268),(516,274),(520,260),(524,272),(528,270),(528,280)],'#dca25b');poly(q,[(515,280),(519,270),(523,280)],'#f4d68f')
# dining table & desk details
ellipse(q,(173,207,225,258),'#3d4a39');rect(q,(178,183,220,234),'#4e4a37');rect(q,(175,177,224,224),'#b08b5c');rect(q,(178,180,221,220),'#c5a371')
for y in (190,203,216):q.line((179,y,220,y),fill='#ab875b')
ellipse(q,(185,188,196,198),'#e2d7b0');ellipse(q,(187,190,194,196),'#7e9076');rect(q,(205,188,214,201),'#c3c4a6');rect(q,(207,188,212,193),'#667761')
for y in (166,235):rect(q,(185,y,215,y+5),'#b89461');rect(q,(188,y+6,192,y+14),'#5f543c');rect(q,(208,y+6,212,y+14),'#5f543c')
# bed, quilt and herbs
rect(q,(105,271,167,349),'#564c39');rect(q,(107,277,165,343),'#b7b296');rect(q,(110,298,162,339),'#537977')
for y in range(300,339,8):q.line((111,y,160,y),fill='#7a9b8b')
rect(q,(113,281,160,294),'#e2d7b2');rect(q,(105,269,167,275),'#b39866');rect(q,(105,342,167,348),'#b39866')
# doorway carpet / threshold
rect(q,(294,347,346,373),'#ad8660');q.line((298,351,342,351),fill='#dec294');rect(q,(292,374,348,382),'#b6ab87');rect(q,(292,383,348,392),'#6e7b64')
save(im,'lodge_interior')
# UI ornament assets: portrait and original leaf badge
portrait=Image.open(OUT/'rowan.png').crop((0,0,24,32)).resize((48,64),Image.Resampling.NEAREST);save(portrait,'portrait')
print('Generated ground, interior, 14 prop regions and 72 original character frames.')
