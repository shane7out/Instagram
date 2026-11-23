/* The hallway of rooms: Room 1 at the front, every room holds 20 people, the hallway never ends.
   Use: <div class="hall" data-you="2"></div>  (data-you is optional: it marks "You are here"). */
(function(){
"use strict";
var css=".hall{position:relative;max-width:440px;margin:16px auto;padding:6px 0 0;text-align:center;font-family:Lato,system-ui,sans-serif}"
+".hall .wl{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}"
+".hall .dr{position:relative;margin:0 auto 10px;border:3px solid #00a8e1;border-radius:28px 28px 8px 8px;background:linear-gradient(#16222f,#0f1b27);padding:10px 8px 12px;color:#fff}"
+".hall .dr b{display:block;font-size:22px;line-height:1.1;font-weight:900;letter-spacing:.08em;text-transform:uppercase}"
+".hall .dr small{display:block;font-size:18px;font-weight:700;color:rgba(255,255,255,.85);margin-top:2px}"
+".hall .pp{display:grid;grid-template-columns:repeat(10,1fr);gap:4px;max-width:260px;margin:8px auto 0}"
+".hall .pp i{display:block;aspect-ratio:1;border-radius:50%;background:#00a8e1}"
+".hall .dr.you{border-color:#fff;box-shadow:0 0 0 4px #00a8e1;background:linear-gradient(#0e4a63,#0f2f43)}"
+".hall .dr.you .yh{display:inline-block;margin-top:8px;padding:4px 14px;border-radius:999px;background:#fff;color:#0f171e;font-weight:900;font-size:18px;letter-spacing:.1em}"
+".hall .dr.f2{opacity:.82}.hall .dr.f3{opacity:.64}.hall .dr.f4{opacity:.46}.hall .dr.f5{opacity:.3}"
+".hall .inf{font-size:64px;line-height:1;font-weight:900;color:#00a8e1;margin-top:2px}"
+".hall .iw{font-size:20px;font-weight:900;margin-top:2px}"
+".hall.c{margin:8px auto}.hall.c .dr{padding:4px 8px 7px;margin-bottom:5px;border-radius:22px 22px 6px 6px}.hall.c .dr b{font-size:20px}.hall.c .dr small{display:none}.hall.c .pp{grid-template-columns:repeat(20,1fr);max-width:300px;gap:2px;margin-top:6px}.hall.c .inf{font-size:44px}.hall.c .iw{font-size:18px;line-height:1.25}.hall.c .dr.you .yh{margin-top:6px}"
+".hall .dr b em{font-style:normal;display:inline-block;margin-left:10px;padding:2px 10px;border-radius:999px;font-size:15px;letter-spacing:.1em;vertical-align:middle}.hall .dr b em.fl{background:rgba(255,255,255,.18);color:#fff}.hall .dr b em.op{background:#00a8e1;color:#0f171e}"
+"@media (prefers-reduced-motion:no-preference){.hall .dr.you{animation:hallglow 2.4s ease-in-out infinite}@keyframes hallglow{50%{box-shadow:0 0 0 8px rgba(0,168,225,.55)}}}";
function init(){
 if(!document.getElementById("hallcss")){var st=document.createElement("style");st.id="hallcss";st.textContent=css;document.head.appendChild(st)}
 var all=document.querySelectorAll(".hall:not([data-done])");
 for(var k=0;k<all.length;k++){
  var h=all[k];h.setAttribute("data-done","1");h.setAttribute("role","img");
  var you=parseInt(h.getAttribute("data-you")||"0",10)||0;var full=parseInt(h.getAttribute("data-full")||"0",10)||0,opn=parseInt(h.getAttribute("data-open")||"0",10)||0;
  h.setAttribute("aria-label","A hallway of rooms. Room 1, Room 2, Room 3 and on with no end. Each room holds 20 people."+(you?" You are in Room "+you+".":""));
  var html='<svg class="wl" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"><path d="M0 0L36 100M100 0L64 100" stroke="rgba(0,168,225,.35)" stroke-width="1.2" fill="none" vector-effect="non-scaling-stroke"/></svg>';
  var cp=/(^|\s)c(\s|$)/.test(h.className),rooms=cp?[1,2,3,4]:[1,2,3,4,5],widths=cp?[100,88,76,64]:[100,86,72,58,46],dots="";for(var d=0;d<20;d++)dots+="<i></i>";
  for(var r=0;r<rooms.length;r++){
   var n=rooms[r],cls="dr"+(r?" f"+(r+1):"")+(n===you?" you":"");
   html+='<div class="'+cls+'" style="width:'+widths[r]+'%"><b>Room '+n+(n<=full?'<em class="fl">FULL</em>':(n===opn?'<em class="op">OPEN NOW</em>':''))+'</b><small>'+"20 people"+'</small><div class="pp">'+dots+'</div>'+(n===you?'<span class="yh">YOU ARE HERE</span>':'')+'</div>';
  }
  html+='<div class="inf" aria-hidden="true">&infin;</div><div class="iw">20 people in every room. It never ends.'+'</div>';
  if(you>rooms.length)html+='<div class="dr you" style="width:60%;margin-top:12px"><b>Room '+you+'</b><small>20 people</small><span class="yh">YOU ARE HERE</span></div>';
  h.innerHTML=html;
 }
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
window.keyHall=init;
})();
