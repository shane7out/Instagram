#!/bin/bash
# Verify the batman card photos are live under /carimg (they'd be deployed with prior runs).
set +e
B="https://classiccarsforsale-co.web.app"
for p in \
  "/carimg/batman-cjn4kkuu-1.jpg" \
  "/carimg/batman-cjN4kkUu-1.jpg" \
  "/carimg/batman-qhhffyxpf-1.jpg" \
  "/carimg/batman-qhHFYxPf-1.jpg" ; do
  echo "$(curl -s -o /dev/null -w '%{http_code} %{size_download}' "$B$p")  $p"
done
