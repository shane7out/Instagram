#!/usr/bin/env python3
"""Builds sites/key-technologies/brand/rr-emboss-circle.svg: the one-circle RR seal.
All lettering is converted to outlines, so it looks the same on every phone (no font needed).
Run from the repo root: python3 docs/key-integration/build_rr_seal.py"""
import math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
FONT='/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf'
ft=TTFont(FONT);gs=ft.getGlyphSet();cmap=ft.getBestCmap();upm=ft['head'].unitsPerEm
K='#0f171e';G='#fbe7a0'
def glyph(ch,size,ls,place):
    """place(gx_center_offset)->(a,b,c,d,e,f) transform from font units (y up) to svg."""
    pass
def adv(ch,size): return gs[cmap[ord(ch)]].width*size/upm
def draw(ch,size,mat):
    pen=SVGPathPen(gs,ntos=lambda v:('%.2f'%v).rstrip('0').rstrip('.'))
    s=size/upm; a,b,c,d,e,f=mat
    tp=TransformPen(pen,(a*s,b*s,c*s,d*s,e,f))
    gs[cmap[ord(ch)]].draw(tp); return pen.getCommands()
def arc_text(text,r,size,ls,top):
    widths=[adv(c,size) for c in text]; total=sum(widths)+ls*(len(text)-1)
    out=[];pos=-total/2
    for ch,w in zip(text,widths):
        mid=pos+w/2; ang=mid/r  # radians from vertical
        if top:
            Px=50+r*math.sin(ang);Py=50-r*math.cos(ang);co=math.cos(ang);si=math.sin(ang)
            # glyph local (gx,gy) -> x=Px+gx*co+gy*si, y=Py+gx*si-gy*co ; gx measured from glyph centre
            mat=(co,si,si,-co,Px-(w/2)*co,Py-(w/2)*si)
        else:
            Px=50+r*math.sin(ang);Py=50+r*math.cos(ang);co=math.cos(ang);si=math.sin(ang)
            mat=(co,-si,-si,-co,Px-(w/2)*co,Py+(w/2)*si)
        out.append(draw(ch,size,(mat[0],mat[1],mat[2],mat[3],mat[4],mat[5])));pos+=w+ls
    return ' '.join(out)
def flat_text(text,cx,y,size,ls):
    widths=[adv(c,size) for c in text];total=sum(widths)+ls*(len(text)-1);x=cx-total/2;out=[]
    for ch,w in zip(text,widths):
        out.append(draw(ch,size,(1,0,0,-1,x,y)));x+=w+ls
    return ' '.join(out)
def dia(x,y,s=1.6): return f'<rect x="{x-s/2}" y="{y-s/2}" width="{s}" height="{s}" fill="{K}" transform="rotate(45 {x} {y})"/>'
def circ(r,sw=.6): return f'<circle cx="50" cy="50" r="{r}" fill="none" stroke="{K}" stroke-width="{sw}"/>'
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100" role="img" aria-label="Key Rewards">
<title>Key Rewards</title>
<defs><filter id="emb" x="-15%" y="-15%" width="130%" height="130%">
 <feGaussianBlur in="SourceAlpha" stdDeviation=".5" result="a"/>
 <feOffset in="a" dx="-1.2" dy="-1.4" result="ho"/><feComposite in="ho" in2="SourceAlpha" operator="out" result="h"/>
 <feFlood flood-color="#ffffff" flood-opacity=".95" result="hf"/><feComposite in="hf" in2="h" operator="in" result="hc"/>
 <feOffset in="a" dx="1.3" dy="1.5" result="so"/><feComposite in="so" in2="SourceAlpha" operator="out" result="s"/>
 <feFlood flood-color="#4d2c00" flood-opacity=".72" result="sf"/><feComposite in="sf" in2="s" operator="in" result="sc"/>
 <feMerge><feMergeNode in="sc"/><feMergeNode in="hc"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
<g filter="url(#emb)"><circle cx="50" cy="50" r="46" fill="none" stroke="{G}" stroke-opacity=".62" stroke-width="3"/></g>
{circ(48.2)}{circ(43.8)}{circ(29.4)}
<g fill="{K}" style="filter:drop-shadow(0 .5px 0 rgba(255,255,255,.7))">
<path d="{arc_text("RESTAURANT",33.6,8.8,1.1,True)}"/>
<path d="{arc_text("REWARDS",40.2,8.8,1.5,False)}"/>
<path d="{flat_text("RR",50,58.5,25,-.4)}"/>
</g>
{dia(13.7,50)}{dia(86.3,50)}
</svg>'''
open('sites/key-technologies/brand/rr-emboss-circle.svg','w').write(svg)
print(len(svg),'bytes')
