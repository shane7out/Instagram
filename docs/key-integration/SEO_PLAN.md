# SEO and "AI/SI" plan (a running list; Claude works on it every check-in, Shane tackles his part a little at a time)

Last updated 2026-11-06. Honest note: nobody can promise rank #1. Ranking takes time, useful content and links from other sites. What we CAN do is be the clearest, most trustworthy answer for the term, and make the site easy for search engines and AI assistants to read.

## Done (on the site)
- Every page has a unique title (60 characters or fewer), meta description, canonical address, social-share tags and structured data (Organization/Service/FAQ/Article/Breadcrumb/ContactPage).
- Sitemap (42+ addresses, real dates), robots.txt, llms.txt (a plain summary for AI assistants), retired pages quietly redirected and kept out of the index.
- NEW guides built to be the clear answer for the brand term: "What is AI/SI? A plain-English guide" and "How to choose an AI consultant: 10 questions to ask". Both are linked from the homepage, the guides page, the Las Vegas page, the sitemap and llms.txt.
- Glossary guide "AI terms in plain English" (2026-11-06): about 19 short definitions (AI, AI/SI, LLM, agent, CRM, hallucination, RAG...), linked from the homepage guides row, the guides page, sitemap and llms.txt. Deliberately leaves out the word "token" (standing rule).
- Guide "AI for law firms: where it helps and what a person must still approve" (2026-11-06): general information, no legal advice, linked from the law page, guides page, sitemap and llms.txt.
- Guide "AI for medical and dental offices" (2026-11-06): general information; not legal or medical advice; does not certify any tool as compliant; linked from the medical-dental page, guides page, sitemap, llms.txt.
- Guide "What a business dashboard should show (and what to leave off)" (2026-11-06): general guidance with restaurant, practice and law examples, links to the dashboard demos and the restaurant and chiropractor pages; sitemap and llms.txt auto-added. No prices, no stats.
- Business Dashboards demo (indexable), Chiropractors & Specialists page, dashboard sections on the restaurant, law and medical pages (2026-11-06).
- Restaurant page (the strongest vertical: Shane keeps watch on about 10,000 restaurants), Las Vegas page, languages page.
- Visitor counter + Owner report (Sources tab shows which pages and sites bring visitors).

## Only Shane can do (each one takes minutes; ask Claude to walk you through)
1. Google Search Console: add keytechnologies.si, verify, submit https://keytechnologies.si/sitemap.xml. (Biggest single step.)
2. Bing Webmaster Tools: same (feeds Bing, Copilot and several AI assistants).
3. Google Business Profile for Key Technologies (service-area business, Las Vegas and Manhattan Beach, no street address shown).
4. Real reviews and quotes from people Shane has worked with (Claude never writes them). Then Claude adds them to the site and to the structured data.
5. Links from places that already know Shane: his Instagram bio, LVR pages, any profile (LinkedIn, X, YouTube). Tell Claude the exact profile addresses and they go into the site's structured data ("sameAs"), which helps search engines connect them.
6. Write or record one short answer a week (a post, a reel caption) that links to the matching guide.

## Claude's standing list (one item per check-in)
- Content ideas, in order: "AI phone answering for restaurants" (no prices), Orange County beach pages (when Shane says go), a "How we work" page.
- Keep titles/descriptions honest and unique; no keyword stuffing; no made-up stats, clients, reviews or rankings.
- Check Core Web Vitals (speed) after every change; keep images sized and compressed.
- Re-run the generators in this order after any change: build_* scripts, add_home_link.py, tidy_nav.py, add_analytics.py (Home button and the counter come from the last two).
- Watch the Owner report's Sources and Pages tabs; double down on what works.
