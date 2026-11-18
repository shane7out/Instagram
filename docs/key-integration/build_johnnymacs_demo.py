#!/usr/bin/env python3
"""Builds the Johnny Mac's DEMO page for keytechnologies.si: the real Johnny Mac's site
(sites/johnny-macs/index.html) with a Restaurant Rewards section built in, using SAMPLE data only.
Output: sites/key-technologies/johnny-macs-demo/index.html (+ img/). Unlisted and noindex until the client agrees.
Run: python3 sites/johnny-macs/build.py && python3 docs/key-integration/build_johnnymacs_demo.py
"""
import os, shutil
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../..'))
SRC = os.path.join(ROOT, 'sites/johnny-macs')
OUT = os.path.join(ROOT, 'sites/key-technologies/johnny-macs-demo')
s = open(os.path.join(SRC, 'index.html'), encoding='utf8').read()

def sub(a, b, count=1):
    global s
    assert a in s, a[:60]
    s = s.replace(a, b, count)

sub('<title>', '<meta name="robots" content="noindex,nofollow"><link rel="stylesheet" href="/fonts/lato.css"><title>')
sub('<title>Johnny Mac\'s Sports Bar &amp; Grill | Henderson, NV | NY Pizza &amp; Buffalo Wings Since 1983</title>',
    '<title>Johnny Mac\'s Website and Rewards Demo | Key Technologies.si</title>')
sub('<nav><a href="#specials">Specials</a>', '<nav><a href="#rewards" class="keep">Rewards</a><a href="#specials">Specials</a>')

CSS = r'''
.demobar{background:#10243a;color:#cfe3f7;font-size:13.5px;text-align:center;padding:9px 14px;border-bottom:1px solid #1f3d5c}
.demobar b{color:#fff}.demobar a{color:#9fd0ff}.demobar .dm{display:flex;flex-wrap:wrap;gap:6px 18px;justify-content:center;margin-top:7px;font-weight:700;font-size:14.5px}.demobar .dm a{white-space:nowrap}
#rewards{--bg:#0f171e;--card:#232f3e;--line:#37475a;--ink:#f6f8fb;--mute:#aab9ca;--mint:#4fc8f0;--gold:#00a8e1;--green:#00a8e1;--r:14px;background:#0f171e;color:#f6f8fb;font-family:Lato,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;border-top:1px solid #37475a;border-bottom:1px solid #37475a}
#rewards h2,#rewards h3,#rewards b{font-family:inherit}#rewards h2{font-weight:900}
#where{background:#0f171e;padding-top:8px}
#rewards .btn,#rewards .offer button{color:#0f171e;font-family:inherit}#rewards .btn.ghost{color:#f6f8fb;background:transparent;border-color:#637283}
#rewards .offer button:disabled{background:transparent;color:#8c9bab;border-color:#37475a}
.byKey{display:flex;align-items:center;gap:8px;margin:0 0 14px;color:#aab9ca;font-size:13.5px}.byKey b{color:#4fc8f0}
.rw{display:grid;grid-template-columns:1fr 1fr;gap:22px;align-items:start}
.rwcard{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:22px}
.rwcard h3{margin:0 0 4px;font-size:21px}
.rwtag{display:inline-block;font-size:11px;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#111;background:var(--gold);border-radius:999px;padding:3px 10px;margin-bottom:10px}
.bal{display:flex;align-items:baseline;gap:8px;margin:6px 0 4px}.bal b{font-size:52px;line-height:1;color:var(--mint);letter-spacing:-.02em}.bal span{color:var(--mute)}
.rwmsg{min-height:22px;margin:8px 0 0;color:var(--gold);font-weight:700;font-size:14.5px}
.offer{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--line)}
.offer:last-child{border-bottom:0}.offer div{flex:1}.offer b{display:block}.offer span{color:var(--mute);font-size:14px}
.offer button{flex:none;font:700 14px inherit;font-family:inherit;border-radius:999px;border:2px solid var(--green);background:var(--green);color:#fff;padding:8px 14px;cursor:pointer}
.offer button:disabled{background:transparent;border-color:#3a3d3a;color:#8c8a7e;cursor:not-allowed}
.steps{list-style:none;margin:14px 0 0;padding:0;display:grid;gap:8px;color:#d8d5c8}
.steps li{padding-left:28px;position:relative}.steps li::before{content:"✓";position:absolute;left:0;color:var(--mint);font-weight:800}
.rwnote{color:var(--mute);font-size:13.5px;margin:14px 0 0}
.invite{margin-top:14px;padding:12px 14px;border:1px dashed #3a3d3a;border-radius:12px;color:var(--mute);font-size:14px}
.invite code{color:var(--ink);word-break:break-all}
@media(max-width:760px){.rw{grid-template-columns:1fr}.bal b{font-size:44px}}
'''
sub('</style>', CSS + '</style>')

BAR = ('<div class="demobar"><b>Demo.</b> A sample restaurant website built by <a href="https://keytechnologies.si/">Key Technologies</a> '
       'with Restaurant Rewards built in. Every member, balance and receipt below is sample data.<span class="dm"><a href="app.html">1. Working account demo</a><a href="../restaurant-rewards-treasury.html?demo=1">2. Rewards wallet and Treasury demo</a><a href="wallet.html">3. The 4 simple steps</a><a href="cards.html">4. Gold wallet card</a><a href="../restaurant-rewards-uses.html">5. What you can use RR for</a></span></div>')
sub('<body>\n', '<body>\n' + BAR + '\n')

SECTION = '''<section id="rewards"><div class="wrap">
 <h2>Restaurant Rewards</h2>
 <p class="byKey"><span>Powered by <b>Key Technologies</b>. Same wallet at every participating restaurant.</span></p>
 <p class="sub">Earn rewards every time you eat here, and use them for free food. One rewards balance that works at every participating restaurant.</p>
 <div class="rw">
  <div class="rwcard" aria-live="polite">
   <span class="rwtag">Sample member</span>
   <h3>Alex's rewards</h3>
   <div class="bal"><b id="rwBal">12</b><span>rewards</span></div>
   <p class="rwnote" style="margin:0">1 reward = $1 toward a free offer at a participating restaurant.</p>
   <div class="row" style="margin-top:14px"><button class="btn" type="button" id="rwEarn">Add a sample $10 receipt</button><button class="btn ghost" type="button" id="rwReset">Start over</button></div>
   <p class="rwmsg" id="rwMsg"></p>
   <div class="invite">Invite a friend, both of you earn. Sample link: <code>restaurantrewards.example/join/alex</code></div>
  </div>
  <div class="rwcard">
   <h3>Use your rewards here</h3>
   <div id="rwOffers"></div>
   <ul class="steps">
    <li>Earn 1 reward per $1 on a receipt we check.</li>
    <li>Use rewards for free food at participating restaurants.</li>
    <li>No password and no app to download.</li>
   </ul>
   <p class="rwnote">Rewards are a free perk with no cash value. Restaurant Rewards can be used for food, gratuity, dinner parties, special events, meet and greets and special invites. This is a free trial game and we are trying it out. Key Technologies is not responsible if the database has a problem, goes down, or anything is lost. Thank you for playing and for believing in the future of this technology. Real offers and amounts are set by each restaurant.</p>
  </div>
 </div>
</div></section>

'''
WHERE = '<section id="where"><div class="wrap"><div data-rr-where></div></div></section>\n<script src="/key-platform/rr-map.js"></script>\n\n'
sub('<section id="reviews">', SECTION + WHERE + '<section id="reviews">')

JS = r'''
(function(){
 var bal=12,START=12,OFFERS=[['Free Pickle Spears (6)','Appetizer',15],['Free French Bread with garlic butter','Appetizer',10],['Free 4-Finger Chicken Basket','Entree',30],['Free Cannoli','Dessert',8]];
 var el=document.getElementById('rwBal'),msg=document.getElementById('rwMsg'),box=document.getElementById('rwOffers');
 function say(t){msg.textContent=t}
 function draw(){
  el.textContent=bal;box.innerHTML='';
  OFFERS.forEach(function(o,i){var d=document.createElement('div');d.className='offer';
   d.innerHTML='<div><b></b><span></span></div><button type="button"></button>';
   d.querySelector('b').textContent=o[0];d.querySelector('span').textContent=o[1]+' · '+o[2]+' rewards';
   var b=d.querySelector('button');b.textContent='Use';b.disabled=bal<o[2];
   b.addEventListener('click',function(){if(bal>=o[2]){bal-=o[2];say('Sample only: you used '+o[2]+' rewards for "'+o[0]+'".');draw()}});
   box.appendChild(d)})}
 document.getElementById('rwEarn').addEventListener('click',function(){bal+=10;say('Sample only: +10 rewards from a checked $10 receipt.');draw()});
 document.getElementById('rwReset').addEventListener('click',function(){bal=START;say('');draw()});
 draw();
})();
'''
sub('</script>\n</body>', JS + '</script>\n</body>')

os.makedirs(os.path.join(OUT, 'img'), exist_ok=True)
for f in os.listdir(os.path.join(SRC, 'img')):
    shutil.copy(os.path.join(SRC, 'img', f), os.path.join(OUT, 'img', f))
open(os.path.join(OUT, 'index.html'), 'w', encoding='utf8').write(s)
print('wrote', os.path.join(OUT, 'index.html'), len(s), 'bytes')
