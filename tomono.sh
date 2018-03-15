#!/bin/bash

# Merge multiple repositories into one big monorepo. Migrates every branch in
# every subrepo to the eponymous branch in the monorepo, with all files
# (including in the history) rewritten to live under a subdirectory.
#
# To use a separate temporary directory while migrating, set the GIT_TMPDIR
# envvar.
#
# To access the individual functions instead of executing main, source this
# script from bash instead of executing it.

${DEBUGSH:+set -x}
if [[ "$BASH_SOURCE" == "$0" ]]; then
	is_script=true
	set -eu -o pipefail
else
	is_script=false
fi

# Default name of the mono repository (override with envvar)
: "${MONOREPO_NAME=core}"

# Monorepo directory
monorepo_dir="$PWD/$MONOREPO_NAME"



##### FUNCTIONS

# Silent pushd/popd
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function read_repositories {
	sed -e 's/#.*//' | grep .
}

# List all branches for a given remote
function remote-branches {
	# Ensure we're always in git root
	pushd "$monorepo_dir"
	# Cleanest way to list all branches without text editing rigmarole
	ls ".git/refs/remotes/$1/"
	popd
}

# Create a monorepository in a directory "core". Read repositories from STDIN:
# one line per repository, with two space separated values:
#
# 1. The (git cloneable) location of the repository
# 2. The name of the target directory in the core repository
function create-mono {
	# Pretty risky, check double-check!
	if [[ "${1:-}" == "--continue" ]]; then
		if [[ ! -d "$MONOREPO_NAME" ]]; then
			echo "--continue specified, but nothing to resume" >&2
			exit 1
		fi
		pushd "$MONOREPO_NAME"
	else
		if [[ -d "$MONOREPO_NAME" ]]; then
			echo "Target repository directory $MONOREPO_NAME already exists." >&2
			return 1
		fi
		mkdir "$MONOREPO_NAME"
		pushd "$MONOREPO_NAME"
		git init
	fi
	read_repositories | while read repo name; do
		if [[ -z "$name" ]]; then
			echo "pass REPOSITORY NAME pairs on stdin" >&2
			return 1
		elif [[ "$name" = */* ]]; then
			echo "Forward slash '/' not supported in repo names: $name" >&2
			return 1
		fi
		echo "Merging in $repo.." >&2
		git remote add "$name" "$repo"
		echo "Fetching $name.." >&2 
		git fetch -qa "$name"
		# Merge every branch from the sub repo into the mono repo, into a
		# branch of the same name (create one if it doesn't exist).
		remote-branches "$name" | while read branch; do
			if git rev-parse -q --verify "$branch"; then
				# Branch already exists, just check it out (and clean up the working dir)
				git checkout -q "$branch"
				git checkout -q -- .
				git clean -f -d
			else
				# Create a fresh branch with an empty root commit"
				git checkout -q --orphan "$branch"
				# The ignore unmatch is necessary when this was a fresh repo
				git rm -rfq --ignore-unmatch .
				git commit -q --allow-empty -m "Root commit for $branch branch"
			fi
			git merge -q --no-commit -s ours "$name/$branch" --allow-unrelated-histories
			git read-tree --prefix="$name/" "$name/$branch"
			git commit -q --no-verify --allow-empty -m "Merging $name to $branch"
		done
	done
	git checkout -q master
	git checkout -q .
}

if [[ "$is_script" == "true" ]]; then
	create-mono "${1:-}"
fi
