/* Deals refresh client — EXTERNAL file (the site's CSP script-src 'self' blocks inline JS,
   which is why every inline version of this silently never ran in browsers).
   - binds the baked #refreshbtn via document-level delegation (survives DOM rebuilds)
   - 30-day rule enforced client-side instantly: hides any card labeled >30 days on the market
   - also hides everything in _deals/removed (sold/expired/stale found by the cloud sweeper)
   - re-applies after app.js re-renders the grid (MutationObserver)
   - tap: spinner + toast, cloud sweep runs within ~15 min, page fixes itself, date updates */
(function(){
  'use strict';
  var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals';
  var MAX_AGE=30;
  var removedCache=null, base=null, toast=null, tt=null;
  function $(id){return document.getElementById(id);}
  function fmt(ts){var d=new Date(ts);return (d.getMonth()+1)+'/'+d.getDate()+'/'+String(d.getFullYear()).slice(-2)+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}
  function setDate(ts){var lu=$('lastupd');if(!lu)return;if(!lu.firstChild||lu.firstChild.nodeType!==3){lu.insertBefore(document.createTextNode(''),lu.firstChild);}lu.firstChild.nodeValue=fmt(ts);}
  function hideCard(a){a.style.display='none';a.setAttribute('data-dead','1');}

  function sweep(){
    document.querySelectorAll('article.card').forEach(function(a){
      if(a.getAttribute('data-dead'))return;
      var f=a.querySelector('.cardfav');var k=f&&f.getAttribute('data-fav');
      if(k&&removedCache&&removedCache[k]){hideCard(a);return;}
      var ageEl=a.querySelector('.listedage');
      if(ageEl){var m=/(\d+)\s*days? on the market/.exec(ageEl.textContent||'');
        if(m&&parseInt(m[1],10)>MAX_AGE){hideCard(a);}}
    });
    var vis=document.querySelectorAll('article.card:not([data-dead])').length;
    var gt=$('grandTotal');if(gt)gt.textContent=vis;
  }

  // --- pill counts must match what clicking shows (data minus removed minus >30d) ---
  var CARSDATA=null;
  function ageDays(c){var t=c.postedTs||c.addedTs||c.added;if(!t)return 0;var d=new Date(t);if(isNaN(d))return 0;return (Date.now()-d.getTime())/864e5;}
  function eligible(c){if(removedCache&&removedCache[c.slug])return false;if(ageDays(c)>MAX_AGE)return false;return true;}
  function fixChips(){
    if(!CARSDATA)return;
    var typeChips={};
    document.querySelectorAll('.chip').forEach(function(b){
      var t=b.dataset&&b.dataset.type;if(!t)return;
      if(['Land','House','Business','Antique','Rental','RV','Ebike','Room','PVCars'].indexOf(t)>=0)typeChips[t]=0;
      if(t==='foreclosures')typeChips[t]=0;
      if(t==='deals')typeChips[t]=0;
    });
    CARSDATA.forEach(function(c){
      if(!eligible(c))return;
      if(typeChips[c.type]!=null)typeChips[c.type]++;
      if(c.fcl&&typeChips.foreclosures!=null)typeChips.foreclosures++;
      if(c.deal&&typeChips.deals!=null)typeChips.deals++;
    });
    document.querySelectorAll('.chip').forEach(function(b){
      var t=b.dataset&&b.dataset.type;if(t==null||typeChips[t]==null)return;
      if(!b.dataset.lbl)b.dataset.lbl=b.textContent.replace(/\s*\d+$/,'').trim();
      b.textContent=b.dataset.lbl+' '+typeChips[t];
    });
  }
  function watchGrid(){
    var grid=$('grid');if(!grid||!window.MutationObserver)return;
    var t=null;
    new MutationObserver(function(){clearTimeout(t);t=setTimeout(function(){sweep();fixChips();},150);})
      .observe(grid,{childList:true});
  }

  function say(msg,ms){
    if(!toast||!document.body.contains(toast)){toast=document.createElement('div');toast.id='rtoast';document.body.appendChild(toast);}
    toast.textContent=msg;toast.classList.add('show');clearTimeout(tt);
    if(ms)tt=setTimeout(function(){toast.classList.remove('show');},ms);
  }

  function pull(){
    fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){if(ts){if(!base)base=ts;setDate(ts);}}).catch(function(){});
    fetch(DB+'/removed.json').then(function(r){return r.json();}).then(function(o){removedCache=o||{};sweep();fixChips();}).catch(function(){sweep();});
    if(!CARSDATA){fetch('/cars.json').then(function(r){return r.json();}).then(function(j){if(Array.isArray(j)){CARSDATA=j;fixChips();}}).catch(function(){});}
  }

  function go(){
    var btn=$('refreshbtn');if(!btn||btn.classList.contains('busy'))return;
    btn.classList.add('busy');btn.classList.remove('done');
    say('Refreshing… checking every listing. Takes up to ~15 min — you can leave this page.');
    fetch(DB+'/refresh_request.json',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(Date.now())}).then(function(){
      var n=0;var iv=setInterval(function(){n++;
        fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){
          if(ts&&base&&ts>base){base=ts;clearInterval(iv);
            fetch(DB+'/removed.json').then(function(r){return r.json();}).then(function(o){
              removedCache=o||{};sweep();fixChips();setDate(ts);
              btn.classList.remove('busy');btn.classList.add('done');btn.innerHTML='✓';
              say('Up to date — '+fmt(ts),6000);
              setTimeout(function(){btn.classList.remove('done');btn.innerHTML='<span class="rg">⟳</span>';},4000);
            }).catch(function(){});
          } else if(ts&&!base){base=ts;}
          else if(n>=80){clearInterval(iv);btn.classList.remove('busy');say('Timed out — tap to try again',6000);}
        }).catch(function(){});
      },15000);
    }).catch(function(){btn.classList.remove('busy');say('No connection — tap to try again',5000);});
  }

  function init(){
    document.addEventListener('click',function(e){
      if(e.target&&e.target.closest&&e.target.closest('#refreshbtn'))go();
    });
    pull();watchGrid();
    setTimeout(sweep,1200);   // safety re-apply after app.js's first render
    setTimeout(sweep,4000);
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
