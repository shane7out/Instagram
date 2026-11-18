#!/usr/bin/env python3
"""Builds sites/key-technologies/brand/rr-seal-fancy.svg: the showpiece RR seal (gold metal ring, pearl border,
black enamel centre with engraved rosette, raised gold RR). Lettering is outlined, so no font is needed.
Run from the repo root: python3 docs/key-integration/build_rr_seal_fancy.py"""
import math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
ft=TTFont('/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf');gs=ft.getGlyphSet();cmap=ft.getBestCmap();upm=ft['head'].unitsPerEm
K='#0f171e'
def adv(c,size): return gs[cmap[ord(c)]].width*size/upm
def draw(ch,size,m):
    pen=SVGPathPen(gs,ntos=lambda v:('%.2f'%v).rstrip('0').rstrip('.'));s=size/upm
    gs[cmap[ord(ch)]].draw(TransformPen(pen,(m[0]*s,m[1]*s,m[2]*s,m[3]*s,m[4],m[5])));return pen.getCommands()
def arc_text(text,r,size,ls,top):
    ws=[adv(c,size) for c in text];total=sum(ws)+ls*(len(text)-1);pos=-total/2;out=[]
    for ch,w in zip(text,ws):
        a=(pos+w/2)/r;co=math.cos(a);si=math.sin(a)
        if top: Px=50+r*si;Py=50-r*co;m=(co,si,si,-co,Px-(w/2)*co,Py-(w/2)*si)
        else: Px=50+r*si;Py=50+r*co;m=(co,-si,-si,-co,Px-(w/2)*co,Py+(w/2)*si)
        out.append(draw(ch,size,m));pos+=w+ls
    return ' '.join(out)
def flat(text,cx,y,size,ls):
    ws=[adv(c,size) for c in text];total=sum(ws)+ls*(len(text)-1);x=cx-total/2;out=[]
    for ch,w in zip(text,ws): out.append(draw(ch,size,(1,0,0,-1,x,y)));x+=w+ls
    return ' '.join(out)
pearls=''.join(f'<circle cx="{50+42.3*math.cos(i*math.pi/36):.2f}" cy="{50+42.3*math.sin(i*math.pi/36):.2f}" r=".62" fill="url(#pearl)"/>' for i in range(72))
rosette=''.join(f'<ellipse cx="50" cy="50" rx="23.5" ry="9.5" transform="rotate({i*7.5} 50 50)"/>' for i in range(24))
rays=''.join(f'<line x1="50" y1="50" x2="{50+27*math.cos(i*math.pi/30):.2f}" y2="{50+27*math.sin(i*math.pi/30):.2f}"/>' for i in range(60))
def leaf(cx,cy,ang,l=3.6,w=1.5): return f'<path d="M0 0Q{l/2} {-w} {l} 0Q{l/2} {w} 0 0Z" transform="translate({cx} {cy}) rotate({ang})" fill="{K}"/>'
sprig=lambda x,dirn:''.join(leaf(x+dirn*i*0.3,50+j*(2.2+i*1.1),(-90 if j<0 else 90)+dirn*(-35 if j<0 else 35)*-1+0,3.2,1.25) for i in range(0) for j in (-1,1))
# laurel sprigs on the sides: three leaf pairs fanning up and down from the side diamonds
def side(x,d):
    out=''
    for k in range(3):
        out+=leaf(x,50-1.8-k*2.7,-70-d*18+ (0 if d>0 else 0),3.4,1.2)
        out+=leaf(x,50+1.8+k*2.7,70+d*18,3.4,1.2)
    return out
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100" role="img" aria-label="Restaurant Rewards (RR)">
<title>Restaurant Rewards (RR)</title>
<defs>
<linearGradient id="ring" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff3c4"/><stop offset=".28" stop-color="#e9c35a"/><stop offset=".55" stop-color="#b78722"/><stop offset=".8" stop-color="#f0d27a"/><stop offset="1" stop-color="#9a6e14"/></linearGradient>
<linearGradient id="face" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6dc8b"/><stop offset=".5" stop-color="#e2b947"/><stop offset="1" stop-color="#c8982e"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff0b8"/><stop offset=".5" stop-color="#e8c25c"/><stop offset="1" stop-color="#b07f1c"/></linearGradient>
<radialGradient id="pearl" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fffbe9"/><stop offset=".6" stop-color="#d9ad45"/><stop offset="1" stop-color="#8a5e0c"/></radialGradient>
<radialGradient id="enamel" cx=".5" cy=".35" r=".75"><stop offset="0" stop-color="#26333f"/><stop offset="1" stop-color="#070b0f"/></radialGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="1" y2="1"><stop offset=".3" stop-color="#fff" stop-opacity="0"/><stop offset=".45" stop-color="#fff" stop-opacity=".38"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/></linearGradient>
<filter id="bev" x="-12%" y="-12%" width="124%" height="124%"><feGaussianBlur in="SourceAlpha" stdDeviation=".45" result="a"/><feOffset in="a" dx="-.9" dy="-1.1" result="ho"/><feComposite in="ho" in2="SourceAlpha" operator="out" result="h"/><feFlood flood-color="#fff" flood-opacity=".9"/><feComposite in2="h" operator="in" result="hc"/><feOffset in="a" dx="1" dy="1.2" result="so"/><feComposite in="so" in2="SourceAlpha" operator="out" result="s"/><feFlood flood-color="#3d2200" flood-opacity=".7"/><feComposite in2="s" operator="in" result="sc"/><feMerge><feMergeNode in="sc"/><feMergeNode in="hc"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="rrb" x="-10%" y="-10%" width="120%" height="120%"><feOffset in="SourceAlpha" dx=".35" dy=".5" result="o"/><feGaussianBlur in="o" stdDeviation=".25" result="b"/><feFlood flood-color="#000" flood-opacity=".75"/><feComposite in2="b" operator="in" result="sh"/><feMerge><feMergeNode in="sh"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="drop" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="1.4" stdDeviation="1.6" flood-color="#000" flood-opacity=".5"/></filter>
<clipPath id="disc"><circle cx="50" cy="50" r="28"/></clipPath>
</defs>
<g filter="url(#drop)"><circle cx="50" cy="50" r="49.2" fill="url(#ring)"/></g>
<circle cx="50" cy="50" r="49.2" fill="none" stroke="{K}" stroke-width=".7"/>
<g filter="url(#bev)"><circle cx="50" cy="50" r="46.2" fill="none" stroke="url(#ring)" stroke-width="3.4"/></g>
<circle cx="50" cy="50" r="44.2" fill="url(#face)"/>
<circle cx="50" cy="50" r="44" fill="none" stroke="{K}" stroke-width=".55"/>
{pearls}
<circle cx="50" cy="50" r="40.2" fill="none" stroke="{K}" stroke-width=".5"/>
<circle cx="50" cy="50" r="29.8" fill="none" stroke="{K}" stroke-width=".5"/>
<g fill="{K}" style="filter:drop-shadow(0 .45px 0 rgba(255,255,255,.75))">
<path d="{arc_text("RESTAURANT",32.7,7.6,1.35,True)}"/>
<path d="{arc_text("REWARDS",38.1,7.6,1.8,False)}"/>
</g>
{side(10.9,1)}{side(89.1,-1)}
<rect x="9.4" y="48.6" width="3" height="3" fill="{K}" transform="rotate(45 10.9 50)"/><rect x="87.6" y="48.6" width="3" height="3" fill="{K}" transform="rotate(45 89.1 50)"/>
<circle cx="50" cy="50" r="28.6" fill="url(#ring)"/>
<circle cx="50" cy="50" r="27.6" fill="url(#enamel)"/>
<g clip-path="url(#disc)"><g fill="none" stroke="#e8c25c" stroke-width=".22" stroke-opacity=".22">{rosette}</g><g stroke="#e8c25c" stroke-width=".14" stroke-opacity=".15">{rays}</g></g>
<circle cx="50" cy="50" r="26.2" fill="none" stroke="#e8c25c" stroke-opacity=".8" stroke-width=".45"/>
<circle cx="50" cy="50" r="24.8" fill="none" stroke="#e8c25c" stroke-opacity=".4" stroke-width=".25"/>
<g filter="url(#rrb)"><path fill="url(#gold)" d="{flat("RR",50,58.6,25,-.4)}"/></g>
<path d="M36 64.5h28" stroke="url(#gold)" stroke-width=".5"/><rect x="48.9" y="63.4" width="2.2" height="2.2" fill="url(#gold)" transform="rotate(45 50 64.5)"/>
<circle cx="50" cy="50" r="49.2" fill="url(#sheen)" opacity=".55"/>
</svg>'''
open('sites/key-technologies/brand/rr-seal-fancy.svg','w').write(svg);print(len(svg),'bytes')
