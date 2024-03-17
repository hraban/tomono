#!/usr/bin/env bash

set -euo pipefail
set -x

# Ensure testing always works even on unconfigured CI etc
export GIT_AUTHOR_NAME="Test"
export GIT_AUTHOR_EMAIL="test@test.com"
export GIT_COMMITTER_NAME="Test"
export GIT_COMMITTER_EMAIL="test@test.com"

d="$(mktemp -d)"
cd "$d"
pwd

mkdir a
(
	cd a
	git init
	(for i in {1..9} ; do echo $i ; done) > count.txt
	git add count.txt
	git commit -m "count from 1 to 9"
	git checkout -b more-numbers
	echo 10 >> count.txt
	git add count.txt
	git commit -m "append 10"
)

echo "$PWD/a" a | tomono

(
	cd core/a
	# In master
	(echo 0; cat count.txt) | sponge count.txt
	git add count.txt
	git commit -m "count from 0"
	# Continue dev
	git checkout more-numbers
	echo 11 >> count.txt
	git add count.txt
	git commit -m "count to 11"
	# Merge it all
	git checkout master
	git merge more-numbers -m "merge dev"
)

echo "Finished dev:"
cat core/a/count.txt
