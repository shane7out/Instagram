# KEY website

The marketing/lead-generation website for KEY — Shane Christensen's AI
consulting and intelligent business systems company.

See `CLAUDE.md` for the full set of rules and the current design system
before changing anything.

## Status

Built from the full written specification (no byte-for-byte original
site was available to port — see `CLAUDE.md`'s "Known open items"). One
page (`index.html`) with everything inline: hero, two lead-capture
forms, services, solutions, the KEY Method, About Shane, locations, FAQ,
and footer. Forms are real, working UI with honest validation — they are
**not** connected to a backend yet, and intentionally don't pretend to
be.

## Deploy (GitHub Pages)

1. Push this repo to GitHub with `index.html` at the root (already the
   case).
2. Repo → Settings → Pages → choose the deployment source/branch →
   publish.
3. A custom domain can be connected later (none is chosen yet — see
   `CLAUDE.md`). Enable HTTPS once a domain is attached.

## Structure

```
index.html     The whole site today (CSS + JS inline)
404.html
privacy.html   Placeholder — finalize once backend/business terms are set
terms.html     Placeholder — finalize once backend/business terms are set
robots.txt
sitemap.xml    Has REPLACE-WITH-DOMAIN placeholders — fix once a domain exists
CLAUDE.md      Rules, design tokens, open items — read first
firebase-leads-rtdb.rules.json   Security rules for KEY's own lead database
```

## Lead database — one Mac step away from live

The forms already have real submission code wired up (see the
`KEY_LEADS_DB_URL` note in `index.html`'s script and the full walkthrough
in `CLAUDE.md`). It's pointed at nothing yet, so right now it shows an
honest "not connected" message instead of a fake success. To turn it on:
create a new Firebase project, set the Realtime Database rules from
`firebase-leads-rtdb.rules.json`, and paste the resulting database URL
into one line in `index.html`. Full steps are in `CLAUDE.md` under "Lead
database." This is intentionally simple — no backend server, no Cloud
Functions, just the database and rules that only allow creating a new
lead (never reading, overwriting, or deleting one).

## Lead alert email + booking link — both built, both off until you add one line

Two more additive, optional features in `index.html`, both off by default
and documented in full in `CLAUDE.md`:

- `KEY_FORMSPREE_URL` — set this (free formspree.io signup, 2 minutes) and
  every lead also sends an email alert, on top of the database save.
- `KEY_CALENDLY_URL` — set this and a successful submission shows a real
  "Book a time now" button instead of just a thank-you line.

Neither needs the Mac — both are plain web signups you can do from a
phone.

## Next steps

- **Get a real domain.** The current GitHub Pages URL
  (`shane7out.github.io/Instagram/`) works but isn't something to put in
  front of a prospect or run ads to — this is the highest-priority item
  left.
- **Create the Firebase project and flip the forms on** — see "Lead
  database" above.
- **Set `KEY_FORMSPREE_URL` and `KEY_CALENDLY_URL`** — see above.
- Once a domain exists, update every placeholder URL in one pass
  (`sitemap.xml`, the `<meta>`/canonical tags in `index.html`).
- Eventually: a way to actually read the collected leads back out (a
  small PIN-gated viewer page, or an export), and/or wire this up to
  Shane's existing CRM instead of/alongside this database.
- Add analytics once a platform is chosen.
- Add real contact details (email/phone) to the footer and Contact
  section.
