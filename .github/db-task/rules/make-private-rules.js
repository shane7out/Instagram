// Builds rules/lvr-rules-private.json from lvr-rules-owner.json (so the two never drift apart).
// MEMBER DATA PROTECTION (plan: docs/key-integration/MEMBER_DATA_PLAN.md, step 1). STAGED, NOT DEPLOYED.
//  - lvr_rewards: the whole-list read is OWNER-ONLY now (no listing or orderBy/shallow queries for anyone else). One member can still be read by exact key.
//  - lvr_member_private/<token>: phone, email, birthday, consent_*, memberKey. The token IS the path, so only someone who holds the
//    member's personal link can read it; nobody can list it; the owner can read all. Anyone can create a new one (sign-up), only once.
//  - lvr_member_idx/<sha256> = memberKey (duplicate and self-referral checks) and round1 entries may carry referredBy.
//  - lvr_refcodes/<code> = memberKey: exact-path lookup for referral codes (replaces orderBy="refCode"); create-once, and the member
//    record must actually carry that code.
// Usage: node make-private-rules.js   (reads/writes next to this file; keeps the __OWNER_UID__ placeholder)
const fs = require('fs'), path = require('path');
const OWN = "(auth != null && auth.uid == '__OWNER_UID__')";
const r = JSON.parse(fs.readFileSync(path.join(__dirname, 'lvr-rules-owner.json'), 'utf8'));
r.lvr_rewards['.read'] = OWN; // only the owner can list members
r.lvr_rewards['$k']['.read'] = true;
r.lvr_member_private = {
  '.read': OWN,
  '$t': {
    '.read': true,
    '.write': "newData.exists() ? (data.exists() ? (newData.child('memberKey').val() == data.child('memberKey').val()) : true) : " + OWN,
    '.validate': "$t.length >= 16 && $t.length <= 64 && newData.hasChildren(['memberKey']) && newData.child('memberKey').isString() && newData.child('memberKey').val().length >= 1 && newData.child('memberKey').val().length <= 64",
    'memberKey': { '.validate': 'newData.isString()' },
    'phone': { '.validate': 'newData.isString() && newData.val().length <= 40' },
    'email': { '.validate': 'newData.isString() && newData.val().length <= 120' },
    'birthday': { '.validate': 'newData.isString() && newData.val().length <= 40' },
    'anniversary': { '.validate': 'newData.isString() && newData.val().length <= 40' },
    '$other': { '.validate': true }
  }
};
r.lvr_refcodes = {
  '$code': {
    '.read': true,
    '.write': "newData.exists() ? (!data.exists() && newData.isString() && root.child('lvr_rewards').child(newData.val()).child('refCode').val() == $code) : " + OWN,
    '.validate': 'newData.isString() && $code.length >= 4 && $code.length <= 12'
  }
};
// duplicate / self-referral check without exposing anyone's phone or email: key = sha256 of the digits of the phone (or the lower-cased email), value = member key. Exact path only, create-once.
r.lvr_member_idx = {
  '$h': {
    '.read': true,
    '.write': "newData.exists() ? (!data.exists() && newData.isString() && newData.val().length >= 1 && newData.val().length <= 64) : " + OWN,
    '.validate': "$h.length == 64 && newData.isString()"
  }
};
// Step 5 (moving the 3 existing members) has to REMOVE the personal-link token (and phone/email/birthday) from the public member record, and the old rule
// made the token unchangeable for everyone. Only the owner may now change or remove it; a stranger still cannot (verified in test-private-rules.js).
{
  const w = r.lvr_rewards['$k']['.write'];
  const old = "((!data.child('token').exists() || newData.child('token').val() == data.child('token').val())";
  if (w.split(old).length !== 2) throw new Error('token clause not found exactly once');
  r.lvr_rewards['$k']['.write'] = w.replace(old, "((" + OWN + " || " + old.slice(1) + ")");
}
// Round One registry entries may carry who invited the member, so the founding-invite count no longer needs the member list.
r.lvr_points.round1['$mk']['referredBy'] = { '.validate': 'newData.isString() && newData.val().length <= 64' };
fs.writeFileSync(path.join(__dirname, 'lvr-rules-private.json'), JSON.stringify(r, null, 1) + '\n');
console.log('wrote lvr-rules-private.json');
