#!/bin/bash

# Merge multiple repositories into one big monorepo. Migrates every branch in
# every subrepo to the eponymous branch in the monorepo, with all files
# (including in the history) rewritten to live under a subdirectory.
#
# To use a temporary directory while migrating, set the GIT_TMPDIR envvar. This
# migration is very I/O heavy so if you have a ramdisk this is a good idea.
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

# Name of the mono repository
MONOREPO_NAME="core"

# Move all files in every branch in the current working directory's git repo to
# a subdirectory (as named), including history and tags and everything
function redir {
	dirname="${1:?redir requires a subdirectory name to move the files to}"
	# Temporary directory name---assume this file doesn't exist in the root in
	# any revision in the entire repo. If it does; probrem.
	local TEMPF=temp-toDvKEq
	# -f: Discard backups
	# --index-filter: Move all files to a subdirectory
	#    the two grep lines remove all submodules
	# --tag..: Migrate tags, too
	# -d: Use a temporary directory, if desired (ramdisk for speed)
	# --all: All branches and tags and, just, everything. \
	# NB: The sed expression contains raw tabs---don't remove them
	# NB: When the post update-index index file is empty, it is not created
	git filter-branch \
		${GIT_TMPDIR:+-d "$GIT_TMPDIR"} \
		--index-filter '
			git ls-files --stage | \
			grep -v "^160000" | \
			grep -v .gitmodules | \
			sed -e "s_	_	'"$dirname"'/_" | \
			GIT_INDEX_FILE="$GIT_INDEX_FILE.new" git update-index --index-info && \
			mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE" || rm "$GIT_INDEX_FILE"' \
		--tag-name-filter cat \
		-- \
		--all
}

function read_repositories {
	sed -e 's/#.*//' | grep .
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
	else
		if [[ -d "$MONOREPO_NAME" ]]; then
			echo "Target repository directory $MONOREPO_NAME already exists." >&2
			return 1
		fi
		mkdir "$MONOREPO_NAME"
		(
			cd "$MONOREPO_NAME"
			git init
		)
	fi
	read_repositories | while read repo name; do
		if [[ -z "$name" ]]; then
			echo "pass REPOSITORY NAME pairs on stdin" >&2
			return 1
		fi
		echo "Merging in $repo.." >&2
		git clone -q --bare "$repo" "$name.git"
		(
			cd "$name.git"
			# Rewrite history first
			redir "$name"
		)
		# Merge every branch from the sub repo into the mono repo, into a
		# branch of the same name (create one if it doesn't exist).
		(
			cd "$MONOREPO_NAME"
			git remote add "$name" "../$name.git"
			git fetch -qa "$name"
			# Silly git branch outputs a * in front of the current branch name..
			git --git-dir ../"$name.git" branch | tr \* ' ' | while read branch; do
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
				git merge -q --no-ff -m "Merging $name to $branch" "$name/$branch"
			done
		)
	done
}

if [[ "$is_script" == "true" ]]; then
	create-mono "${1:-}"
fi
