#!/usr/bin/env python3
"""Builds the Johnny Mac's site from the facts on johnnymacswings.com.
  index.html            -> images by relative path (img/...)
  single (for dashboard hosting) -> ../../.github/db-task/fetched/johnny-macs-single.html, images inlined
Run:  python3 sites/johnny-macs/build.py
"""
import base64, html, json, os, re
HERE = os.path.dirname(os.path.abspath(__file__))
E = html.escape

LOCS = [
 dict(id='boulder', name='Boulder Highway', addr='842 S Boulder Hwy', city='Henderson, NV 89015', tel='702-564-2121',
      hours=[('Mon – Thu','11:00 AM – 10:00 PM'),('Friday','11:00 AM – 11:00 PM'),('Saturday','11:00 AM – 10:00 PM'),('Sunday','11:00 AM – 9:00 PM')],
      order=('Order online','https://toasttab.com/johnny-mac-s/'), note='Delivery 11 AM – 8 PM daily. Pickup and delivery: call the restaurant.',
      sched={0:(660,1320),1:(660,1320),2:(660,1320),3:(660,1320),4:(660,1380),5:(660,1320),6:(660,1260)}, tz='America/Los_Angeles'),
 dict(id='water', name='Water Street Tavern', addr='117 S Water Street', city='Henderson, NV 89015', tel='725-214-7317',
      hours=[('Mon – Thu','10:00 AM – 10:00 PM'),('Fri &amp; Sat','9:00 AM – 12:00 AM'),('Sunday','9:00 AM – 10:00 PM')],
      order=('Order online','https://toasttab.com/waterstreet/'), note='Live band every Friday &amp; Saturday, 8 PM – 12 AM. Bar open until 2 AM.',
      sched={0:(600,1320),1:(600,1320),2:(600,1320),3:(600,1320),4:(540,1440),5:(540,1440),6:(540,1320)}, tz='America/Los_Angeles'),
 dict(id='cedar', name='Cedar City, Utah', addr='2605 N Main St #130', city='Cedar City, UT 84721', tel='435-708-0220',
      hours=[('Mon – Thu','11:00 AM – 10:00 PM'),('Friday','11:00 AM – 11:00 PM'),('Saturday','11:00 AM – 10:00 PM'),('Sunday','11:00 AM – 9:00 PM')],
      order=None, note='Our newest location. Call to order.',
      sched={0:(660,1320),1:(660,1320),2:(660,1320),3:(660,1320),4:(660,1380),5:(660,1320),6:(660,1260)}, tz='America/Denver'),
]

# Monday-first specials, exactly as printed on their site
SPECIALS = [
 ('Monday','Homemade Meatloaf','Served with mashed potatoes and gravy and mixed veggies'),
 ('Tuesday','Corned Beef and Cabbage','Best in town. Served piled high with cabbage and red potatoes'),
 ('Wednesday','Half-Price Pizza','Buffalo New York famous pizza. 1/2 off pizza (dine in only, no take out or delivery)'),
 ('Thursday','2 for 1 Spaghetti and Meatballs','House meatballs in our signature tomato sauce'),
 ('Friday','Pub Style Fish Fry','With coleslaw, French fries and a side of tartar sauce. Also: beer battered jumbo shrimp basket, and Buffalo’s famous roast beef on a Kimmelweck roll'),
 ('Saturday','Buffalo’s Famous Roast Beef','On a Kimmelweck roll, served with au jus, horseradish and French fries'),
 ('Sunday','Buffalo’s Famous Roast Beef','On a Kimmelweck roll, served with au jus, horseradish and French fries. Also: 16” 1 item pizza, your choice of 1 topping'),
]

MENU = [
 ('Daily Deals','',[
  ('Henderson Special','5 lbs. of wings and a large 1-topping pizza'),
  ('Small Henderson Special','2 lbs. of wings and a small 1-topping pizza'),
  ('Family Night Special','5 lbs. of wings, a large 1-topping pizza and a large house or Caesar salad'),
  ('Johnny Mac’s Famous Ribs','Fall-off-the-bone pork short ribs drenched in BBQ sauce, served with coleslaw'),
  ('Beer Battered Shrimp Basket','Hand-battered Mexican white jumbo shrimp, served with coleslaw and French fries')]),
 ('Appetizers','',[
  ('Homemade Mozzarella Sticks (5)',''),('Italian Panko Breaded Zucchini Sticks (6)',''),
  ('French Bread','With garlic butter, melted mozzarella cheese and tomato slices'),
  ('Homemade New England Clam Chowder','Friday only'),('Deep Fried Panko Breaded Pickle Spears (6)','')]),
 ('House Salads','',[
  ('Johnny Mac’s House Salad','Fresh greens, tomatoes, celery, carrots, green olives, pepperoncini, homemade croutons'),
  ('Caesar Salad','Fresh hearts of romaine lettuce and classic Caesar dressing'),
  ('Antipasto Salad','Fresh greens topped with our signature mixture of meats and cheeses'),
  ('Johnny Mac’s Chicken Salad','House salad with your choice of grilled chicken breast or crispy chicken tenders')]),
 ('Chicken Fingers','All of our fingers are tossed with your choice of any signature sauce.',[
  ('4-Finger Basket','Served with French fries, or substitute onion rings'),
  ('8-Finger Basket','Served with celery sticks and ranch or bleu cheese dressing')]),
 ('Signature Subs','All subs are on a toasted hoagie roll and served with chips. Sub fries or onion rings.',[
  ('Johnny Mac Chicken','Crispy chicken tenders tossed in your choice of sauce, lettuce, tomato, provolone and American cheese, signature creamy Italian and mayo'),
  ('The Club Sub','Turkey, ham, crispy bacon, lettuce, tomato, provolone and American cheese, signature creamy Italian and mayo'),
  ('Italian Bomber Sub','Ham, capicola, salami, roasted red peppers, lettuce, tomato, onion and provolone with mayo'),
  ('Veggie Sub','Lettuce, tomato, mushrooms, roasted red peppers, green peppers, onions, artichoke hearts, broccoli and provolone with mayo'),
  ('Johnny Mac BLT','Crisp hickory smoked bacon, lettuce, tomato and mayo'),
  ('Meatball Parmesan Sub','Meatballs with our signature marinara and melted mozzarella'),
  ('Chicken Parmesan Sub','Crispy chicken with our signature marinara and melted mozzarella'),
  ('The Big Vin','Italian sausage, capicola, lettuce, tomato, provolone, signature creamy Italian and mayo')]),
 ('Pizza','We make our dough fresh daily using only 100% whole milk Wisconsin mozzarella and the very best crushed tomatoes. Extra toppings available.',[
  ('Traditional NY Cheese',''),
  ('Johnny Mac Special','Fresh green bell peppers, onion, sliced black olives, pepperoni and sausage'),
  ('Meat Lovers','Pepperoni, sausage, ground beef and Canadian bacon'),
  ('Hawaiian','Fresh pineapple and Canadian bacon'),
  ('California White','Olive oil, garlic, fresh basil, tomatoes, ricotta, roasted red peppers, artichokes and mozzarella'),
  ('Tomato, Basil, Garlic','Chunky tomatoes, fresh basil, garlic and mozzarella'),
  ('3 Cheese','Mozzarella, ricotta and Parmesan'),
  ('Meatball Marinara','Our signature marinara topped with house meatballs and fresh basil'),
  ('Daily Pizza Special','2 slices pepperoni with a large soda')]),
 ('Famous Wings','Johnny Mac is from Buffalo, NY. He knows wings like no other. We only buy fresh, never frozen jumbo wings, and only use Broaster fryers with 100% rice oil, zero trans fat.',[
  ('7 Jumbo Wings','1 lb.'),('14 Jumbo Wings','2 lbs.'),('21 Jumbo Wings','3 lbs.'),('35 Jumbo Wings','5 lbs.'),
  ('Signature sauces','Mild · Medium · Hot · Suicide · Hickory BBQ · Teriyaki · Lemon Pepper · Garlic Parmesan. Served with celery sticks, ranch or bleu cheese.')]),
 ('Burgers','All burgers are ½ lb. Angus beef, served with French fries, onion rings or a tossed side salad.',[
  ('Village Burger','Provolone and American cheeses, lettuce, tomato and onion, signature creamy Italian and mayo'),
  ('Bacon Swiss Burger','Crispy bacon, Swiss, lettuce, tomato and onion, signature creamy Italian and mayo'),
  ('BBQ Bacon Ranch Burger','Crispy bacon, hickory BBQ sauce, onion ring and melted Swiss with ranch'),
  ('California Burger','Crispy bacon, cheddar, fresh sliced avocado, lettuce, tomato and onion ring with mayo'),
  ('Bacon, Mushroom, 3 Cheese Burger','Crispy bacon, sautéed mushrooms, Swiss, American and provolone, lettuce, tomato and onion'),
  ('Johnny Mac’s Classic Burger','Sliced pickle and diced onion with Thousand Island, ketchup and mustard'),
  ('Cheddar Jalapeño Burger','Melted cheddar, jalapeños, lettuce, tomato and onion with mayo'),
  ('Bleu Cheese Burger','Sautéed mushrooms, lettuce, tomato and onion with our house bleu cheese dressing'),
  ('Grilled Chicken Burger','Marinated chicken breast, provolone and American, lettuce, tomato and onion')]),
 ('Pasta','Fresh baked garlic bread served with all pasta dishes. Lunch portion available 11 AM – 4 PM.',[
  ('Spaghetti and Meatballs','House meatballs in our signature tomato sauce'),
  ('Fettuccini Alfredo','Fettuccini in our creamy Alfredo sauce'),
  ('Ravioli with Fresh Tomato Sauce','Cheese ravioli topped with our signature tomato sauce'),
  ('Ravioli with Vodka Pink Sauce','Cheese ravioli topped with our vodka pink sauce'),
  ('Linguini with Clams','Tossed with your choice of red or white wine clam sauce'),
  ('Ziti with Italian Sausage','Italian sausage, roasted red peppers, mushrooms and fresh basil in our signature tomato sauce'),
  ('Angel Hair Basil Garlic Tomato','Angel hair, fresh basil, garlic and tomatoes in a white wine marinara'),
  ('Ziti with Broccoli','Fresh garlic, broccoli, mushrooms and roasted red peppers, tossed in olive oil'),
  ('Fettuccini Bolognese','Topped with our signature meat sauce'),
  ('Homemade Lasagna','Topped with our signature tomato sauce')]),
 ('Kid’s Menu','',[
  ('Chicken Fingers with French Fries',''),('Spaghetti with Meatballs',''),('Cheese Ravioli',''),
  ('Fettuccini Alfredo',''),('Open Faced French Bread Pizza',''),('Grilled Cheese Sandwich with French Fries','')]),
 ('Desserts','',[
  ('Ice Cream Sundae','Vanilla ice cream topped with whipped cream and chocolate sauce'),
  ('Cheesecakes','From The Cheesecake Factory. Seasonal, ask your server what’s available'),
  ('Johnny Mac’s Signature Cannolis','Two, made fresh daily. Signature chocolate chip cream hand piped into cannoli shells, dusted with powdered sugar and chocolate sauce')]),
 ('Drinks','',[
  ('Fountain Drinks (unlimited refills)','Coke, Diet Coke, Sprite, Dr. Pepper, Pink Lemonade, Coke Zero, Root Beer and Raspberry Iced Tea'),
  ('Also','Milk, coffee, brewed iced tea, cranberry or orange juice, bottled water'),
  ('Bottled beer','Bud · Bud Light · Miller Lite · MGD · Michelob Ultra · Coors Light · Angry Orchard · Stella Cidre · Miller 64 · Miller High Life · Sam Adams · Newcastle · Fat Tire · Miller Fortune · Corona · Corona Light · Dos Equis · Heineken · Labatt Blue · Blue Moon · Dogfish Head'),
  ('Draught beer (seasonal)','Bud Light · Miller Lite · Guinness · Stella · Sierra Nevada · Sam Adams'),
  ('Non-alcoholic beer','Sharp’s · O’Doul’s'),
  ('Red wines','Cabernet, Merlot, Pinot Noir, Chianti'),
  ('White wines','House Chardonnay, Kendall Jackson Chardonnay, Pinot Grigio, White Zinfandel')]),
]

IMGS = {'pizza':'Specialty pizza with fresh tomato and basil','burger':'Angus burger with fries','roastbeef':'Buffalo roast beef on a Kimmelweck roll',
        'bar':'Inside Johnny Mac\'s with big screens and a full bar','cannoli':'Signature cannolis and tiramisu','garlicbread':'French bread with melted mozzarella and tomato'}

def menu_html():
    tabs = ''.join('<button class="chip%s" data-t="m%d">%s</button>' % (' on' if i == 0 else '', i, E(n)) for i, (n, _, _) in enumerate(MENU))
    panes = []
    for i, (n, intro, items) in enumerate(MENU):
        li = ''.join('<li><b>%s</b>%s</li>' % (E(a), ('<span>%s</span>' % E(b)) if b else '') for a, b in items)
        panes.append('<div class="pane%s" id="m%d"><h3>%s</h3>%s<ul>%s</ul></div>' % (' on' if i == 0 else '', i, E(n), ('<p class="intro">%s</p>' % E(intro)) if intro else '', li))
    return '<div class="chips" role="tablist">%s</div>%s' % (tabs, ''.join(panes))

def loc_html():
    out = []
    for L in LOCS:
        q = (L['addr'] + ', ' + L['city']).replace(' ', '+').replace('#', '%23')
        hrs = ''.join('<tr><td>%s</td><td>%s</td></tr>' % (d, h) for d, h in L['hours'])
        btn = ('<a class="btn go" href="%s" target="_blank" rel="noopener">%s</a>' % (L['order'][1], L['order'][0])) if L['order'] else ''
        out.append('''<article class="loc" data-loc="%s">
 <h3>%s <small class="open" data-open="%s"></small></h3>
 <p class="addr">%s<br>%s</p>
 <table>%s</table>
 <p class="hh">Happy hour Mon – Fri, 3 – 6 PM</p>
 <p class="note">%s</p>
 <div class="row"><a class="btn" href="tel:%s">Call %s</a>%s<a class="btn ghost" href="https://www.google.com/maps/search/?api=1&amp;query=%s" target="_blank" rel="noopener">Directions</a></div>
</article>''' % (L['id'], L['name'], L['id'], L['addr'], L['city'], hrs, L['note'], re.sub(r'\D', '', L['tel']), L['tel'], btn, q))
    return '\n'.join(out)

def spec_html():
    return ''.join('<article class="spec" data-day="%d"><h4>%s</h4><h3>%s</h3><p>%s</p></article>' % ((i + 1) % 7, d, E(t), E(p)) for i, (d, t, p) in enumerate(SPECIALS))

LD = {"@context": "https://schema.org", "@graph": [
  {"@type": "Restaurant", "@id": "#bh", "name": "Johnny Mac's Sports Bar & Grill", "servesCuisine": ["New York Style Pizza", "Buffalo Wings", "Italian", "American"],
   "telephone": "+1-702-564-2121", "url": "https://johnnymacswings.com/",
   "address": {"@type": "PostalAddress", "streetAddress": "842 S Boulder Hwy", "addressLocality": "Henderson", "addressRegion": "NV", "postalCode": "89015", "addressCountry": "US"},
   "foundingDate": "1983", "sameAs": ["https://www.facebook.com/johnnymacswings/", "https://www.instagram.com/johnnymacssportsbar/", "https://www.yelp.com/biz/johnny-macs-henderson"]},
  {"@type": "Restaurant", "name": "Johnny Mac's Water Street Tavern", "telephone": "+1-725-214-7317",
   "address": {"@type": "PostalAddress", "streetAddress": "117 S Water Street", "addressLocality": "Henderson", "addressRegion": "NV", "postalCode": "89015", "addressCountry": "US"}},
  {"@type": "Restaurant", "name": "Johnny Mac's Sports Bar & Grill – Cedar City", "telephone": "+1-435-708-0220",
   "address": {"@type": "PostalAddress", "streetAddress": "2605 N Main St #130", "addressLocality": "Cedar City", "addressRegion": "UT", "postalCode": "84721", "addressCountry": "US"}}]}

SCHED = json.dumps({L['id']: {'s': {str(k): v for k, v in L['sched'].items()}, 'tz': L['tz']} for L in LOCS})

CSS = r'''
:root{--bg:#0e0f0e;--card:#171917;--ink:#f4f1e8;--mute:#b9b6a8;--green:#078439;--mint:#87edaf;--gold:#ffd400;--line:#2a2d2a;--r:14px}
*{box-sizing:border-box}html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-font-smoothing:antialiased}
img{max-width:100%;display:block}a{color:inherit}
.wrap{max-width:1080px;margin:0 auto;padding:0 18px}
header{position:sticky;top:0;z-index:20;background:rgba(14,15,14,.92);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
header .wrap{display:flex;align-items:center;gap:14px;height:62px}
header img{height:46px;width:auto}
nav{display:flex;gap:2px;margin-left:auto;overflow-x:auto;scrollbar-width:none}nav::-webkit-scrollbar{display:none}
nav a{white-space:nowrap;text-decoration:none;font-size:14px;font-weight:600;padding:8px 11px;border-radius:8px;color:var(--mute)}
nav a:hover{color:var(--ink);background:#222}
.btn{display:inline-block;text-decoration:none;font-weight:700;font-size:15px;padding:12px 20px;border-radius:999px;background:var(--green);color:#fff;border:2px solid var(--green);text-align:center;cursor:pointer}
.btn:hover{filter:brightness(1.12)}.btn.ghost{background:transparent;border-color:#4a4d4a;color:var(--ink)}.btn.go{background:var(--gold);border-color:var(--gold);color:#111}
header .btn{padding:9px 16px;font-size:14px;flex:none}
.hero{position:relative;min-height:78vh;display:flex;align-items:center;background:#000 center/cover no-repeat;isolation:isolate}
.hero::before{content:"";position:absolute;inset:0;background:linear-gradient(90deg,rgba(0,0,0,.88),rgba(0,0,0,.45) 70%,rgba(0,0,0,.2));z-index:-1}
.hero h1{font-size:clamp(34px,6.4vw,66px);line-height:1.05;margin:0 0 14px;letter-spacing:-.02em}
.hero h1 em{font-style:normal;color:var(--mint)}
.hero .tag{color:var(--gold);font-weight:800;letter-spacing:.14em;text-transform:uppercase;font-size:13px;margin:0 0 10px}
.hero p.lead{font-size:clamp(17px,2.2vw,21px);max-width:560px;margin:0 0 24px;color:#e9e6da}
.row{display:flex;flex-wrap:wrap;gap:10px}
.strip{background:var(--green);color:#fff}
.strip .wrap{display:flex;flex-wrap:wrap;gap:6px 28px;justify-content:center;padding:13px 18px;font-weight:700;font-size:15px}
section{padding:64px 0}
h2{font-size:clamp(26px,4vw,38px);margin:0 0 6px;letter-spacing:-.01em}
h2+.sub{color:var(--mute);margin:0 0 26px;max-width:640px}
.specs{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:14px}
.spec{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:18px}
.spec h4{margin:0 0 4px;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--mint)}
.spec h3{margin:0 0 6px;font-size:19px}.spec p{margin:0;color:var(--mute);font-size:15px}
.spec.today{border-color:var(--gold);box-shadow:0 0 0 1px var(--gold)}.spec.today h4::after{content:" · TODAY";color:var(--gold)}
.always{background:linear-gradient(135deg,#0b3d1f,#102a18);border:1px solid #1d6b3a;border-radius:var(--r);padding:20px;margin-bottom:14px}
.always h3{margin:0 0 4px}.always p{margin:0;color:#cfe9d8}
.chips{display:flex;gap:8px;overflow-x:auto;padding-bottom:10px;margin-bottom:14px;scrollbar-width:thin}
.chip{flex:none;border:1px solid #3a3d3a;background:#171917;color:var(--ink);font:600 14px inherit;font-family:inherit;padding:9px 15px;border-radius:999px;cursor:pointer}
.chip.on{background:var(--gold);border-color:var(--gold);color:#111}
.pane{display:none}.pane.on{display:block}
.pane h3{margin:4px 0 4px;font-size:24px}.intro{color:var(--mute);margin:0 0 14px;max-width:720px}
.pane ul{list-style:none;margin:0;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:10px}
.pane li{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:13px 15px}
.pane li b{display:block}.pane li span{display:block;color:var(--mute);font-size:14.5px;margin-top:2px}
.menu-foot{color:var(--mute);font-size:14px;margin-top:14px}
.photos{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
.photos img{width:100%;height:100%;aspect-ratio:1;object-fit:cover;border-radius:12px}
.photos .big{grid-column:span 2;grid-row:span 2}
.locs{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:16px}
.loc{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:22px}
.loc h3{margin:0 0 6px;font-size:22px}.loc .addr{margin:0 0 12px;color:var(--mute)}
.loc table{width:100%;border-collapse:collapse;font-size:15px;margin-bottom:10px}.loc td{padding:5px 0;border-bottom:1px solid var(--line)}.loc td:last-child{text-align:right;color:var(--mute)}
.loc .hh{color:var(--gold);font-weight:700;margin:8px 0 4px;font-size:14.5px}.loc .note{color:var(--mute);font-size:14px;margin:0 0 14px}
.open{white-space:nowrap;display:inline-block;font-size:11px;font-weight:800;border-radius:999px;padding:3px 9px;vertical-align:middle;margin-left:6px;letter-spacing:.04em}
.open.y{background:#0f5d34;color:#bff3d2}.open.n{background:#3a2a2a;color:#e8b8b8}
.story{display:grid;grid-template-columns:1fr 1fr;gap:34px;align-items:center}
.story img{border-radius:var(--r);width:100%;aspect-ratio:4/3;object-fit:cover}
.story p{color:#d8d5c8}
.bullets{list-style:none;padding:0;margin:16px 0 0;display:grid;gap:10px}
.bullets li{padding-left:28px;position:relative;color:#d8d5c8}
.bullets li::before{content:"☘";position:absolute;left:0;color:var(--mint)}
.links{display:flex;flex-wrap:wrap;gap:10px}
footer{border-top:1px solid var(--line);padding:30px 0 46px;color:var(--mute);font-size:14px}
footer .wrap{display:flex;flex-wrap:wrap;gap:12px 28px;align-items:center;justify-content:space-between}
@media(max-width:760px){
 nav a:not(.keep){display:none}header img{height:40px}
 section{padding:46px 0}.story{grid-template-columns:1fr}
 .photos{grid-template-columns:repeat(2,1fr)}.photos .big{grid-column:span 2;grid-row:auto}.photos .big img{aspect-ratio:16/10}
 .hero{min-height:70vh}
}
'''

JS = r'''
(function(){
 var $=function(s,r){return (r||document).querySelector(s)},$$=function(s,r){return [].slice.call((r||document).querySelectorAll(s))};
 $$('.chip').forEach(function(c){c.addEventListener('click',function(){
  $$('.chip').forEach(function(x){x.classList.remove('on')});$$('.pane').forEach(function(x){x.classList.remove('on')});
  c.classList.add('on');$('#'+c.dataset.t).classList.add('on')})});
 var S=%s;
 function now(tz){var p=new Intl.DateTimeFormat('en-US',{timeZone:tz,weekday:'short',hour:'numeric',minute:'numeric',hour12:false}).formatToParts(new Date()),o={};
  p.forEach(function(x){o[x.type]=x.value});var d={Sun:0,Mon:1,Tue:2,Wed:3,Thu:4,Fri:5,Sat:6}[o.weekday];return {d:d,m:(+o.hour%%24)*60+(+o.minute)}}
 try{
  $$('.open').forEach(function(el){var L=S[el.dataset.open],n=now(L.tz),t=L.s[n.d],y=(n.d+6)%%7,pt=L.s[y];
   var open=n.m>=t[0]&&n.m<t[1];
   el.textContent=open?'OPEN NOW':'CLOSED NOW';el.className='open '+(open?'y':'n')});
  var n=now('America/Los_Angeles');$$('.spec').forEach(function(s){if(+s.dataset.day===n.d)s.classList.add('today')});
 }catch(e){}
})();
''' % SCHED

def page(img_src):
    def im(k): return img_src(k)
    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Johnny Mac's Sports Bar &amp; Grill | Henderson, NV | NY Pizza &amp; Buffalo Wings Since 1983</title>
<meta name="description" content="Famous for New York style pizza and Buffalo wings. Pastas, burgers, subs and daily specials. Johnny Mac's Sports Bar &amp; Grill: Boulder Highway and Water Street in Henderson, NV, plus Cedar City, UT. Drinks, food and gaming.">
<meta name="theme-color" content="#0e0f0e">
<meta property="og:title" content="Johnny Mac's Sports Bar &amp; Grill | Henderson, NV">
<meta property="og:description" content="New York style pizza, Buffalo wings, daily specials and a full bar since 1983.">
<meta property="og:type" content="restaurant">
<link rel="icon" href="%(logo)s">
<script type="application/ld+json">%(ld)s</script>
<style>%(css)s</style>
</head>
<body>
<header><div class="wrap">
 <a href="#top" aria-label="Johnny Mac's home"><img src="%(logo)s" alt="Johnny Mac's Sports Bar &amp; Grill, since 1983" width="48" height="46"></a>
 <nav><a href="#specials">Specials</a><a href="#menu">Menu</a><a href="#locations" class="keep">Locations</a><a href="#story">Our Story</a><a href="#reviews">Reviews</a></nav>
 <a class="btn go" href="#locations">Order Now</a>
</div></header>

<main id="top">
<div class="hero" style="background-image:url(%(hero)s)"><div class="wrap">
 <p class="tag">Drinks • Food • Gaming</p>
 <h1>Famous for <em>New York style pizza</em> and <em>Buffalo wings</em>.</h1>
 <p class="lead">Great pastas, burgers and sandwiches, and great specials every day. Henderson’s neighborhood sports bar and grill since 1983.</p>
 <div class="row"><a class="btn go" href="#locations">Order Now</a><a class="btn ghost" href="#menu">See the Menu</a></div>
</div></div>
<div class="strip"><div class="wrap"><span>Since 1983</span><span>3 locations</span><span>Happy hour Mon – Fri, 3 – 6 PM</span></div></div>

<section id="specials"><div class="wrap">
 <h2>Daily Specials</h2><p class="sub">Great specials every day. Today’s is highlighted.</p>
 <div class="always"><h3>Every day: Buffalo New York Famous BBQ Wings</h3><p>Made with our signature sauces, served with celery sticks and ranch or bleu cheese. 1, 2, 3, 5 or 10 pounds. Sauces: Mild, Medium, Hot, Suicide, Hickory BBQ, Teriyaki, Lemon Pepper, Garlic Parmesan.</p></div>
 <div class="specs">%(specs)s</div>
 <p class="menu-foot">All menu items and prices subject to change.</p>
</div></section>

<section id="menu" style="background:#121412"><div class="wrap">
 <h2>The Menu</h2><p class="sub">Fresh dough daily, never-frozen jumbo wings, and Italian favorites made in house.</p>
 %(menu)s
 <p class="menu-foot">For current prices, see online ordering or call your location. Prices subject to change.</p>
</div></section>

<section><div class="wrap"><div class="photos">
 <div class="big"><img src="%(i_pizza)s" alt="%(a_pizza)s" loading="lazy" width="900" height="643"></div>
 <img src="%(i_burger)s" alt="%(a_burger)s" loading="lazy" width="900" height="631">
 <img src="%(i_roastbeef)s" alt="%(a_roastbeef)s" loading="lazy" width="900" height="585">
 <img src="%(i_cannoli)s" alt="%(a_cannoli)s" loading="lazy" width="512" height="640">
 <img src="%(i_garlicbread)s" alt="%(a_garlicbread)s" loading="lazy" width="900" height="675">
</div></div></section>

<section id="locations"><div class="wrap">
 <h2>Locations &amp; Hours</h2><p class="sub">Order online from Boulder Highway or Water Street. Cedar City takes phone orders.</p>
 <div class="locs">%(locs)s</div>
 <p class="menu-foot" style="margin-top:18px">Prices subject to change. Hours may vary. <a href="https://www.toasttab.com/johnny-mac-s/giftcards" target="_blank" rel="noopener">Buy a gift card</a>.</p>
</div></section>

<section id="story" style="background:#121412"><div class="wrap story">
 <div><h2>Since 1983</h2>
  <p>Johnny Mac’s has been feeding Henderson for over 40 years. Johnny Mac is from Buffalo, NY, and he knows wings like no other.</p>
  <ul class="bullets">
   <li><b>Pizza:</b> dough made fresh daily with 100%% whole milk Wisconsin mozzarella.</li>
   <li><b>Wings:</b> fresh, large, never frozen, cooked in Broaster fryers with 100%% rice oil and zero trans fat.</li>
   <li><b>Pasta:</b> spaghetti, lasagna, fettuccini, ravioli, ziti and more, with fresh baked garlic bread.</li>
  </ul></div>
 <img src="%(i_bar)s" alt="%(a_bar)s" loading="lazy" width="640" height="428">
</div></section>

<section id="reviews"><div class="wrap">
 <h2>What Guests Say</h2><p class="sub">Read what our guests are saying, and leave us a review.</p>
 <div class="links">
  <a class="btn ghost" href="https://www.yelp.com/biz/johnny-macs-henderson" target="_blank" rel="noopener">Yelp</a>
  <a class="btn ghost" href="https://www.tripadvisor.com/Restaurant_Review-g45953-d422753-Reviews-Johnny_Mac_s_Restaurant_Bar-Henderson_Nevada.html" target="_blank" rel="noopener">TripAdvisor</a>
  <a class="btn ghost" href="https://www.facebook.com/johnnymacswings/reviews" target="_blank" rel="noopener">Facebook</a>
  <a class="btn ghost" href="https://www.instagram.com/johnnymacssportsbar/" target="_blank" rel="noopener">Instagram</a>
 </div>
</div></section>
</main>

<footer><div class="wrap">
 <div>© Johnny Mac’s Sports Bar &amp; Grill. All rights reserved.</div>
 <div>842 S Boulder Hwy, Henderson NV · <a href="tel:7025642121">702-564-2121</a></div>
</div></footer>
<script>%(js)s</script>
</body>
</html>
''' % dict(logo=im('logo'), hero=im('pizza'), ld=json.dumps(LD), css=CSS, specs=spec_html(), menu=menu_html(), locs=loc_html(), js=JS,
           **{'i_' + k: im(k) for k in IMGS}, **{'a_' + k: E(v) for k, v in IMGS.items()})

def rel(k): return 'img/%s.%s' % (k, 'png' if k == 'logo' else 'jpg')
def inl(k):
    p = os.path.join(HERE, rel(k)); mt = 'image/png' if k == 'logo' else 'image/jpeg'
    return 'data:%s;base64,%s' % (mt, base64.b64encode(open(p, 'rb').read()).decode())

open(os.path.join(HERE, 'index.html'), 'w').write(page(rel))
out = os.path.normpath(os.path.join(HERE, '../../.github/db-task/fetched/johnny-macs-single.html'))
open(out, 'w').write(page(inl))
print('index.html %d bytes; single %d bytes' % (os.path.getsize(os.path.join(HERE, 'index.html')), os.path.getsize(out)))
