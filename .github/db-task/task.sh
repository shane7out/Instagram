#!/bin/bash
# Read-only diagnostic: check current DNS records for keytechnologies.si to
# see what's configured (or not) at the registrar before giving DNS instructions.
set -e
echo "=== A records ==="
dig +short keytechnologies.si A || true
echo "=== CNAME ==="
dig +short keytechnologies.si CNAME || true
echo "=== www CNAME ==="
dig +short www.keytechnologies.si CNAME || true
echo "=== NS (nameservers) ==="
dig +short keytechnologies.si NS || true
