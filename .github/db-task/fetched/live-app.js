(function(){var y=document.getElementById('yr');if(y)y.textContent=new Date().getFullYear();})();
  var CARS=[], LIST=[], curType='all', curQ='', curSort='price-desc', curMake='', rng={price:null,year:null};
  var grid=document.getElementById('grid'), invcount=document.getElementById('invcount');
  // Deletions + favorites are SYNCED ACROSS DEVICES via the owner's Firebase RTDB
  // (classiccars_deletions / classiccars_favs). localStorage is just the instant local cache.
  var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com';
  var HIDDEN=(function(){try{return new Set(JSON.parse(localStorage.getItem('cc_hidden')||'[]'));}catch(e){return new Set();}})();
  function saveHidden(){try{var a=[];HIDDEN.forEach(function(v){a.push(v);});localStorage.setItem('cc_hidden',JSON.stringify(a));}catch(e){}}
  var FAVS=(function(){try{return new Set(JSON.parse(localStorage.getItem('cc_favs')||'[]'));}catch(e){return new Set();}})();
  function saveFavs(){try{var a=[];FAVS.forEach(function(v){a.push(v);});localStorage.setItem('cc_favs',JSON.stringify(a));}catch(e){}}
  // owner's NOTES per car — { slug: { timestampMs: "text", ... } } — synced via RTDB classiccars_notes
  var NOTES=(function(){try{return JSON.parse(localStorage.getItem('cc_notes')||'{}');}catch(e){return {};}})();
  function saveNotes(){try{localStorage.setItem('cc_notes',JSON.stringify(NOTES));}catch(e){}}
  function noteCount(slug){return (slug&&NOTES[slug])?Object.keys(NOTES[slug]).length:0;}
  function refreshNoteBtn(slug){document.querySelectorAll('.notesbtn[data-note="'+slug+'"]').forEach(function(b){var n=noteCount(slug);b.textContent='📝 Notes'+(n?' ('+n+')':'');});}
  function cloudSync(){ // pull the shared state, merge, push up anything this device knows that the cloud doesn't
    fetch(DB+'/classiccars_deletions.json').then(function(r){return r.json();}).then(function(d){
      d=d||{};
      var changed=false;
      var live=new Set(CARS.map(function(c){return c.slug;}));
      Object.keys(d).forEach(function(s){ if(!FAVS.has(s)&&!HIDDEN.has(s)){HIDDEN.add(s);changed=true;} });
      // favorites always win: a favorited car can never sit in the delete state
      FAVS.forEach(function(s){ if(HIDDEN.has(s)){HIDDEN.delete(s);changed=true;} if(d[s]) fetch(DB+'/classiccars_deletions/'+encodeURIComponent(s)+'.json',{method:'DELETE'}).catch(function(){}); });
      // upload local deletions the cloud is missing — but ONLY for cars that still exist
      // (re-uploading slugs of already-purged cars created an endless queue-refill loop)
      HIDDEN.forEach(function(s){ if(!d[s]&&live.has(s)) fetch(DB+'/classiccars_deletions/'+encodeURIComponent(s)+'.json',{method:'PUT',body:JSON.stringify({at:new Date().toISOString()})}).catch(function(){}); });
      if(changed){saveHidden();render();}
    }).catch(function(){});
    fetch(DB+'/classiccars_favs.json').then(function(r){return r.json();}).then(function(d){
      d=d||{};
      var cloud=new Set(Object.keys(d));
      var changed=false;
      if(cloud.size===0&&FAVS.size>0){
        // first sync from a device with pre-sync favorites: seed the cloud from local
        FAVS.forEach(function(s){ fetch(DB+'/classiccars_favs/'+encodeURIComponent(s)+'.json',{method:'PUT',body:JSON.stringify({at:new Date().toISOString()})}).catch(function(){}); });
      }else{
        // cloud is the source of truth (so un-favoriting on one phone applies everywhere)
        FAVS.forEach(function(s){ if(!cloud.has(s)){FAVS.delete(s);changed=true;} });
        cloud.forEach(function(s){ if(!FAVS.has(s)){FAVS.add(s);changed=true;} });
      }
      if(changed){saveFavs();render();}
    }).catch(function(){});
    fetch(DB+'/classiccars_notes.json').then(function(r){return r.json();}).then(function(d){
      d=d||{};
      if(JSON.stringify(d)!==JSON.stringify(NOTES)){
        NOTES=d;saveNotes();
        // refresh visible note-count badges in place (no full render, so open panels/typing survive)
        document.querySelectorAll('.notesbtn').forEach(function(b){refreshNoteBtn(b.getAttribute('data-note'));});
      }
    }).catch(function(){});
  }
  // LIVE sync (like the LVR database): re-pull every 40s and whenever the tab comes back into focus,
  // so a delete or favorite on one phone shows up on every other device automatically.
  setInterval(cloudSync,40000);
  document.addEventListener('visibilitychange',function(){ if(!document.hidden) cloudSync(); });
  function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];});}
  function priceTxt(p){return p&&p>40?('$'+p.toLocaleString()):'Price on request';}
  // deal score — lower is a better value (cheaper + fewer miles + newer). Used for the
  // "Best Deals" sort and the "great deal" badge.
  function dealScore(c){
    var price=c.price>1000?c.price:1e9;
    var miles=(c.miles!=null&&c.miles>0)?c.miles:130000;
    var year=c.year||1990;
    return price + miles*0.03 - (year-1990)*120;
  }
  // freshness: a car is "new" for 72h after it was imported
  function addedAt(c){ if(!c.added)return 0; var t=(c.addedTs&&c.addedTs.length>10)?Date.parse(c.addedTs):Date.parse(c.added+'T00:00:00'); return t||0; }
  function newTarget(c){ var t=addedAt(c); return t?t+72*3600*1000:0; }
  function isNew(c){ return newTarget(c)>Date.now(); }
  // listing AGE (owner 2026-07-06: show how old it is, not a countdown)
  function fmtAge(ms){ if(ms<0)ms=0; var m=Math.floor(ms/60000),h=Math.floor(ms/3600000),d=Math.floor(ms/86400000);
    if(m<60)return m+'m ago'; if(h<48)return h+'h ago'; return d+'d '+Math.floor((ms-d*86400000)/3600000)+'h ago'; }
  // time ON THE MARKET (owner 2026-07-07): real Craigslist posting date when known, else our import date
  function listedAt(c){ if(c.postedTs){var t=Date.parse(c.postedTs);if(t)return t;} return addedAt(c); }
  function hasDrop(c){ if(!(c.dropAmt>0)||!c.dropTs)return false; var t=Date.parse(c.dropTs); return t&&(Date.now()-t)<14*86400000; } // drop badge lives 14 days
  function isHot(c){ return !!c.deal||(c.dealPct||0)>=15||hasDrop(c); }
  var TYPED={Land:1,House:1,Business:1,Antique:1,Rental:1,RV:1,Ebike:1,Free:1,Foreclosure:1,PVCars:1,Room:1};
  function chipCounts(){ // live counts on every pill so the owner sees what's behind each tab
    var counts={};
    document.querySelectorAll('.chip').forEach(function(b){counts[b.dataset.type]=0;});
    CARS.forEach(function(c){
      if(HIDDEN.has(c.slug))return;
      if(FAVS.has(c.slug)){if(counts.favs!==undefined)counts.favs++;return;}
      if(counts[c.type]!==undefined){ if(c.type!=='Antique'||(c.dealPct||0)>=25||c.apAll)counts[c.type]++; }
      if(counts.new!==undefined&&!TYPED[c.type]&&isNew(c))counts.new++;
      if(counts.deals!==undefined&&isHot(c))counts.deals++;
      if(counts.foreclosures!==undefined&&(c.type==='Foreclosure'||c.fcl))counts.foreclosures++;
      if(counts.sold!==undefined&&c.sold)counts.sold++;
      if(counts.Prius!==undefined&&/prius/i.test(c.name||''))counts.Prius++;
    });
    document.querySelectorAll('.chip').forEach(function(b){
      if(!b.dataset.lbl)b.dataset.lbl=b.textContent.trim();
      var n=counts[b.dataset.type];
      b.textContent=b.dataset.lbl+(n?' ('+Number(n).toLocaleString()+')':'');
    });
  }
  function fmtMarket(ms){ if(ms<0)ms=0; var h=Math.floor(ms/3600000),d=Math.floor(ms/86400000);
    if(h<24)return h<=1?'1 hour':(h+' hours'); if(d<2)return '1 day'; return d+' days'; }
  function dualRange(key,lo,hi,step,fmt){
    var mn=document.getElementById(key+'Min'),mx=document.getElementById(key+'Max'),
        fill=document.getElementById(key+'Fill'),lab=document.getElementById(key+'Val');
    if(!mn||!mx||!fill||!lab)return; // sliders removed (owner 2026-07-06)
    [mn,mx].forEach(function(el){el.min=lo;el.max=hi;el.step=step;});
    mn.value=lo;mx.value=hi;rng[key]=[lo,hi];
    function upd(){
      var a=+mn.value,b=+mx.value;
      if(a>b){if(document.activeElement===mn){a=b;mn.value=a;}else{b=a;mx.value=b;}}
      rng[key]=[a,b];
      var pa=hi>lo?(a-lo)/(hi-lo)*100:0,pb=hi>lo?(b-lo)/(hi-lo)*100:100;
      fill.style.left=pa+'%';fill.style.width=(pb-pa)+'%';
      lab.textContent=fmt(a)+' – '+fmt(b);
      render();
    }
    mn.oninput=upd;mx.oninput=upd;upd();
  }
  function initRanges(){
    var prices=CARS.map(function(c){return c.price;}).filter(function(p){return p>0;});
    var years=CARS.map(function(c){return c.year;});
    if(prices.length){var plo=Math.floor(Math.min.apply(null,prices)/1000)*1000,phi=Math.ceil(Math.max.apply(null,prices)/1000)*1000;dualRange('price',plo,phi,1000,function(v){return '$'+Number(v).toLocaleString();});}
    if(years.length){dualRange('year',Math.min.apply(null,years),Math.max.apply(null,years),1,function(v){return ''+v;});}
  }
  function render(){
    // don't wipe the grid while the owner is typing a note (a background sync could re-render)
    if(document.activeElement&&document.activeElement.classList&&document.activeElement.classList.contains('notein'))return;
    // stale-render guard: bump FIRST so any earlier render's pending appendBatch goes inert —
    // including when this render ends early on an empty list ("No matches").
    var myGen=(window.__renderGen=(window.__renderGen||0)+1);
    chipCounts();
    var list=CARS.filter(function(c){
      if(curType==='favs'){if(!FAVS.has(c.slug))return false;if(HIDDEN.has(c.slug))return false;} // Favs tab = starred (and not deleted)
      else if(curType==='deals'){ // 🔥 combined Best Deals view: 15%+ deals or fresh price drops, every category
        if(FAVS.has(c.slug))return false;
        if(HIDDEN.has(c.slug))return false;
        if(!isHot(c))return false;
      }
      else if(curType==='foreclosures'){ // 🔨 all foreclosures + repos: type Foreclosure OR any fcl-flagged listing
        if(FAVS.has(c.slug))return false;
        if(HIDDEN.has(c.slug))return false;
        if(!(c.type==='Foreclosure'||c.fcl))return false;
      }
      else{
        if(FAVS.has(c.slug))return false;                       // starred cars leave the main views
        if(c.type==='Land'&&curType!=='Land')return false;      // land lives only in the Land tab
        if(c.type==='House'&&curType!=='House')return false;    // houses live only in the Houses tab
        if(c.type==='Rental'&&curType!=='Rental')return false;  // rentals live only in the Rentals tab
        if(c.type==='RV'&&curType!=='RV')return false;          // RVs live only in the RV tab
        if(c.type==='Ebike'&&curType!=='Ebike')return false;    // e-bikes live only in the E-Bikes tab
        if(c.type==='Free'&&curType!=='Free')return false;      // free stuff lives only in the Free tab
        if(c.type==='Foreclosure'&&curType!=='foreclosures')return false; // foreclosures/repos live only in the Foreclosures tab
        if(c.type==='PVCars'&&curType!=='PVCars')return false; // Palos Verdes cheap cars live only in that tab
        if(c.type==='Room'&&curType!=='Room')return false; // rooms for rent live only in the Rooms tab
        if(c.type==='Business'&&curType!=='Business')return false; // businesses live only in the Business tab
        if(c.type==='Antique'){ if(curType!=='Antique')return false; if(!((c.dealPct||0)>=25||c.apAll))return false; } // Antiques: own tab, 25%+ deals only
        else if(curType==='Antique')return false;
        if(curType!=='sold'&&HIDDEN.has(c.slug))return false;   // X'd-out cars hidden everywhere except Sold
        if(curType==='Prius'){if(!/prius/i.test(c.name||''))return false;}
        else if(curType==='new'){if(!isNew(c))return false;}
        else if(curType==='sold'){if(!c.sold)return false;}
        else if(curType!=='all'&&c.type!==curType)return false;
      }
      if(curMake&&c.make!==curMake)return false;
      if(curQ){var h=((c.year||'')+' '+(c.name||'')+' '+(c.type||'')).toLowerCase();if(h.indexOf(curQ)<0)return false;}
      if(rng.price&&c.price>1000&&(c.price<rng.price[0]||c.price>rng.price[1]))return false;
      if(rng.year&&(c.year<rng.year[0]||c.year>rng.year[1]))return false;
      return true;
    });
    // header total is context-aware: Favorites/Land tabs show their own counts, everything else the car pool
    var pool=CARS.filter(function(c){return !HIDDEN.has(c.slug)&&!FAVS.has(c.slug)&&c.type!=='Land'&&c.type!=='House'&&c.type!=='Business'&&c.type!=='Antique'&&c.type!=='Rental'&&c.type!=='RV'&&c.type!=='Ebike'&&c.type!=='Free'&&c.type!=='Foreclosure'&&c.type!=='PVCars'&&c.type!=='Room';}).length;
    var gt=document.getElementById('grandTotal'), gl=document.getElementById('grandLabel');
    if(gt){
      if(curType==='favs'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' favorites';}
      else if(curType==='deals'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' hot deals';}
      else if(curType==='foreclosures'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' foreclosures & repos';}
      else if(curType==='PVCars'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' cars under $3k';}
      else if(curType==='Room'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' rooms for rent';}
      else if(curType==='Land'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' land deals';}
      else if(curType==='House'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' houses';}
      else if(curType==='Business'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' businesses';}
      else if(curType==='Antique'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' antique deals';}
      else if(curType==='Rental'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' rentals';}
      else if(curType==='RV'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' RVs';}
      else if(curType==='Ebike'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' e-bikes';}
      else if(curType==='Free'){gt.textContent=Number(list.length).toLocaleString();if(gl)gl.textContent=' free items';}
      else{gt.textContent=Number(pool).toLocaleString();if(gl)gl.textContent=' cars available';}
    }
    if(!list.length){grid.innerHTML='';invcount.textContent='';return;} // blank page when nothing matches
    var P=function(c){return c.price>1000?c.price:-1;};
    list.sort(function(a,b){
      // Favorites default to best-deals-first (owner); an explicit sort choice still wins
      if(curType==='favs'&&curSort==='price-desc'){ if((b.dealPct||0)!==(a.dealPct||0))return (b.dealPct||0)-(a.dealPct||0); return dealScore(a)-dealScore(b); }
      if(curSort==='deal'){ if((b.dealPct||0)!==(a.dealPct||0))return (b.dealPct||0)-(a.dealPct||0); return dealScore(a)-dealScore(b); }
      if(curSort==='new')return newTarget(b)-newTarget(a);
      if(curSort==='market-asc')return listedAt(b)-listedAt(a);   // fewest days on market first
      if(curSort==='market-desc')return listedAt(a)-listedAt(b);  // longest on market first
      if(curSort==='price-asc')return (a.price>1000?a.price:Infinity)-(b.price>1000?b.price:Infinity);
      if(curSort==='year-desc')return b.year-a.year;
      if(curSort==='year-asc')return a.year-b.year;
      return P(b)-P(a); // price-desc (default)
    });
    LIST=list;
    var cardHTML=function(c,ri){
      var all=(c.imgs&&c.imgs.length)?c.imgs:(c.img?[c.img]:[]);
      var total=all.length;
      var title=esc(c.year+' '+c.name);
      var href=c.src?esc(c.src):null; // clicking anything opens the original Craigslist ad
      var A=' target="_blank" rel="noopener"';
      var soldtag=c.sold?'<span class="soldtag">SOLD</span>':'';
      var ph;
      if(total){
        var nav=total>1
          ?'<button type="button" class="nav prev" aria-label="Previous photo">‹</button><button type="button" class="nav next" aria-label="Next photo">›</button>'
          :'';
        var cnt=total>1?'<span class="count">1/'+total+'</span>':'';
        var pa=href?('<a class="phlink" href="'+href+'"'+A+' aria-label="View '+title+' on Craigslist">'):'<span class="phlink">';
        var paEnd=href?'</a>':'</span>';
        ph='<div class="ph" data-i="0">'+soldtag+pa+'<img class="cimg" src="'+esc(all[0])+'" alt="'+title+'" loading="lazy" decoding="async" width="320" height="240">'+paEnd+nav+cnt+'</div>';
      } else {
        ph='<div class="ph">'+soldtag+'<span class="noimg">Photo coming soon</span></div>';
      }
      var nonveh=(c.type==='Land'||c.type==='House'||c.type==='Business'||c.type==='Antique'||c.type==='Rental'||c.type==='RV'||c.type==='Ebike'||c.type==='Free'||c.type==='Foreclosure'||c.type==='PVCars'||c.type==='Room');var mi=nonveh?'':((c.miles!=null)?(Number(c.miles).toLocaleString()+' miles'):'Mileage n/a');
      var nm=href?('<a class="nm" href="'+href+'"'+A+'>'+title+'</a>'):('<p class="nm">'+title+'</p>');
      // top line of every card: just the market age ("13 days") — no NEW pill, no icon (owner 2026-07-07)
      var la=listedAt(c);
      var marketline=la?('<div class="listedage">'+fmtMarket(Date.now()-la)+' on the market</div>'):'';
      // Favorites + Land + Teslas always show their deal % (owner) — other views only badge flagged deals
      var isTesla=/tesla/i.test(c.name||'');
      var showPct=c.deal||((curType==='favs'||curType==='deals'||curType==='Land'||curType==='House'||curType==='Business'||curType==='Antique'||curType==='RV'||curType==='Ebike'||isTesla)&&c.dealPct>0);
      var dealtag=showPct?('<span class="tag">⭐ '+c.dealPct+'% under market</span>')
                 :((curType==='favs'||curType==='Land'||curType==='House'||curType==='Business'||curType==='Antique'||curType==='RV'||curType==='Ebike'||isTesla)?'<span class="tag" style="opacity:.6">no price comps</span>':'');
      var fsdtag=c.fsd?'<span class="tag fsdtag">🤖 SELF-DRIVING INCLUDED</span>':'';
      var fcltag=c.fcl?'<span class="tag fsdtag">🔨 FORECLOSURE</span>':'';
      var droptag=hasDrop(c)?('<span class="tag droptag">📉 PRICE DROP −$'+Number(c.dropAmt).toLocaleString()+'</span>'):'';
      var tags=(dealtag||fsdtag||fcltag||droptag)?('<div class="tags">'+droptag+fcltag+fsdtag+dealtag+'</div>'):'';
      var dealval=(showPct&&c.fair)?('<div class="dealval">Est. value ~$'+Number(c.fair).toLocaleString()+' · save ~$'+Number(c.save).toLocaleString()+'</div>'):'';
      var isFav=FAVS.has(c.slug);
      return '<article class="card'+(c.fsd?' fsd':'')+'" data-ri="'+ri+'">'
        +'<button class="cardfav'+(isFav?' isfav':'')+'" data-fav="'+esc(c.slug||'')+'" title="'+(isFav?'Remove from favorites':'Add to favorites')+'" aria-label="Favorite">'+(isFav?'⭐':'☆')+'</button>'
        +'<button class="cardx" data-x="'+esc(c.slug||'')+'" title="Hide this car" aria-label="Hide this car">✕</button>'+ph
        +'<div class="body">'+marketline+tags+nm
        +(mi?'<div class="mi">'+esc(mi)+'</div>':'')
        +(c.location?'<div class="cardloc">📍 '+esc(c.location)+'</div>':'')
        +dealval
        +'<div class="price">'+(c.type==='Free'?'FREE':priceTxt(c.price)+((c.type==='Rental'||c.type==='Room')?'/mo':''))+'</div>'
        +'<button type="button" class="notesbtn" data-note="'+esc(c.slug||'')+'">📝 Notes'+(noteCount(c.slug)?' ('+noteCount(c.slug)+')':'')+'</button>'
        +'<div class="notesbox" data-notesfor="'+esc(c.slug||'')+'" hidden></div>'
        +'</div></article>';
    };
    // chunked rendering: paint 48 cards at a time as the visitor nears them (keeps scrolling smooth)
    var CHUNK=48,shown=0;
    grid.innerHTML='';
    function bindPh(ph){
      ph.addEventListener('mouseenter',function(){
        clearTimeout(ph._dwell);clearInterval(ph._auto);
        ph._dwell=setTimeout(function(){ph._auto=setInterval(function(){advance(ph,1);},2000);},3000);
      });
      ph.addEventListener('mouseleave',function(){clearTimeout(ph._dwell);clearInterval(ph._auto);});
    }
    function appendBatch(){
      if(myGen!==window.__renderGen)return; // a newer render owns the grid — never append stale cards
      if(shown>=list.length)return;
      var end=Math.min(shown+CHUNK,list.length);
      var tmp=document.createElement('div');
      tmp.innerHTML=list.slice(shown,end).map(function(c,k){return cardHTML(c,shown+k);}).join('');
      while(tmp.firstChild){
        var node=tmp.firstChild;
        grid.appendChild(node);
        if(node.querySelectorAll){node.querySelectorAll('.ph').forEach(bindPh);}
      }
      shown=end;
    }
    window.__appendBatch=appendBatch;
    if(!window.__gridSentinel){
      var s=document.createElement('div');
      s.style.cssText='height:1px';
      grid.parentNode.insertBefore(s,grid.nextSibling);
      window.__gridSentinel=s;
      if('IntersectionObserver' in window){
        new IntersectionObserver(function(en){
          if(en[0].isIntersecting&&window.__appendBatch)window.__appendBatch();
        },{rootMargin:'1800px 0px'}).observe(s);
      }
    }
    appendBatch();
    if(!('IntersectionObserver' in window)){while(shown<list.length)appendBatch();}
    setTimeout(function(){
      if(shown<list.length&&window.__gridSentinel){
        var r=window.__gridSentinel.getBoundingClientRect();
        if(r.top<window.innerHeight+1800)appendBatch();
      }
    },60);
    invcount.textContent='Showing '+list.length+' of '+pool;
    var q=document.getElementById('q');
    if(q)q.placeholder='Search make, model, or year…';

  }
  function advance(ph,dir){
    var card=ph.closest('.card');if(!card)return;var c=LIST[+card.dataset.ri];if(!c)return;
    var imgs=c.imgs||[],n=imgs.length;if(n<2)return;
    var i=(parseInt(ph.dataset.i||'0',10)+dir+n)%n;
    ph.dataset.i=i;
    var img=ph.querySelector('.cimg');if(img)img.src=imgs[i];
    var cnt=ph.querySelector('.count');if(cnt)cnt.textContent=(i+1)+'/'+n;
  }
  function renderNotes(slug,box){
    var m=NOTES[slug]||{};
    var keys=Object.keys(m).sort(function(a,b){return +b-+a;}); // newest first
    var html=keys.map(function(ts){
      return '<div class="noteitem"><div class="notetime">'+new Date(+ts).toLocaleString()
        +' <button type="button" class="notedel" data-slug="'+esc(slug)+'" data-ts="'+ts+'" title="Delete note">×</button></div>'
        +'<div class="notetext">'+esc(m[ts])+'</div></div>';
    }).join('');
    box.innerHTML=(html||'<div class="notesempty">No notes yet.</div>')
      +'<textarea class="notein" placeholder="Add a note…"></textarea>'
      +'<button type="button" class="noteadd" data-slug="'+esc(slug)+'">Add note</button>';
  }
  grid.addEventListener('click',function(e){
    var nb=e.target.closest('.notesbtn');
    if(nb){e.preventDefault();var s=nb.getAttribute('data-note');var box=nb.parentNode.querySelector('.notesbox[data-notesfor="'+s+'"]');
      if(box){if(box.hidden){renderNotes(s,box);box.hidden=false;}else{box.hidden=true;}}return;}
    var na=e.target.closest('.noteadd');
    if(na){e.preventDefault();var s2=na.getAttribute('data-slug');var box2=na.closest('.notesbox');var ta=box2.querySelector('.notein');
      var text=(ta.value||'').trim();if(!text)return;
      var ts=Date.now();
      if(!NOTES[s2])NOTES[s2]={};NOTES[s2][ts]=text;saveNotes();
      try{fetch(DB+'/classiccars_notes/'+encodeURIComponent(s2)+'/'+ts+'.json',{method:'PUT',body:JSON.stringify(text)}).catch(function(){});}catch(err){}
      renderNotes(s2,box2);refreshNoteBtn(s2);return;}
    var nd=e.target.closest('.notedel');
    if(nd){e.preventDefault();var s3=nd.getAttribute('data-slug'),ts3=nd.getAttribute('data-ts');
      if(NOTES[s3]){delete NOTES[s3][ts3];if(!Object.keys(NOTES[s3]).length)delete NOTES[s3];saveNotes();}
      try{fetch(DB+'/classiccars_notes/'+encodeURIComponent(s3)+'/'+ts3+'.json',{method:'DELETE'}).catch(function(){});}catch(err){}
      var box3=nd.closest('.notesbox');renderNotes(s3,box3);refreshNoteBtn(s3);return;}
    var fv=e.target.closest('.cardfav');
    if(fv){e.preventDefault();e.stopPropagation();var fid=fv.getAttribute('data-fav');if(fid){
      if(FAVS.has(fid)){
        // UN-favorite = send it back to the normal pool everywhere: clear fav, un-hide, cancel any pending delete
        FAVS.delete(fid);
        HIDDEN.delete(fid);saveHidden();
        try{fetch(DB+'/classiccars_favs/'+encodeURIComponent(fid)+'.json',{method:'DELETE'}).catch(function(){});}catch(err){}
        try{fetch(DB+'/classiccars_deletions/'+encodeURIComponent(fid)+'.json',{method:'DELETE'}).catch(function(){});}catch(err){}
      }else{
        FAVS.add(fid);
        try{fetch(DB+'/classiccars_favs/'+encodeURIComponent(fid)+'.json',{method:'PUT',body:JSON.stringify({at:new Date().toISOString()})}).catch(function(){});}catch(err){}
      }
      saveFavs();var fc=fv.closest('.card');if(fc){fc.style.transition='opacity .18s';fc.style.opacity='0';setTimeout(render,180);}else render();}return;}
    var x=e.target.closest('.cardx');
    if(x){e.preventDefault();e.stopPropagation();var id=x.getAttribute('data-x');if(id){
      HIDDEN.add(id);saveHidden();
      if(FAVS.has(id)){FAVS.delete(id);saveFavs();try{fetch(DB+'/classiccars_favs/'+encodeURIComponent(id)+'.json',{method:'DELETE'}).catch(function(){});}catch(err){}} // deleting from Favorites really deletes it
      // queue a PERMANENT delete: the daily maintenance task reads this node and removes the car
      // (and its photos) from the real database, then rebuilds the site.
      try{fetch(DB+'/classiccars_deletions/'+encodeURIComponent(id)+'.json',{method:'PUT',body:JSON.stringify({at:new Date().toISOString()})}).catch(function(){});}catch(err){}
      var card=x.closest('.card');if(card){card.style.transition='opacity .18s';card.style.opacity='0';setTimeout(render,180);}else render();
    }return;}
    var btn=e.target.closest('.nav');
    if(btn){e.preventDefault();advance(btn.closest('.ph'),btn.classList.contains('next')?1:-1);}
  });
  // swipe / drag on card photos (touch + mouse)
  function swEnd(ph,sx,x){
    if(sx==null)return;var dx=x-sx;
    if(Math.abs(dx)>35){advance(ph,dx<0?1:-1);
      var a=ph.querySelector('.phlink');if(a){var sw=function(ev){ev.preventDefault();ev.stopPropagation();a.removeEventListener('click',sw,true);};a.addEventListener('click',sw,true);}
    }
  }
  grid.addEventListener('touchstart',function(e){if(e.touches.length>1){var p0=e.target.closest('.ph');if(p0)p0._sx=null;return;}var ph=e.target.closest('.ph');if(ph&&!e.target.closest('.nav'))ph._sx=e.changedTouches[0].clientX;},{passive:true});
  grid.addEventListener('touchend',function(e){var ph=e.target.closest('.ph');if(ph&&ph._sx!=null){swEnd(ph,ph._sx,e.changedTouches[0].clientX);ph._sx=null;}},{passive:true});
  var mPh=null,mX=null;
  grid.addEventListener('mousedown',function(e){var ph=e.target.closest('.ph');if(ph&&!e.target.closest('.nav')){mPh=ph;mX=e.clientX;}});
  window.addEventListener('mouseup',function(e){if(mPh){swEnd(mPh,mX,e.clientX);mPh=null;mX=null;}});
  document.getElementById('sortBy').addEventListener('change',function(){curSort=this.value;render();});
  document.getElementById('makeFilter').addEventListener('change',function(){curMake=this.value;render();});
  function populateMakes(){
    var mk={};CARS.forEach(function(c){if(c.make&&!/^(honda|land|house|business|antique|rental|rv|ebike|free|foreclosure|palos verdes|room)$/i.test(c.make))mk[c.make]=1;});
    var sel=document.getElementById('makeFilter');
    Object.keys(mk).sort().forEach(function(m){var o=document.createElement('option');o.value=m;o.textContent=m;sel.appendChild(o);});
  }
  document.querySelectorAll('.chip').forEach(function(b){b.addEventListener('click',function(){
    document.querySelectorAll('.chip').forEach(function(x){x.setAttribute('aria-pressed','false');});
    b.setAttribute('aria-pressed','true');curType=b.dataset.type;
    var ss=document.getElementById('sortBy');
    if(ss){var def=(curType==='Free'||curType==='Rental'||curType==='foreclosures'||curType==='PVCars'||curType==='Room')?'new':'deal';ss.value=def;curSort=def;} // free stuff & rentals: newest first — first-come-first-served
    render();
  });});
  // search bar removed (owner 2026-07-06) — listeners guarded in case it ever returns
  var qel=document.getElementById('q'),qt;
  if(qel){
    qel.addEventListener('input',function(){clearTimeout(qt);qt=setTimeout(function(){curQ=qel.value.trim().toLowerCase();render();},120);});
    qel.addEventListener('keydown',function(e){if(e.key==='Enter'){e.preventDefault();clearTimeout(qt);curQ=qel.value.trim().toLowerCase();render();}});
  }
  // ===== Easy financing estimator =====


  fetch('cars.json?v=1783268292').then(function(r){return r.json();}).then(function(d){CARS=d||[];populateMakes();initRanges();render();cloudSync();}).catch(function(){grid.innerHTML='<p style="color:var(--muted)">Inventory unavailable right now.</p>';});

  // live listing-age on newly-imported cars — tick every 30s (badge retires after the 72h window)
  setInterval(function(){
    document.querySelectorAll('.tagnew[data-target]').forEach(function(el){
      var t=+el.getAttribute('data-target'), added=+el.getAttribute('data-added'), left=t-Date.now(), cd=el.querySelector('.cd');
      if(left<=0){el.parentNode&&el.remove();} else if(cd){cd.textContent=fmtAge(Date.now()-added);}
    });
  },30000);

  // ===== Hamburger menu =====
  var hambBtn=document.getElementById('hambBtn'),menuPanel=document.getElementById('menuPanel');
  function toggleMenu(show){menuPanel.hidden=!show;hambBtn.setAttribute('aria-expanded',show?'true':'false');}
  hambBtn.addEventListener('click',function(e){e.stopPropagation();toggleMenu(menuPanel.hidden);});
  menuPanel.addEventListener('click',function(e){if(e.target.closest('.menu-item'))toggleMenu(false);});
  document.addEventListener('click',function(e){if(!menuPanel.hidden&&!menuPanel.contains(e.target)&&e.target!==hambBtn&&!hambBtn.contains(e.target))toggleMenu(false);});
  document.addEventListener('keydown',function(e){if(e.key==='Escape')toggleMenu(false);});



  // ===== "Coming soon" popups for the sister-site menu links =====
  (function(){
    var ov=document.getElementById('soonOverlay'); if(!ov) return;
    var SOON={
      motorcycles:{e:'🏍️',t:'Classic Motorcycles For Sale',d:'classicmotorcyclesforsale.co'},
      airplanes:{e:'✈️',t:'Classic Airplanes For Sale',d:'classicairplanesforsale.co'},
      boats:{e:'⛵',t:'Classic Boats For Sale',d:'classicboatsforsale.co'}
    };
    function openSoon(k){var s=SOON[k]; if(!s) return; document.getElementById('soonEmoji').textContent=s.e; document.getElementById('soonTitle').textContent=s.t; document.getElementById('soonDom').textContent=s.d; ov.hidden=false; document.body.style.overflow='hidden';}
    function closeSoon(){ov.hidden=true; document.body.style.overflow='';}
    document.addEventListener('click',function(e){var t=e.target.closest('[data-soon]'); if(t){e.preventDefault(); openSoon(t.getAttribute('data-soon')); return;} if(e.target===ov||e.target.id==='soonClose'||e.target.id==='soonOk') closeSoon();});
    document.addEventListener('keydown',function(e){if(e.key==='Escape'&&!ov.hidden) closeSoon();});
  })();



(function(){var b=document.getElementById('toTop');if(!b)return;
b.addEventListener('click',function(e){e.preventDefault();
  var se=document.scrollingElement||document.documentElement;
  var h=document.documentElement,p=h.style.scrollBehavior;h.style.scrollBehavior='auto';
  function up(){se.scrollTop=0;document.body.scrollTop=0;window.scrollTo(0,0);}
  up();requestAnimationFrame(up);setTimeout(function(){up();h.style.scrollBehavior=p;},120);
});})();
(function(){var el=document.getElementById('pageViews');if(!el)return;
var slug=el.getAttribute('data-slug')||'home';
var CU='https://lvr-data-a60c1-default-rtdb.firebaseio.com/classiccars_pageviews/'+encodeURIComponent(slug)+'.json';
function show(n){if(n!=null&&!isNaN(n))el.textContent=Number(n).toLocaleString();}
function read(){fetch(CU).then(function(r){return r.json();}).then(show).catch(function(){});}
try{var k='ccv_'+slug;
  if(localStorage.getItem(k)){read();return;}
  localStorage.setItem(k,'1');
  fetch(CU,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({'.sv':{'increment':1}})}).then(function(r){return r.json();}).then(show).catch(read);
}catch(e){read();}})();

(function(){try{var day=new Date().toISOString().slice(0,10);var B='https://lvr-data-a60c1-default-rtdb.firebaseio.com/classiccars_stats/'+day;var inc=JSON.stringify({'.sv':{'increment':1}});
fetch(B+'/total.json',{method:'PUT',body:inc});fetch(B+'/pages/home.json',{method:'PUT',body:inc});
if(document.referrer){var rd=(new URL(document.referrer)).hostname;if(rd&&rd.indexOf('classiccarsforsale')<0){fetch(B+'/ref/'+rd.replace(/[.#$\/\[\]]/g,'_')+'.json',{method:'PUT',body:inc});}}}catch(e){}})();
(function(){var f=document.getElementById('alertForm');if(!f)return;
f.addEventListener('submit',function(ev){ev.preventDefault();
var em=document.getElementById('alertEmail').value.trim();var want=document.getElementById('alertWant').value.trim();var msg=document.getElementById('alertMsg');
if(!em||em.indexOf('@')<1){msg.textContent='Please enter a valid email.';msg.style.color='#b00020';return;}
fetch('https://lvr-data-a60c1-default-rtdb.firebaseio.com/classiccars_alerts.json',{method:'POST',body:JSON.stringify({email:em,wants:want||'anything',at:new Date().toISOString()})}).catch(function(){});
fetch('https://formsubmit.co/ajax/shane7out@gmail.com',{method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json'},body:JSON.stringify({_subject:'NEW ALERT SIGNUP — classiccarsforsale-co.web.app',Email:em,Wants:want||'anything',_template:'table'})}).catch(function(){});
msg.textContent='✓ You\'re on the list! We\'ll let you know when fresh classics land.';msg.style.color='#0d47a1';f.reset();});})();

(function(){var b=document.getElementById('toBottom');if(!b)return;
b.addEventListener('click',function(e){e.preventDefault();
  // render all remaining cards first so the page reaches its true full height
  var guard=0;while(window.__appendBatch&&guard<400){var before=document.querySelectorAll('.card').length;window.__appendBatch();guard++;if(document.querySelectorAll('.card').length===before)break;}
  var se=document.scrollingElement||document.documentElement;
  var h=document.documentElement,p=h.style.scrollBehavior;h.style.scrollBehavior='auto';
  function down(){se.scrollTop=se.scrollHeight;document.body.scrollTop=se.scrollHeight;window.scrollTo(0,se.scrollHeight);}
  down();requestAnimationFrame(down);setTimeout(function(){down();h.style.scrollBehavior=p;},160);
});})();
