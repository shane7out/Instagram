# Key Rewards: what was built (2026-11-06) and how it fits together

Status: BUILT AND TESTED IN A SANDBOX. NOT LIVE. Live needs: attorney review, written restaurant agreements, owner sign-in, the staged
database rules deployed, and Shane saying go. Nothing here changes the live LVR Rewards program, its members, balances or rules.

## Pieces
| Piece | File | What it is |
|---|---|---|
| Engine | `sites/key-technologies/key-platform/kr-engine.js` | All the logic (split, check-in, approve, close, redeem, summary). Two storage back ends: `localStore` (sandbox, this browser only) and `firebaseStore` (live REST, not switched on). |
| Owner / restaurant dashboard | `sites/key-technologies/key-rewards-dashboard.html` | Overview KPIs and chart, create events, check-in tab with QR code and approve/reject, close and issue (with a confirm step), redemptions, restaurants, rules. Sandbox banner on top. noindex, no visitor counter. |
| Member check-in page | `sites/key-technologies/key-rewards-checkin.html?e=<event id>` | Guest enters a first name; the phone gets a private random member code. After the event it shows the member's rewards. |
| Public demo / service | `key-platform/demos/key-rewards-events.html`, homepage card "Key Rewards: Guest Events & Loyalty" | Sliders and a close button, made-up data. |
| Database rules (staged) | `.github/db-task/rules/key-rewards-rules.json` | Section `key_rewards`. Placeholder `__OWNER_UID__` (the deploy script fills it). |
| Deploy script (NOT run) | `.github/db-task/mac/deploy-key-rewards-rules.sh` | Backs up current rules, adds only `key_rewards`, runs live checks, restores the old rules if any check fails. |
| Tests | `.github/db-task/rewards-tests/test-kr-engine.js` (41 checks, pure logic) and `.github/db-task/rules/test-key-rewards.js` (87 checks: the rules plus the engine through the Firebase store, in the emulator) | Run the second with `env -u HTTPS_PROXY -u HTTP_PROXY -u https_proxy -u http_proxy -u ALL_PROXY NO_PROXY='*' bash .github/db-task/rules/run-kr-rules-test.sh` |

## Data (all under `key_rewards/`)
- `restaurants/<rid>`: name, city, country, active, createdAt. Owner only.
- `events/<eid>`: rid, title, pool, cap, opensAt, closesAt, status (draft, open, closed), createdAt; set when closed: approvedCount, share, issued, leftover, closedAt. Anyone may read ONE event by id (the check-in page needs it); only the owner may list or write. Pool and cap cannot change after creation; a closed event can never change; status only moves draft to open to closed; issued + leftover must equal the pool.
- `checkins/<eid>/<mkey>`: t, name (first name only), status (pending, approved, rejected). Anyone may CREATE one, once, while the event is open and inside its window, always as pending, with a member code of 12 to 40 letters or digits. Only the owner reads them; only the owner may approve or reject (status only), and not after the event is closed.
- `shares/<eid>/<mkey>`: rewards, at. Written once by the owner when the event closes, never above the cap or the pool. A member can read their own by knowing their private code; nobody can list them.
- `redemptions/<id>`: mkey, rid, offer, rewards (whole number, at least 15), at. Owner only, write once.
- Unknown fields are refused everywhere.

## The rule (one line)
share = the smaller of (pool divided by approved guests, rounded down) and the per-person cap. Issued = share x guests. The leftover is never issued. Everything is a whole number; there is no money anywhere in the system.

## What the rules cannot do (honest limits)
- No server code: the split is computed by the owner's dashboard and written in one atomic update; the rules check the cap, the pool and that issued + leftover = pool, but cannot recount the guests. Staff approval is the control against fake check-ins.
- A person with two phones (or cleared storage) can scan twice; staff approval is the control.
- Crediting event rewards into a member's LVR Rewards balance is NOT connected (it would touch the member points rules). The ledger here is separate: received minus redeemed per member code. Connecting them is a later, reviewed step.
- Live mode needs the owner signed in with the Firebase sign-in (not set up yet).

## To go live (in order)
1. Attorney reviews terms, privacy policy and the restaurant agreement (questions in KEY_REWARDS_PLAN.md).
2. Owner sign-in set up (owner-login.sh).
3. Run `deploy-key-rewards-rules.sh` on the Mac (after Shane says go).
4. Switch the dashboard and check-in page from `KR.localStore` to `KR.firebaseStore` (one line each) and add the owner token; run one real event with a friendly restaurant.
