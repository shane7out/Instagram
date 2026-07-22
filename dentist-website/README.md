# Lumina Dental Studio — Website

A polished, fully responsive marketing site for a fictional boutique dental
practice. Built as a lightweight static site with **no build step** and **no
runtime dependencies** — just open it in a browser.

## Pages

| File | Purpose |
| --- | --- |
| `index.html` | Home — hero, services, why-us, **before/after smile gallery**, stats, testimonials, booking form |
| `services.html` | Full service list, technology, membership/financing plans, FAQ |
| `about.html` | Practice story, values, care team, stats |
| `blog.html` | Patient resources / articles + newsletter signup |
| `contact.html` | Booking form, hours, location map, contact details |
| `privacy.html` | Privacy policy (sample content) |
| `accessibility.html` | Accessibility statement (sample content) |
| `404.html` | Branded not-found page |

## Structure

```
dentist-website/
├── index.html  services.html  about.html  blog.html  contact.html
├── privacy.html  accessibility.html  404.html
├── css/styles.css       # complete design system (tokens, components, responsive)
├── js/main.js           # nav, scroll reveal, FAQ, counters, before/after slider, form
├── og-image.png         # 1200×630 social share image
├── site.webmanifest     # PWA manifest
├── sitemap.xml  robots.txt
└── README.md
```

## Design

- **Aesthetic:** warm, calming boutique feel — cream + teal + coral accent
- **Type:** Fraunces (display) + Inter (body), loaded from Google Fonts
- **Imagery:** inline SVG illustrations and CSS gradients — no external images,
  so the site renders anywhere, even offline (aside from web fonts)
- **Motion:** scroll-reveal, animated stat counters, an interactive before/after
  smile slider, hover states — all respecting `prefers-reduced-motion`
- **Accessibility:** semantic landmarks, ARIA labels, visible focus rings,
  keyboard-friendly nav/FAQ/slider, and a `noscript` fallback
- **Responsive:** mobile-first, with a slide-down mobile menu under 860px

## SEO & sharing

- Per-page `<title>`, meta description, canonical URL
- Open Graph + Twitter Card tags with a rendered `og-image.png`
- **JSON-LD structured data:** `Dentist` (name, address, geo, hours, rating) on
  every page, plus `FAQPage` on the services page
- `sitemap.xml`, `robots.txt`, and a `site.webmanifest` for installability

## Wiring up the contact form

The appointment forms validate on the client and show a success state. They run
in **demo mode** until you point them at a backend. To go live, add a
`data-endpoint` attribute with your form service URL (e.g. Formspree):

```html
<form data-demo data-endpoint="https://formspree.io/f/your-id" novalidate>
```

The script (`js/main.js`) will `POST` the form data there and show the success
state on a `2xx` response, or a fallback message on error.

## Running it

No tooling required:

```bash
# open directly
open dentist-website/index.html

# or serve locally
cd dentist-website && python3 -m http.server 8000   # → http://localhost:8000
```

## Notes

- All business details (name, phone, address, reviews) and blog articles are
  **placeholder content** for a fictional practice — swap in real info to launch.
- Update the `https://www.luminadental.com` URLs in the `<head>` tags,
  `sitemap.xml`, and `robots.txt` to your real domain before deploying.
