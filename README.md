# Multi- To Mono-repository

Merge multiple repositories into one big monorepository. Migrates every branch in
every subrepo to the eponymous branch in the monorepo, with all files
(including in the history) rewritten to live under a subdirectory.

To use a separate temporary directory while migrating, set the `GIT_TMPDIR`
envvar.

To access the individual functions instead of executing main, source this
script from bash instead of executing it.


## Usage

Invoke the script and pipe a list of repositories to stdin. It will create a new repository, in a directory called `core`:

```sh
./tomono.sh <<EOF
https://github.com/foo/bar.git bar
/home/me/myrepo myrepo
EOF
```

The contents of each repository will be moved to a subdirectory. A new branch will be created for each branch in each of those repositories, and branches of equal name will be merged.

E.g., if both repositories had a branch called `master`, your new repository (core) would have one branch called `master` with two directories in root: `bar/` and `myrepo/`.

If you already have a repository called `core` and wish to import more into it, pass the `--continue` flag. Make sure you don't have any outstanding changes!
