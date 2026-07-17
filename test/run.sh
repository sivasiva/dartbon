#!/usr/bin/env bash
# Compiles every fixture with the ported library and fails on any
# deprecation warning or compile error. GREEN = zero deprecation warnings.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
count=0
for f in $(find test/fixtures -name '*.scss' -type f ! -name '_*' | sort); do
  count=$((count + 1))
  err=$(npx --no-install sass --load-path=. --no-source-map "$f" 2>&1 >/dev/null)
  status=$?
  if [ $status -ne 0 ]; then
    echo "ERROR compiling $f:"; echo "$err"; fail=1; continue
  fi
  if echo "$err" | grep -iq 'deprecat'; then
    echo "DEPRECATION in $f:"; echo "$err" | grep -i deprecat | head -3; fail=1
  fi
done

# Golden snapshot comparison (faithful-output guard).
for f in $(find test/fixtures -name '*.scss' -type f ! -name '_*' | sort); do
  golden="test/golden/$(echo "$f" | sed 's#test/fixtures/##; s#/#__#g; s#\.scss#.css#')"
  if [ -f "$golden" ]; then
    if ! diff -q <(npx --no-install sass --load-path=. --no-source-map --style=expanded "$f") "$golden" >/dev/null; then
      echo "GOLDEN MISMATCH: $f vs $golden"; fail=1
    fi
  fi
done

echo "---"
echo "compiled $count fixtures"
if [ "$count" -ne 37 ]; then
  echo "FIXTURE COUNT WRONG: expected 37, compiled $count"; fail=1
fi
if [ $fail -eq 0 ]; then echo "GREEN: no deprecation warnings"; exit 0
else echo "RED: warnings or errors present"; exit 1; fi
