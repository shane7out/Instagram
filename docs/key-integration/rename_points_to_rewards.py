#!/usr/bin/env python3
"""Renames the visible word "points" to "rewards" (program name LVR Points -> LVR Rewards) without touching code.
Only visible text is changed: HTML text and visible attributes, and string literals inside <script>. Code, ids, classes,
database keys (lvr_points, lvr_rewards, wallet.points ...) and file/URL names are left alone, except the two terms pages
which are renamed on purpose (points-terms.html -> rewards-terms.html, points-privacy.html -> rewards-privacy.html).
Usage:  python3 rename_points_to_rewards.py [--write] file...     (without --write it only prints what would change)"""
import re, sys

PH = '\u0001%d\u0001'
EXC_PHRASES = re.compile(r"(?i)\b(data points?|point of|points of|starting points?|entry points?|bullet points?|at this point|pointers?|pointing|viewpoints?|endpoints?|breakpoints?|checkpoints?|touchpoints?|access points?|price points?|talking points?|selling points?|decimal points?|focal points?|pain points?)")
ATTR = re.compile(r"""(?i)\b(?:id|class|for|name|data-[\w-]+|href|src|action|aria-controls|aria-labelledby)=(["'\\]*)[^"'>]*?points?[^"'>]*?\1""")
CODEISH = re.compile(r"(?i)([#.]points?\b|\bpoints?(?=[\[=_])|\bpoints?:(?=\S)|_points?\b|\bpoints?-[a-z]|[a-z]-points?\b|lvr-points|lvr_points|wallet\.points|\.points\b|DEMO_PTS)")

def protect(s):
    keep = []
    def sub(rx, text):
        def f(m):
            keep.append(m.group(0)); return PH % (len(keep) - 1)
        return rx.sub(f, text)
    s = sub(ATTR, s)
    s = sub(EXC_PHRASES, s)
    s = sub(CODEISH, s)
    return s, keep

def restore(s, keep):
    for i, k in enumerate(keep): s = s.replace(PH % i, k)
    return s

def rename_text(s):
    # terms pages keep working under new names
    s = s.replace('points-terms.html', 'rewards-terms.html').replace('points-privacy.html', 'rewards-privacy.html')
    if not re.search(r'(?i)point', s): return s
    s = s.replace('Las Vegas Restaurant Points', 'Las Vegas Restaurant Rewards')
    t, keep = protect(s)
    t = re.sub(r'LVR Points', 'LVR Rewards', t)
    t = re.sub(r'Las Vegas Restaurant Points', 'Las Vegas Restaurant Rewards', t)
    t = re.sub(r'\b1 point\b', '1 reward', t)
    t = re.sub(r'\bPOINTS\b', 'REWARDS', t)
    t = re.sub(r'\bPoints\b', 'Rewards', t)
    t = re.sub(r'\bpoints\b', 'rewards', t)
    t = re.sub(r'\bPoint\b', 'Reward', t)
    t = re.sub(r'\bpoint\b', 'reward', t)
    return restore(t, keep)

# ---------- JS string-literal lexer ----------
def lex_js(code, depth_brace=False, i=0):
    """returns (new_code, end_index). Only string/template literal text is passed through rename_literal."""
    out = []; n = len(code); prev = ''
    brace = 0
    while i < n:
        c = code[i]
        if c == '/' and i + 1 < n and code[i + 1] == '/':
            j = code.find('\n', i); j = n if j < 0 else j; out.append(code[i:j]); i = j; continue
        if c == '/' and i + 1 < n and code[i + 1] == '*':
            j = code.find('*/', i + 2); j = n if j < 0 else j + 2; out.append(code[i:j]); i = j; continue
        if c in '\'"':
            j = i + 1
            while j < n and code[j] != c:
                j += 2 if code[j] == '\\' else 1
            lit = code[i + 1:j]; out.append(c + rename_literal(lit) + c); i = j + 1; prev = c; continue
        if c == '`':
            out.append('`'); i += 1; buf = []
            while i < n and code[i] != '`':
                if code[i] == '\\': buf.append(code[i:i + 2]); i += 2; continue
                if code[i] == '$' and i + 1 < n and code[i + 1] == '{':
                    out.append(rename_literal(''.join(buf))); buf = []
                    inner, i = lex_js(code, True, i + 2); out.append('${' + inner + '}'); continue
                buf.append(code[i]); i += 1
            out.append(rename_literal(''.join(buf))); out.append('`'); i += 1; prev = '`'; continue
        if c == '/' and prev in '(,=:[!&|?{};+-*%<>~^' or (c == '/' and prev == ''):
            j = i + 1; incls = False
            while j < n and (code[j] != '/' or incls):
                if code[j] == '\\': j += 2; continue
                if code[j] == '[': incls = True
                elif code[j] == ']': incls = False
                j += 1
            j += 1
            while j < n and code[j].isalpha(): j += 1
            out.append(code[i:j]); i = j; prev = ')'; continue
        if depth_brace:
            if c == '{': brace += 1
            elif c == '}':
                if brace == 0: return ''.join(out), i + 1
                brace -= 1
        out.append(c)
        if not c.isspace(): prev = c
        i += 1
    return ''.join(out), i

LOG = []
def rename_literal(lit):
    if not re.search(r'(?i)point', lit): return lit
    st = lit.strip()
    if re.fullmatch(r"[a-z0-9_.#\-\[\]:/@$]+", st) and st != st.title() and 'point' in st.lower() and not re.search(r'\s', lit):
        # looks like a key, selector, path or class: leave it
        if st.lower() != 'points' or True:
            return lit
    new = rename_text(lit)
    if new != lit: LOG.append((lit, new))
    return new

def process_html(t):
    t = t.replace('points-terms.html', 'rewards-terms.html').replace('points-privacy.html', 'rewards-privacy.html')
    out = []; pos = 0
    pat = re.compile(r'(<script\b[^>]*>)(.*?)(</script>)|(<style\b[^>]*>.*?</style>)|(<!--.*?-->)|(<[^>]+>)', re.S)
    for m in pat.finditer(t):
        out.append(rename_text(t[pos:m.start()]))  # text node
        if m.group(1):
            tag, body, end = m.group(1), m.group(2), m.group(3)
            if 'ld+json' in tag: body = rename_text(body)
            elif 'src=' in tag: pass
            else: body, _ = lex_js(body)
            out.append(tag + body + end)
        elif m.group(4) or m.group(5): out.append(m.group(0))
        else:
            tag = m.group(6)
            # visible attributes only
            def attr(a):
                name = a.group(1).lower()
                if name in ('content', 'title', 'alt', 'placeholder', 'aria-label', 'value', 'label'):
                    return a.group(1) + '=' + a.group(2) + rename_text(a.group(3)) + a.group(2)
                return a.group(0)
            tag = re.sub(r'([\w:-]+)=(["\'])(.*?)\2', attr, tag, flags=re.S)
            out.append(tag)
        pos = m.end()
    out.append(rename_text(t[pos:]))
    return ''.join(out)

def skeleton(code):
    """code with the inside of all string literals blanked, to prove only literal text changed"""
    out = []; i = 0; n = len(code)
    while i < n:
        c = code[i]
        if c in '\'"`':
            j = i + 1
            while j < n and code[j] != c: j += 2 if code[j] == '\\' else 1
            out.append(c + c); i = j + 1; continue
        out.append(c); i += 1
    return ''.join(out)

if __name__ == '__main__':
    write = '--write' in sys.argv
    for f in [a for a in sys.argv[1:] if not a.startswith('--')]:
        src = open(f, encoding='utf-8').read()
        if f.endswith('.html'): new = process_html(src)
        elif f.endswith('.js'): new, _ = lex_js(src.replace('points-terms.html', 'rewards-terms.html').replace('points-privacy.html', 'rewards-privacy.html'))
        else: new = rename_text(src)
        if new != src:
            if write: open(f, 'w', encoding='utf-8').write(new)
            print('%s: changed (%d -> %d chars)' % (f, len(src), len(new)))
