"""Independent definition checks + generic orientation search with reachability pruning.
No Godot dependency. Witnesses are independently evaluated, never assumed correct.
"""
import json, sys, time
from pathlib import Path
D=[(0,-1),(1,0),(0,1),(-1,0)]
TYPES={'straight','corner','tee','cross','start','target','blocked','one_way','switch','gate','splitter','color_path','color_target','teleporter'}
def ports(t):
 typ=t['type'];typ=t.get('shape','straight') if typ in ('color_path','gate','switch') else typ
 base={'straight':[0,2],'corner':[0,1],'tee':[0,1,3],'cross':[0,1,2,3],'start':[1],'target':[3],'color_target':[3],'one_way':[1,3],'splitter':[0,1,2,3],'teleporter':[1,3]}.get(typ,[])
 return [(p+t['rotation'])%4 for p in base]
def evaluate(l,tiles=None):
 ts=tiles or l['tiles'];w,h=l['width'],l['height'];q=[(i,-1,'neutral') for i,t in enumerate(ts) if t['type']=='start'];seen=set();powered=set();targets=set()
 channels={t.get('channel','A') for t in ts if t['type']=='switch' and t.get('on',False)}
 pairs={}
 for i,t in enumerate(ts):
  if t['type']=='teleporter':pairs.setdefault(t.get('pair','A'),[]).append(i)
 for i,entry,color in q:
  if (i,entry,color) in seen:continue
  seen.add((i,entry,color));t=ts[i];typ=t['type'];ps=ports(t)
  if (entry>=0 and entry not in ps) or typ=='blocked':continue
  if typ=='gate' and t.get('channel','A') not in channels:continue
  if typ in ('one_way','splitter') and entry>=0 and entry!=(3+t['rotation'])%4:continue
  if typ=='color_path':
   if color not in ('neutral',t['color']):continue
   color=t['color']
  if typ=='color_target' and color!=t['color']:continue
  powered.add(i)
  if typ in ('target','color_target'):targets.add(i);continue
  if typ=='teleporter' and entry!=-2:
   pair=pairs.get(t.get('pair','A'),[])
   if len(pair)==2:q.append((pair[1] if pair[0]==i else pair[0],-2,color))
   continue
  for p in ps:
   if typ=='one_way' and p!=(1+t['rotation'])%4:continue
   if typ=='splitter' and p==(3+t['rotation'])%4:continue
   x,y=i%w+D[p][0],i//w+D[p][1]
   if 0<=x<w and 0<=y<h:
    j=y*w+x
    if (p+2)%4 in ports(ts[j]):q.append((j,(p+2)%4,color))
 required={i for i,t in enumerate(ts) if t['type'] in ('target','color_target') and t.get('required',True)}
 return bool(required) and required<=targets,powered,targets

def solve(l,limit=250000):
 ts=json.loads(json.dumps(l['tiles']));w,h=l['width'],l['height'];domains={};nodes=0
 for i,t in enumerate(ts):
  if t['type']=='switch':domains[i]=[False,True]
  elif not t.get('fixed',False) and t['type']!='blocked':
   period=2 if t['type']=='straight' or (t['type']=='color_path' and t.get('shape')=='straight') else 4
   domains[i]=list(range(period))
 start=next(i for i,t in enumerate(ts) if t['type']=='start');targets=[i for i,t in enumerate(ts) if t['type'] in ('target','color_target')]
 # Safe optimistic graph: union of possible ports, ignores direction/color/gate.
 # This only prunes impossible states; final acceptance uses full rules above.
 def viable(remaining):
  possible=[]
  for i,t in enumerate(ts):
   if i in remaining and t['type']!='switch':
    p=set();old=t['rotation']
    for r in remaining[i]:t['rotation']=r;p.update(ports(t))
    t['rotation']=old;possible.append(p)
   else:possible.append(set(ports(t)))
  found={start};queue=[start]
  for i in queue:
   for p in possible[i]:
    x,y=i%w+D[p][0],i//w+D[p][1]
    if 0<=x<w and 0<=y<h:
     j=y*w+x
     if j not in found and (p+2)%4 in possible[j]:found.add(j);queue.append(j)
   if ts[i]['type']=='teleporter':
    for j,t in enumerate(ts):
     if t['type']=='teleporter' and t.get('pair')==ts[i].get('pair') and j not in found:found.add(j);queue.append(j)
  return all(i in found for i in targets)
 def dfs(remaining):
  nonlocal nodes
  nodes+=1
  if nodes>limit:raise RuntimeError('Search limit exceeded')
  if not viable(remaining):return None
  if not remaining:return json.loads(json.dumps(ts)) if evaluate(l,ts)[0] else None
  # Breadth from source keeps chain constraints early; decoys last.
  i=min(remaining,key=lambda i:(ts[i].get('decoy',False),abs(i%w-start%w)+abs(i//w-start//w),len(remaining[i])))
  rest={k:v for k,v in remaining.items() if k!=i};field='on' if ts[i]['type']=='switch' else 'rotation';old=ts[i].get(field,False)
  for value in remaining[i]:
   ts[i][field]=value;answer=dfs(rest)
   if answer is not None:return answer
  ts[i][field]=old;return None
 return dfs(domains),nodes

def validate(l):
 w,h=l['width'],l['height'];ts=l['tiles'];assert 2<=w<=9 and 2<=h<=7
 assert len(ts)==w*h;assert sum(t['type']=='start' for t in ts)==1
 assert any(t['type'] in ('target','color_target') for t in ts)
 for i,t in enumerate(ts):
  assert (t['x'],t['y'])==(i%w,i//w);assert t['type'] in TYPES;assert 0<=t['rotation']<=3 and 0<=t['solution']<=3
  if t['type'] in ('gate','switch'):assert t.get('channel')
  if t['type'] in ('color_path','color_target'):assert t.get('color') in ('violet','coral')
  if t['type']=='teleporter':assert sum(u['type']=='teleporter' and u.get('pair')==t.get('pair') for u in ts)==2
 assert not evaluate(l)[0], 'Level begins solved'
 witness=json.loads(json.dumps(ts))
 for t in witness:
  t['rotation']=t['solution']
  if t['type']=='switch':t['on']=t.get('solution_on',True)
 solved,powered,_=evaluate(l,witness);assert solved,'Authored solution fails'
 assert all(i in powered for i,t in enumerate(witness) if t['type']!='blocked' and not t.get('decoy',False)), 'Mandatory tile disconnected'
 answer,nodes=solve(l);assert answer is not None,'No independently found solution'
 return nodes
if __name__=='__main__':
 levels=json.loads((Path(__file__).resolve().parents[1]/'data/levels.json').read_text());assert len(levels)==20
 started=time.perf_counter();total=0
 for l in levels:
  n=validate(l);total+=n;print(f"PASS {l['id']:02d} {l['title']:<25} {l['width']}x{l['height']} | par {l['par']:2d} | search {n} nodes")
 print(f'20/20 validated; {total} search nodes; {time.perf_counter()-started:.3f}s. All witnesses and independent solutions pass.')
