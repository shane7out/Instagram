#!/bin/bash
# Read-only research of public pages (no secrets, nothing written anywhere).
node .github/db-task/research/find2.js 2>&1 | head -500
