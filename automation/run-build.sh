#!/usr/bin/env bash
set -euo pipefail

# Runs the qortal Docker build and push pipeline.

cd /opt/qortal
echo "[run-build] Starting build at $(date -Is)"
./docker_build.sh
echo "[run-build] Build completed at $(date -Is)"
