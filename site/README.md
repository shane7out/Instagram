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

## Notes

- **Forms do not send.** There is no backend. Submitting either form shows a
  confirmation in place and points the visitor at the phone number and email
  address, so an inquiry is never silently dropped. Wire the forms to a form
  service or a mail handler before using this in production.
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
