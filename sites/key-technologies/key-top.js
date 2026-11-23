/* The gold key stays fixed at the top of every Key Rewards page. It never moves.
   Inside the swipe deck (key-tour.html, ?embed=1) the deck draws the key, so this stays out of the way. */
(function(){
"use strict";
var embedded=false;try{embedded=window.self!==window.top}catch(e){embedded=true}
if(/[?&]embed=1/.test(location.search))embedded=true;
var css=".klw,.brandline,.pbrand,.fromline,p.brand{display:none!important}";
if(embedded){css+="#ktop{display:none!important}"}
else{css+="#ktop{position:fixed;top:0;left:0;right:0;z-index:9999;height:calc(env(safe-area-inset-top,0px) + 88px);padding-top:calc(env(safe-area-inset-top,0px) + 16px);display:flex;align-items:center;justify-content:center;background:radial-gradient(55% 140% at 50% 70%,rgba(231,174,45,.2),rgba(231,174,45,0) 70%),#0f171e;border-bottom:1px solid rgba(231,174,45,.35)}#ktop a{display:flex;align-items:center;justify-content:center;height:100%;padding:0 20px}#ktop img{height:62px;width:auto;display:block;filter:drop-shadow(0 0 14px rgba(231,174,45,.55)) drop-shadow(0 2px 3px rgba(0,0,0,.5))}#ktop a:focus-visible{outline:3px solid #fff;outline-offset:-3px}body{padding-top:calc(env(safe-area-inset-top,0px) + 88px)!important}"}
function go(){
 var st=document.createElement("style");st.id="ktopcss";st.textContent=css;document.head.appendChild(st);
 if(!embedded&&!document.getElementById("ktop")){var d=document.createElement("div");d.id="ktop";d.innerHTML='<a href="keys/" aria-label="Key Rewards"><img src="brand/key-gold.svg" alt="Key Rewards" width="134" height="62"></a>';document.body.insertBefore(d,document.body.firstChild)}
}
if(document.body)go();else document.addEventListener("DOMContentLoaded",go);
})();
