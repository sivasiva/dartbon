#!/usr/bin/env bash
# Removes Bourbon 4.x's internal self-deprecation layer.
# Public mixin/function bodies are preserved; only the deprecation
# machinery is deleted.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Delete the deprecation core + its settings variable file.
rm -f _bourbon-deprecate.scss settings/_deprecation-warnings.scss

# 2. Remove their @import lines from the entrypoint.
perl -ni -e 'print unless m{\@import\s+"(settings/deprecation-warnings|bourbon-deprecate)"}' _bourbon.scss

# 3. Several functions/helpers wrap their @warn in:
#      @if $output-bourbon-deprecation-warnings == true {
#        @warn "...";
#      }
#    This is a block, not a standalone statement: deleting only the lines
#    that contain the toggle variable (as step 4 does) would strip the
#    "@if ... {" opening line but leave its matching "}" behind, orphaning
#    the brace and breaking the parse. Remove the whole block atomically
#    first, non-greedily so it can't swallow past its own closing brace.
find . -name '*.scss' -not -path './test/*' -type f -exec perl -0777 -pi -e '
  s/^[ \t]*\@if\s+\$output-bourbon-deprecation-warnings\s*==\s*true\s*\{\n(?:.*\n)*?[ \t]*\}\n//mg;
' {} +

# 4. Across all remaining partials, delete:
#    - lines that invoke the deprecation mixin
#    - lines that touch the $output-bourbon-deprecation-warnings toggle
#      (the 3-line save/false/restore !global toggle - each line is an
#      independent statement, safe to delete line-by-line)
find . -name '*.scss' -not -path './test/*' -type f -exec perl -ni -e '
  next if /\@include\s+_bourbon-deprecate/;
  next if /output-bourbon-deprecation-warnings/;
  print;
' {} +

echo "strip complete"
