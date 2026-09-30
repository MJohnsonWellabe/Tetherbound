from pathlib import Path
import hashlib,json,math,random,struct,wave

def synth(effect, role, base, signature, soft):
    """One layered mono sample per event; a volley never opens N voices."""
    sr=22050
    duration=.56 if 'travel' in role else (.38 if 'impact' in role else .16)
    rng=random.Random(int(hashlib.sha256((effect+role).encode()).hexdigest()[:12],16))
    result=[]
    for i in range(round(sr*duration)):
        t=i/sr
        attack=min(1,t/.009)
        decay=math.exp(-t/(.13 if 'travel' in role else .07))
        noise=rng.uniform(-1,1)
        pitch=base*(1+signature*.04)*math.exp(-t*(1.2 if 'impact' in role else -.12))
        tone=math.sin(math.tau*pitch*t)+.35*math.sin(math.tau*pitch*1.71*t)
        if effect=='stone_throw':
            # Three bounded grains; boulder variant has one lower resonance.
            envelope=sum(math.exp(-max(0,t-onset)*85) if t>=onset else 0 for onset in (0,.04,.085))
            value=(noise*.62+tone*.38)*envelope
        elif effect=='stone_boulder': value=(noise*.30+tone*.70)*decay
        elif effect in ('sky_lightning','chain_lightning'):
            value=(noise*.72+tone*.28)*decay*(.65+.35*math.sin(math.tau*55*t))
        elif effect in ('water_jet','bubble_volley','tidal_wave'):
            value=(noise*.35+tone*.65)*decay*(.7+.3*math.sin(math.tau*12*t))
        elif effect in ('fireball','flame_cone','ember_burst'):
            value=(noise*.60+tone*.40)*decay
        elif effect in ('wind_blade','tornado','frost_breath'):
            value=(noise*.65+tone*.35)*decay*(.7+.3*math.sin(math.tau*7*t))
        else: value=(noise*.20+tone*.80)*decay
        if 'travel' in role:
            value += (.09*noise+.09*math.sin(math.tau*base*.7*t))*math.sin(math.pi*t/duration)**2
        if 'mastery' in role:
            # Added harmonic layer at the same peak; no gain increase.
            value=.84*value+.12*math.sin(math.tau*base*2.01*t)*decay
        value *= attack * min(1,(duration-t)/.03) * (.30 if soft else .46)
        result.append(max(-.85,min(.85,value)))
    return sr,result

def main():
    folder=Path(__file__).resolve().parent
    recipes=json.loads((folder/'recipes.json').read_text(encoding='utf-8'))
    for effect,recipe in recipes.items():
        for role in ('launch','travel','launch_travel','impact','launch_mastery','launch_travel_mastery','impact_mastery'):
            sr,samples=synth(effect,role,recipe['base_hz'],recipe['signature'],recipe['soft'])
            with wave.open(str(folder/f'{effect}_{role}.wav'),'wb') as file:
                file.setnchannels(1);file.setsampwidth(2);file.setframerate(sr)
                file.writeframes(struct.pack('<'+'h'*len(samples),*(round(v*32767) for v in samples)))
    print('Regenerated original cue assets; inspect/judge before accepting changed sound')

if __name__=='__main__':main()
