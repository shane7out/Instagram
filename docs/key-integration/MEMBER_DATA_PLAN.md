# Member-data protection plan (LVR Rewards) — started 2026-11-11 (Shane: "I still want to build the member data protection")

Goal: a stranger can no longer read member phones, emails, birthdays or personal-link tokens, and can no longer download the whole member list.
Constraints: free Spark plan (no server code), the live LVR Rewards program must keep working for the 3 real members, nothing goes live without Shane running a Mac command, existing member data is only moved with Shane's explicit OK, rewards rules unchanged (no cash value, never expire, etc.).

## What is exposed today (checked read-only, db-task run 497)
`lvr_rewards` is readable by anyone who knows the database address (3 children). Each member record holds: name, instagram, phone, (email), birthday, anniversary, consent_* fields, points, status, refCode, chestState AND `token` (the member's personal-link secret, which opens that member's screen). Member keys are push ids that are ALSO public (round1 leaderboard, receipts, transactions use them).
The member screen finds a member with `lvr_rewards.json?orderBy="token"&equalTo=...`, counts members with `?shallow=true`, and finds referrers with `orderBy="refCode"` / `"referredBy"`. All of those need the whole list to be readable, which is why rules alone could not close this before.

## Design (Spark-only, "secret as the path")
Rules can hide a list but still allow reading one exact path. So the secrets become path names nobody can list:
1. NEW `lvr_member_private/<token>` : phone, email, birthday, anniversary, consent_*, memberKey. Read: anyone who knows the exact token path (the member), or the owner. List: never. Write: create-once by the sign-up pages; owner can edit.
2. NEW small indexes, exact-path only: `lvr_refcodes/<code> = memberKey`; member count via the existing public `lvr_points/round1` (already lists every member) so `shallow` is not needed.
3. `lvr_rewards/<memberKey>` keeps only non-sensitive fields (name, instagram, points, status, refCode, chestState, referral counters). `token` is removed from it. Top-level read of `lvr_rewards` is removed; reading ONE member by key stays open for now (needed by leaderboard/restaurant views), so points are still publicly readable per member (that is acceptable: first name + last initial + points are already shown on the leaderboard).
4. Owner tools (Points admin, Key room, main dashboard Rewards CRM) read `lvr_rewards` and `lvr_member_private` with the owner sign-in token (already built into those pages).
5. Write rules for points stay as they are (tamper-proofing points needs server code = Blaze plan; documented open gap).

## Build order (each step tested and reversible; nothing live until the Mac deploy)
- Step 1 (code, no live effect): new rules file `rules/lvr-rules-private.json` + emulator tests (CI) proving: stranger cannot list lvr_rewards or lvr_member_private, cannot read phone/token of anyone, member can read their own private node by token, owner can read all, sign-up can create but not overwrite.
- Step 2 (code): sign-up pages (rewards.html public sign-up; lvr-rewards.html VIP page) write the private node + refcode index and no longer put phone/email/birthday/token in the public record.
- Step 3 (code): member app (my-account.html) loads by `lvr_member_private/<token>` then `lvr_rewards/<memberKey>`; counts and referrals through the new indexes; receipts use the private phone it just read.
- Step 4 (code): owner tools read the private node (Points admin Approvals/Members, Key room); main dashboard Rewards CRM patched by a Mac patch script like the earlier ones.
- Step 5 (needs Shane's explicit OK): one Mac script with the owner sign-in MOVES the 3 existing members into the new layout (copy first, verify, then remove the old fields; backup file written first).
- Step 6: deploy the new rules with automatic rollback (same pattern as deploy-owner-rules.sh), then a read-only outside probe: expect 401 on `lvr_rewards`, and none of phone/token readable.
Order matters: pages that understand BOTH layouts go live first, then data move, then rules. The old layout keeps working until the rules step.

## Status
- 2026-11-11: plan written. Step 1 next.
