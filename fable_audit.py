#!/usr/bin/env python3
"""
Fable 5 Website Audit — one-command pipeline.

Rebuilt for a Linux environment (Chromium via Playwright's bundle, Lighthouse via npx).

Usage:
    python3 fable_audit.py <domain> [--name "Business Name"] [--logo file.png]
        [--color "#0f0f0f"] [--accent "#b8181f"] [--pages 40]
        [--no-lighthouse] [--no-pdf]

Outputs to audits/<domain>/: Report.pdf, Report.jpg, report.md, data.json
"""

import argparse
import base64
import glob
import html
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Environment specifics (this Linux machine)
# ---------------------------------------------------------------------------
CHROME_CANDIDATES = [
    "/opt/pw-browsers/chromium",
    "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
    os.environ.get("CHROME_PATH", ""),
    "google-chrome",
    "chromium",
]


def find_chrome():
    for c in CHROME_CANDIDATES:
        if c and (os.path.exists(c) or _which(c)):
            return c
    return None


def _which(name):
    for p in os.environ.get("PATH", "").split(os.pathsep):
        f = os.path.join(p, name)
        if os.path.exists(f) and os.access(f, os.X_OK):
            return f
    return None


def find_lighthouse():
    """Prefer a cached npx binary; fall back to `npx --yes lighthouse`."""
    hits = glob.glob(os.path.expanduser("~/.npm/_npx/*/node_modules/.bin/lighthouse"))
    if hits:
        return [hits[0]]
    return ["npx", "--yes", "lighthouse"]


UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36")

SECURITY_HEADERS = {
    "strict-transport-security": "HSTS",
    "content-security-policy": "Content-Security-Policy",
    "x-frame-options": "X-Frame-Options",
    "x-content-type-options": "X-Content-Type-Options (nosniff)",
    "referrer-policy": "Referrer-Policy",
}

JUNK_PATTERNS = re.compile(
    r"(/feed/?$|/tag/|/category/|/author/|/wp-json|/comments/|\?replytocom=|"
    r"/page/\d+|/attachment/|/trackback/?$|\.xml\.gz$)", re.I)

RELEVANT_SCHEMA = {
    "LocalBusiness", "Organization", "Restaurant", "Store", "AutoDealer",
    "MedicalBusiness", "Physician", "Church", "Product", "Service",
    "Vehicle", "Car", "ProfessionalService", "WebSite", "WebPage",
    "BreadcrumbList", "FAQPage", "Review",
}


# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
def fetch(url, timeout=30, allow_redirects=True):
    try:
        r = requests.get(url, headers={"User-Agent": UA}, timeout=timeout,
                         allow_redirects=allow_redirects)
        return r
    except Exception as e:
        return _FakeResp(str(e))


class _FakeResp:
    def __init__(self, err):
        self.status_code = 0
        self.headers = {}
        self.text = ""
        self.content = b""
        self.url = ""
        self.elapsed = timedelta(0)
        self.error = err

    def json(self):
        raise ValueError("no json")


def normalize_domain(domain):
    domain = domain.strip()
    if not domain.startswith(("http://", "https://")):
        domain = "https://" + domain
    p = urlparse(domain)
    host = p.netloc
    base = f"{p.scheme}://{host}"
    return base, host


# ---------------------------------------------------------------------------
# Home page analysis
# ---------------------------------------------------------------------------
def meta_content(soup, **attrs):
    tag = soup.find("meta", attrs=attrs)
    if tag and tag.get("content"):
        return tag["content"].strip()
    return None


def analyze_home(url, resp):
    d = {
        "url": resp.url or url,
        "status": resp.status_code,
        "ttfb_ms": round(resp.elapsed.total_seconds() * 1000) if resp.status_code else None,
        "html_bytes": len(resp.content),
        "title": None, "title_len": 0,
        "description": None, "desc_len": 0,
        "canonical": None,
        "h1_count": 0,
        "img_total": 0, "img_missing_alt": 0,
        "og": {}, "twitter": {},
        "schema_types": [], "aggregate_ratings": [],
        "https": (resp.url or url).startswith("https://"),
    }
    if not resp.status_code or not resp.text:
        return d

    soup = BeautifulSoup(resp.text, "lxml")

    if soup.title and soup.title.string:
        d["title"] = soup.title.string.strip()
        d["title_len"] = len(d["title"])

    desc = meta_content(soup, attrs={"name": "description"}) or meta_content(soup, name="description")
    if desc:
        d["description"] = desc
        d["desc_len"] = len(desc)

    can = soup.find("link", rel="canonical")
    if can and can.get("href"):
        d["canonical"] = can["href"].strip()

    d["h1_count"] = len(soup.find_all("h1"))

    imgs = soup.find_all("img")
    d["img_total"] = len(imgs)
    d["img_missing_alt"] = sum(1 for i in imgs if not (i.get("alt") or "").strip())

    for tag in soup.find_all("meta", property=re.compile(r"^og:", re.I)):
        if tag.get("content"):
            d["og"][tag["property"].lower()] = tag["content"].strip()
    for tag in soup.find_all("meta", attrs={"name": re.compile(r"^twitter:", re.I)}):
        if tag.get("content"):
            d["twitter"][tag["name"].lower()] = tag["content"].strip()

    # JSON-LD
    for s in soup.find_all("script", type="application/ld+json"):
        raw = s.string or s.get_text() or ""
        for block in _iter_json(raw):
            _collect_schema(block, d)

    d["schema_types"] = sorted(set(d["schema_types"]))
    return d


def _iter_json(raw):
    raw = raw.strip()
    if not raw:
        return
    try:
        yield json.loads(raw)
    except Exception:
        # sometimes multiple concatenated objects
        for m in re.finditer(r"\{.*?\}(?=\s*[\{\[]|\s*$)", raw, re.S):
            try:
                yield json.loads(m.group(0))
            except Exception:
                continue


def _collect_schema(block, d):
    if isinstance(block, list):
        for b in block:
            _collect_schema(b, d)
        return
    if not isinstance(block, dict):
        return
    if "@graph" in block:
        _collect_schema(block["@graph"], d)
    t = block.get("@type")
    if isinstance(t, list):
        d["schema_types"].extend(str(x) for x in t)
    elif t:
        d["schema_types"].append(str(t))
    ar = block.get("aggregateRating")
    if isinstance(ar, dict):
        d["aggregate_ratings"].append({
            "type": t if isinstance(t, str) else (t[0] if isinstance(t, list) and t else "?"),
            "rating": ar.get("ratingValue"),
            "count": ar.get("reviewCount") or ar.get("ratingCount"),
        })
    # nested
    for v in block.values():
        if isinstance(v, (dict, list)):
            _collect_schema(v, d)


def check_security_headers(resp):
    present = {}
    for key, label in SECURITY_HEADERS.items():
        present[label] = key in {k.lower() for k in resp.headers.keys()}
    return present


# ---------------------------------------------------------------------------
# Robots / sitemap / 404
# ---------------------------------------------------------------------------
def discover_robots_sitemap(base):
    out = {"robots_found": False, "sitemaps": [], "urls": [],
           "junk_urls": [], "offdomain_urls": [], "url_count": 0}
    host = urlparse(base).netloc

    robots = fetch(urljoin(base, "/robots.txt"))
    sitemap_urls = []
    if robots.status_code == 200 and robots.text:
        out["robots_found"] = True
        for line in robots.text.splitlines():
            m = re.match(r"\s*sitemap:\s*(\S+)", line, re.I)
            if m:
                sitemap_urls.append(m.group(1).strip())
    if not sitemap_urls:
        sitemap_urls = [urljoin(base, "/sitemap.xml")]

    seen_sitemaps = set()
    all_urls = []

    def load_sitemap(sm_url, depth=0):
        if depth > 3 or sm_url in seen_sitemaps:
            return
        seen_sitemaps.add(sm_url)
        r = fetch(sm_url)
        if r.status_code != 200 or not r.text:
            return
        out["sitemaps"].append(sm_url)
        soup = BeautifulSoup(r.text, "xml")
        # sitemap index
        for sm in soup.find_all("sitemap"):
            loc = sm.find("loc")
            if loc and loc.text:
                load_sitemap(loc.text.strip(), depth + 1)
        for u in soup.find_all("url"):
            loc = u.find("loc")
            if loc and loc.text:
                all_urls.append(loc.text.strip())

    for sm in sitemap_urls:
        load_sitemap(sm)

    for u in all_urls:
        if JUNK_PATTERNS.search(u):
            out["junk_urls"].append(u)
        if urlparse(u).netloc and urlparse(u).netloc != host:
            out["offdomain_urls"].append(u)

    out["urls"] = all_urls
    out["url_count"] = len(all_urls)
    return out


def test_404(base):
    r = fetch(urljoin(base, "/this-page-should-not-exist-fable5-audit-xyz"))
    return {"status": r.status_code, "is_true_404": r.status_code == 404}


# ---------------------------------------------------------------------------
# Multi-page crawl
# ---------------------------------------------------------------------------
def crawl(urls, base, limit):
    host = urlparse(base).netloc
    same = [u for u in urls if urlparse(u).netloc in ("", host)]
    same = list(dict.fromkeys(same))[:limit]
    pages = []
    titles = {}
    for u in same:
        r = fetch(u, timeout=35)
        if r.status_code != 200 or not r.text:
            pages.append({"url": u, "status": r.status_code, "title": None,
                          "desc": None, "h1": 0, "slow": False,
                          "load_ms": round(r.elapsed.total_seconds() * 1000) if r.status_code else None})
            continue
        soup = BeautifulSoup(r.text, "lxml")
        title = soup.title.string.strip() if (soup.title and soup.title.string) else None
        desc = meta_content(soup, attrs={"name": "description"})
        h1 = len(soup.find_all("h1"))
        load_ms = round(r.elapsed.total_seconds() * 1000)
        pages.append({"url": u, "status": r.status_code, "title": title,
                      "desc": desc, "h1": h1, "slow": load_ms > 25000,
                      "load_ms": load_ms})
        if title:
            titles.setdefault(title, []).append(u)
    dup_titles = {t: us for t, us in titles.items() if len(us) > 1}
    return {"pages": pages, "count": len(pages),
            "no_h1": [p["url"] for p in pages if p.get("h1") == 0 and p["status"] == 200],
            "dup_titles": dup_titles,
            "slow_urls": [p["url"] for p in pages if p.get("slow")]}


# ---------------------------------------------------------------------------
# Lighthouse
# ---------------------------------------------------------------------------
def run_lighthouse(url, chrome):
    lh = find_lighthouse()
    outfile = tempfile.NamedTemporaryFile(suffix=".json", delete=False).name
    cmd = lh + [
        url, "--quiet",
        "--chrome-flags=--headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage",
        "--only-categories=performance,accessibility,best-practices,seo",
        "--form-factor=mobile", "--screenEmulation.mobile",
        "--output=json", f"--output-path={outfile}",
        "--max-wait-for-load=60000",
    ]
    env = dict(os.environ)
    if chrome:
        env["CHROME_PATH"] = chrome
    try:
        subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=180)
        with open(outfile) as f:
            data = json.load(f)
    except Exception as e:
        return {"available": False, "error": str(e)}
    finally:
        try:
            os.unlink(outfile)
        except OSError:
            pass

    cats = data.get("categories", {})
    audits = data.get("audits", {})

    def score(cat):
        s = cats.get(cat, {}).get("score")
        return round(s * 100) if isinstance(s, (int, float)) else None

    def num(aid):
        return audits.get(aid, {}).get("numericValue")

    return {
        "available": True,
        "performance": score("performance"),
        "accessibility": score("accessibility"),
        "best_practices": score("best-practices"),
        "seo": score("seo"),
        "lcp_s": round(num("largest-contentful-paint") / 1000, 1) if num("largest-contentful-paint") else None,
        "si_s": round(num("speed-index") / 1000, 1) if num("speed-index") else None,
        "tbt_ms": round(num("total-blocking-time")) if num("total-blocking-time") is not None else None,
        "weight_mb": round(num("total-byte-weight") / 1048576, 1) if num("total-byte-weight") else None,
    }


# ---------------------------------------------------------------------------
# Scoring & grading  (weights per handoff spec)
# ---------------------------------------------------------------------------
WEIGHTS = {
    "performance": 0.20, "crawlability": 0.15, "seo_meta": 0.15,
    "structured_data": 0.12, "hygiene": 0.10, "security": 0.10,
    "accessibility": 0.10, "social": 0.08,
}


def clamp(x):
    return int(round(max(0, min(100, x))))


def score_all(home, sec, robots, four04, crawl_res, lh):
    s = {}

    # Performance (.20)
    if lh.get("available") and lh.get("performance") is not None:
        s["performance"] = lh["performance"]
    else:
        ttfb = home.get("ttfb_ms") or 3000
        s["performance"] = clamp(100 - (ttfb - 200) / 40)  # rough fallback

    # Crawlability (.15)
    c = 100
    if not robots["robots_found"]:
        c -= 20
    if robots["url_count"] == 0:
        c -= 35
    if not four04["is_true_404"]:
        c -= 25
    if robots["offdomain_urls"]:
        c -= 15
    s["crawlability"] = clamp(c)

    # SEO meta (.15)
    m = 0
    if home["title"]:
        m += 30
        if 30 <= home["title_len"] <= 65:
            m += 10
        elif home["title_len"] > 65:
            m += 3
    if home["description"]:
        m += 25
        if 70 <= home["desc_len"] <= 160:
            m += 10
    if home["canonical"]:
        m += 15
    if home["h1_count"] == 1:
        m += 10
    s["seo_meta"] = clamp(m)

    # Structured data (.12)
    sd = 0
    if home["schema_types"]:
        sd += 45
        if set(home["schema_types"]) & RELEVANT_SCHEMA:
            sd += 45
        else:
            sd += 15
    s["structured_data"] = clamp(sd if sd else 10)

    # Site hygiene (.10)
    h = 100
    pages_ok = max(1, crawl_res["count"])
    h -= min(40, len(crawl_res["no_h1"]) / pages_ok * 60)
    h -= min(25, len(crawl_res["dup_titles"]) * 8)
    h -= min(20, len(robots["junk_urls"]) / max(1, robots["url_count"]) * 40)
    s["hygiene"] = clamp(h)

    # Security (.10)
    present = sum(1 for v in sec.values() if v)
    s["security"] = clamp(present / len(sec) * 100)

    # Accessibility (.10)
    if lh.get("available") and lh.get("accessibility") is not None:
        a = lh["accessibility"]
    else:
        a = 80
    if home["img_total"]:
        alt_ratio = 1 - home["img_missing_alt"] / home["img_total"]
        a = round(a * 0.7 + alt_ratio * 100 * 0.3)
    s["accessibility"] = clamp(a)

    # Social (.08)
    soc = 0
    if home["og"].get("og:title"):
        soc += 25
    if home["og"].get("og:description"):
        soc += 20
    if home["og"].get("og:image"):
        soc += 30
    if home["twitter"].get("twitter:card"):
        soc += 25
    s["social"] = clamp(soc)

    overall = round(sum(s[k] * WEIGHTS[k] for k in WEIGHTS))
    return s, overall


def letter_grade(score):
    table = [(97, "A+"), (93, "A"), (90, "A-"), (87, "B+"), (83, "B"),
             (80, "B-"), (77, "C+"), (73, "C"), (70, "C-"), (67, "D+"),
             (63, "D"), (60, "D-"), (0, "F")]
    for cut, g in table:
        if score >= cut:
            return g
    return "F"


def grade_color(grade):
    """Green ring for B+/A, amber for C-range, crimson below."""
    if grade in ("A+", "A", "A-", "B+", "B", "B-"):
        return "#1a7f37"   # green
    if grade in ("C+", "C", "C-"):
        return "#b8860b"   # amber
    return "#b8181f"       # crimson


# ---------------------------------------------------------------------------
# Findings register + priority remediation
# ---------------------------------------------------------------------------
def build_findings(home, sec, robots, four04, crawl_res, lh, scores):
    F = []  # (category, status, detail, severity 0-3)

    # Performance
    if lh.get("available"):
        if lh.get("weight_mb") and lh["weight_mb"] > 3:
            F.append(("Performance", "FAIL",
                      f"Page weight {lh['weight_mb']} MB; LCP {lh.get('lcp_s','?')}s (LH perf {lh.get('performance')})", 3))
        elif lh.get("performance", 100) < 50:
            F.append(("Performance", "FAIL",
                      f"Lighthouse mobile performance {lh['performance']}/100; LCP {lh.get('lcp_s','?')}s", 3))
        elif lh.get("performance", 100) < 90:
            F.append(("Performance", "WARN",
                      f"Lighthouse mobile performance {lh['performance']}/100; LCP {lh.get('lcp_s','?')}s", 2))
        else:
            F.append(("Performance", "PASS",
                      f"Lighthouse mobile performance {lh['performance']}/100", 0))
    else:
        F.append(("Performance", "WARN",
                  f"Lighthouse unavailable; home TTFB {home.get('ttfb_ms','?')} ms", 1))

    # SEO title
    if not home["title"]:
        F.append(("SEO · Title", "FAIL", "Home page has no <title>", 3))
    elif home["title_len"] > 65:
        F.append(("SEO · Title", "WARN", f"Title is {home['title_len']} chars (aim 30–60)", 2))
    else:
        F.append(("SEO · Title", "PASS", f"Title present ({home['title_len']} chars)", 0))

    # Meta description
    if not home["description"]:
        F.append(("SEO · Meta desc", "FAIL", "No meta description on home page", 2))
    elif not (70 <= home["desc_len"] <= 160):
        F.append(("SEO · Meta desc", "WARN", f"Meta description {home['desc_len']} chars (aim 70–160)", 1))
    else:
        F.append(("SEO · Meta desc", "PASS", f"Meta description present ({home['desc_len']} chars)", 0))

    # Canonical
    F.append(("SEO · Canonical", "PASS" if home["canonical"] else "WARN",
              "Canonical tag present" if home["canonical"] else "No canonical tag on home page",
              0 if home["canonical"] else 1))

    # H1
    if home["h1_count"] == 0:
        F.append(("Content · H1", "FAIL", "Home page has no H1 heading", 2))
    elif home["h1_count"] > 1:
        F.append(("Content · H1", "WARN", f"{home['h1_count']} H1 tags on home page (prefer 1)", 1))
    else:
        F.append(("Content · H1", "PASS", "Exactly one H1 on home page", 0))
    if crawl_res["no_h1"]:
        F.append(("Content · H1 (site)", "WARN",
                  f"{len(crawl_res['no_h1'])}/{crawl_res['count']} crawled pages have no H1", 2))

    # Structured data
    if not home["schema_types"]:
        F.append(("Structured data", "FAIL", "No JSON-LD schema detected", 2))
    else:
        rel = set(home["schema_types"]) & RELEVANT_SCHEMA
        F.append(("Structured data", "PASS" if rel else "WARN",
                  "Schema: " + ", ".join(home["schema_types"][:5]) + ("…" if len(home["schema_types"]) > 5 else ""),
                  0 if rel else 1))
    for ar in home["aggregate_ratings"]:
        F.append(("Structured data · Rating", "WARN",
                  f"aggregateRating {ar['rating']}★/{ar['count']} in {ar['type']} schema — needs verification against third-party reviews",
                  2))

    # Security
    missing = [lbl for lbl, ok in sec.items() if not ok]
    if not missing:
        F.append(("Security headers", "PASS", "All 5 baseline headers present", 0))
    else:
        sev = 3 if len(missing) >= 4 else 2
        F.append(("Security headers", "FAIL" if len(missing) >= 4 else "WARN",
                  f"Missing {len(missing)}/5: " + ", ".join(m.split(' (')[0] for m in missing), sev))

    # Crawlability
    if not robots["robots_found"]:
        F.append(("Crawlability · robots", "WARN", "No robots.txt found", 1))
    if robots["url_count"] == 0:
        F.append(("Crawlability · sitemap", "FAIL", "No sitemap URLs discovered", 2))
    else:
        F.append(("Crawlability · sitemap", "PASS",
                  f"{robots['url_count']} URLs across {len(robots['sitemaps'])} sitemap(s)", 0))
    if robots["offdomain_urls"]:
        F.append(("Crawlability · sitemap", "FAIL",
                  f"{len(robots['offdomain_urls'])} sitemap URLs point off-domain", 3))
    if robots["junk_urls"]:
        n = len(robots["junk_urls"])
        F.append(("Site hygiene", "WARN",
                  f"{n} low-value/junk URL{'s' if n != 1 else ''} in sitemap", 1))

    # 404
    F.append(("Crawlability · 404", "PASS" if four04["is_true_404"] else "WARN",
              "Unknown paths return true 404" if four04["is_true_404"]
              else f"Unknown path returned HTTP {four04['status']} (soft 404)",
              0 if four04["is_true_404"] else 2))

    # Accessibility / alt
    if home["img_total"] and home["img_missing_alt"]:
        F.append(("Accessibility · alt", "WARN",
                  f"{home['img_missing_alt']}/{home['img_total']} home images missing alt text", 1))

    # Social
    if not home["og"]:
        F.append(("Social · Open Graph", "WARN", "No Open Graph tags (poor link previews)", 2))
    elif not home["og"].get("og:image"):
        F.append(("Social · Open Graph", "WARN", "No og:image (link previews lack thumbnail)", 1))
    else:
        F.append(("Social · Open Graph", "PASS", "Open Graph tags present", 0))

    # Dup titles
    if crawl_res["dup_titles"]:
        n = len(crawl_res["dup_titles"])
        F.append(("Site hygiene · titles", "WARN",
                  f"{n} duplicate page title{'s' if n != 1 else ''} across crawl", 1))

    # Dedup, sort by severity desc, keep register to 8 rows (highest-signal first)
    F.sort(key=lambda x: -x[3])
    register = F[:8]

    # Priority remediation = top 3 actionable (sev>=2), phrased as fixes
    remediation = []
    for cat, status, detail, sev in F:
        if sev >= 2 and status != "PASS":
            remediation.append(_as_fix(cat, detail))
        if len(remediation) == 3:
            break
    while len(remediation) < 3:
        remediation.append("Maintain current standards; re-audit in 90 days.")
    return register, remediation


def _as_fix(cat, detail):
    c = cat.lower()
    if "performance" in c:
        return "Cut page weight and defer non-critical JS/images to bring mobile LCP under 2.5s."
    if "security" in c:
        return "Add the missing security response headers (HSTS, CSP, X-Frame-Options, nosniff, Referrer-Policy)."
    if "structured data · rating" in c:
        return "Verify or remove the on-page aggregateRating so it matches independently auditable reviews."
    if "structured data" in c:
        return "Add LocalBusiness/relevant JSON-LD schema with NAP, hours, and geo."
    if "sitemap" in c and "off-domain" in detail.lower():
        return "Regenerate the sitemap so it lists only this domain's live, canonical URLs."
    if "sitemap" in c:
        return "Publish an XML sitemap and reference it from robots.txt."
    if "title" in c:
        return "Rewrite the page title to a unique 30–60 character, keyword-led headline."
    if "meta desc" in c:
        return "Write a compelling 70–160 character meta description for the home page."
    if "h1" in c:
        return "Ensure every page has exactly one descriptive H1 heading."
    if "404" in c:
        return "Return a real HTTP 404 for unknown URLs instead of a soft 200."
    if "open graph" in c or "social" in c:
        return "Add Open Graph + Twitter Card tags (title, description, 1200×630 image)."
    return f"Address: {detail}"


# ---------------------------------------------------------------------------
# Rendering — HTML report
# ---------------------------------------------------------------------------
def _b64_logo(path):
    try:
        data = Path(path).read_bytes()
        ext = Path(path).suffix.lstrip(".").lower() or "png"
        if ext == "svg":
            ext = "svg+xml"
        return f"data:image/{ext};base64," + base64.b64encode(data).decode()
    except Exception:
        return None


def seal_svg():
    """Gold notary-style seal: beaded edge, curved text, FABLE 5 center."""
    return '''<svg viewBox="0 0 200 200" width="96" height="96" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="gold" cx="50%" cy="40%" r="65%">
      <stop offset="0%" stop-color="#fdf3d0"/>
      <stop offset="45%" stop-color="#e8c85a"/>
      <stop offset="100%" stop-color="#a9822b"/>
    </radialGradient>
    <path id="top" d="M 100,100 m -74,0 a 74,74 0 1,1 148,0" fill="none"/>
    <path id="bot" d="M 100,100 m 70,0 a 70,70 0 1,1 -140,0" fill="none"/>
  </defs>
  <circle cx="100" cy="100" r="94" fill="url(#gold)" stroke="#8a6a1e" stroke-width="2"/>
  <circle cx="100" cy="100" r="86" fill="none" stroke="#8a6a1e" stroke-width="1" stroke-dasharray="2 3.4"/>
  <circle cx="100" cy="100" r="66" fill="#fbf1cf" stroke="#8a6a1e" stroke-width="1.5"/>
  <text font-family="Georgia,serif" font-size="15" font-weight="700" fill="#6b4f16" letter-spacing="2">
    <textPath href="#top" startOffset="50%" text-anchor="middle">CLAUDE · FABLE 5</textPath>
  </text>
  <text font-family="Georgia,serif" font-size="13" font-weight="700" fill="#6b4f16" letter-spacing="3">
    <textPath href="#bot" startOffset="50%" text-anchor="middle">AUDITED · VERIFIED</textPath>
  </text>
  <text x="100" y="94" text-anchor="middle" font-family="Georgia,serif" font-size="27" font-weight="800" fill="#7a5a18">FABLE</text>
  <text x="100" y="120" text-anchor="middle" font-family="Georgia,serif" font-size="27" font-weight="800" fill="#7a5a18">5</text>
  <text x="100" y="138" text-anchor="middle" font-family="Arial,sans-serif" font-size="7.5" font-weight="700" fill="#8a6a1e" letter-spacing="1.5">SEAL OF APPROVAL</text>
</svg>'''


STATUS_STYLE = {
    "PASS": ("#1a7f37", "#e7f4ea", "PASS"),
    "WARN": ("#9a6a00", "#fdf3d8", "WARN"),
    "FAIL": ("#b8181f", "#fbe6e6", "FAIL"),
}


def build_html(meta, home, sec, lh, scores, overall, grade, register, remediation):
    esc = html.escape
    logo_uri = _b64_logo(meta["logo"]) if meta.get("logo") else None
    gcolor = grade_color(grade)

    # logo block
    if logo_uri:
        logo_html = f'<img src="{logo_uri}" alt="logo"/>'
    else:
        logo_html = f'<div class="wordmark">{esc(meta["name"])}</div>'

    # lighthouse strip
    if lh.get("available"):
        cells = [
            ("Performance", lh.get("performance")),
            ("Accessibility", lh.get("accessibility")),
            ("Best Practices", lh.get("best_practices")),
            ("SEO", lh.get("seo")),
        ]
        strip = "".join(
            f'<div class="lh"><div class="lhnum" style="color:{_lh_col(v)}">{v if v is not None else "—"}</div>'
            f'<div class="lhlbl">{lbl}</div></div>' for lbl, v in cells)
        metrics = (f'LCP {lh.get("lcp_s","—")}s · Speed Index {lh.get("si_s","—")}s · '
                   f'TBT {lh.get("tbt_ms","—")} ms · Weight {lh.get("weight_mb","—")} MB')
    else:
        strip = '<div class="lh"><div class="lhnum" style="color:#999">—</div><div class="lhlbl">Lighthouse unavailable</div></div>'
        metrics = f'Home TTFB {home.get("ttfb_ms","—")} ms · {home.get("html_bytes",0)//1024} KB HTML'

    # findings rows
    rows = ""
    for cat, status, detail, _sev in register:
        col, bg, lbl = STATUS_STYLE[status]
        rows += (f'<tr><td class="fcat">{esc(cat)}</td>'
                 f'<td><span class="badge" style="color:{col};background:{bg}">{lbl}</span></td>'
                 f'<td class="fdet">{esc(detail)}</td></tr>')

    rem = "".join(f'<li>{esc(r)}</li>' for r in remediation)

    # sub-score bars
    bars = ""
    label_map = {"performance": "Performance", "crawlability": "Crawlability",
                 "seo_meta": "SEO Meta", "structured_data": "Structured Data",
                 "hygiene": "Site Hygiene", "security": "Security",
                 "accessibility": "Accessibility", "social": "Social"}
    for k in WEIGHTS:
        v = scores[k]
        bcol = "#1a7f37" if v >= 85 else ("#b8860b" if v >= 65 else "#b8181f")
        bars += (f'<div class="barrow"><span class="blbl">{label_map[k]}</span>'
                 f'<span class="btrack"><span class="bfill" style="width:{v}%;background:{bcol}"></span></span>'
                 f'<span class="bval">{v}</span></div>')

    return f"""<!doctype html><html><head><meta charset="utf-8">
<style>
@page {{ size: Letter; margin: 0; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ width: 816px; height: 1056px; font-family: 'Helvetica Neue', Arial, sans-serif;
  color: #1a1a1a; background: #fff; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
.head {{ background: {meta['color']}; padding: 26px 30px; display: flex; align-items: center;
  justify-content: space-between; }}
.plate {{ background: #fff; border-radius: 12px; padding: 10px 16px; display: flex; align-items: center;
  min-width: 190px; height: 74px; }}
.plate img {{ max-height: 54px; max-width: 220px; object-fit: contain; }}
.wordmark {{ font-size: 19px; font-weight: 800; color: {meta['color']}; }}
.htitle {{ display: flex; align-items: center; gap: 16px; }}
.htxt {{ text-align: right; }}
.htxt .k {{ color: #e8c85a; font-size: 22px; font-weight: 800; letter-spacing: 2px; }}
.htxt .s {{ color: #f4e6b8; font-size: 10px; letter-spacing: 3px; margin-top: 2px; }}
.rule {{ height: 2px; background: linear-gradient(90deg,#a9822b,#e8c85a,#a9822b); }}
.sub {{ display: flex; justify-content: space-between; align-items: flex-start; padding: 22px 30px 12px; }}
.biz {{ font-size: 21px; font-weight: 800; }}
.bizurl {{ color: #666; font-size: 12px; margin-top: 2px; }}
.ref {{ text-align: right; font-size: 10.5px; color: #555; line-height: 1.5; }}
.grade-wrap {{ display: flex; align-items: center; gap: 22px; padding: 8px 30px 10px; }}
.circle {{ width: 96px; height: 96px; border-radius: 50%; border: 6px solid {gcolor};
  display: flex; flex-direction: column; align-items: center; justify-content: center; flex: 0 0 auto; }}
.circle .g {{ font-size: 38px; font-weight: 900; color: {gcolor}; line-height: 1; }}
.circle .n {{ font-size: 12px; color: #666; font-weight: 700; }}
.bars {{ flex: 1; }}
.barrow {{ display: flex; align-items: center; gap: 8px; margin: 3px 0; }}
.blbl {{ width: 108px; font-size: 10.5px; color: #333; }}
.btrack {{ flex: 1; height: 8px; background: #eee; border-radius: 4px; overflow: hidden; }}
.bfill {{ display: block; height: 100%; }}
.bval {{ width: 26px; text-align: right; font-size: 10px; font-weight: 700; color: #444; }}
.lhstrip {{ display: flex; gap: 10px; padding: 10px 30px 8px; }}
.lh {{ flex: 1; border: 1px solid #e6e6e6; border-radius: 8px; padding: 9px 8px; text-align: center; }}
.lhnum {{ font-size: 24px; font-weight: 900; }}
.lhlbl {{ font-size: 9.5px; color: #666; margin-top: 2px; }}
.metrics {{ text-align: center; font-size: 10px; color: #777; padding: 0 30px 12px; }}
.sec {{ padding: 5px 30px; }}
.sech {{ font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;
  color: {meta['color']}; border-bottom: 1.5px solid {meta['accent']}; padding-bottom: 3px; margin-bottom: 5px; }}
table {{ width: 100%; border-collapse: collapse; }}
td {{ padding: 5px 6px; border-bottom: 1px solid #eee; font-size: 10.5px; vertical-align: top; }}
.fcat {{ width: 150px; font-weight: 700; color: #333; }}
.fdet {{ color: #444; }}
.badge {{ font-size: 9px; font-weight: 800; padding: 2px 7px; border-radius: 10px; letter-spacing: .5px; }}
.rem {{ list-style: none; }}
.rem li {{ font-size: 11px; padding: 6px 0 6px 24px; position: relative; color: #333; border-bottom: 1px solid #f0f0f0; }}
.rem li:before {{ content: counter(rc); counter-increment: rc; position: absolute; left: 0; top: 4px;
  width: 17px; height: 17px; background: {meta['accent']}; color: #fff; border-radius: 50%;
  font-size: 10px; font-weight: 800; text-align: center; line-height: 17px; }}
.rem {{ counter-reset: rc; }}
.cert {{ margin: 10px 30px 0; border: 1.5px solid #d9c37a; background: #fdfaf0; border-radius: 10px;
  padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; }}
.cert .txt {{ font-size: 10.5px; color: #4a4020; line-height: 1.5; max-width: 560px; }}
.cert .sig {{ font-family: Georgia, serif; font-size: 17px; font-weight: 700; color: {meta['color']}; margin-top: 4px; }}
.foot {{ text-align: center; font-size: 8.5px; color: #999; padding: 8px 30px 0; }}
</style></head><body>
<div class="head">
  <div class="plate">{logo_html}</div>
  <div class="htitle">
    <div class="htxt"><div class="k">FABLE 5 AUDIT REPORT</div><div class="s">WEBSITE PERFORMANCE · SEO · SECURITY</div></div>
    {seal_svg()}
  </div>
</div>
<div class="rule"></div>
<div class="sub">
  <div><div class="biz">{esc(meta['name'])}</div><div class="bizurl">{esc(meta['host'])}</div></div>
  <div class="ref">Ref: {esc(meta['ref'])}<br>Audit date: {esc(meta['date'])}<br>Re-audit due: {esc(meta['reaudit'])}</div>
</div>
<div class="grade-wrap">
  <div class="circle"><div class="g">{grade}</div><div class="n">{overall}/100</div></div>
  <div class="bars">{bars}</div>
</div>
<div class="lhstrip">{strip}</div>
<div class="metrics">Lighthouse mobile · {metrics}</div>
<div class="sec"><div class="sech">Findings Register</div>
  <table>{rows}</table></div>
<div class="sec"><div class="sech">Priority Remediation</div>
  <ol class="rem">{rem}</ol></div>
<div class="cert">
  <div class="txt">This certifies that <b>{esc(meta['name'])}</b> ({esc(meta['host'])}) was audited on
    {esc(meta['date'])} using automated performance, SEO, structured-data, security, and accessibility
    analysis (Lighthouse mobile + site-wide crawl). Overall grade: <b>{grade} ({overall}/100)</b>.
    <div class="sig">Claude Fable 5</div>
    <span style="font-size:9.5px;color:#8a7a45">model claude-fable-5 · digital audit signature</span></div>
  {seal_svg()}
</div>
<div class="foot">Generated by the Fable 5 Audit pipeline · Ref {esc(meta['ref'])} · Findings are point-in-time and provided for remediation guidance.</div>
</body></html>"""


def _lh_col(v):
    if v is None:
        return "#999"
    return "#1a7f37" if v >= 90 else ("#b8860b" if v >= 50 else "#b8181f")


# ---------------------------------------------------------------------------
# Rendering — PDF / JPG via Chromium
# ---------------------------------------------------------------------------
def render_pdf(chrome, html_path, pdf_path):
    cmd = [chrome, "--headless=new", "--no-sandbox", "--disable-gpu",
           "--disable-dev-shm-usage", "--no-pdf-header-footer",
           f"--print-to-pdf={pdf_path}", f"file://{html_path}"]
    subprocess.run(cmd, capture_output=True, timeout=120)
    return os.path.exists(pdf_path)


def render_jpg(chrome, html_path, jpg_path):
    png = jpg_path.replace(".jpg", "_raw.png")
    cmd = [chrome, "--headless=new", "--no-sandbox", "--disable-gpu",
           "--disable-dev-shm-usage", "--hide-scrollbars",
           "--force-device-scale-factor=2", "--window-size=816,1056",
           f"--screenshot={png}", f"file://{html_path}"]
    subprocess.run(cmd, capture_output=True, timeout=120)
    if not os.path.exists(png):
        return False
    from PIL import Image
    im = Image.open(png).convert("RGB")
    # Normalize to exactly 1632x2112 (2x Letter)
    target = (1632, 2112)
    if im.size != target:
        canvas = Image.new("RGB", target, "white")
        crop = im.crop((0, 0, min(im.width, target[0]), min(im.height, target[1])))
        canvas.paste(crop, (0, 0))
        im = canvas
    im.save(jpg_path, "JPEG", quality=92)
    try:
        os.unlink(png)
    except OSError:
        pass
    return True


# ---------------------------------------------------------------------------
# Markdown
# ---------------------------------------------------------------------------
def build_md(meta, home, sec, lh, scores, overall, grade, register, remediation):
    lines = [f"# Fable 5 Audit Report — {meta['name']}", "",
             f"**Site:** {meta['host']}  ", f"**Ref:** {meta['ref']}  ",
             f"**Audit date:** {meta['date']} · **Re-audit due:** {meta['reaudit']}  ",
             f"**Overall grade:** {grade} ({overall}/100)", "",
             "## Category scores", ""]
    label_map = {"performance": "Performance (.20)", "crawlability": "Crawlability (.15)",
                 "seo_meta": "SEO Meta (.15)", "structured_data": "Structured Data (.12)",
                 "hygiene": "Site Hygiene (.10)", "security": "Security (.10)",
                 "accessibility": "Accessibility (.10)", "social": "Social (.08)"}
    lines.append("| Category | Score |")
    lines.append("|---|---|")
    for k in WEIGHTS:
        lines.append(f"| {label_map[k]} | {scores[k]}/100 |")
    lines.append("")
    if lh.get("available"):
        lines += ["## Lighthouse (mobile)", "",
                  f"- Performance {lh.get('performance')} · Accessibility {lh.get('accessibility')} · "
                  f"Best Practices {lh.get('best_practices')} · SEO {lh.get('seo')}",
                  f"- LCP {lh.get('lcp_s')}s · Speed Index {lh.get('si_s')}s · "
                  f"TBT {lh.get('tbt_ms')} ms · Weight {lh.get('weight_mb')} MB", ""]
    lines += ["## Findings register", "", "| Area | Status | Detail |", "|---|---|---|"]
    for cat, status, detail, _ in register:
        lines.append(f"| {cat} | {status} | {detail} |")
    lines += ["", "## Priority remediation", ""]
    for i, r in enumerate(remediation, 1):
        lines.append(f"{i}. {r}")
    lines += ["", "---", "",
              "_Certified by Claude Fable 5 · model claude-fable-5 · "
              f"digital audit signature · Ref {meta['ref']}_"]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Fable 5 website audit")
    ap.add_argument("domain")
    ap.add_argument("--name", default=None)
    ap.add_argument("--logo", default=None)
    ap.add_argument("--color", default="#0f0f0f")
    ap.add_argument("--accent", default="#b8181f")
    ap.add_argument("--pages", type=int, default=40)
    ap.add_argument("--no-lighthouse", action="store_true")
    ap.add_argument("--no-pdf", action="store_true")
    args = ap.parse_args()

    base, host = normalize_domain(args.domain)
    name = args.name or host.replace("www.", "").split(".")[0].replace("-", " ").title()
    outdir = Path("audits") / host
    outdir.mkdir(parents=True, exist_ok=True)

    chrome = find_chrome()
    print(f"→ Auditing {base}  (name: {name})")
    print(f"  chrome: {chrome}")

    print("  · fetching home page…")
    resp = fetch(base)
    home = analyze_home(base, resp)
    if not resp.status_code:
        print(f"  ! home fetch failed: {getattr(resp,'error','?')}")

    print("  · security headers…")
    sec = check_security_headers(resp)

    print("  · robots + sitemap…")
    robots = discover_robots_sitemap(base)
    print(f"    sitemaps: {len(robots['sitemaps'])}  urls: {robots['url_count']}  "
          f"junk: {len(robots['junk_urls'])}  off-domain: {len(robots['offdomain_urls'])}")

    print("  · 404 test…")
    four04 = test_404(base)

    print(f"  · crawling up to {args.pages} pages…")
    crawl_urls = robots["urls"] if robots["urls"] else [base]
    crawl_res = crawl(crawl_urls, base, args.pages)
    print(f"    crawled {crawl_res['count']}  no-H1: {len(crawl_res['no_h1'])}  "
          f"dup-titles: {len(crawl_res['dup_titles'])}")

    if args.no_lighthouse:
        lh = {"available": False, "error": "skipped"}
    else:
        print("  · lighthouse (mobile)… this can take ~60s")
        lh = run_lighthouse(base, chrome)
        if lh.get("available"):
            print(f"    perf {lh['performance']} · a11y {lh['accessibility']} · "
                  f"bp {lh['best_practices']} · seo {lh['seo']}")
        else:
            print(f"    lighthouse unavailable: {lh.get('error','?')}")

    scores, overall = score_all(home, sec, robots, four04, crawl_res, lh)
    grade = letter_grade(overall)
    register, remediation = build_findings(home, sec, robots, four04, crawl_res, lh, scores)

    now = datetime.now()
    ref = f"{re.sub(r'[^A-Z]', '', name.upper())[:3] or 'F5A'}-{now:%Y-%m%d}"
    meta = {
        "name": name, "host": host, "logo": args.logo,
        "color": args.color, "accent": args.accent,
        "date": now.strftime("%B %-d, %Y"),
        "reaudit": (now + timedelta(days=90)).strftime("%B %-d, %Y"),
        "ref": ref,
    }

    # write data.json
    data = {"meta": meta, "home": home, "security": sec, "robots":
            {k: (v if k not in ("urls",) else v[:50]) for k, v in robots.items()},
            "four04": four04, "crawl": {k: v for k, v in crawl_res.items() if k != "pages"},
            "lighthouse": lh, "scores": scores, "overall": overall, "grade": grade,
            "register": [{"area": c, "status": s, "detail": d} for c, s, d, _ in register],
            "remediation": remediation}
    (outdir / "data.json").write_text(json.dumps(data, indent=2, default=str))

    # write html + md
    html_str = build_html(meta, home, sec, lh, scores, overall, grade, register, remediation)
    html_path = (outdir / "report.html").resolve()
    html_path.write_text(html_str)
    (outdir / "report.md").write_text(
        build_md(meta, home, sec, lh, scores, overall, grade, register, remediation))

    # render
    if chrome and not args.no_pdf:
        print("  · rendering PDF…")
        render_pdf(chrome, str(html_path), str(outdir / "Report.pdf"))
    if chrome:
        print("  · rendering JPG (1632×2112)…")
        render_jpg(chrome, str(html_path), str(outdir / "Report.jpg"))

    print(f"\n✓ {name}: grade {grade} ({overall}/100)")
    print(f"  → {outdir}/  (Report.pdf, Report.jpg, report.md, data.json)")


if __name__ == "__main__":
    main()
