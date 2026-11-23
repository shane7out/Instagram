/* "What keys are for": use them (food, experiences, meet and greets, trade and barter) and the big giveaway goals
   (cars, houses, cash, trips). Use: <div class="uses"></div>  or  <div class="uses c"></div> for the compact tour version. */
(function(){
"use strict";
var S='fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"';
function ic(p){return '<svg viewBox="0 0 24 24" width="30" height="30" '+S+' stroke-width="1.7" aria-hidden="true">'+p+'</svg>'}
var USE=[
 ["Parties","Parties for the community. They are coming.",ic('<path d="M5.8 11.3 2 22l10.7-3.79"/><path d="M4 3h.01"/><path d="M22 8h.01"/><path d="M15 2h.01"/><path d="M22 20h.01"/><path d="M11 13c1.93 1.93 2.83 4.17 2 5-.83.83-3.07-.07-5-2-1.93-1.93-2.83-4.17-2-5 .83-.83 3.07.07 5 2Z"/><path d="m22 2-2.24.75a2.9 2.9 0 0 0-1.96 3.12c.1.86-.57 1.63-1.45 1.63h-.38c-.86 0-1.6.6-1.76 1.44L14 10"/>')],
 ["Events","VIP nights, tastings and more",ic('<path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/><path d="M13 5v2"/><path d="M13 11v2"/><path d="M13 17v2"/>')],
 ["Food","Free meals at the restaurants we work with, all around the world",ic('<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>')],
 ["Meet and greets","Meet people and the places you love",ic('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>')],
 ["Trade and barter","List, buy and trade in the marketplace",ic('<path d="m16 3 4 4-4 4"/><path d="M20 7H4"/><path d="m8 21-4-4 4-4"/><path d="M4 17h16"/>')]
];
var G=[
 ["Cars",'<path d="M10 54V47q0-4 5-5l21-5 14-12q3-3 8-3h22q6 0 10 5l9 10 9 4q5 2 5 6v7q0 3-3 3h-6M26 57h62M10 54q0 3 3 3h3"/><circle cx="34" cy="57" r="9"/><circle cx="94" cy="57" r="9"/><circle cx="34" cy="57" r="3.5"/><circle cx="94" cy="57" r="3.5"/><path d="M52 27 42 37h28V27ZM74 27v10h18l-6-8q-2-2-6-2Z"/>'],
 ["Houses",'<path d="M14 44 60 10l46 34M22 38v32h76V38M84 22V12h10v20"/><path d="M52 70V52h16v18M30 46h14v12H30zM76 46h14v12H76z"/>'],
 ["Cash",'<path d="M18 18h84a6 6 0 0 1 6 6"/><rect x="12" y="24" width="96" height="48" rx="6"/><rect x="20" y="31" width="80" height="34" rx="3"/><circle cx="60" cy="48" r="10"/><path d="M60 42v12M63.5 44.5c-1-1.4-5.5-1.8-6.2.4-.7 2.3 6.4 1.4 6.4 4 0 2.4-5.4 2.6-6.6.6" stroke-width="2"/><path d="M26 48h.01M94 48h.01" stroke-width="4"/>'],
 ["Trips",'<path d="M104 26c4-4 4-10 0-12s-8 0-12 4L72 38 26 28l-6 6 38 16-14 16-14-2-4 4 14 8 8 14 4-4-2-14 16-14 16 38 6-6-10-46z" transform="translate(-4 -6) scale(.84)"/>']
];
var css=".uses{max-width:440px;margin:18px auto;font-family:Lato,system-ui,sans-serif;color:#fff;text-align:center}"
+".uses .ey{margin:0 0 10px;font-size:15px;letter-spacing:.3em;font-weight:900;color:#00a8e1;text-transform:uppercase}"
+".uses h2{margin:0 0 6px;font-size:30px;line-height:1.15;font-weight:900}.uses h2 span{color:#00a8e1}"
+".uses .sub{margin:0 0 18px;font-size:19px;line-height:1.45;color:rgba(255,255,255,.92)}"
+".uses .ug{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:0 0 26px}.uses .ut:last-child:nth-child(odd){grid-column:1/-1}.uses .ut.first{border-color:#00a8e1;box-shadow:0 0 0 2px rgba(0,168,225,.25)}"
+".uses .ut{padding:16px 12px 14px;border-radius:18px;background:linear-gradient(160deg,#18283a,#101b27);border:1px solid rgba(255,255,255,.16);text-align:center}"
+".uses .ut i{display:flex;align-items:center;justify-content:center;width:56px;height:56px;margin:0 auto 10px;border-radius:50%;border:1.5px solid rgba(0,168,225,.7);color:#00a8e1;background:radial-gradient(circle,rgba(0,168,225,.22),rgba(0,168,225,.04))}"
+".uses .ut b{display:block;font-size:20px;line-height:1.15;font-weight:900}.uses .ut span{display:block;margin-top:5px;font-size:17px;line-height:1.35;color:rgba(255,255,255,.88)}"
+".uses .gg{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:0 0 12px}"
+".uses .gp{padding:14px 10px 12px;border-radius:18px;background:radial-gradient(120% 90% at 50% 0%,rgba(0,168,225,.28),rgba(16,27,39,1) 70%);border:1px solid rgba(0,168,225,.5);text-align:center}"
+".uses .gp svg{display:block;width:100%;max-width:150px;height:auto;margin:0 auto 6px;color:#fff}.uses .gp svg .ac{color:#00a8e1}"
+".uses .gp b{display:block;font-size:20px;letter-spacing:.2em;text-transform:uppercase;font-weight:900}"
+".uses .fine{margin:8px 4px 0;font-size:17px;line-height:1.45;color:rgba(255,255,255,.88)}"
+".uses.c{margin:6px auto}.uses.c .ug{gap:8px;margin:0 0 14px}.uses.c .ut{padding:10px 8px 10px}.uses.c .ut i{width:44px;height:44px;margin-bottom:6px}.uses.c .ut i svg{width:24px;height:24px}.uses.c .ut b{font-size:18px}.uses.c .ut span{display:none}"
+".uses.c .gg{gap:8px;margin:0 0 8px}.uses.c .gp{padding:8px 6px 8px}.uses.c .gp svg{max-width:96px;margin-bottom:2px}.uses.c .gp b{font-size:16px}.uses.c .ey{margin-bottom:8px;font-size:14px}.uses.c .fine{font-size:16px;margin-top:6px}";
function init(){
 if(!document.getElementById("usescss")){var st=document.createElement("style");st.id="usescss";st.textContent=css;document.head.appendChild(st)}
 var all=document.querySelectorAll(".uses:not([data-done])");
 for(var k=0;k<all.length;k++){
  var u=all[k];u.setAttribute("data-done","1");var cp=/(^|\s)c(\s|$)/.test(u.className);
  var h='<p class="ey">'+(cp?'Use them':'What keys are for')+'</p>';
  if(!cp)h+='<h2>Parties. Events. Food. <span>Win big.</span></h2><p class="sub">Keys are free to get. Go to parties, events and great food, meet people, and trade.</p>';
  h+='<div class="ug">';
  for(var i=0;i<USE.length;i++)h+='<div class="ut'+(i===0?' first':'')+'"><i>'+USE[i][2]+'</i><b>'+USE[i][0]+'</b><span>'+USE[i][1]+'</span></div>';
  h+='</div><p class="ey">'+(cp?'Big giveaway goals':'The big giveaways')+'</p><div class="gg">';
  for(var j=0;j<G.length;j++)h+='<div class="gp"><svg viewBox="0 0 120 80" '+S+' stroke-width="2.2" aria-hidden="true">'+G[j][1]+'</svg><b>'+G[j][0]+'</b></div>';
  h+='</div><p class="fine">'+(cp?'Goals, not promises yet.':'These are our goals, not promises yet. Winners are picked by a random number generator. Free to enter. No purchase needed.')+'</p>';
  u.innerHTML=h;
 }
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
window.keyUses=init;
})();
