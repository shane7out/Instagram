// One-time site patch for the Batman Cards tab (owner, 2026-08-03).
// - gen.js: add 'Batman' to every non-vehicle type exemption list
// - inject-home.js: same, plus no-mileage rendering
// - index.html: add the 🦇 Batman Cards chip next to 🏺 Antiques
// - manual.json + watch-batman.js: apAll:true so the tab never deal-gates them
// Backs up each file to *.bak-batman. Prints a replacement-count report; run gen after.
const fs=require('fs'), path=require('path');
const ROOT=path.join(__dirname,'..');
let report=[];
function patch(file, rules){
  const p=path.join(ROOT,file);
  let t=fs.readFileSync(p,'utf8');
  const orig=t;
  rules.forEach(([re,rep,label])=>{
    const n=(t.match(re)||[]).length;
    t=t.replace(re,rep);
    report.push(file+' :: '+label+' -> '+n+' replacement(s)');
  });
  if(t!==orig){ fs.writeFileSync(p+'.bak-batman',orig); fs.writeFileSync(p,t); }
  return t!==orig;
}

// gen.js — negation chains (&&) and inclusion chains (||) keyed off 'Room', FRESH_EXEMPT object
patch('_tools/gen.js',[
  [/c\.type\s*!==\s*'Room'/g, "c.type !== 'Room' && c.type !== 'Batman'", "!==Room chains"],
  [/c\.type\s*===\s*'Room'/g, "c.type === 'Room' || c.type === 'Batman'", "===Room chains"],
  [/PVCars\s*:\s*1\s*}/g, "PVCars:1, Batman:1 }", "FRESH_EXEMPT"],
]);

// inject-home.js — static-grid exclusion (Room chain) + no-mileage list (ends at 'Free')
patch('_tools/inject-home.js',[
  [/c\.type\s*!==\s*'Room'/g, "c.type!=='Room'&&c.type!=='Batman'", "!==Room chain"],
  [/c\.type\s*===\s*'Free'\)/g, "c.type==='Free'||c.type==='Batman')", "nonveh list"],
]);

// index.html — the chip row
patch('index.html',[
  [/(<button class="chip chip-antique" data-type="Antique"[^>]*>🏺 Antiques<\/button>)/,
   '$1\n        <button class="chip chip-batman" data-type="Batman" aria-pressed="false">🦇 Batman Cards</button>',
   "batman chip"],
]);

// watch-batman.js — future imports carry apAll:true
patch('_tools/watch-batman.js',[
  [/type:'Batman',/g, "type:'Batman',apAll:true,", "apAll on imports"],
]);

// manual.json — existing Batman entries get apAll:true
const MP=path.join(ROOT,'_tools','manual.json');
const manual=JSON.parse(fs.readFileSync(MP,'utf8'));
let n=0;
manual.forEach(e=>{ if(e.type==='Batman'&&!e.apAll){ e.apAll=true; n++; } });
if(n){ fs.writeFileSync(MP+'.bak-batman',fs.readFileSync(MP)); fs.writeFileSync(MP,JSON.stringify(manual,null,1)); }
report.push('manual.json :: apAll on existing Batman entries -> '+n);

console.log(report.join('\n'));
console.log('PATCH DONE');
