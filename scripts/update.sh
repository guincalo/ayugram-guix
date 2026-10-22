#!/bin/sh
# Bump ayugram-desktop to AyuGram's latest release.
# Prints the new version on stdout when the package file changed.
set -eu
scm=modules/ayugram/packages/ayugram.scm
cur=$(sed -n 's/^(define %ayugram-version "\(.*\)")$/\1/p' "$scm")
tag=$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN:-}" \
  https://api.github.com/repos/AyuGram/AyuGramDesktop/releases/latest \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
new=${tag#v}
[ -n "$new" ] || { echo "no tag found" >&2; exit 1; }
# Only move forward.
if [ "$new" = "$cur" ] || [ "$(printf '%s\n%s\n' "$cur" "$new" | sort -V | tail -1)" = "$cur" ]; then
  echo "up to date: $cur (latest $tag)" >&2
  exit 0
fi
tmp=$(mktemp -d)
git -c advice.detachedHead=false clone -q --recursive --branch "$tag" \
  https://github.com/AyuGram/AyuGramDesktop.git "$tmp/src"
# Same as `guix hash -rx`: recursive nar sha256 without .git entries.
hash=$(python3 scripts/narhash.py "$tmp/src")
rm -rf "$tmp"
sed -i \
  -e "s/^(define %ayugram-version \".*\")$/(define %ayugram-version \"$new\")/" \
  -e "s/^(define %ayugram-hash \".*\")$/(define %ayugram-hash \"$hash\")/" \
  "$scm"
echo "$new"
