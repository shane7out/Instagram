#!/usr/bin/env python3
"""Shane (2026-11-27): "we can soften back up on the S side. Don't need to put it everywhere like we said before. More of it should just
be in the AI, but every once in a while I splash it in the SI, of course, with the domain, but for the most part we just call it AI."
This REPLACES the 2026-11-21 version ("AI/SI everywhere"). The file keeps its name because add_light_look.py runs it last on every rebuild.
It turns AI/SI into plain AI in the visible text, titles, descriptions, alt text and JSON-LD of every page, in llms.txt, list.json and the demo widgets.
Where AI/SI STAYS (the occasional splash, on purpose):
  * the domain and brand (Key Technologies.si is not touched),
  * the three service names that carry it: "AI/SI Strategy", "AI/SI Agents", "Custom AI/SI Systems",
  * any text that explains the words (it mentions Artificial Intelligence or Superintelligence), e.g. the home page eyebrow,
  * the two explainer guides guides/what-is-ai-si.html and guides/ai-terms-plain-english.html,
  * <script> code, <style>, comments, links, ids, classes, file names and URLs.
Safe to run twice."""
import re, html
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2] / 'sites' / 'key-technologies'
SKIP = {'guides/what-is-ai-si.html', 'guides/ai-terms-plain-english.html'}
KEEP = ['Custom AI/SI Systems', 'AI/SI Strategy', 'AI/SI Agents']
EXPLAIN = re.compile(r'super\s*intelligen|artificial intelligence', re.I)
def conv(t):
    if 'AI/SI' not in t or EXPLAIN.search(t): return t
    hold = {}
    for i, k in enumerate(KEEP):
        ph = '\u0001%d\u0002' % i
        if k in t: t = t.replace(k, ph); hold[ph] = k
    t = t.replace('AI/SI', 'AI')
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
    return ''.join(out)
def main():
    n = 0
    for f in sorted(ROOT.rglob('*.html')):
        rel = f.relative_to(ROOT).as_posix()
        if rel in SKIP: continue
        s = f.read_text(encoding='utf-8'); s2 = page(s)
        if s2 != s: f.write_text(s2, encoding='utf-8'); n += 1
    for rel in ('llms.txt', 'key-platform/demos/list.json'):
        f = ROOT / rel
        if f.exists():
            s = f.read_text(encoding='utf-8'); s2 = conv(s)
            if s2 != s: f.write_text(s2, encoding='utf-8'); n += 1
    f = ROOT / 'key-platform' / 'demo-widgets.js'
    if f.exists():
        lines = f.read_text(encoding='utf-8').split('\n'); out = [conv(l) for l in lines]
        if out != lines: f.write_text('\n'.join(out), encoding='utf-8'); n += 1
    print('AI softened on', n, 'file(s)')
if __name__ == '__main__': main()
