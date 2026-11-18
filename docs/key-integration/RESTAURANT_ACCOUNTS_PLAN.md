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
