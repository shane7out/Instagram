# Making the Johnny Mac's account demo real (plan, 2026-11-18)

Demo (sample data only, unlisted): https://keytechnologies.si/johnny-macs-demo/app.html
Three things it shows, all working in the browser and remembered between visits: (1) the RESTAURANT view: account balance, given out / used and returned, "give Restaurant Rewards to a customer", and an activity list; (2) the CUSTOMER view: log in, balance, "use Restaurant Rewards" (type an amount or "use all"), and "my activity" listing every time rewards came in or went out; (3) a 5-step guide at the top that ticks as you go. "Start over" resets it.

## What already exists in the REAL system (from LVR-PROJECT-STATUS.md; not re-tested today)
- A member wallet opened with a personal link (no password), with a balance and a log of every grant/adjustment (`lvr_points/wallets`, `grants`).
- Restaurants with their own portal login that shows only their own redemptions, with CSV download (`lvr-restaurant-portal.html`).
- A catalog of redeemable offers per restaurant (fixed point cost), redemption codes, and a funding ledger per restaurant ("credit remaining"). Vanilla Rice is live this way.
- Owner admin (`lvr-points-admin.html`) to create wallets, adjust points with a reason, see every redemption.
So the demo's "account balance" is the restaurant's funding credit, and "activity" is the grants + redemptions logs already stored.

## What the demo does that the real system does NOT do yet
1. Restaurant account screen: show the credit balance, what was given out and what was used, as a bank-style statement (the portal today lists redemptions only).
2. Customer "my activity" list showing BOTH rewards received and rewards used in one timeline (today: grants log and redemptions are separate).
3. Typing any amount to redeem (e.g. 83.17). The real program redeems FIXED offers from the catalog at a set point cost, and the terms say rewards are only for free offers. Typed amounts toward a bill would change the program: ATTORNEY FIRST. Also real points are whole numbers.
4. "Rewards return to the restaurant's account when used": today a redemption spends the member's points and uses up the restaurant's funded credit. Decide the accounting (below).

## Decisions needed from Shane before building
- Who pays for the 500 (does Johnny Mac's buy credit from Shane, or does Shane give a starting amount)?
- When a customer redeems, do the rewards go back into the restaurant's account (demo) or is the credit simply used up (today)?
- Fixed offers (today) or a typed amount (demo)? Typed amount needs attorney review and a terms change.
- How does a customer log in at Johnny Mac's: the same personal link as today (recommended), or phone + code (needs a text-message service and cost).

## Build steps, in order (nothing goes live until Shane runs a Mac command; the live program keeps working at every step)
1. NO CODE: add Johnny Mac's as a restaurant with a catalog offer using lvr-points-admin (existing tool) and write its funding credit entry. Shane does this in the admin; I can write the exact click-by-click list.
2. Restaurant portal: add an "Account" card + Recent activity (given out / used) reading the existing funding ledger and redemptions. Mac deploy script with automatic rollback, like deploy-rewards-admin.sh.
3. Customer screen (my-account.html): add one combined "My activity" timeline from grants + redemptions. Website change only (no database change).
4. Only after the decisions above: typed-amount redemption, if approved.
5. Run the emulator rules tests (task.sh already does) before any rules change; no rules change is needed for steps 1-3.

## Rules to keep (standing)
Restaurant Rewards have no cash value, are not money or property, cannot be sent between people, no "use it or lose it", no dollar amounts shown on rewards, Instagram tag bonus stays off, the live program for existing members must keep working, no PINs in chat or the repo.

## Update 2026-11-18: the Treasury (Shane: "start with 1 million Restaurant Rewards, create wallets one by one, move the credit from one to the other")
Page: https://keytechnologies.si/restaurant-rewards-treasury.html (unlisted, noindex). One fixed supply of 1,000,000.00 Restaurant Rewards starts in a "Treasury" wallet; Shane creates wallets one by one (restaurant, organization, customer, other) and moves credit between any two wallets with an optional note. Every move is an entry in an append-only ledger (nothing edited or deleted; fix a mistake by moving credit back); balances are always computed from the ledger; the page shows "Everything adds up" or a warning if the wallets ever stop summing to the supply; per-wallet statement (tap a wallet); CSV list, JSON backup/restore, "Start over" (needs typing RESET).
LIMIT TODAY: it is a PROTOTYPE that keeps its records in THIS BROWSER ONLY (browser storage). If the browser data is cleared, or Shane opens it on another phone, the records are not there. Download a backup after every session.
TO MAKE IT REAL (needs Shane's OK + a Mac command; nothing in the live program changes):
1. New database node `rr_ledger` (wallets + append-only entries) separate from every LVR/Key node; owner-only read/write with the owner sign-in already used on the owner pages; rules that refuse edits/deletes of existing entries and refuse a move larger than the sender's balance is not possible in rules alone, so the page checks balances and an hourly/nightly check script re-adds the ledger and alerts if it does not equal 1,000,000.00.
2. Emulator tests for the new rules (task.sh already runs the rules tests), then deploy with automatic rollback like deploy-key-rules.sh.
3. Switch the page from browser storage to the database (same screens), keep the JSON backup button, add the weekly backup of rr_ledger to backup-setup.sh.
4. Connect wallets to people: a restaurant wallet to the restaurant portal (Account card), a customer wallet to the member screen (My activity). See the plan above.
OPEN QUESTIONS / ATTORNEY: is one central supply that Shane hands out an issuer-style currency? Keep: no cash value, never sold or exchanged for money or anything of value, no transfers between customers, no "coins/tokens" wording, no blockchain. Decide who may hold wallets (restaurants, organizations) and what a restaurant gives Shane in return for credit (paying for credit can look like selling a stored-value instrument). Get the attorney's view BEFORE any restaurant pays for credit or any customer holds a balance outside the existing, reviewed program.
