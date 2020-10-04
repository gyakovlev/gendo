# GENDO (Gentoo + Docker) setup

this is in very early stages, there are bugs, inflexibility.
Very early stage.



## Usage

Idea is to wrap docker into Makefile and use to build/test/package gentoo ebuilds.

General workflow idea:

`make glibc-pkg`  - emits glibc binary package to local directory.

`make ms-gsl` - installs all `ms-gsl` (test)deps and runst testsuite. 

```shell-session
git diff > local.diff
make mesa
```
NIY:^ apply `local.diff` patch to gentoo repository and run tests for `mesa`



## Required docker options in `daemon.json`:
```json
{
    "experimental": true,
    "features": { "buildkit": true }
}
```
