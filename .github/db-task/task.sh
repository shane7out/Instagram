#!/bin/bash
# Read-only research of public restaurant websites (no secrets, nothing written anywhere).
node .github/db-task/research/find-ig.js 2>&1 | head -400
