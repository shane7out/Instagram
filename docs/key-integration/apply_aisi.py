#!/usr/bin/env python3
"""Shane (2026-11-21): 'I would like to see AI/SI everywhere.'
Turns the standalone word AI into AI/SI in the visible text, titles, descriptions, alt text and JSON-LD of every page and in llms.txt.
Run it LAST in the generator order (add_light_look.py calls it), so regenerated pages get it again. Safe to run twice (AI/SI is never touched).
Left alone on purpose:
  * the two explainer guides that define AI and superintelligence separately (guides/what-is-ai-si.html, guides/ai-terms-plain-english.html),
  * the fixed phrases "AI and superintelligence", "AI or superintelligence" and "(AI)" (they define the words),
  * <script> code, <style>, comments, links, ids, classes, file names, URLs,
  * a <title> that would become longer than 70 characters (the site check limit)."""
import re, sys, html
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2] / 'sites' / 'key-technologies'
SKIP = {'guides/what-is-ai-si.html', 'guides/ai-terms-plain-english.html'}
AI = re.compile(r'(?<![A-Za-z0-9/_.\-])AI(?![A-Za-z0-9/])(?!\s*/\s*S)')
# a text that explains AI and SI as two separate things is left exactly as written
DEF = re.compile(r'\bSI is\b|\bSI side\b|\bAI side\b|\bAI is artificial|Artificial Intelligence\s*/|\bAI\s*/\s*SI\b|AI\)? that|\(AI/SI:|\bSI\b[^.<]{0,40}superintelligen', re.I)
KEEP = ['AI and superintelligence', 'AI or superintelligence', 'artificial intelligence (AI)', 'Artificial Intelligence (AI)', '(AI)']
def conv(t):
    if DEF.search(t): return t
    t = t.replace('AI Solutions company (AI/SI)', 'AI/SI Solutions company')
    hold = {}
    for i, k in enumerate(KEEP):
        ph = '\u0001%d\u0002' % i
        if k in t: t = t.replace(k, ph); hold[ph] = k
    t = AI.sub('AI/SI', t)
    for ph, k in hold.items(): t = t.replace(ph, k)
    return t
ATTR = re.compile(r'(\s(?:content|alt|aria-label|title|placeholder|aria-description)=")([^"]*)(")')
SEG = re.compile(r'(<script\b[^>]*>.*?</script>|<style\b[^>]*>.*?</style>|<!--.*?-->|<[^>]+>)', re.S)
def page(s):
    out = []
    for seg in SEG.split(s):
        if not seg: continue
        if seg.startswith('<!--') or seg.lower().startswith('<style'): out.append(seg)
        elif seg.lower().startswith('<script'):
            m = re.match(r'(<script\b[^>]*>)(.*)(</script>)$', seg, re.S | re.I)
            out.append(m.group(1) + re.sub(r'"((?:[^"\\]|\\.)*)"', lambda q: '"' + conv(q.group(1)) + '"', m.group(2)) + m.group(3) if m and 'ld+json' in m.group(1).lower() else seg)
        elif seg.startswith('<'):
            out.append(ATTR.sub(lambda m: m.group(1) + conv(m.group(2)) + m.group(3), seg))
        else: out.append(conv(seg))
    s2 = ''.join(out)
    # keep <title> within 70 characters; if the new one is too long, put the old title (and the matching og/twitter titles) back
    t_old = re.search(r'<title>(.*?)</title>', s, re.S); t_new = re.search(r'<title>(.*?)</title>', s2, re.S)
    if t_old and t_new and len(html.unescape(t_new.group(1).strip())) > 70 >= len(html.unescape(t_old.group(1).strip())):
        s2 = s2.replace(t_new.group(0), t_old.group(0), 1)
        for prop in ('og:title', 'twitter:title'):
            mo = re.search(r'(<meta (?:property|name)="%s" content=")([^"]*)(")' % re.escape(prop), s); mn = re.search(r'(<meta (?:property|name)="%s" content=")([^"]*)(")' % re.escape(prop), s2)
            if mo and mn: s2 = s2.replace(mn.group(0), mo.group(0), 1)
    return s2
def main():
    n = 0; cnt = 0
    for f in sorted(ROOT.rglob('*.html')):
        rel = f.relative_to(ROOT).as_posix()
        if rel in SKIP: continue
        s = f.read_text(encoding='utf-8'); s2 = page(s)
        if s2 != s: f.write_text(s2, encoding='utf-8'); n += 1; cnt += len(AI.findall(s)) if False else 0
    ll = ROOT / 'llms.txt'
    if ll.exists():
        s = ll.read_text(encoding='utf-8'); s2 = conv(s)
        if s2 != s: ll.write_text(s2, encoding='utf-8'); n += 1
    print('AI/SI applied on', n, 'file(s)')
if __name__ == '__main__': main()
