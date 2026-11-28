// Fake Firebase for a dry run of deploy-dashboard-lock.sh (no network, nothing real is touched)
const fs=require('fs'),cp=require('child_process'),os=require('os'),path=require('path');
const MODE=process.env.MOCK_MODE||'good';
const OLD_WRITE="newData.exists() && (!data.child('customrecords').exists() || newData.child('customrecords').exists()) && (!data.child('staging_approved').exists() || newData.child('staging_approved').exists()) && (!data.child('staging_added').exists() || newData.child('staging_added').exists()) && (!data.child('records').exists() || newData.child('records').exists())";
const UID='abcdefghij0123456789ABCDEF12';
let rules={rules:{lvr_points:{x:1},'$rest':{'.read':true,'.write':MODE==='drift'?'true':OLD_WRITE}}};
let locked=false;
const frag=fs.readFileSync(process.env.FRAG,'utf8');
cp.execSync=(c)=>{ if(/gcloud/.test(c)) return Buffer.from('tok'); return Buffer.from(''); };
const answers=['owner@example.test\n','pw\n'];let ai=0,cur='';
const realOpen=fs.openSync,realRead=fs.readSync;
fs.openSync=function(p,...a){ if(p==='/dev/tty') return 9999; return realOpen.call(fs,p,...a); };
fs.readSync=function(fd,buf,off,len,pos){ if(fd===9999){ if(!cur){cur=answers[ai++]||'\n';} const ch=cur[0];cur=cur.slice(1);buf[off]=ch.charCodeAt(0);return 1;} return realRead.call(fs,fd,buf,off,len,pos); };
fs.closeSync=(orig=>function(fd){ if(fd===9999) return; return orig.call(fs,fd); })(fs.closeSync);
const home=process.env.HOME_FAKE; os.homedir=()=>home;
const R=(s,b)=>({status:s,ok:s===200,json:async()=>JSON.parse(b),text:async()=>b});
global.fetch=async(url,opts={})=>{ const u=String(url),m=(opts.method||'GET').toUpperCase();
 if(u.includes('lvr-data-a60c1.web.app')) return R(200,MODE==='nobridge'?'<html></html>':'<html>DASHSDK01 OWNER_AUTH_SDK</html>');
 if(u.includes('/ownerAuth/apiKey.json')) return R(200,'"fake-key"');
 if(u.includes('identitytoolkit')) return R(200,JSON.stringify({idToken:'ID',localId:UID}));
 if(u.includes('/.settings/rules.json')){ if(m==='PUT'){ rules=JSON.parse(opts.body); locked=!!(rules.rules['$rest']&&rules.rules['$rest']['.read']!==true); console.log('   [mock] rules PUT, locked='+locked); return R(200,'{}'); } return R(200,JSON.stringify(rules)); }
 if(u.includes('dashboard-lock-rules.json')) return R(200,frag);
 // data calls
 const hasAuth=/auth=ID/.test(u); const isLockedPath=/\/(dashboard_crec|dashboard|staging_approved)(\.json|\/)/.test(u);
 if(isLockedPath){ if(!locked) return R(200,'null'); if(MODE==='broken'&&hasAuth) return R(401,'{}'); return hasAuth?R(200,'null'):R(401,'{"error":"Permission denied"}'); }
 return R(200,'null'); };
