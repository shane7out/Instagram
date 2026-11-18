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
:root{--bg:#0f171e;--card:#1b2735;--line:#4a5d72;--ink:#ffffff;--key:#00a8e1;--key2:#7fd8f7;--good:#7fd8f7}
*{box-sizing:border-box}
html{font-size:100%%;-webkit-text-size-adjust:100%%}
body{margin:0;background:var(--bg);color:var(--ink);font:400 21px/1.45 Lato,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-font-smoothing:antialiased}
.demo{background:#10243a;color:#e3f0fc;font-size:15px;line-height:1.35;text-align:center;padding:8px 14px;border-bottom:1px solid #1f3d5c}
.demo b{color:#fff}
.wrapcol{max-width:480px;margin:0 auto;padding:0 18px}
header{display:flex;align-items:center;gap:12px;padding:14px 0 0}
header img{height:68px;width:auto}
header span{font-weight:900;font-size:20px;line-height:1.2}
.step{color:var(--key2);font-weight:900;letter-spacing:.05em;text-transform:uppercase;font-size:16px;margin:14px 0 6px}
.dots{display:flex;gap:8px;margin:0 0 16px}.dots i{flex:1;height:8px;border-radius:99px;background:#2d3e52}.dots i.on{background:var(--key)}
h1{font-size:32px;line-height:1.15;margin:0 0 10px;font-weight:900;letter-spacing:-.01em}
p{margin:0 0 12px;color:#e9f1f8}
.say{font-size:22px;line-height:1.4;color:#fff;font-weight:700}
.wallet{background:var(--card);border:3px solid var(--key);border-radius:18px;padding:12px 16px;margin:12px 0;text-align:center}
.wallet small{display:block;color:#e9f1f8;font-size:18px;font-weight:700}
.wallet .num{font-size:30px;font-weight:900;line-height:1.02;color:var(--key2);letter-spacing:-.03em}
.wallet .num span{display:block;font-size:16px;font-weight:700;color:#e9f1f8;letter-spacing:0;margin-top:0}
.wallet.small .num{font-size:26px}
.cust{background:var(--card);border:2px solid var(--line);border-radius:20px;padding:10px 18px;margin:10px 0;display:flex;flex-direction:column;align-items:center;text-align:center;gap:2px}
.cust b{font-size:21px}.cust .n{font-size:22px;font-weight:900;color:var(--good);line-height:1}.cust .n{text-align:center}.cust .n small{display:block;font-size:16px;color:#e9f1f8;font-weight:700;margin-top:4px}
.btn{display:block;width:100%%;min-height:62px;margin:14px 0 0;padding:12px 18px;border:0;border-radius:16px;background:var(--key);color:#0f171e;font:900 22px Lato,system-ui,sans-serif;cursor:pointer}
.btn:active{background:#33bce8}.btn:focus-visible{outline:5px solid #fff;outline-offset:4px}
.btn.ghost{background:transparent;color:#fff;border:3px solid #7d90a5;min-height:54px;font-size:20px}
ul.big{list-style:none;padding:0;margin:12px 0 0}ul.big li{padding:12px 0 12px 44px;position:relative;border-bottom:2px solid var(--line);color:#fff;font-size:21px;line-height:1.35}
ul.big li::before{content:"✓";position:absolute;left:6px;color:var(--good);font-weight:900;font-size:28px;top:7px}
.fine{font-size:15px;line-height:1.45;color:#cfdbe7;margin-top:18px;padding-bottom:30px}
.hide{display:none}
.redeemrow{display:flex;gap:10px;margin-top:14px;align-items:stretch}
.redeemrow input{flex:1.3;min-width:0;font:900 26px Lato,system-ui,sans-serif;padding:10px 12px;border-radius:14px;border:2px solid #7d90a5;background:#0f171e;color:#fff;text-align:center}
.redeemrow input::placeholder{color:#8fa2b6;font-weight:400;font-size:19px}
.redeemrow input:focus-visible{outline:4px solid var(--key2);outline-offset:2px}
.redeemrow .btn{flex:1;margin:0;width:auto;min-height:60px}
.lab{display:block;color:#e9f1f8;font-size:18px;font-weight:700;margin:14px 0 6px}
.linkbtn{display:block;margin:8px auto 0;padding:10px;background:none;border:0;color:var(--key2);font:700 18px Lato,system-ui,sans-serif;text-decoration:underline;cursor:pointer}
.err{color:#ffb84d;font-weight:700;font-size:18px;text-align:center;margin:6px 0 0;min-height:24px}
.result{color:var(--good);font-size:20px;line-height:1.35;font-weight:900;text-align:center;margin:10px 0 0}
.rotate{display:none;position:fixed;inset:0;z-index:99;background:#0f171e;color:#fff;align-items:center;justify-content:center;text-align:center;padding:30px;font-size:30px;font-weight:900;line-height:1.3}
.rotate div{max-width:420px}.rotate small{display:block;font-size:22px;font-weight:400;margin-top:10px;color:#e9f1f8}
@media (orientation:landscape) and (max-height:520px){.rotate{display:flex}}
@media (prefers-reduced-motion:no-preference){.pop{animation:pop .5s ease}@keyframes pop{0%%{transform:scale(.96);opacity:.5}100%%{transform:scale(1);opacity:1}}}
'''

def page(c):
    cfg = json.dumps(c['js'])
    logo = '<img src="%s" alt="" width="72" height="68">' % c['logo'] if c.get('logo') else ''
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
 var C=%(cfg)s,cur=1,wallet,alex,rest,secs=[1,2,3,4].map(function(i){return document.getElementById('s'+i)}),dots=document.querySelectorAll('.dots i'),lab=document.getElementById('stepLabel');
 function $(i){return document.getElementById(i)}
 function fmt(c){return (c/100).toFixed(2)}
 function R(el,c){if(el)el.innerHTML=fmt(c)+'<span>Restaurant Rewards</span>'}
 function P(el,c){el.innerHTML=fmt(c)+'<small>Restaurant Rewards</small>'}
 function paint(){R($('w2'),wallet);P($('c2'),alex);R($('w3'),wallet);P($('c3'),alex);R($('r3'),rest);R($('w4'),wallet)}
 function show(n){cur=n;secs.forEach(function(s,i){s.classList.toggle('hide',i!==n-1)});[].forEach.call(dots,function(d,i){d.classList.toggle('on',i<n)});lab.textContent='Step '+n+' of 4';window.scrollTo(0,0);var h=secs[n-1].querySelector('h1');if(h){h.setAttribute('tabindex','-1');h.focus({preventScroll:true})}}
 function reset(){wallet=C.start;alex=0;rest=C.restStart;paint();$('earn').classList.remove('hide');$('n2').classList.add('hide');$('m2').classList.add('hide');$('m3').classList.add('hide');$('rbox').classList.remove('hide');$('n3').classList.add('hide');$('amt').value='';$('err').textContent=''}
 [].forEach.call(document.querySelectorAll('[data-next]'),function(b){b.addEventListener('click',function(){show(cur+1)})});
 $('earn').addEventListener('click',function(){wallet-=C.give;alex=C.give;paint();$('m2').textContent=C.m2;$('m2').classList.remove('hide');this.classList.add('hide');$('n2').classList.remove('hide');$('n2').focus()});
 function parse(v){v=String(v).replace(/[$,\s]/g,'');if(!/^\d+(\.\d{1,2})?$/.test(v))return null;return Math.round(parseFloat(v)*100)}
 function redeem(){
  var a=parse($('amt').value);
  if(a===null||a<=0){$('err').textContent='Please type an amount, like 83.17';$('amt').focus();return}
  if(a>alex){$('err').textContent='Alex only has '+fmt(alex)+'. Please type a smaller amount.';$('amt').focus();return}
  $('err').textContent='';alex-=a;if(C.toRest){rest+=a}else{wallet+=a}paint();
  $('m3').textContent='Alex used '+fmt(a)+' Restaurant Rewards. '+C.m3;$('m3').classList.remove('hide');$('rbox').classList.add('hide');$('n3').classList.remove('hide');$('n3').focus()}
 $('redeem').addEventListener('click',redeem);
 $('amt').addEventListener('keydown',function(e){if(e.key==='Enter'){e.preventDefault();redeem()}});
 $('all').addEventListener('click',function(){$('amt').value=fmt(alex);redeem()});
 $('again').addEventListener('click',function(){reset();show(1)});
 reset();
})();
</script>
</body>
</html>
'''.replace('%(cfg)s', cfg) % dict(title=c['title'], css=CSS % (), banner=c['banner'], logo=logo, head=c['head'], body=body)

JOHNNY_BODY = '''<section id="s1">
<h1>This is your wallet.</h1>
<p class="say">500 Restaurant Rewards are in it for Johnny Mac's.</p>
<div class="wallet"><small>Your wallet</small><div class="num">500.00<span>Restaurant Rewards</span></div></div>
<p>Customers earn Restaurant Rewards from your wallet when they eat with you.</p>
<button class="btn" type="button" data-next>Next</button>
</section>
<section id="s2" class="hide">
<h1>A customer earns Restaurant Rewards.</h1>
<p class="say">Alex eats at Johnny Mac's and sends in the receipt.</p>
<div class="wallet"><small>Your wallet</small><div class="num" id="w2" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c2" aria-live="polite"></span></div>
<p class="result hide pop" id="m2"></p>
<button class="btn" type="button" id="earn">Alex earns 150 Restaurant Rewards</button>
<button class="btn hide" type="button" data-next id="n2">Next</button>
</section>
<section id="s3" class="hide">
<h1>The customer uses them here.</h1>
<p class="say">Alex types how many to use, then taps Redeem.</p>
<div class="wallet"><small>Your wallet</small><div class="num" id="w3" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c3" aria-live="polite"></span></div>
<p class="result hide pop" id="m3"></p>
<div id="rbox"><label class="lab" for="amt">How many Restaurant Rewards does Alex use?</label>
<div class="redeemrow"><input id="amt" type="text" inputmode="decimal" autocomplete="off" placeholder="Type an amount, like 83.17" aria-describedby="err"><button class="btn" type="button" id="redeem">Redeem</button></div>
<button class="linkbtn" type="button" id="all">Use all of Alex's Restaurant Rewards</button>
<p class="err" id="err" role="alert"></p></div>
<button class="btn hide" type="button" data-next id="n3">Next</button>
</section>
<section id="s4" class="hide">
<h1>That's it.</h1>
<p class="say">The Restaurant Rewards Alex used went back into your wallet.</p>
<div class="wallet"><small>Your wallet</small><div class="num" id="w4"></div></div>
<ul class="big"><li>Alex got free food and will come back.</li><li>You see every Restaurant Reward used, and when.</li><li>Nothing to install. Nothing to learn.</li></ul>
<button class="btn ghost" type="button" id="again">Show me again</button>
<p class="fine">Restaurant Rewards are a free perk for customers, with no cash value. This demo uses made-up numbers. The final details are agreed with each restaurant.</p>
</section>'''

LVMPD_BODY = '''<section id="s1">
<h1>This is the LVMPD wallet.</h1>
<p class="say">777 Restaurant Rewards are in it.</p>
<div class="wallet"><small>LVMPD wallet</small><div class="num">777.00<span>Restaurant Rewards</span></div></div>
<p>Restaurant Rewards from this wallet can be used at restaurants in the Restaurant Rewards network.</p>
<button class="btn" type="button" data-next>Next</button>
</section>
<section id="s2" class="hide">
<h1>A person gets Restaurant Rewards.</h1>
<p class="say">Alex receives 150 Restaurant Rewards from the LVMPD wallet.</p>
<div class="wallet"><small>LVMPD wallet</small><div class="num" id="w2" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c2" aria-live="polite"></span></div>
<p class="result hide pop" id="m2"></p>
<button class="btn" type="button" id="earn">Alex gets 150 Restaurant Rewards</button>
<button class="btn hide" type="button" data-next id="n2">Next</button>
</section>
<section id="s3" class="hide">
<h1>They use them at a restaurant.</h1>
<p class="say">At Johnny Mac's, Alex types how many to use, then taps Redeem.</p>
<div class="wallet small"><small>LVMPD wallet</small><div class="num" id="w3" aria-live="polite"></div></div>
<div class="cust"><b>Alex</b><span class="n" id="c3" aria-live="polite"></span></div>
<div class="wallet small"><small>Johnny Mac's wallet</small><div class="num" id="r3" aria-live="polite"></div></div>
<p class="result hide pop" id="m3"></p>
<div id="rbox"><label class="lab" for="amt">How many Restaurant Rewards does Alex use?</label>
<div class="redeemrow"><input id="amt" type="text" inputmode="decimal" autocomplete="off" placeholder="Type an amount, like 83.17" aria-describedby="err"><button class="btn" type="button" id="redeem">Redeem</button></div>
<button class="linkbtn" type="button" id="all">Use all of Alex's Restaurant Rewards</button>
<p class="err" id="err" role="alert"></p></div>
<button class="btn hide" type="button" data-next id="n3">Next</button>
</section>
<section id="s4" class="hide">
<h1>That's it.</h1>
<p class="say">The Restaurant Rewards Alex used moved into the restaurant's wallet.</p>
<ul class="big"><li>Alex got a free meal.</li><li>The restaurant got the Restaurant Rewards.</li><li>You can see where every Restaurant Reward went.</li><li>Any restaurant that joins accepts the same Restaurant Rewards.</li></ul>
<button class="btn ghost" type="button" id="again">Show me again</button>
<p class="fine"><b>Example only.</b> This page is not affiliated with and is not endorsed by the Las Vegas Metropolitan Police Department. Restaurant Rewards are a free perk with no cash value. All names and numbers are made up to show the idea.</p>
</section>'''

PAGES = [
 (os.path.join(SITE, 'johnny-macs-demo/wallet.html'), dict(title="Johnny Mac's Wallet Demo", head="Johnny Mac's Wallet", logo='img/logo.png',
   banner="Sample people and sample numbers. Nothing here is real or connected to a bank or a register.", body=JOHNNY_BODY,
   js=dict(start=50000, give=15000, restStart=0, toRest=False, m2='150 Restaurant Rewards moved from your wallet to Alex.', m3='They went back into your wallet.'))),
 (os.path.join(SITE, 'lvmpd-demo/index.html'), dict(title="LVMPD Wallet Example", head="LVMPD Wallet (example)", logo='',
   banner="Example only, made-up numbers. Not affiliated with or endorsed by LVMPD.", body=LVMPD_BODY,
   js=dict(start=77700, give=15000, restStart=0, toRest=True, m2='150 Restaurant Rewards moved from the LVMPD wallet to Alex.', m3='They went into Johnny Mac\'s wallet.'))),
]
for path, c in PAGES:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf8').write(page(c))
    print('wrote', os.path.relpath(path, ROOT), os.path.getsize(path), 'bytes')
