/*
STAGED: proves the dashboard bridge (DASHSDK01) really signs the Firebase live connection in as the owner, against the Auth + Database emulators
with the dashboard lock rules. Run: bash .github/db-task/rules/run-dashboard-sdk-test.sh
*/
const fs=require('fs'),http=require('http');const {chromium}=require('playwright');
const AUTH='http://127.0.0.1:9099', DB='http://127.0.0.1:9000';
const dash=fs.readFileSync(process.env.DASH_COPY,'utf8');
let bridge=dash.match(/<!--DASHSDK01-START-->[\s\S]*?<!--DASHSDK01-END-->/)[0].replace('https://www.gstatic.com/firebasejs/10.12.0/','/fb/');
const page=`<!doctype html><html><head><meta charset=utf-8><script defer src="/fb/firebase-app-compat.js"></script><script defer src="/fb/firebase-database-compat.js"></script>${bridge}</head><body><pre id=o></pre><script>
function log(m){document.getElementById('o').textContent+=m+'\\n';}
window.addEventListener('load',function(){
 firebase.initializeApp({databaseURL:'${DB}?ns=demo-lvr-default-rtdb',projectId:'lvr-data-a60c1'});
 var db=firebase.database();
 db.ref('dashboard_crec').once('value').then(function(v){log('READ OK '+Object.keys(v.val()||{}).join(','));},function(e){log('READ DENIED');});
 window.writeTest=function(){return db.ref('dashboard_crec/w1').set({name:'sdk write'}).then(function(){return 'WRITE OK'},function(){return 'WRITE DENIED'});};
});
</script></body></html>`;
const srv=http.createServer((q,r)=>{ if(q.url==='/'){r.setHeader('content-type','text/html');r.end(page);} else if(q.url.startsWith('/fb/')){const f=process.env.FB_DIR+'/node_modules/firebase/'+q.url.slice(4);if(fs.existsSync(f)){r.setHeader('content-type','text/javascript');r.end(fs.readFileSync(f));}else{r.statusCode=404;r.end();}} else {r.statusCode=404;r.end();}});
let fails=0;const ok=(n,c)=>{console.log((c?'PASS':'FAIL')+'  '+n);if(!c)fails++;};
(async()=>{
 await new Promise(r=>srv.listen(8201,r));
 const su=await (await fetch(AUTH+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:'owner@example.test',password:'correct-horse-1',returnSecureToken:true})})).json();
 const UID=su.localId;
 const frag=JSON.parse(fs.readFileSync(process.env.LOCK_RULES,'utf8').replace(/__OWNER_UID__/g,UID));
 const rr=await fetch(DB+'/.settings/rules.json?ns=demo-lvr-default-rtdb',{method:'PUT',headers:{Authorization:'Bearer owner'},body:JSON.stringify({rules:Object.assign({'ownerAuth':{'.read':true,'.write':false}},frag)})});
 ok('rules loaded',rr.status===200);
 await fetch(DB+'/dashboard_crec/seed.json?ns=demo-lvr-default-rtdb',{method:'PUT',headers:{Authorization:'Bearer owner'},body:JSON.stringify({name:'Seed Cafe'})});
 await fetch(DB+'/ownerAuth/apiKey.json?ns=demo-lvr-default-rtdb',{method:'PUT',headers:{Authorization:'Bearer owner'},body:JSON.stringify('fake-web-key')});
 const b=await chromium.launch();const ctx=await b.newContext();
 await ctx.route(/identitytoolkit\.googleapis\.com|securetoken\.googleapis\.com/,async route=>{const u=new URL(route.request().url());const rq=route.request();
   const resp=await fetch(AUTH+'/'+u.host+u.pathname+u.search,{method:rq.method(),headers:{'content-type':rq.headers()['content-type']||'application/json'},body:rq.postData()||undefined});
   route.fulfill({status:resp.status,headers:{'content-type':'application/json','access-control-allow-origin':'*'},body:await resp.text()});});
 const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.addInitScript(()=>{try{localStorage.setItem('lvrSdkApiKey','fake-web-key')}catch(e){}});
 await p.goto('http://localhost:8201/');await p.waitForTimeout(1500);
 let o=await p.textContent('#o');ok('signed out: locked list is refused ('+o.trim()+')',/READ DENIED/.test(o));
 ok('signed out: SDK write refused',await p.evaluate(()=>writeTest())==='WRITE DENIED');
 // owner signs in through the bridge (what the owner sign-in box calls) -> page reloads once
 const nav=p.waitForNavigation({timeout:8000}).catch(()=>null);
 await p.evaluate(()=>{OWNER_AUTH_SDK.signIn('owner@example.test','correct-horse-1')});
 await nav;await p.waitForTimeout(1800);
 o=await p.textContent('#o');ok('signed in (after the one reload): list loads ('+o.trim()+')',/READ OK seed/.test(o));
 ok('signed in: SDK write works',await p.evaluate(()=>writeTest())==='WRITE OK');
 // a fresh load keeps the sign-in (browser remembers it)
 await p.reload();await p.waitForTimeout(1500);o=await p.textContent('#o');ok('next visit still signed in',/READ OK/.test(o));
 await p.evaluate(()=>{OWNER_AUTH_SDK.signOut()});await p.waitForTimeout(800);await p.reload();await p.waitForTimeout(1500);o=await p.textContent('#o');
 ok('after sign-out the list is refused again',/READ DENIED/.test(o));
 // a different (non-owner) account signed in through the same bridge gets nothing
 await fetch(AUTH+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:'other@example.test',password:'whatever-12',returnSecureToken:true})});
 await p.evaluate(()=>{sessionStorage.clear();OWNER_AUTH_SDK.signIn('other@example.test','whatever-12')});await p.waitForTimeout(2500);o=await p.textContent('#o');
 ok('a signed-in non-owner is refused',/READ DENIED/.test(o)&&!/READ OK/.test(o));
 ok('no page errors ('+errs.join('|')+')',errs.length===0);
 await b.close();srv.close();process.exit(fails?1:0);
})().catch(e=>{console.log('ERR',e);process.exit(2)});
