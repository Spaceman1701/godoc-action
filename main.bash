#!/bin/bash

set -eo pipefail

cd "$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1

MODULE_ROOT="$(go list -m)"
REPO_NAME="$(basename $(echo $GITHUB_REPOSITORY))"
PR_NUMBER="$(echo $GITHUB_REF | sed 's#refs/pull/\(.*\)/.*#\1#')"

#mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
#cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
godoc -http localhost:8080 &
for (( ; ; )); do
  sleep 0.5
  if [[ $(curl -so /dev/null -w '%{http_code}' "http://localhost:8080/pkg/$MODULE_ROOT/") -eq 200 ]]; then
    break
  fi
done
wget --quiet --mirror --show-progress --page-requisites --execute robots=off --no-parent "http://localhost:8080/pkg/$MODULE_ROOT/"

git checkout origin/gh-pages || git checkout -b gh-pages

echo "generated doc"
rm -rf doc lib "$PR_NUMBER" pkg # Delete previous documents.
mv localhost:8080/* .
echo "moved doc to root"
rm -rf localhost:8080
#find pkg -type f -exec sed -i  "s#/lib/godoc#/$MODULE_ROOT/lib/godoc#g" {} +
mv "pkg/$MODULE_ROOT/index.html" index.html
echo "configured for gh-pages"
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
#[ -d "$PR_NUMBER" ] || mkdir "$PR_NUMBER"
#mv pkg "$PR_NUMBER"
#git add "$PR_NUMBER" doc lib
rm -rf ../pkg ../doc ../lib ../index.html
mv pkg ../
mv doc ../
mv lib ../
mv index.html ../
git add ../pkg ../doc ../lib ../index.html
git commit -m "Update documentation"

GODOC_URL="https://$(dirname $(echo $GITHUB_REPOSITORY)).github.io/$REPO_NAME/$PR_NUMBER/pkg/$MODULE_ROOT/index.html"

# if ! curl -sH "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" | grep '## GoDoc' > /dev/null; then
#   curl -sH "Authorization: token $GITHUB_TOKEN" \
#     -d '{ "body": "## GoDoc\n'"$GODOC_URL"'" }' \
#     "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments"
# fi
