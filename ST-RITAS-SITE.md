# St Rita's Retreat — Website

A five-page website for St Rita's Retreat, a personal and group retreat center
in Gold Hill, Oregon. Plain HTML and CSS — no accounts, no monthly fees, and
nothing to install. It is built to be hosted free on GitHub Pages.

## Links

| What | Where |
| --- | --- |
| Directory of all sites | https://shane7out.github.io/Instagram/ |
| St Rita's Retreat | https://shane7out.github.io/Instagram/st-ritas/ |
| Code | https://github.com/shane7out/Instagram |
| Branch it lives on | `claude/st-ritas-retreat-clone-ntz6ys` |

The two web addresses start working once hosting is switched on — see below.

## Turn on hosting (one time)

1. Go to https://github.com/shane7out/Instagram
2. Click **Settings**, then **Pages** in the left sidebar.
3. Under Source, choose **Deploy from a branch**.
4. Set Branch to `claude/st-ritas-retreat-clone-ntz6ys` and folder to **/docs**.
5. Click **Save**, then wait a minute and open the directory link above.

Later, once you're happy with it, you can merge the branch into `main` and
point Pages at `main` instead. That's the more usual setup.

## The pages

| Page | What's on it |
| --- | --- |
| Home | Headline, the three ways to stay, the grounds, the setting |
| About | The retreat's story and the Southern Oregon setting |
| Facilities | Guest rooms, chapel, library, dining, grotto, labyrinth, trails |
| Availability | Booking calendar, inquiry form, deposit and cancellation terms |
| Contact | Phone, email, address, message form, directions |

## Where the files are

```
docs/
  index.html            <- the directory page listing all your sites
  st-ritas/             <- the retreat website
    index.html            home page
    about.html
    facilities.html
    availability.html     includes the booking calendar
    contact.html
    assets/               design and behavior (styles.css, main.js, calendar.js)
    data/
      availability.json   which dates are taken
tools/
  sync_availability.py  <- fills in the calendar from a calendar app
```

## Updating the booking calendar

The calendar shows which nights are taken. It does **not** take bookings or
payments — guests pick dates and send an inquiry, and a date becomes real when
the contract and deposit come in, the same as now.

Two ways to keep it current:

**By hand.** Edit `docs/st-ritas/data/availability.json` and add a line like:

```json
{ "start": "2026-09-11", "end": "2026-09-13", "status": "booked" }
```

Dates are the **nights slept**, including both ends. A group arriving Sep 14
and leaving Sep 17 sleeps the 14th, 15th and 16th, so the end date is the
16th — that leaves the 17th open for whoever comes next. Use `"held"` for a
tentative hold and `"closed"` for maintenance.

**From a calendar app.** Keep bookings in Google, Apple, or Outlook Calendar,
copy that calendar's secret .ics address, and run:

```
python3 tools/sync_availability.py "PASTE-THE-ICS-ADDRESS-HERE"
```

That rewrites the file for you. Guest and group names are not published unless
you add `--include-labels`. Run it after changing bookings, then commit.

## Adding another website to the directory

Open `docs/index.html`, copy one `<a class="site">` block, and change three
things: the address it points to, the name, and the one-line description. The
address can be a folder in this repo (like `st-ritas/`) or a full web address
(like `https://example.com`).

## Still to do

- **The inquiry form does not send email yet.** Submitting it shows a
  confirmation and points the guest at the phone number and email address.
  This should be wired to a form service before the link goes out widely.
- **Photos are placeholders.** The images are hand-drawn shapes in the site's
  colors. Real photography drops straight in where those sit.
- **The web address contains the word "Instagram"** because that is the
  repository's name. Connecting a real domain like stritaretreat.com, or
  moving the site to its own repository, fixes that.
- **Check the details.** Room counts, the grotto and labyrinth, the 90-day
  cancellation terms, the address and phone number all came from publicly
  listed information. Confirm them against the retreat's own records before
  publishing.

## Contact details currently on the site

- 10800 Blackwell Road, Gold Hill, Oregon 97525
- 541-660-0032
- info@stritaretreat.com
