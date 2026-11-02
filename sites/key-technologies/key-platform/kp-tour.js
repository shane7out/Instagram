/* KEY Platform guided tour: walk through every demo in order.
   Start it from the demo library ("Start the tour"). On each demo a bar at the bottom shows where you are,
   with Back, Next and End tour. The tour state lives only in this browser tab (sessionStorage). */
(function(){
'use strict';
var KEY='kpTour';
var me=document.currentScript;var BASE=me?me.src.replace(/kp-tour\.js(\?.*)?$/,''):'';
function active(){try{return sessionStorage.getItem(KEY)==='1'}catch(e){return false}}
function setActive(v){try{if(v)sessionStorage.setItem(KEY,'1');else sessionStorage.removeItem(KEY)}catch(e){}}
function load(){return fetch(BASE+'demos/list.json',{cache:'no-cache'}).then(function(r){return r.json()})}
window.KPTour={
 start:function(){setActive(true);load().then(function(L){location.href=BASE+L[0].href}).catch(function(){setActive(false)})},
 end:function(){setActive(false)}
};
function bar(L,i){
 var cur=L[i],prev=L[i-1],next=L[i+1];
 var d=document.createElement('div');d.className='kp-tourbar';d.setAttribute('role','region');d.setAttribute('aria-label','Demo tour');
 function esc(t){return String(t).replace(/[&<>"]/g,function(x){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[x]})}
 d.innerHTML='<div class="kp-tourin"><a class="kp-tbtn" id="kpTPrev" href="'+(prev?BASE+prev.href:'#')+'"'+(prev?'':' aria-disabled="true"')+'>&larr; Back</a>'+
  '<div class="kp-tmid"><b>Tour: demo '+(i+1)+' of '+L.length+'</b><span>'+esc(cur.title)+'</span><span class="kp-tprog"><i style="width:'+Math.round((i+1)/L.length*100)+'%"></i></span></div>'+
  '<a class="kp-tbtn kp-tnext" id="kpTNext" href="'+(next?BASE+next.href:BASE+'index.html#library')+'">'+(next?'Next &rarr;':'Finish')+'</a>'+
  '<button type="button" class="kp-tbtn kp-tend" id="kpTEnd" aria-label="End the tour">End tour</button></div>';
 document.body.appendChild(d);document.body.classList.add('kp-touring');
 d.querySelector('#kpTEnd').onclick=function(){setActive(false);d.remove();document.body.classList.remove('kp-touring')};
 if(!next)d.querySelector('#kpTNext').addEventListener('click',function(){setActive(false)});
 var pv=d.querySelector('#kpTPrev');if(!prev)pv.addEventListener('click',function(e){e.preventDefault()});
 document.addEventListener('keydown',function(e){var t=e.target&&e.target.tagName;if(/INPUT|TEXTAREA|SELECT/.test(t)||e.metaKey||e.ctrlKey||e.altKey)return;
  if(e.key==='ArrowRight'&&next){document.getElementById('kpTNext').click()}
  if(e.key==='ArrowLeft'&&prev){document.getElementById('kpTPrev').click()}});
}
function init(){
 if(!active()||!document.querySelector('.kp-main'))return;
 var here=location.pathname.replace(/^.*key-platform\//,'');if(here===''||here==='index.html'||here==='partners.html')return;
 load().then(function(L){var i=-1;L.forEach(function(x,k){if(here===x.href||here===x.href.replace(/index\.html$/,''))i=k});if(i>=0)bar(L,i)}).catch(function(){});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
