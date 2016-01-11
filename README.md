# Multi- To Mono-repository

Merge multiple repositories into one big monorepository. Migrates every branch in
every subrepo to the eponymous branch in the monorepo, with all files
(including in the history) rewritten to live under a subdirectory.

To use a separate temporary directory while migrating, set the `GIT_TMPDIR`
envvar.

To access the individual functions instead of executing main, source this
script from bash instead of executing it.
