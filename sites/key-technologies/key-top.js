/* The gold key stays fixed at the top of every Key Rewards page. It never moves.
   Inside the swipe deck (key-tour.html, ?embed=1) the deck draws the key, so this stays out of the way. */
(function(){
"use strict";
var embedded=false;try{embedded=window.self!==window.top}catch(e){embedded=true}
if(/[?&]embed=1/.test(location.search))embedded=true;
var css=".klw,.brandline,.pbrand,.fromline,p.brand{display:none!important}";
if(embedded){css+="#ktop{display:none!important}"}
else{css+="#ktop{position:fixed;top:0;left:0;right:0;z-index:9999;height:calc(env(safe-area-inset-top,0px) + 54px);padding-top:calc(env(safe-area-inset-top,0px) + 6px);display:flex;align-items:center;justify-content:center;background:#0f171e;border-bottom:1px solid rgba(255,255,255,.12)}#ktop a{display:flex;align-items:center;justify-content:center;height:100%;padding:0 20px}#ktop img{height:26px;width:auto;display:block}#ktop a:focus-visible{outline:3px solid #fff;outline-offset:-3px}body{padding-top:calc(env(safe-area-inset-top,0px) + 54px)!important}"}
function go(){
 var st=document.createElement("style");st.id="ktopcss";st.textContent=css;document.head.appendChild(st);
 if(!embedded&&!document.getElementById("ktop")){var d=document.createElement("div");d.id="ktop";d.innerHTML='<a href="keys/" aria-label="Key Rewards"><img src="brand/key-gold.svg" alt="Key Rewards" width="56" height="26"></a>';document.body.insertBefore(d,document.body.firstChild)}
}
if(document.body)go();else document.addEventListener("DOMContentLoaded",go);
})();
