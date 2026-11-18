#!/usr/bin/env python3
"""Builds sites/key-technologies/brand/rr-seal-fancy.svg: the showpiece RR seal (gold metal ring, pearl border,
black enamel centre with engraved rosette, raised gold RR). Lettering is outlined, so no font is needed.
Run from the repo root: python3 docs/key-integration/build_rr_seal_fancy.py"""
import math,sys,argparse
ap=argparse.ArgumentParser()
ap.add_argument('--sides',choices=['laurel','diamond'],default='laurel')
ap.add_argument('--center',choices=['spirals','plain','rings','rays'],default='plain')
ap.add_argument('--rule',type=int,default=0,help='1 = small rule and diamond under the RR')
ap.add_argument('--rr',type=float,default=28,help='RR size')
ap.add_argument('--track',type=float,default=3.0,help='space between the two R')
ap.add_argument('--out',default='sites/key-technologies/brand/rr-seal-fancy.svg')
A=ap.parse_args();PLAIN=A.sides=='diamond'
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
def _b(i):
    c=math.cos(i*math.pi/90);d=math.sin(i*math.pi/90);col='#fff6d0' if i%2 else '#a9791a'
    return f'<line x1="{50+30.2*c:.2f}" y1="{50+30.2*d:.2f}" x2="{50+43.8*c:.2f}" y2="{50+43.8*d:.2f}" stroke="{col}" stroke-width=".18" stroke-opacity=".16"/>'
burst=''.join(_b(i) for i in range(180))
rays=''.join(f'<line x1="50" y1="50" x2="{50+27*math.cos(i*math.pi/30):.2f}" y2="{50+27*math.sin(i*math.pi/30):.2f}"/>' for i in range(60))
def dia(a0,r=35.0):
    cx,cy=50+r*math.sin(math.radians(a0)),50-r*math.cos(math.radians(a0))
    return f'<rect x="{cx-1.5:.2f}" y="{cy-1.5:.2f}" width="3" height="3" fill="{K}" transform="rotate(45 {cx:.2f} {cy:.2f})"/>'
def laurel(a0,r=35.0):
    """A small laurel sprig either side of a diamond, following the band. a0 = angle in degrees from north (clockwise)."""
    out=''
    for sgn in (1,-1):
        # stem
        a1=math.radians(a0+sgn*3.2);a2=math.radians(a0+sgn*19)
        x1,y1=50+r*math.sin(a1),50-r*math.cos(a1);x2,y2=50+r*math.sin(a2),50-r*math.cos(a2)
        out+=f'<path d="M{x1:.2f} {y1:.2f}A{r} {r} 0 0 {1 if sgn>0 else 0} {x2:.2f} {y2:.2f}" fill="none" stroke="{K}" stroke-width=".45"/>'
        for k in range(4):
            a=math.radians(a0+sgn*(5+k*4.4));px,py=50+r*math.sin(a),50-r*math.cos(a)
            tx,ty=math.cos(a)*sgn,math.sin(a)*sgn;nx,ny=math.sin(a),-math.cos(a)
            for side in (1,-1):
                ux=math.cos(math.radians(38))*tx+side*math.sin(math.radians(38))*nx
                uy=math.cos(math.radians(38))*ty+side*math.sin(math.radians(38))*ny
                L=3.3-k*.25;w=1.15
                out+=f'<path d="M0 0Q{L/2:.2f} {-w} {L:.2f} 0Q{L/2:.2f} {w} 0 0Z" transform="translate({px:.2f} {py:.2f}) rotate({math.degrees(math.atan2(uy,ux)):.1f})" fill="{K}"/>'
    cx,cy=50+r*math.sin(math.radians(a0)),50-r*math.cos(math.radians(a0))
    out+=f'<rect x="{cx-1.5:.2f}" y="{cy-1.5:.2f}" width="3" height="3" fill="{K}" transform="rotate(45 {cx:.2f} {cy:.2f})"/>'
    return out
rings=''.join(f'<circle cx="50" cy="50" r="{r}" fill="none" stroke="#e8c25c" stroke-width=".18" stroke-opacity=".2"/>' for r in (6,10,14,18,22))
CENTER={'spirals':f'<g fill="none" stroke="#e8c25c" stroke-width=".22" stroke-opacity=".22">{rosette}</g><g stroke="#e8c25c" stroke-width=".14" stroke-opacity=".15">{rays}</g>','plain':'','rings':rings,'rays':f'<g stroke="#e8c25c" stroke-width=".16" stroke-opacity=".2">{rays}</g>'}[A.center]
RULE='''<path d="M36 64.5h28" stroke="url(#gold)" stroke-width=".5"/><rect x="48.9" y="63.4" width="2.2" height="2.2" fill="url(#gold)" transform="rotate(45 50 64.5)"/>''' if A.rule else ''
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100" role="img" aria-label="Restaurant Rewards (RR)">
<title>Restaurant Rewards (RR)</title>
<defs>
<linearGradient id="ring" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff3c4"/><stop offset=".28" stop-color="#e9c35a"/><stop offset=".55" stop-color="#b78722"/><stop offset=".8" stop-color="#f0d27a"/><stop offset="1" stop-color="#9a6e14"/></linearGradient>
<linearGradient id="face" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6dc8b"/><stop offset=".5" stop-color="#e2b947"/><stop offset="1" stop-color="#c8982e"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6c8"/><stop offset=".35" stop-color="#f4cf4a"/><stop offset=".7" stop-color="#d9a420"/><stop offset="1" stop-color="#9a6a0c"/></linearGradient>
<radialGradient id="pearl" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fffbe9"/><stop offset=".6" stop-color="#d9ad45"/><stop offset="1" stop-color="#8a5e0c"/></radialGradient>
<radialGradient id="enamel" cx=".5" cy=".35" r=".75"><stop offset="0" stop-color="#141c25"/><stop offset="1" stop-color="#05080b"/></radialGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="1" y2="1"><stop offset=".3" stop-color="#fff" stop-opacity="0"/><stop offset=".45" stop-color="#fff" stop-opacity=".5"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/></linearGradient>
<filter id="bev" x="-12%" y="-12%" width="124%" height="124%"><feGaussianBlur in="SourceAlpha" stdDeviation=".45" result="a"/><feOffset in="a" dx="-.9" dy="-1.1" result="ho"/><feComposite in="ho" in2="SourceAlpha" operator="out" result="h"/><feFlood flood-color="#fff" flood-opacity=".9"/><feComposite in2="h" operator="in" result="hc"/><feOffset in="a" dx="1" dy="1.2" result="so"/><feComposite in="so" in2="SourceAlpha" operator="out" result="s"/><feFlood flood-color="#3d2200" flood-opacity=".7"/><feComposite in2="s" operator="in" result="sc"/><feMerge><feMergeNode in="sc"/><feMergeNode in="hc"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="rrb" x="-10%" y="-10%" width="120%" height="120%"><feOffset in="SourceAlpha" dx=".35" dy=".5" result="o"/><feGaussianBlur in="o" stdDeviation=".25" result="b"/><feFlood flood-color="#000" flood-opacity=".75"/><feComposite in2="b" operator="in" result="sh"/><feMerge><feMergeNode in="sh"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="drop" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="1.4" stdDeviation="1.6" flood-color="#000" flood-opacity=".5"/></filter>
<clipPath id="bandclip"><path fill-rule="evenodd" d="M50 5.8A44.2 44.2 0 1 1 49.99 5.8ZM50 20.2A29.8 29.8 0 1 0 50.01 20.2Z"/></clipPath>
<clipPath id="disc"><circle cx="50" cy="50" r="28"/></clipPath>
</defs>
<g filter="url(#drop)"><circle cx="50" cy="50" r="49.2" fill="url(#ring)"/></g>
<circle cx="50" cy="50" r="49.2" fill="none" stroke="{K}" stroke-width=".7"/>
<g filter="url(#bev)"><circle cx="50" cy="50" r="46.2" fill="none" stroke="url(#ring)" stroke-width="3.4"/></g>
<circle cx="50" cy="50" r="44.2" fill="url(#face)"/>
<g clip-path="url(#bandclip)">{burst}</g>
<circle cx="50" cy="50" r="44" fill="none" stroke="{K}" stroke-width=".55"/>
{pearls}
<circle cx="50" cy="50" r="40.2" fill="none" stroke="{K}" stroke-width=".5"/>
<circle cx="50" cy="50" r="29.8" fill="none" stroke="{K}" stroke-width=".5"/>
<g fill="{K}" style="filter:drop-shadow(0 .45px 0 rgba(255,255,255,.75))">
<path d="{arc_text("RESTAURANT",32.6,8.2,1.25,True)}"/>
<path d="{arc_text("REWARDS",38.0,8.2,1.7,False)}"/>
</g>
{(dia(270) + dia(90)) if PLAIN else (laurel(270) + laurel(90))}
<g filter="url(#bev)"><circle cx="50" cy="50" r="28.8" fill="none" stroke="url(#ring)" stroke-width="2.2"/></g>
<circle cx="50" cy="50" r="27.7" fill="#000" opacity=".35"/>
<circle cx="50" cy="50" r="27.6" fill="url(#enamel)"/>
<g clip-path="url(#disc)">{CENTER}</g>
<circle cx="50" cy="50" r="26.2" fill="none" stroke="#e8c25c" stroke-opacity=".8" stroke-width=".45"/>
<circle cx="50" cy="50" r="24.8" fill="none" stroke="#e8c25c" stroke-opacity=".4" stroke-width=".25"/>
<g filter="url(#rrb)"><path fill="url(#gold)" stroke="#7a520a" stroke-width=".3" stroke-linejoin="round" d="{flat("RR",50,50+A.rr*.34,A.rr,A.track)}"/></g>
{RULE}
</svg>'''
open(A.out,'w').write(svg);print(len(svg),'bytes')
