# The octopus (how everything fits together)

Shane's model (2026-11-18): Key Technologies is the brain. Everything else is a tentacle that looks, feels and works like Key Technologies. Same colors, same font, same layout, one wallet per person.

## The brain (Key Technologies)
- Look: background #0f171e, cards #232f3e, lines #37475a, text #f6f8fb, dim text #aab9ca, Key blue #00a8e1 (hover #33bce8), light blue #4fc8f0, buttons blue with dark text #0f171e, font Lato. Dark only.
- One product: **Restaurant Rewards** (the points system; formerly "LVR Rewards"). One wallet per person, one balance, accepted at every participating restaurant.
- Checked automatically: `.github/site-check/static.py` fails with "theme drift" if a rewards page loses the Key background, blue or Lato font.

## The tentacles
| Tentacle | What it is | Where | Status |
|---|---|---|---|
| Johnny Mac's | Restaurant website with Restaurant Rewards built in | sites/johnny-macs (real site), sites/key-technologies/johnny-macs-demo (unlisted demo) | demo done; client has not joined |
| Las Vegas Restaurants | The first operator and Instagram community; member sign-up and Rewards admin | lvr-data-a60c1.web.app (Mac deploys) | rename + Key look script ready: deploy-restaurant-rewards-name.sh |
| CRM | Customer records for Key Technologies and clients | key-platform, kt-crm | exists |
| Other businesses | Any restaurant (or later any business) that wants to join | restaurants.html, join-restaurant.html | open when they are ready; do not chase the rest |

## Rules of the model
1. A new tentacle never gets its own colors or fonts for the rewards experience. It reuses the Key look.
2. A restaurant's own website may keep its own brand; the wallet/rewards part inside it uses the Key look and says "Powered by Key Technologies".
3. Rewards are a promotional perk, never money or property, and are not sent between people. Friends join through an invite link.
4. Restaurants join when they understand it and are ready. The rest are left alone for now.
