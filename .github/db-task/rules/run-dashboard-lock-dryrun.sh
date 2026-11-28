#!/bin/bash
# DRY RUN of mac/deploy-dashboard-lock.sh against a FAKE Firebase (no network, nothing real is touched).
# Proves the script's own logic: refuses without a backup / bridge / matching live rule, locks, verifies, and rolls back when a check fails.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W=/tmp/dashlock-dryrun; rm -rf "$W"; mkdir -p "$W/home/lvr-backups/2026-11-28" "$W/home/.lvr"
echo -n abcdefghij0123456789ABCDEF12 > "$W/home/.lvr/owner-uid"; touch "$W/home/lvr-backups/2026-11-28/dashboard_crec.json.gz" "$W/home/lvr-backups/2026-11-28/dashboard.json.gz"
node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");require("fs").writeFileSync(process.argv[2],s.slice(s.indexOf("<<'"'"'NODE'"'"'\n")+9,s.indexOf("\nNODE\n")))' "$HERE/../mac/deploy-dashboard-lock.sh" "$W/ddl.js" || exit 1
RC=0
run(){ # mode expected-text   (MOCK_MODE good unless the name says otherwise)
  OUT=$(HOME_FAKE="${HOME_OVERRIDE:-$W/home}" MOCK_MODE=${1/nobackup/good} FRAG="$HERE/dashboard-lock-rules.json" node -r "$HERE/dryrun-mock-firebase.js" "$W/ddl.js" 2>&1)
  if echo "$OUT" | grep -q "$2"; then echo "PASS  $1: $2"; else echo "FAIL  $1: expected '$2'"; echo "$OUT" | tail -5; RC=1; fi
}
run good "ALL CHECKS PASSED"
run broken "put your old rules back automatically -> HTTP 200"
run drift "not the one this was tested against"
mkdir -p "$W/empty/.lvr"; cp "$W/home/.lvr/owner-uid" "$W/empty/.lvr/"; HOME_OVERRIDE="$W/empty" run nobackup "No database backup"
run nobridge "does not have the sign-in bridge"
exit $RC
