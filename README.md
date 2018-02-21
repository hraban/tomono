# Multi- To Mono-repository

Merge multiple repositories into one big monorepository. Migrates every branch in
every subrepo to the eponymous branch in the monorepo, with all files
(including in the history) rewritten to live under a subdirectory.

Features:

* Preserve full history and commit hashes of all repositories.
* Don't Stop The World: keep working in your other repositories during the
  migration and pull the changes into the monorepo as you go.
* No conflicts: Each original repository keeps their directory structure, no
  merging required. All files are moved into a subdirectory.

Requirements:
* git version 2.9+.

## Usage

Prepare a list of repositories to merge in a file, for example repos.txt:

```
git@github.com:mycompany/service-one.git one
git@github.com:mycompany/service-two.git two
git@github.com:mycompany/service-three.git three
```

The format is: `<repository_url><space><new_name>`. The repository url can be
anything that can be passed to `git clone`.

Now pipe the file to the tomono.sh script. Assuming you've downloaded this
program to your home directory, for example, you can do:

```sh
$ cat repos.txt | ~/tomono/tomono.sh
```

This will create a new repository called `core`, in your current directory.

If you already have a repository called `core` and wish to import more into it,
pass the `--continue` flag. Make sure you don't have any outstanding changes!

To change the name of the monorepo directory, set an envvar before any other
operations:

```sh
$ export MONOREPO_NAME=my_directory
$ ...
```

## Fluid migration: Don't Stop The World

New changes to the old repositories can be imported into the monorepo and
merged in. For example, in the above example, say repository `one` had a branch
`my_branch` which continued to be developed after the migration. To pull those
changes in:

```sh
# Fetch all changes to the old repositories
$ git fetch --all
$ git checkout my_branch
$ git merge --strategy recursive --strategy-option subtree=one/ one/my_branch
```

This is a regular merge like you are used to (recursive is the default). The
only special thing about it is the `--strategy-option subtree=one/`: this tells
git that the files have all been moved to a subdirectory called `one`.

### Github branch protection

If:

* the changes have been made to master in the old repo, and
* your mono repo is stored on Github, and
* you have branch protection set up for master,

you could create a PR from the changes instead of directly merging into master:

```sh
$ git fetch --all
# Checkout to master first to make sure we're basing this off the latest master
$ git checkout master
# Now the new "some_branch" will be where our current master is
$ git checkout -b new_one_master
$ git merge --strategy recursive --strategy-option subtree=one/ one/master
$ git push -b origin new_one_master
# Go to Github and create a PR from branch 'new_one_master'
```

## Explanation

The contents of each repository will be moved to a subdirectory. A new branch
will be created for each branch in each of those repositories, and branches of
equal name will be merged.

In the example above, if both repositories `one` and `two` had a branch called
`feature-XXX`, your new repository (core) would have one branch called
`feature-XXX` with two directories in it: `one/` and `two/`.

Usually, every repository will have at least a branch called `master`, so your
new monorepo will have a branch called `master` with a subdirectory for each
original repository's master branch.

A detailed explanation of this program can be found in the accompanying blog
post:

https://syslog.ravelin.com/multi-to-mono-repository-c81d004df3ce

## Further steps

Once your new repository is created, you'll need to update your CI environment.
This means merging all .travis.yml, .circle.yml and similar files into a single
file in the top level. The same holds for the Makefile, which can branch off
into the separate subdirectories to do independent work there.

Additionally, you will need to make a decision about vendoring, if applicable:
do you want to use one vendoring dir for all your code (e.g. a top-level
`vendor` for Go, or `node_modules` for node), or do you want to keep independent
vendoring directories for each project? Both solutions have their respective
pros and cons, which is best depends on your situation.
