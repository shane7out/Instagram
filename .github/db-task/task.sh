#!/bin/bash
# read-only status check (no personal data printed)
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "ownerAuth/apiKey stored: $(curl -s $DB/ownerAuth/apiKey.json | cut -c1-6)"
echo "_debug/ownersetup: $(curl -s $DB/_debug/ownersetup.json | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[EMAIL]/g' | head -c 900)"
echo "_debug/ownerrules: $(curl -s $DB/_debug/ownerrules.json | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[EMAIL]/g' | head -c 900)"
echo "members: $(curl -s "$DB/lvr_rewards.json?shallow=true" | tr ',' '\n' | wc -l)  round1: $(curl -s "$DB/lvr_points/round1.json?shallow=true" | tr ',' '\n' | wc -l)"
echo "pending sign-ups: $(curl -s "$DB/lvr_rewards.json?orderBy=%22status%22&equalTo=%22pending%22&shallow=true" | head -c 200)"
echo "pool/total: $(curl -s $DB/lvr_points/pool/total.json)  decay_runs: $(curl -s "$DB/lvr_points/decay_runs.json" | head -c 200)  pool_drop_runs: $(curl -s "$DB/lvr_points/pool_drop_runs.json" | head -c 200)"
echo "settings/paused: $(curl -s $DB/lvr_points/settings/paused.json)"
echo "leads (count only): $(curl -s "$DB/key_leads/leads.json?shallow=true" | tr ',' '\n' | wc -l)"
echo "anon write to settings (200 = owner-only rules NOT yet live): $(curl -s -o /dev/null -w '%{http_code}' -X PUT -d '1' $DB/lvr_points/settings/zz_probe2.json)"
curl -s -X DELETE $DB/lvr_points/settings/zz_probe2.json >/dev/null
