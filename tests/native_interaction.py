"""Real X11 input smoke test; run with an X server and xdotool available.
Example: DISPLAY=:100 XDOTOOL=/path/to/xdotool python3 tests/native_interaction.py
Only isolated render-evidence save data is touched.
"""
from pathlib import Path
import os,subprocess,time,json
from PIL import ImageGrab
ROOT=Path(__file__).resolve().parents[1]
XD=os.environ.get('XDOTOOL','xdotool')
def xd(*args):return subprocess.check_output([XD,*map(str,args)],text=True).strip()
log=open('/tmp/mindflip-native-smoke.log','w')
p=subprocess.Popen(['godot','--path',str(ROOT),'--resolution','1280x720','--audio-driver','Dummy','--','--view=1'],stdout=log,stderr=log)
try:
 win=None
 for _ in range(80):
  try:win=xd('search','--pid',p.pid,'--name','MindFlip').splitlines()[-1];break
  except subprocess.CalledProcessError:time.sleep(.1)
 assert win,'Native game window did not appear'
 time.sleep(1)
 geo=dict(line.split('=') for line in xd('getwindowgeometry','--shell',win).splitlines() if '=' in line)
 x,y,w,h=[int(geo[k]) for k in ['X','Y','WIDTH','HEIGHT']]
 assert (w,h)==(1280,720)
 def tap(lx,ly):xd('windowraise',win,'windowfocus',win,'mousemove',x+round(lx*w/960),y+round(ly*h/540),'click','1')
 # Rotate an incorrect tile, then undo using the actual UI button.
 tap(350,355);time.sleep(.1);tap(806,323);time.sleep(.1)
 # The initially highlighted upper corner needs one clockwise turn.
 tap(350,247);time.sleep(2)
 save=Path.home()/'.local/share/godot/app_userdata/MindFlip/render-evidence.json'
 data=json.loads(save.read_text());assert data['results']['1']=={'moves':1,'stars':3}
 assert data['unlocked']>=2
 ImageGrab.grab(xdisplay=os.environ.get('DISPLAY')).crop((x,y,x+w,y+h)).save(ROOT/'docs/completion-native.png')
 # Use Next Level button, then pause and resume through actual native buttons.
 tap(480,348);time.sleep(.2);tap(905,54);time.sleep(.2)
 ImageGrab.grab(xdisplay=os.environ.get('DISPLAY')).crop((x,y,x+w,y+h)).save(ROOT/'docs/pause.png')
 tap(480,219);time.sleep(.2)
 data=json.loads(save.read_text());assert data['session']['level']==2 and data['session']['moves']==0
 print('PASS native tile tap, Undo button, completion, 3 stars, unlock, Next, pause, Resume; rendered screenshots saved.')
finally:
 p.terminate();p.wait(timeout=5);log.close()
