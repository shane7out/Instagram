# Restaurant Rewards: brief for the attorney

Prepared for Shane Christensen (Key Technologies.si, Las Vegas, NV). This is a plain-language summary of what has been built and what we need a lawyer to decide BEFORE any real customer holds a balance or any restaurant pays for credit. It is not legal advice and makes no legal conclusions. Please advise on Nevada and federal law as applicable.

## 1. What exists today

**Restaurant Rewards ("RR")** is a promotional loyalty program that already runs for Las Vegas restaurants. Customers earn whole-number points for visits and check-ins and redeem them for **fixed free offers** from a restaurant's catalog (for example a free appetizer). The published program terms say the points have no cash value, are not money or property, and cannot be exchanged for cash. A restaurant's prepaid "credit remaining" in the program is a promotional budget that Key Technologies tracks.

**New prototype ("Treasury")**, not yet used with real customers:

- One central supply of **1,000,000 Restaurant Rewards**, created once and recorded in a database. The supply is fixed; the system refuses to create more.
- Shane (the operator) opens **wallets** one at a time (a restaurant, an organization, a customer, "other") and **moves credit** from the Treasury wallet to them.
- A wallet can **pay a restaurant** ("redeem"). The restaurant sees the payment on its own phone and **confirms or declines** it with its own PIN. Until the restaurant confirms, the credit is held (the payer is debited; the restaurant is not yet credited). A declined payment returns to the payer.
- Every move is written to an append-only record (no edits, no deletes). Amounts are whole numbers only; no cents, no dollar signs.
- Wording on every screen: "Restaurant Rewards are a promotional perk with no cash value. They are not money, a deposit or stored value and cannot be exchanged for cash."

Nothing is sold. No customer pays anything for Restaurant Rewards today.

## 2. Questions we need answered

### A. Is one central supply handed out by Key Technologies an "issuer" problem?
Key Technologies would mint a fixed supply and distribute it to wallets that can later be spent at participating restaurants. Does that structure, by itself, create obligations (money transmission, stored value / prepaid access, gift certificate or gift card rules, unclaimed property / escheat, state or federal registration), even if nothing is ever sold?

### B. What changes if a restaurant pays Key Technologies for credit?
The business idea has a restaurant funding credit it later honors. If a restaurant (or anyone) **pays money** to receive Restaurant Rewards, is that selling a stored-value instrument or a gift card? What wording and structure (for example, "marketing budget", "service fee", "campaign credit", a fixed offer catalog, no cash-out, no transfers outside the program) keeps this a promotional program? Who may be paid, and when may a balance expire?

### C. What is a restaurant's balance worth, and what can it do with it?
When a customer pays a restaurant in Restaurant Rewards and the restaurant confirms, the restaurant holds a balance. Today the program does not say what that balance is. Options we need advice on:
1. The balance is used up (burned) when redeemed; nothing accumulates for the restaurant.
2. The restaurant keeps the balance and can only spend it on Key Technologies services (marketing, software, etc.).
3. The restaurant can send it onward to other wallets in the program.
4. The restaurant can cash it out (we believe this is the highest-risk option and do not intend it without advice).

For each option, does it create cash-equivalent value, and what disclosures and limits are required?

### D. Typing a free-form amount (e.g. "83") instead of redeeming fixed offers
The live program redeems fixed offers at a set point cost. The prototype lets a wallet pay any whole amount to a restaurant. Does free-form payment make the points look like currency toward a bill? Is a fixed catalog (or a cap per visit, or "toward food only") needed?

### E. Customer wallets and person-to-person movement
The terms today say points cannot be sent between people. The Treasury can move credit between any two wallets. We intend to move credit only **Treasury to wallet** and **wallet to restaurant**, not customer to customer. Is that enough? Any problem with an **organization** wallet (a charity, a police-support organization) receiving credit and passing it to people?

### F. Gifts and donations
If Key Technologies gives Restaurant Rewards to an outside organization as a gift or sponsorship, are there gift, tax or lobbying/ethics issues, particularly when the organization is connected to public employees? (The prototype uses a sample organization wallet for planning only; **no outside group has agreed to anything**, and no names are to be used publicly without that group's written permission.)

### G. Consumer disclosures and terms
What must the program terms and the wallet screens say (no cash value, expiration rules, no refunds, how disputes work, who the operator is, how to get a record of activity)? Do the confirmation numbers and receipts raise any issue?

### H. Privacy and records
The database stores wallet names, amounts and timestamps. Customer wallets may carry a person's name. What notice and consent do we need, how long should records be kept, and how do we handle deletion requests when the ledger is intentionally append-only?

### I. Wording we are deliberately avoiding
We do not use "coin", "token", "crypto", "blockchain", "wallet balance in dollars", or any dollar value. Please confirm this is the right posture, and tell us any other words to avoid.

## 3. Controls already in the system

- Fixed total supply; the database refuses a second issue.
- Whole numbers only; amounts cannot be negative or fractional.
- Append-only ledger: entries cannot be changed or deleted, and wallets cannot be renamed or removed.
- Operator actions require a PIN-protected account; each restaurant has its own PIN and can only confirm or decline payments addressed to it. A restaurant cannot see other restaurants' payments or the wallet list.
- Payments wait for the restaurant's confirmation; declined payments leave no effect.
- No money moves through the system. There is no payment processor, no bank connection, no cash-out.

## 4. Documents we can give you
- The current published program terms and privacy page.
- Screenshots of every screen (wallet, redeem, receipt, restaurant confirm page).
- The database rules (the machine-enforced limits listed above).
- A one-page flow: Treasury -> wallet -> restaurant -> confirm.

## 5. Decisions Shane has to make with you
1. Will restaurants ever pay for credit, and if so how is it described?
2. What happens to a restaurant's confirmed balance (burned, spent on Key Technologies services, or something else)?
3. Fixed offers only, or free-form amounts?
4. Which organizations may hold wallets, and what written agreement do we get from them first?
