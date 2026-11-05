# Next steps (a running list: we add to it and Shane tackles it a little at a time)

Last updated 2026-11-05. Nothing here is urgent except item 1.

1. **Owner sign-in (security).** Step 1 (Shane): Firebase console > Authentication > Sign-in method > Email/Password > Enable. Step 2 (later, Shane): the one `owner-login.sh` command in Terminal on the Mac. Until step 2 is done the restaurant database can still be read by anyone who knows where to look. Claude re-checks from outside after Shane says "owner login done".
2. **Real reviews or quotes** from 2-3 actual people Shane has worked with (Claude never writes or invents them; Shane asks, they answer, Claude puts them on the site and fills the empty testimonials page).
3. **Fast replies to every lead.** Idea: an automatic "we got your message" confirmation, plus Shane replying within hours.
4. **SEO and numbers (Shane, a little at a time):** Google Search Console (submit sitemap.xml); the visitor counter is BUILT (see the Owner link in any page footer; opens after the owner sign-in in item 1; GA ID is still blank, optional); Google Business Profile for Key Technologies; PageSpeed API key for the audit tool.
5. **Outreach is where clients come from.** About 107 restaurants still have no Instagram handle; Shane (or Claude with Shane's list) can look them up. Keep adding restaurants from screenshots to the DM list.
6. **Orange County beach city pages** (later; the Las Vegas page is the model).
7. **Case studies:** none yet. Idea: a "proof" page from Shane's own numbers (about 10,000 restaurants watched).
8. **Pricing:** deliberately OFF the site (Shane, 2026-11-05). Revisit only with real client numbers. Shane wants a number in mind for free calls.
9. **Sales Partner Network demo: TAKEN DOWN (Shane, 2026-11-05).** The demo page, its cards and links, and the commission calculator on the Email demo are gone (old addresses quietly redirect to the demos hub). Open question: the separate Partner interest list page (key-platform/partners.html) is still up; keep or take down?
10. Ideas not yet decided: a Services-page "read more" tidy-up is done; add the founder card to city pages; footer "Book a Call" link.
11. **Backups (checked 2026-11-05):** there is NO automatic backup of the LVR database. The only backup in the repo is a one-time copy from 2026-09-10 (five nodes, before a clean-up). The Firebase free plan has no scheduled backups as far as we know. The repo is PUBLIC, so a backup must never be saved into it (it would publish the restaurant list). Options: (a) Firebase console > Realtime Database > Data > three dots > Export JSON (works on any plan, saves to the Mac); (b) a Mac script that downloads the data to a dated file in a folder Time Machine already backs up; (c) a PRIVATE repository for backups (needs a one-time token from Shane). Decision pending.
12. **Domain keytechnologies.si:** check the registrar login, that auto-renew is ON, and that the renewal card is current (an expired domain takes the whole site down). Claude cannot see this.
13. **The site publishes from the branch claude/master-file-e6ofy0**, not from main. Fine today; worth moving to main later so it cannot be lost by deleting the branch.
14. **Contact-form email alerts use Formspree's free plan** (a monthly limit applies). Leads are also saved in the database, so none are lost, but check the limit if volume grows.
15. **Visitor counter follow-ups:** (a) have an attorney glance at privacy.html now that it describes the counter; (b) deploy the staged key rules with the owner lockdown (item 1) so only you can read the data; (c) after you sign in once on a device, that device stops counting itself (switch on the report page).
16. **The Owner report is open to anyone who clicks 'Owner' (Shane's choice for now).** It shows only anonymous numbers. Lock it when the owner sign-in (item 1) is done: it then asks for the sign-in by itself.
17. **SEO roadmap:** see docs/key-integration/SEO_PLAN.md (Search Console and Bing Webmaster Tools are the two biggest steps; Claude works one item per check-in).
