#!/usr/bin/env python3
"""Builds the large-type, portrait, four-step wallet demos (sample numbers only, unlisted + noindex):
  sites/key-technologies/johnny-macs-demo/wallet.html   (Johnny Mac's, 500 rewards, redeemed rewards go back into his wallet)
  sites/key-technologies/lvmpd-demo/index.html          (example sponsor wallet, 777 rewards, redeemed rewards move to the restaurant's wallet)
Run from the repo root, anywhere in the chain before add_security_meta.py:  python3 docs/key-integration/build_wallet_demos.py
The LVMPD page is a clearly labeled EXAMPLE: no logo, no badge, "not affiliated with or endorsed by"."""
import os, json
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../..'))
SITE = os.path.join(ROOT, 'sites/key-technologies')

CSS = r'''
:root{--bg:#0f171e;--card:#1b2735;--line:#4a5d72;--ink:#ffffff;--key:#00a8e1;--key2:#7fd8f7;--good:#5fe49a}
*{box-sizing:border-box}
html{font-size:100%%;-webkit-text-size-adjust:100%%}
body{margin:0;background:var(--bg);color:var(--ink);font:400 26px/1.55 Lato,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-font-smoothing:antialiased}
.demo{background:#10243a;color:#e3f0fc;font-size:19px;line-height:1.4;text-align:center;padding:12px 16px;border-bottom:1px solid #1f3d5c}
.demo b{color:#fff}
.wrapcol{max-width:540px;margin:0 auto;padding:0 22px}
header{display:flex;align-items:center;gap:16px;padding:20px 0 0}
header img{height:64px;width:auto}
header span{font-weight:900;font-size:26px;line-height:1.2}
.step{color:var(--key2);font-weight:900;letter-spacing:.05em;text-transform:uppercase;font-size:22px;margin:22px 0 8px}
.dots{display:flex;gap:10px;margin:0 0 22px}.dots i{flex:1;height:10px;border-radius:99px;background:#2d3e52}.dots i.on{background:var(--key)}
h1{font-size:48px;line-height:1.12;margin:0 0 16px;font-weight:900;letter-spacing:-.01em}
p{margin:0 0 18px;color:#e9f1f8}
.say{font-size:30px;line-height:1.4;color:#fff;font-weight:700}
.wallet{background:var(--card);border:3px solid var(--key);border-radius:24px;padding:24px 26px;margin:22px 0}
.wallet small{display:block;color:#e9f1f8;font-size:24px;font-weight:700}
.wallet .num{font-size:128px;font-weight:900;line-height:1.02;color:var(--key2);letter-spacing:-.03em}
.wallet .num span{font-size:30px;font-weight:700;color:#e9f1f8;letter-spacing:0;margin-left:10px}
.wallet.small .num{font-size:96px}
.cust{background:var(--card);border:2px solid var(--line);border-radius:24px;padding:20px 26px;margin:16px 0;display:flex;justify-content:space-between;align-items:center;gap:12px}
.cust b{font-size:32px}.cust .n{font-size:56px;font-weight:900;color:var(--good);line-height:1}.cust .n small{font-size:24px;color:#e9f1f8;font-weight:700}
.ticket{border:4px dashed var(--good);border-radius:24px;padding:22px 26px;margin:18px 0;background:rgba(95,228,154,.10)}
.ticket b{display:block;font-size:34px;line-height:1.25}.ticket .code{font-size:54px;font-weight:900;letter-spacing:.1em;color:var(--good);margin-top:6px}
.btn{display:block;width:100%%;min-height:88px;margin:22px 0 0;padding:18px 22px;border:0;border-radius:22px;background:var(--key);color:#0f171e;font:900 32px Lato,system-ui,sans-serif;cursor:pointer}
.btn:active{background:#33bce8}.btn:focus-visible{outline:5px solid #fff;outline-offset:4px}
.btn.ghost{background:transparent;color:#fff;border:3px solid #7d90a5;min-height:72px;font-size:28px}
ul.big{list-style:none;padding:0;margin:12px 0 0}ul.big li{padding:18px 0 18px 58px;position:relative;border-bottom:2px solid var(--line);color:#fff;font-size:28px;line-height:1.35}
ul.big li::before{content:"✓";position:absolute;left:6px;color:var(--good);font-weight:900;font-size:38px;top:12px}
.fine{font-size:19px;line-height:1.45;color:#cfdbe7;margin-top:30px;padding-bottom:50px}
.hide{display:none}
.rotate{display:none;position:fixed;inset:0;z-index:99;background:#0f171e;color:#fff;align-items:center;justify-content:center;text-align:center;padding:30px;font-size:30px;font-weight:900;line-height:1.3}
.rotate div{max-width:420px}.rotate small{display:block;font-size:22px;font-weight:400;margin-top:10px;color:#e9f1f8}
@media (orientation:landscape) and (max-height:520px){.rotate{display:flex}}
@media (prefers-reduced-motion:no-preference){.pop{animation:pop .5s ease}@keyframes pop{0%%{transform:scale(.96);opacity:.5}100%%{transform:scale(1);opacity:1}}}
'''

def page(c):
    cfg = json.dumps(c['js'])
    logo = '<img src="%s" alt="" width="68" height="64">' % c['logo'] if c.get('logo') else ''
    body = c['body']
    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>%(title)s | Key Technologies.si</title>
<meta name="description" content="A simple four-step demo of how Restaurant Rewards move through a wallet. Sample numbers only.">
<meta name="theme-color" content="#0f171e">
<link rel="stylesheet" href="/fonts/lato.css">
<style>%(css)s</style>
</head>
<body>
<div class="rotate" role="alert"><div>Please turn your phone upright.<small>This page is made to be read standing up.</small></div></div>
<div class="demo"><b>Demo.</b> %(banner)s</div>
<div class="wrapcol">
<header>%(logo)s<span>%(head)s</span></header>
<main>
<div class="step" id="stepLabel">Step 1 of 4</div>
<div class="dots" aria-hidden="true"><i class="on"></i><i></i><i></i><i></i></div>
%(body)s
</main>
</div>
<script>
(function(){
 var C=%(cfg)s,cur=1,secs=[1,2,3,4].map(function(i){return document.getElementById('s'+i)}),dots=document.querySelectorAll('.dots i'),lab=document.getElementById('stepLabel');
 function $(i){return document.getElementById(i)}
 function R(el,v){el.innerHTML=v+'<span>rewards</span>'}
 function P(el,v){el.innerHTML=v+' <small>rewards</small>'}
 function show(n){cur=n;secs.forEach(function(s,i){s.classList.toggle('hide',i!==n-1)});[].forEach.call(dots,function(d,i){d.classList.toggle('on',i<n)});lab.textContent='Step '+n+' of 4';window.scrollTo(0,0);var h=secs[n-1].querySelector('h1');if(h){h.setAttribute('tabindex','-1');h.focus({preventScroll:true})}}
 function reset(){R($('w2'),C.start);P($('c2'),0);R($('w3'),C.start-C.give);P($('c3'),C.give);if($('r3'))R($('r3'),C.restStart);
  $('earn').classList.remove('hide');$('n2').classList.add('hide');$('redeem').classList.remove('hide');$('ticket').classList.add('hide');$('n3').classList.add('hide')}
 [].forEach.call(document.querySelectorAll('[data-next]'),function(b){b.addEventListener('click',function(){show(cur+1)})});
 $('earn').addEventListener('click',function(){R($('w2'),C.start-C.give);P($('c2'),C.give);this.classList.add('hide');$('n2').classList.remove('hide');$('n2').focus()});
 $('redeem').addEventListener('click',function(){P($('c3'),0);R($('w3'),C.afterRedeemWallet);if($('r3'))R($('r3'),C.restStart+C.give);this.classList.add('hide');$('ticket').classList.remove('hide');$('n3').classList.remove('hide');$('n3').focus()});
 $('again').addEventListener('click',function(){reset();show(1)});
 reset();
})();
</script>
</body>
</html>
''' % dict(title=c['title'], css=CSS % (), banner=c['banner'], logo=logo, head=c['head'], body=body, cfg=cfg)

JOHNNY_BODY = '''<section id="s1">
<h1>This is your wallet.</h1>
<p class="say">500 Restaurant Rewards are in it for Johnny Mac's.</p>
<div class="wallet"><small>Your wallet</small><div class="num">500<span>rewards</span></div></div>
<p>Customers earn rewards from your wallet when they eat with you.</p>
<button class="btn" type="button" data-next>Next</button>
</section>
<section id="s2" class="hide">
<h1>A customer earns rewards.</h1>
<p class="say">Alex eats at Johnny Mac's and sends in the receipt.</p>
<div class="wallet"><small>Your wallet</small><div class="num" id="w2" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c2" aria-live="polite"></span></div>
<button class="btn" type="button" id="earn">Alex earns 15 rewards</button>
<button class="btn hide" type="button" data-next id="n2">Next</button>
</section>
<section id="s3" class="hide">
<h1>The customer uses them here.</h1>
<p class="say">Alex wants free Mozzarella Sticks. Alex taps Redeem.</p>
<div class="wallet"><small>Your wallet</small><div class="num" id="w3" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c3" aria-live="polite"></span></div>
<button class="btn" type="button" id="redeem">Alex taps Redeem</button>
<div class="ticket hide pop" id="ticket"><b>Free Mozzarella Sticks (5)</b>Show this code to your server:<div class="code">JM-4F7K</div></div>
<button class="btn hide" type="button" data-next id="n3">Next</button>
</section>
<section id="s4" class="hide">
<h1>That's it.</h1>
<p class="say">The 15 rewards Alex used went back into your wallet.</p>
<div class="wallet"><small>Your wallet</small><div class="num">500<span>rewards</span></div></div>
<ul class="big"><li>Alex got free food and will come back.</li><li>You see every reward used, and when.</li><li>Nothing to install. Nothing to learn.</li></ul>
<button class="btn ghost" type="button" id="again">Show me again</button>
<p class="fine">Restaurant Rewards are a free perk for customers, with no cash value. This demo uses made-up numbers. The final details are agreed with each restaurant.</p>
</section>'''

LVMPD_BODY = '''<section id="s1">
<h1>This is the LVMPD wallet.</h1>
<p class="say">777 Restaurant Rewards are in it.</p>
<div class="wallet"><small>LVMPD wallet</small><div class="num">777<span>rewards</span></div></div>
<p>Rewards from this wallet can be used at restaurants in the Restaurant Rewards network.</p>
<button class="btn" type="button" data-next>Next</button>
</section>
<section id="s2" class="hide">
<h1>A person gets rewards.</h1>
<p class="say">Alex receives 15 rewards from the LVMPD wallet.</p>
<div class="wallet"><small>LVMPD wallet</small><div class="num" id="w2" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c2" aria-live="polite"></span></div>
<button class="btn" type="button" id="earn">Alex gets 15 rewards</button>
<button class="btn hide" type="button" data-next id="n2">Next</button>
</section>
<section id="s3" class="hide">
<h1>They use them at a restaurant.</h1>
<p class="say">At Johnny Mac's, Alex taps Redeem for free Mozzarella Sticks.</p>
<div class="wallet small"><small>LVMPD wallet</small><div class="num" id="w3" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c3" aria-live="polite"></span></div>
<div class="wallet small"><small>Johnny Mac's wallet</small><div class="num" id="r3" aria-live="polite"></div></div>
<button class="btn" type="button" id="redeem">Alex taps Redeem</button>
<div class="ticket hide pop" id="ticket"><b>Free Mozzarella Sticks (5)</b>Show this code to the server:<div class="code">JM-4F7K</div></div>
<button class="btn hide" type="button" data-next id="n3">Next</button>
</section>
<section id="s4" class="hide">
<h1>That's it.</h1>
<p class="say">The 15 rewards moved into the restaurant's wallet.</p>
<ul class="big"><li>Alex got a free meal.</li><li>The restaurant got the rewards.</li><li>You can see where every reward went.</li><li>Any restaurant that joins accepts the same rewards.</li></ul>
<button class="btn ghost" type="button" id="again">Show me again</button>
<p class="fine"><b>Example only.</b> This page is not affiliated with and is not endorsed by the Las Vegas Metropolitan Police Department. Restaurant Rewards are a free perk with no cash value. All names and numbers are made up to show the idea.</p>
</section>'''

PAGES = [
 (os.path.join(SITE, 'johnny-macs-demo/wallet.html'), dict(title="Johnny Mac's Wallet Demo", head="Johnny Mac's Wallet", logo='img/logo.png',
   banner="Sample people and sample numbers. Nothing here is real or connected to a bank or a register.", body=JOHNNY_BODY,
   js=dict(start=500, give=15, afterRedeemWallet=500, restStart=0))),
 (os.path.join(SITE, 'lvmpd-demo/index.html'), dict(title="LVMPD Wallet Example", head="LVMPD Wallet (example)", logo='',
   banner="Example only, made-up numbers. Not affiliated with or endorsed by LVMPD.", body=LVMPD_BODY,
   js=dict(start=777, give=15, afterRedeemWallet=762, restStart=0))),
]
for path, c in PAGES:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf8').write(page(c))
    print('wrote', os.path.relpath(path, ROOT), os.path.getsize(path), 'bytes')
