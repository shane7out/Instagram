// Builds rules/lvr-rules-private.json from lvr-rules-owner.json (so the two never drift apart).
// MEMBER DATA PROTECTION (plan: docs/key-integration/MEMBER_DATA_PLAN.md, step 1). STAGED, NOT DEPLOYED.
//  - lvr_rewards: the whole-list read is REMOVED (no listing, no orderBy/shallow queries). One member can still be read by exact key.
//  - lvr_member_private/<token>: phone, email, birthday, consent_*, memberKey. The token IS the path, so only someone who holds the
//    member's personal link can read it; nobody can list it; the owner can read all. Anyone can create a new one (sign-up), only once.
//  - lvr_refcodes/<code> = memberKey: exact-path lookup for referral codes (replaces orderBy="refCode"); create-once, and the member
//    record must actually carry that code.
// Usage: node make-private-rules.js   (reads/writes next to this file; keeps the __OWNER_UID__ placeholder)
const fs = require('fs'), path = require('path');
const OWN = "(auth != null && auth.uid == '__OWNER_UID__')";
const r = JSON.parse(fs.readFileSync(path.join(__dirname, 'lvr-rules-owner.json'), 'utf8'));
delete r.lvr_rewards['.read'];
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
fs.writeFileSync(path.join(__dirname, 'lvr-rules-private.json'), JSON.stringify(r, null, 1) + '\n');
console.log('wrote lvr-rules-private.json');
