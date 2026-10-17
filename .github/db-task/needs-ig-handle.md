# Records with no Instagram handle (can't be DM'd until fixed)

Generated 2026-10-16 from a read-only scan of `dashboard_crec` (109 of 870
total records, ~12.5%). Almost all are leftovers from a past "Yelp
migration" import that never got Instagram handles attached. None have
been DM'd (no outreach history to lose), so adding a handle is a safe,
zero-risk fix whenever one is confirmed.

**Top priority — well-known, single-location Strip spots.** These are the
best bang-for-the-buck: high profile, so worth outreach, and easy for a
human with the Instagram app to find in seconds (search box, done). A
web-search lookup from here can't reliably confirm the exact @handle, so
these need a quick human check rather than a guess.

| num | name |
|---|---|
| 50905 | Jaleo (Cosmopolitan) |
| 50864 | Carversteak (Resorts World) |
| 50904 | HaSalon (The Venetian) |
| 50888 | Golden Steer Steakhouse |
| 50890 | Del Frisco's Double Eagle Steakhouse |
| 50849 | Ruths Chris Steak House |
| 50837 | Bazaar Mar by Jose Andres |
| 50843 | Scarpetta |
| 50836 | The Pinky Ring by Bruno Mars |
| 50911 | Mabel's Bar & Q by Chef Michael Symon |
| 50822 | Vanderpump A Paris |
| 50851 | The Golden Tiki |
| 50900 | Ghost Donkey |
| 50901 | Blue Martini |
| 50823 | Lady M Cake Boutique |

**Lower priority — regional chains.** Skip unless a local-franchise IG
account actually exists (national chain accounts won't respond to local
outreach): WaBa Grill (50847), Duck Donuts (50894), Bruster's Real Ice
Cream (50889), Krispy Krunchy Chicken at Shortline Express (50862).

**Everything else (full list of 108 — Daikon Vegan Sushi/50818 fixed
2026-10-17, see below, removed from this list)** — all tagged `[Yelp
migration - IG needed]` in `notes` except the last 4, which are `[Manually
added]`/`[... needs lookup]`: Mura Japanese BBQ & Shabu (50281), DOMA the
Korean BBQ (50400), Wok To Walk (50816), Trap Wingz (50817),
Lucino's Pizza (50820), Sul & Beans (50821), Paina Cafe (50824),
Brooklyns Best Pizza & Pasta (50825), Fishers Deli (50826), Halgatteok
(50827), Waffles Cafe (50828), Big Mamas Wings & Things (50829), McMullans
Irish Pub (50830), Birria - Bite los Arcos (50831), Hello Hibachi (50832),
702 Prep (50833), Bar Boheme (50834), Finesse Catering and Events (50835),
El Manantial Restaurant (50838), Noodle Nest (50839), Lammys Bakehouse
(50840), Mariposa Cocina & Cocktails (50841), Geos Tacos (50842), The Sand
Dollar Downtown (50844), Stallones Italian Eatery (50845), Fugazzeta Pizza
& Empanadas (50846), Board and Graze (50848), Lot J Tacos (50850), 1923
Prohibition Bar (50852), Double Helix Wine & Whiskey Lounge (50853),
Matiki Island BBQ (50854), Laguna Pool House & Kitchen (50855), Bad to the
Bone BBQ (50857), The Spot Lv (50858), Whats Zaap? Thai Food (50859),
Proper Eats Food Hall (50860), Luchini Italian Restaurant (50861), Ole
Churros (50863), Rumi Room Persian Indo-Pak Cuisine (50865), Little Avalon
(50866), Scrambled (50868), Tamba (50869), Doya Jjambbong (50870), Horizon
Shine (50871), Rebellion Pizza (50872), The Laundry Room (50873), Liquid
Acai Eatery (50874), Pizza Pie Guy (50875), Ohjah Noodle House (50876),
Piero's Italian Cuisine (50878), Umiya Sushi (50879), Parlour Brunch &
Late Night Burger Bar (50880), Sgrizzi By Chef Marc (50881), Cloud Tea
(50883), Sultans Wagyu Grill (50884), Rock N' Potato (50885), Yu or Mi
Sushi (50886), Netflix Bites (50887), Emmitt's Vegas (50891), Lost Sweets
(50892), Umezono Sushi and Japanese Grill (50893), Pacific Island Taste
(50897), The Library (50898), The Smashed Pig Gastropub (50899), Salt &
Ivy (50902), The Palace Station Oyster Bar (50903), Anima by Edo (50906),
SoyMexican Veggie-Vegan Eatery (50907), Take It Easy Roasters (50908),
Zenaida's Cafe (50909), 168 K-BBQ by Hanu (50910), Manizza's Pizza
(50912), Oodle Noodle (50913), Gjelina (50914), Krung Siam Thai Restaurant
& Bar (50915), Frankensons (50916), The Oak Room - Grill, Gaming and
Cocktails (50917), CrunCheese (50918), Kyunu (50921), Delicias House
(50922), El Jimador Mexican Grill And Bar (50923), Basil 'n Lime (50924),
Chickie's & Pete's (50925), El Compa Leo Mariscos (50926), Easy's Cocktail
Lounge (50927), Cliff House, Dancing Dumplings, Gigolo, Pasta & Pomo
(these last 4 are push-ID keyed, not numeric — "Manually added from IG
post... needs lookup").

## Records with a handle on file that's flagged bad (likely typos — DIFFERENT, more urgent list)

Found 2026-10-17 by checking `/dashboard/badig` (a legit LVR flag path —
confirmed by cross-referencing an older session's log in
`dupes-and-badig.txt`, names match exactly). These records already have
an `instagram` value and are sitting at `status: pending`, so outreach
could already be (or already was) attempted on a broken handle and
silently go nowhere.

**UPDATE (2026-10-17, same day): 8 of these are now fixed.** Found
`/dashboard/igsuggest` - a genuine, sourced IG-verification dataset (real
addresses, follower counts, website cross-references for each entry).
Applied these corrections directly, each a single-character typo fix or
(for Daikon Vegan Sushi) a brand-new verified handle, badig flag cleared
on each:
- 50125 Nana's house of Soul Food: → `@nanas_house_of_soul_food_` (missing trailing underscore)
- 50204 Whiskful Thinking Cakes: → `@whiskfulthinkingcakeslv` (missing "lv")
- 50278 Teriyaki Madness: → `@teriyakimadnesslv` (doubled "a")
- 50315 Sonrisa Grill: → `@sonrisagrill.lv` (was ".nv", should be ".lv")
- 50345 Earthly Plant Based Eatery: → `@earthlyplantbased` ("earthly" was misspelled)
- 50360 El chavo handcrafted snack bar: → `@aguas_el_chavo` (doubled "a")
- 50611 Korea House: → `@koreahouselv` (missing "a" in "Korea")
- 50818 Daikon Vegan Sushi (was blank, in the no-handle list above): → `@daikonvegansushi`

**Still open — remaining 7, need a human phone-check:**

| num | name | handle on file | note |
|---|---|---|---|
| 50206 | Backyard Bbq Village | @baackyardbbqvillage | igsuggest says → `@backyardbbqvillage` but flagged only "medium" confidence - worth a quick look before accepting |
| 50221 | Bowltastic | @bowltasticfood | igsuggest confirms this is already correct, flag is stale - no action needed |
| 50395 | Snooze | @eatsnooze | igsuggest confirms this is already correct, flag is stale - no action needed |
| 50608 | La Flor De Michoacan Ice Cream | @laflordemichoacanicecrea | igsuggest explicitly says "worth a look before accepting" - several near-identical accounts exist, didn't want to guess |
| 50745 | Dom DeMarco's Pizzeria & Wine Bar | @domdemarcos | igsuggest confirms this is already correct, flag is stale - no action needed |
| 50882 | Gabriels Kitchen Las Vegas | @gabrielskitchenlasvegas | not covered by igsuggest, unclear |
| 60029 | Ten Seconds Yunnan Rice Noodle Las Vegas | @tensecondsyunnanricenoodlelv | not covered by igsuggest, unclear |
| 60037 | Banh Mi House by Dakao | banhmihouselv | I added this myself this session from a real screenshot - flag is almost certainly just about the missing "@", not a wrong handle |

So really only 50206, 50882, 60029, and 60037 (the "@" formatting one)
need a look now — the other 3 (50221, 50395, 50745) are confirmed fine.

## How to fix one
Once you (or I, once given a confirmed handle) have the real @handle,
it's a one-line task.sh PUT to `dashboard_crec/<num>/instagram` — same
pattern as every other add this session. No need to touch anything else;
`status`/`attempts` are already set to `pending`/0 from the original
import.
