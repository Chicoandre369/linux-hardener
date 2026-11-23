#!/bin/bash
# Tests basicos - no requieren root, no cambian el sistema
set -euo pipefail
echo "Test 1: harden.sh existe y es ejecutable..."
test -x ./harden.sh && echo "OK - ejecutable" || (echo "FAIL"; exit 1)
echo "Test 2: --help funciona..."
./harden.sh --help | grep -q "check-only" && echo "OK - help" || (echo "FAIL - help"; exit 1)
echo "Test 3: config existe..."
test -f config/hardening.conf && echo "OK - config" || (echo "FAIL - config"; exit 1)
echo "Todos los tests pasaron"
