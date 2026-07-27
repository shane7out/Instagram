#!/bin/bash
# Phase 1: READ-ONLY inspection of dashboard_crec so the write can mirror the
# real record schema exactly. No mutations in this phase.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
echo "== record count =="
jq 'keys|length' crec.json
echo "== last key =="
jq -r 'keys|last' crec.json
echo "== last record (schema template) =="
jq -c --arg k "$(jq -r 'keys|last' crec.json)" '.[$k]' crec.json
echo "== second-to-last record (schema confirmation) =="
jq -c --arg k "$(jq -r 'keys|.[-2]' crec.json)" '.[$k]' crec.json
echo "== highest num in crec =="
jq '[.[]|.num?|numbers]|max' crec.json
echo "== target handles already present? =="
grep -cio 'fortunelasvegas' crec.json || true
grep -cio 'blacklabelburgerco' crec.json || true
grep -cio 'shookshakery' crec.json || true
echo "== tombstone info =="
curl -s "$DB/dashboard_deleted.json" -o dele.json
jq 'keys|length' dele.json
jq -c 'keys|.[-5:]' dele.json
