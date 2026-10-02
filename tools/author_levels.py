"""Compile explicitly hand-designed routes into portable level definitions.
No random generation. Coordinates, branches, mechanics and scrambles are authored here.
"""
import json
from pathlib import Path
D=[(0,-1),(1,0),(0,1),(-1,0)]
LEVELS=[]
def level(title,chapter,w,h,routes,scramble,locked=(),mechanics=None,decoys=(),tip=''):
    ports={};starts=set();targets=set()
    for route in routes:
        starts.add(route[0]);targets.add(route[-1])
        for a,b in zip(route,route[1:]):
            dx,dy=b[0]-a[0],b[1]-a[1];dr=D.index((dx,dy))
            ports.setdefault(a,set()).add(dr);ports.setdefault(b,set()).add((dr+2)%4)
    # Shared route endpoint that is also traversed is a junction, never a target.
    targets={p for p in targets if len(ports[p])==1}
    start=routes[0][0];tiles=[];j=0
    bases={'straight':{0,2},'corner':{0,1},'tee':{0,1,3},'cross':{0,1,2,3},'start':{1},'target':{3}}
    mechanics=mechanics or {}
    for y in range(h):
        for x in range(w):
            p=(x,y)
            if p not in ports:
                tiles.append({'x':x,'y':y,'type':'blocked','rotation':0,'solution':0,'fixed':True});continue
            ps=ports[p]
            typ='start' if p==start else 'target' if p in targets else 'cross' if len(ps)==4 else 'tee' if len(ps)==3 else 'straight' if (max(ps)-min(ps)==2) else 'corner'
            rot=next(r for r in range(4) if {(d+r)%4 for d in bases[typ]}==ps)
            m=mechanics.get(p,{})
            t={'x':x,'y':y,'type':typ,'rotation':rot,'solution':rot,'fixed':p in locked or typ in ('start','target','cross')}
            if m:
                if m['type'] in ('one_way','splitter'):
                    incoming=m['incoming'];rot=(incoming-3)%4;t['solution']=rot;t['rotation']=rot
                if m['type'] in ('color_path','switch','gate'):t['shape']=typ
                t.update(m)
                if m['type']=='switch':t.update(fixed=True,on=False,solution_on=True)
                if m['type']=='gate':t['fixed']=True
                if m['type']=='color_target':t['fixed']=True
            if not t['fixed']:
                offset=scramble[j%len(scramble)];j+=1;t['rotation']=(rot+offset)%4
            tiles.append(t)
    for x,y,typ,rot in decoys:
        idx=y*w+x;tiles[idx]={'x':x,'y':y,'type':typ,'rotation':rot,'solution':rot,'fixed':False,'decoy':True}
    par=sum((t['solution']-t['rotation'])% (2 if t['type']=='straight' or (t['type']=='color_path' and t.get('shape')=='straight') else 4) for t in tiles if not t['fixed'])+sum(t['type']=='switch' for t in tiles)
    LEVELS.append({'id':len(LEVELS)+1,'title':title,'chapter':chapter,'width':w,'height':h,'par':par,'tip':tip,'tiles':tiles})
# Routes are literal designer-authored paths, including each bend and branch.
level('A little twist','FIRST CONTACT',3,2,[[(0,1),(1,1),(1,0),(2,0)]],[3,0],tip='Tap a tile to rotate it. Join the source to the gold target.')
level('Find your flow','FIRST CONTACT',4,3,[[(0,2),(1,2),(1,1),(2,1),(2,0),(3,0)]],[1,3,1,2],tip='Light travels only through matching connections.')
level('Around the bend','FIRST CONTACT',4,3,[[(0,0),(1,0),(2,0),(2,1),(1,1),(1,2),(2,2),(3,2)]],[1,1,2,3],tip='Follow the path. You can undo any move.')
level('Two destinations','BRANCHING OUT',4,3,[[(0,1),(1,1),(2,1),(2,0),(3,0)],[(0,1),(1,1),(2,1),(2,2),(3,2)]],[1,2,1,3],tip='Every gold target needs energy. T-junctions divide the flow.')
level('The long way','BRANCHING OUT',5,4,[[(0,3),(1,3),(1,2),(2,2),(2,1),(3,1),(3,0),(4,0)],[(0,3),(1,3),(1,2),(2,2),(3,2),(3,3),(4,3)]],[1,3,2,1,2],decoys=[(0,0,'corner',1),(4,2,'straight',0)],tip='Some paths are distractions. Trace the useful connections.')
level('Cross currents','BRANCHING OUT',5,4,[[(0,1),(1,1),(2,1),(3,1),(4,1)],[(0,1),(1,1),(2,1),(2,0),(3,0)],[(0,1),(1,1),(2,1),(2,2),(2,3),(3,3),(4,3)]],[1,2,3,1],tip='Four-way junctions carry energy in every direction.')
level('Anchored','FIXED POINTS',4,3,[[(0,2),(1,2),(1,1),(2,1),(2,0),(3,0)]],[2,1,3],locked=[(1,1)],tip='Tiles with a small lock stay fixed. Build around them.')
level('Between the anchors','FIXED POINTS',5,4,[[(0,0),(1,0),(1,1),(2,1),(3,1),(3,2),(2,2),(2,3),(3,3),(4,3)]],[1,2,3,1],locked=[(1,1),(3,2)],decoys=[(4,0,'tee',0)],tip='Use fixed tiles as clues to the route.')
level('Hold the center','FIXED POINTS',5,4,[[(0,2),(1,2),(2,2),(2,1),(3,1),(3,0),(4,0)],[(0,2),(1,2),(2,2),(3,2),(3,3),(4,3)]],[1,3,2,1],locked=[(2,2),(3,0)],tip='Two targets, one anchored junction.')
level('Open sesame','CIRCUIT SWITCHES',4,2,[[(0,1),(1,1),(2,1),(3,1)]],[1],mechanics={(1,1):{'type':'switch','channel':'A'},(2,1):{'type':'gate','channel':'A'}},tip='Tap the switch. Its matching gate opens.')
level('Switchback','CIRCUIT SWITCHES',5,3,[[(0,2),(1,2),(2,2),(2,1),(3,1),(3,0),(4,0)]],[2,1,3],mechanics={(1,2):{'type':'switch','channel':'A'},(3,1):{'type':'gate','channel':'A'}},tip='Switches toggle instead of rotating. Open the gate, then route energy.')
level('Double permission','CIRCUIT SWITCHES',6,4,[[(0,2),(1,2),(2,2),(2,1),(3,1),(4,1),(4,0),(5,0)],[(0,2),(1,2),(2,2),(3,2),(3,3),(4,3),(5,3)]],[1,3,1,2],mechanics={(1,2):{'type':'switch','channel':'A'},(4,1):{'type':'gate','channel':'A'},(3,3):{'type':'switch','channel':'B'},(4,3):{'type':'gate','channel':'B'}},tip='Lettered switches control their matching gates.')
level('Go with the arrow','ONE DIRECTION',4,3,[[(0,1),(1,1),(2,1),(3,1)]],[2,1],mechanics={(1,1):{'type':'one_way','incoming':3},(2,1):{'type':'one_way','incoming':3}},tip='Arrow tiles carry energy in one direction only.')
level('A directed detour','ONE DIRECTION',5,4,[[(0,3),(1,3),(1,2),(1,1),(2,1),(3,1),(3,0),(4,0)]],[1,2,3,1],mechanics={(1,2):{'type':'one_way','incoming':2},(2,1):{'type':'one_way','incoming':3}},locked=[(1,1)],tip='Turn the arrows to follow the flow, not oppose it.')
level('No turning back','ONE DIRECTION',6,4,[[(0,1),(1,1),(2,1),(3,1),(3,0),(4,0),(5,0)],[(0,1),(1,1),(2,1),(2,2),(2,3),(3,3),(4,3),(5,3)]],[3,1,2,1],mechanics={(1,1):{'type':'one_way','incoming':3},(4,0):{'type':'one_way','incoming':3},(4,3):{'type':'one_way','incoming':3}},tip='One source can still feed several directed routes.')
level('Three ways forward','SPLIT THE SIGNAL',5,3,[[(0,1),(1,1),(2,1),(3,1),(4,1)],[(0,1),(1,1),(2,1),(2,0),(3,0)],[(0,1),(1,1),(2,1),(2,2),(3,2)]],[1,2,3],mechanics={(2,1):{'type':'splitter','incoming':3}},tip='A splitter takes energy at its arrow tail and sends it out through three arms.')
level('Divide and deliver','SPLIT THE SIGNAL',6,5,[[(0,2),(1,2),(2,2),(3,2),(4,2),(4,1),(5,1)],[(0,2),(1,2),(2,2),(2,1),(2,0),(3,0),(4,0),(5,0)],[(0,2),(1,2),(2,2),(2,3),(2,4),(3,4),(4,4),(5,4)]],[1,2,3,1,3],mechanics={(2,2):{'type':'splitter','incoming':3},(4,0):{'type':'one_way','incoming':3}},locked=[(2,3)],tip='Align the splitter input first. Then complete each branch.')
level('A change of color','CHROMATIC LOGIC',5,3,[[(0,1),(1,1),(2,1),(3,1),(4,1)]],[1,1],mechanics={(2,1):{'type':'color_path','color':'violet'},(4,1):{'type':'color_target','color':'violet'}},tip='A color tile tints neutral energy. Match the target color.')
level('Separate spectra','CHROMATIC LOGIC',6,4,[[(0,2),(1,2),(2,2),(2,1),(3,1),(4,1),(4,0),(5,0)],[(0,2),(1,2),(2,2),(3,2),(3,3),(4,3),(5,3)]],[2,1,3,1],mechanics={(3,1):{'type':'color_path','color':'violet'},(5,0):{'type':'color_target','color':'violet'},(4,3):{'type':'color_path','color':'coral'},(5,3):{'type':'color_target','color':'coral'}},tip='Split neutral energy before tinting it. Different colors cannot mix.')
level('The MindFlip','FINAL CONNECTION',7,5,[[(0,2),(1,2),(2,2),(3,2),(4,2),(5,2),(6,2)],[(0,2),(1,2),(2,2),(2,1),(2,0),(3,0),(4,0),(5,0),(6,0)],[(0,2),(1,2),(2,2),(2,3),(2,4),(3,4),(4,4),(5,4),(6,4)]],[1,3,2,1,3,2],mechanics={(1,2):{'type':'switch','channel':'A'},(2,2):{'type':'splitter','incoming':3},(4,2):{'type':'gate','channel':'A'},(5,2):{'type':'one_way','incoming':3},(4,0):{'type':'color_path','color':'violet'},(6,0):{'type':'color_target','color':'violet'},(4,4):{'type':'color_path','color':'coral'},(6,4):{'type':'color_target','color':'coral'}},locked=[(2,1),(2,3)],tip='Everything connects: switch, split, direct, and color the flow.')
OUT=Path(__file__).resolve().parents[1]/'data/levels.json';OUT.write_text(json.dumps(LEVELS,indent=2)+'\n')
print('Compiled 20 handcrafted levels, pars:',[l['par'] for l in LEVELS])
