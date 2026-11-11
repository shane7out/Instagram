import os,re,sys,collections,html
from urllib.parse import urlparse,urldefrag
import os as _o
root=_o.environ.get('SITE_ROOT','sites/key-technologies')
_o.chdir(root); root='.'
pages=[]
for d,_,fs in os.walk(root):
    if '/fonts' in d: continue
    for f in fs:
        if f.endswith('.html'): pages.append(os.path.join(d,f)[2:])
pages.sort()
def read(p): return open(p,encoding='utf-8',errors='replace').read()
ids={}
for p in pages:
    t=read(p); ids[p]=set(re.findall(r'\bid=["\']([^"\']+)["\']',t))
titles=collections.defaultdict(list); issues=[]
sm=read('sitemap.xml'); smurls=set(re.findall(r'<loc>https?://[^/]+/?([^<]*)</loc>',sm))
for p in pages:
    t=read(p); noidx=bool(re.search(r'<meta[^>]+robots[^>]+noindex',t,re.I))
    ti=re.search(r'<title>(.*?)</title>',t,re.S); ti=html.unescape(ti.group(1).strip()) if ti else None
    titles[ti].append(p)
    if not ti: issues.append((p,'no title'))
    elif len(ti)>70: issues.append((p,f'title long {len(ti)}'))
    md=re.search(r'<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']*)',t,re.I)
    if not noidx:
        if not md: issues.append((p,'no meta description'))
        elif len(md.group(1))>170: issues.append((p,f'description long {len(md.group(1))}'))
        if not re.search(r'rel=["\']canonical',t): issues.append((p,'no canonical'))
        if p not in smurls and p!='index.html' and not p.startswith('guides/index') : issues.append((p,'indexable but not in sitemap'))
    h1=len(re.findall(r'<h1[\s>]',t))
    if h1!=1 and not noidx: issues.append((p,f'h1 count {h1}'))
    for m in re.finditer(r'<img\b[^>]*>',t):
        if not re.search(r'\balt=',m.group(0)): issues.append((p,'img without alt: '+m.group(0)[:70]))
    if not re.search(r'name=["\']viewport',t): issues.append((p,'no viewport'))
    if re.search(r'shane@keytechnologies\.si',t): issues.append((p,'EMAIL on page'))
    for w in re.findall(r'(?i)\b(affordable|budget[- ]friendly|cheap|\$\d+(?:\.\d\d)?\s*(?:/|per)\s*(?:mo|month|hour|hr))\b',re.sub(r'<script.*?</script>|<style.*?</style>','',t,flags=re.S)):
        issues.append((p,'price-ish wording: '+w))
    # links
    for m in re.finditer(r'\b(?:href|src)=["\']([^"\'#][^"\']*|#[^"\']*)["\']',t):
        u=m.group(1)
        if re.match(r'(https?:|mailto:|tel:|sms:|data:|javascript:|//)',u): continue
        base=os.path.dirname(p)
        path,frag=urldefrag(u)
        path=path.split('?')[0]
        if path=='' : tgt=p
        elif path.startswith('/'): tgt=path[1:]
        else: tgt=os.path.normpath(os.path.join(base,path))
        if tgt.endswith('/') or tgt=='' : tgt=os.path.join(tgt,'index.html')
        if not os.path.exists(tgt):
            if os.path.exists(tgt+'.html'): continue
            issues.append((p,'broken link: '+u)); continue
        if frag and tgt.endswith('.html') and tgt in ids and frag not in ids[tgt] and frag!='top':
            issues.append((p,f'missing anchor #{frag} in {tgt}'))
for ti,ps in titles.items():
    if ti and len(ps)>1: issues.append((','.join(ps[:4]),'duplicate title: '+ti[:60]))
for u in smurls:
    if u and not os.path.exists(u) and not os.path.exists(u+'.html') and not os.path.exists(os.path.join(u,'index.html')): issues.append(('sitemap.xml','sitemap URL missing file: '+u))
print(len(pages),'pages',len(issues),'issues')
c=collections.Counter(re.sub(r':.*','',i[1]) for i in issues); print(c)
for i in issues[:80]: print(i)

# the number of services quoted on the site must equal the real number of services (key-platform/demos/list.json)
import json as _j
_N=len(_j.load(open('key-platform/demos/list.json',encoding='utf-8')))
for p in pages:
    t=read(p)
    for m in re.finditer(r'<b>(\d+) services</b>|See all (\d+) (?:services|demos)|Open all (\d+) (?:services|demos)',t):
        n=int(m.group(1) or m.group(2) or m.group(3))
        if n!=_N: issues.append((p,'service count %d but the real number is %d (run docs/key-integration/sync_service_count.py)'%(n,_N)))
for _l in read('llms.txt').split('\n'):
    for m in re.finditer(r'all (\d+) services',_l):
        if int(m.group(1))!=_N: issues.append(('llms.txt','service count %s but the real number is %d'%(m.group(1),_N)))
HARD=('service count','broken link','missing anchor','no title','no meta description','no canonical','EMAIL on page','price-ish','img without alt','sitemap URL missing')
hard=[i for i in issues if i[1].startswith(HARD)]
print('HARD problems:',len(hard))
sys.exit(1 if hard else 0)
