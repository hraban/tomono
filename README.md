# Multi- To Mono-repository

Merge multiple repositories into one big monorepository. Migrates every branch in
every subrepo to the eponymous branch in the monorepo, with all files
(including in the history) rewritten to live under a subdirectory.


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
