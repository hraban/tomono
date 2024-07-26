#!/usr/bin/env bash

set -euo pipefail

set -x

# The tomono script is tangled right next to the test script
export PATH="$PWD:$PATH"

d="$(mktemp -d)"
cd "$d"

# Two reasonably complex repos with lots of changes but not too many. And both
# with a ‘master’ branch.
>remotes.txt cat <<EOF
https://github.com/git/git.git git
https://git.code.sf.net/p/sbcl/sbcl sbcl
EOF

cat remotes.txt | while read url dir ; do
	git clone "$url" "$dir"
	(
		cd "$dir"
		git log --before 1.year.ago -1 --format=%h | xargs git reset --hard
	)
	echo "$PWD/$dir $dir" >> locals.txt
done

<locals.txt tomono

# Now we have a repo core with SBCL and Git, both where they were 1y ago. Update
# those and merge in the changes.

cat remotes.txt | while read _ dir ; do
	(
		cd "$dir"
		git reset --hard HEAD@{1}
	)
done

cd core
git fetch --all
git checkout master

cat ../remotes.txt | while read _ dir; do
	git merge --no-edit -X subtree="$dir/" "$dir/master"
done

echo "Successfully merged in 1 year worth of changes from both remotes into $PWD"
