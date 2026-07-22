# Lumina Dental Studio — Website

A polished, fully responsive marketing site for a fictional boutique dental
practice. Built as a lightweight static site with **no build step** and **no
runtime dependencies** — just open it in a browser.

## Pages

| File | Purpose |
| --- | --- |
| `index.html` | Home — hero, services overview, why-us, stats, testimonials, booking form |
| `services.html` | Full service list, technology, membership/financing plans, FAQ |
| `about.html` | Practice story, values, care team, stats |
| `contact.html` | Booking form, hours, location map, contact details |

## Structure

```
dentist-website/
├── index.html
├── services.html
├── about.html
├── contact.html
├── css/
│   └── styles.css     # complete design system (tokens, components, responsive)
├── js/
│   └── main.js        # mobile nav, scroll reveal, FAQ, counters, form demo
└── README.md
```

## Design

- **Aesthetic:** warm, calming boutique feel — cream + teal + coral accent
- **Type:** Fraunces (display) + Inter (body), loaded from Google Fonts
- **Imagery:** inline SVG illustrations and CSS gradients — no external images,
  so the site renders anywhere, even offline (aside from web fonts)
- **Motion:** scroll-reveal, animated stat counters, hover states — all respect
  `prefers-reduced-motion`
- **Accessibility:** semantic landmarks, ARIA labels, visible focus rings,
  keyboard-friendly nav and FAQ accordion
- **Responsive:** mobile-first, with a slide-down mobile menu under 860px

## Running it

No tooling required. Either:

```bash
# open directly
open dentist-website/index.html

# or serve locally
cd dentist-website && python3 -m http.server 8000
# then visit http://localhost:8000
```

## Notes

- The appointment forms are front-end demos — they show a success state but do
  not submit anywhere. Wire the `<form data-demo>` elements to your booking
  backend (or a service like Formspree) to go live.
- All business details (name, phone, address, reviews) are placeholder content
  for a fictional practice.
