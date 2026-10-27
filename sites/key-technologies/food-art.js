/* Illustrated food "photos" for the demo menu. Every picture is drawn in code (SVG), so there are
   no image files and nothing to license. window.FoodArt.svg(id) returns an <svg> string (4:3). */
(function () {
  var W = 400, H = 300;
  function rng(seed) { var a = seed >>> 0; return function () { a |= 0; a = a + 0x6D2B79F5 | 0; var t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
  function f(n) { return Math.round(n * 10) / 10; }

  var DEFS = '<defs>' +
    '<radialGradient id="faPlate" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#ffffff"/><stop offset=".7" stop-color="#e9ecef"/><stop offset="1" stop-color="#c9ced4"/></radialGradient>' +
    '<radialGradient id="faBowl" cx=".4" cy=".3" r=".9"><stop offset="0" stop-color="#4a5d7a"/><stop offset="1" stop-color="#1d2a40"/></radialGradient>' +
    '<radialGradient id="faRice" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#e9e5da"/></radialGradient>' +
    '<radialGradient id="faMeat" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="#e8b25c"/><stop offset=".6" stop-color="#b9702a"/><stop offset="1" stop-color="#7d4318"/></radialGradient>' +
    '<radialGradient id="faGreen" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="#7fc25a"/><stop offset="1" stop-color="#2f6e24"/></radialGradient>' +
    '<radialGradient id="faCheese" cx=".4" cy=".4" r=".8"><stop offset="0" stop-color="#ffd978"/><stop offset="1" stop-color="#f0a93a"/></radialGradient>' +
    '<radialGradient id="faPep" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="#d6513c"/><stop offset="1" stop-color="#8d1f17"/></radialGradient>' +
    '<radialGradient id="faDough" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="#f3cf8b"/><stop offset=".7" stop-color="#d49a4a"/><stop offset="1" stop-color="#a86a24"/></radialGradient>' +
    '<radialGradient id="faCream" cx=".4" cy=".3" r=".9"><stop offset="0" stop-color="#fffaf0"/><stop offset="1" stop-color="#ecdcc0"/></radialGradient>' +
    '<radialGradient id="faChoc" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="#6b3a24"/><stop offset="1" stop-color="#2d150b"/></radialGradient>' +
    '<radialGradient id="faSalmon" cx=".4" cy=".3" r=".9"><stop offset="0" stop-color="#ffa07a"/><stop offset="1" stop-color="#e0623f"/></radialGradient>' +
    '<radialGradient id="faBroth" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#d89a4b"/><stop offset="1" stop-color="#8a4f1b"/></radialGradient>' +
    '<linearGradient id="faWood" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5a3a22"/><stop offset=".5" stop-color="#3f2716"/><stop offset="1" stop-color="#2a190d"/></linearGradient>' +
    '<linearGradient id="faSlate" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#37424f"/><stop offset="1" stop-color="#1c232c"/></linearGradient>' +
    '<linearGradient id="faTea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e9d3b4"/><stop offset="1" stop-color="#b98a58"/></linearGradient>' +
    '<filter id="faShadow" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity=".5"/></filter>' +
    '<filter id="faSoft" x="-10%" y="-10%" width="120%" height="120%"><feDropShadow dx="0" dy="1.5" stdDeviation="1.5" flood-color="#000" flood-opacity=".4"/></filter>' +
    '<filter id="faGrain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="4" result="n"/><feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 .22 0"/></filter>' +
    '<radialGradient id="faVig" cx=".5" cy=".5" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient>' +
    '</defs>';

  function bg(kind) {
    return '<rect width="400" height="300" fill="url(#' + (kind === 'slate' ? 'faSlate' : 'faWood') + ')"/>' +
      (kind === 'wood' ? '<g stroke="#00000033" stroke-width="1.4"><path d="M0 60H400M0 120H400M0 180H400M0 240H400"/></g><g stroke="#ffffff10" stroke-width="1"><path d="M0 62H400M0 122H400M0 182H400M0 242H400"/></g>' : '') +
      '<rect width="400" height="300" filter="url(#faGrain)"/>';
  }
  function finish() { return '<rect width="400" height="300" fill="url(#faVig)"/>'; }

  function plate(cx, cy, r) {
    return '<g filter="url(#faShadow)"><circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="url(#faPlate)"/></g><circle cx="' + cx + '" cy="' + cy + '" r="' + f(r * .78) + '" fill="none" stroke="#00000014" stroke-width="2"/>';
  }
  function bowl(cx, cy, r, inner) {
    return '<g filter="url(#faShadow)"><circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="url(#faBowl)"/></g><circle cx="' + cx + '" cy="' + cy + '" r="' + f(r * .9) + '" fill="#e9eef5"/><circle cx="' + cx + '" cy="' + cy + '" r="' + f(r * .84) + '" fill="' + (inner || '#f4f1ea') + '"/>';
  }
  function grains(R, cx, cy, rad, n, col) {
    var s = '';
    for (var i = 0; i < n; i++) {
      var a = R() * 6.283, d = Math.sqrt(R()) * rad, x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d;
      s += '<ellipse cx="' + f(x) + '" cy="' + f(y) + '" rx="3.4" ry="1.5" transform="rotate(' + f(R() * 180) + ' ' + f(x) + ' ' + f(y) + ')" fill="' + (col || '#fffdf6') + '" stroke="#00000014" stroke-width=".5"/>';
    }
    return s;
  }
  function seeds(R, cx, cy, rad, n, col) {
    var s = '';
    for (var i = 0; i < n; i++) { var a = R() * 6.283, d = Math.sqrt(R()) * rad; s += '<ellipse cx="' + f(cx + Math.cos(a) * d) + '" cy="' + f(cy + Math.sin(a) * d) + '" rx="1.6" ry=".9" fill="' + (col || '#fff') + '"/>'; }
    return s;
  }
  function floret(x, y, s) {
    var o = '<g filter="url(#faSoft)"><rect x="' + f(x - 1.6 * s) + '" y="' + f(y) + '" width="' + f(3.2 * s) + '" height="' + f(7 * s) + '" rx="1.5" fill="#8fc46a"/>';
    [[-5, -3], [0, -6], [5, -3], [-2.5, 0], [3, 0]].forEach(function (p) { o += '<circle cx="' + f(x + p[0] * s) + '" cy="' + f(y + p[1] * s) + '" r="' + f(4.6 * s) + '" fill="url(#faGreen)"/>'; });
    return o + '</g>';
  }
  function chunk(x, y, w, h, rot, R) {
    return '<g transform="rotate(' + rot + ' ' + x + ' ' + y + ')" filter="url(#faSoft)"><rect x="' + f(x - w / 2) + '" y="' + f(y - h / 2) + '" width="' + w + '" height="' + h + '" rx="' + f(h / 2.6) + '" fill="url(#faMeat)"/>' +
      '<path d="M' + f(x - w / 2 + 4) + ' ' + f(y - h / 5) + 'l' + f(w - 8) + ' 3M' + f(x - w / 2 + 4) + ' ' + f(y + h / 5) + 'l' + f(w - 8) + ' 3" stroke="#5a2f10" stroke-width="1.6" stroke-linecap="round" opacity=".55"/>' +
      '<ellipse cx="' + f(x - w / 5) + '" cy="' + f(y - h / 4) + '" rx="' + f(w / 5) + '" ry="2.2" fill="#fff" opacity=".28"/></g>';
  }
  function slice(x, y, r, col) { return '<g filter="url(#faSoft)"><circle cx="' + x + '" cy="' + y + '" r="' + r + '" fill="' + col + '"/><circle cx="' + x + '" cy="' + y + '" r="' + f(r * .55) + '" fill="#fff" opacity=".18"/></g>'; }
  function scallions(R, cx, cy, rad, n) {
    var s = '';
    for (var i = 0; i < n; i++) { var a = R() * 6.283, d = Math.sqrt(R()) * rad, x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d; s += '<circle cx="' + f(x) + '" cy="' + f(y) + '" r="2.4" fill="#9bd16a"/><circle cx="' + f(x) + '" cy="' + f(y) + '" r="1.1" fill="#e9f7c8"/>'; }
    return s;
  }

  var ART = {};
  ART.chickenBowl = function () {
    var R = rng(11);
    var s = bg('wood') + bowl(200, 150, 124, '#ffffff') + '<circle cx="200" cy="150" r="104" fill="url(#faRice)"/>' + grains(R, 200, 150, 100, 150);
    s += chunk(150, 120, 46, 24, -20, R) + chunk(200, 105, 50, 26, 8, R) + chunk(246, 125, 46, 24, 28, R) + chunk(168, 158, 44, 24, 12, R) + chunk(228, 170, 44, 24, -14, R);
    s += floret(122, 160, 1.05) + floret(274, 150, 1) + floret(196, 198, 1.1) + floret(250, 96, .9);
    [[116, 128], [280, 188], [160, 92]].forEach(function (p) { s += slice(p[0], p[1], 6.5, '#f08a2c'); });
    return s + seeds(R, 200, 140, 90, 60, '#fff3d6') + scallions(R, 200, 150, 90, 12) + finish();
  };
  ART.friedRice = function () {
    var R = rng(23);
    var s = bg('slate') + plate(200, 150, 130) + '<circle cx="200" cy="148" r="92" fill="#e8c76e"/>' + grains(R, 200, 148, 90, 170, '#f6e2a0');
    for (var i = 0; i < 26; i++) { var a = R() * 6.283, d = Math.sqrt(R()) * 86; s += '<circle cx="' + f(200 + Math.cos(a) * d) + '" cy="' + f(148 + Math.sin(a) * d) + '" r="' + f(2 + R() * 1.6) + '" fill="' + (['#e9a21c', '#5fae3a', '#f08a2c', '#fff7c4'][i % 4]) + '"/>'; }
    for (var k = 0; k < 6; k++) {
      var ang = k * 1.05 + .3, x = 200 + Math.cos(ang) * 58, y = 148 + Math.sin(ang) * 52;
      s += '<g transform="rotate(' + f(ang * 57.3 + 90) + ' ' + f(x) + ' ' + f(y) + ')" filter="url(#faSoft)"><path d="M' + f(x - 15) + ' ' + f(y) + 'q15 -26 30 0q-6 18 -30 0z" fill="#f4a384"/><path d="M' + f(x - 13) + ' ' + f(y - 2) + 'q13 -16 26 0" fill="none" stroke="#fff" stroke-width="2" opacity=".5"/><path d="M' + f(x + 15) + ' ' + f(y) + 'l7 6l-1 -10z" fill="#e0775a"/></g>';
    }
    return s + scallions(R, 200, 148, 80, 22) + finish();
  };
  ART.salmonBowl = function () {
    var R = rng(37);
    var s = bg('wood') + bowl(200, 150, 124, '#ffffff') + '<circle cx="200" cy="150" r="104" fill="url(#faRice)"/>' + grains(R, 200, 150, 100, 130);
    s += '<g filter="url(#faSoft)"><rect x="136" y="96" width="128" height="52" rx="22" transform="rotate(-8 200 122)" fill="url(#faSalmon)"/><path d="M146 108q54 -10 112 -4M144 122q56 -8 116 -2M146 136q54 -6 112 -2" stroke="#ffd9c4" stroke-width="3" fill="none" opacity=".75" transform="rotate(-8 200 122)"/></g>';
    for (var i = 0; i < 6; i++) s += '<g filter="url(#faSoft)"><path d="M' + (128 + i * 14) + ' 178q12 -24 24 0q-12 12 -24 0z" fill="#9fcf6a"/><path d="M' + (131 + i * 14) + ' 178q9 -14 17 0" stroke="#e9f3b9" stroke-width="2" fill="none"/></g>';
    for (var j = 0; j < 14; j++) { var a = R() * 6.283, d = 22 + R() * 30; s += '<ellipse cx="' + f(280 + Math.cos(a) * d / 2.4) + '" cy="' + f(176 + Math.sin(a) * d / 2.4) + '" rx="5" ry="3" fill="#5c9a3c" transform="rotate(' + f(R() * 180) + ' 280 176)"/>'; }
    s += '<g filter="url(#faSoft)"><rect x="262" y="96" width="30" height="40" rx="3" fill="#1d2b22" transform="rotate(14 276 116)"/></g>';
    return s + seeds(R, 200, 150, 90, 70, '#fff3d6') + finish();
  };
  ART.pizza = function () {
    var R = rng(41);
    var s = bg('wood') + '<g filter="url(#faShadow)"><rect x="52" y="18" width="296" height="264" rx="26" fill="#9c6b3a"/><rect x="60" y="26" width="280" height="248" rx="20" fill="#b9814a"/></g>';
    s += '<g filter="url(#faShadow)"><circle cx="200" cy="150" r="112" fill="url(#faDough)"/></g><circle cx="200" cy="150" r="96" fill="url(#faCheese)"/>';
    for (var i = 0; i < 40; i++) { var a = R() * 6.283, d = Math.sqrt(R()) * 90; s += '<ellipse cx="' + f(200 + Math.cos(a) * d) + '" cy="' + f(150 + Math.sin(a) * d) + '" rx="' + f(5 + R() * 7) + '" ry="' + f(3 + R() * 4) + '" fill="#ffe7a1" opacity=".55"/>'; }
    [[160, 100], [214, 92], [250, 130], [178, 150], [230, 176], [146, 188], [200, 206], [124, 138], [270, 168], [202, 130]].forEach(function (p) {
      s += slice(p[0], p[1], 17, 'url(#faPep)'); for (var q = 0; q < 4; q++) s += '<circle cx="' + f(p[0] - 7 + R() * 14) + '" cy="' + f(p[1] - 7 + R() * 14) + '" r="2.2" fill="#6a120d" opacity=".7"/>';
    });
    for (var b = 0; b < 7; b++) { var ba = R() * 6.283, bd = R() * 80, bx = 200 + Math.cos(ba) * bd, by = 150 + Math.sin(ba) * bd; s += '<path d="M' + f(bx) + ' ' + f(by) + 'q8 -12 16 0q-8 10 -16 0z" fill="#3f8f2a" transform="rotate(' + f(R() * 360) + ' ' + f(bx) + ' ' + f(by) + ')"/>'; }
    s += '<g stroke="#8a5a1f" stroke-width="2" opacity=".6"><path d="M200 38V262M88 150H312M120 70L280 230M280 70L120 230"/></g>';
    return s + finish();
  };
  ART.garlicKnots = function () {
    var R = rng(53);
    var s = bg('slate') + plate(190, 150, 128);
    [[130, 118], [190, 100], [246, 124], [150, 184], [214, 192], [268, 178]].forEach(function (p) {
      s += '<g filter="url(#faSoft)"><ellipse cx="' + p[0] + '" cy="' + p[1] + '" rx="31" ry="23" transform="rotate(' + f(R() * 40 - 20) + ' ' + p[0] + ' ' + p[1] + ')" fill="url(#faDough)"/><path d="M' + (p[0] - 18) + ' ' + p[1] + 'q18 -18 36 0M' + (p[0] - 16) + ' ' + (p[1] + 6) + 'q16 12 32 0" stroke="#8c571b" stroke-width="3" fill="none" stroke-linecap="round" opacity=".7"/><ellipse cx="' + (p[0] - 8) + '" cy="' + (p[1] - 9) + '" rx="13" ry="3.5" fill="#fff" opacity=".28"/></g>';
      for (var q = 0; q < 7; q++) s += '<rect x="' + f(p[0] - 22 + R() * 44) + '" y="' + f(p[1] - 14 + R() * 28) + '" width="3.2" height="1.6" fill="#4f9c36"/>';
    });
    s += '<g filter="url(#faShadow)"><circle cx="322" cy="70" r="40" fill="#f2f4f6"/></g><circle cx="322" cy="70" r="31" fill="url(#faPep)"/><ellipse cx="316" cy="62" rx="12" ry="6" fill="#fff" opacity=".22"/>';
    return s + finish();
  };
  ART.sundae = function () {
    var R = rng(67);
    var s = bg('wood') + '<g filter="url(#faShadow)"><circle cx="200" cy="154" r="120" fill="#f4f1ea"/></g><circle cx="200" cy="154" r="98" fill="#fbf9f4" stroke="#00000012" stroke-width="2"/>';
    [[150, 150], [210, 126], [250, 166], [172, 198], [226, 206]].forEach(function (p) { s += '<g filter="url(#faSoft)"><rect x="' + (p[0] - 22) + '" y="' + (p[1] - 22) + '" width="44" height="44" rx="5" transform="rotate(' + f(R() * 30 - 15) + ' ' + p[0] + ' ' + p[1] + ')" fill="url(#faChoc)"/><rect x="' + (p[0] - 18) + '" y="' + (p[1] - 18) + '" width="36" height="8" rx="3" fill="#8a5232" opacity=".6" transform="rotate(' + f(R() * 6) + ' ' + p[0] + ' ' + p[1] + ')"/></g>'; });
    s += '<g filter="url(#faShadow)"><circle cx="200" cy="148" r="46" fill="url(#faCream)"/></g><ellipse cx="186" cy="132" rx="20" ry="10" fill="#fff" opacity=".6"/>';
    s += '<path d="M170 140q8 24 18 8q6 22 16 4q8 18 20 -4q8 14 12 -8q-6 -26 -34 -32q-26 4 -32 32z" fill="#4a2414" opacity=".92"/><ellipse cx="190" cy="132" rx="9" ry="4" fill="#fff" opacity=".35"/>';
    s += '<g filter="url(#faSoft)"><circle cx="204" cy="108" r="11" fill="#c2182b"/><ellipse cx="200" cy="104" rx="3.6" ry="2.2" fill="#fff" opacity=".6"/><path d="M204 98q6 -12 16 -16" stroke="#3f7a2a" stroke-width="2.4" fill="none"/></g>';
    for (var i = 0; i < 26; i++) { var a = R() * 6.283, d = 46 + R() * 44; s += '<circle cx="' + f(200 + Math.cos(a) * d) + '" cy="' + f(154 + Math.sin(a) * d) + '" r="1.7" fill="#3a1d10" opacity=".7"/>'; }
    return s + finish();
  };
  ART.tacos = function () {
    var R = rng(79);
    var s = bg('slate') + '<g transform="translate(200 150) scale(1.22) translate(-200 -150)"><g filter="url(#faShadow)"><rect x="30" y="52" width="340" height="196" rx="26" fill="#d9d4c8"/></g><rect x="38" y="60" width="324" height="180" rx="20" fill="#efebe1"/>';
    [[116, 150], [200, 150], [284, 150]].forEach(function (p, i) {
      s += '<g filter="url(#faShadow)"><path d="M' + (p[0] - 40) + ' ' + (p[1] + 40) + 'q40 -110 80 0z" fill="#f0cf74"/></g><path d="M' + (p[0] - 34) + ' ' + (p[1] + 36) + 'q34 -92 68 0" fill="none" stroke="#c99a2f" stroke-width="2" opacity=".7"/>';
      for (var j = 0; j < 11; j++) s += '<circle cx="' + f(p[0] - 22 + R() * 44) + '" cy="' + f(p[1] - 6 + R() * 34) + '" r="' + f(4 + R() * 4) + '" fill="' + ['#8a4a22', '#a35c28', '#6e3a18'][j % 3] + '"/>';
      for (var k = 0; k < 8; k++) s += '<ellipse cx="' + f(p[0] - 24 + R() * 48) + '" cy="' + f(p[1] - 12 + R() * 26) + '" rx="4.2" ry="2.6" fill="' + ['#4f9c36', '#e9e4d0', '#d6513c'][k % 3] + '" transform="rotate(' + f(R() * 180) + ' ' + p[0] + ' ' + p[1] + ')"/>';
    });
    s += '<g filter="url(#faSoft)"><path d="M322 214q22 -22 40 0q-20 14 -40 0z" fill="#b6d84a"/><path d="M326 214q16 -14 32 0" fill="none" stroke="#eaf7a8" stroke-width="2"/></g><g filter="url(#faSoft)"><path d="M44 212q22 -22 40 0q-20 14 -40 0z" fill="#b6d84a"/></g>';
    return s + '</g>' + finish();
  };
  ART.nachos = function () {
    var R = rng(83);
    var s = bg('wood') + '<g filter="url(#faShadow)"><circle cx="200" cy="152" r="124" fill="#2c3440"/></g><circle cx="200" cy="152" r="112" fill="#39424f"/>';
    for (var i = 0; i < 34; i++) { var a = R() * 6.283, d = Math.sqrt(R()) * 92, x = 200 + Math.cos(a) * d, y = 152 + Math.sin(a) * d * .85, r = R() * 360; s += '<g filter="url(#faSoft)" transform="rotate(' + f(r) + ' ' + f(x) + ' ' + f(y) + ')"><path d="M' + f(x - 20) + ' ' + f(y + 14) + 'L' + f(x) + ' ' + f(y - 20) + 'L' + f(x + 20) + ' ' + f(y + 14) + 'z" fill="#e9b94d"/><path d="M' + f(x - 12) + ' ' + f(y + 9) + 'L' + f(x) + ' ' + f(y - 10) + 'L' + f(x + 12) + ' ' + f(y + 9) + 'z" fill="#f6d27a" opacity=".7"/></g>'; }
    for (var m = 0; m < 16; m++) { var b = R() * 6.283, e = Math.sqrt(R()) * 80; s += '<path d="M' + f(200 + Math.cos(b) * e - 18) + ' ' + f(152 + Math.sin(b) * e) + 'q10 -16 22 -2q8 14 -6 18q-14 4 -16 -16z" fill="#ffc94a" opacity=".92"/>'; }
    for (var j = 0; j < 9; j++) { var c = R() * 6.283, g = Math.sqrt(R()) * 80; s += slice(f(200 + Math.cos(c) * g), f(152 + Math.sin(c) * g), 7, '#79b33e') + '<circle cx="' + f(200 + Math.cos(c) * g) + '" cy="' + f(152 + Math.sin(c) * g) + '" r="3" fill="#e9f3b9"/>'; }
    for (var t = 0; t < 12; t++) { var h = R() * 6.283, q = Math.sqrt(R()) * 80; s += '<circle cx="' + f(200 + Math.cos(h) * q) + '" cy="' + f(152 + Math.sin(h) * q) + '" r="3.4" fill="#d6513c"/>'; }
    s += '<g filter="url(#faShadow)"><circle cx="338" cy="62" r="34" fill="#f2f4f6"/></g><circle cx="338" cy="62" r="26" fill="#c43b2a"/>' + seeds(R, 338, 62, 20, 16, '#7bb04a');
    return s + finish();
  };
  ART.churros = function () {
    var R = rng(97);
    var s = bg('slate') + '<g filter="url(#faShadow)"><rect x="40" y="70" width="320" height="170" rx="22" fill="#eee9df"/></g>';
    [[84, 100, -8], [92, 140, -4], [100, 180, 2], [108, 218, 6]].forEach(function (p) {
      s += '<g filter="url(#faSoft)" transform="rotate(' + p[2] + ' ' + p[0] + ' ' + p[1] + ')"><rect x="' + p[0] + '" y="' + p[1] + '" width="190" height="26" rx="13" fill="url(#faDough)"/>';
      for (var i = 0; i < 17; i++) s += '<path d="M' + (p[0] + 10 + i * 10.4) + ' ' + (p[1] + 2) + 'v22" stroke="#9c5f1f" stroke-width="2" opacity=".55"/>';
      for (var q = 0; q < 40; q++) s += '<circle cx="' + f(p[0] + 8 + R() * 174) + '" cy="' + f(p[1] + 3 + R() * 20) + '" r="1.1" fill="#fff" opacity=".9"/>';
      s += '</g>';
    });
    s += '<g filter="url(#faShadow)"><circle cx="318" cy="156" r="52" fill="#ffffff"/></g><circle cx="318" cy="156" r="42" fill="url(#faChoc)"/><ellipse cx="304" cy="142" rx="16" ry="7" fill="#fff" opacity=".3"/>';
    return s + finish();
  };
  ART.ramen = function () {
    var R = rng(101);
    var s = bg('wood') + bowl(200, 150, 128, '#f4f1ea') + '<circle cx="200" cy="150" r="104" fill="url(#faBroth)"/>';
    for (var i = 0; i < 14; i++) { var a = R() * 6.283, d = R() * 86; s += '<ellipse cx="' + f(200 + Math.cos(a) * d) + '" cy="' + f(150 + Math.sin(a) * d) + '" rx="' + f(6 + R() * 8) + '" ry="' + f(3 + R() * 4) + '" fill="#f3c46f" opacity=".35"/>'; }
    for (var n = 0; n < 12; n++) s += '<path d="M' + f(124 + n * 4) + ' ' + f(122 + n * 3) + 'q' + f(24 + R() * 20) + ' ' + f(-20 - R() * 14) + ' ' + f(52 + R() * 30) + ' ' + f(R() * 18) + 'q' + f(-10 - R() * 12) + ' ' + f(24 + R() * 10) + ' ' + f(-30 - R() * 20) + ' ' + f(18 + R() * 8) + '" fill="none" stroke="#f1d27e" stroke-width="4.6" stroke-linecap="round" opacity=".95"/>';
    [[168, 118], [228, 112]].forEach(function (p) { s += '<g filter="url(#faSoft)"><ellipse cx="' + p[0] + '" cy="' + p[1] + '" rx="26" ry="20" fill="#fdf8ec"/><circle cx="' + (p[0] + 2) + '" cy="' + (p[1] + 1) + '" r="11" fill="#f0a21c"/><ellipse cx="' + (p[0] - 2) + '" cy="' + (p[1] - 4) + '" rx="4" ry="2.4" fill="#fff" opacity=".55"/></g>'; });
    [[130, 178], [170, 192], [214, 188]].forEach(function (p) { s += '<g filter="url(#faSoft)"><ellipse cx="' + p[0] + '" cy="' + p[1] + '" rx="26" ry="16" fill="#d79a86" transform="rotate(' + f(R() * 30 - 15) + ' ' + p[0] + ' ' + p[1] + ')"/><ellipse cx="' + p[0] + '" cy="' + p[1] + '" rx="19" ry="9" fill="#e9b9a6" opacity=".7"/></g>'; });
    s += '<g filter="url(#faSoft)"><rect x="262" y="92" width="34" height="46" rx="3" fill="#17261c" transform="rotate(16 279 115)"/></g>';
    for (var c = 0; c < 18; c++) { var b = R() * 6.283, e = 40 + R() * 56; s += '<circle cx="' + f(200 + Math.cos(b) * e) + '" cy="' + f(150 + Math.sin(b) * e) + '" r="3.2" fill="#f3d442"/>'; }
    return s + scallions(R, 200, 150, 82, 24) + finish();
  };
  ART.gyoza = function () {
    var R = rng(113);
    var s = bg('slate') + plate(190, 150, 128);
    [[120, 116, -24], [180, 98, -6], [240, 112, 16], [140, 176, 8], [204, 188, -12], [264, 176, 24]].forEach(function (p) {
      s += '<g filter="url(#faSoft)" transform="rotate(' + p[2] + ' ' + p[0] + ' ' + p[1] + ')"><path d="M' + (p[0] - 34) + ' ' + p[1] + 'q34 -40 68 0q-34 22 -68 0z" fill="#f6ecd6"/><path d="M' + (p[0] - 30) + ' ' + (p[1] + 3) + 'q30 16 60 0q-30 10 -60 0z" fill="#d48a2c"/>';
      for (var i = 0; i < 7; i++) s += '<path d="M' + (p[0] - 24 + i * 8) + ' ' + (p[1] - 14 + Math.abs(3 - i) * 2.4) + 'l1 12" stroke="#d8c8a4" stroke-width="2.4" stroke-linecap="round"/>';
      s += '<ellipse cx="' + (p[0] - 8) + '" cy="' + (p[1] - 12) + '" rx="13" ry="3.4" fill="#fff" opacity=".5"/></g>';
    });
    s += '<g filter="url(#faShadow)"><circle cx="336" cy="66" r="36" fill="#f2f4f6"/></g><circle cx="336" cy="66" r="27" fill="#3a1d0e"/><ellipse cx="328" cy="58" rx="10" ry="4" fill="#fff" opacity=".28"/>' + seeds(R, 336, 66, 18, 14, '#f3d442');
    return s + finish();
  };
  ART.boba = function () {
    var R = rng(127);
    var s = bg('slate') + '<g filter="url(#faShadow)"><path d="M140 70h120l-14 190q-2 14 -16 14h-60q-14 0 -16 -14z" fill="#ffffff" opacity=".25"/></g>';
    s += '<path d="M146 96h108l-12 160q-1 10 -12 10h-60q-11 0 -12 -10z" fill="url(#faTea)"/><path d="M146 96h108l-3 38h-102z" fill="#fff" opacity=".18"/>';
    for (var i = 0; i < 46; i++) { var x = 160 + R() * 80, y = 218 + R() * 42, w = (y - 218) / 42; s += '<circle cx="' + f(x) + '" cy="' + f(y) + '" r="5.6" fill="#241209"/><circle cx="' + f(x - 1.6) + '" cy="' + f(y - 1.8) + '" r="1.5" fill="#fff" opacity=".5"/>'; }
    s += '<path d="M150 108h100" stroke="#fff" stroke-width="3" opacity=".35"/><path d="M158 120q-4 70 4 120" stroke="#fff" stroke-width="5" opacity=".28" fill="none" stroke-linecap="round"/>';
    s += '<g filter="url(#faSoft)"><rect x="138" y="62" width="124" height="16" rx="7" fill="#f1f3f5"/><rect x="146" y="70" width="108" height="30" rx="8" fill="#ffffff" opacity=".2"/></g><g filter="url(#faSoft)"><rect x="214" y="6" width="10" height="150" rx="5" fill="#f06c8a" transform="rotate(10 219 80)"/></g>';
    return s + finish();
  };

  window.FoodArt = {
    svg: function (id) {
      var fn = ART[id]; if (!fn) return '';
      return '<svg viewBox="30 22 340 255" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Illustration of food" style="display:block;width:100%;height:100%">' + fn() + '</svg>';
    },
    defs: function () { return '<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">' + DEFS + '</svg>'; },
    ids: Object.keys(ART)
  };
})();
