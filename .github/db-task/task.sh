#!/bin/bash
# Verify the Batman Cards tab is live on the Deals site.
set -e
echo "--- index.html ---"
curl -s https://classiccarsforsale-co.web.app/ -o d.html
echo "size: $(wc -c < d.html)"
echo "batman chip: $(grep -c chip-batman d.html || true)"
echo "--- cars.json ---"
curl -s https://classiccarsforsale-co.web.app/cars.json -o cars.json
echo "size: $(wc -c < cars.json)"
grep -o 'clbm[a-zA-Z0-9]*' cars.json | sort -u | head
echo "batman entries: $(grep -c '"type": *"Batman"\|"type":"Batman"' cars.json || true)"
