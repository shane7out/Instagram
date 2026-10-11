#!/bin/bash
# Check whether the Needs-Follow-Up dashboard patch has been deployed yet
# (Shane may have run it without confirming back).
set -e
curl -s "https://lvr-data-a60c1.web.app/?ci=$(date +%s)" --max-time 20 -o /tmp/live-dash.html -w "http=%{http_code} bytes=%{size_download}\n"
echo "APP_VERSION: $(grep -ao 'APP_VERSION=[0-9]*' /tmp/live-dash.html | head -1)"
for MARK in 'openFollowupDM' 's-needsfollowup'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live-dash.html)"
done
