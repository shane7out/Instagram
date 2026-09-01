# St Rita's Retreat — website

A static recreation of the St Rita's Retreat website (Gold Hill, Oregon): a
personal and group retreat center above the Rogue River Valley.

## Pages

| File | Purpose |
| --- | --- |
| `index.html` | Home — hero, the three ways to stay, the grounds, the setting |
| `about.html` | The retreat's story, what it offers, and the Southern Oregon setting |
| `facilities.html` | Guest house, shared spaces, and the grounds |
| `availability.html` | How booking works, inquiry form, deposit and cancellation terms |
| `contact.html` | Phone, email, addresses, message form, directions |

`assets/styles.css` holds the whole design system; `assets/main.js` handles the
mobile menu and the inquiry forms.

## Running it

No build step and no dependencies — open `index.html` directly, or serve the
folder:

```
python3 -m http.server 8000 --directory site
```

Then visit <http://localhost:8000>.

## The availability calendar

`availability.html` shows a live month grid built by `assets/calendar.js` from
`data/availability.json`. Guests pick an arrival and a departure date and those
carry straight into the inquiry form. No third-party booking service and no
server are involved — it is a static file the site reads.

### The data file

```json
{
  "updated": "2026-09-01",
  "blocks": [
    { "start": "2026-09-11", "end": "2026-09-13", "status": "booked", "label": "Parish weekend" }
  ]
}
```

`start` and `end` are **nights occupied, inclusive of both ends**. A group
arriving Sep 14 and departing Sep 17 sleeps the nights of the 14th, 15th and
16th, so it is recorded as `start: 2026-09-14, end: 2026-09-16` — the 17th
stays open for the next arrival. `status` is `booked`, `held`, or `closed`.
`label` is optional and shown only in the accessible description; leave it out
to keep guest names off a public page.

### Keeping it current

Either edit `data/availability.json` by hand, or keep bookings in a normal
calendar app and sync:

```
python3 tools/sync_availability.py "https://calendar.google.com/calendar/ical/.../basic.ics"
```

That reads any `.ics` feed (Google, Apple, Outlook, or a saved file) and
rewrites the data file. It uses only the Python standard library. Event
summaries are not published unless you pass `--include-labels`. An event is
recorded as `held` when its status is tentative or its title starts with HOLD,
`closed` when the title mentions CLOSED or MAINTENANCE, and `booked`
otherwise; cancelled and past events are dropped.

A browser cannot read a Google Calendar `.ics` feed directly — the feed sends
no CORS headers — which is why the sync runs ahead of time and the site reads
the resulting file. Run it after changing bookings and commit the result, or
run it on a schedule from CI.

## Notes

- **Forms do not send.** There is no backend. Submitting either form shows a
  confirmation in place and points the visitor at the phone number and email
  address, so an inquiry is never silently dropped. Wire the forms to a form
  service or a mail handler before using this in production.
- **The calendar shows availability; it does not take bookings.** Guests pick
  dates and send an inquiry — nothing is reserved automatically, which matches
  how the retreat already works (contract and deposit confirm a date). Opened
  over `file://` the browser blocks the data fetch, so the calendar renders
  with nothing marked taken and says so rather than showing dates as free.
- **Imagery is placeholder.** Photographs are stood in for by inline SVG
  illustrations in the retreat's palette, so the site renders with no external
  image files. Replace the `.plate` blocks with real photography when it is
  available.
- **Fonts** load from Google Fonts (Cormorant Garamond and Inter) with system
  serif and sans-serif fallbacks, so the site still reads correctly offline.
- Content reflects publicly listed details for the retreat — 15 rooms sleeping
  up to 30 retreatants, the grotto, labyrinth and trails, the 90-day
  cancellation terms, and the Blackwell Road address. Confirm all of it against
  the retreat's own records before publishing.
