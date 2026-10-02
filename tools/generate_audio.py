"""Original synthesized, quiet glass tones and a seamless 16-second ambient loop."""
import wave, math, struct
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets/audio';OUT.mkdir(parents=True,exist_ok=True)
SR=22050
def save(name,seconds,fn):
 with wave.open(str(OUT/(name+'.wav')),'wb') as w:
  w.setparams((1,2,SR,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/SR)))*32767)) for i in range(int(seconds*SR))))
def tone(f,t,d=.22):return math.sin(math.tau*f*t)*math.exp(-t*12)*(1-math.exp(-t*180))*(max(0,1-t/d))
save('rotate',.17,lambda t:.24*tone(660,t,.17)+.1*tone(990,t,.17))
save('button',.1,lambda t:.22*tone(440,t,.1))
save('connect',.26,lambda t:.18*tone(523.25,t,.26)+.1*tone(784.9,t,.26))
save('target',.45,lambda t:.22*tone(1046.5,t,.45)+.13*tone(1318.5,t,.45))
save('complete',1.5,lambda t:sum(.17*tone(f,t-i*.14,.8) for i,f in enumerate([523.25,659.25,783.99,1046.5]) if 0<=t-i*.14<.8))
# Frequencies are exact integer cycles over loop length; LFO also loops at 16 sec.
freqs=[round(f*16)/16 for f in [130.81,196,261.63,329.63]]
save('ambience',16,lambda t:sum(.024*math.sin(math.tau*f*t)*(0.65+.35*math.sin(math.tau*t/16+i)) for i,f in enumerate(freqs)))
print('Generated six original WAV assets.')
