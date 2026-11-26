#!/usr/bin/env python3
"""Shane (2026-11-26): "from now on we will say they have a cash value... 1 reward is equal to $1 of credit ... you can exchange that for the credit."
Replaces the "no cash value" statements on the KEY REWARDS pages with: each key / reward is worth $1 in credit toward offers at participating
businesses (credit, not paid out in cash). NOT touched on purpose: the LVR member program pages (my-account, rewards-terms, spin-terms, menu, rewards.html,
which already say $1 toward free offers), the generic restaurant-rewards guides and the home-page service blurb (advice and product copy for other businesses).
Each pair must be found exactly once (a missing or doubled one stops the run). Idempotent: already-changed text is skipped."""
import pathlib, sys
S = pathlib.Path('sites/key-technologies')
KW = 'Each key is worth $1 in credit toward offers at participating businesses'
P = {
 'key-rules.html': [('Keys have no cash value.', KW + ' on the Key Rewards network. Credit is used with those businesses and is not paid out in cash.')],
 'key-what-you-get.html': [('Keys have no cash value. Key Technologies', KW + ', and is not paid out in cash. Key Technologies')],
 'key-waitlist.html': [('Keys are rewards points with no cash value.', KW + ', and is not paid out in cash.'), ('rv:"v2"', 'rv:"v3"')],
 'key-dine.html': [('I understand keys have no cash value.', 'I understand each key is worth $1 in credit at participating businesses and is not paid out in cash.'),
                   ('Keys have no cash value and are good for 60 days', 'Each key is worth $1 in credit at participating businesses (not paid out in cash) and is good for 60 days')],
 'key-giveaway.html': [('Keys have no cash value. They cannot be sold or exchanged for cash. They are good for 60 days', KW + '. Credit is not paid out in cash. Keys are good for 60 days')],
 'key-rewards-join.html': [('They have no cash value, cannot be sold or exchanged for cash, and do not expire.', 'Each reward is worth $1 in credit toward offers at participating businesses. Rewards cannot be exchanged for cash and do not expire.')],
 'key-rewards-checkin.html': [('They never expire, have no cash value, cannot be sold or exchanged for cash, and are never refunded once used.', 'They never expire, are each worth $1 in credit toward offers at participating businesses, cannot be exchanged for cash, and are never refunded once used.')],
 'key-rewards-dashboard.html': [('Rewards have no cash value.</p>', 'Each reward is worth $1 in credit.</p>'),
     ('Rewards have no cash value, cannot be sold or exchanged, and are never refunded once used.', 'Each reward is worth $1 in credit toward an offer. Rewards cannot be sold or exchanged for cash, and are never refunded once used.'),
     ('They have no cash value, cannot be sold or exchanged for cash, and are never refunded once used.', 'Each is worth $1 in credit toward an offer, cannot be exchanged for cash, and is never refunded once used.')],
 'key-rewards-me.html': [('Rewards have no cash value and cannot be sold or exchanged for cash.', 'Each reward is worth $1 in credit toward offers at participating businesses and cannot be exchanged for cash.'),
     ('Rewards have no cash value and cannot be bought or sold.', 'Each reward is worth $1 in credit and cannot be bought or sold.')],
 'key-rewards-marketplace.html': [('Key Rewards points have no cash value and cannot be bought, sold or exchanged for cash.', 'Each Key Rewards point is worth $1 in credit toward offers at participating businesses. Points cannot be bought, sold or exchanged for cash.'),
     ('Key Rewards points have no cash value and are good for 60 days', 'Each Key Rewards point is worth $1 in credit and is good for 60 days'),
     ('<li>Key Rewards points have no cash value.</li>', '<li>Each Key Rewards point is worth $1 in credit toward offers.</li>')],
 'restaurant-confirm.html': [('Key Rewards are a promotional perk with no cash value.', 'Key Rewards are a promotional perk. Each one is worth $1 in credit toward offers at participating businesses.')],
 'restaurant-rewards-treasury.html': [('Key Rewards are a promotional perk with no cash value.', 'Key Rewards are a promotional perk. Each one is worth $1 in credit toward offers at participating businesses.'),
     ('They are not money, a deposit or stored value and cannot be exchanged for cash', 'They are not money or a deposit and cannot be exchanged for cash'),
     ('Key Rewards have no cash value.', 'Each Key Reward is worth $1 in credit.'),
     ('No cash value. Not a debit or credit card.', 'Worth $1 in credit each. Not a debit or credit card.'),
     ('No cash value. Key Rewards are not money and cannot be exchanged for cash.', 'Worth $1 in credit each. Key Rewards are not money and cannot be exchanged for cash.')],
 'restaurant-rewards-uses.html': [('Key Rewards is a free trial game with no cash value, and it cannot be bought or sold.', 'Key Rewards is a free trial game. Each reward is worth $1 in credit toward offers, and rewards cannot be bought or sold.')],
 'sign-agreement.html': [('They have no cash value and follow the Key Rewards program terms.', 'Each is worth $1 in credit and follows the Key Rewards program terms.')],
 'key-platform/kr-engine.js': [('// Rewards have no cash value and cannot be bought or sold', '// Each reward is worth $1 in credit; rewards cannot be bought or sold')],
}
for f in ['restaurant-rewards-share.html', 'restaurant-rewards-share-gold.html', 'restaurant-rewards-share-kt.html', 'restaurant-rewards-share-story.html']:
    P[f] = [('No cash value', '$1 in credit each')]
bad = 0
for rel, pairs in P.items():
    f = S / rel; s = f.read_text(encoding='utf-8'); o = s
    for a, b in pairs:
        n = s.count(a)
        if n == 0:
            if b in s: continue
            print('NOT FOUND', rel, '|', a[:60]); bad += 1; continue
        if n > 1 and rel not in ('restaurant-rewards-treasury.html',) :
            print('MORE THAN ONCE', rel, n, '|', a[:60])
        s = s.replace(a, b)
    if s != o: f.write_text(s, encoding='utf-8'); print('changed', rel)
sys.exit(1 if bad else 0)
